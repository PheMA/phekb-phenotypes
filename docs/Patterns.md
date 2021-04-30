# Phenotype to CQL Patterns

We have observed many common design patterns that appear in phenotype definitions, which have been reported in ["Design patterns for the development of electronic health record-driven phenotype extraction algorithms"](https://doi.org/10.1016/j.jbi.2014.06.007).

Here we provide example CQL for how to implement these patterns in practice, including supporting rationale.

## Medical setting of action

This may be done at different levels of granularity, including "Inpatient" or "Outpatient", or at the level of a specific department.

### Inpatient/Outpatient

This example comes from [a heart failure phenotype](https://github.com/PheMA/heart-failure-use-case/blob/master/definition/heart-failure.cql) which was considering both inpatient and outpatient examples.

Our first question is what FHIR resource to use in our CQL statement. The [Encounter](https://www.hl7.org/fhir/encounter.html) resource seems the most relevant. From here, looking at the different attributes we see `Encounter.class` gives us exactly the level of specification that we are interested in, as it is constrained by the [ActEncounterCode](https://www.hl7.org/fhir/v3/ActEncounterCode/vs.html) value set and we can select specific codes like `AMB` for ambulatory encounters.

Here's an example library that looks for loosely defined "inpatient" and "outpatient" encounters. Note that for a specific purpose, your definition of inpatient or outpatient may need to include other codes in [ActEncounterCode](https://www.hl7.org/fhir/v3/ActEncounterCode/vs.html).

```
library EncounterExample

using FHIR version '4.0.0'

codesystem "ActEncounterCode": 'http://terminology.hl7.org/ValueSet/v3-ActEncounterCode'

code "Inpatient Encounter": 'IMP' from "ActEncounterCode"
code "Outpatient Encounter": 'AMB' from "ActEncounterCode"

context Patient

define "Any Outpatient Encounters":
    [Encounter: "Outpatient Encounter"] E

define "Any Inpatient Encounters":
    [Encounter: "Inpatient Encounter"] E

define "Encounter Criteria":
    exists("Any Inpatient Encounters") or
    exists("Any Outpatient Encounters")
```

### Specific department

Sometimes we need to be more specific as to where an encounter took place. This may be tied to a specific department or specialty. Here we are considering how to specify that an encounter was in a certain medical department.

The first question we have is how to represent each department as a coded value. In reviewing specific examples using OHDSI's Athena tool, we see that they have a [Place of Service](https://athena.ohdsi.org/search-terms/terms?domain=Place+of+Service&page=1&pageSize=15&query=) vocabulary domain which is a collection of SNOMED and Nebraska Lexicon codes. Navigating the hierarchy of these codes, we can see that these roll up to the [Health encounter sites](https://athena.ohdsi.org/search-terms/terms/4192764) SNOMED code.

One caveat is that we haven't explicitly tested every possible mapping from a department/specialty to these SNOMED codes to guarantee coverage. Using a few examples though, this seems like a reasonable starting place.

Our next question is what FHIR resource to use in our CQL statement. The [Encounter](https://www.hl7.org/fhir/encounter.html) resource seems the most relevant.

If the phenotype definition is referring to a department/location in the context of what is done at that location, it's possible that `Encounter.serviceType` would be more appropriate. There is an [existing value set](https://www.hl7.org/fhir/valueset-service-type.html) which has several options, but note that these do not map to our SNOMED definitions.

It may be more appropriate to use the `Encounter.location` attribute, which is a reference to a `Location` resource. More specifically, `Location.type` is [associated with a value set](https://www.hl7.org/fhir/v3/ServiceDeliveryLocationRoleType/vs.html) that describes another classification for the type of service delivery performed at that location. It sounds like it would mirror `Encounter.serviceType`, but they are completely different value sets.

Here is an example library to find encounters with a service type of `Cardiovascular Disease`. A similar library could be built for `Encounter.location.type`, but using the appropriate code system.

**WARNING: Still testing this code**

```
library ServiceTypeExample

using FHIR version '4.0.0'
include FHIRHelpers version '4.0.0' called FHIRHelpers

codesystem "ServiceType": 'http://terminology.hl7.org/CodeSystem/service-type'

code "Cardiovascular Disease": '276' from "ServiceType"

context Patient

define "Encounter Criteria":
    exists([Encounter] E where E.serviceType = "Cardiovascular Disease")
```

## Provider diagnosis

Sometimes the phenotype definition specifies that a diagnosis should be made by
a provider and/or come from the encounter or problem list. We use `Condition` to
model this as follows.

#### CQL

```
codesystem "ConditionCategoryCodes": 'http://terminology.hl7.org/CodeSystem/condition-category'
code "problem-list-item": 'problem-list-item' from "ConditionCategoryCodes"
code "encounter-diagnosis": 'encounter-diagnosis' from "ConditionCategoryCodes"
concept "PhysicianDiagnosisCategory": { "problem-list-item", "encounter-diagnosis" } display 'Physician Diagnosis Category'

define "Has Physician T2DM Diagnosis":
  Count([Condition: "Type 2 DM"] C
    where C.category ~ "PhysicianDiagnosisCategory") >= 2
```

#### Data

```yaml
 - resourceType: Condition
    code: ICD9CM#250.52 Diabetes with ophthalmic manifestations, type II or unspecified type, uncontrolled
    onsetDateTime: "2014-10-10T00:00:00.000Z"
    recordedDate: "2014-10-10T16:00:00.000Z"
    category: http://terminology.hl7.org/CodeSystem/condition-category#problem-list-item Problem List

```

## Medications

There are very many ways to model medications in FHIR with varying levels of
complexity. It is possible to model the workflow order-dispense-administration
workflow step by step, and it is also possible to just capture that a drug was
take using a single resource. In this work we opt for the latter approach, but
we should discuss the implications in the publication.

We choose to model drugs at the RxNorm ingredient level unless the phenotype
definition explicitly states otherwise, and we use the `MedicationRequest` resource
with `status = completed` as follows:

#### CQL

```
define function "Sodium Channel Blocking Drugs Before Date"(
    endDate DateTime
):
    [MedicationRequest: "Sodium Channel Blocking Drugs"] M
        where M.authoredOn on or before endDate
```

#### Data

```yaml
- resourceType: MedicationRequest
  code: RXNORM#5691 imipramine
  authoredOn: "2007-11-12T16:00:00.000Z"
  status: completed
```

## NLP

We are currently ignoring the NLP parts of phenotype definitions as we currently
have no NLP pipeline in place to integrate with.

## Lab Values

We use `Observation` resources with **LOINC** codes to model labs.

## Genotyped for eEMERGE

Many of the eMERGE phenotypes only consider patients that have been sequenced. We
model this using an `Observation` noting that biobank specimens are available:

```yaml
- resourceType: Observation
  code: LOINC#75520-7 Biobank specimens are stored and available for research
```

## Other Conventions

- We use a top-level statement with the name `"Case"` as the phenotype entry
  point. If this statement evaluates to true for a patient, then they are considered
  a case.
- We use `ValueSet` resources as much as possible instead of individual codes or
  concepts.
