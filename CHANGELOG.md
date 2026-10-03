# nf-core/plasmodiumdrugres: Changelog

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## v1.0.0 - [2026-09-29]

Initial release of nf-core/plasmodiumdrugres, created with the [nf-core](https://nf-co.re/) template.

### `Added`

- Sync with nf-core template version 4.1.0
- Collect local module software versions into `pipeline_info/nf_core_plasmodiumdrugres_software_versions.yml`
- Standardize `sl_summary.tsv` / `ml_summary.tsv` column schemas and archive full tool-specific concatenated tables under `raw_summaries/`
- Multi-arch (`linux/amd64` and `linux/arm64`) Docker and Singularity containers and conda lock files for all local modules, built with `nf-core modules container create`
- `--fem_coi` parameter for the average complexity of infection FEM assumes for every specimen (default `3`, previously hard-coded in `FEM_WRAPPER`)
- `--pmo` accepts gzip-compressed PMO files (`.json.gz`)
- `--collapse_calls_by_summing` (default `true`) sums amino acid calls across all targets covering a locus; previously only the highest-read target was used
- `--pmo_replicate_libraries` (`combine` or `max_reads`) to choose how specimens with several library samples in a PMO are handled
- `test_full` profile now runs on real MAD4HatTeR surveillance data from Eswatini, Namibia, South Africa and Zambia (1,646 specimens, Dataset 1 of the PMO paper, [Zenodo 10.5281/zenodo.20550920](https://doi.org/10.5281/zenodo.20550920))

### `Fixed`

- Align README Nextflow / template badges with manifest and `.nf-core.yml`
- Point contributing guidelines at `docs/CONTRIBUTING.md`
- Allele tables extracted from a PMO now use `specimen_name` instead of `library_sample_name`, so populations derived with `--pmo_population_fields` match specimens when the two names differ
- `docker` profile no longer forces `linux/amd64` emulation, so Apple Silicon uses native arm64 images (use `-profile docker,emulate_amd64` to opt back in)
- Specimens missing from the population assignment are no longer dropped silently: they are listed in `unassigned_specimens.txt` in the output directory and the run logs a warning with their count. The report name is now spelt consistently in `split_table_by_population_map.R` and both split modules

### `Dependencies`

- Use Bioconda `r-pgecore=0.1.0` instead of the `bin/PGEcore` git submodule; update modules to the packaged CLI flag names
- Bump `r-freqestimationmodel` to 0.1.1 (adds MCMC seeding required by PGEcore's FEM wrapper)

### `Deprecated`

- Remove unused FastQC and MultiQC modules (lint ignores MultiQC config; pipeline does not run MultiQC)
- Hide unused `--input` template parameter (kept for nf-core lint compatibility)
- Remove the monolithic `plasmogenepi/plasmodiumdrugres` Docker image fallback; every local module now declares its own container
