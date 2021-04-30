const fetch = require("node-fetch");

const BASE_URL = "https://rxnav.nlm.nih.gov/REST";
const SEARCH_URL = `${BASE_URL}/rxcui?caller=RxNav&name=`; // e.g. https://rxnav.nlm.nih.gov/REST/rxcui?caller=RxNav&name=Cyclophosphamide
const DETAILS_URL =
  "https://rxnav.nlm.nih.gov/REST/rxcui/__RX_CUI__/allrelatedextension?caller=RxNav";

const FETCH_OPTS = { headers: { Accept: "application/json" } };

/**
 * UPDATE THESE 👇
 */
const VALUE_SET_ID = "17.red-blood-cell-meds";
const VALUE_SET_NAME = "Medication Affecting Red Blood Cells";

const SEARCH_STRINGS = [
  "Epoetin Alfa",
  "Darbepoetin alfa",
  "Filgrastim",
  "Pegfilgrastim",
  "Sargramostim",
  "Methotrexate",
  "Azathioprine",
  "6-Mercaptopurine",
  "Cyclophosphamide",
  "Hydroxyurea",
  "Imatinib",
  "Dasatinib",
  "Nilotinib",
  "Busulfan",
  "Etoposide",
  "Lomustine",
  "Thioguanine",
  "Lenalidomide",
  "Chlorambucil",
  "Melphalan",
  "Trofosfamide",
  "Mycophenolate mofetil",
  "Capecitabine",
  "Tegafur",
  "Carmofur",
  "Cyclosporine",
  "Tacrolimus",
  "Phenytoin",
  "Fosphenytoin",
  "Valproic acid",
];

/**
 * UPDATE THESE 👆🏼
 */

const VALUESET_TEMPLATE = {
  resourceType: "ValueSet",
  id: VALUE_SET_ID,
  url: `http://cts.nlm.nih.gov/fhir/ValueSet/${VALUE_SET_ID}`,
  name: VALUE_SET_NAME,
  status: "active",
  compose: {
    include: [
      {
        system: "http://www.nlm.nih.gov/research/umls/rxnorm",
        concept: [],
      },
    ],
  },
};

const search = async (drug) => {
  const url = SEARCH_URL + drug;

  console.log(`Searching for ${drug}`);

  return fetch(url, FETCH_OPTS)
    .then((res) => res.json())
    .then((json) => {
      if (json.idGroup.rxnormId && json.idGroup.rxnormId.length === 1) {
        return json.idGroup.rxnormId[0];
      } else {
        throw new Error(`❌ No single match found for ${drug}`);
      }
    });
};

const getDetails = async (rxcui, drug) => {
  const url = DETAILS_URL.replace("__RX_CUI__", rxcui);

  return fetch(url, FETCH_OPTS)
    .then((res) => res.json())
    .then((json) => {
      const ingredients = json.allRelatedGroup.conceptGroup.find(
        (cg) => cg.tty === "IN"
      ).conceptProperties;

      if (ingredients.length != 1) {
        throw new Error(`❌ No single ingredient found for ${drug}`);
      }

      const ingredient = ingredients[0];

      return {
        code: ingredient.rxcui,
        display: ingredient.name,
      };
    });
};

const run = async () => {
  for (i in SEARCH_STRINGS) {
    const drug = SEARCH_STRINGS[i];

    await search(drug)
      .then((rxcui) => getDetails(rxcui, drug))
      .then((concept) => {
        VALUESET_TEMPLATE.compose.include[0].concept.push(concept);
      })
      .catch((err) => {
        console.log(err.message);
      });
  }

  console.log(JSON.stringify(VALUESET_TEMPLATE, " ", 2));
};

run();
