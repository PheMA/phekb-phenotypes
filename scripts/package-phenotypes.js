const glob = require("glob");
const fs = require("fs");

const moment = require("moment");
const { breadth } = require("treeverse");

/**
 * This script will walk the "phenotypes" directory and package each phenotype
 * as a FHIR bundle including Library, ValueSet, and Composition resources.
 */
const data = {
  metadata: {},
  cql: {},
  elm: {},
  codeSystems: {},
  valueSets: {},
  phenotypes: [],
};

const phemaOrg = {
  resourceType: "Organization",
  id: "phema-org",
  identifier: [
    {
      system: "urn:ietf:rfc:3986",
      value: "urn:uuid:b4c8ce08-2722-4406-93d5-00196e483fa6",
    },
  ],
  active: true,
  name: "Phenotype Execution & Modeling Architecture (PhEMA)",
  alias: "PhEMA",
  telecom: [
    {
      system: "url",
      value: "https://projectphema.org/",
    },
  ],
};

const storeResource = (resource) => {
  if (resource.resourceType == "ValueSet") {
    data.valueSets[resource.id] = resource;
    console.log(`✅ Found ValueSet ${resource.id}`);
  } else if (resource.resourceType == "CodeSystem") {
    data.codeSystems[resource.id] = resource;
    console.log(`✅ Found CodeSystem ${resource.id}`);
  } else if (resource.library) {
    // Consider adding version here
    data.elm[resource.library.identifier.id] = resource;
    console.log(`✅ Found ELM for ${resource.library.identifier.id}`);
  } else {
    console.log(`❌ Unknown resource type: ${JSON.stringify(resource)}`);
  }
};

/**
 * Finds a value set by a given canonical URL
 *
 * @param {*} canonicalUrl The canonical URL of the value set
 * @returns
 */
const findValueSetByCanonicalUrl = (canonicalUrl) => {
  let vs = null;

  Object.keys(data.valueSets).forEach((k) => {
    if (data.valueSets[k].url === canonicalUrl) {
      vs = data.valueSets[k];
    }
  });

  return vs;
};

/**
 * Add a value set, and any sub value sets
 *
 * @param {*} valueSets The array of value sets
 * @param {*} valueSetDef  The value set def to add
 */
const addValueSet = (valueSets, valueSetDef) => {
  const valueSet = data.valueSets[valueSetDef.id];

  // Check to see if there are any referenced value sets and add them
  valueSet.compose.include.forEach((include) => {
    if (include.valueSet) {
      console.log(`✅ Adding referenced ValueSet ${include.valueSet[0]}`);

      const includedValueSet = findValueSetByCanonicalUrl(include.valueSet[0]);

      addValueSet(valueSets, includedValueSet);
    }
  });

  valueSets.push(valueSet);
};

/**
 * Gets the list of valuesets referenced by an array of phenotypes
 *
 * @param {string[]} ids Array of phenotype ids
 */
const getValueSets = (ids) => {
  const valueSets = [];

  ids.forEach((id) => {
    const elm = data.elm[id];
    elm.library.valueSets &&
      elm.library.valueSets.def.forEach((v) => {
        addValueSet(valueSets, v);
      });
  });

  return valueSets;
};

/**
 * Gets a the ids of included CQL libraries
 *
 * @param {string} id The phenotype id
 */
const getIncludes = (id) => {
  const elm = data.elm[id];

  const includes = new Set();

  elm.library.includes &&
    elm.library.includes.def.forEach((inc) => {
      if (data.cql.hasOwnProperty(inc.path)) {
        const subincludes = getIncludes(inc.path);

        subincludes.forEach((i) => {
          includes.add(i);
        });

        includes.add(inc.path);
      } else {
        console.log(
          `❌ Could not locate include ${inc.path} version ${inc.version}`
        );
      }
    });

  return [...includes];
};

const createBinary = (id) => {
  const binary = {
    resourceType: "Binary",
    id: `metadata-${id}`,
    contentType: "application/json",
    data: Buffer.from(
      JSON.stringify(data.metadata[id]) ||
        JSON.stringify({ error: "No metadata available" })
    ).toString("base64"),
  };

  return binary;
};

/**
 * Creates the Composition resource for the phenotype
 *
 * @param {string} id The phenotype id
 */
const compositionTemplate = (id) => {
  const elm = data.elm[id];
  const title = data.metadata[id] ? data.metadata[id].name : "";

  const composition = {
    resourceType: "Composition",
    id: `phema-${id}-${elm.library.identifier.version}`,
    identifier: [
      {
        system: "https://workbench.phema.science/identifier/phenotype",
        value: id,
      },
    ],
    status: "preliminary",
    date: moment().format("YYYY-MM-DDTHH:mm:ssZ"),
    type: {
      coding: [
        {
          system: "http://ncimeta.nci.nih.gov",
          code: "C166209",
        },
      ],
    },
    title: `${title} Phenotype Definition`,
    author: [
      {
        reference: "Organization/phema-org",
      },
    ],
    custodian: {
      reference: "Organization/phema-org",
    },
    relatesTo: [
      {
        code: "appends",
        targetIdentifier: {
          system: "urn:ietf:rfc:3986",
          value: data.metadata[id]
            ? data.metadata[id].url
            : "https://projectphema.org",
        },
      },
    ],
    section: [],
  };

  return composition;
};

/**
 * Very light-weight and imperfect children getting for the visitor pattern
 *
 * TODO: Implement stuff beyond basic expression operands
 *
 * @param {*} node
 * @param {*} nodeResult
 */
const getChildren = (node, nodeResult) => {
  if (node.def) {
    return node.def;
  } else if (node.expression) {
    if (typeof node.expression.operand === "object") {
      return [node.expression];
    } else {
      return node.expression.operand;
    }
  } else if (node.operand) {
    if (typeof node.operand === "object") {
      return [node.operand];
    } else {
      return node.operand;
    }
  } else {
    return [];
  }
};

const getValueSetId = (id, name) => {
  const elm = data.elm[id];

  return elm.library.valueSets.def.find((vs) => vs.name === name).id;
};

const getDataRequirements = (id) => {
  const dataRequirement = [];

  const elm = data.elm[id];

  // Bad visitor implementation
  breadth({
    tree: elm.library.statements,
    getChildren: getChildren,
    visit: (node) => {
      // if (node.expression) {
      //   console.log("Visiting: ", node.expression.type);
      // } else if (node.type) {
      //   console.log("Visiting: ", node.type);
      // }

      if (node.type === "Retrieve") {
        const dataType = node.dataType.split("}")[1];

        // We should never be retrieving the Patient directly
        if (dataType !== "Patient") {
          const req = {
            type: dataType,
          };

          // TODO handle non-valueset references
          if (node.codes.type === "ValueSetRef") {
            req.codeFilter = [
              {
                path: node.codeProperty,
                valueSet: getValueSetId(id, node.codes.name),
              },
            ];
          }

          dataRequirement.push(req);
        }
      }
    },
  });

  return dataRequirement;
};

const getRelatedArtifacts = (id) => {
  const relatedArtifact = [];

  const includeIds = getIncludes(id);
  const deps = includeIds.map((dep) => createLibrary(dep));

  deps.forEach((dep) => {
    relatedArtifact.push({
      type: "depends-on",
      resource: `Library/${dep.id}`,
    });
  });

  return relatedArtifact;
};

/**
 * Creates a Library resource for the CQL library
 *
 * @param {string} id The CQL library id
 */
const createLibrary = (id) => {
  const elm = data.elm[id];

  const title = data.metadata[id]
    ? data.metadata[id].name
    : elm.library.identifier.id;

  const library = {
    resourceType: "Library",
    id: `library-${elm.library.identifier.id}-${elm.library.identifier.version}`,
    identifier: [
      {
        system: "https://workbench.phema.science/identifier/phenotype-library",
        value: id,
      },
    ],
    title: `${title} Phenotype Definition`,
    // This is how the cqf-ruler resolves libraries
    name: `${elm.library.identifier.id}`,
    version: `${elm.library.identifier.version}`,
    dataRequirement: getDataRequirements(id),
    relatedArtifact: getRelatedArtifacts(id),
    content: [
      {
        contentType: "text/cql",
        data: data.cql[id],
      },
      {
        contentType: "application/elm+json",
        data: Buffer.from(JSON.stringify(data.elm[id])).toString("base64"),
      },
    ],
  };

  return library;
};

const extractLibraryId = (file) => {
  const cqlString = fs.readFileSync(file).toString("utf-8");
  const regex = /library\s*"?([a-zA-Z\.\-0-9]+)/;

  // This is imperfect, because the statement could be commented out
  const id = cqlString.match(regex)[1];

  if (!id) {
    throw new Error("No library identifier found");
  }

  return id;
};

const main = async () => {
  // Step 1. Collect all the resources into the `data` variable
  await new Promise((resolve, reject) => {
    glob("phenotypes/**/*.?(json|cql)", (err, files) => {
      if (err) {
        console.error("❌ Error reading resources: ", err);
        reject();
      }

      files.forEach((f) => {
        let raw = fs.readFileSync(f);

        if (f.endsWith("cql")) {
          // Assuming we only have one version of everything for now
          const ident = extractLibraryId(f);

          data.cql[ident] = Buffer.from(raw).toString("base64");

          console.log(`✅ Found CQL library ${ident}`);
        } else {
          let parsed = JSON.parse(raw);

          if (parsed.resourceType === "Bundle") {
            parsed.entry.forEach((entry) => {
              storeResource(entry.resource);
            });
          } else {
            if (parsed.library) {
              if (
                parsed.library.statements.def.some((s) => s.name === "Case")
              ) {
                // Eventually we should include the version here
                data.phenotypes.push(parsed.library.identifier.id);
              }
            }

            storeResource(parsed);
          }
        }
      });

      resolve();
    });
  });

  // Step 2. Collect all metadata
  await new Promise((resolve, reject) => {
    glob("data/**/*.json", (err, files) => {
      if (err) {
        console.error("❌ Error reading metadata: ", err);
        reject();
      }

      files.forEach((f) => {
        let raw = fs.readFileSync(f);
        let parsed = JSON.parse(raw);

        let id = `${parsed.id}.${parsed.slug}`;

        if (data.cql.hasOwnProperty(id)) {
          data.metadata[id] = parsed;
        }
      });

      resolve();
    });
  });

  /// debug
  fs.writeFileSync(`debug-data.json`, JSON.stringify(data, " ", 2));

  // Step 3. Construct batch bundle for each phenotype
  data.phenotypes.forEach((p) => {
    console.log(`🧬 Creating Bundle for phenotype ${p}`);

    const bundle = {
      resourceType: "Bundle",
      type: "batch",
      entry: [],
    };

    // Add the phema org
    bundle.entry.push({
      resource: phemaOrg,
      request: {
        method: "PUT",
        url: "Organization/phema-org",
      },
    });

    // Create main library
    const entry = createLibrary(p);

    // Create metadata binary
    const binary = createBinary(p);

    // Create dependencies
    const includeIds = getIncludes(p);
    const deps = includeIds.map((dep) => createLibrary(dep));

    // Get valuesets
    const valuesets = getValueSets([p, ...includeIds]);

    /////// Create the sections
    const comp = compositionTemplate(p);

    //// 1. Entry point section
    comp.section.push({
      title: "Phenotype Entry Point",
      text: {
        div:
          "The CQL library containing the phenotype 'Case' definition. The referenced Binary resource contains phenotype metadata from PheKB.",
      },
      author: [
        {
          reference: "Organization/phema-org",
        },
      ],
      entry: [
        {
          reference: `Library/${entry.id}`,
        },
        {
          reference: `Binary/${binary.id}`,
        },
      ],
    });

    //// 2. Add dependent libraries sections
    deps.forEach((dep) => {
      comp.section.push({
        title: `Dependent library: ${dep.id}`,
        text: { div: "Library that the main phenotype entry point depends on" },
        author: [
          {
            reference: "Organization/phema-org",
          },
        ],
        entry: [
          {
            reference: `Library/${dep.id}`,
          },
        ],
      });
    });

    //// 3 Add value sets sections
    valuesets.forEach((vs) => {
      comp.section.push({
        title: `Dependent value set: ${vs.id}`,
        text: {
          div:
            "Value set that the main phenotype entry point or one of its dependencies uses",
        },
        author: [
          {
            reference: "Organization/phema-org",
          },
        ],
        entry: [
          {
            reference: `ValueSet/${vs.id}`,
          },
        ],
      });
    });

    ////// Add resources to bundle

    //// Add the metadata binary
    bundle.entry.push({
      resource: binary,
      request: {
        method: "PUT",
        url: `Binary/${binary.id}`,
      },
    });

    //// Add entry point
    bundle.entry.push({
      resource: entry,
      request: {
        method: "PUT",
        url: `Library/${entry.id}`,
      },
    });

    //// Add dependencies
    deps.forEach((dep) => {
      bundle.entry.push({
        resource: dep,
        request: {
          method: "PUT",
          url: `Library/${dep.id}`,
        },
      });
    });

    //// Add value set
    valuesets.forEach((vs) => {
      bundle.entry.push({
        resource: vs,
        request: {
          method: "PUT",
          url: `ValueSet/${vs.id}`,
        },
      });
    });

    // Add the composition
    bundle.entry.push({
      resource: comp,
      request: {
        method: "PUT",
        url: `Composition/${comp.id}`,
      },
    });

    // write out
    fs.writeFileSync(
      `bundles/phema-phenotype.${p}.bundle.json`,
      JSON.stringify(bundle, " ", 2)
    );
  });
};

main();
