# nf-core/plasmodiumdrugres: Output

## Introduction

This document describes the output produced by the pipeline. All paths below are relative to the top-level results directory (`--outdir`).

The main results are two summary tables: [`sl_summary.tsv`](#single-locus-allele-frequencies) for individual drug resistance codons and [`ml_summary.tsv`](#multi-locus-allele-frequencies) for haplotypes across groups of codons. Most users only need these two files. The other outputs explain how the summaries were reached and help with troubleshooting.

## Pipeline overview

The pipeline steps and estimation methods are described in the [introduction](https://nf-co.re/plasmodiumdrugres). The outputs, in the order they are produced, are:

- [Translated Loci](#translated-loci): amino acid calls for each specimen at each locus of interest
- [Single Locus Allele Frequencies](#single-locus-allele-frequencies): prevalence and frequency of each amino acid at each locus of interest
- [Multi Locus Allele Frequencies](#multi-locus-allele-frequencies): prevalence and frequency of haplotypes across groups of loci
- [SL-from-ML Summary](#sl-from-ml-summary): single-locus frequencies derived from the multi-locus estimates
- [Unassigned specimens](#unassigned-specimens): specimens left out because they have no population
- [Raw summary tables](#raw-summary-tables): the full method-specific tables behind the summaries
- [Pipeline information](#pipeline-information): reports and software versions from the run

## Key terms

- **Prevalence** is the proportion of specimens in which an allele was detected at all. A specimen with a mixed (polyclonal) infection can count towards the prevalence of more than one allele at the same locus, so prevalences at a locus can add up to more than 1.
- **Frequency** is the estimated proportion of parasites in the population that carry an allele. Frequencies at a locus add up to 1. Estimating frequency from polyclonal infections is not straightforward, which is why the pipeline offers several methods.
- **Population** is the group of specimens an estimate is made for (for example a country, a health facility or a year). See [population grouping](https://nf-co.re/plasmodiumdrugres/usage#population-grouping-optional) in the usage docs. Without population grouping, all specimens form one population named by `--population_label` (default `pop1`).
- **Variant** identifiers use [variant string notation](https://github.com/mrc-ide/variantstring), as used by [STAVE](https://github.com/mrc-ide/STAVE). The gene, the amino acid position(s) and the amino acid(s) are separated by `:`, with the gene given by its `gene_id` from `--loci_of_interest_bed`:
  - single locus: `gene_id:aa_position:aa`, for example `PF3D7_0417200.1:51:I` is isoleucine at codon 51 of _dhfr_
  - multi-locus haplotype: positions and amino acids are each joined by `_`, in the same order, for example `PF3D7_0417200.1:51_59_108:I_R_N` is I at codon 51, R at 59 and N at 108

## Translated Loci

The first step converts the microhaplotype sequences into amino acid calls. Each distinct microhaplotype is aligned to the reference sequence of its panel target, and the codon at each locus in `--loci_of_interest_bed` that the target covers is extracted and translated. This is done by [`translate_loci_of_interest`](https://plasmogenepi.github.io/PGEcore/reference/translate_loci_of_interest.html) from [PGEcore](https://github.com/PlasmoGenEpi/PGEcore).

When a locus is covered by more than one panel target, the calls are combined into one call per specimen, locus and amino acid. By default the reads are summed across all covering targets. With `--collapse_calls_by_summing false`, only the target with the most reads for that specimen and locus is used. The collapsed calls are the input to all the estimates below.

Use these files to check which loci your panel covers, how many specimens have a call at each locus, and what was called for a given specimen.

<details markdown="1">
<summary>Output files</summary>

- `translated_loci/`
  - `collapsed_amino_acid_calls.tsv.gz`: One row per specimen, locus and amino acid, with the reference amino acid, the read count and the target(s) the call came from. This is the table used for estimation.
  - `amino_acid_calls.tsv.gz`: The calls before collapsing: one row per specimen, target, microhaplotype and locus, with the microhaplotype sequence, the observed and reference codon, and the observed and reference amino acid.
  - `loci_covered_by_target_samples_info.tsv`: One row per locus of interest, with the target covering it (`covered_by_target`), the reference amino acid, and the number of specimens with a call (`n_samples`) out of the total (`total_samples`). Use it to check that every locus you are interested in is covered by your panel.
  - `loci_of_interest_for_target_for_microhap.tsv.gz`: The codon and amino acid each distinct microhaplotype sequence gives at each locus it covers. Useful for checking how a particular sequence was translated.

</details>

## Single Locus Allele Frequencies

For each population, the pipeline estimates the prevalence and frequency of every amino acid seen at each locus of interest, for example the proportion of parasites carrying the _crt_ K76T mutation.

Prevalence is calculated directly from the amino acid calls. Frequency is estimated with the method chosen by `--slaf_method`:

- `naive` (default): a simple estimate from the calls in each specimen, using either the within-specimen proportion of reads (`--naive_slaf_method read_count_prop`, default) or presence/absence (`presence_absence`). Implemented in PGEcore as [`estimate_allele_frequency_naive`](https://plasmogenepi.github.io/PGEcore/reference/estimate_allele_frequency_naive.html).
- `IDM`: the [incomplete data model](https://doi.org/10.1371/journal.pone.0287161), which estimates frequencies while accounting for polyclonal infections. Run through a PGEcore wrapper.
- `mhaps_freq`: microhaplotype frequencies are first estimated with [Dcifer](https://github.com/EPPIcenter/dcifer), then converted to amino acid frequencies at each locus. Run through a PGEcore wrapper.

The results for all populations are combined into one table with the same columns whichever method was used.

<details markdown="1">
<summary>Output files</summary>

- `sl_summary.tsv`: Single-locus prevalence and frequency for every population.

</details>

### `sl_summary.tsv` columns

| Column         | Description                                                                              |
| -------------- | ---------------------------------------------------------------------------------------- |
| `population`   | Population label for this row (a user-defined grouping of samples; see usage docs).      |
| `variant`      | Single-locus variant in [variant string notation](#key-terms), `gene_id:aa_position:aa`. |
| `prev`         | Estimated prevalence for the variant in the population.                                  |
| `sample_count` | Number of samples with the variant (for prevalence estimate).                            |
| `sample_total` | Total number of samples considered (for prevalence estimate).                            |
| `freq`         | Estimated single-locus allele frequency.                                                 |

Method-specific columns are left out of this table and kept in [`raw_summaries/raw_sl_summary.tsv`](#raw-summary-tables).

## Multi Locus Allele Frequencies

Resistance to some drugs depends on a combination of mutations, for example the _dhfr_ N51I, C59R and S108N triple mutant. Multi-locus estimates give the prevalence and frequency of each combination (haplotype) of amino acids across a group of loci. The groups are defined in `--loci_groups`; this step only runs when that file is provided.

In a polyclonal infection it is usually not possible to tell which amino acids came from the same parasite, so haplotype frequencies have to be estimated. The method is chosen with `--mlaf_method`:

- `naive` (default): uses specimens with a call at every locus in the group, and infers their haplotypes when only one locus is mixed or when one allele dominates at every locus (its share of reads is above `--naive_multilocus_wsaf_cut_off`, default 0.70). Prevalence and frequency are then calculated from the within-specimen allele proportions (`--naive_mlaf_method wsaf_prop`, default) or presence/absence (`presence_absence`). Implemented in PGEcore as [`multilocus_prevfreq_naive`](https://plasmogenepi.github.io/PGEcore/reference/multilocus_prevfreq_naive.html).
- `MLBM`: the [MultiLociBiallelicModel](https://www.frontiersin.org/articles/10.3389/fepid.2022.943625/full). Run through a PGEcore wrapper.
- `FEM`: the [FreqEstimationModel](https://doi.org/10.1186/1475-2875-13-102), a Bayesian model that also reports credible intervals. It needs the average complexity of infection, set with `--fem_coi`. Run through a PGEcore wrapper.

<details markdown="1">
<summary>Output files</summary>

- `ml_summary.tsv`: Multi-locus haplotype estimates for every population and loci group.
  When `--loci_groups` is omitted, this file is still written but contains only the header row.

</details>

### `ml_summary.tsv` columns

| Column         | Description                                                                                        |
| -------------- | -------------------------------------------------------------------------------------------------- |
| `population`   | Population label for this row.                                                                     |
| `group_id`     | Group identifier from `--loci_groups`.                                                             |
| `variant`      | Haplotype in [variant string notation](#key-terms), for example `PF3D7_0417200.1:51_59_108:I_R_N`. |
| `prev`         | Estimated prevalence (included when available).                                                    |
| `sample_count` | Number of samples with the variant (included when available).                                      |
| `sample_total` | Total number of samples considered (included when available).                                      |
| `freq`         | Estimated multi-locus haplotype frequency.                                                         |

Not all methods report `prev`, `sample_count` and `sample_total`. Those that are reported are included in the order shown above:

| MLAF method | Columns in `ml_summary.tsv`                                                         |
| ----------- | ----------------------------------------------------------------------------------- |
| `naive`     | `population`, `group_id`, `variant`, `prev`, `sample_count`, `sample_total`, `freq` |
| `MLBM`      | `population`, `group_id`, `variant`, `freq`                                         |
| `FEM`       | `population`, `group_id`, `variant`, `prev`, `sample_total`, `freq`                 |

Method-specific columns are left out of this table and kept in [`raw_summaries/raw_ml_summary.tsv`](#raw-summary-tables).

## SL-from-ML Summary

The haplotype frequencies from the multi-locus step can be turned back into single-locus frequencies by combining the frequencies of all haplotypes that carry each amino acid. Comparing these with the frequencies in `sl_summary.tsv` is a useful consistency check, because the two come from different methods.

<details markdown="1">
<summary>Output files</summary>

- `raw_summaries/raw_sl_from_ml_summary.tsv`: Single-locus frequencies derived from the multi-locus estimates. The columns depend on `--mlaf_method` (see [Raw summary tables](#raw-summary-tables)).
  When `--loci_groups` is omitted, this file is still written but contains only the header row.

</details>

## Unassigned specimens

When populations are assigned with `--population_assignment` or `--pmo_population_fields`, any specimen that has amino acid calls but no population is left out of every estimate. So that this does not go unnoticed, the pipeline lists those specimens in this file and logs a warning with their number during the run and again when it finishes.

<details markdown="1">
<summary>Output files</summary>

- `unassigned_specimens.txt`: Specimens left out because they have no population, one per line. Only written when at least one specimen is unassigned.

</details>

## Raw summary tables

To keep `sl_summary.tsv` and `ml_summary.tsv` the same whichever method is used, columns that only some methods produce are removed from them. The full tables, with every column each method produces, are kept here. Use them if you need method-specific details, such as the credible intervals from FEM.

<details markdown="1">
<summary>Output files</summary>

- `raw_summaries/`
  - `raw_sl_summary.tsv`: Full single-locus prevalence and frequency table.
  - `raw_ml_summary.tsv`: Full multi-locus table.
  - `raw_sl_from_ml_summary.tsv`: Single-locus frequencies derived from multi-locus estimates (see [SL-from-ML Summary](#sl-from-ml-summary)).

</details>

Columns appear in the order each method writes them, so the order can differ from the standardised summaries.

### `raw_sl_summary.tsv` columns by SLAF method

| SLAF method  | Columns in `raw_sl_summary.tsv`                                                                         |
| ------------ | ------------------------------------------------------------------------------------------------------- |
| `naive`      | `population`, `variant`, `prev`, `sample_count`, `sample_total`, `freq`                                 |
| `IDM`        | `population`, `variant`, `prev`, `sample_count`, `sample_total`, `freq`                                 |
| `mhaps_freq` | `population`, `variant`, `prev`, `sample_count`, `sample_total`, `freq`, `sample_total_for_allele_freq` |

Only `mhaps_freq` adds a column: `sample_total_for_allele_freq`, the number of specimens Dcifer used to estimate the frequency. `prev`, `sample_count` and `sample_total` always come from the naive prevalence estimate, whichever SLAF method is used.

### `raw_ml_summary.tsv` columns by MLAF method

| MLAF method | Columns in `raw_ml_summary.tsv`                                                                                     |
| ----------- | ------------------------------------------------------------------------------------------------------------------- |
| `naive`     | `population`, `variant`, `sample_total`, `sample_count`, `prev`, `freq`, `group_id`                                 |
| `MLBM`      | `population`, `group_id`, `variant`, `freq`                                                                         |
| `FEM`       | `population`, `sequence`, `freq`, `median_freq`, `CI_2.5`, `CI_97.5`, `prev`, `variant`, `sample_total`, `group_id` |

Only `FEM` adds columns:

- `sequence`: FEM's internal code for the haplotype, one digit per locus in the group.
- `median_freq`: posterior median of the haplotype frequency (`freq` is the posterior mean).
- `CI_2.5`, `CI_97.5`: lower and upper bounds of the 95% credible interval for the frequency.

### `raw_sl_from_ml_summary.tsv` columns by MLAF method

| MLAF method | Columns in `raw_sl_from_ml_summary.tsv`                                             |
| ----------- | ----------------------------------------------------------------------------------- |
| `naive`     | `population`, `group_id`, `variant`, `sample_total`, `sample_count`, `freq`, `prev` |
| `MLBM`      | `population`, `variant`, `freq`                                                     |
| `FEM`       | `population`, `variant`, `freq`                                                     |

## Pipeline information

Nextflow and the pipeline write reports about the run itself. Use them to troubleshoot errors, to see run times and resource usage, and to record the parameters and software versions used, for example when publishing results.

<details markdown="1">
<summary>Output files</summary>

- `pipeline_info/`
  - Reports generated by Nextflow: `execution_report.html`, `execution_timeline.html`, `execution_trace.txt` and `pipeline_dag.html`.
  - Reports generated by the pipeline: `pipeline_report.html`, `pipeline_report.txt` and `nf_core_plasmodiumdrugres_software_versions.yml`. The `pipeline_report*` files are only present if `--email` / `--email_on_fail` is set.
  - Parameters used by the pipeline run: `params.json`.

</details>

See the [Nextflow reports documentation](https://docs.seqera.io/platform-cloud/reports/overview) for more on the execution reports.
