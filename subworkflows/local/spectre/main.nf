include { MOSDEPTH                      } from '../../../modules/local/mosdepth/main'
include { SPECTRE_REMOVE_NS             } from '../../../modules/local/spectre/remove_ns/main'
include { SPECTRE_CNV_CALLER            } from '../../../modules/local/spectre/cnv_caller/main'

workflow SPECTRE {
    take:
    ch_input        // channel: [ val(meta), path(bam), path(index) ]
    ch_reference    // channel: [ val(meta), path(fasta) ]

    main:

    ch_versions = Channel.empty()

    //
    // MODULE: Run mosdepth
    // 
    MOSDEPTH (
        ch_input,
        ch_reference
    )
    ch_versions = ch_versions.mix(MOSDEPTH.out.versions.first())

    //
    // MODULE: Generate mdr file 
    // 
    SPECTRE_REMOVE_NS (
        ch_reference
    )
    ch_versions = ch_versions.mix(SPECTRE_REMOVE_NS.out.versions.first())

    //
    // MODULE: Run spectre cnv caller
    // 
    mosdepth_ch = MOSDEPTH.out.regions_bed
        .join(MOSDEPTH.out.regions_csi)
    
    SPECTRE_CNV_CALLER (
        mosdepth_ch,
        SPECTRE_REMOVE_NS.out.mdr,
        ch_reference
    )
    ch_versions = ch_versions.mix(SPECTRE_CNV_CALLER.out.versions.first())

    emit:
    spectre_cnv_bed     = SPECTRE_CNV_CALLER.out.bed
    versions            = ch_versions
}
