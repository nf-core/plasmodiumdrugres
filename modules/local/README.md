# Local nf-core-style modules

Pipeline-specific processes live under `modules/local/<module_name>/` with:

- `main.nf` — process definition (`conda`, `container`, `versions.yml` emit)
- `environment.yml` — Bioconda / conda-forge dependencies
- `meta.yml` — module metadata for linting and docs (where present)
- `Dockerfile` — when no single BioContainer exists (multi-tool R envs)

Shared environment templates live under `modules/env_templates/` and are copied into module directories by `scripts/build_module_images.sh`.

## Environment families

| Image tag | Used by |
|-----------|---------|
| `plasmogenepi/plasmodiumdrugres-translate-loci:1.0.0` | `translate_loci_of_interest`, `pileup_specific_snps` |
| `plasmogenepi/plasmodiumdrugres-bioc-biostrings:1.0.0` | `add_ref_seqs_with_targeted_ref_fasta`, `add_ref_seqs_with_full_genome_ref_fasta` |
| `plasmogenepi/plasmodiumdrugres-r-tidyverse:1.0.0` | `split_*_by_population`, `merge_tables`, `concat_tables`, `count_samples_by_coi` |
| `plasmogenepi/plasmodiumdrugres-pgecore-r:1.0.0` | naive prev/freq, multilocus naive, `slaf_from_mhaps_freqs`, `estimate_coi_naive` |
| `plasmogenepi/plasmodiumdrugres-variantstring:1.0.0` | `mlbm_wrapper`, `slaf_from_stave_mlaf` |
| `plasmogenepi/plasmodiumdrugres-fem:1.0.0` | `fem_wrapper` |
| `plasmogenepi/plasmodiumdrugres-idm:1.0.0` | `idm_wrapper` |
| `plasmogenepi/plasmodiumdrugres-dcifer:1.0.0` | `dcifer_slaf_wrapper`, `dcifer_ibd_wrapper` |
| `plasmogenepi/plasmodiumdrugres-pmotools:1.0.0` | `extract_allele_table`, `extract_population_map_from_pmo`, `extract_panel_info_to_bed` |
| `plasmogenepi/plasmodiumdrugres` | legacy monolithic fallback in `nextflow.config` docker profile |

Build all module images:

```bash
./scripts/build_module_images.sh
```

Images are built for `linux/amd64` by default (same as GitHub Actions). On Apple Silicon this uses Docker emulation and is slower but matches CI. For native arm64 local builds: `DOCKER_PLATFORM=linux/arm64 ./scripts/build_module_images.sh`.

If a build fails with `Read-only file system` under `/opt/conda/pkgs`, Docker Desktop is usually out of disk space or has a stale cache — free space in Docker Desktop settings, then run `docker builder prune -f` and retry.

Run module tests with Docker (build images first):

```bash
nf-test test tests/modules/local/merge_tables.nf.test --profile test,docker
```

Use `--profile test,conda` for modules whose dependencies are on Bioconda/conda-forge (tidyverse, Biostrings, pmotools, etc.).

**Conda limitations:** Some R packages are not on Bioconda/conda-forge (`dcifer`, `variantstring`, and `FreqEstimationModel` are installed from PlasmoGenEpi r-universe or GitHub in Dockerfiles). `pmotools` is installed from PyPI via `pip`. With `--profile conda`, Nextflow only uses `environment.yml`, not the Dockerfile — so `dcifer_*`, `mlbm_wrapper`, `slaf_from_stave_mlaf`, and `fem_wrapper` tests require `--profile test,docker` (after `./scripts/build_module_images.sh`).

Per-module images are not published to Docker Hub yet; build locally or extend CI publish workflows before removing the monolithic fallback.
