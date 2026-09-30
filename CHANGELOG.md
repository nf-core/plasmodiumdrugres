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

### `Fixed`

- Align README Nextflow / template badges with manifest and `.nf-core.yml`
- Point contributing guidelines at `docs/CONTRIBUTING.md`
- `docker` profile no longer forces `linux/amd64` emulation, so Apple Silicon uses native arm64 images (use `-profile docker,emulate_amd64` to opt back in)
- Call `bin/` scripts by name instead of `${projectDir}/bin/...` so they are staged on executors without a shared launch directory (AWS Batch, Google Batch, Seqera Platform); make all `bin/` scripts executable

### `Dependencies`

- Use Bioconda `r-pgecore=0.1.0` instead of the `bin/PGEcore` git submodule; update modules to the packaged CLI flag names
- Bump `r-freqestimationmodel` to 0.1.1 (adds MCMC seeding required by PGEcore's FEM wrapper)

### `Deprecated`

- Remove unused FastQC and MultiQC modules (lint ignores MultiQC config; pipeline does not run MultiQC)
- Hide unused `--input` template parameter (kept for nf-core lint compatibility)
- Remove the monolithic `plasmogenepi/plasmodiumdrugres` Docker image fallback; every local module now declares its own container
