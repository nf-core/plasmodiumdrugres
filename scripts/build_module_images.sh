#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

sync_env() {
    local template="$1"
    shift
    for module in "$@"; do
        cp "modules/env_templates/${template}/environment.yml" "modules/local/${module}/environment.yml"
        cp "modules/env_templates/${template}/Dockerfile" "modules/local/${module}/Dockerfile"
    done
}

sync_env r_tidyverse \
    split_aa_table_by_population \
    split_allele_table_by_population \
    merge_tables \
    concat_tables \
    count_samples_by_coi

sync_env pgecore_r \
    estimate_allele_prevalence_naive \
    estimate_allele_frequency_naive \
    estimate_multilocus_prevfreq_naive \
    slaf_from_mhaps_freqs \
    estimate_coi_naive

sync_env bioc_biostrings \
    add_ref_seqs_with_targeted_ref_fasta \
    add_ref_seqs_with_full_genome_ref_fasta

for module in slaf_from_stave_mlaf mlbm_wrapper; do
    cp modules/local/variantstring/environment.yml "modules/local/${module}/environment.yml"
    cp modules/local/variantstring/Dockerfile "modules/local/${module}/Dockerfile"
done

for module in extract_allele_table extract_population_map_from_pmo extract_panel_info_to_bed; do
    cp modules/local/pmotools/environment.yml "modules/local/${module}/environment.yml"
    cp modules/local/pmotools/Dockerfile "modules/local/${module}/Dockerfile"
done

for module in dcifer_ibd_wrapper; do
    cp modules/local/dcifer_slaf_wrapper/environment.yml "modules/local/${module}/environment.yml"
    cp modules/local/dcifer_slaf_wrapper/Dockerfile "modules/local/${module}/Dockerfile"
done

for module in pileup_specific_snps; do
    cp modules/local/translate_loci_of_interest/environment.yml "modules/local/${module}/environment.yml"
    cp modules/local/translate_loci_of_interest/Dockerfile "modules/local/${module}/Dockerfile"
done

build() {
    local tag="$1"
    local context="$2"
    # Match CI (ubuntu amd64) and nextflow.config docker profile. Override for native arm64:
    #   DOCKER_PLATFORM=linux/arm64 ./scripts/build_module_images.sh
    local platform="${DOCKER_PLATFORM:-linux/amd64}"
    echo "Building ${tag} from ${context} (platform=${platform})"
    docker build --platform "${platform}" -t "${tag}" "${context}"
}

build plasmogenepi/plasmodiumdrugres-r-tidyverse:1.0.0 modules/env_templates/r_tidyverse
build plasmogenepi/plasmodiumdrugres-pgecore-r:1.0.0 modules/env_templates/pgecore_r
build plasmogenepi/plasmodiumdrugres-bioc-biostrings:1.0.0 modules/env_templates/bioc_biostrings
build plasmogenepi/plasmodiumdrugres-translate-loci:1.0.0 modules/local/translate_loci_of_interest
build plasmogenepi/plasmodiumdrugres-variantstring:1.0.0 modules/local/variantstring
build plasmogenepi/plasmodiumdrugres-fem:1.0.0 modules/local/fem_wrapper
build plasmogenepi/plasmodiumdrugres-idm:1.0.0 modules/local/idm_wrapper
build plasmogenepi/plasmodiumdrugres-dcifer:1.0.0 modules/local/dcifer_slaf_wrapper
build plasmogenepi/plasmodiumdrugres-pmotools:1.0.0 modules/local/pmotools
build plasmogenepi/plasmodiumdrugres .

echo "All module images built."
