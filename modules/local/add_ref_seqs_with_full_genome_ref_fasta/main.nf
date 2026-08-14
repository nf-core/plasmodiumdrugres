/*
 * STEP - ADD_REF_SEQS_WITH_FULL_GENOME_REF_FASTA
 * add a column with the ref sequence pulled from a genome file using the coordinates of the bed file
 */

process ADD_REF_SEQS_WITH_FULL_GENOME_REF_FASTA {

    label 'process_single'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container
?         'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/fa/fa5e7a47124ffe90a02dcbdc8d87234f42aa88ec26014d4f45928f92b647052a/data'
:         'community.wave.seqera.io/library/bioc_biostrings:4bff14692906e36a' }"

    input:
    path ref_bed
    path genome

    output:
    path ("ref_bed_with_seqs.bed"), emit: ref_bed_with_seqs
    path "versions.yml", emit: versions

    script:
    """
    Rscript ${projectDir}/bin/PGEcore/scripts/add_ref_seq_to_ref_bed_table/add_ref_seqs_with_full_genome_ref_fasta.R \
        --genome_fasta ${genome} \
        --ref_bed ${ref_bed} \
        --out ref_bed_with_seqs.bed

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        r-base: \$( R --version | sed -n '1s/.*\\([0-9]\\+\\.[0-9]\\+\\.[0-9]\\+\\).*/\\1/p' )
        bioconductor-biostrings: \$( Rscript -e 'cat(as.character(packageVersion("Biostrings")))' 2>/dev/null || echo 'N/A' )
    END_VERSIONS
    """
}
