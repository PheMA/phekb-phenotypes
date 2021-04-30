/**
 * PheKB Phenotype
 *
 * Name : Red Blood Cell Indices
 * ID   : 17
 * Url  : https://phekb.org/node/17
 */
library "17.red-blood-cell-indices" version '1.0.0'

using FHIR version '4.0.0'

include FHIRHelpers version '4.0.0' called FHIRHelpers
include PhEMAHelpers version '1.0.0' called PhEMAHelpers

valueset "Red Blood Cell Labs": '17.red-blood-cell-labs'
valueset "ESR Labs": '17.esr-labs'
valueset "Medications Affecting Red Blood Cells": '17.red-blood-cell-meds'
valueset "Anemias and Other Hematologic Disorders": '17.R1.anemias-and-other-hematologic-disorders'
valueset "Spleen Disorders": '17.R2.spleen-disorders'
valueset "Hereditary Anemias": '17.IV.hereditary-anemias'
valueset "Hematologic Malignancies": '17.Ia.hematologic-malignancies'
valueset "Solid Organ Malignancies": '17.Ia.solid-organ-malignancies'
valueset "III Hepatic Disorders": '17.III.hepaptic-disorders'
valueset "Inflammatory Bowel Disease": '17.E2.inflammatory-bowel-disease'
valueset "Autoimmune/Connective Tissue Disorders": '17.E1.autoimmune-connective-tissue-disorders'
valueset "R6 Long Term Oxygen Therapy": '17.R6.long-term-oxygen-therapy'
valueset "E3 Infectuous Diseases": '17.E3.infectuous-diseases'
valueset "II Bone Marrow And Organ Transplants": '17.II.bone-marrow-and-organ-transplant-procedures'
valueset "Ib Chemotherapy": '17.Ib.chemotherapy'
valueset "IV Anesthesia For Blood Loss And Anemia": '17.VI.anesthesia-for-blood-loss-and-anemia'

/**
    NOTE: These are actually for flags, not exclusions, so they aren't needed

valueset "R3 Hepaptic Disorders": '17.R3.hepaptic-disorders'
valueset "R4 Renal Disorders": '17.R4.renal-disorders'
valueset "R5 Renal Procedures": '17.R5.renal-procedures'
*/

context Patient

/**
    If the patient had chemo in year 4 or 5 a hematologic or solid-organ malignancy
    return the effective date of that malignancy. All samples after this date
    should be excluded
*/
define "Index Date For Chemo In Year 4 or 5":
    PhEMAHelpers."Earliest Date"(
        PhEMAHelpers."Effective Dates"(
            (
                [Condition: "Hematologic Malignancies"] 
                    union
                [Condition: "Solid Organ Malignancies"]
            ) C
                where exists(
                    ["Procedure": "Ib Chemotherapy"] P
                        where PhEMAHelpers."Effective Date"(P) in
                            Interval[PhEMAHelpers."Effective Date"(C) + 3 years,
                                     PhEMAHelpers."Effective Date"(C) + 5 years]
                )
        )
    )

/**
    Exclude patient the sample occurs after them having chemo in year 4 or 5
    after a hematologic or solid-organ malignancy
*/
define function "Exclusion Ib" (sample FHIR.Observation):
    if "Index Date For Chemo In Year 4 or 5" is not null then
        PhEMAHelpers."Effective Date"(sample) after "Index Date For Chemo In Year 4 or 5"
    else
        false

define "Earliest Hematologic Or Solid Organ Malignancy Date":
    PhEMAHelpers."Effective Date"(
        PhEMAHelpers."Earliest"(
            [Condition: "Hematologic Malignancies"] 
                    union
            [Condition: "Solid Organ Malignancies"]
        )
    )

/**
    Exclude the sample if it is in the [-2y, +5y] window relative to the first
    hematologic or solid-organ malignancy
*/
define function "Exclusion Ia" (sample FHIR.Observation):
    if "Earliest Hematologic Or Solid Organ Malignancy Date" is null then
        false
    else
        PhEMAHelpers."Effective Date"(sample) in Interval[
            "Earliest Hematologic Or Solid Organ Malignancy Date" - 2 years,
            "Earliest Hematologic Or Solid Organ Malignancy Date" + 5 years
        ]

define function "Exclusion I" (sample FHIR.Observation):
    "Exclusion Ia"(sample) or "Exclusion Ib"(sample)

/**
    Exclude patients who had a transplant in the three years
    prior to the sample
*/
define function "Exclusion II" (sample FHIR.Observation):
    exists(
        [Procedure: "II Bone Marrow And Organ Transplants"] P
            where PhEMAHelpers."Effective Date"(P) in
                Interval[PhEMAHelpers."Effective Date"(sample) - 3 years,
                         PhEMAHelpers."Effective Date"(sample)]
    )

/**
    Exclude patient if the sample occurred after a cirrhosis
    diagnosis
*/
define function "Exclusion III" (sample FHIR.Observation):
    exists(
        [Condition: "III Hepatic Disorders"] C
            where PhEMAHelpers."Effective Date"(C) before PhEMAHelpers."Effective Date"(sample)
    )

/**
    Exclude all patients with hereditary anemias
*/
define "Exclusion IV":
    exists(
        [Condition: "Hereditary Anemias"]
    )

/**
    Exclude patients who were takings drugs that could impact RBC within
    two months of the sample date
*/
define function "Exclusion V" (sample FHIR.Observation):
    exists(
        [MedicationRequest: "Medications Affecting Red Blood Cells"] M
            where PhEMAHelpers."Effective Date"(M) in
                Interval[PhEMAHelpers."Effective Date"(sample) - 2 months,
                         PhEMAHelpers."Effective Date"(sample) + 2 months]    
    )

/**
    Exclude patients who had their sample taken up to three months
    after a surgery
*/
define function "Exclusion VI" (sample FHIR.Observation):
    exists(
        [Procedure: "IV Anesthesia For Blood Loss And Anemia"] P
            where PhEMAHelpers."Effective Date"(sample) in
                Interval[PhEMAHelpers."Effective Date"(P),
                         PhEMAHelpers."Effective Date"(P) + 3 months]    
    )

define function "Common Exclusions" (sample FHIR.Observation):
    "Exclusion I"(sample)
        or
    "Exclusion II"(sample)
        or
    "Exclusion III"(sample)
        or
    "Exclusion IV"
        or
    "Exclusion V"(sample)
        or
    "Exclusion VI"(sample)

/**
    NOTE: These are not actually exclusions, but "flags" used for later analysis,
          so they do not need to be included in the "Case" definition

define function "Exclusion R1" (sample FHIR.Observation):
    false

define function "Exclusions R2-R6" (sample FHIR.Observation):
    false

define function "RBC Exclusions" (sample FHIR.Observation):
    "Exclusion R1"(sample)
        or
    "Exclusions R2-R6"(sample)
*/

/**
    Has a valid RBC lab that isn't subject to any of the common
    or RBC exclusions
*/
define "RBC Candidate":
    exists(
        [Observation: "Red Blood Cell Labs"] O
            where not "Common Exclusions"(O)
    )

define "Earliest Autoimmune, Connective Tissue, IBD Date":
    PhEMAHelpers."Effective Date"(
        PhEMAHelpers."Earliest"(
            [Condition: "Autoimmune/Connective Tissue Disorders"]
                union
            [Condition: "Inflammatory Bowel Disease"]
        )
    )

/**
    Exclude patients with with autoimmune, connective tissue, and inflammatory 
    bowel disorders in the [-2yr, +5yr] interval relative to the sample
*/
define function "Exclusion E1-E2" (sample FHIR.Observation):
    if "Earliest Autoimmune, Connective Tissue, IBD Date" is null then
        false
    else
        PhEMAHelpers."Effective Date"(sample) in Interval[
            "Earliest Autoimmune, Connective Tissue, IBD Date" - 2 years,
            "Earliest Autoimmune, Connective Tissue, IBD Date" + 5 years
        ]

define "Earliest Infectuous Disease Date":
    PhEMAHelpers."Effective Date"(
        PhEMAHelpers."Earliest"([Condition: "E3 Infectuous Diseases"])
    )

define function "Exclusion E3" (sample FHIR.Observation):
    if "Earliest Infectuous Disease Date" is null then
        false
    else
        PhEMAHelpers."Effective Date"(sample) in Interval[
            "Earliest Infectuous Disease Date" - 2 years,
            "Earliest Infectuous Disease Date" + 2 years
        ]

define function "ESR Exclusions" (sample FHIR.Observation):
    "Exclusion E1-E2"(sample) or "Exclusion E3"(sample)

define "ESR Candidate":
        exists(
        [Observation: "ESR Labs"] O
            where (
                (not "Common Exclusions"(O))
                    and
                (not "ESR Exclusions"(O))
            )
    )

define "Case":
    "RBC Candidate" or "ESR Candidate"
