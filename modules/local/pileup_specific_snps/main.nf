/*
 * STEP - PILEUP_SPECIFIC_SNPS
 * Extract SNPs of interest from allele table
 */

process PILEUP_SPECIFIC_SNPS {
    label 'process_low'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container ?
        'plasmogenepi/plasmodiumdrugres-translate-loci:1.0.0' :
        'plasmogenepi/plasmodiumdrugres-translate-loci:1.0.0' }"

    input:
    path allele_table
    path ref_bed
    path snps_of_interest
    val extra_args

    output:
    path ("base_counts/collapsed_snp_calls.tsv.gz"), emit: collapsed_snp_calls
    path ("base_counts/snp_calls.tsv.gz"), emit: snp_calls
    path ("base_counts/snps_covered_by_target_samples_info.tsv"), emit: snps_covered_by_target_samples_info
    path "versions.yml", emit: versions

    script:
    def extra_args = "${extra_args}"
    """
    Rscript ${projectDir}/bin/PGEcore/scripts/pileup_specific_snps/pileup_specific_snps.R \\
        --allele_table ${allele_table} \\
        --ref_bed ${ref_bed} \\
        --snps_of_interest ${snps_of_interest} \\
        --output_directory base_counts \\
        ${extra_args}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        r-base: \$( R --version | sed -n '1s/.*\\([0-9]\\+\\.[0-9]\\+\\.[0-9]\\+\\).*/\\1/p' )
        bioconductor-pwalign: \$( Rscript -e 'cat(as.character(packageVersion("pwalign")))' 2>/dev/null || echo 'N/A' )
    END_VERSIONS
    """
}
