/**
 * Scaffold a new test for a phenotype with the next number
 */
const fs = require("fs");
const yargs = require("yargs");
const glob = require("glob");
const branchName = require("current-git-branch");

const padded = (number) => {
  let caseString;

  if (typeof number === "string") {
    caseString = number;
  } else {
    caseString = ("000" + number).slice(-3);
  }

  return caseString;
};

const newBlankTest = (number) => {
  return `---
name: ${padded(number)} >> ADD Name << Case

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
`;
};

const updateNumber = (testCase, number) => {
  return testCase.replace(/name:\s*?[0-9]{3}/, `name: ${padded(number)}`);
};

const writeTestCase = (testCase, slug, number, copy) => {
  fs.writeFileSync(
    `phenotypes/${slug}/test/cases/${slug}.case-${padded(number)}-test.yaml`,
    testCase
  );

  let message = `✅ Created test case ${padded(number)} for phenotype ${slug}`;

  if (copy) {
    message = message + ` by copying test case ${padded(number - 1)}`;
  } else {
    message = message + ` from a blank template`;
  }

  console.log(message);
};

const run = (slug, copy) => {
  if (!fs.existsSync(`phenotypes/${slug}`)) {
    console.log(`💥 Phenotype with slug '${slug}' does not exists`);
    process.exit(1);
  }

  // Get list of tests cases
  glob(`phenotypes/${slug}/test/cases/*.yaml`, (err, files) => {
    if (err) {
      const msg = `💥 Error listing test cases: ${err}`;
      console.error(msg);
      process.exit(1);
    }

    // Extract the largest number
    let max = 0;
    let maxFile = "";

    files.forEach((file) => {
      // "-test.yaml" preferred, but we have ".test.yaml" in some cases
      const regex = /.*-([0-9]{3})[-.]test\.yaml/;

      const num = parseInt(file.match(regex)[1]);

      if (num > max) {
        max = num;
        maxFile = file;
      }
    });

    // Create case with next number
    if (copy) {
      // Copy the previous test case and updated the number
      const maxTextCaseString = fs.readFileSync(maxFile, "utf8");
      const newTestCaseString = updateNumber(maxTextCaseString, max + 1);

      writeTestCase(newTestCaseString, slug, max + 1, copy);
    } else {
      const newTestCaseString = newBlankTest(max + 1);

      writeTestCase(newTestCaseString, slug, max + 1, copy);
    }
  });
};

const main = async () => {
  const options = yargs
    .usage("Usage: -s <slug>")
    .option("s", {
      alias: "slug",
      describe: "The phenotype slug",
      type: "string",
      demandOption: true,
    })
    .default("slug", () => {
      return branchName();
    })
    .option("c", {
      alias: "copy",
      describe: "Copy latest test case",
      type: "boolean",
      default: true,
      demandOption: false,
    }).argv;

  run(options.slug, options.copy);
};

main();
