/**
 * PheKB Phenotype
 *
 * Name : Statins and MACE
 * ID   : 170
 * Url  : https://phekb.org/node/170
 */
library "170.statins-and-mace" version '1.0.0'

using FHIR version '4.0.0'

include FHIRHelpers version '4.0.0' called FHIRHelpers
include PhEMAHelpers version '1.0.0' called PhEMAHelpers

valueset "Acute Myocardial Infarction": '170.ami'
valueset "Troponin I Labs": '170.tni-labs'
valueset "Troponin T Labs": '170.tnt-labs'
valueset "CK-MB/CK Ratio": '170.ckmb-ratio'
valueset "Creatinine Kinase Labs": '170.ckmb-labs'
valueset "Revascularization Procedures": '170.revascularization-procs'
valueset "Statin Medications": '170.statin-meds'

context Patient

define function "Get AMIs Dates Within 5 Days"(
    dt System.DateTime
):
    [Condition: "Acute Myocardial Infarction"] C
        where
            dt before PhEMAHelpers."Effective Date"(C)
                and
            difference in days between dt
                and
            PhEMAHelpers."Effective Date"(C) < 5
        return
             PhEMAHelpers."Effective Date"(C)

// Gets the start date of a potential 5 day window along
// with and array of all the valid end dates
define "Potential 5 Day Windows":
    [Condition: "Acute Myocardial Infarction"] AMI1
        where
            Count(
                "Get AMIs Dates Within 5 Days"(PhEMAHelpers."Effective Date"(AMI1))
            ) > 0
        return {
            windowStartDate: PhEMAHelpers."Effective Date"(AMI1),
            validWindowEndDates: "Get AMIs Dates Within 5 Days"(PhEMAHelpers."Effective Date"(AMI1))
        }


define function "Has Qualifying TNI In Window"(
    startDate System.DateTime,
    endDate System.DateTime
):
    exists(
        [Observation: "Troponin I Labs"] TI
            where 
                TI.value >= System.Quantity { value: 0.10, unit: 'ng/ml' }
                    and
                PhEMAHelpers."Effective Date"(TI) in Interval[startDate, endDate]
    )

define function "Has Qualifying TNT In Window"(
    startDate System.DateTime,
    endDate System.DateTime
):
    exists(
        [Observation: "Troponin T Labs"] TT
            where 
                TT.value >= System.Quantity { value: 0.10, unit: 'ng/ml' }
                    and
                PhEMAHelpers."Effective Date"(TT) in Interval[startDate, endDate]
    )

define function "Has Qualifying CMBK In Window"(
    startDate System.DateTime,
    endDate System.DateTime
):
    exists(
        [Observation: "CK-MB/CK Ratio"] R
            where 
                PhEMAHelpers.RatioToQuantity(FHIRHelpers.ToRatio(R.value)) >= 3
                    and
                PhEMAHelpers."Effective Date"(R) in Interval[startDate, endDate]
    )
        and
    exists(
        [Observation: "Creatinine Kinase Labs"] C
            where 
                C.value >= System.Quantity { value: 10.0, unit: 'ng/ml' }
                    and
                PhEMAHelpers."Effective Date"(C) in Interval[startDate, endDate]
    )

define function "Has Qualifying Lab In Window"(
    startDate System.DateTime,
    endDate System.DateTime
):
    "Has Qualifying TNI In Window"(startDate, endDate)
        or
    "Has Qualifying TNT In Window"(startDate, endDate)
        or
    "Has Qualifying CMBK In Window"(startDate, endDate)


define function "Has Statin At Least 180 Dates Before Date"(
    dt System.DateTime
):
    exists(
        [MedicationRequest: "Statin Medications"] S
            where 
                PhEMAHelpers."Effective Date"(S) before dt
                    and
                difference in days
                    between PhEMAHelpers."Effective Date"(S) and dt
                >= 180
    )

define function "Has Qualifying Statin Order And Lab In Any Window"(
    windows List<Tuple { windowStartDate System.DateTime, validWindowEndDates List<System.DateTime> }>
):
    exists(
        (windows) W
            where
                exists(
                    (W.validWindowEndDates) E
                        where
                            // Lab must be in "same time window"
                            "Has Qualifying Lab In Window"(W.windowStartDate, E)
                                and
                            "Has Statin At Least 180 Dates Before Date"(W.windowStartDate)
                ) 
    )

define "Has Revascularization Procedure With Statin Order":
    exists(
        [Procedure: "Revascularization Procedures"] P
            where
                "Has Statin At Least 180 Dates Before Date"(
                     PhEMAHelpers."Effective Date"(P)
                )
    )

define "Case":
    (
        Count("Potential 5 Day Windows") > 0
            and
        "Has Qualifying Statin Order And Lab In Any Window"("Potential 5 Day Windows")
    )
        or
    "Has Revascularization Procedure With Statin Order"
