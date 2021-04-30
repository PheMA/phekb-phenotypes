/**
 * PheKB Phenotype
 *
 * Name : Steroid Induced Osteonecrosis
 * ID   : 155
 * Url  : https://phekb.org/node/155
 */
library "155.steroid-induced-osteonecrosis" version '1.0.0'

using FHIR version '4.0.0'

include FHIRHelpers version '4.0.0' called FHIRHelpers
include PhEMAHelpers version '1.0.0' called PhEMAHelpers
include PhEMAMedications version '1.0.0' called PhEMAMedications

valueset "Corticosteroid Medication": '155.corticosteroid-medications'
valueset "Qualifying Routes": '155.qualifying-routes'
valueset "Alcoholism": '155.alcoholism'
valueset "Sickle Cell Disease": '155.sickle-cell-disease'
valueset "Gaucher": '155.gaucher'
valueset "Legg-Calve-Perthes": '155.legg-calve-perthes'
valueset "HIV": '155.hiv'
valueset "Organ Transplant Diagnosis": '155.organ-transplant-diagnosis'
valueset "Organ Transplant Procedure": '155.organ-transplant-procedures'
valueset "HIV Labs": '155.hiv-labs'
valueset "Necrosis Diagnosis": '155.necrosis-diagnosis'

context Patient

define "Qualifying Medication Requests":
    [MedicationRequest] M
            where M.dosageInstruction.route in "Qualifying Routes"

define "Exclusions":
    exists(
        [Condition: "Alcoholism"]
            union
        [Condition: "Sickle Cell Disease"]
            union
        [Condition: "Gaucher"]
            union
        [Condition: "Legg-Calve-Perthes"]
            union
        [Condition: "HIV"]
            union
        [Condition: "Organ Transplant Diagnosis"]
            union
        [Procedure: "Organ Transplant Procedure"]
            union
        [Observation: "HIV Labs"] O
            where O.value is null or O.value !~ 'undetectable'    
    )

define "Necrosis Diagnosis In Query Window":
    exists(
        [Condition: "Necrosis Diagnosis"] C
            where PhEMAHelpers."Effective Date"(C) in
                Interval[PhEMAMedications."Earliest Exposure Date"("Qualifying Medication Requests"),
                         PhEMAMedications."Latest Exposure Date"("Qualifying Medication Requests") + 1 year]
    )

define "At Least Two Weeks Of Steroid Exposure":
    PhEMAMedications."Get Total Exposure Days"(
        "Qualifying Medication Requests"
    ).value >= 14

define "Case":
    "At Least Two Weeks Of Steroid Exposure"
        and
    (not "Exclusions")
        and
    "Necrosis Diagnosis In Query Window"