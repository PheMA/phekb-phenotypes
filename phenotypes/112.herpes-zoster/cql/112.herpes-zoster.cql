/**
 * PheKB Phenotype
 *
 * Name : Herpes Zoster
 * ID   : 112
 * Url  : https://phekb.org/node/112
 */
library "112.herpes-zoster" version '1.0.0'

using FHIR version '4.0.0'

include FHIRHelpers version '4.0.0' called FHIRHelpers
include PhEMAHelpers version '1.0.0' called PhEMAHelpers
include PhEMAOperational version '1.0.0' called PhEMAOperational

valueset "Zoster Diagnoses": '112.zoster-diagnoses'
valueset "Zoster Vaccination Procedures": '112.zoster-vaccination-procedures'
valueset "HIV Diagnoses": '112.hiv-diagnoses'
valueset "Blood Or Bone Marrow Cancer Diagnoses": '112.blood-or-bone-marrow-cancer-diagnoses'
valueset "Chemotherapy Procedures": '112.chemo-procedures'

context Patient

define "Index Date":
    // Date of first diagnosis on or after 40
    PhEMAHelpers."Earliest Date"(
        PhEMAHelpers."Effective Dates"("Diagnoses On Or After 40")
    )

define function "Vaccination On Date"(
    date System.DateTime
):
    exists(
        [Procedure: "Zoster Vaccination Procedures"] P
            where ToDate(PhEMAHelpers."Effective Date"(P)) = ToDate(date)
    )

define "Diagnoses On Or After 40":
    [Condition: "Zoster Diagnoses"] C
        where AgeInYearsAt(PhEMAHelpers."Effective Date"(C)) >= 40
        // I-2-a: exclude diagnoses occuring on vaccination date
            and
        (not "Vaccination On Date"(PhEMAHelpers."Effective Date"(C)))

define "Diagnosis On Or After 40":
    // I-2-a: exclude diagnoses occuring on vaccination date
    exists("Diagnoses On Or After 40")

define "HIV Diagnosis On Two Distinct Days":
    Count(
        PhEMAHelpers."Distinct Dates"(
            [Condition: "HIV Diagnoses"]
        )
    ) >= 2

define "Blood Or Bone Marrow Cancer Diagnosis In Prior Year":
    exists(
        [Condition: "Blood Or Bone Marrow Cancer Diagnoses"] C
            where PhEMAHelpers."Effective Date"(C) after ("Index Date" - 365 days)
    )

define "Chemotherapy In Prior Six Months":
    exists(
        [Procedure: "Chemotherapy Procedures"] P
            where PhEMAHelpers."Effective Date"(P) after ("Index Date" - 180 days)
    )

define "Case":
    // I-1
    AgeInYears() >= 40
        and
    // I-2
    "Diagnosis On Or After 40"
        and
    // I-3
    PhEMAOperational."Continuous Years Of Enrollment"(5)
        and
    // E-1
    (not "HIV Diagnosis On Two Distinct Days")
        and
    // E-2
    (not "Blood Or Bone Marrow Cancer Diagnosis In Prior Year")
        and
    // E-3
    (not "Chemotherapy In Prior Six Months")

