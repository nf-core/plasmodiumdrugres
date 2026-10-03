/*
 * STEP - DCIFER_WRAPPER
 * Run the Dcifer allele frequency wrapper script
 */

process DCIFER_SLAF_WRAPPER {

    label 'process_low'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container
?         'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/9b/9bab54983c4e424479bda4b7b8d6a17b403205bc68e93dc3078485f6b6528d3a/data'
:         'community.wave.seqera.io/library/dcifer_slaf_wrapper:d418b71ff1cb5828' }"

    input:
    path allele_table

    output:
    tuple val("${allele_table.getBaseName(3)}"), path("${allele_table.getBaseName(3)}.mhaps_slaf.tsv"), emit: mhaps_slaf
    path "versions.yml", emit: versions

    script:
    def extra_args = task.ext.args ? task.ext.args : ''

    """
    export PATH="\$(Rscript -e 'cat(system.file(\"exec\", package = \"PGEcore\"))'):\${PATH}"
    dcifer_slaf_wrapper \\
        --allele_table ${allele_table} \\
        --slaf_output "${allele_table.getBaseName(3)}.mhaps_slaf.tsv" \\
        ${extra_args}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        r-base: \$( R --version | sed -n '1s/.*\\([0-9]\\+\\.[0-9]\\+\\.[0-9]\\+\\).*/\\1/p' )
        r-pgecore: \$( Rscript -e 'cat(as.character(packageVersion("PGEcore")))' )
        dcifer: \$( Rscript -e 'cat(as.character(packageVersion("dcifer")))' 2>/dev/null || echo 'N/A' )
    END_VERSIONS
    """
}

//@todo need to figure out a way to add an optional --coi_table data/example_coi_table.tsv
//the below defaults are handled by the parmas.dcifer_slaf_wraper_* arguments which then gets added to task.ext.args
//--coi_lrank 2
//--qstart 0.5
//--tol 0.0001
