/**
 * PheKB Phenotype
 *
 * Name : Cardiac Conduction (QRS)
 * ID   : 8
 * Url  : https://phekb.org/node/8
 */
library "8.cardiac-conduction-qrs" version '1.0.0'

using FHIR version '4.0.0'

include FHIRHelpers version '4.0.0' called FHIRHelpers
include PhEMAString version '1.0.0' called PhEMAString

// See https://www.hl7.org/fhir/mdc.html
codesystem "MDC": 'urn:oid:2.16.840.1.113883.6.24'
code "ECG Measurement": '131328' from "MDC" display 'MDC_ECG_ELEC_POTL'

valueset "Heart Disease Procedures": '8.cardiac-conduction-qrs.heart-disease-cpt'
valueset "Sodium Channel Blocking Drugs": 'omop-concept-set-36'
valueset "Potassium Lab Test": 'omop-concept-set-37'
valueset "Calcium Lab Test": 'omop-concept-set-38'
valueset "Magnesium Lab Test": 'omop-concept-set-39'
valueset "Creatine Kinase Lab Test": 'omop-concept-set-40'
valueset "Troponin Lab Test": 'omop-concept-set-41'
valueset "BNP Lab Test": 'omop-concept-set-42'
valueset "QRS Duration": 'omop-concept-set-43'
valueset "Heart Rate": 'omop-concept-set-44'
valueset "Heart Disease": 'omop-concept-set-45'


define function "Sodium Channel Blocking Drugs Before Date"(
    endDate DateTime
):
    [MedicationRequest: "Sodium Channel Blocking Drugs"] M
        where M.authoredOn on or before endDate

define function "Heart Disease Diagnosis Before Date"(
    endDate DateTime
):
    [Condition: "Heart Disease"] C
        where C.onset on or before endDate

define function "Heart Disease Procedure Before Date"(
    endDate DateTime
):
    [Procedure: "Heart Disease Procedures"] P
        where P.performed on or before endDate

define function "Potassium Outside Range In Period Date"(
    startDate DateTime,
    endDate DateTime
):
    [Observation: "Potassium Lab Test"] O
        where FHIRHelpers.ToDateTime(O.effective as FHIR.dateTime) in Interval(startDate, endDate)
            and
        (O.value > 6 'mmol/L' or O.value < 3.5 'mmol/L')     

define function "Calcium Outside Range In Period Date"(
    startDate DateTime,
    endDate DateTime
):
    [Observation: "Calcium Lab Test"] O
        where FHIRHelpers.ToDateTime(O.effective as FHIR.dateTime) in Interval(startDate, endDate)
            and
        (O.value > 11 'mg/dL' or O.value < 8 'mg/dL')     

define function "Magnesium Outside Range In Period Date"(
    startDate DateTime,
    endDate DateTime
):
    [Observation: "Magnesium Lab Test"] O
        where FHIRHelpers.ToDateTime(O.effective as FHIR.dateTime) in Interval(startDate, endDate)
            and
        O.value < 1.7 'mg/dL'   

define function "Creatine Kinase Outside Range In Period Date"(
    startDate DateTime,
    endDate DateTime
):
    [Observation: "Creatine Kinase Lab Test"] O
        where FHIRHelpers.ToDateTime(O.effective as FHIR.dateTime) in Interval(startDate, endDate)
            and
        O.value > 8 'U/L'

define function "Troponin Outside Range In Period Date"(
    startDate DateTime,
    endDate DateTime
):
    [Observation: "Troponin Lab Test"] O
        where FHIRHelpers.ToDateTime(O.effective as FHIR.dateTime) in Interval(startDate, endDate)
            and
        O.value > 0.05 'ng/mL'     

define function "BNP Outside Range In Period Date"(
    startDate DateTime,
    endDate DateTime
):
    [Observation: "BNP Lab Test"] O
        where FHIRHelpers.ToDateTime(O.effective as FHIR.dateTime) in Interval(startDate, endDate)
            and
        O.value > 100 'pg/mL'

define function "Lab Outside Range In Period"(
    ecgDate DateTime
):
    exists("Potassium Outside Range In Period Date"(ecgDate - 48 hours, ecgDate + 48 hours))
        or
    exists("Calcium Outside Range In Period Date"(ecgDate - 48 hours, ecgDate + 48 hours))
        or
    exists("Magnesium Outside Range In Period Date"(ecgDate - 48 hours, ecgDate + 48 hours))
        or
    exists("Creatine Kinase Outside Range In Period Date"(ecgDate - 48 hours, ecgDate + 48 hours))
        or
    exists("Troponin Outside Range In Period Date"(ecgDate - 48 hours, ecgDate + 48 hours))
        or
    exists("BNP Outside Range In Period Date"(ecgDate - 48 hours, ecgDate + 48 hours))

define function "Derived Heart Rate In Range"(
    observationId String
):
    [Observation: "Heart Rate"] O
        where PhEMAString."GetId"(O.derivedFrom.reference) = observationId
            and
        O.value >= 50 '/min'
            and
        O.value <= 100 '/min'

define function "Derived QRS In Range"(
    observationId String
):
    [Observation: "QRS Duration"] O
        where PhEMAString."GetId"(O.derivedFrom.reference) = observationId
            and
        O.value >= 65 'ms'
            and
        O.value <= 120 'ms'

define "Normal ECG":
    [Observation: "ECG Measurement"] O
        where exists("Derived QRS In Range"(O.id))
            and
        exists("Derived Heart Rate In Range"(O.id))
            and
        not exists("Sodium Channel Blocking Drugs Before Date"(FHIRHelpers.ToDateTime(O.effective as FHIR.dateTime) + 1 week))
            and
        not exists("Heart Disease Diagnosis Before Date"(FHIRHelpers.ToDateTime(O.effective as FHIR.dateTime) + 1 month))
            and
        not exists("Heart Disease Procedure Before Date"(FHIRHelpers.ToDateTime(O.effective as FHIR.dateTime) + 1 month))
            and
        not "Lab Outside Range In Period"(FHIRHelpers.ToDateTime(O.effective as FHIR.dateTime))        

define "Case":
    exists("Normal ECG")