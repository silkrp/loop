process WAKHAN {
    tag "$meta.id"
    label 'process_medium'

    // FIXME Conda is not supported at the moment
    //conda "${moduleDir}/environment.yml"
    container "docker.io/mkolmogo/wakhan:dev_c717baa"

    input:
    tuple val(meta), path(tumor_bam), path(tumor_index), path(phased_vcf), path(severus_vcf)
    tuple val(meta2), path(fasta)

    output:
    tuple val(meta), path("*")                      , emit: everything
    //path  "versions.yml"                            , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    wakhan \\
        --threads $task.cpus \\
        --reference $fasta \\
        --target-bam $tumour_bam \\
        --normal-phased-vcf $phased_vcf \\
        --genome-name $prefix \\
        --out-dir-plots . \\
        --breakpoints $severus_vcf
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """

    """
}

