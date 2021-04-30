/**
 * PheKB Phenotype
 *
 * Name : Urinary incontinence
 * ID   : 1404
 * Url  : https://phekb.org/node/1404
 */
library "1404.urinary-incontinence" version '1.0.0'

using FHIR version '4.0.0'

include FHIRHelpers version '4.0.0' called FHIRHelpers
include PhEMAHelpers version '1.0.0' called PhEMAHelpers
include PhEMAProstate version '1.0.0' called PhEMAProstate

// Reusing value sets from 1197
valueset "Prostate Cancer Diagnoses": '2.16.840.1.113762.1.4.1116.307'

context Patient

define "Has Two Or More Encounters Before First Treatment":
    exists(PhEMAProstate."First Prostate Cancer Treatment Date")
      and
    PhEMAHelpers."Number Of Encounters Before Date"(
        [Encounter],
        PhEMAProstate."First Prostate Cancer Treatment Date"
    ) >= 2

define "Has Prostate Cancer Diagnoses":
    exists([Condition: "Prostate Cancer Diagnoses"])

define "Has Prostate Cancer Treatment":
    exists(PhEMAProstate."First Prostate Cancer Treatment Date")

define "In Base Population":
    PhEMAHelpers."Is Male"
        and
    AgeInYears() >= 35

define "Case":
    "In Base Population"
        and
    "Has Prostate Cancer Diagnoses"
        and
    "Has Two Or More Encounters Before First Treatment"
        and
    // This seems duplicative because we identify the presence via "First Prostate Cancer
    // Treatment Date", but it is explicitly listed again because it's written this way
    // in the pseudocode.
    // Should we assume we can optimize and remove it, because that makes the most sense?
    "Has Prostate Cancer Treatment"

