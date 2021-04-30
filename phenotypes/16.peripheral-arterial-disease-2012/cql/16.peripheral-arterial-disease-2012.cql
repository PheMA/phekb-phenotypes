/**
 * PheKB Phenotype
 *
 * Name : Peripheral Arterial Disease (PAD)
 * ID   : 16
 * Url  : https://phekb.org/node/16
 */
library "16.peripheral-arterial-disease-2012" version '1.0.0'

using FHIR version '4.0.0'

include FHIRHelpers version '4.0.0' called FHIRHelpers
include PhEMAHelpers version '1.0.0' called PhEMAHelpers

valueset "Non-Atherosclerotic PAD Diagnosis": '16.non-atherosclerotic-pad-dx'
valueset "PAD Diagnosis": '16.pad-dx'
valueset "Lower Extremity Artery Angiography Procedure": '16.lower-extremity-artery-angiography'
valueset "Non Coronary Vessel Stent Procedure": '16.non-coronary-vessel-stent'
valueset "Ankle Brachial Index": '16.ankle-brachial-index'
valueset "Ankle Systolic Blood Pressure": '16.ankle-systolic-blood-pressure'
valueset "Lower Extremity Artery Surgery Procedure": '16.lower-extremity-surgery-vascular-interventions'
valueset "Alternate Reason for Lower Extremity Artery Surgery": '16.lower-extremity-alternate-surgery-reason'
valueset "Lower Extremity Amputation": '16.lower-extremitiy-amputation'
valueset "Non-Vascular Amputation": '16.non-vascular-amputation'
valueset "Claudication Meds": '16.claudication-meds'

context Patient

define "Has Abnormal Vascular Lab Measurements":
    exists([Observation: "Ankle Brachial Index"] ABI
        where ABI.value > 1.4)
          or
    exists([Observation: "Ankle Systolic Blood Pressure"] SBP
        where SBP.value > 255 'mm[Hg]')
    // An additional criterion: 'Ankle brachial index <0.9 at rest or post exercise'
    // cannot be modeled and is not included here

// Section 5: Use Of Medications For Claudication:
define "Has Medications for Claudication":
    if exists([MedicationRequest: "Claudication Meds"]) then 1
    else 0

// Section 4: NLP Of Radiology Reports
// Not implementing NLP criterion

define "Has lower extremity artery angiography and non coronary vessel stent":
    exists (
        [Procedure: "Lower Extremity Artery Angiography Procedure"] P1
            where exists(
                [Procedure: "Non Coronary Vessel Stent Procedure"] P2
                    where PhEMAHelpers."Effective Date"(P1) = PhEMAHelpers."Effective Date"(P2)
            )
    )

define "Has lower extremity artery surgical and percutaneous vascular interventions":
    exists([Procedure: "Lower Extremity Artery Surgery Procedure"])
        and
    not(exists([Condition: "Alternate Reason for Lower Extremity Artery Surgery"]))

define "Has lower extremity amputation":
    exists([Procedure: "Lower Extremity Amputation"])
        and
    not(exists([Condition: "Non-Vascular Amputation"]))

// Section 3: Procedure Codes Related To PAD
define "Has Procedure Codes for PAD":
    if "Has lower extremity artery angiography and non coronary vessel stent"
          or
      "Has lower extremity artery surgical and percutaneous vascular interventions"
          or
      "Has lower extremity amputation" then 1
    else 0

// Section 2: ICD-9-CM Diagnosis Codes For PAD
define "Has Diagnosis Codes For PAD":
    if exists([Condition: "PAD Diagnosis"]) then 1
    else 0

// Section 1: Vascular Lab Criteria
define "Has Vascular Lab Criteria":
    "Has Abnormal Vascular Lab Measurements"
        and
    // Exclude non-atherosclerotic causes of PAD: >=2 occurrences of dx
    Count([Condition: "Non-Atherosclerotic PAD Diagnosis"]) < 2

define "Has Additional Qualifying Criteria":
    // 'any of the two related codes or presence of indicative phrases in Sections 2-5'
    Sum({
        "Has Diagnosis Codes For PAD",
        "Has Procedure Codes for PAD",
        "Has Medications for Claudication"
    }) >= 2

define "Case":
    "Has Vascular Lab Criteria"
        or
    "Has Additional Qualifying Criteria"
