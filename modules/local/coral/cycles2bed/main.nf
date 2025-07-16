process CORAL_CYCLES2BED {
    tag "$meta.id"
    label 'process_medium'

    // FIXME Conda is not supported at the moment
    container "docker.io/rpsilk/coral:latest"

    input:
    tuple val(meta), path(cycles)

    output:
    tuple val(meta), path("*.bed")                    , emit: bed

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    coral cycle2bed \\
        --cycle-file $cycles \\
        --output-file ${prefix}.bed
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}.bed
    """
}

