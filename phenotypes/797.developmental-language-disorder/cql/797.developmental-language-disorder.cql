/**
 * PheKB Phenotype
 *
 * Name : Developmental Language Disorder
 * ID   : 797
 * Url  : https://phekb.org/node/797
 */
library "797.developmental-language-disorder" version '1.0.0'

using FHIR version '4.0.0'

include FHIRHelpers version '4.0.0' called FHIRHelpers
include PhEMAHelpers version '1.0.0' called PhEMAHelpers

valueset "Developmental Language Disorder Diagnoses": '797.developmental-language-disorder-diagnoses'
valueset "Developmental Language Disorder Exclusion Diagnoses": '797.developmental-language-disorder-exclusion-diagnoses'
valueset "DLD Category 1 Diagnoses": '797.dld-category-1-diagnoses'
valueset "DLD Category 2 Diagnoses": '797.dld-category-2-diagnoses'
valueset "DLD Category 3 Diagnoses": '797.dld-category-3-diagnoses'
valueset "DLD Category 4 Diagnoses": '797.dld-category-4-diagnoses'

context Patient

define "Has DLD Diagnosis":
    exists([Condition: "Developmental Language Disorder Diagnoses"])

define "Has DLD Exclusion Diagnosis":
    exists([Condition: "Developmental Language Disorder Exclusion Diagnoses"])

define "Has Category 1 or 2 Diagnosis":
    exists([Condition: "DLD Category 1 Diagnoses"])
        or
    exists([Condition: "DLD Category 2 Diagnoses"])

define "Has Category 3 or 4 Diagnosis":
    exists([Condition: "DLD Category 3 Diagnoses"])
        or
    exists([Condition: "DLD Category 4 Diagnoses"])    

define "Case":
    "Has DLD Diagnosis"
        and
    (not "Has DLD Exclusion Diagnosis")
        and
    (AgeInYears() < 18)
        and
    "Has Category 1 or 2 Diagnosis"
        and
    (not "Has Category 3 or 4 Diagnosis")
