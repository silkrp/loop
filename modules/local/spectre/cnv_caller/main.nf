process SPECTRE_CNV_CALLER {
    tag "$meta.id"
    label 'process_medium'

    // FIXME Conda is not supported at the moment
    container "docker.io/rpsilk/spectre:latest"

    input:
    tuple val(meta), path(mosdepth_regions_bed), path(mosdepth_regions_csi)
    tuple val(meta2), path(mdr)
    tuple val(meta3), path(fasta)

    output:
    tuple val(meta), path('*.vcf.gz')          , emit: vcf
    tuple val(meta), path('*_cnv.bed.gz')      , emit: bed
    tuple val(meta), path('*_cnv.bed.gz.tbi')  , emit: bed_index
    tuple val(meta), path('*.spc.gz')          , emit: spc
    path  "versions.yml"                       , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"

    // TODO nf-core: add check for sample type (tumour or normal) so that --cancer can be set correctly
    // TODO nf-core: add in blacklist areas for spectre
    // TODO nf-core: add in the ploidy for individual chromosomes? 
    // TODO nf-core: provide a SNV file for the sample? 
    """
    spectre CNVCaller \\
        --coverage $mosdepth_regions_bed \\
        --sample-id $prefix \\
        --output-dir . \\
        --reference $fasta \\
        --metadata $mdr \\
        --cancer

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        spectre: \$(spectre version 2>&1 | sed 's/^.*spectre //; s/ .*\$//')
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}.vcf
    touch ${prefix}_cnv.bed.gz
    touch ${prefix}_cnv.bed.gz.tbi
    touch ${prefix}.spc.gz

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        spectre: \$(spectre version 2>&1 | sed 's/^.*spectre //; s/ .*\$//')
    END_VERSIONS
    """
}
