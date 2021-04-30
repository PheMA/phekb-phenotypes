const cqlt = require("cql-testing");
const path = require("path");

// NOTE: When working on a single phenotype, use something like the following
//       to only run the required test case
//cqlt.test(path.join(__dirname, "phenotypes/135.drug-induced-liver-injury"));

cqlt.test(path.join(__dirname, "phenotypes"));
