process SAVANA {
    tag "$meta.id"
    label 'process_medium'

    // FIXME Conda is not supported at the moment
    //conda "${moduleDir}/environment.yml"
    container "docker://quay.io/biocontainers/savana:1.3.4--pyhdfd78af_0"

    input:
    tuple val(meta), path(target_input), path(target_index), path(control_input), path(control_index), path(vcf) 
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
    savana to \\
        --tumour $target_input \\
        --outdir . \\
        --ref $fasta \\
        --snp_vcf $vcf

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        savana: \$(savana --version 2>&1 | sed 's/^.*savana //; s/ .*\$//')
    END_VERSIONS
    """
    // savana \\
    //     --tumour $tumor \\
    //     --normal $normal \\
    //     --outdir . \\
    //     --ref $fasta \\
    //     --snp_vcf <vcf-file> \\
    //     --sample $prefix

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        savana: \$(savana --version 2>&1 | sed 's/^.*savana //; s/ .*\$//')
    END_VERSIONS
    """
}

