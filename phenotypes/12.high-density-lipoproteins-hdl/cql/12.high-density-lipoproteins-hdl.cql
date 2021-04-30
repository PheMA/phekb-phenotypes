/**
 * PheKB Phenotype
 *
 * Name : High-Density Lipoproteins (HDL)
 * ID   : 12
 * Url  : https://phekb.org/node/12
 *
 * This phenotype identifies patients that have two or more LDL observations that
 * occurred before any lipid impacting event
 */
library "12.high-density-lipoproteins-hdl" version '1.0.0'

using FHIR version '4.0.0'

include FHIRHelpers version '4.0.0' called FHIRHelpers
include PhEMAHelpers version '1.0.0' called PhEMAHelpers
include PhEMADiabetes version '1.0.0' called PhEMADiabetes

valueset "HDL Labs": 'omop-concept-set-47'
valueset "Diabetes Codes": 'omop-concept-set-46'

valueset "Fasting Glucose": 'omop-concept-set-30'
valueset "Random Glucose": 'omop-concept-set-31'
valueset "Hemoglobin A1C": 'omop-concept-set-32'

valueset "Cancer Codes": '2.16.840.1.113762.1.4.1116.231'

valueset "Hyperthyroidism Codes": 'omop-concept-set-48'
valueset "Hypothyroidism Codes": 'omop-concept-set-50'
valueset "Levothyroxine Meds": 'omop-concept-set-51'
valueset "Gemfibrozil Meds": 'omop-concept-set-55'
valueset "Niacin Meds": 'omop-concept-set-56'
valueset "Estrogen Meds": 'omop-concept-set-57'
valueset "TSH Labs": 'omop-concept-set-49'

valueset "Statin Meds": '2.16.840.1.113762.1.4.1021.7'

/////////// DIABETES

define "Has Diabetes Code":
    exists([Condition: "Diabetes Codes"])

define "Earliest Diabetes Diagnosis Date":
    PhEMAHelpers."Earliest"([Condition: "Diabetes Codes"])

define "Earliest Bad Random Glucose":
    PhEMAHelpers."Earliest"(
        PhEMADiabetes."Abnormal Random Glucose"(200)
    )

define "Earliest Bad HbA1c":
    PhEMAHelpers."Earliest"(
        PhEMADiabetes."Abnormal Hemoglobin A1C"(6.0)
    )

define "Second Bad Fasting Glucose":
    if Count(PhEMADiabetes."Abnormal Fasting Glucose"(126.0)) >= 2 then
        PhEMAHelpers."Latest"(
            PhEMADiabetes."Abnormal Fasting Glucose"(126.0)
        )
    else
        null

define "Diabetes Indicators":
    ({
        PhEMAHelpers."Effective Dates"("Earliest Diabetes Diagnosis Date"),
        PhEMAHelpers."Effective Dates"("Earliest Bad Random Glucose"),
        PhEMAHelpers."Effective Dates"("Earliest Bad HbA1c"),
        PhEMAHelpers."Effective Dates"("Second Bad Fasting Glucose")
    }) R
        where R is not null

define "HbA1c Test And Bad Random Glucose":
    exists([Observation : "Hemoglobin A1C"])
        and
    exists(PhEMADiabetes."Abnormal Random Glucose"(200))

define "Earliest HbA1C or Bad Random Glucose":
    PhEMAHelpers."Earliest"(flatten {
        [Observation : "Hemoglobin A1C"],
        PhEMADiabetes."Abnormal Random Glucose"(200)
    })

define "Earliest Diabetes Indication":
    if "Has Diabetes Code" then
        PhEMAHelpers."Earliest Date"("Diabetes Indicators")
    else if "HbA1c Test And Bad Random Glucose" then
        PhEMAHelpers."Effective Date"(
            "Earliest HbA1C or Bad Random Glucose"
        )
    else
        null

/////////// CANCER

define "Earliest Cancer Indication":
    PhEMAHelpers."Effective Date"(
        PhEMAHelpers."Earliest"([Condition: "Cancer Codes"])
    )

/////////// HYPERTHYROIDISM

define "Earliest Hyperthyroidism Diagnosis":
    PhEMAHelpers."Earliest"(
        [Condition: "Hyperthyroidism Codes"] C
            where PhEMAHelpers."Dx Count"(FHIRHelpers.ToConcept(C.code)) >= 2
    )

define "Earliest Hypothyroidism Diagnosis":
    PhEMAHelpers."Earliest"(
        [Condition: "Hypothyroidism Codes"] C
            where PhEMAHelpers."Dx Count"(FHIRHelpers.ToConcept(C.code)) >= 2
    )

define "Earliest Levothyroxine Med":
    PhEMAHelpers."Earliest"(
        [MedicationRequest: "Levothyroxine Meds"] M
    )

define "Bad TSH Lab":
 [Observation: "TSH Labs"] O
    where
        case
            when PhEMAHelpers."Effective Date"(O) before @1990-02-06 then
                // 11/13/1986	2/6/1990	0.29	5.00
                O.value < System.Quantity { value: 0.29, unit: 'mU/L' }
                    or
                O.value > System.Quantity { value: 5.00, unit: 'mU/L' }
            when PhEMAHelpers."Effective Date"(O) before @1993-05-27 then
                // 2/7/1990	5/27/1993	0.46	3.60
                O.value < System.Quantity { value: 0.46, unit: 'mU/L' }
                    or
                O.value > System.Quantity { value: 3.60, unit: 'mU/L' }
            when PhEMAHelpers."Effective Date"(O) before @1995-03-31 then
                // 5/28/1993	3/31/1995	0.55	4.10
                O.value < System.Quantity { value: 0.55, unit: 'mU/L' }
                    or
                O.value > System.Quantity { value: 4.10, unit: 'mU/L' }
            when PhEMAHelpers."Effective Date"(O) before @1999-05-18 then
                // 4/1/1995	5/18/1999	0.46	4.88
                O.value < System.Quantity { value: 0.46, unit: 'mU/L' }
                    or
                O.value > System.Quantity { value: 4.88, unit: 'mU/L' }
            when PhEMAHelpers."Effective Date"(O) before @2004-05-10 then
                // 5/19/1999	10/5/2004	0.40	5.70
                O.value < System.Quantity { value: 0.40, unit: 'mU/L' }
                    or
                O.value > System.Quantity { value: 5.70, unit: 'mU/L' }
            else
                // 10/6/2004	Current	0.35	4.50
                O.value < System.Quantity { value: 0.35, unit: 'mU/L' }
                    or
                O.value > System.Quantity { value: 4.50, unit: 'mU/L' }
        end

define "Earliest Hyper/Hypothyroidism Indication":
    PhEMAHelpers."Earliest Date"(flatten {
        PhEMAHelpers."Effective Dates"("Earliest Hyperthyroidism Diagnosis"),
        PhEMAHelpers."Effective Dates"("Earliest Hypothyroidism Diagnosis"),
        PhEMAHelpers."Effective Dates"("Earliest Levothyroxine Med"),
        PhEMAHelpers."Effective Dates"("Bad TSH Lab")
    })

define "Earliest Statin Use Indication":
    PhEMAHelpers."Earliest Date"(flatten {
        PhEMAHelpers."Effective Dates"([MedicationRequest: "Statin Meds"])
    })

define "Earliest Gemfibrozil Use Indication":
    PhEMAHelpers."Earliest Date"(flatten {
        PhEMAHelpers."Effective Dates"([MedicationRequest: "Gemfibrozil Meds"])
    })

define "Earliest Niacin Use Indication":
    PhEMAHelpers."Earliest Date"(flatten {
        PhEMAHelpers."Effective Dates"([MedicationRequest: "Niacin Meds"])
    })

define "Earliest Estrogen Use Indication":
    PhEMAHelpers."Earliest Date"(flatten {
        PhEMAHelpers."Effective Dates"([MedicationRequest: "Estrogen Meds"])
    })

/////////// CENSORING LOGIC

define "Earliest Lipid Impacting Event":
    PhEMAHelpers."Earliest Date"(flatten {
        "Earliest Diabetes Indication",
        "Earliest Cancer Indication",
        "Earliest Hyper/Hypothyroidism Indication",
        "Earliest Statin Use Indication",
        "Earliest Gemfibrozil Use Indication",
        "Earliest Niacin Use Indication",
        "Earliest Estrogen Use Indication"
    })

define "Has Two Or More HDLs Before Lipid Impacting Event":
    PhEMAHelpers."Number Of Observations Before Date"(
        [Observation: "HDL Labs"],
        "Earliest Lipid Impacting Event"
    ) >= 2

define "Case":
    "Has Two Or More HDLs Before Lipid Impacting Event"
