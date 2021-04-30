/**
 * PheKB Phenotype
 *
 * Name : Chronic Autoimmune Hypothyroidism (presumptive Hashimoto’s hypothyroidism)
 * ID   : 14
 * Url  : https://phekb.org/node/14
 */
library "14.hypothyroidism" version '1.0.0'

using FHIR version '4.0.0'

include FHIRHelpers version '4.0.0' called FHIRHelpers
include PhEMAHelpers version '1.0.0' called PhEMAHelpers

valueset "Hypothyroidism Diagnosis": '14.hypothyroidism-dx'
valueset "TSH Labs": '14.tsh-labs'
valueset "FT4 Labs": '14.ft4-labs'
valueset "Anti-Thyroglobulin Labs": '14.anti-thyroglobulin-ab'
valueset "Anti-Thyroperoxidase Labs": '14.anti-thyroperoxidase'
valueset "Pregnancy Diagnoses": '14.pregnancy-diagnoses'
valueset "Contrast Exposure Procedures": '14.contrast-exposure-procedures'
valueset "Pregnancy Labs": '14.pregnancy-labs'
valueset "Thyroid Replacement Medications": '14.thyroid-replacement-meds'
valueset "Secondary Hypothyroidism Diagnoses": '14.secondary-hypothyroidism-diagnoses'
valueset "Radiation Therapy Procedures": '14.radiation-therapy-procedures'
valueset "Thyroidectomy Procedures": '14.thyroidectomy-procedures'
valueset "Other Thyroid Diseases Diagnosis": '14.thyroid-disease-exclusions'
valueset "Thyroid-Altering Medications": '14.thyroid-altering-meds'

context Patient

/**
  The following two Effective Date functions should ideally live in the PhEMA
  library, but were causing errors when running.  Leaving as local functions
  for now.
*/
define function "Effective Date" (
  c Choice<FHIR.Observation,FHIR.MedicationRequest,FHIR.Condition>
):
    if c is FHIR.Observation then
        PhEMAHelpers."Effective Date"(c as FHIR.Observation)
    else if c is FHIR.MedicationRequest then
        PhEMAHelpers."Effective Date"(c as FHIR.MedicationRequest)
    else
        PhEMAHelpers."Effective Date"(c as FHIR.Condition)

define function "Effective Date" (
  c Choice<FHIR.Observation,FHIR.Condition>
):
    if c is FHIR.Observation then
        PhEMAHelpers."Effective Date"(c as FHIR.Observation)
    else
        PhEMAHelpers."Effective Date"(c as FHIR.Condition)

/**
    Exclude lab results and medications that fall within 6 months
    before a pregnancy to one year after.
*/
define function "Pregnancy Exclusion" (sample Choice<FHIR.Observation,FHIR.MedicationRequest,FHIR.Condition>):
    exists(
        (
            [Condition: "Pregnancy Diagnoses"]
                union
            [Observation: "Pregnancy Labs"]
        ) P
            where "Effective Date"(sample) in
                Interval["Effective Date"(P) - 6 months,
                         "Effective Date"(P) + 1 year]
    )

/**
    Exclude lab results and medications that fall up to 6 weeks after
    a procedure that has a contrast exposure.
*/
define function "Contrast Exposure Exclusion" (sample Choice<FHIR.Observation,FHIR.MedicationRequest>):
    exists(
        [Procedure: "Contrast Exposure Procedures"] P
            where "Effective Date"(sample) in
                Interval[PhEMAHelpers."Effective Date"(P),
                         PhEMAHelpers."Effective Date"(P) + 6 weeks]
    )

/**
    Exclusion criteria that apply to laboratory results and medications
*/
define function "Time Dependent Exclusions" (sample Choice<FHIR.Observation,FHIR.MedicationRequest>):
    "Pregnancy Exclusion"(sample)
        or
    "Contrast Exposure Exclusion"(sample)

/**
    Has an order for a thyroid replacement medication, which doesn't
    fall within any of the specified exclusion windows.
*/
define "Thyroid replacement medication use":
    [MedicationRequest: "Thyroid Replacement Medications"] M
        where not "Time Dependent Exclusions"(M)

define "Abnormal TSH Labs":
    [Observation: "TSH Labs"] O
        where not "Time Dependent Exclusions"(O)
          and O.value > System.Quantity { value: 5, unit: 'U/mL' }

define "Abnormal FT4 Labs":
    [Observation: "FT4 Labs"] O
        where not "Time Dependent Exclusions"(O)
          and O.value < System.Quantity { value: 0.5, unit: 'ng/dL' }

define "Abnormal Anti-Thyroglobulin Labs":
    [Observation: "Anti-Thyroglobulin Labs"] O
        where not "Time Dependent Exclusions"(O)
          and O.value = 'Positive'

define "Abnormal Anti-Thyroperoxidase Labs":
    [Observation: "Anti-Thyroperoxidase Labs"] O
        where not "Time Dependent Exclusions"(O)
          and O.value = 'Positive'

/**
    Has an abnormal TSH or FT4 lab, which doesn't fall within any
    of the specified exclusion windows.
*/
define "Abnormal TSH or FT4 Labs":
    "Abnormal TSH Labs"
        union
    "Abnormal FT4 Labs"
        union
    // The phenotype definition included these two lab types under
    // the broader "TSH / FT4" lab category, even if they aren't named
    // the same.
    "Abnormal Anti-Thyroglobulin Labs"
        union
    "Abnormal Anti-Thyroperoxidase Labs"

define "Thyroid altering medication":
    exists([MedicationRequest: "Thyroid-Altering Medications"])

define "Other thyroid diseases":
    exists([Condition: "Other Thyroid Diseases Diagnosis"])

define "First hypothyroidism diagnosis":
    PhEMAHelpers."Earliest"([Condition: "Hypothyroidism Diagnosis"])

/**
    Only consider if the radiation therapy precedes
    diagnosis of hypothyroidism
*/
define "Radiation therapy before hypothyroidism diagnosis":
    [Procedure: "Radiation Therapy Procedures"] P
        where PhEMAHelpers."Effective Date"(P) before
            PhEMAHelpers."Effective Date"("First hypothyroidism diagnosis")

define "Post surgical or post-radiation hypothyroidism":
    exists("Radiation therapy before hypothyroidism diagnosis")
        or
    exists([Procedure: "Thyroidectomy Procedures"])

define "Secondary causes of hypothyroidism":
    exists([Condition: "Secondary Hypothyroidism Diagnoses"])

define "Date of earliest lab or med":
    PhEMAHelpers."Earliest Date"(flatten {
        PhEMAHelpers."Effective Dates"("Abnormal TSH or FT4 Labs"),
        PhEMAHelpers."Effective Dates"("Thyroid replacement medication use")
    })

define "Date of latest lab or med":
    PhEMAHelpers."Latest Date"(flatten {
        PhEMAHelpers."Effective Dates"("Abnormal TSH or FT4 Labs"),
        PhEMAHelpers."Effective Dates"("Thyroid replacement medication use")
    })

define "Has sufficient time between labs and meds":
    // Use Coalesce to handle when 0 labs/meds are available and we have a null result
    // in the months calculation
    Coalesce(
        (months between "Date of earliest lab or med" and "Date of latest lab or med"),
        0  // Default to 0 months if null so this define will then always return false
    ) >= 3

define "Has thyroid replacement medication use":
    exists("Thyroid replacement medication use")

define "Has abnormal TSH or FT4 lab":
    exists("Abnormal TSH or FT4 Labs")

define "Has hypothyroidism diagnosis":
    exists([Condition: "Hypothyroidism Diagnosis"] C
        where not "Pregnancy Exclusion"(C))

define "Case":
    ("Has hypothyroidism diagnosis" or "Has abnormal TSH or FT4 lab")
        and
    "Has thyroid replacement medication use"
        and
    "Has sufficient time between labs and meds"
        and
    not (
        "Secondary causes of hypothyroidism"
            or
        "Post surgical or post-radiation hypothyroidism"
            or
        "Other thyroid diseases"
            or
        "Thyroid altering medication"
    )
