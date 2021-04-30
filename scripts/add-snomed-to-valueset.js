#!/usr/bin/env node

/**
 * Takes a ValueSet resource as input, reads the ICD9 codes, and adds the
 * matching SNOMED codes
 *
 * Run as follows: node scripts/add-snomed-to-valueset.js -v phenotypes/1516.thrombotic-event/valuesets/1516.thrombotic-event-valuesets.bundle.json  -m mapping/ICD9CM_SNOMED_MAP_1TO1_202012.txt mapping/ICD9CM_SNOMED_MAP_1TOM_202012.txt
 *
 * Change the -v parameter to point to the value set or bundle you want to map
 */
const fs = require("fs");
const yargs = require("yargs");
const readline = require("readline");

// ICD_CODE	ICD_NAME	IS_CURRENT_ICD	IP_USAGE	OP_USAGE	AVG_USAGE	IS_NEC	SNOMED_CID	SNOMED_FSN	IS_1-1MAP	CORE_USAGE	IN_CORE
const cols = {
  ICD_CODE: 0,
  ICD_NAME: 1,
  IS_CURRENT_ICD: 2,
  IP_USAGE: 3,
  OP_USAGE: 4,
  AVG_USAGE: 5,
  IS_NEC: 6,
  SNOMED_CID: 7,
  SNOMED_FSN: 8,
  IS_1_1MAP: 9,
  CORE_USAGE: 10,
  IN_CORE: 11,
};

const prepareMapFile = async (map, mapping) => {
  console.log(`✅ Parsing mapping file ${mapping}`);
  const fileStream = fs.createReadStream(mapping);

  const rl = readline.createInterface({
    input: fileStream,
    crlfDelay: Infinity,
  });

  let lineno = 0;
  for await (const line of rl) {
    // ignore header
    if (lineno > 0) {
      const values = line.split("\t");

      const icd = map.get(values[cols.ICD_CODE]);

      if (icd) {
        // Don't put duplicates in the map
        if (!icd.some((code) => code.code === values[cols.SNOMED_CID])) {
          icd.push({
            code: values[cols.SNOMED_CID],
            display: values[cols.SNOMED_FSN],
          });
        }
      } else {
        map.set(values[cols.ICD_CODE], [
          {
            code: values[cols.SNOMED_CID],
            display: values[cols.SNOMED_FSN],
          },
        ]);
      }
    }

    lineno++;
  }
  console.log(`✅ Processed ${lineno} mappings`);

  return map;
};

const prepareMap = async (mappings) => {
  const map = new Map();

  for (const mapping of mappings) {
    await prepareMapFile(map, mapping);
  }

  return map;
};

const updatedValueSets = (map, valuesetOrBundle, id) => {
  const text = fs.readFileSync(valuesetOrBundle).toString();
  const resource = JSON.parse(text);

  const updateValueSet = (valueset) => {
    const codes = [];
    // Collect all ICD9 codes
    valueset.compose.include.forEach((include) => {
      if (include.system === "http://hl7.org/fhir/sid/icd-9-cm") {
        include.concept.forEach((concept) => {
          codes.push(concept.code);
        });
      }
    });

    // Get the corresponding SNOMED codes
    const mapped = [];
    if (codes.length == 0) {
      console.log(`❌ No ICD-9 codes found in ValueSet ${valueset.id}`);
      return;
    } else {
      codes.forEach((code) => {
        const snomed = map.get(code);

        if (snomed == null) {
          console.log(`❌ No SNOMED mapping found for ICD-9 ${code}`);
        } else {
          console.log(
            `✅ Found ${snomed.length} mapping(s) for ICD-9 code ${code}`
          );
          mapped.push(...snomed);
        }
      });
    }

    // Create a new include and add it to the value set
    const include = {
      system: "http://snomed.info/sct",
      concept: [],
    };

    mapped.forEach((code) => {
      include.concept.push(code);
    });

    if (include.concept.length > 0) {
      valueset.compose.include.push(include);
    } else {
      console.log(`❌ No mappings found for include`);
    }
  };

  if (resource.resourceType === "Bundle") {
    console.log(`✅ Found Bundle resource`);
    resource.entry.forEach((entry) => {
      if (
        entry.resource.resourceType === "ValueSet" &&
        (entry.resource.id === id || id == null)
      ) {
        console.log(`✅ Mapping ICD-9 codes in ValueSet ${entry.resource.id}`);
        updateValueSet(entry.resource);
      }
    });
  } else if (resource.resourceType === "ValueSet") {
    console.log(`✅ Found ValueSet resource`);
    updateValueSet(resource);
  } else {
    console.log(`❌ Unsupported resource type`);
  }

  // persist resource
  fs.writeFileSync(valuesetOrBundle, JSON.stringify(resource, " ", 2));
};

const run = (valuesetOrBundle, mappings, id) => {
  prepareMap(mappings).then((map) => {
    updatedValueSets(map, valuesetOrBundle, id);
  });
};

const main = async () => {
  const options = yargs
    .usage("Usage: -v <name>")
    .option("v", {
      alias: "valueset",
      describe: "Input ValueSet or Bundle resource",
      type: "string",
      demandOption: true,
    })
    .option("m", {
      alias: "mappings",
      describe: "Mapping files",
      type: "array",
      demandOption: true,
    })
    .option("i", {
      alias: "id",
      describe: "Value set id to update (if bundle), defaults to all",
      type: "string",
      demandOption: false,
    }).argv;

  run(options.valueset, options.mappings, options.id);
};

main();
