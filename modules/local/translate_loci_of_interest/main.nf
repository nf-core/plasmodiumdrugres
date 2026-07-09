/*
 * STEP - TRANSLATE_LOCI_OF_INTEREST
 * Pull out and translate loci of interest to amino acid calls
 */

process TRANSLATE_LOCI_OF_INTEREST {
    label 'process_low'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container ?
        'plasmogenepi/plasmodiumdrugres-translate-loci:1.0.0' :
        'plasmogenepi/plasmodiumdrugres-translate-loci:1.0.0' }"

    input:
    path allele_table
    path ref_bed
    path loci_of_interest
    val extra_args

    output:
    path ("translated_loci/collapsed_amino_acid_calls.tsv.gz"), emit: collapsed_amino_acid_calls
    path ("translated_loci/amino_acid_calls.tsv.gz"), emit: amino_acid_calls
    path ("translated_loci/loci_covered_by_target_samples_info.tsv"), emit: loci_covered_by_target_samples_info
    path ("translated_loci/loci_of_interest_for_target_for_microhap.tsv.gz"), emit: loci_of_interest_for_target_for_microhap
    path "versions.yml", emit: versions

    publishDir "${params.outdir}", mode: "${params.publish_dir_mode}", overwrite: true

    script:
    def extra_args = "${extra_args}"
    """
    Rscript ${projectDir}/bin/PGEcore/scripts/translate_loci_of_interest/translate_loci_of_interest.R \\
        --allele_table ${allele_table} \\
        --ref_bed ${ref_bed} \\
        --loci_of_interest ${loci_of_interest} \\
        --output_directory translated_loci \\
        ${extra_args}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        r-base: \$( R --version | sed -n '1s/.*\\([0-9]\\+\\.[0-9]\\+\\.[0-9]\\+\\).*/\\1/p' )
        bioconductor-biostrings: \$( Rscript -e 'cat(as.character(packageVersion("Biostrings")))' 2>/dev/null || echo 'N/A' )
        bioconductor-pwalign: \$( Rscript -e 'cat(as.character(packageVersion("pwalign")))' 2>/dev/null || echo 'N/A' )
    END_VERSIONS
    """
}
