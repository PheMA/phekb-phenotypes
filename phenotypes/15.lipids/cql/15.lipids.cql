/**
 * PheKB Phenotype
 *
 * Name : Lipids
 * ID   : 15
 * Url  : https://phekb.org/node/15
 */
library "15.lipids" version '1.0.0'

using FHIR version '4.0.0'

include FHIRHelpers version '4.0.0' called FHIRHelpers
include PhEMAHelpers version '1.0.0' called PhEMAHelpers

valueset "Hormone Therapy Medications": '15.hormone-therapy-meds'
valueset "Antilipemic Medications": '15.antilipemic-meds'
valueset "Thyroid Disorder Diagnoses": '15.thyroid-disorder-dx'
valueset "Diabetes Diagnoses": '15.diabetes-dx'
valueset "Cancer Diagnoses": '15.cancer-dx'
valueset "LDL-C Laboratory Results": '15.ldl-labs'

context Patient

define "Earliest diagnosis exclusion":
    PhEMAHelpers."Effective Date"(
        PhEMAHelpers."Earliest"((
            [Condition: "Thyroid Disorder Diagnoses"]
                union
            [Condition: "Diabetes Diagnoses"]
                union
            [Condition: "Cancer Diagnoses"]
        ))
    )

define "Earliest medication exclusion":
    PhEMAHelpers."Effective Date"(
        PhEMAHelpers."Earliest"((
            [MedicationRequest: "Hormone Therapy Medications"]
                union
            [MedicationRequest: "Antilipemic Medications"]
        ))
    )

define "Earliest exclusion date":
    PhEMAHelpers."Earliest Date"(flatten {
        "Earliest medication exclusion",
        "Earliest diagnosis exclusion"
    })

define "Has LDL-C measure before exclusion date":
    exists(
        [Observation: "LDL-C Laboratory Results"] C
            where "Earliest exclusion date" is null
                    or
                PhEMAHelpers."Effective Date"(C) before "Earliest exclusion date"
    )

define "Case":
    "Has LDL-C measure before exclusion date"
