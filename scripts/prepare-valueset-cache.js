const glob = require("glob");
const fs = require("fs");

const VS_CACHE_FILE = "phenotypes/__common/.vscache/valueset-db.json";

console.log("Updating value set cache");

const cacheFile = fs.readFileSync(VS_CACHE_FILE);
let cache = JSON.parse(cacheFile);

glob("phenotypes/**/valuesets/*.json", (err, files) => {
  if (err) {
    console.error("Error preparing value set cache: ", err);
    return;
  }

  files.forEach((file) => {
    console.log(file);

    const valueSetFile = fs.readFileSync(file);
    const valueSet = JSON.parse(valueSetFile);

    if (valueSet.resourceType === "ValueSet") {
      console.log(`Adding ${file} to value set cache`);

      ahrq = valueSetToAHRQFormat(valueSet);

      // update cache
      cache = Object.assign({}, cache, ahrq);
    } else if (valueSet.resourceType === "Bundle") {
      console.log(`Adding bundle ${file} to value set cache`);

      ahrq = bundleToAHRQFormat(valueSet);

      // update cache
      cache = Object.assign({}, cache, ...ahrq);
    } else {
      console.warn(
        `Non ValueSet resource found in a 'valueset' directory: ${file}`
      );
    }
  });

  fs.writeFile(VS_CACHE_FILE, JSON.stringify(cache, " ", 2), (err) => {
    if (err) {
      console.error("Error writing value set cache: ", err);
      return;
    }

    console.log("Successfully updated value set cache");
  });
});

/**
 *
 * @param {string} url - the ValueSet's URL
 * @param {object} bundleResource - optional bundle, if the source valueset is a FHIR Bundle
 */
const findValueSetResource = (url, bundleResource) => {
  // If there is a bundle provided, we will check that first to see if we can detect the referenced
  // value set contained within.
  if (bundleResource) {
    for (i in bundleResource.entry) {
      const entry = bundleResource.entry[i];
      if (entry.resource && entry.resource.resourceType === 'ValueSet' && entry.resource.url === url) {
        return entry.resource;
      }
    }
  }

  // If this isn't a bundle, or we couldn't find the referenced value set, look for a file
  // containing the definition.
  const filenames = glob.sync("phenotypes/**/valuesets/*.json");

  for (i in filenames) {
    const valueSetFile = fs.readFileSync(filenames[i]);
    const valueSet = JSON.parse(valueSetFile);

    if (valueSet.url === url) {
      return valueSet;
    }
  }

  return null;
};

const bundleToAHRQFormat = (bundleResource) => {
  // A bundle can have 0..* value sets within it
  const ahrqValueSets = [];

  if (!bundleResource.entry) {
    return null;
  }

  bundleResource.entry.forEach((entry) => {
    // We won't report to the user any non-ValueSet resources because we expect there to be
    // some, given that this is a Bundle.
    if (entry.resource && entry.resource.resourceType === "ValueSet") {
      ahrq = valueSetToAHRQFormat(entry.resource, bundleResource);
      ahrqValueSets.push(ahrq);
    }
  });

  return ahrqValueSets;
}

const valueSetToAHRQFormat = (valueSetResource, bundleResource) => {
  const ahrqValueSet = {};

  const id = valueSetResource.id;

  const currentDate = new Date()
    .toISOString()
    .substring(0, 10)
    .replace(/-/g, "");

  const version = valueSetResource.version || currentDate;

  ahrqValueSet[id] = {
    [version]: {
      oid: id,
      version,
      codes: [],
    },
  };

  valueSetResource.compose.include.forEach((codeList) => {
    if (codeList.concept) {
      // Add directly listed codes
      codeList.concept.forEach((concept) => {
        ahrqValueSet[id][version].codes.push({
          code: concept.code,
          system: codeList.system,
          version: concept.version,
        });
      });
    }

    if (codeList.valueSet) {
      // Add referenced value sets (only one level deep)
      codeList.valueSet.forEach((valueSetUrl) => {
        const nestedValueSet = findValueSetResource(valueSetUrl, bundleResource);

        if (nestedValueSet) {
          nestedValueSet.compose.include.forEach((nestedCodeList) => {
            // Add directly listed codes of reference value set
            nestedCodeList.concept.forEach((concept) => {
              ahrqValueSet[id][version].codes.push({
                code: concept.code,
                system: nestedCodeList.system,
                version: concept.version,
              });
            });
          });
        }
      });
    }
  });

  return ahrqValueSet;
};
