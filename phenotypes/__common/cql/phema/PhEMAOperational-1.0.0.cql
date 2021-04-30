/**
    Stub implementaitons of local operational logic. The idea is that sites
    override these functions with implementations that make sense in the local
    context.

    This is necessary because some criteria do not have universally appl
*/
library PhEMAOperational version '1.0.0'

using FHIR version '4.0.0'

//// ENROLLMENT

define function "Continuous Years Of Enrollment" (
    numYears Integer
):
    // Individual sites must implement this method
	true


//// LOCAL REGISTRIES

define "Exists In Local Registry":
    // Individual sites must implement this method
    false