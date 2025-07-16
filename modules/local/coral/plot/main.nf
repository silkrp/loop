process CORAL_PLOT {
    tag "$meta.id"
    label 'process_medium'

    // FIXME Conda is not supported at the moment
    container "docker.io/rpsilk/coral:latest"

    input:
    tuple val(meta), path(bam), path(index), path(cn_seg), path(graph), path(cycles)
    
    output:
    tuple val(meta), path("*_converted_all_cycles.bed")     , emit: bed
    tuple val(meta), path("*_cycles.pdf")                   , emit: cycles_pdf
    tuple val(meta), path("*_graph.pdf")                    , emit: graph_pdf
    tuple val(meta), path("*_cycles.png")                   , emit: cycles_png
    tuple val(meta), path("*_graph.png")                    , emit: graph_png


    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    coral plot \\
        --ref hg38 \\
        --bam $bam \\
        --graph $graph \\
        --cycle-file $cycles \\
        --output-prefix $prefix \\
        --plot-cycles 
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}_converted_all_cycles.bed  
    touch ${prefix}_cycles.png  
    touch ${prefix}_graph.png
    touch ${prefix}_cycles.pdf                
    touch ${prefix}_graph.pdf
    """
}

