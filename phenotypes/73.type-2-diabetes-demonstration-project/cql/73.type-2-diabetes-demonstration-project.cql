/**
 * PheKB Phenotype
 *
 * Name : Diabetes Mellitus Type II Demonstration Project
 * ID   : 73
 * Url  : https://phekb.org/node/73
 */
library "73.type-2-diabetes-demonstration-project" version '1.0.0'

using FHIR version '4.0.0'

include FHIRHelpers version '4.0.0' called FHIRHelpers
include PhEMAHelpers version '1.0.0' called PhEMAHelpers
include PhEMADiabetes version '1.0.0' called PhEMADiabetes

valueset "Diabetes Mellitus Type II Diagnoses": '73.t2dm-dx'
valueset "Non-Insulin Diabetes Mellitus Type II Medications": '73.t2dm-non-insulin-meds'
valueset "Diabetes Mellitus Type II Insulin Medications": '73.t2dm-insulin-meds'

context Patient

// Diagnosis and meds
define "Case 1":
    exists([Condition: "Diabetes Mellitus Type II Diagnoses"])
        and
    exists([MedicationRequest: "Non-Insulin Diabetes Mellitus Type II Medications"])

// Diagnosis and labs, but not meds
define "Case 2":
    exists([Condition: "Diabetes Mellitus Type II Diagnoses"])
        and
    (
        // Addition some precision here since the function checks >= not >
        // Obviously this isn't perfect, but it should work in many cases
        exists(PhEMADiabetes."Abnormal Random Glucose"(200.00001))
            and
        exists(PhEMADiabetes."Abnormal Hemoglobin A1C"(6.500001))
    )
        and not
    (
        exists([MedicationRequest: "Non-Insulin Diabetes Mellitus Type II Medications"])
            or
        exists([MedicationRequest: "Diabetes Mellitus Type II Insulin Medications"])
    )

// Non-insulin meds and labs
define "Case 3":
    exists([MedicationRequest: "Non-Insulin Diabetes Mellitus Type II Medications"])
        and
     (
        // Addition some precision here since the function checks >= not >
        // Obviously this isn't perfect, but it should work in many cases
        exists(PhEMADiabetes."Abnormal Random Glucose"(200.00001))
            and
        exists(PhEMADiabetes."Abnormal Hemoglobin A1C"(6.500001))
    )   

define "Case":
    AgeInYears() >= 18
        and
    (
        "Case 1"
            or
        "Case 2"
            or
        "Case 3"
    )
