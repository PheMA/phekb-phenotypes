/**
 * PheKB Phenotype
 *
 * Name : Rheumatoid Arthritis
 * ID   : 74
 * Url  : https://phekb.org/node/74
 */
library "74.rheumatoid-arthritis-demonstration-project" version '1.0.0'

using FHIR version '4.0.0'

include FHIRHelpers version '4.0.0' called FHIRHelpers
include PhEMAHelpers version '1.0.0' called PhEMAHelpers

valueset "Rheumatoid Arthritis Diagnoses": '74.rheumatoid-arthritis-dx'
valueset "Rheumatoid Arthritis Medications": '74.rheumatoid-arthritis-meds'

// Apparently "Juvenile Diagnoses" is a subset of "Inflamatory Diagnoses" 
valueset "Rheumatoid Arthritis Inflamatory Diagnoses": '74.rheumatoid-arthritis-inflammatory-dx'
valueset "Rheumatoid Arthritis Juvenile Diagnoses": '74.rheumatoid-arthritis-juvenile-dx'

context Patient

define "Case 1":
    exists([Condition: "Rheumatoid Arthritis Diagnoses"])
        and
    exists([MedicationRequest: "Rheumatoid Arthritis Medications"])
        and
   (not exists([Condition: "Rheumatoid Arthritis Inflamatory Diagnoses"]))

// This mostly overlaps with Case 1, so I'm guess something is underspecified
define "Case 2":
    exists([Condition: "Rheumatoid Arthritis Diagnoses"])
        and
    exists([MedicationRequest: "Rheumatoid Arthritis Medications"])
        and
    (not exists([Condition: "Rheumatoid Arthritis Juvenile Diagnoses"]))

define "Case":
    "Case 1"
        or
    "Case 2"
