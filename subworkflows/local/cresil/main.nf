include { GUNZIP                      } from '../../../modules/nf-core/gunzip/main'
include { CRESIL_TRIM                 } from '../../../modules/local/cresil/trim/main'
include { CRESIL_IDENTIFY             } from '../../../modules/local/cresil/identify/main'
include { CRESIL_ANNOTATE             } from '../../../modules/local/cresil/annotate/main'
// include { CRESIL_VISUALIZE            } from '../../../modules/local/cresil/visualize/main'

workflow CRESIL {
    take:
    ch_input                 // channel: [ val(meta), path(reads) ]
    ch_cresil_reference      // channel: [ val(meta), path(mmi) ]

    main:

    ch_versions = Channel.empty()

    ch_input
        .branch { meta, file ->
            needs_gunzip: file.getExtension() == 'gz'
                return [meta, file]
            ready: true
                return [meta, file]
        }
        .set { input_branched }

    // Process the gz files
    gunzipped = GUNZIP(input_branched.needs_gunzip).gunzip

    // Combine processed and unprocessed files
    cresil_trim_input = gunzipped.mix(input_branched.ready)

    //
    // MODULE: Run cresil trim
    // 
    CRESIL_TRIM (
        cresil_trim_input,
        ch_cresil_reference
    )

    //
    // MODULE: Run cresil identify
    // 
    identify_input = cresil_trim_input
        .join(CRESIL_TRIM.out.trim)

    CRESIL_IDENTIFY (
        identify_input,
        ch_cresil_reference
    )

    //
    // MODULE: Run cresil annotate
    // 
    CRESIL_ANNOTATE (
        CRESIL_IDENTIFY.out.identify,
        ch_cresil_reference
    )

    // CRESIL_VISUALIZE (

    // )


    emit:
    versions            = ch_versions

}
