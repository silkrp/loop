process CORAL_SEED {
    tag "$meta.id"
    label 'process_medium'

    // FIXME Conda is not supported at the moment
    container "docker.io/rpsilk/coral:latest"

    input:
    tuple val(meta), path(cn_seg)

    output:
    tuple val(meta), path("*_CNV_SEEDS.bed")      , emit: seed_bed
    //path  "versions.yml"            , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    coral seed \\
        --cn-seg $cn_seg \\
        --output-prefix $prefix
    """

    // cat <<-END_VERSIONS > versions.yml
    // "${task.process}":
    //     cramino: \$(cramino --version 2>&1 | sed 's/^.*cramino //; s/ .*\$//')
    // END_VERSIONS

    // stub:
    // def prefix = task.ext.prefix ?: "${meta.id}"
    // """
    // touch ${prefix}.cramino.txt

    // cat <<-END_VERSIONS > versions.yml
    // "${task.process}":
    //     cramino: \$(cramino --version 2>&1 | sed 's/^.*cramino //; s/ .*\$//')
    // END_VERSIONS
    // """
}

