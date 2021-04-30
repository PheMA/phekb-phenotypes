/**
 * PheKB Phenotype
 *
 * Name : Resistant Hypertension
 * ID   : 68
 * Url  : https://phekb.org/node/68
 */
library "68.resistant-hypertension" version '1.0.0'

using FHIR version '4.0.0'

include FHIRHelpers version '4.0.0' called FHIRHelpers
include PhEMAHelpers version '1.0.0' called PhEMAHelpers
include PhEMAString version '1.0.0' called PhEMAString

// Diagnoses
valueset "Exclusion Diagnoses (Any Time)": '68.exclusion-any-time-dx'
valueset "Exclusion Diagnoses (Within 5 Years)": '68.exclusion-within-5-years-dx'

// Observations
valueset "Systolic Blood Pressure Labs": '68.systolic-bp'
valueset "Diastolic Blood Pressure Labs": '68.diastolic-bp'
valueset "Creatinine": 'phema-creatinine'
valueset "Ejection Fraction": '68.ejection-fraction'

// Medication classes
valueset "Medication Class Hydralazine": '68.med-class-hydralazine'
valueset "Medication Class Minoxidil": '68.med-class-minoxidil'
valueset "Medication Class Central Alpha Antagonists": '68.med-class-central-alpha-antagonists'
valueset "Medication Class ACEI/ARB": '68.med-class-central-acei-arb'
valueset "Medication Class Aldosterone Antagonists": '68.med-class-aldosterone-antagonists'
valueset "Medication Class Diuretics": '68.med-class-diuretics'
valueset "Medication Class Diuretic Combination": '68.med-class-diuretic-combo'
valueset "Medication Class Alpha Antagonists": '68.med-class-alpha-antagonists'
valueset "Medication Class Non-Dihydro CCBs": '68.med-class-non-dihydro-ccbs'
valueset "Medication Class Dihydro CCBs": '68.med-class-dihydro-ccbs'
valueset "Medication Class Beta Blockers": '68.med-class-beta-blockers'

// These classes count as 2
valueset "Medication Class Thiazide/BB Combination": '68.med-class-thiazide-bb-combo'
valueset "Medication Class Thiazide/ACEI/ARB Combination": '68.med-class-thiazide-acei-arb-combo'
valueset "Medication Class Thiazide/Aldosterone Antagonist Combination": '68.med-class-thiazide-aldosterone-antagonist-combo'
valueset "Medication Class Thiazide/Renin Antagonist Combination": '68.med-class-thiazide-renin-antagonist-combo'

codesystem "ActEncounterCode": 'http://terminology.hl7.org/ValueSet/v3-ActEncounterCode'
codesystem "RaceAndEthnicityCDC": 'urn:oid:2.16.840.1.113883.6.238'

code "Inpatient Encounter": 'IMP' from "ActEncounterCode"
code "Outpatient Encounter": 'AMB' from "ActEncounterCode"

code "Black or African American": '2054-5' from "RaceAndEthnicityCDC"

context Patient

/*
    The algorithm to detect at least N concurrent medication classes is as
    follows.

    Step 1. Collapse all intervals within the same class into a single interval.
            The result is having only one concurrent interval for each class,
            which simplies counting.

            So, if we had the follow:

            C1:  |--------|           |------|
            C1:       |--------|

            This could be collapsed into:

            C1:   |------------|      |------|

            At any point in time, we are only interested in if there is an
            active medication from any given class. We don't care what the 
            medication is, so we don't lose important information in this step.

    Step 2: We prepare a data structure that contains each interval, along with
            how much the specific interval should count towards the total. Most
            medication classes count 1, but some combo medications count 2.

            So, we'll have something like this:

            C1:   |------------|{1}   |------|{1}
            C2:       |----|{1}     |-----|{1}
            C13:     |----------|{2}         |-----|{2}     <- this is a combo

    Step 3: We flatten all the lists into a single list of {interval, count}
            pairs. We don't need to track which class any interval belongs to
            anymore, because we know two intervals of the same class cannot
            be concurrent (thanks to step 1).

    Step 4: We prepare a new data structure by extracting the start and end
            dates of each interval. With each start date, we keep the count, and
            with the end date we keep the negated value of the count. So we'll
            have something like.

            L = {(2011-01-01, 1), (2012-03-04, 1), (2016-09-02, -1), (2020-01-01, -1)}

            Note that some combo medications will have a count of 2 or -2.

    Step 5: Sort the list by date.

    Step 6: Iterate through the list, and keep a running total by adding the
            count value associated with each date. This running total will be
            the number of concurrent open intervals. Doing this for the list
            shown in step 4 will give us:

            T = {(2011-01-01, 1), (2012-03-04, 2), (2016-09-02, 1), (2020-01-01, 0)}

            We now know how many medication classes are active at each date.
*/

////////////////////////////////////////////////////////////////////////////////
//
// STEP 0: Extract just the intervals from the MedicationRequest dispense data
//
////////////////////////////////////////////////////////////////////////////////

define "Single Count Medication Classes":
    {
        "Medication Class Hydralazine",
        "Medication Class Minoxidil",
        "Medication Class Central Alpha Antagonists",
        "Medication Class ACEI/ARB",
        "Medication Class Aldosterone Antagonists",
        "Medication Class Diuretics",
        "Medication Class Diuretic Combination",
        "Medication Class Alpha Antagonists",
        "Medication Class Non-Dihydro CCBs",
        "Medication Class Dihydro CCBs",
        "Medication Class Beta Blockers"
    }

define "Double Count Medication Classes":
    {
        "Medication Class Thiazide/BB Combination",
        "Medication Class Thiazide/ACEI/ARB Combination",
        "Medication Class Thiazide/Aldosterone Antagonist Combination",
        "Medication Class Thiazide/Renin Antagonist Combination"
    }

define "Find Single Count Intervals":
    ("Single Count Medication Classes") VS
        return
            [MedicationRequest: VS] M
                where
                    // Only consider intervals we know for sure
                    M.dispenseRequest.validityPeriod is not null
                return
                    Interval[
                        // Convert to system types so builtin function work
                        FHIRHelpers.ToDateTime(M.dispenseRequest.validityPeriod.start),
                        FHIRHelpers.ToDateTime(M.dispenseRequest.validityPeriod.end)
                    ]

define "Find Double Count Intervals":
    ("Double Count Medication Classes") VS
        return
            [MedicationRequest: VS] M
                where
                    // Only consider intervals we know for sure
                    M.dispenseRequest.validityPeriod is not null
                return
                    Interval[
                        // Convert to system types so builtin function work
                        FHIRHelpers.ToDateTime(M.dispenseRequest.validityPeriod.start),
                        FHIRHelpers.ToDateTime(M.dispenseRequest.validityPeriod.end)
                    ]

////////////////////////////////////////////////////////////////////////////////
//
// STEP 1: Collapse any concurrent intervals of the same class
//
////////////////////////////////////////////////////////////////////////////////

define "Collapsed Single Count Intervals":
    ("Find Single Count Intervals") C
        return collapse C

define "Collapsed Double Count Intervals":
        ("Find Double Count Intervals") C2
        return collapse C2

////////////////////////////////////////////////////////////////////////////////
//
// STEP 2: Associate count values with each class. 1 for most, 2 for some combos
//
////////////////////////////////////////////////////////////////////////////////

define "Single Count Tuples":
    ("Collapsed Single Count Intervals") Single
        where
            Length(Single) > 0 // filter out empty classes at this stage
        return
            (Single) S
                return Tuple {
                    startDate: S.low,
                    endDate: S.high,
                    count: 1
                }

define "Double Count Tuples":
    ("Collapsed Double Count Intervals") Double
        where
            Length(Double) > 0 // filter out empty classes at this stage
        return
            (Double) D
                return Tuple {
                    startDate: D.low,
                    endDate: D.high,
                    count: 2
                }

////////////////////////////////////////////////////////////////////////////////
//
// STEP 3 & 4: Merge and flatten lists, and split into individual dates
//
////////////////////////////////////////////////////////////////////////////////

define "Single Dates With Counts":
    flatten (
        ("Single Count Tuples") Single
            return
                flatten (
                    (Single) S
                        return {
                            Tuple {
                                date: S.startDate,
                                count: 1
                            },
                            Tuple {
                                date: S.endDate,
                                count: -1
                            }
                        }
                )
    )

define "Double Dates With Counts":
    flatten (
        ("Double Count Tuples") Double
            return
                flatten (
                    (Double) D
                        return {
                            Tuple {
                                date: D.startDate,
                                count: 2
                            },
                            Tuple {
                                date: D.endDate,
                                count: -2
                            }
                        }
                )
    )
    
define "All Dates With Counts":
    // Flatten is necessary here instead of Union, because Union uses set
    // semantics and eliminates duplicates, which we don't want
    flatten {
        "Single Dates With Counts",
        "Double Dates With Counts"   
    }

////////////////////////////////////////////////////////////////////////////////
//
// STEP 5: Sort the list by date
//
////////////////////////////////////////////////////////////////////////////////

define "Sorted Dates With Counts":
    ("All Dates With Counts") A
        return 
            all A // necessary to avoid set semantics
        sort 
            by date

////////////////////////////////////////////////////////////////////////////////
//
// STEP 6: Calculate the total number of open intervals (i.e. active medication
//         classes) at each date
//
////////////////////////////////////////////////////////////////////////////////

define "Sorted Dates With Totals":
    (Tail("Sorted Dates With Counts")) DC
        aggregate all DT starting ({
            Tuple {
                date: First("Sorted Dates With Counts").date,
                total: First("Sorted Dates With Counts").count
            }
        }): flatten {
            DT,
            Tuple {
                date: DC.date,
                total: Last(DT).total + DC.count
            }
        }    

////////////////////////////////////////////////////////////////////////////////
//
// The rest of the phenotype logic starts here
//
////////////////////////////////////////////////////////////////////////////////

// We are using the first date when medCount medications are taken, but another
// interpretation is to use the second date, since that is technically when
// the patient qualifies as a case
define function "Index Date For Med Count"(
    medCount Integer
):
    First("Dates With At Least X Meds"(medCount))    

define function "Dates With At Least X Meds"(
    medCount Integer
):
    ("Sorted Dates With Totals") SD
        where
            SD.total >= medCount
        return
            SD.date        

define function "Has At Least X Meds Greater Than A Month Apart"(
    medCount Integer
):
    if Length("Dates With At Least X Meds"(medCount)) = 0 then
        false
    else
        // There's a better way to do this with aggregate queries, but I'm
        // doing it this way to keep things consistent
        exists(
            ("Dates With At Least X Meds"(medCount)) D1
                where
                    exists(
                        ("Dates With At Least X Meds"(medCount)) D2
                            where
                                D1 != D2
                                    and
                                duration in months between D1 and D2 >= 1
                    )    
        )        

// At least 4 concurrent med classes
define "Case Type 1":
    "Has At Least X Meds Greater Than A Month Apart"(4)

define "High BP Measurements":
    (
        [Observation: "Systolic Blood Pressure Labs"] SBP
            where
                exists(
                    [Encounter] E
                        where
                            PhEMAString."GetId"(SBP.encounter.reference) = E.id
                )
                    and
                SBP.value as Quantity > System.Quantity { value: 140.0, unit: 'mm[Hg]' } 
    )
        union
    (
        [Observation: "Diastolic Blood Pressure Labs"] DBP
            where
                exists(
                    [Encounter] E
                        where
                            PhEMAString."GetId"(DBP.encounter.reference) = E.id
                )
                    and
                DBP.value as Quantity > System.Quantity { value: 90.0, unit: 'mm[Hg]' }         
    )

// We're looking for the total of meds on the latest date before the parameter
define function "Med Count At Date"(
    date System.DateTime
):
    Last(
        ("Sorted Dates With Totals") SD
            where
                SD.date before date
    ).total

define "Qualifying BP Measurements":
    ("High BP Measurements") HBP
        where
            duration in months between 
                "Index Date For Med Count"(3)
                    and          
                PhEMAHelpers."Effective Date"(HBP) >= 1 
            and
                "Med Count At Date"(PhEMAHelpers."Effective Date"(HBP)) >= 3

// medication criteria: 3 simultanuous, at least twice, at least 1 month apart
//  AND
// two outpatient SBP > 140 or DBP > 90 measurements, at least 1 month after
// meeting medication criteria 
define "Case Type 2":
    "Has At Least X Meds Greater Than A Month Apart"(3)
        and
    Count("Qualifying BP Measurements") >= 2

define "Has Any Time Exclusion Diagnosis":
    exists([Condition: "Exclusion Diagnoses (Any Time)"])

define function "Has Within 5 Year Exclusion Diagnosis"(
    indexDate System.DateTime
):
    exists(
        [Condition: "Exclusion Diagnoses (Within 5 Years)"] C
            where
                duration in years between 
                    PhEMAHelpers."Effective Date"(C) and indexDate
                in Interval(-5, 5)
    )

define "Race eGFR Factor":
    if PhEMAHelpers."Get Race" ~ "Black or African American" then
        1.210
    else
        1

define "Gender eGFR Factor":
    if PhEMAHelpers."Is Female" then
        0.742
    else
        1  

define function "Age eGFR Factor"(
    date System.DateTime
):
    Power(AgeInYearsAt(date), -0.203)

// The formula is now here on Wikipedia: https://en.wikipedia.org/wiki/Glomerular_filtration_rate#Modification_of_Diet_in_Renal_Disease_(MDRD)_formula
define "eGFR Measurements":
    [Observation: "Creatinine"] SC
        return Tuple {
            value: 186 
                    * Power((SC.value as Quantity).value, -1.154) 
                    * "Age eGFR Factor"(PhEMAHelpers."Effective Date"(SC))
                    * "Race eGFR Factor"
                    * "Gender eGFR Factor",
            date: PhEMAHelpers."Effective Date"(SC)
        }

define function "Has Disqualifying eGFR Measurement"(
    indexDate System.DateTime
):
    exists(
        ("eGFR Measurements") eGFR
            where
                eGFR.value < 30
                    and
                eGFR.date before indexDate + 6 months        
    )

define function "Has Disqualifying EF Measurement"(
    indexDate System.DateTime
):
    exists(
        [Observation: "Ejection Fraction"] EF
            where
                EF.value < System.Quantity { value: 35, unit: '%' }
                    and
                PhEMAHelpers."Effective Date"(EF) in
                    Interval[indexDate - 1 year, indexDate + 1 year]
    )

define function "Has Case Type 1 Exclusions"(
    indexDate System.DateTime
):
    "Has Any Time Exclusion Diagnosis"
        or
    "Has Within 5 Year Exclusion Diagnosis"(indexDate)
        or
    "Has Disqualifying eGFR Measurement"(indexDate)
        or
    "Has Disqualifying EF Measurement"(indexDate)

define function "Has Case Type 2 Exclusions"(
    indexDate System.DateTime
):
    // A bit of repition here, but I think it makes it clearer
    "Has Any Time Exclusion Diagnosis"
        or
    "Has Within 5 Year Exclusion Diagnosis"(indexDate)
        or
    "Has Disqualifying eGFR Measurement"(indexDate)

define "Case":
    (
        "Case Type 1"
            and
        (not "Has Case Type 1 Exclusions"("Index Date For Med Count"(4)))
    )
        or
    (
        "Case Type 2"
            and
        (not "Has Case Type 2 Exclusions"("Index Date For Med Count"(3)))
    )
