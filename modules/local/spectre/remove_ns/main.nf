process SPECTRE_REMOVE_NS {
    tag "$fasta"
    label 'process_medium'

    // FIXME Conda is not supported at the moment
    container "docker.io/rpsilk/spectre:latest"

    input:
    tuple val(meta), path(fasta)

    output:
    tuple val(meta), path('*.mdr')      , emit: mdr
    path  "versions.yml"                , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def genome = task.ext.prefix ?: "${meta.genome}"

    """
    spectre RemoveNs \\
        --reference $fasta \\
        --output-dir . \\
        --output-file ${genome}.mdr 

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        spectre: \$(spectre version 2>&1 | sed 's/^.*spectre //; s/ .*\$//')
    END_VERSIONS
    """

    stub:
    def genome = task.ext.prefix ?: "${meta.genome}"
    """
    touch ${genome}.mdr

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        spectre: \$(spectre version 2>&1 | sed 's/^.*spectre //; s/ .*\$//')
    END_VERSIONS
    """
}
