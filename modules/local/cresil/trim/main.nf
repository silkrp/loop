process CRESIL_TRIM {
    tag "$meta.id"
    label 'process_medium'

    // FIXME Conda is not supported at the moment
    //conda "${moduleDir}/environment.yml"
    container "docker.io/hyeong8984/cresil:v1.1.0"

    input:
    tuple val(meta), path(reads)
    tuple val(meta2), path(cresil_reference)

    output:
    tuple val(meta), path("*/trim.txt")               , emit: trim

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"

    """
    cresil trim \\
        -t $task.cpus \\
        -fq $reads \\
        -r reference.mmi \\
        -o $prefix
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """

    """
}
