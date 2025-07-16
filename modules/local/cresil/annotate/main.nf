process CRESIL_ANNOTATE {
    tag "$meta.id"
    label 'process_medium'

    // FIXME Conda is not supported at the moment
    //conda "${moduleDir}/environment.yml"
    container "docker.io/hyeong8984/cresil:v1.1.0"

    input:
    tuple val(meta), path(identify)
    tuple val(meta2), path(cresil_reference)

    output:
    tuple val(meta), path("*")                      , emit: everything
    //path  "versions.yml"                            , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"

    """
    cresil annotate \\
        -t $task.cpus \\
        -rp reference.rmsk.bed \\
        -cg reference.cpg.bed \\
        -gb reference.gene.bed \\
        -identify $identify 

    mv cresil_gAnnotation ${prefix}_cresil_gAnnotation
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """

    """
}

