/**
 * PheKB Phenotype
 *
 * Name : Height
 * ID   : 13
 * Url  : https://phekb.org/node/13
 */
library "13.height" version '1.0.0'

using FHIR version '4.0.0'

include FHIRHelpers version '4.0.0' called FHIRHelpers
include PhEMAHelpers version '1.0.0' called PhEMAHelpers

valueset "Medications Affecting Growth": '13.meds-affecting-growth'
valueset "Growth Hormone Labs": '13.growth-hormone-labs'
valueset "Body Height": '13.body-height'

valueset "Diagnoses Affecting Height": '13.dx-affecting-height'
valueset "Childhood Diagnoses Affecting Height": '13.childhood-dx-affecting-height'

context Patient

define "Growth Hormone Lab Before Adulthood":
    [Observation: "Growth Hormone Labs"] O
        where
            case
                when PhEMAHelpers."Is Male" then
                    AgeInYearsAt(PhEMAHelpers."Effective Date"(O)) <= 21
                else
                    // Use 18 for all non-male genders to be conservative
                    AgeInYearsAt(PhEMAHelpers."Effective Date"(O)) <= 18
            end

define "Has Growth Hormone Lab Before Adulthood":
    exists("Growth Hormone Lab Before Adulthood")

define "Meds Affecting Height Before Adulthood":
    [MedicationRequest: "Medications Affecting Growth"] M
        where
            case
                when PhEMAHelpers."Is Male" then
                    AgeInYearsAt(PhEMAHelpers."Effective Date"(M)) <= 21
                else
                    // Use 18 for all non-male genders to be conservative
                    AgeInYearsAt(PhEMAHelpers."Effective Date"(M)) <= 18
            end

define "Has Meds Affecting Height Before Adulthood":
    exists("Meds Affecting Height Before Adulthood")

define "Earlist Growth Affecting Date":
    PhEMAHelpers."Earliest Date"(
        Flatten(
            {
                "Growth Hormone Lab Before Adulthood" L return PhEMAHelpers."Effective Date"(L),
                "Meds Affecting Height Before Adulthood" M return PhEMAHelpers."Effective Date"(M)
            }
        )
    )

define "Has Childhood Height Affecting Diagnosis":
    exists([Condition: "Childhood Diagnoses Affecting Height"] C
        where
            case
                when PhEMAHelpers."Is Male" then
                    AgeInYearsAt(PhEMAHelpers."Effective Date"(C)) <= 21
                else
                    // Use 18 for all non-male genders to be conservative
                    AgeInYearsAt(PhEMAHelpers."Effective Date"(C)) <= 18
            end
    )

define "Earliest Height Affecting Diagnosis":
    PhEMAHelpers."Earliest Date"(
        PhEMAHelpers."Effective Dates"([Condition: "Diagnoses Affecting Height"])
    )

define "Has Valid Height Before Height Affecting Diagnosis":
    exists([Observation: "Body Height"] O
        where
            O.value >= 55 'cm'
                and
            O.value <= 275 'cm'
                and
            (
                if "Earliest Height Affecting Diagnosis" is null then
                    true
                else
                    PhEMAHelpers."Effective Date"(O) before "Earliest Height Affecting Diagnosis"
            )
    )

define "Case":
    (not "Has Growth Hormone Lab Before Adulthood")
        and
    (not "Has Meds Affecting Height Before Adulthood")
        and
    (not "Has Childhood Height Affecting Diagnosis")
        and
    "Has Valid Height Before Height Affecting Diagnosis"
