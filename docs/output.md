# nf-core/plasmodiumdrugres: Output

## Introduction

This document describes the output produced by the pipeline. All paths below are relative to the top-level results directory (`--outdir`).

Column definitions in this page reflect current pipeline behavior for each estimation method.

## Pipeline overview

The pipeline is built using [Nextflow](https://www.nextflow.io/) and processes data using the following steps:

1. Translate loci of interest ([`PGEcore`](https://github.com/PlasmoGenEpi/PGEcore))
2. Split by population
3. Estimate allele prevalence ([`PGEcore`](https://github.com/PlasmoGenEpi/PGEcore))
4. Estimate multilocus allele frequency (only when `--loci_groups` is provided). Choice of method between:
   1. [MultiLociBiallelicModel](https://www.frontiersin.org/articles/10.3389/fepid.2022.943625/full) ([`PGEcore` wrapper script](https://github.com/PlasmoGenEpi/PGEcore))
   2. [FreqEstimationModel](https://doi.org/10.1186/1475-2875-13-102) ([`PGEcore` wrapper script](https://github.com/PlasmoGenEpi/PGEcore))
   3. Naive method ([`PGEcore`](https://github.com/PlasmoGenEpi/PGEcore))
5. Estimate single locus allele frequency. Choice of method between:
   1. [Incomplete data model (IDM)](https://doi.org/10.1371/journal.pone.0287161) ([`PGEcore` wrapper script](https://github.com/PlasmoGenEpi/PGEcore))
   2. [Naive `PGEcore` method](https://github.com/PlasmoGenEpi/PGEcore)
   3. [mhaps_freq (from microhaplotype frequencies via DCIFER)](https://github.com/PlasmoGenEpi/PGEcore)
6. Merge prevalence and frequency outputs
7. Concatenate population outputs into standardized summary tables, while preserving raw tool-specific outputs in `raw_summaries/`

### Single Locus Allele Frequencies

<details markdown="1">
<summary>Output files</summary>

- `sl_summary.tsv`: Single-locus summary table (prevalence + frequency), merged across populations with standardized columns.

</details>

#### `sl_summary.tsv` columns

Standardized columns (always present, in this order):

| Column         | Description                                                                         |
| -------------- | ----------------------------------------------------------------------------------- |
| `population`   | Population label for this row (a user-defined grouping of samples; see usage docs). |
| `variant`      | Single-locus amino-acid variant identifier.                                         |
| `prev`         | Estimated prevalence for the variant in the population.                             |
| `sample_count` | Number of samples with the variant (for prevalence estimate).                       |
| `sample_total` | Total number of samples considered (for prevalence estimate).                       |
| `freq`         | Estimated single-locus allele frequency.                                            |

Tool-specific columns are removed during standardization. See [Raw summary tables](#raw-summary-tables) for method-specific columns that are excluded.

### Multi Locus Allele Frequencies

<details markdown="1">
<summary>Output files</summary>

- `ml_summary.tsv`: Multi-locus summary table, merged across populations with standardized columns.
  When `--loci_groups` is omitted, this file is still written but contains only the header row.

</details>

#### `ml_summary.tsv` columns

Standardized columns (in this order):

| Column         | Description                                                   |
| -------------- | ------------------------------------------------------------- |
| `population`   | Population label for this row.                                |
| `group_id`     | Group identifier from `--loci_groups`.                        |
| `variant`      | Multi-locus variant / haplotype identifier.                   |
| `prev`         | Estimated prevalence (included when available).               |
| `sample_count` | Number of samples with the variant (included when available). |
| `sample_total` | Total number of samples considered (included when available). |
| `freq`         | Estimated multi-locus allele frequency.                       |

Not all MLAF methods report `prev`, `sample_count`, and `sample_total`. When present, they are included in the order shown above; otherwise the table contains only `population`, `group_id`, `variant`, and `freq`.

Tool-specific columns are removed during standardization. See [Raw summary tables](#raw-summary-tables) for method-specific columns that are excluded.

### SL-from-ML Summary

<details markdown="1">
<summary>Output files</summary>

- `raw_summaries/raw_sl_from_ml_summary.tsv`: Single-locus frequencies derived from multi-locus estimates, with all tool-specific columns retained (see [Raw summary tables](#raw-summary-tables)).
  When `--loci_groups` is omitted, this file is still written but contains only the header row.

</details>

### Translated Loci

<details markdown="1">
<summary>Output files</summary>

- `translated_loci/`
  - `amino_acid_calls.tsv.gz`: Raw amino acid calls from individual targets.
  - `collapsed_amino_acid_calls.tsv.gz`: Amino acid calls collapsed. E.g. if a locus is covered by multiple targets these will be collapsed from `amino_acid_calls.tsv.gz` into this file.
  - `loci_covered_by_target_samples_info.tsv`: The loci from the input that were found to be covered by input data.

</details>

### Raw summary tables

<details markdown="1">
<summary>Output files</summary>

- `raw_summaries/`: Concatenated summary tables across populations before column standardization. These retain all tool-specific columns from upstream method outputs.
  - `raw_sl_summary.tsv`: Full single-locus (prevalence + frequency) table before standardization.
  - `raw_ml_summary.tsv`: Full multi-locus table before standardization.
  - `raw_sl_from_ml_summary.tsv`: Single-locus frequencies derived from multi-locus estimates (no corresponding top-level standardized file).

</details>

The standardized `sl_summary.tsv` and `ml_summary.tsv` files exclude tool-specific columns. Full concatenated outputs are archived in `raw_summaries/`. The tables below describe additional columns produced by each method.

#### Single-locus tool-specific columns

These columns may appear in upstream SLAF/prevalence outputs but are not included in the standardized `sl_summary.tsv`. They are retained in `raw_summaries/raw_sl_summary.tsv`:

| SLAF method               | Extra columns                                                                                |
| ------------------------- | -------------------------------------------------------------------------------------------- |
| `IDM`                     | None.                                                                                        |
| `naive`                   | `allele_count`, `allele_total` (from prevalence estimation).                                 |
| `mhaps_freq` (via DCIFER) | `sample_total_for_allele_freq` (sample total associated with the frequency estimate output). |

#### Multi-locus tool-specific columns

These columns may appear in upstream MLAF outputs but are not included in the standardized `ml_summary.tsv`. They are retained in `raw_summaries/raw_ml_summary.tsv`:

| MLAF method | Extra columns                                  |
| ----------- | ---------------------------------------------- |
| `MLBM`      | None.                                          |
| `FEM`       | `sequence`, `median_freq`, `CI_2.5`, `CI_97.5` |
| `naive`     | `allele_count`, `allele_total`                 |

#### `raw_sl_from_ml_summary.tsv` columns by MLAF method

| MLAF method | Columns in `raw_sl_from_ml_summary.tsv`                                                                             |
| ----------- | ------------------------------------------------------------------------------------------------------------------- |
| `MLBM`      | `population`, `variant`, `freq`                                                                                     |
| `FEM`       | `population`, `variant`, `freq`                                                                                     |
| `naive`     | `population`, `group_id`, `variant`, `prev`, `sample_count`, `sample_total`, `allele_count`, `allele_total`, `freq` |

### Pipeline information

<details markdown="1">
<summary>Output files</summary>

- `pipeline_info/`
  - Reports generated by Nextflow: `execution_report.html`, `execution_timeline.html`, `execution_trace.txt` and `pipeline_dag.html`.
  - Reports generated by the pipeline: `pipeline_report.html`, `pipeline_report.txt` and `nf_core_plasmodiumdrugres_software_versions.yml`. The `pipeline_report*` files are only present if `--email` / `--email_on_fail` is set.
  - Parameters used by the pipeline run: `params.json`.

</details>

[Nextflow](https://docs.seqera.io/platform-cloud/reports/overview) provides excellent functionality for generating various reports relevant to the running and execution of the pipeline. This will allow you to troubleshoot errors with the running of the pipeline, and also provide you with other information such as launch commands, run times and resource usage.
