/**
 * PheKB Phenotype
 *
 * Name : PhEMA BPH (Benign Prostatic Hyperplasia) cases
 * ID   : 1070
 * Url  : https://phekb.org/node/1070
 */
library "1070.phema-bph-benign-prostatic-hyperplasia-cases" version '1.0.0'

using FHIR version '4.0.0'

include FHIRHelpers version '4.0.0' called FHIRHelpers
include PhEMAHelpers version '1.0.0' called PhEMAHelpers

valueset "BPH Exclusion Diagnoses": '2.16.840.1.113762.1.4.1053.25'
valueset "BPH Diagnoses": '2.16.840.1.113762.1.4.1053.28'
valueset "BPH Drugs": '2.16.840.1.113762.1.4.1053.30'
valueset "BPH Procs": '2.16.840.1.113762.1.4.1053.29'

context Patient

define "BPH Medications":
    exists([MedicationRequest: "BPH Drugs"])

define "BPH Procedures":
    exists([Procedure: "BPH Procs"])

define "Two Or More BPH Diagnoses":
    Count([Condition: "BPH Diagnoses"]) >= 2

define "Has Exclusion Diagnoses":
    exists([Condition: "BPH Exclusion Diagnoses"])

define "In Base Population":
    PhEMAHelpers."Is Male" 
        and 
    PhEMAHelpers."In Biobank"
        and
    AgeInYears() >= 40 

define "Case":
    "In Base Population" 
        and 
    (not "Has Exclusion Diagnoses")
        and
    "Two Or More BPH Diagnoses"
        and
    ("BPH Medications" or "BPH Procedures")

