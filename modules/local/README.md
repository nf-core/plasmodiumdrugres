# Local nf-core-style modules

Pipeline-specific processes live under `modules/local/<module_name>/` with:

- `main.nf` — process definition (`conda`, `container`, `versions.yml` emit)
- `environment.yml` — Bioconda / conda-forge dependencies
- `meta.yml` — module metadata for linting and docs
- `.conda-lock/` — Wave/conda lock files from `nf-core modules container create` (when present)

## Containers

Module containers are built and published via Seqera Wave with:

```bash
nf-core modules container create modules/local/<module_name>
```

`main.nf` `container` directives point at the resulting `community.wave.seqera.io/...` (and singularity) URIs. Optional architecture-specific configs live under `conf/containers_*.config`.

## Testing

```bash
nf-test test tests/modules/local/merge_tables.nf.test --profile docker
nf-test test tests/modules/local/merge_tables.nf.test --profile conda
```

All module dependencies are on Bioconda/conda-forge, including:

| Package             | Conda name                    | Channel     |
| ------------------- | ----------------------------- | ----------- |
| pmotools            | `pmotools=1.1.0`              | bioconda    |
| dcifer              | `r-dcifer=1.5.2`              | conda-forge |
| variantstring       | `r-variantstring=1.8.7`       | bioconda    |
| FreqEstimationModel | `r-freqestimationmodel=0.1.0` | bioconda    |

Note: `r-variantstring`, `r-freqestimationmodel`, and Biostrings/`pwalign` modules pin `r-base=4.5` (Bioconductor 3.22 builds). Other R modules remain on `r-base=4.4`.

**Apple Silicon + conda:** `r-validate` has no `osx-arm64` build. Use `CONDA_SUBDIR=osx-64` (Rosetta) for local conda tests, or prefer `--profile docker`.

**Host pyenv:** The `conda` / `mamba` profiles strip `~/.pyenv` from `PATH` so process CLIs (e.g. `pmotools-python`) come from the conda env, not a host install.
