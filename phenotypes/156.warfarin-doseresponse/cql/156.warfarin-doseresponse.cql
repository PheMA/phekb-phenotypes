/**
 * PheKB Phenotype
 *
 * Name : Warfarin dose/response
 * ID   : 156
 * Url  : https://phekb.org/node/156
 */
library "156.warfarin-doseresponse" version '1.0.0'

using FHIR version '4.0.0'

include FHIRHelpers version '4.0.0' called FHIRHelpers
include PhEMAHelpers version '1.0.0' called PhEMAHelpers
include PhEMATemporal version '1.0.0' called PhEMATemporal

valueset "Warfarin Medications": '156.warfarin-meds'
valueset "Anticoagulation Clinic Encounter Types": '156.anticoagulation-clinic-encounter-types'
valueset "INR Labs" : '156.inr-labs'

context Patient

define "Sorted Prescriptions":
    PhEMAHelpers."Sorted Dates"("Warfarin Prescriptions In Anticoagulation Clinic")

define "Warfarin Prescriptions In Anticoagulation Clinic":
    from
        [MedicationRequest: "Warfarin Medications"] M,
        [Encounter: "Anticoagulation Clinic Encounter Types"] E
    where
        M.encounter.reference = E.id
    return 
        M

define "Has At Least Two Warfarin Prescriptions In Anticoagulation Clinic":
    Count("Warfarin Prescriptions In Anticoagulation Clinic") >= 2

/**
    We are interested in intervals of 3 - 12 weeks between prescriptions
*/
define "Qualifying Intervals":
    (("Warfarin Prescriptions In Anticoagulation Clinic") P
        return 
            if 
                IndexOf("Warfarin Prescriptions In Anticoagulation Clinic", P) > 0 // start from 2nd index
                    and
                (
                    difference in weeks between
                        PhEMAHelpers."Effective Date"(   // previous prescription
                            "Warfarin Prescriptions In Anticoagulation Clinic"[
                                IndexOf("Warfarin Prescriptions In Anticoagulation Clinic", P) - 1
                            ]
                        )
                            and
                        PhEMAHelpers."Effective Date"(P) // current prescription
                    in Interval[3, 12]
                )
            then
                Interval[
                    PhEMAHelpers."Effective Date"(
                        "Warfarin Prescriptions In Anticoagulation Clinic"[
                            IndexOf("Warfarin Prescriptions In Anticoagulation Clinic", P) - 1
                        ]
                    ),
                    PhEMAHelpers."Effective Date"(P)
                ]
            else
                null
    ) W
        where W is not null // filter out nulls

/**
    Get the relevant labs in a given interval sorted by effective date
*/
define function "INR Labs In Interval"(
    int Interval<System.DateTime>
):
    [Observation: "INR Labs"] O
        where PhEMAHelpers."Effective Date"(O) in int
        sort by start of PhEMATemporal."Normalize Onset"(effective)

/**
    Checks for two labs in a row. Builds an array of booleans for each
    consecutive pair (false for the first element). The value will be true
    if all conditions are met (both in range and one data apart). Checks for
    any true value in the array
*/
define function "Has Two Consecutive Good INR Labs In Interval"(
    int Interval<System.DateTime>
):
    (("INR Labs In Interval"(int)) L
        return 
            if IndexOf("INR Labs In Interval"(int), L) > 0 // start from 2nd index
                and
            (
                // current lab in range
                    (L.value as FHIR.Quantity).value in Interval[2.0, 3.0]
                // previous lab in range
                and
                    ("INR Labs In Interval"(int)[
                        IndexOf("INR Labs In Interval"(int), L) - 1
                    ].value as FHIR.Quantity).value in Interval[2.0, 3.0]
                // at least one day apart
                and (
                    difference in days between
                        PhEMAHelpers."Effective Date"(
                            "INR Labs In Interval"(int)[
                                IndexOf("INR Labs In Interval"(int), L) - 1
                            ]
                        )
                            and
                        PhEMAHelpers."Effective Date"(L)
                    >= 1
                )                
            )
            then
                true
            else
                false
    ) contains true

/**
    Same array building idea as above, but checks for values outside range
*/
define function "Has Disqualifying INR Lab In Interval"(
    int Interval<System.DateTime>
):
    (("INR Labs In Interval"(int)) L
        return
            if not ((L.value as FHIR.Quantity).value in Interval[2.0, 3.0]) then
                true
            else
                false
    ) contains true

/**
    Finds qualifiying intervals (2 prescriptions 3-12 weeks apart) and checks in
    each interval for two consecutive INR labs in range
*/
define "Has Two Qualifying INR Labs And No Disqualifying INR Labs":
    exists(
        ("Qualifying Intervals") I
            where
                "Has Two Consecutive Good INR Labs In Interval"(
                    Interval[
                        I.low - 7 days,
                        I.high
                    ]
                )
                    and
                (
                    not "Has Disqualifying INR Lab In Interval"(
                        Interval[
                            I.low - 7 days,
                            I.high
                        ]
                    )
                )
    )

define "Case":
    "Has Two Qualifying INR Labs And No Disqualifying INR Labs"
