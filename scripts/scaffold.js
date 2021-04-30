const fs = require("fs");
const { exit } = require("process");
const { exec } = require("child_process");

const main = async () => {
  const args = process.argv.slice(2);

  if (args.length != 1) {
    console.log("Usage: yarn scaffold <phenotype-id.slug>");

    exit(1);
  }

  const phenotype = args[0];

  // create directories
  fs.mkdirSync(`phenotypes/${phenotype}`);
  fs.mkdirSync(`phenotypes/${phenotype}/cql`);
  fs.mkdirSync(`phenotypes/${phenotype}/valuesets`);
  fs.mkdirSync(`phenotypes/${phenotype}/test`);
  fs.mkdirSync(`phenotypes/${phenotype}/test/cases`);

  // create CQL file
  fs.writeFileSync(
    `phenotypes/${phenotype}/cql/${phenotype}.cql`,
    `/**
 * PheKB Phenotype
 *
 * Name : >> ADD Name <<
 * ID   : ${phenotype.split(".")[0]}
 * Url  : https://phekb.org/node/${phenotype.split(".")[0]}
 */
library "${phenotype}" version '1.0.0'

using FHIR version '4.0.0'

include FHIRHelpers version '4.0.0' called FHIRHelpers
include PhEMAHelpers version '1.0.0' called PhEMAHelpers

// valueset "Name": 'id'

context Patient

define "Case":
    true
`
  );

  // create test config
  fs.writeFileSync(
    `phenotypes/${phenotype}/test/cqlt.yaml`,
    `---
library:
  name: "${phenotype}"
  paths:
    - ../cql
    - ../../__common/cql
tests:
  path: cases
options:
  vsac:
    cache: ../../__common/.vscache
  date: "2020-09-17T00:00:00.0Z"
  dumpFiles:
    enabled: false # Change this to true to generate debugging output
    path: ../../../debugging_output
`
  );

  // create first test case template
  fs.writeFileSync(
    `phenotypes/${phenotype}/test/cases/${phenotype}.case-001-test.yaml`,
    `---
name: 001 >> ADD Name << Case

data:
  - resourceType: Patient
    name: Joe Smith
    gender: male
    birthDate: 1958-07-16

  # - resourceType: Encounter
  #   id: encounter-2
  #   period: "1978-11-12T16:00:00.000Z"
  #   serviceType: http://terminology.hl7.org/CodeSystem/service-type#276 Cardiovascular Disease

  # - resourceType: Procedure
  #   encounter: Encounter/encounter-2
  #   code: CPT#34800 Endovascular repair of infrarenal abdominal aortic aneurysm or dissection; using aorto-aortic tube prosthesis
  #   performedDateTime: "1978-11-12T16:00:00.000Z" # The patient was too young for this procedure to be considered

  # - resourceType: Observation
  #  code: LOINC#2085-9 Cholesterol in HDL [Mass/volume] in Serum or Plasma
  #   valueQuantity: 51 mg/dL
  #   effectiveDateTime: "2007-06-01T07:00:00.000Z"

  # - resourceType: Encounter
  #   id: encounter-1
  #   period: 2008-11-12T16:00:00.000
  #   serviceType: http://terminology.hl7.org/CodeSystem/service-type#15 Aromatherapy
  #   diagnosis:
  #   condition: Condition/condition-1

  # - resourceType: MedicationRequest
  #   code: RXNORM#139825 insulin detemir
  #   authoredOn: "2018-10-15T16:00:00.000Z"
  #   status: completed

  # - resourceType: Condition
  #   id: condition-1
  #   code: ICD9#441.3 Abdominal aortic aneurysm, ruptured
  #   onsetDateTime: "1998-12-12T16:00:00.000Z"

results:
  # Statement Name: Expected Value
  Case: true
`
  );

  let { stdout } = await checkout_branch(phenotype);
};

const checkout_branch = async (phenotype_slug) => {
  return new Promise(function (resolve, reject) {
    exec(`git checkout -b ${phenotype_slug}`, (err, stdout, stderr) => {
      if (err) {
        reject(err);
      } else {
        resolve({ stdout, stderr });
      }
    });
  });
};

main();
