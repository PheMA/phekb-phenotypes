/**
 * PheKB Phenotype
 *
 * Name : Drug Induced Liver Injury
 * ID   : 135
 * Url  : https://phekb.org/node/135
 */
library "135.drug-induced-liver-injury" version '1.0.0'

using FHIR version '4.0.0'

include FHIRHelpers version '4.0.0' called FHIRHelpers
include PhEMAHelpers version '1.0.0' called PhEMAHelpers

valueset "Acute Liver Injury Diagnoses": '135.acute-liver-injury-dx'
valueset "Total Bilirubin Labs": '135.total-bilirubin'
valueset "Alanine Aminotransferase Labs": '135.alt'
valueset "Alanine Phosphatase Labs": '135.alp'
valueset "Chronic Liver Injury Diagnoses": '135.chronic-liver-injury-dx'
valueset "Liver Toxicity Medications (Expanded List)": '135.liver-toxicity-meds-expanded-list'
valueset "Exclusionary Diagnoses": '135.exclusionary-dx'
valueset "Exclusionary Procedures": '135.exclusionary-procs'

context Patient

// Note 1 Baseline population is institution specific
define "In Base Population":
    // Included as most eMERGE implementers would have used this criteria
    PhEMAHelpers."In Biobank"
      and
    AgeInYears() > 1

////////////////////////////////////////////////////////////////////////////////
//
// ALP
//
////////////////////////////////////////////////////////////////////////////////

define "ALP At Least 2x ULN":
    [Observation: "Alanine Phosphatase Labs"] ALP
        where
            ALP.value as Quantity
                >=
            2 * System.Quantity { value: 120.0, unit: 'U/L' }

define "Has ALP At Least 2x ULN":
    exists("ALP At Least 2x ULN")

////////////////////////////////////////////////////////////////////////////////
//
// ALT
//
////////////////////////////////////////////////////////////////////////////////

define function "ALT At Least Multiple x ULN"(
    multiple Integer
):
    [Observation: "Alanine Aminotransferase Labs"] ALT
        where
            ALT.value as Quantity
                >=
            multiple * System.Quantity { value: 45.0, unit: 'U/L' }

define function "Has ALT At Least Multiple x ULN"(
    multiple Integer
):
    exists("ALT At Least Multiple x ULN"(multiple))

////////////////////////////////////////////////////////////////////////////////
//
// Bilirubin
//
////////////////////////////////////////////////////////////////////////////////

define "Bilirubin At Least 2x ULN":
    [Observation: "Total Bilirubin Labs"] B
        where
            B.value as Quantity
                >=
            2 * System.Quantity { value: 40.0, unit: 'umol/L' }

define "Has Bilirubin At Least 2x ULN":
    exists("Bilirubin At Least 2x ULN")

////////////////////////////////////////////////////////////////////////////////
//
// Index Dates
//
////////////////////////////////////////////////////////////////////////////////

define "Medications Index Date":
    PhEMAHelpers."Earliest Date"(
        [MedicationRequest: "Liver Toxicity Medications (Expanded List)"] M
            return PhEMAHelpers."Effective Date"(M)
    )

define "Acute Liver Injury Diagnosis Index Date":
    PhEMAHelpers."Earliest Date"(
        [Condition: "Acute Liver Injury Diagnoses"] C
            return PhEMAHelpers."Effective Date"(C)
    )

////////////////////////////////////////////////////////////////////////////////
//
// Phentotype Criteria
//
////////////////////////////////////////////////////////////////////////////////

// A1. Diagnosed with liver injury
define "Has Acute Liver Injury Diagnosis":
    exists([Condition: "Acute Liver Injury Diagnoses"])

// A2. Exposure to drug within 3mo of dx
define "Has Drug Exposure In 3 Month Window":
    exists(
        [MedicationRequest: "Liver Toxicity Medications (Expanded List)"] M
            where
                duration in months between
                    PhEMAHelpers."Effective Date"(M)
                        and
                    "Acute Liver Injury Diagnosis Index Date"
                <= 3 // Interpreting "within 3 months" as <= 3 months
    )

// B. Chronic liver injury?
define "Has Disqualifying Chronic Liver Injury":
    // The algorithm says to "Consider chronicity" for chronic liver injury.  Because this
    // is not further defined, we are using the qualification of any diagnosis code as
    // being sufficient.
    exists([Condition: "Chronic Liver Injury Diagnoses"])

// C[1-3]. Reaches DILI threshold
define "Qualifies As Drug Induced Liver Injury":
    // NOTE: The definitions on pages 4 and 6 differ. Page 6 matches
    //       the flow chart, so that's what I'm using here
    "Has ALP At Least 2x ULN"
        or
    "Has ALT At Least Multiple x ULN"(3)
        or
    "Has Bilirubin At Least 2x ULN"

// Assess labs after drug exposure
define "Has Elevated Labs after Drug Exposure":
  "ALP At Least 2x ULN Within 6mo After Medications"
      or
  "ALT At Least 5x ULN Within 6mo After Medications"
      or
  (
    "ALT At Least 3x ULN Within 6mo After Medications"
        and
    "Bilirubin At Least 2x ULN Within 6mo After Medications"
  )


// C4. ALP >= 2x ULN within 6mo after meds
define "ALP At Least 2x ULN Within 6mo After Medications":
    exists(
        ("ALP At Least 2x ULN") ALP
            where
                duration in months between
                    "Medications Index Date"
                        and
                    PhEMAHelpers."Effective Date"(ALP)
                <= 6 // Interpreting "within 6 months" as <= 6 months
    )

// C5. ALT >= 5x ULN within 6mo after meds
define "ALT At Least 5x ULN Within 6mo After Medications":
    exists(
        ("ALT At Least Multiple x ULN"(5)) ALT
            where
                duration in months between
                    "Medications Index Date"
                        and
                    PhEMAHelpers."Effective Date"(ALT)
                <= 6 // Interpreting "within 6 months" as <= 6 months
    )

// C6. ALT >= 3x ULN within 6mo after meds
define "ALT At Least 3x ULN Within 6mo After Medications":
    exists(
        ("ALT At Least Multiple x ULN"(3)) ALT
            where
                duration in months between
                    "Medications Index Date"
                        and
                    PhEMAHelpers."Effective Date"(ALT)
                <= 6 // Interpreting "within 6 months" as <= 6 months
    )

// C7. Bilirubin >= 2 ULN within 6mo after meds
define "Bilirubin At Least 2x ULN Within 6mo After Medications":
    exists(
        ("Bilirubin At Least 2x ULN") B
            where
                duration in months between
                    "Medications Index Date"
                        and
                    PhEMAHelpers."Effective Date"(B)
                <= 6 // Interpreting "within 6 months" as <= 6 months
    )

// NOTE 14 - Evaluate if patient lab values were elevated within 1 month prior
//  to medication administration
define "Has Elevated Labs before Drug Exposure":
    "ALP At Least 2x ULN Within 1mo Prior Medications"
        or
    "ALT At Least 3x ULN Within 1mo Prior Medications"
        or
    "Bilirubin At Least 2x ULN Within 1mo Prior Medications"

// C8. ALP >= 2x ULN within 1mo prior to med
define "ALP At Least 2x ULN Within 1mo Prior Medications":
    exists(
        ("ALP At Least 2x ULN") ALP
            where
                duration in months between
                    PhEMAHelpers."Effective Date"(ALP)
                        and
                    "Medications Index Date"
                >= 1 // Interpreting "within 1 month" as >= 1 month
    )

// C9. ALT >= 3x ULN within 1mo prior to med
define "ALT At Least 3x ULN Within 1mo Prior Medications":
    exists(
        ("ALT At Least Multiple x ULN"(3)) ALT
            where
                duration in months between
                    PhEMAHelpers."Effective Date"(ALT)
                        and
                    "Medications Index Date"
                >= 1 // Interpreting "within 1 month" as >= 1 month
    )

// C10. Bilirubin >= 2x ULN within 1mo prior to med
define "Bilirubin At Least 2x ULN Within 1mo Prior Medications":
    exists(
        ("Bilirubin At Least 2x ULN") B
            where
                duration in months between
                    PhEMAHelpers."Effective Date"(B)
                        and
                    "Medications Index Date"
                >= 1 // Interpreting "within 1 month" as >= 1 month
    )

// D. Disqualifying diagnoses
define "Has Disqualifying Diagnosis":
    // In note 15, "chronic liver disease" is included, even though is dealt
    // with in (B). Although it seems unnecessary, we will include here to follow
    // the phenotype definition as written.
    exists([Condition: "Chronic Liver Injury Diagnoses"])
        or
    exists([Condition: "Exclusionary Diagnoses"])
        or
    exists([Procedure: "Exclusionary Procedures"])

define "Case":
    "In Base Population"
        and
    "Has Acute Liver Injury Diagnosis"
        and
    "Qualifies As Drug Induced Liver Injury"
        and
    (not "Has Disqualifying Chronic Liver Injury")
        and
    "Has Drug Exposure In 3 Month Window"
        and
    "Has Elevated Labs after Drug Exposure"
        and
    (not "Has Elevated Labs before Drug Exposure")
        and
    (not "Has Disqualifying Diagnosis")
