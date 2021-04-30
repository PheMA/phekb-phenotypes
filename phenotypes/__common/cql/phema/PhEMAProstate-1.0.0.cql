/**
    Common function related to prostate cancer
*/
library PhEMAProstate version '1.0.0'

using FHIR version '4.0.0'

include FHIRHelpers version '4.0.0' called FHIRHelpers
include PhEMAHelpers version '1.0.0' called PhEMAHelpers

valueset "Prostate Cancer Treatment Procedures": '1197.prostate-cancer-treatment-procedures'

context Patient

/// Prostate Cancer Treatment

define "First Prostate Cancer Treatment Date":
    PhEMAHelpers."Earliest Date"(
      PhEMAHelpers."Effective Dates"([Procedure: "Prostate Cancer Treatment Procedures"])
    )