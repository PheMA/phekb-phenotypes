/**
 * PheKB Phenotype
 *
 * Name : White Blood Cell Indices
 * ID   : 19
 * Url  : https://phekb.org/node/19
 */
library "19.white-blood-cell-indices" version '1.0.0'

using FHIR version '4.0.0'

include FHIRHelpers version '4.0.0' called FHIRHelpers

valueset "White Blood Cell Labs": '19.white-blood-cell-labs'
valueset "HIV Indication": '19.hiv-indication'
valueset "Dialysis Procedures": '19.dialysis-procedures'
valueset "Splenectomy Procedures": '19.splenectomy-procedures'

context Patient

define "Has HIV Indication":
    exists([Condition: "HIV Indication"])

define "Has Dialysis Procedure":
    exists([Procedure: "Dialysis Procedures"])

define "Has Splenectomy Procedure":
    exists([Procedure: "Splenectomy Procedures"])

define "Has WBC Sample":
    exists([Observation: "White Blood Cell Labs"])

define "Case":
    "Has WBC Sample"
        and
    (not "Has HIV Indication")
        and
    (not "Has Dialysis Procedure")
        and
    (not "Has Splenectomy Procedure")
    
    
