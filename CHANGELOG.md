# nf-core/plasmodiumdrugres: Changelog

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## v1.0.0dev - [unreleased<!-- TODO nf-core: replace with date on release -->]

Initial release of nf-core/plasmodiumdrugres, created with the [nf-core](https://nf-co.re/) template.

### `Added`

- Sync with nf-core template version 4.1.0
- Collect local module software versions into `pipeline_info/nf_core_plasmodiumdrugres_software_versions.yml`
- Standardize `sl_summary.tsv` / `ml_summary.tsv` column schemas and archive full tool-specific concatenated tables under `raw_summaries/`

### `Fixed`

- Align README Nextflow / template badges with manifest and `.nf-core.yml`
- Point contributing guidelines at `docs/CONTRIBUTING.md`

### `Dependencies`

### `Deprecated`

- Remove unused FastQC and MultiQC modules (lint ignores MultiQC config; pipeline does not run MultiQC)
- Hide unused `--input` template parameter (kept for nf-core lint compatibility)
