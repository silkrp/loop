include { NANOMONSV_PARSE          } from '../../../modules/local/nanomonsv/parse/main'
include { NANOMONSV_GET            } from '../../../modules/local/nanomonsv/get/main'

workflow NANOMONSV {
    take:
    ch_samplesheet    // channel: [ val(meta), path(bam), path(index)]
    ch_reference  // channel: [ val(meta), path(fasta) ]

    main:

    ch_versions = Channel.empty()
    
    if (params.matched) {

        nanomonsv_input_ch = ch_samplesheet

    } else {

        nanomonsv_input_ch = ch_samplesheet
            .filter({ meta, bam, index -> meta.type == 'tumour' })

    }

    //
    // MODULE: Run nanomonsv for SV calling
    //
    NANOMONSV_PARSE (
        nanomonsv_input_ch,
        ch_reference
    )

    //
    // Generate channel for tumour-normal bam pairs
    //
    if (params.matched) {
        
        ch_tumour = ch_samplesheet
            .filter({ meta, bam, index -> meta.type == 'tumour' })
            .map({ meta, bam, index -> [[id: meta.id, type: 'paired'], bam, index] })
            
        ch_normal = ch_samplesheet
            .filter({ meta, bam, index -> meta.type == 'normal' })
            .map({ meta, bam, index -> [[id: meta.id, type: 'paired'], bam, index] })
    
        matched_bam_ch = ch_tumour
            .join(ch_normal)

    } else {

        matched_bam_ch = ch_samplesheet
            .map({ meta, bam, index -> [[id: meta.id, type: 'paired'], bam, index, [], []] })

    }

    //
    // Generate channel for tumour-normal pairs from nanomonsv output
    //
    NANOMONSV_PARSE.out.bp_info.mix(
               NANOMONSV_PARSE.out.bp_info_tbi,
               NANOMONSV_PARSE.out.deletion,
               NANOMONSV_PARSE.out.deletion_tbi,
               NANOMONSV_PARSE.out.insertion,
               NANOMONSV_PARSE.out.insertion_tbi,
               NANOMONSV_PARSE.out.rearrangement,
               NANOMONSV_PARSE.out.rearrangement_tbi)
    .map { meta, file -> tuple(meta.id, file) }
    .groupTuple()
    .map { sample, files -> tuple([ id: sample, type: "paired" ], files)}
    .set { nanomonsv_paired_ch }

    //
    // Generate final input for nanomonsv containing matched normal-tumour bam files and nanomonsv parse output files
    //
    nanomonsv_get_input = matched_bam_ch
        .join(nanomonsv_paired_ch)

    //
    // MODULE: Run nanomonsv for SV calling
    //
    NANOMONSV_GET (
        nanomonsv_get_input,
        ch_reference
    )

    emit:
    vcf        = NANOMONSV_GET.out.vcf
    versions   = ch_versions
}
