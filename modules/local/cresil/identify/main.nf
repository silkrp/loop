process CRESIL_IDENTIFY {
    tag "$meta.id"
    label 'process_medium'

    // FIXME Conda is not supported at the moment
    //conda "${moduleDir}/environment.yml"
    container "docker.io/hyeong8984/cresil:v1.1.0"

    input:
    tuple val(meta), path(reads), path(trim)
    tuple val(meta2), path(cresil_reference)

    output:
    tuple val(meta), path("*.eccDNA_final.txt")                      , emit: identify

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"

    """
    cresil identify \\
        -t $task.cpus \\
        -fa reference.fa \\
        -fai reference.fa.fai \\
        -fq $reads \\
        -cm r1041_e82_400bps_hac_v4.3.0 \\
        -trim $trim \\
        -s

    mv eccDNA_final.txt ${prefix}.eccDNA_final.txt
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """

    """
}

