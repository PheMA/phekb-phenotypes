/**
 * PheKB Phenotype
 *
 * Name : Multimodal Analgesia
 * ID   : 1053
 * Url  : https://phekb.org/node/1053
 */
library "1053.multimodal-analgesia" version '1.0.0'

using FHIR version '4.0.0'

include FHIRHelpers version '4.0.0' called FHIRHelpers
include PhEMAHelpers version '1.0.0' called PhEMAHelpers
include PhEMAString version '1.0.0' called PhEMAString
include MATGlobalCommonFunctions version '4.0.000' called Global

valueset "Surgery Procedures": '1197.surgery-procedures'
valueset "Opioids": '1053.opioids'
valueset "Acetaminophen": '1053.acetaminophen'
valueset "NSAIDs": '1053.nsaids'

context Patient

define function "Encounter From Surgery"(
    proc FHIR.Procedure
):
    SingletonFrom( // This just converts the list into a single encounter
        [Encounter] E
            where PhEMAString."GetId"(proc.encounter.reference) = E.id
    )

define function "Encounter Has Opioid At Discharge"(
    enc FHIR.Encounter
):
    if enc is null then
        false
    else
        exists(
            [MedicationRequest: "Opioids"] M
                where
                    PhEMAString."GetId"(M.encounter.reference) = enc.id
                        and
                    M.category ~ Global."Discharge"
        )

define function "Encounter Has Acetaminpphen At Discharge"(
    enc FHIR.Encounter
):
    if enc is null then
        false
    else
        exists(
            [MedicationRequest: "Acetaminophen"] M
                where
                    PhEMAString."GetId"(M.encounter.reference) = enc.id
                        and
                    M.category ~ Global."Discharge"
        )

define function "Encounter Has NSAIDs At Discharge"(
    enc FHIR.Encounter
):
    if enc is null then
        false
    else
        exists(
            [MedicationRequest: "NSAIDs"] M
                where
                    PhEMAString."GetId"(M.encounter.reference) = enc.id
                        and
                    M.category ~ Global."Discharge"
        )

define function "Encounter Has Another Analgesic At Discharge"(
    enc FHIR.Encounter
):
    "Encounter Has Acetaminpphen At Discharge"(enc)
        or
    "Encounter Has NSAIDs At Discharge"(enc)

// Fail fast sanity check, all the logic is really in the next statement
define "Has Surgery Procedure":
    exists([Procedure: "Surgery Procedures"])

define "Has Surgery With Multimodal Analgesia At Discharge":
    exists(
        [Procedure: "Surgery Procedures"] P
            where
                "Encounter Has Opioid At Discharge"("Encounter From Surgery"(P))
                    and
                "Encounter Has Another Analgesic At Discharge"("Encounter From Surgery"(P))
    )

define "Case":
    "Has Surgery Procedure"
        and
    "Has Surgery With Multimodal Analgesia At Discharge"