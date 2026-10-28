/*
 * STEP - ADD_REF_SEQS_WITH_FULL_GENOME_REF_FASTA
 * add a column with the ref sequence pulled from a genome file using the coordinates of the bed file
 */

process ADD_REF_SEQS_WITH_FULL_GENOME_REF_FASTA {
    tag "${ref_bed.name}"
    label 'process_single'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container
?         'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/23/235feee891e603259b7567113cccf878a64af4a645f7df5437538c6850cc8095/data'
:         'community.wave.seqera.io/library/add_ref_seqs_biostrings:d01d72c23bec9e6c' }"

    input:
    path ref_bed
    path genome

    output:
    path ("ref_bed_with_seqs.bed") , emit: ref_bed_with_seqs
    path "versions.yml"            , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    """
    export PATH="\$(Rscript -e 'cat(system.file(\"exec\", package = \"PGEcore\"))'):\${PATH}"
    add_ref_seqs_with_full_genome_ref_fasta \\
        --genome_fasta ${genome} \\
        --ref_bed ${ref_bed} \\
        --output ref_bed_with_seqs.bed

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        r-base: \$( R --version | sed -n '1s/.*\\([0-9]\\+\\.[0-9]\\+\\.[0-9]\\+\\).*/\\1/p' )
        r-pgecore: \$( Rscript -e 'cat(as.character(packageVersion("PGEcore")))' )
        bioconductor-biostrings: \$( Rscript -e 'cat(as.character(packageVersion("Biostrings")))' )
    END_VERSIONS
    """
}
