/**
 * PheKB Phenotype
 *
 * Name : Asthma Response To Inhaled Steroids
 * ID   : 115
 * Url  : https://phekb.org/node/115
 */
library "115.asthma-response-to-inhaled-steroids" version '1.0.0'

using FHIR version '4.0.0'

include FHIRHelpers version '4.0.0' called FHIRHelpers
include PhEMAHelpers version '1.0.0' called PhEMAHelpers
include PhEMAMedications version '1.0.0' called PhEMAMedications

valueset "Asthma Diagnoses": '115.asthma-dx'
valueset "Asthma ICS Exclusionary Diagnoses": '115.asthma-exclusionary-dx'
valueset "Asthma Medications (Any Route)": '115.asthma-meds-any-route'
valueset "Asthma Medications (Exclude Nasal Route)": '115.asthma-meds-no-nasal'
valueset "Asthma Medications (Exclude Nasal and Topical)": '115.asthma-meds-exclude-nasal-topical'
valueset "Asthma Medications (Require Inhaled, Topical, IV, Intraarticual, IM, Nasal)": '115.asthma-meds-required-routes'
valueset "Corticosteroid Medications": '115.corticosteroid-medications-meds' 
valueset "Acute Exacerbation Or Wheezing Diagnoses": '115.acute-exacerbation-or-wheezing-dx'

codesystem "ActEncounterCode": 'http://terminology.hl7.org/ValueSet/v3-ActEncounterCode'

code "Inpatient Encounter": 'IMP' from "ActEncounterCode"

context Patient

define "Has Qualifying Asthma Diagnoses":
    exists(
        [Condition: "Asthma Diagnoses"] C1
            where
                exists(
                    [Condition: "Asthma Diagnoses"] C2
                        where
                            // Make sure they are on different days 
                            ToDate(PhEMAHelpers."Effective Date"(C1))
                                != ToDate(PhEMAHelpers."Effective Date"(C2))
                            and
                                "Correct Age"(C2)
                )
                    and
                "Correct Age"(C1)
    )

define function "Correct Age"(
    dx FHIR.Condition
):
    AgeInYearsAt(PhEMAHelpers."Effective Date"(dx)) in
        Interval[4, 35]   

define function "Correct Age"(
    med FHIR.MedicationRequest
):
    AgeInYearsAt(PhEMAHelpers."Effective Date"(med)) in
        Interval[4, 35]   

define "Has Exclusionary Diagnosis":
    exists([Condition: "Asthma ICS Exclusionary Diagnoses"])

define "Has Qualifying Any Route Medication":
    exists(
        [MedicationRequest: "Asthma Medications (Any Route)"] M
            where
                "Correct Age"(M)
    )

define "Has Qualifying Non-Nasal Medication":
    exists(
        [MedicationRequest: "Asthma Medications (Exclude Nasal Route)"] M
            where
                "Correct Age"(M)
                    and
                PhEMAMedications."Medication Does Not Have Route"(
                    M,
                    PhEMAMedications."Nasal use"
                )
    )

define "Has Qualifying Non-Nasal, Non-Topical Medication":
    exists(
        [MedicationRequest: "Asthma Medications (Exclude Nasal and Topical)"] M
            where
                "Correct Age"(M)
                    and
                PhEMAMedications."Medication Does Not Have Route"(
                    M,
                    PhEMAMedications."Nasal use"
                )
                    and
                PhEMAMedications."Medication Does Not Have Route"(
                    M,
                    PhEMAMedications."Topical route"
                )
    )

define "Has Qualifying Required Route Medication":
    exists(
        [MedicationRequest: "Asthma Medications (Require Inhaled, Topical, IV, Intraarticual, IM, Nasal)"] M
            where
                "Correct Age"(M)
                    and
                PhEMAMedications."Medication Has Any Route"(
                    M,
                    {
                        PhEMAMedications."Respiratory tract route (Inhaled)",
                        PhEMAMedications."Topical route",
                        PhEMAMedications."Intravenous use (IV)",
                        PhEMAMedications."Intra-articular route",
                        PhEMAMedications."Intramuscular use (IM)",
                        PhEMAMedications."Nasal use"
                    }    
                )
    )

define "Has Qualifying Medication":
    "Has Qualifying Any Route Medication"
        or
    "Has Qualifying Non-Nasal Medication"
        or
    "Has Qualifying Non-Nasal, Non-Topical Medication"
        or
    "Has Qualifying Required Route Medication"

define "Asthma ICS":
    "Has Qualifying Asthma Diagnoses"
        and
    (not "Has Exclusionary Diagnosis")
        and
    "Has Qualifying Medication"

define function "Exacerbation Or Wheezing During Encounter"(
    enc FHIR.Encounter
):
    exists(
        [Condition: "Acute Exacerbation Or Wheezing Diagnoses"] C
            where
                if enc.period.end is null then
                    // The hospitalization is ongoing
                    FHIRHelpers.ToDateTime(C.onset) after enc.period.start
                else
                    FHIRHelpers.ToDateTime(C.onset) after enc.period.start
                        and
                    FHIRHelpers.ToDateTime(C.onset) before enc.period.end               
    )

define "TEST":
    [MedicationRequest] M
        return Tuple {
            med: M,
            matches: PhEMAMedications."Dose Unit Matches Regex"(M, 'mg')
        }    

define function "Qualifying Steroids During Encounter"(
    enc FHIR.Encounter
):
    exists(
        [MedicationRequest: "Corticosteroid Medications"] M
            where
                (
                    if enc.period.end is null then
                        // The hospitalization is ongoing
                        M.authoredOn after enc.period.start
                    else
                        M.authoredOn after enc.period.start
                            and
                        M.authoredOn before enc.period.end
                )
                    and
                (not PhEMAMedications."Dose Unit Matches Regex"(M, '%'))
                    and
                (
                    (
                        PhEMAMedications."Medication Has Any Route"(
                            M,
                            {
                                PhEMAMedications."Intravenous use (IV)",
                                PhEMAMedications."Intramuscular use (IM)",
                                PhEMAMedications."Oral use (PO)"
                            }
                        )
                            or
                        // Since FHIR requires UCUM units, milligrams can only
                        // be expressed in one way
                        PhEMAMedications."Dose Unit Matches Regex"(M, 'mg')
                    )
                        and
                    (
                        PhEMAMedications."Medication Does Not Have Route"(M, PhEMAMedications."Nasal use")
                            and
                        PhEMAMedications."Medication Does Not Have Route"(M, PhEMAMedications."Topical route")
                            and
                        PhEMAMedications."Medication Does Not Have Route"(M, PhEMAMedications."Respiratory tract route (Inhaled)")
                    )
                )
    )


define "Inpatient Hospitalization":
    exists(
        [Encounter: class in "Inpatient Encounter"] E
            where
                "Exacerbation Or Wheezing During Encounter"(E)
                    and
                "Qualifying Steroids During Encounter"(E)
    )

define "Asthma Exacerbation":
    // Emergency hospitalization are defined using the presense of notes
    "Inpatient Hospitalization"

define "Case":
    "Asthma ICS"
        and
    "Asthma Exacerbation"
