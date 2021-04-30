/**
 * PheKB Phenotype
 *
 * Name : Bone scan utilization
 * ID   : 1197
 * Url  : https://phekb.org/node/1197
 */
library "1197.bone-scan-utilization" version '1.0.0'

using FHIR version '4.0.0'

include FHIRHelpers version '4.0.0' called FHIRHelpers

include PhEMAHelpers version '1.0.0' called PhEMAHelpers
include PhEMAProstate version '1.0.0' called PhEMAProstate
include PhEMATemporal version '1.0.0' called PhEMATemporal

valueset "Prostate Cancer Diagnoses": '2.16.840.1.113762.1.4.1116.307'
valueset "Bone Scan Procedures": '1197.bone-scan-codes'
valueset "Surgery Procedures": '1197.surgery-procedures'

context Patient

define "Has Bone Scan Before First Treatment":
		exists([Procedure: "Bone Scan Procedures"] P
				where start of PhEMATemporal."Normalize Interval"( P.performed ) before PhEMAProstate."First Prostate Cancer Treatment Date")

define "Has Two Or More Encounters Before First Treatment":
    exists(PhEMAProstate."First Prostate Cancer Treatment Date")
      and
    PhEMAHelpers."Number Of Encounters Before Date"(
        [Encounter],
        PhEMAProstate."First Prostate Cancer Treatment Date"
    ) >= 2

define "Has Prostate Cancer Diagnoses":
    exists([Condition: "Prostate Cancer Diagnoses"])

define "Has Surgical Procedure Before First Treatment":
		exists([Procedure: "Surgery Procedures"] P
				where start of PhEMATemporal."Normalize Interval"( P.performed ) before PhEMAProstate."First Prostate Cancer Treatment Date")

define "In Base Population":
    PhEMAHelpers."Is Male"
        and
    // The phenotype definition text mentions both ">=35" and ">35"
    AgeInYears() >= 35

define "Case":
    "In Base Population"
        and
    "Has Prostate Cancer Diagnoses"
        and
    "Has Two Or More Encounters Before First Treatment"
        and
    "Has Bone Scan Before First Treatment"
        and
    "Has Surgical Procedure Before First Treatment"

