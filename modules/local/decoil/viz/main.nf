process DECOIL_VIZ {
    tag "$meta.id"
    label 'process_medium'

    // FIXME Conda is not supported at the moment
    container "docker://madagiurgiu25/decoil-viz:1.0.3"

    input:
    tuple val(meta), path(bam), path(index), path(sv_vcf), path(bigwig), path(summary), path(bed), path(links)
    tuple val(meta2), path(fasta)
    tuple val(meta3), path(gtf)

    output:
    tuple val(meta), path("*.reconstruct.html")        , emit: html

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    bam_abs=\$(realpath ${bam})
    index_abs=\$(realpath ${index})
    sv_vcf_abs=\$(realpath ${sv_vcf})
    bigwig_abs=\$(realpath ${bigwig})
    summary_abs=\$(realpath ${summary})
    bed_abs=\$(realpath ${bed})
    links_abs=\$(realpath ${links})
    fasta_abs=\$(realpath ${fasta})
    gtf_abs=\$(realpath ${gtf})
    outdir_abs=\$(pwd)

    decoil-viz \\
        --coverage \$bigwig_abs \\
        --summary \$summary_abs \\
        --reference \$fasta_abs \\
        --annotation-gtf \$gtf_abs \\
        --bed \$bed_abs \\
        --links \$links_abs \\
        --outputdir \$outdir_abs \\
        --name ${prefix} \\
        --full FULL

    mv reconstruct.html ${prefix}.reconstruct.html

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        decoil-viz: \$(decoil-viz --version 2>&1 | sed 's/^.*decoil-viz //; s/ .*\$//')
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        decoil-viz: \$(decoil-viz --version 2>&1 | sed 's/^.*decoil-viz //; s/ .*\$//')
    END_VERSIONS
    """
}
