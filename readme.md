# PheKB Phenotypes

[![PhEMA](./repo-badge.svg)](https://projectphema.org "PhEMA")
![](https://img.shields.io/badge/progress-33%2F33-brightgreen?style=flat)

Collection of PheKB [phenotypes](./phenotypes) translated as part of the PhEMA
phenotype variability project.

## Overview

This repo consists of the following parts.

#### CQL to ELM Translator

A compiled version of the [`cql-to-elm`](https://github.com/cqframework/clinical_quality_language/tree/master/Src/java/cql-to-elm)
translator is in the [tools](./tools) directory. This is necessary because the
testing framework used only works with ELM and not directly with CQL.

#### Value Set Cache Builder

There is a small script in the [scripts](./scripts) directory that creates a
cache from `ValueSet` resources (in phenotype `valuesets` directories) in the
format expected by the testing framework.

#### PheKB Phenotypes

The translated phenotypes are in the [phenotypes](./phenotypes) directory. Each
phenotype consists of a CQL file and a collection of FHIR `ValueSet` resources.

#### Test Cases

Inside each phenotype directory there is a `test` folder, which contains the
test configuration (`cqlt.yaml`) and a set of tests cases (in the `cases`
directory). The test are executed using AHRQ's [CQL Testing
Framework](https://github.com/AHRQ-CDS/CQL-Testing-Framework).

## [Documentation](./docs)

- [📝 Contributing](./docs/Contributing.md)
- [❄️ Phenotype Patterns](./docs/Patterns.md)

## Running The Tests

### Prerequisites

- Java 11+
- NodeJS 14+

First install the dependencies:

```
yarn install
```

Then run the tests:

```
yarn test
```

## Phenotype List

| #   | id                                       | slug                                         | Translated By | Validated By | Status  |
| --- | ---------------------------------------- | -------------------------------------------- | ------------- | ------------ | ------- |
| 1   | [8](https://phekb.org/phenotype/8)       | cardiac-conduction-qrs                       | Pascal        | Luke         | ✅ Done |
| 2   | [9](https://phekb.org/phenotype/9)       | cataracts                                    | Luke          | Pascal       | ✅ Done |
| 3   | [12](https://phekb.org/phenotype/12)     | high-density-lipoproteins-hdl                | Pascal        | Luke         | ✅ Done |
| 4   | [13](https://phekb.org/phenotype/13)     | height                                       | Pascal        | Luke         | ✅ Done |
| 5   | [14](https://phekb.org/phenotype/14)     | hypothyroidism                               | Luke          | Pascal       | ✅ Done |
| 6   | [15](https://phekb.org/phenotype/15)     | lipids                                       | Luke          | Pascal       | ✅ Done |
| 7   | [16](https://phekb.org/phenotype/16)     | peripheral-arterial-disease-2012             | Luke          | Pascal       | ✅ Done |
| 8   | [17](https://phekb.org/phenotype/17)     | red-blood-cell-indices                       | Pascal        | Luke         | ✅ Done |
| 9   | [18](https://phekb.org/phenotype/18)     | type-2-diabetes-mellitus                     | Luke          | Pascal       | ✅ Done |
| 10  | [19](https://phekb.org/phenotype/19)     | white-blood-cell-indices                     | Pascal        | Luke         | ✅ Done |
| 11  | [68](https://phekb.org/phenotype/68)     | resistant-hypertension                       | Pascal        | Luke         | ✅ Done |
| 12  | [73](https://phekb.org/phenotype/73)     | type-2-diabetes-demonstration-project        | Pascal        | Luke         | ✅ Done |
| 13  | [74](https://phekb.org/phenotype/74)     | rheumatoid-arthritis-demonstration-project   | Pascal        | Luke         | ✅ Done |
| 14  | [76](https://phekb.org/phenotype/76)     | multiple-sclerosis-demonstration-project     | Pascal        | Luke         | ✅ Done |
| 15  | [77](https://phekb.org/phenotype/77)     | crohns-disease-demonstration-project         | Pascal        | Luke         | ✅ Done |
| 16  | [78](https://phekb.org/phenotype/78)     | atrial-fibrillation-demonstration-project    | Pascal        | Luke         | ✅ Done |
| 17  | [88](https://phekb.org/phenotype/88)     | clopidogrel-poor-metabolizers                | Pascal        | Luke         | ✅ Done |
| 18  | [112](https://phekb.org/phenotype/112)   | herpes-zoster                                | Pascal        | Luke         | ✅ Done |
| 19  | [115](https://phekb.org/phenotype/115)   | asthma-response-to-inhaled-steroids          | Pascal        | Luke         | ✅ Done |
| 20  | [135](https://phekb.org/phenotype/135)   | drug-induced-liver-injury                    | Luke          | Pascal       | ✅ Done |
| 21  | [155](https://phekb.org/phenotype/155)   | steroid-induced-osteonecrosis                | Pascal        | Luke         | ✅ Done |
| 22  | [156](https://phekb.org/phenotype/156)   | warfarin-doseresponse                        | Pascal        | Luke         | ✅ Done |
| 23  | [162](https://phekb.org/phenotype/162)   | autism                                       | Pascal        | Luke         | ✅ Done |
| 24  | [170](https://phekb.org/phenotype/170)   | statins-and-mace                             | Pascal        | Luke         | ✅ Done |
| 25  | [602](https://phekb.org/phenotype/602)   | familial-hypercholesterolemia                | Pascal        | Luke         | ✅ Done |
| 26  | [615](https://phekb.org/phenotype/615)   | sickle-cell-disease                          | Pascal        | Luke         | ✅ Done |
| 27  | [797](https://phekb.org/phenotype/797)   | developmental-language-disorder              | Pascal        | Luke         | ✅ Done |
| 28  | [1053](https://phekb.org/phenotype/1053) | multimodal-analgesia                         | Pascal        | Luke         | ✅ Done |
| 29  | [1058](https://phekb.org/phenotype/1058) | systemic-lupus-erythematosus-sle             | Pascal        | Luke         | ✅ Done |
| 30  | [1070](https://phekb.org/phenotype/1070) | phema-bph-benign-prostatic-hyperplasia-cases | Pascal        | Luke         | ✅ Done |
| 31  | [1205](https://phekb.org/phenotype/1205) | digital-rectal-exam                          | Luke          | Pascal       | ✅ Done |
| 32  | [1404](https://phekb.org/phenotype/1404) | urinary-incontinence                         | Luke          | Pascal       | ✅ Done |
| 33  | [1197](https://phekb.org/phenotype/1197) | bone-scan-utilization                        | Luke          | Pascal       | ✅ Done |
