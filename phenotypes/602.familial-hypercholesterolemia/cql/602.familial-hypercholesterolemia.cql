/**
 * PheKB Phenotype
 *
 * Name : Familial Hypercholesterolemia
 * ID   : 602
 * Url  : https://phekb.org/node/602
 */
library "602.familial-hypercholesterolemia" version '1.0.0'

using FHIR version '4.0.0'

include FHIRHelpers version '4.0.0' called FHIRHelpers
include PhEMAHelpers version '1.0.0' called PhEMAHelpers

// Lipid profile
valueset "Total Cholesterol": '602.total-cholesterol'
valueset "LDL-C": '602.ldl-c'
valueset "HDL": '602.hdl'
valueset "Triglycerides": '602.triglycerides'

// Secondary causes
valueset "Thyroid Stimulating Hormone": '602.tsh'
valueset "Alkaline Phosphatase": '602.alkaline-phosphatase'
valueset "Total Bilirubin": '602.total-bilirubin'
valueset "Protein In 24h Urine Collection": '602.protein-in-urine'
valueset "Urine Protein/Creatine Ratio": '602.urine-protein-creatine-ratio'
valueset "Creatinine": '602.creatinine'
valueset "Estimated Glomerular Filtration Rate": '602.egfr'
valueset "HbA1c": '602.hba1c'
valueset "Fasting Glucose Capillary": '602.fasting-glucose-capillary'
valueset "Fasting Glucose Serum": '602.fasting-glucose-serum'

// Lowering procs/meds
valueset "Lipid Lowering Medications": '602.lipid-lowering-meds'
valueset "Lipid Lowering Procedures": '602.lipid-lowering-procs'

// ASCVD indicators
valueset "Coronary Heart Disease Indicator Diagnoses": '602.chd-indicator-dx'
valueset "Coronary Heart Disease Indicator Procedures": '602.chd-indicator-px'
valueset "Cerebrovascular Disease Indicator Diagnoses": '602.cvd-indicator-dx'
valueset "Cerebrovascular Disease Indicator Procedures": '602.cvd-indicator-px'
valueset "Peripheral Arterial Disease Indicator Diagnoses": '602.pad-indicator-dx'
valueset "Peripheral Arterial Disease Indicator Diagnoses (Need 2 Codes)": '602.pad-indicator-dx-2'

context Patient

//// Lipid profile

define function "HDL On Date"(
    dt System.DateTime
):
    // Not perfect, we could take the latest value
    First(
        [Observation: "HDL"] O
            where
                ToDate(dt) = ToDate(PhEMAHelpers."Effective Date"(O))
            return
                O.value as Quantity
    )

define function "Triglycerides On Date"(
    dt System.DateTime
):
    // Not perfect, we could take the latest value
    First(
        [Observation: "Triglycerides"] O
            where
                ToDate(dt) = ToDate(PhEMAHelpers."Effective Date"(O))
            return
                O.value as Quantity
    )

// Direct LDL measurement, or values for the Friedewald equation
define "Has Lipid Profile":
    exists([Observation: "LDL-C"])
        or
    (
        // This is imperfect because it doesn't check that they are all on
        // the same day, but we fail later if they aren't
        exists([Observation: "Total Cholesterol"])
            and
        exists([Observation: "HDL"])
            and
        exists([Observation: "Triglycerides"])
    )

define "Has High Triglycerides":
    Count(
        [Observation: "Triglycerides"] TG
            where TG.value >= System.Quantity { value: 500, unit: 'mg/dL' }
    ) >= 2

define "Get All Friedewald Values":
    // Iterate over all total cholersterol values, find an HDL and TG 
    [Observation: "Total Cholesterol"] TC
        where
            "HDL On Date"(PhEMAHelpers."Effective Date"(TC)) is not null
                and
            "Triglycerides On Date"(PhEMAHelpers."Effective Date"(TC)) is not null
        return
            Tuple {
                date: PhEMAHelpers."Effective Date"(TC),
                // Making assumption about the units here
                ldl: (TC.value as Quantity) - ("HDL On Date"(PhEMAHelpers."Effective Date"(TC)) as Quantity) - (("Triglycerides On Date"(PhEMAHelpers."Effective Date"(TC)) as Quantity) / 5)
            }

define "Highest Friedewald LDL/Date Tuple":
    First(
        ("Get All Friedewald Values") F
            sort by ldl desc
    )   

define "Highest LDL Direct Measurement":
    First(
        [Observation: "LDL-C"] L
            sort by FHIRHelpers.ToQuantity(value) desc
    ) 

define "Highest LDL/Date Tuple":
    // If both direct measurement and Friedewald exist, return highest
    if exists("Highest LDL Direct Measurement") and exists("Highest Friedewald LDL/Date Tuple") then
        if FHIRHelpers.ToQuantity("Highest LDL Direct Measurement".value) > "Highest Friedewald LDL/Date Tuple".ldl then
            Tuple {
                date: PhEMAHelpers."Effective Date"("Highest LDL Direct Measurement"),
                ldl: FHIRHelpers.ToQuantity("Highest LDL Direct Measurement".value)
            }
        else
            "Highest Friedewald LDL/Date Tuple"
    else if exists("Highest LDL Direct Measurement") then
        Tuple {
            date: PhEMAHelpers."Effective Date"("Highest LDL Direct Measurement"),
            ldl: FHIRHelpers.ToQuantity("Highest LDL Direct Measurement".value)
        }
    else
        "Highest Friedewald LDL/Date Tuple"

define "Index Date":
    "Highest LDL/Date Tuple".date

//// Lipid profile

///// Treatment

define "Has Lipid Lowering Treatment In Interval":
    exists(
        [MedicationRequest: "Lipid Lowering Medications"] M
            where PhEMAHelpers."Effective Date"(M) in Interval
                ["Highest LDL/Date Tuple".date - 1 year, 
                 "Highest LDL/Date Tuple".date - 6 weeks]
    )
        or
    exists(
        [Procedure: "Lipid Lowering Procedures"] P
            where PhEMAHelpers."Effective Date"(P) in Interval
                ["Highest LDL/Date Tuple".date - 1 year, 
                 "Highest LDL/Date Tuple".date - 6 weeks]
    )   

///// Treatment

///// Secondary Causes

define "Has Hypothyroidism":
    exists(
        [Observation: "Thyroid Stimulating Hormone"] TSH
            where TSH.value >= System.Quantity { value: 10.0, unit: 'mU/L' }
    )

define "Has Biliary Obstruction":
    exists(
        [Observation: "Alkaline Phosphatase"] AP
            where AP.value >= System.Quantity { value: 200.0, unit: 'IU/L' }
    )

define "Has Liver Disease":
    exists(
        [Observation: "Total Bilirubin"] B
            where B.value > System.Quantity { value: 2.0, unit: 'mg/dL' }
    )
    
define "Has Nephrotic Syndrome":
    exists(
        [Observation: "Protein In 24h Urine Collection"] P24
            where P24.value > System.Quantity { value: 3.0, unit: 'g' }
    )
        or
    exists(
          [Observation: "Urine Protein/Creatine Ratio"] PCR
            where 
                PhEMAHelpers.RatioToQuantity(
                    FHIRHelpers.ToRatio(PCR.value as Ratio)
                ) > 3.0
    )

define "Has Renal Failure":
    exists(
        [Observation: "Creatinine"] C
            where C.value > System.Quantity { value: 2.6, unit: 'mg/dL' }
    )
        or
    exists(
        [Observation: "Estimated Glomerular Filtration Rate"] GFR
            where GFR.value < System.Quantity { value: 15.0, unit: 'mL/min' }
    )

define "Has Diabetes":
    exists(
        [Observation: "HbA1c"] H
            where H.value > System.Quantity { value: 9.0, unit: '%' }
    )
        or
    exists(
        [Observation: "Fasting Glucose Capillary"] FGC
            where FGC.value > System.Quantity { value: 200.0, unit: 'mg/dL' }
    )
        or
    exists(
        [Observation: "Fasting Glucose Serum"] FGS
            where FGS.value > System.Quantity { value: 220.0, unit: 'mg/dL' }
    )

define "Has Secondary Cause Of Hypercholesterolemia":
    "Has Hypothyroidism"
        or
    "Has Biliary Obstruction"
        or
    "Has Liver Disease"
        or
    "Has Nephrotic Syndrome"
        or
    "Has Renal Failure"
        or
    "Has Diabetes"

///// Secondary Causes

define "In Base Population":
    AgeInYears() >= 18
        and
    "Has Lipid Profile"

define "Adjusted LDL Value":
    if "Has Lipid Lowering Treatment In Interval" then
        System.Quantity { 
            value: "Highest LDL/Date Tuple".ldl.value / 0.7, 
            unit: 'mg/dL' 
        }
    else 
        "Highest LDL/Date Tuple".ldl

define "Adjusted Highest LDL Meets Case Threshold":
    "Adjusted LDL Value" >= System.Quantity { value: 155, unit: 'mg/dL' } 

///// Stage I

define "Stage I":
    "In Base Population"
        and
    (not "Has Secondary Cause Of Hypercholesterolemia")
        and
    (not "Has High Triglycerides") // this is shown in the flowchart
        and
    "Adjusted Highest LDL Meets Case Threshold"

///// Stage II

// Premature ASCVD case status: presence of two or more pertinent diagnosis
// and/or procedural codes in EHR before age 56 in men and 66 in women.

define function "Is Premature At Date"(
    dt System.DateTime
):
    if PhEMAHelpers."Is Female" then
        AgeInYearsAt(dt) < 66
    else
        // Treating all non-female genders as male to be conservative
        AgeInYearsAt(dt) < 56

define "Has Premature CHD":
    Count(
        (
            [Condition: "Coronary Heart Disease Indicator Diagnoses"] C
                where "Is Premature At Date"(PhEMAHelpers."Effective Date"(C))
        )
        union
        (
            [Procedure: "Coronary Heart Disease Indicator Procedures"] P
                where "Is Premature At Date"(PhEMAHelpers."Effective Date"(P))
        )
    ) >= 2

define "CVD or Single PAD Diagnoses":
    (
        [Condition: "Cerebrovascular Disease Indicator Diagnoses"] C
            where "Is Premature At Date"(PhEMAHelpers."Effective Date"(C))
    )
    union
    (
        [Procedure: "Coronary Heart Disease Indicator Procedures"] P
            where "Is Premature At Date"(PhEMAHelpers."Effective Date"(P))

    )
    union
    (
        [Condition: "Peripheral Arterial Disease Indicator Diagnoses"] C2
            where "Is Premature At Date"(PhEMAHelpers."Effective Date"(C2))  
    )

define "Has PAD Diagnosis Requiring Two Codes":
    exists(
        // These conditions require two dx
        [Condition: "Peripheral Arterial Disease Indicator Diagnoses (Need 2 Codes)"] C
            where
                "Is Premature At Date"(PhEMAHelpers."Effective Date"(C))
                    and
                Count(
                    [Condition: C.code] CC
                        where "Is Premature At Date"(PhEMAHelpers."Effective Date"(CC))
                ) >= 2
    )

define "Has Premature CVD Or PAD":
    Count("CVD or Single PAD Diagnoses") >= 2
        or
    (
        Count("CVD or Single PAD Diagnoses") = 1    
            and
        "Has PAD Diagnosis Requiring Two Codes"
    )

define "Group I":
    case
        when "Adjusted LDL Value".value > 325 then
            8
        when "Adjusted LDL Value".value >= 251 then
            5
        when "Adjusted LDL Value".value >= 191 then
            3
        when "Adjusted LDL Value".value >= 155 then
            1
        else
            0
    end

define "Group II":
    case
        when "Has Premature CHD" then
            2
        when "Has Premature CVD Or PAD" then
            1
        else
            0
    end

define "Stage II":
    "Group I" + "Group II" // Other groups are NLP only   

define "Case":
    "Stage I"
        and
    // This numeric value should probably be adjusted since we ignore NLP
    ("Stage II" >= 6)

