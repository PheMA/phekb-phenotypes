/**
    Common string functions
*/
library PhEMAString version '1.0.0'

using FHIR version '4.0.0'

include FHIRHelpers version '4.0.0' called FHIRHelpers

define function "GetId"(uri String):
	Last(Split(uri, '/'))