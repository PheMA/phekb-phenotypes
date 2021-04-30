const glob = require("glob");
const fs = require("fs");

glob("data/**/*.json", (err, files) => {
  if (err) {
    console.error("Error updating metadata: ", err);
    return;
  }

  files
    .filter((file) => !file.includes("__excluded"))
    .forEach((metadataFile) => {
      const phenotypeId = metadataFile.split("/").pop().slice(0, -5);

      if (fs.existsSync(`phenotypes/${phenotypeId}`)) {
        console.log(`Updating metadata for '${phenotypeId}'`);

        let raw = fs.readFileSync(metadataFile);
        let metadata = JSON.parse(raw);

        glob(`phenotypes/${phenotypeId}/**/*.*`, (err, phenotypeFiles) => {
          if (err) {
            console.error("Error updating metadata: ", err);
            return;
          }

          const phema = {
            cql: [],
            valuesets: [],
            test: {
              cases: [],
            },
          };

          phenotypeFiles.forEach((file) => {
            const parts = file.split("/").slice(2);

            switch (parts[0]) {
              case "cql":
                phema.cql.push(parts.slice(1).join("/"));
                break;
              case "valuesets":
                phema.valuesets.push(parts.slice(1).join("/"));
                break;
              case "test":
                if (parts[1] === "cqlt.yaml") {
                  phema.test.config = "cqlt.yaml";
                } else {
                  phema.test.cases.push(parts.slice(2).join("/"));
                }
                break;
              default:
                console.warn(`Unknown phenotype directory: ${parts[0]}`);
            }
          });

          metadata.phema = phema;

          fs.writeFileSync(metadataFile, JSON.stringify(metadata, " ", 2));
        });
      } else {
        console.warn(`No phenotype found for '${phenotypeId}'`);
      }

      //   glob("data/**/*.json", (err, files) => {

      //   const valueSetFile = fs.readFileSync(file);
      //   const valueSet = JSON.parse(valueSetFile);

      //   if (valueSet.resourceType != "ValueSet") {
      //     console.warn(
      //       `Non ValueSet resource found in a 'valueset' directory: ${file}`
      //     );
      //   } else {
      //     console.log(`Adding ${file} to value set cache`);

      //     ahrq = valueSetToAHRQFormat(valueSet);

      //     // update cache
      //     cache = Object.assign({}, cache, ahrq);
      //   }
      // });

      // fs.writeFile(VS_CACHE_FILE, JSON.stringify(cache, " ", 2), (err) => {
      //   if (err) {
      //     console.error("Error writing value set cache: ", err);
      //     return;
      //   }

      //   console.log("Successfully updated value set cache");
    });
});
