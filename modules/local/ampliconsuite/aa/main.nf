process AMPLICONSUITE_AA {
    tag "${meta.id}"
    label 'process_medium'

    //container "docker://quay.io/biocontainers/ampliconsuite:1.3.8--pyhdfd78af_0"
    container 'nf-core/prepareaa:1.0.5'

    input:
    tuple val(meta), path(tumour_bam), path(tumour_index), path(cnv_bed)
    tuple val(meta2), path(mosek_license_dir)
    tuple val(meta3), path(aa_data_repo)

    output:
    tuple val(meta), path('*')     , emit: everything

    output:
    tuple val(meta), path('*'), emit: aa_output

    // path "*.bed"                    , emit: bed
    // path "*.log"                    , emit: log
    // path "*run_metadata.json"       , emit: run_metadata_json
    // path "*sample_metadata.json"    , emit: sample_metadata_json
    // path "*timing_log.txt"          , emit: timing_log
    // path "*logs.txt"                , emit: logs, optional: true
    // path "*cycles.txt"              , emit: cycles, optional: true
    // path "*graph.txt"               , emit: graph, optional: true
    // path "versions.yml"             , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"

    """
    export AA_DATA_REPO=\$(echo $aa_data_repo)
    export MOSEKLM_LICENSE_FILE=\$(pwd)
    export AA_SRC=\$(dirname \$(python -c "import ampliconarchitectlib; print(ampliconarchitectlib.__file__)"))
    export AC_SRC=\$(dirname \$(which amplicon_classifier.py))

    AmpliconSuite-pipeline.py \\
        $args \\
        -s $prefix \\
        -t $task.cpus \\
        --cnv_bed $cnv_bed \\
        --bam $tumour_bam \\
        --ref hg38 \\
        --run_AA --run_AC 

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        AmpliconSuite-pipeline.py: \$(AmpliconSuite-pipeline.py --version | sed 's/AmpliconSuite-pipeline version //')
    END_VERSIONS
    """

    // find ${prefix}_AA_results/ -type f -print0 | xargs -0 mv -t ./
    // find ${prefix}_classification/ -type f -print0 | xargs -0 mv -t ./

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}.bed
    touch ${prefix}_run_metadata.json
    touch ${prefix}_sample_metadata.json
    touch ${prefix}_timing_log.txt

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        AmpliconSuite-pipeline.py: \$(AmpliconSuite-pipeline.py --version | sed 's/AmpliconSuite-pipeline version //')
    END_VERSIONS
    """
}
