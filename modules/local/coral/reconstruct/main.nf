process CORAL_RECONSTRUCT {
    tag "$meta.id"
    label 'process_medium'

    // FIXME Conda is not supported at the moment
    container "docker.io/rpsilk/coral:latest"
    containerOptions '--bind ~/gurobi/gurobi.lic:/opt/gurobi/gurobi.lic'

    input:
    tuple val(meta), path(bam), path(index), path(cn_seg), path(seed_bed)
    //tuple val(meta4), path(gurobi_licence)

    output:
    tuple val(meta), path("*_cycles.txt")          , emit: cycles    //, optional: true
    tuple val(meta), path("*_graph.txt")           , emit: graph     //, optional: true
    tuple val(meta), path("*_summary.txt")         , emit: summary   //, optional: true
    tuple val(meta), path("*_alignments.pickle")   , emit: pickle    //, optional: true
    tuple val(meta), path("*_graph.log")           , emit: log       //, optional: true

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"

    // export GRB_LICENSE_FILE=\$(realpath $gurobi_licence)

    """
    coral reconstruct \\
        --lr-bam $bam \\
        --cnv-seed $seed_bed \\
        --output-dir . \\
        --cn-seg $cn_seg \\
        --solver-threads $task.cpus 

    mv amplicon1_cycles.txt ${prefix}.amplicon1_cycles.txt
    mv amplicon1_graph.txt ${prefix}.amplicon1_graph.txt
    mv amplicon_summary.txt ${prefix}.amplicon_summary.txt
    mv chimeric_alignments.pickle ${prefix}.chimeric_alignments.pickle
    mv infer_breakpoint_graph.log ${prefix}.infer_breakpoint_graph.log
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch amplicon1_cycles.txt  
    touch amplicon_summary.txt
    touch infer_breakpoint_graph.log
    touch amplicon1_graph.txt   
    touch chimeric_alignments.pickle
    """
}

