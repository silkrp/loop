process CORAL_CYCLE {
    tag "$meta.id"
    label 'process_medium'

    // FIXME Conda is not supported at the moment
    container "docker.io/rpsilk/coral:latest"
    containerOptions '--bind ~/gurobi/gurobi.lic:/opt/gurobi/gurobi.lic'

    input:
    tuple val(meta), path(graph)

    output:
    tuple val(meta), path("*.cycle_decomposition.log")    , emit: log
    tuple val(meta), path("*_cycles.txt")               , emit: cycles

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    coral cycle \\
        --bp-graph $graph \\
        --output-dir . \\
        --threads $task.cpus 
    
    mv amplicon1_cycles.txt ${prefix}.amplicon1_cycles.txt
    mv cycle_decomposition.log ${prefix}.cycle_decomposition.log
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """

    """
}

