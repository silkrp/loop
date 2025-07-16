process DECOIL_RECONSTRUCT {
    tag "$meta.id"
    label 'process_medium'

    // TODO make output so that they have the sample name in them
    // FIXME Conda is not supported at the moment
    container "docker.io/rpsilk/decoil:22-make-decoil-compatible-with-more-sv-callers-outputs"

    input:
    tuple val(meta), path(bam), path(index), path(sv_vcf), path(bigwig)
    tuple val(meta2), path(fasta)
    tuple val(meta3), path(gtf)
    val sv_caller

    output:
    tuple val(meta), path("*.reconstruct.bed")                          , emit: reconstruct_bed
    tuple val(meta), path("*.reconstruct.ecDNA.bed")                    , emit: reconstruct_ecdna_bed
    tuple val(meta), path("*.summary.txt")                              , emit: summary_txt
    tuple val(meta), path("*.reconstruct.ecDNA.fasta")                  , emit: ecdna_fasta
    tuple val(meta), path("*.reconstruct.ecDNA.filtered.bed")           , emit: ecdna_filtered_bed
    tuple val(meta), path("*.reconstruct.ecDNA.filtered.fasta")         , emit: ecdna_filtered_fasta
    tuple val(meta), path("*.reconstruct.fasta")                        , emit: fasta
    tuple val(meta), path("*.reconstruct.links.ecDNA.filtered.txt")     , emit: ecdna_links_filtered
    tuple val(meta), path("*.reconstruct.links.ecDNA.txt")              , emit: ecdna_links
    tuple val(meta), path("*.reconstruct.links.txt")                    , emit: links
    path  "versions.yml"                                                , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def caller = sv_caller == "nanomonsv"  ? "nanomonsv" : "sniffles2"
    """
    decoil reconstruct \\
        --sv-caller 'nanomonsv' \\
        --bam $bam \\
        --vcf $sv_vcf \\
        --coverage $bigwig \\
        --outputdir . \\
        --name $prefix \\
        --reference-genome $fasta \\
        --annotation-gtf $gtf

    mv reconstruct.bed ${prefix}.reconstruct.bed
    mv reconstruct.ecDNA.bed ${prefix}.reconstruct.ecDNA.bed
    mv summary.txt ${prefix}.summary.txt
    mv reconstruct.ecDNA.fasta ${prefix}.reconstruct.ecDNA.fasta
    mv reconstruct.ecDNA.filtered.bed ${prefix}.reconstruct.ecDNA.filtered.bed
    mv reconstruct.ecDNA.filtered.fasta ${prefix}.reconstruct.ecDNA.filtered.fasta
    mv reconstruct.fasta ${prefix}.reconstruct.fasta
    mv reconstruct.links.ecDNA.filtered.txt ${prefix}.reconstruct.links.ecDNA.filtered.txt
    mv reconstruct.links.ecDNA.txt ${prefix}.reconstruct.links.ecDNA.txt
    mv reconstruct.links.txt ${prefix}.reconstruct.links.txt

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        decoil: \$(decoil --version 2>&1 | sed 's/^.*decoil //; s/ .*\$//')
    END_VERSIONS
    """
    
    // TODO nf-core: consider what filters should be used in decoil
    // filters used by Ed
    // --filter-score 40 \
    // --fragment-min-cov 40 \
    // --min-cov 40 \
    // --min-cov-alt 20 \
    // --min-vaf 0.01 \
    // --fragment-min-size 1000 \
    // --min-sv-len 5000

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch reconstruct.bed
    touch reconstruct.ecDNA.bed
    touch summary.txt

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        decoil: \$(decoil --version 2>&1 | sed 's/^.*decoil //; s/ .*\$//')
    END_VERSIONS
    """
}
