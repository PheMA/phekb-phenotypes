/**
    Common function related to medications
*/
library PhEMAMedications version '1.0.0'

using FHIR version '4.0.0'

include FHIRHelpers version '4.0.0' called FHIRHelpers
include PhEMAHelpers version '1.0.0' called PhEMAHelpers

codesystem "SNOMED": 'http://snomed.info/sct'

// Routes
code "Nasal use": '46713006' from "SNOMED" display 'Nasal use'
code "Topical route": '6064005' from "SNOMED" display 'Topical route'
code "Respiratory tract route (Inhaled)": '447694001' from "SNOMED" display 'Respiratory tract route (Inhaled)'
code "Intravenous use (IV)": '47625008' from "SNOMED" display 'Intravenous use (IV)'
code "Intra-articular route": '12130007' from "SNOMED" display 'Intra-articular route'
code "Intramuscular use (IM)": '78421000' from "SNOMED" display 'Intramuscular use (IM)'
code "Oral use (PO)": '26643006' from "SNOMED" display 'Oral use (PO)'

define function "Medication Has Route"(
    med FHIR.MedicationRequest,
    route Code
):
    // FIXME: 🚨 This only looks at the first dosage instruction
    if med.dosageInstruction[0].route ~ route then
        true
    else
        false // we return false if there is no route, which I think is correct

define function "Medication Has Any Route"(
    med FHIR.MedicationRequest,
    routes List<Code>
):
    exists(
        (routes) R
            where
                "Medication Has Route"(med, R)
    )

// The semantics are slighly different to "Medication Has Route". Specifically,
// if the route is null we should return false, since we don't have enough
// information to make a determination
define function "Medication Does Not Have Route"(
    med FHIR.MedicationRequest,
    route Code
):
    if med.dosageInstruction[0].route is null then
        false
    else
        not (med.dosageInstruction[0].route ~ route)

///// Medication exposure functions

/**
	Converts a time-based quantitiy to days with a granularity of 1. If the
	source < 1, it will be rounded up to 1.

	For example, if we are converting 2.0 'hours' to 'days', the result will be 1.0
*/
define function "Convert To Days With Granularity"(
	source System.Quantity
):
	if (convert source to 'days').value < 1.0 then
		System.Quantity { value: 1.0, unit: 'days' }
	else
		convert source to 'days'

/**
	Get the exposure in days. If the dosage instructions do not specify any
	repitition, assume one day of exposure.
*/
define function "Get Exposure Days"(
	request MedicationRequest
):
	// FIXME: 🚨 This only looks at the first dosage instruction
	if request.dosageInstruction[0].timing.repeat.bounds is null then
		System.Quantity { value: 1.0, unit: 'days' }
	else
		// FIXME: 🚨 This only looks at the first dosage instruction, and
		// 			 and assumes the type is Duration
		"Convert To Days With Granularity"(
			FHIRHelpers.ToQuantity(First(request.dosageInstruction.timing.repeat.bounds) as FHIR.Duration)
		)

/**
	Get the sum total of exposure in days for a list of MedicationRequests
*/
define function "Get Total Exposure Days"(
	requests List<MedicationRequest>
):
	Sum(
		(requests R return "Get Exposure Days"(R))
	)


define function "Earliest Exposure Date"(
	requests List<MedicationRequest>
):
	// This assumes the medication was start on the date that the request was authored
	PhEMAHelpers."Earliest Date"(
		(requests R return R.authoredOn)
	)

/**
	If the dosage instructions contain a repeat instruction, calculated the end
	date of the repeating period
*/
define function "Latest Exposure Date"(
	requests List<MedicationRequest>
):
	PhEMAHelpers."Latest Date"(
		(
			requests R
				return if R.dosageInstruction.timing.repeat is null then
					R.authoredOn
				else
					// FIXME: 🚨 This only looks at the first dosage instruction, and
					// 			 and assumes the type is Duration
					R.authoredOn
						+
					FHIRHelpers.ToQuantity(First(R.dosageInstruction.timing.repeat.bounds) as FHIR.Duration)
		)
	)

define function "Dose Unit Matches Regex"(
	med FHIR.MedicationRequest,
	regex String
):
	if med.dosageInstruction[0].doseAndRate[0].dose is null then
		false
	else
		// FIXME: 🚨 This only looks at the first dosage instruction
		//			 and first doseAndRate
		Matches(
			(med.dosageInstruction[0].doseAndRate[0].dose as Quantity).unit,
			regex
		)