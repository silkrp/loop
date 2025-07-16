include { DEEPTOOLS_BAMCOVERAGE    } from '../../../modules/nf-core/deeptools/bamcoverage/main'
include { DECOIL_RECONSTRUCT       } from '../../../modules/local/decoil/reconstruct/main'
include { DECOIL_VIZ               } from '../../../modules/local/decoil/viz/main'

workflow DECOIL {
    take:
    ch_samplesheet      // channel: [ val(meta), path(bam), path(index), path(vcf) ]
    ch_reference        // channel: [ val(meta), path(fasta) ]
    ch_reference_fai    // channel: [ val(meta), path(fai) ]
    ch_annotation       // channel: [ val(meta), path(gtf) ]

    main:

    ch_versions = Channel.empty()

    //
    // MODULE: Generate BigWig file using deeptools bamCoverage
    //
    bam_ch = ch_samplesheet
        .map { meta, bam, index, vcf -> [meta, bam, index] }

    fasta_ch = ch_reference.map { meta, fasta -> fasta }
    fai_ch = ch_reference_fai.map { meta, fai -> fai }

    DEEPTOOLS_BAMCOVERAGE (
        bam_ch,
        fasta_ch,
        fai_ch
    )
    ch_versions = ch_versions.mix(DEEPTOOLS_BAMCOVERAGE.out.versions.first())

    //
    // Generate channel of tumour bam, sv vcf, and bigwig file
    //    
    decoil_input_ch = ch_samplesheet
        .join(DEEPTOOLS_BAMCOVERAGE.out.bigwig)
        
    //
    // MODULES: Run decoil pipeline
    //
    DECOIL_RECONSTRUCT (
        decoil_input_ch,
        ch_reference,
        ch_annotation,
        params.sv_caller
    )

    //
    // MODULES: Run decoil-viz pipeline
    //
    decoil_viz_input = decoil_input_ch
        .join(DECOIL_RECONSTRUCT.out.summary_txt)
        .join(DECOIL_RECONSTRUCT.out.ecdna_filtered_bed)
        .join(DECOIL_RECONSTRUCT.out.ecdna_links_filtered)

    DECOIL_VIZ (
        decoil_viz_input,
        ch_reference,
        ch_annotation
    )

    emit:
    versions   = ch_versions
}
