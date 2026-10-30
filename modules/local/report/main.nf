/*
 * STEP - REPORT
 * HTML report of quality-control, sanity-check and results plots
 */

process REPORT {
    tag "all populations"
    label 'process_low'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container
?         'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/91/9171694963b936e4d51ebe9fb7e76abf6372d9cad32d6f691f126e12b306a96b/data'
:         'community.wave.seqera.io/library/report:43073bb72f678898' }"

    input:
    path sl_summary
    path ml_summary
    path raw_summaries
    path loci_coverage
    path aa_calls
    path report_templates, stageAs: 'report_templates'
    path unassigned_specimens
    path population_assignment

    output:
    path "plasmodiumdrugres_report.html" , emit: report
    path "figures/*"                     , optional: true, emit: figures
    path "versions.yml"                  , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: '--interactive TRUE'
    def pop_label = params.population_label ?: 'pop1'
    """
    mkdir -p tmp figures
    export HOME="\$PWD"
    export TMPDIR="\$PWD/tmp"
    export TMP="\$PWD/tmp"
    export TEMP="\$PWD/tmp"
    export XDG_CACHE_HOME="\$PWD/tmp"
    export XDG_CONFIG_HOME="\$PWD/tmp"
    export R_USER_CACHE_DIR="\$PWD/tmp"
    export R_USER_CONFIG_DIR="\$PWD/tmp"
    export R_USER_DATA_DIR="\$PWD/tmp"
    cp -L report_templates/* .
    render_report.R \\
        --sl_summary ${sl_summary} \\
        --ml_summary ${ml_summary} \\
        --sl_from_ml ${raw_summaries}/raw_sl_from_ml_summary.tsv \\
        --loci_coverage ${loci_coverage} \\
        --aa_calls ${aa_calls} \\
        --template report.Rmd \\
        --output plasmodiumdrugres_report.html \\
        --figures_dir figures \\
        --population_label ${pop_label} \\
        --unassigned ${unassigned_specimens} \\
        --population_assignment ${population_assignment} \\
        ${args}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        r-base: \$( R --version | sed -n '1s/.*\\([0-9]\\+\\.[0-9]\\+\\.[0-9]\\+\\).*/\\1/p' )
        r-ggplot2: \$( Rscript -e 'cat(as.character(packageVersion("ggplot2")))' )
        r-plotly: \$( Rscript -e 'cat(as.character(packageVersion("plotly")))' )
        r-rmarkdown: \$( Rscript -e 'cat(as.character(packageVersion("rmarkdown")))' )
        pandoc: \$( pandoc --version | sed -n '1s/.* //p' )
    END_VERSIONS
    """
}
