process CORAL_HSR {
    tag "$meta.id"
    label 'process_medium'

    // FIXME Conda is not supported at the moment
    container "docker.io/rpsilk/coral:latest"

    input:
    tuple val(meta), path(bam), path(index), path(cn_seg), path(cycles), path(logfile)

    output:
    tuple val(meta), path("*")                      , emit: everything

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    cov=\$(awk -F 'LR normal cov =' '{print \$2}' $logfile | cut -d',' -f1)
    echo \$cov

    coral hsr \\
        --lr-bam $bam \\
        --cycles $cycles \\
        --cn-seg $cn_seg \\
        --output-prefix $prefix \\
        --normal-cov \$cov
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    """
}
