/**
 * PheKB Phenotype
 *
 * Name : Crohn’s Disease
 * ID   : 77
 * Url  : https://phekb.org/node/77
 */
library "77.crohns-disease-demonstration-project" version '1.0.0'

using FHIR version '4.0.0'

include FHIRHelpers version '4.0.0' called FHIRHelpers

valueset "Crohns Diagnoses": '77.crohns-disease-dx-codes'
valueset "Crohns Drugs": '77.crohns-disease-drug-codes'

context Patient

define "Has Medications":
    exists([MedicationRequest: "Crohns Drugs"])

define "Has More Than Two Diagnoses":
    Count([Condition: "Crohns Diagnoses"]) > 2

define "Case":
    "Has Medications"
        and
    "Has More Than Two Diagnoses"
