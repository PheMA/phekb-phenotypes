const fs = require("fs");
const yargs = require("yargs");
const csv = require("csv");

const run = (phenotypePath) => {
  const rows = [];

  const phenotypeText = fs.readFileSync(phenotypePath);
  const phenotype = JSON.parse(phenotypeText);

  phenotype.entry.forEach((entry) => {
    if (entry.resource.resourceType === "ValueSet") {
      const valueSet = entry.resource;

      valueSet.compose.include.forEach((include) => {
        include.concept.forEach((concept) => {
          rows.push({
            valueSetId: valueSet.id,
            valueSetName: valueSet.name,
            code: concept.code,
            display: concept.display,
            codeSystem: include.system,
          });
        });
      });
    }
  });

  csv.stringify(rows, { header: true }).pipe(process.stdout);
};

const main = async () => {
  const options = yargs.usage("Usage: -b <name>").option("b", {
    alias: "bundle",
    describe: "Input phenotype Bundle resource",
    type: "string",
    demandOption: true,
  }).argv;

  run(options.b);
};

main();
