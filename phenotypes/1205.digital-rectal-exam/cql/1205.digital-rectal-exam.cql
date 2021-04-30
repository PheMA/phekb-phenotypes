/**
 * PheKB Phenotype
 *
 * Name : Digital Rectal Exam
 * ID   : 1205
 * Url  : https://phekb.org/node/1205
 */
library "1205.digital-rectal-exam" version '1.0.0'

using FHIR version '4.0.0'

include FHIRHelpers version '4.0.0' called FHIRHelpers
include PhEMAHelpers version '1.0.0' called PhEMAHelpers
include PhEMAProstate version '1.0.0' called PhEMAProstate

// Reusing value sets from 1197
valueset "Prostate Cancer Diagnoses": '2.16.840.1.113762.1.4.1116.307'
// New value set specific to 1205
valueset "Digital Rectal Exam Procedures": '1205.digital-rectal-exam-codes'

context Patient

define function "Has DRE Up To 6 Months Before Treatment Date"(
    treatmentDate DateTime
):
    [Procedure: "Digital Rectal Exam Procedures"] P
        where P.performed in Interval(treatmentDate - 6 months, treatmentDate)

define "Has DRE Up To 6 Months Before First Treatment":
    exists("Has DRE Up To 6 Months Before Treatment Date"(
      PhEMAProstate."First Prostate Cancer Treatment Date"
    ))

define "Has Prostate Cancer Diagnoses":
    exists([Condition: "Prostate Cancer Diagnoses"])

define "In Base Population":
    PhEMAHelpers."Is Male"
        and
    AgeInYears() > 35

define "Case":
    "In Base Population"
        and
    "Has Prostate Cancer Diagnoses"
        and
    "Has DRE Up To 6 Months Before First Treatment"
