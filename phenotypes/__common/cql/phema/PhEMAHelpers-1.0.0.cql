/**
    Common functions and statements used in PhEMA phenotypes

	NOTE: This is a bit of a mess at the moment, sorry, hopefully we can evole
		  a more consistent API as we figure out what's needed
*/
library PhEMAHelpers version '1.0.0'

using FHIR version '4.0.0'

include FHIRHelpers version '4.0.0' called FHIRHelpers
include PhEMATemporal version '1.0.0' called PhEMATemporal

codesystem "LOINC": 'http://loinc.org'

valueset "Biobank Specimens Available": '2.16.840.1.113762.1.4.1026.1'

code "Yes": 'LA33-6' from "LOINC" display 'Yes'

// We will use this concept to act as the default concept if no explicit
// value is provided for the biobank status value.
concept "Default Biobank Sample Exists": { "Yes" } display 'Default Biobank Sample Exists'

context Patient

define function "Earliest" (
	conditions List<FHIR.Condition>
):
	First(
		(conditions) C
			sort by start of PhEMATemporal."Normalize Onset"(onset)
	)

define function "Earliest" (
	observations List<FHIR.Observation>
):
	First(
		(observations) O
			sort by start of PhEMATemporal."Normalize Interval"(effective)
	)

define function "Earliest" (
	medications List<FHIR.MedicationRequest>
):
	First(
		(medications) C
			sort by start of PhEMATemporal."Normalize Onset"(authoredOn)
	)

define function "Effective Date" (
	obs FHIR.Observation
):
	start of PhEMATemporal."Normalize Onset"(obs.effective)


define function "Effective Date" (
	dx FHIR.Condition
):
	start of PhEMATemporal."Normalize Interval"(dx.onset)

define function "Effective Date" (
	rx FHIR.MedicationRequest
):
	start of PhEMATemporal."Normalize Interval"(rx.authoredOn)

define function "Effective Date" (
	px FHIR.Procedure
):
	start of PhEMATemporal."Normalize Interval"(px.performed)

define function "Effective Date" (
	enc FHIR.Encounter
):
	start of PhEMATemporal."Normalize Interval"(enc.period)

define function "Earliest Date" (
	dates List<System.DateTime>
):
	First(
		(
            (dates) D
                where D is not null
                return {
                    IndexDate: D
                }
        ) DD
        sort by IndexDate
    ).IndexDate

define function "Latest Date" (
	dates List<System.DateTime>
):
	First(
		(
            (dates) D
                where D is not null
                return {
                    IndexDate: D
                }
        ) DD
        sort by IndexDate desc
    ).IndexDate

define function "Latest" (
	observations List<FHIR.Observation>
):
	First(
		(observations) O
			sort by start of PhEMATemporal."Normalize Interval"(effective) desc
	)

define function "Sorted Dates"(
	list List<MedicationRequest> // TODO: include other resource types
):
	(
		("Effective Dates"(list)) D
			where D is not null
			return {
				IndexDate: D
			}
	) DD
	sort by IndexDate

define function "Number Of Observations Before Date" (
	observations List<FHIR.Observation>,
	endDate System.DateTime
):
	if endDate is null then
		Count(observations)
	else
		Count(
			( observations ) O
				where start of PhEMATemporal."Normalize Interval"( O.effective ) before endDate
		)

define function "Number Of Encounters Before Date" (
	encounters List<FHIR.Encounter>,
	endDate System.DateTime
):
	if endDate is null then
		Count(encounters)
	else
		Count(
			( encounters ) E
				where start of PhEMATemporal."Normalize Interval"( E.period.start ) before endDate
		)

define function "Dx Count" (
	dx System.Concept
):
	Count([Condition: dx])

///// Function Overloading Below

define function "Effective Dates" (
	obs List<FHIR.Observation>
):
	(obs) O
		return "Effective Date"(O)

define function "Effective Dates" (
	dx List<FHIR.Condition>
):
	(dx) D
		return "Effective Date"(D)

define function "Effective Dates" (
	rx List<FHIR.MedicationRequest>
):
	(rx) R
		return "Effective Date"(R)

define function "Effective Dates" (
	px List<FHIR.Procedure>
):
	(px) P
		return "Effective Date"(P)

///// Common eMERGE Phenotype Functions

define "In Biobank":
  // We are assuming that the presence of a biobank specimen result with no value means that
  // the sample exists.
  exists([Observation: "Biobank Specimens Available"] O
    where Coalesce(O.value, "Default Biobank Sample Exists") ~ "Yes")

///// Demographics

// This is far from perfect
define "Get Race":
	FHIRHelpers.ToCode(
		First(
			// Get the outer race extension
			First(
				(Patient.extension) E
					where E.url.value = 'http://hl7.org/fhir/us/core/StructureDefinition/us-core-race'
			).extension
		).value as Coding
	)

define "Is Male":
	Patient.gender ~ 'male'

define "Is Female":
	Patient.gender ~ 'female'

///// Getting distict dates

define function "Distinct Dates"(
	dx List<Condition>
):
	distinct (("Effective Dates"(dx)) D return ToDate(D))

define function RatioToQuantity(
    q System.Ratio
):
    q.numerator.value / q.denominator.value