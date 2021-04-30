/**
 * PheKB Phenotype
 *
 * Name : Sickle Cell Disease
 * ID   : 615
 * Url  : https://phekb.org/node/615
 */
library "615.sickle-cell-disease" version '1.0.0'

using FHIR version '4.0.0'

include FHIRHelpers version '4.0.0' called FHIRHelpers
include PhEMAHelpers version '1.0.0' called PhEMAHelpers

valueset "Sickle Cell Disease Diagnoses": '615.sickle-cell-disease-diagnoses'
valueset "Sickle Cell Trait Diagnoses": '615.sickle-cell-trait-diagnoses'
codesystem "ActEncounterCode": 'http://terminology.hl7.org/ValueSet/v3-ActEncounterCode'

code "Inpatient Encounter": 'IMP' from "ActEncounterCode"
code "Outpatient Encounter": 'AMB' from "ActEncounterCode"

context Patient

define "Has Sickle Cell Disease Diagnosis":
    exists([Condition: "Sickle Cell Disease Diagnoses"])

define "Has Two Outpatient Visits At Least 30 Days Apart":
    if Count([Encounter: class in "Outpatient Encounter"]) < 2 then
        false
    else
        exists(
            [Encounter: class in "Outpatient Encounter"] O1
                where 
                    exists(
                        [Encounter: class in "Outpatient Encounter"] O2
                            where
                                days between PhEMAHelpers."Effective Date"(O1) and PhEMAHelpers."Effective Date"(O2) >= 30
                    )
        )

define "Has Two Outpatient Visits Or One Hospitalization":
    "Has Two Outpatient Visits At Least 30 Days Apart"
        or
    Count([Encounter: class in "Inpatient Encounter"]) >= 1

define "Has More Sickle Cell Trait Than Disease Diagnoses":
    Coalesce(
        Count([Condition: "Sickle Cell Trait Diagnoses"])
        > Count([Condition: "Sickle Cell Disease Diagnoses"])
        , false
    )

define "Case":
    "Has Sickle Cell Disease Diagnosis"
        and
    "Has Two Outpatient Visits Or One Hospitalization"
        and
    (not "Has More Sickle Cell Trait Than Disease Diagnoses")
