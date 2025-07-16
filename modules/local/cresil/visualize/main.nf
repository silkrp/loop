process CRESIL_VISUALIZE {
    tag "$meta.id"
    label 'process_medium'

    // FIXME Conda is not supported at the moment
    //conda "${moduleDir}/environment.yml"
    container "docker.io/hyeong8984/cresil:v1.1.0"

    input:
    tuple val(meta), path(tumor_bam), path(tumor_index), path(normal_bam), path(normal_index), path(phased_vcf), path(severus_vcf)
    tuple val(meta2), path(fasta)
    val phased

    output:
    tuple val(meta), path("*")                      , emit: everything
    //path  "versions.yml"                            , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def phasing = phased ? "" : "--without-phasing"
    def phased_vcf_input = normal_bam ? "--normal-phased-vcf $phased_vcf" : "--tumor-vcf $phased_vcf"

    """
    cresil visualize \\
        -t 4 \\
        -c ec1 \\
        -identify cresil_result/eccDNA_final.txt     
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """

    """
}

