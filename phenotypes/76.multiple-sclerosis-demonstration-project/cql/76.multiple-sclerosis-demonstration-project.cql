/**
 * PheKB Phenotype
 *
 * Name : Multiple Sclerosis
 * ID   : 76
 * Url  : https://phekb.org/node/76
 */
library "76.multiple-sclerosis-demonstration-project" version '1.0.0'

using FHIR version '4.0.0'

include FHIRHelpers version '4.0.0' called FHIRHelpers

valueset "Multiple Sclerosis Diagnoses": '76.multiple-sclerosis-dx-codes'
valueset "Multiple Sclerosis Other Diagnoses": '76.multiple-sclerosis-other-dx-codes'
valueset "Multiple Sclerosis Drugs": '76.multiple-sclerosis-drug-codes'

context Patient

define "Has Multiple Sclerosis Diagnosis":
    exists([Condition: "Multiple Sclerosis Diagnoses"])

define "Has Other Diagnoses":
    exists([Condition: "Multiple Sclerosis Other Diagnoses"])

define "Has Medications":
    exists([MedicationRequest: "Multiple Sclerosis Drugs"])

define "Case":
    "Has Multiple Sclerosis Diagnosis"
        or
    ("Has Other Diagnoses"
        and
    "Has Medications")
