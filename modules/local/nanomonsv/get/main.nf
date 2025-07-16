process NANOMONSV_GET {
    tag "$meta.id"
    label 'process_medium'

    // FIXME Conda is not supported at the moment
    //conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/nanomonsv:0.7.2--pyhdfd78af_0' :
        'biocontainers/nanomonsv:0.8.0--pyhdfd78af_0' }"

    input:
    tuple val(meta), path(tumour_bam), path(tumour_index), path(normal_bam), path(normal_index), path(nanomonsv_parse_output)
    tuple val(meta2), path(fasta)

    output:
    tuple val(meta), path("*.nanomonsv.result.txt")              , emit: txt
    tuple val(meta), path("*.tumour.nanomonsv.result.vcf")       , emit: vcf
    tuple val(meta), path("*.nanomonsv.supporting_read.txt")     , emit: supporting_reads
    path  "versions.yml"                                         , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def control = normal_bam ? "--control_prefix ${prefix}.normal --control_bam $normal_bam" : ''
    """
    nanomonsv get \\
        ${prefix}.tumour \\
        $tumour_bam \\
        $fasta \\
        $control \\
        --processes $task.cpus    
    
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        nanomonsv: \$(nanomonsv --version 2>&1 | sed 's/^.*nanomonsv //; s/ .*\$//')
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        nanomonsv: \$(nanomonsv --version 2>&1 | sed 's/^.*nanomonsv //; s/ .*\$//')
    END_VERSIONS
    """
}

