/**
 * PheKB Phenotype
 *
 * Name : Autism
 * ID   : 162
 * Url  : https://phekb.org/node/162
 */
library "162.autism" version '1.0.0'

using FHIR version '4.0.0'

valueset "Autism Spectrum Diagnoses": '162.autism-spectrum-dx'
valueset "Autism Exclusion Diagnoses": '162.autism-exclusion-dx'

context Patient

define "Has Autism Diagnosis":
    exists([Condition: "Autism Spectrum Diagnoses"])

define "Has Autism Exclusion Diagnosis":
    exists([Condition: "Autism Exclusion Diagnoses"])

define "Case":
    "Has Autism Diagnosis"
        and
    (not "Has Autism Exclusion Diagnosis")
