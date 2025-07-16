process NANOMONSV_PARSE {
    tag "$meta.id"
    label 'process_medium'

    // FIXME Conda is not supported at the moment
    //conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/nanomonsv:0.7.2--pyhdfd78af_0' :
        'biocontainers/nanomonsv:0.8.0--pyhdfd78af_0' }"

    input:
    tuple val(meta), path(bam), path(index)
    tuple val(meta2), path(fasta)

    output:
    tuple val(meta), path("*.bp_info.sorted.bed.gz")              , emit: bp_info
    tuple val(meta), path("*.bp_info.sorted.bed.gz.tbi")          , emit: bp_info_tbi
    tuple val(meta), path("*.deletion.sorted.bed.gz")             , optional: true, emit: deletion
    tuple val(meta), path("*.deletion.sorted.bed.gz.tbi")         , optional: true, emit: deletion_tbi
    tuple val(meta), path("*.insertion.sorted.bed.gz")            , optional: true, emit: insertion
    tuple val(meta), path("*.insertion.sorted.bed.gz.tbi")        , optional: true, emit: insertion_tbi
    tuple val(meta), path("*.rearrangement.sorted.bedpe.gz")      , optional: true, emit: rearrangement
    tuple val(meta), path("*.rearrangement.sorted.bedpe.gz.tbi")  , optional: true, emit: rearrangement_tbi
    path  "versions.yml"                                          , emit: versions


    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def type = task.ext.type ?: "${meta.type}"
    """
    nanomonsv parse \\
        --reference_fasta $fasta \\
        $bam \\
        ${prefix}.${type}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        nanomonsv: \$(nanomonsv --version 2>&1 | sed 's/^.*nanomonsv //; s/ .*\$//')
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    def type = task.ext.type ?: "${meta.type}"
    """
    touch ${prefix}.${type}.bp_info.sorted.bed.gz
    touch ${prefix}.${type}.bp_info.sorted.bed.gz.tbi
    touch ${prefix}.${type}.deletion.sorted.bed.gz
    touch ${prefix}.${type}.deletion.sorted.bed.gz.tbi
    touch ${prefix}.${type}.insertion.sorted.bed.gz
    touch ${prefix}.${type}.insertion.sorted.bed.gz.tbi
    touch ${prefix}.${type}.rearrangement.sorted.bed.gz
    touch ${prefix}.${type}.rearrangement.sorted.bed.gz.tbi

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        nanomonsv: \$(nanomonsv --version 2>&1 | sed 's/^.*nanomonsv //; s/ .*\$//')
    END_VERSIONS
    """
}

