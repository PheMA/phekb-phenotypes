const glob = require("glob");
const fs = require("fs");
const { exec } = require("child_process");
const yaml = require("js-yaml");

const countCql = () => {
  glob("phenotypes/**/*.cql", (err, files) => {
    phema_files = files.filter((f) => {
      return (
        !f.includes("FHIRHelpers-4.0.0.cql") &&
        !f.includes("MATGlobalCommonFunctions-4.0.000.cql") &&
        !f.includes("thrombotic-event")
      );
    });

    // console.log("=============[ CQL ]==============");
    // phema_files.forEach((f) => {
    //   console.log(f);
    // });

    exec(`npx cloc ${phema_files.join(" ")}`, (err, stdout, stderr) => {
      if (err) {
        throw err;
      } else {
        console.log("=============[ CQL ]==============");
        console.log(stdout);
      }
    });
  });
};

const countCodesInValueSet = (valueSet) => {
  let total = 0;

  valueSet.compose.include.forEach((include) => {
    if (include.concept) {
      total += include.concept.length;
    }
  });

  return total;
};

const getCodesInValueSet = (valueSet) => {
  let codes = new Set();

  valueSet.compose.include.forEach((include) => {
    if (include.concept) {
      include.concept.forEach((code) => {
        codes.add(code.code);
      });
    }
  });

  return codes;
};

const countValueSets = () => {
  console.log("=============[ Value Sets ]==============");
  glob("phenotypes/**/valuesets/*.json", (err, files) => {
    phema_files = files.filter((f) => {
      return (
        !f.includes("FHIRHelpers-4.0.0.cql") &&
        !f.includes("MATGlobalCommonFunctions-4.0.000.cql") &&
        !f.includes("thrombotic-event")
      );
    });

    let allCodes = new Set();
    let codesTotal = 0;

    let total = 0;
    phema_files.forEach((f) => {
      //   console.log(f);

      const jsonStr = fs.readFileSync(f).toString("utf-8");
      const json = JSON.parse(jsonStr);

      if (json.resourceType === "ValueSet") {
        // console.log(json.id);
        total++;

        codesTotal += countCodesInValueSet(json);
        getCodesInValueSet(json).forEach((el) => allCodes.add(el));
      } else if (json.resourceType === "Bundle") {
        for (let i = 0; i < json.entry.length; i++) {
          const entry = json.entry[i];

          if (entry.resource.resourceType === "ValueSet") {
            // console.log(entry.resource.id);
            total++;

            codesTotal += countCodesInValueSet(entry.resource);

            getCodesInValueSet(entry.resource).forEach((el) =>
              allCodes.add(el)
            );
          }
        }
      } else {
        console.log("!!!!!!! Unknown json file");
      }
    });

    console.log(`Value set total: ${total}`);
    console.log(`Codes total: ${codesTotal}`);
    console.log(`Unique codes: ${allCodes.size}`);
  });
};

const countTests = () => {
  const data = {};

  let assertionTotal = 0;

  glob("phenotypes/**/test/cases/*.yaml", (err, files) => {
    phema_files = files.filter((f) => {
      return (
        !f.includes("FHIRHelpers-4.0.0.cql") &&
        !f.includes("MATGlobalCommonFunctions-4.0.000.cql") &&
        !f.includes("thrombotic-event")
      );
    });

    phema_files.forEach((f) => {
      // console.log(f);

      const yamlStr = fs.readFileSync(f).toString("utf-8");
      const yml = yaml.load(yamlStr);

      // console.log(JSON.stringify(yml, " ", 2));
      assertionTotal += Object.keys(yml.results).length;

      for (let i = 0; i < yml.data.length; i++) {
        const resource = yml.data[i];

        if (!data[resource.resourceType]) {
          data[resource.resourceType] = 1;
        } else {
          data[resource.resourceType]++;
        }
      }
    });

    console.log("=============[ Tests ]==============");
    console.log("cases: ", phema_files.length);
    console.log("assertions: ", assertionTotal);
    console.log("resources: ", JSON.stringify(data, " ", 2));
  });
};

const main = () => {
  countCql();
  countValueSets();
  countTests();
};

main();
