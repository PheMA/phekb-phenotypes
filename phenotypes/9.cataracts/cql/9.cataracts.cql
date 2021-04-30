/**
 * PheKB Phenotype
 *
 * Name : Cataracts
 * ID   : 9
 * Url  : https://phekb.org/node/9
 */
library "9.cataracts" version '1.0.0'

using FHIR version '4.0.0'

include FHIRHelpers version '4.0.0' called FHIRHelpers
include PhEMAHelpers version '1.0.0' called PhEMAHelpers

valueset "Cataract Surgery": 'omop-concept-set-22'
valueset "Cataract Diagnosis": 'omop-concept-set-24'

context Patient

define "Has Cataract Surgery Procedure":
    exists([Procedure: "Cataract Surgery"])

define "Has Cataract Diagnoses":
    Count([Condition: "Cataract Diagnosis"]) >= 2

define "Earliest Surgery Date":
  First([Procedure: "Cataract Surgery"] S sort by FHIRHelpers.ToDateTime(performed)).performed as FHIR.dateTime

define "Earliest Diagnosis Date":
  First([Condition: "Cataract Diagnosis"] D sort by FHIRHelpers.ToDateTime(onset)).onset as FHIR.dateTime

define "Earliest diagnosis or surgery":
  First("Earliest Diagnosis Date" union "Earliest Surgery Date").value

define "50 years or older at first qualifying event":
  AgeInYearsAt("Earliest diagnosis or surgery") >= 50

// Determine if the patient is a case
define "Case":
  PhEMAHelpers."In Biobank" and
  ("Has Cataract Surgery Procedure" or "Has Cataract Diagnoses") and
  "50 years or older at first qualifying event"
