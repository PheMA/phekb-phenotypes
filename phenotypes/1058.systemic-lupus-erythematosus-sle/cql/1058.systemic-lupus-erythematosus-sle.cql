/**
 * PheKB Phenotype
 *
 * Name : Systemic Lupus Erythematosus
 * ID   : 1058
 * Url  : https://phekb.org/node/1058
 * 
 * The algorithm with the highest PPV at 95% in the training set and 91% in the
 * validation set was 3 or more counts of the SLE ICD-9 code, ANA positive (>= 1:40),
 * and ever use of both disease-modifying antirheumatic drugs and steroids, while
 * excluding individuals with systemic sclerosis and dermatomyositis ICD-9 codes
 *
 */
library "1058.systemic-lupus-erythematosus-sle" version '1.0.0'

using FHIR version '4.0.0'

include FHIRHelpers version '4.0.0' called FHIRHelpers
include PhEMAHelpers version '1.0.0' called PhEMAHelpers

valueset "System Lupus Erythematosus diagnoses": '1058.sle-diagnoses'
valueset "Anti-Nuclear Antibody Labs": '1058.ana-labs'
valueset "Disease Modifying Antirheumatic Drugs": '1058.dmard-drugs'
valueset "Corticosteroids": '1058.corticosteroids'
valueset "Systemic Sclerosis Diagnoses": '1058.systemic-sclerosis-diagnoses'
valueset "Dermatomyositis Diagnoses": '1058.dermatomyositis-diagnoses'

context Patient

define "Has Three Or More SLE Diagnoses":
    Count([Condition: "System Lupus Erythematosus diagnoses"]) >= 3

define "Has Positive ANA":
    exists(
        [Observation: "Anti-Nuclear Antibody Labs"] A
            where
                PhEMAHelpers.RatioToQuantity(FHIRHelpers.ToRatio(A.value as FHIR.Ratio))
                    >=
                PhEMAHelpers.RatioToQuantity(1:40)
    )

define "Has DMARD":
    exists([MedicationRequest: "Disease Modifying Antirheumatic Drugs"])

define "Has Steroids":
    exists([MedicationRequest: "Corticosteroids"])

define "Has Exclusion Diagnosis":
    exists([Condition: "Systemic Sclerosis Diagnoses"])
        or
    exists([Condition: "Dermatomyositis Diagnoses"])

define "Case":
    "Has Three Or More SLE Diagnoses"
        and
    "Has Positive ANA"
        and 
    "Has DMARD"
        and
    "Has Steroids"
        and
    (not "Has Exclusion Diagnosis")