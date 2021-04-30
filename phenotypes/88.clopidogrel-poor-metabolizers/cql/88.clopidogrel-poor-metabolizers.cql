/**
 * PheKB Phenotype
 *
 * Name : Clopidogrel Poor Metabolizers
 * ID   : 88
 * Url  : https://phekb.org/node/88
 */
library "88.clopidogrel-poor-metabolizers" version '1.0.0'

using FHIR version '4.0.0'

include FHIRHelpers version '4.0.0' called FHIRHelpers
include PhEMAHelpers version '1.0.0' called PhEMAHelpers

valueset "Myocardial Infarction Diagnoses": '88.myocardial-infarction'
valueset "Stent Procedures": '88.stent-procedures'
valueset "Revascularization Procedures": '88.revascularization-procedures'
valueset "Stroke Diagnoses": '88.stroke-diagnoses'
valueset "Clopidogrel": '88.clopidogrel'

context Patient

define function "Has Clopidogrel With Days Of Date"(
    numDays Decimal,
    date System.DateTime
):
    exists(
        [MedicationRequest: "Clopidogrel"] M
            where PhEMAHelpers."Effective Date"(M) in
                Interval[date - System.Quantity { value: numDays, unit: 'days' }, 
                         date + System.Quantity { value: numDays, unit: 'days' }]
    )


// Phenotype definition says "Code must occur on two successive days"
define "Myocardial Infarction":
    [Condition: "Myocardial Infarction Diagnoses"] MI
        where exists(
            [Condition: "Myocardial Infarction Diagnoses"] MI2
                where
                    ToDate(PhEMAHelpers."Effective Date"(MI2)) =
                    ToDate(PhEMAHelpers."Effective Date"(MI)) + 1 day
        )

define "Myocardial Infarction Diagnosis With Clopidogrel":
    ("Myocardial Infarction") C
        // Use a 7 day interval as proxy for "med list at discharge"
        where "Has Clopidogrel With Days Of Date"(
            7, // Based on median LOS from https://www.ncbi.nlm.nih.gov/pmc/articles/PMC6306951/
            PhEMAHelpers."Effective Date"(C)    
        )

define "Intracoronary Stent":
    exists([Procedure: "Stent Procedures"])

define "Index Date":
    PhEMAHelpers."Earliest Date"(
        PhEMAHelpers."Effective Dates"("Myocardial Infarction Diagnosis With Clopidogrel")
    )

define "Myocardial Infarction Diagnosis With Clopidogrel In Interval":
    exists(("Myocardial Infarction") MI
        where "Has Clopidogrel With Days Of Date"(
            30,
            PhEMAHelpers."Effective Date"(MI)   
        )
            and 
        PhEMAHelpers."Effective Date"(MI) in 
            Interval["Index Date" + 30 days, "Index Date" + 730 days]
    )

define "Revascularization With Clopidogrel In Interval":
    exists([Procedure: "Revascularization Procedures"] R
        where "Has Clopidogrel With Days Of Date"(
            30,
            PhEMAHelpers."Effective Date"(R)   
        )
            and 
        PhEMAHelpers."Effective Date"(R) in 
            Interval["Index Date" + 30 days, "Index Date" + 730 days]
    )

define "Stroke With Clopidogrel In Interval":
    exists([Condition: "Stroke Diagnoses"] S
        where "Has Clopidogrel With Days Of Date"(
            30,
            PhEMAHelpers."Effective Date"(S)   
        )
            and 
        PhEMAHelpers."Effective Date"(S) in 
            Interval["Index Date" + 30 days, "Index Date" + 730 days]
    )

define "Death With Clopidogrel In Interval":
    Coalesce(
        (
            Patient.deceased in Interval["Index Date" + 30 days, "Index Date" + 730 days]
                and
            "Has Clopidogrel With Days Of Date"(30, Patient.deceased)
        )
    , false)

define "Has Second Event With Clopidogrel":
    "Myocardial Infarction Diagnosis With Clopidogrel In Interval"
        or
    "Revascularization With Clopidogrel In Interval"
        or
    "Stroke With Clopidogrel In Interval"
        or
    "Death With Clopidogrel In Interval"    

define "Has Myocardial Infarction Diagnosis With Clopidogrel":
    exists("Myocardial Infarction Diagnosis With Clopidogrel")

define "Case":
    ("Has Myocardial Infarction Diagnosis With Clopidogrel"
        or
     "Intracoronary Stent")
        and
    "Has Second Event With Clopidogrel"
