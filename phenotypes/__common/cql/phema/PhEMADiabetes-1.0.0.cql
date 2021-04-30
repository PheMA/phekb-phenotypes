/**
    Common function related to diabetes
*/
library PhEMADiabetes version '1.0.0'

using FHIR version '4.0.0'

include FHIRHelpers version '4.0.0' called FHIRHelpers

valueset "Fasting Glucose": 'omop-concept-set-30'
valueset "Random Glucose": 'omop-concept-set-31'
valueset "Hemoglobin A1C": 'omop-concept-set-32'

context Patient


/// Fasting Glucose

define function "Abnormal Fasting Glucose" (
    lowerLimit Decimal
):
	[Observation: "Fasting Glucose"] O
		where O.value >= System.Quantity { value: lowerLimit, unit: 'mg/dl' }

define function "Has Abnormal Fasting Glucose" (
    lowerLimit Decimal
):
	exists("Abnormal Fasting Glucose"(lowerLimit))

/// Random Glucose

define function "Abnormal Random Glucose" (
    lowerLimit Decimal
):
	[Observation: "Random Glucose"] O
		where O.value >= System.Quantity { value: lowerLimit, unit: 'mg/dl' }

define function "Has Abnormal Random Glucose"(
    lowerLimit Decimal
):
	exists("Abnormal Random Glucose"(lowerLimit))

/// Hemoglobin A1C

define function "Abnormal Hemoglobin A1C" (
    lowerLimit Decimal
):
	[Observation: "Hemoglobin A1C"] O
		where O.value >= System.Quantity { value: lowerLimit, unit: '%' }

define function "Has Abnormal Hemoglobin A1C"(
    lowerLimit Decimal
):
	exists("Abnormal Hemoglobin A1C"(lowerLimit))