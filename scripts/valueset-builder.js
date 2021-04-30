#!/usr/bin/env node

/**
 * This script takes in a CSV file with the following columns:
 *
 *  valueSetId, valueSetName, searchTerm, vocabularyId
 *
 * Regular expression are allowed in the searchTerm column. Use the
 * drug/ingredient name (not RxNorm code) for drug searches
 */
const fs = require("fs");
const yargs = require("yargs");
const { Client } = require("pg");
const Papa = require("papaparse");
const { TransformUtils } = require("@phema/terminology-utils/lib/index");

const newValueSet = (id, name) => {
  return {
    resourceType: "ValueSet",
    id,
    url: `https://workbench.phema.science/fhir/ValueSet/${id}`,
    name,
    status: "active",
    publisher: "Project PhEMA",
    compose: {
      include: [],
    },
  };
};

const parseInput = (input) => {
  const data = fs.readFileSync(input, "utf8");

  const csv = Papa.parse(data, {
    header: true,
  });

  csv.errors.forEach((e) => {
    console.log(`❌ Row ${e.row}: ${e.message}`);
  });

  return csv;
};

const isRegex = (term) => {
  return term.includes("^") || term.includes("*");
};

const prepValues = (csv) => {
  const values = [];

  csv.data.forEach((v) => {
    const value = [];

    value.push(`'${v.searchTerm}'`);
    value.push(`'${v.vocabularyId}'`);

    if (isRegex(v.searchTerm)) {
      value.push("'regex'");
      // We only search by drug string if the search term isn't all digits.  All digits
      // is our signal that the RxNorm code is an RxCUI
    } else if (
      v.vocabularyId.toUpperCase() === "RXNORM" &&
      v.searchTerm.match(/^[\d]+$/) === null
    ) {
      value.push("'drug'");
    } else {
      value.push("'exact'");
    }

    value.push(`'${v.valueSetId}'`);

    values.push(`(${value.join(", ")})`);
  });

  return `${values.join(", ")}`;
};

const search = async (values) => {
  const query_template = `with search_terms as (
	    select * from (values __VALUES__) as st (term, vocab, category, vsid)
    )
    select
        term,
        vocab,
        category,
        vsid,
        cdm.concept.concept_code,
        cdm.concept.concept_name
    from
        search_terms,
        cdm.concept
    where
        cdm.concept.vocabulary_id = search_terms.vocab
            and
        (
            case
                when category = 'regex' then
                    cdm.concept.concept_code ~ search_terms.term
                when category = 'exact' then
                    cdm.concept.concept_code = search_terms.term
                else
                    cdm.concept.concept_name ilike search_terms.term and cdm.concept.concept_class_id in ('Ingredient', 'Precise Ingredient', 'Brand Name')
            end
        )`;

  const query = query_template.replace("__VALUES__", values);

  const client = new Client();

  await client.connect();

  const results = await client.query(query);

  await client.end();

  return results.rows;
};

const assembleValueSets = (input, results) => {
  const valueSets = {};

  input.forEach((term) => {
    let vs = valueSets[term.valueSetId];

    if (!vs) {
      vs = newValueSet(term.valueSetId, term.valueSetName);
    }

    const matches = results.filter(
      (r) => term.searchTerm === r.term && r.vsid === vs.id
    );

    if (isRegex(term.searchTerm)) {
      if (matches.length > 1) {
        console.log(
          `✅ Found ${matches.length} matches for ${term.searchTerm}`
        );
      } else {
        // Warn, since we probably expect multiple results for a regex search
        console.log(
          `❌ Found ${matches.length} matches for ${term.searchTerm}`
        );
      }
    } else {
      // Warn if we don't find exactly one match for exact or drug search
      if (matches.length === 1) {
        console.log(
          `✅ Found ${matches.length} matches for ${term.searchTerm}`
        );
      } else {
        console.log(
          `❌ Found ${matches.length} matches for ${term.searchTerm}`
        );
      }
    }

    // find the vocab ID to FHIR canonical URL mapping
    const system = TransformUtils.omopVocabularies.find(
      (v) =>
        v.omopVocabularyId.toUpperCase() === term.vocabularyId.toUpperCase()
    );

    if (!system) {
      console.log(`❌ Cannot find FHIR canonical URL for ${term.vocabularyId}`);
    } else {
      // check if we have the system already included
      let includedSystem = vs.compose.include.find(
        (i) => i.system === system.fhirCanonicalUrl
      );

      let push = false;
      if (!includedSystem) {
        includedSystem = {
          system: system.fhirCanonicalUrl,
          concept: [],
        };

        push = true;
      }

      matches.forEach((m) => {
        // TODO: FIXME to not push duplicates

        includedSystem.concept.push({
          code: m.concept_code,
          display: m.concept_name,
        });
      });

      if (push) {
        vs.compose.include.push(includedSystem);
      }
    }

    valueSets[term.valueSetId] = vs;
  });

  return valueSets;
};

const buildBundle = (valueSets) => {
  const request = {
    method: "POST",
    url: "ValueSet",
  };

  const bundle = {
    resourceType: "Bundle",
    type: "batch",
    entry: [],
  };

  Object.keys(valueSets).forEach((v) => {
    const valueSet = valueSets[v];

    bundle.entry.push({
      resource: valueSet,
      request,
    });
  });

  return bundle;
};

const run = async (input, output) => {
  const csv = parseInput(input);

  const values = prepValues(csv);

  const results = await search(values);

  const valueSets = assembleValueSets(csv.data, results);

  const bundle = buildBundle(valueSets);

  fs.writeFileSync(output, JSON.stringify(bundle, " ", 2));
};

const main = async () => {
  const options = yargs
    .usage("Usage: -i <name> -o <name>")
    .option("i", {
      alias: "input",
      describe: "Input CSV file",
      type: "string",
      demandOption: true,
    })
    .option("o", {
      alias: "output",
      describe: "Output Bundle file",
      type: "string",
      demandOption: true,
    }).argv;

  run(options.input, options.output);
};

main();

/**
Valid values for `vocabularId` column in CSV:

Procedure Type
Specialty
NDFRT
dm+d
RxNorm Extension
Condition Type
Visit
Currency
VA Class
BDPM
HES Specialty
SPL
None
AMT
OPCS4
RxNorm
Relationship
Race
ICD10CM
SMQ
GCN_SEQNO
NFC
DRG
Meas Type
HCPCS
ATC
MedDRA
Concept Class
ICD9Proc
NUCC
EphMRA ATC
Multum
SNOMED
Place of Service
UCUM
PCORNet
Cost Type
Death Type
OXMIS
Cohort
MDC
ICD10PCS
NDC
Ethnicity
MeSH
Device Type
APC
LOINC
Revenue Code
VA Product
Visit Type
ICD10
Drug Type
Note Type
ABMS
Vocabulary
ICD9CM
CPT4
CIEL
Gender
Obs Period Type
Observation Type
Domain
 */
