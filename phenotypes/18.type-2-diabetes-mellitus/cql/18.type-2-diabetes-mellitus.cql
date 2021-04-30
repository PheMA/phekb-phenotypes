/**
 * PheKB Phenotype
 *
 * Name : Type 2 Diabetes Mellitus
 * ID   : 18
 * Url  : https://phekb.org/node/18
 */
library "18.type-2-diabetes-mellitus" version '1.0.0'

using FHIR version '4.0.0'

include FHIRHelpers version '4.0.0' called FHIRHelpers
include PhEMAHelpers version '1.0.0' called PhEMAHelpers
include PhEMADiabetes version '1.0.0' called PhEMADiabetes

// Build a concept that represents problem list and encounter diagnosis categories.  This is used to qualify
// a Condition as being 'physician diagnosed'
codesystem "ConditionCategoryCodes": 'http://terminology.hl7.org/CodeSystem/condition-category'
code "problem-list-item": 'problem-list-item' from "ConditionCategoryCodes"
code "encounter-diagnosis": 'encounter-diagnosis' from "ConditionCategoryCodes"
concept "PhysicianDiagnosisCategory": { "problem-list-item", "encounter-diagnosis" } display 'Physician Diagnosis Category'

valueset "Type 1 DM": 'omop-concept-set-26'
valueset "Type 2 DM": 'omop-concept-set-27'
valueset "T1DM Medications": 'omop-concept-set-28'
valueset "T2DM Medications": 'omop-concept-set-29'
valueset "Fasting Glucose": 'omop-concept-set-30'
valueset "Random Glucose": 'omop-concept-set-31'
valueset "Hemoglobin A1C": 'omop-concept-set-32'

context Patient

define "No Type 1 DM Diagnosis":
  not(exists([Condition: "Type 1 DM"]))

define "No Type 2 DM Diagnosis":
  not(exists([Condition: "Type 2 DM"]))

// We are writing this exactly as represented within the original phenotype.  It
// uses a Count(distinct) > 0 as opposed to just Exists()
define "Has Type 2 DM Diagnosis":
  Count(distinct [Condition: "Type 2 DM"]) > 0

// Must be an encounter or problem list diagnosis, unlike the other T2DM query
// which allows any source.
define "Has Physician T2DM Diagnosis":
  Count([Condition: "Type 2 DM"] C
    where C.category ~ "PhysicianDiagnosisCategory") >= 2

define "First T1DM Medication":
  First([MedicationRequest: "T1DM Medications"])

define "First T2DM Medication":
  First([MedicationRequest: "T2DM Medications"])

define "Has abnormal fasting glucose":
  PhEMADiabetes."Has Abnormal Fasting Glucose"(125)

define "Has abnormal random glucose":
  PhEMADiabetes."Has Abnormal Random Glucose"(200)

define "Has abnormal hemoglobin A1c":
  PhEMADiabetes."Has Abnormal Hemoglobin A1C"(6.5)

// Any of the abnormal lab criteria
define "Has abnormal lab":
  "Has abnormal fasting glucose" or
  "Has abnormal random glucose" or
  "Has abnormal hemoglobin A1c"

define "Case Type 1":
  "No Type 1 DM Diagnosis" and
  "Has Type 2 DM Diagnosis" and
  exists("First T1DM Medication") and
  exists("First T2DM Medication") and
  Count ([MedicationRequest: "T2DM Medications"]) < Count([MedicationRequest: "T1DM Medications"])

define "Case Type 2":
  "No Type 1 DM Diagnosis" and
  "Has Type 2 DM Diagnosis" and
  not(exists("First T1DM Medication")) and
  exists("First T2DM Medication")

define "Case Type 3":
  "No Type 1 DM Diagnosis" and
  "Has Type 2 DM Diagnosis" and
  not(exists("First T1DM Medication")) and
  not(exists("First T2DM Medication")) and
  "Has abnormal lab"

define "Case Type 4":
  "No Type 1 DM Diagnosis" and
  "No Type 2 DM Diagnosis" and
  exists("First T2DM Medication") and
  "Has abnormal lab"

define "Case Type 5":
  "No Type 1 DM Diagnosis" and
  "Has Type 2 DM Diagnosis" and
  exists("First T1DM Medication") and
  not(exists("First T2DM Medication")) and
  "Has Physician T2DM Diagnosis"


// Determine if the patient is a case
define "Case":
  "Case Type 1" or
  "Case Type 2" or
  "Case Type 3" or
  "Case Type 4" or
  "Case Type 5"
