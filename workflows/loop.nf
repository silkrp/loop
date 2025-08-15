/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT MODULES / SUBWORKFLOWS / FUNCTIONS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
include { paramsSummaryMap                      } from 'plugin/nf-schema'
include { softwareVersionsToYAML                } from '../subworkflows/nf-core/utils_nfcore_pipeline'
include { methodsDescriptionText                } from '../subworkflows/local/utils_nfcore_loop_pipeline'

// SUBWORKFLOWS
include { CORAL                                 } from '../subworkflows/local/coral/main'
include { DECOIL                                } from '../subworkflows/local/decoil/main'
include { CRESIL                                } from '../subworkflows/local/cresil/main'

// MODULES
include { SAMTOOLS_FAIDX                        } from '../modules/local/samtools/faidx/main'
include { FORMAT_CNVS                           } from '../modules/local/format_cnvs/main'
include { BCFTOOLS_QUERY as BCFTOOLS_QUERY_LR   } from '../modules/local/bcftools/query/main'
include { AMPLICONSUITE_AA                      } from '../modules/local/ampliconsuite/aa/main'
include { GUNZIP                                } from '../modules/nf-core/gunzip/main'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow LOOP {

    take:
    ch_sr_samplesheet // channel: short-read samplesheet read in from --sr_input
    ch_lr_samplesheet // channel: long-read samplesheet read in from --lr_input
    ch_reference      // channel: reference genome read in from --genome
    ch_annotation     // channel: annotation file read in from --gtf
    ch_gurobi         // channel: gurobi licence file read in from --gurobi
    ch_mosek          // channel: mosek licence file read in from --mosek
    ch_aa_data 
    ch_cresil_reference
    
    main:

    ch_versions = Channel.empty()

    def run_mode = params.run_mode ? params.run_mode.split(',') : []

    //
    // MODULE: Generate .fai index for FASTA
    //
    SAMTOOLS_FAIDX (
        ch_reference
    )

    ////////// SHORT READ 
    if ('short-read' in run_mode) {

        // 
        // MODULE: Run amplicon architect on short-read bam file
        //
        AMPLICONSUITE_AA (
            ch_sr_samplesheet,
            ch_mosek,
            ch_aa_data
        )

    }

    
    ////////// LONG READ 
    if ('long-read' in run_mode) {

        //
        // MODULE: Format cnv calls ready for ampliconsuite
        //
        bcftools_query_sr_input = ch_lr_samplesheet
            .map({ meta, bam, index, fastq, svs, cnvs -> [ meta, cnvs ] })

        BCFTOOLS_QUERY_LR (
            bcftools_query_sr_input
        )

        //
        // SUBWORKFLOW: Run CoRAL ecDNA prediction using CNV calls
        //
        coral_input_ch = ch_lr_samplesheet
            .map({ meta, bam, index, fastq, svs, cnvs -> [ meta, bam, index ] })
            .join(BCFTOOLS_QUERY.out.output)

        CORAL (
            coral_input_ch
            //ch_gurobi
        )

        //
        // SUBWORKFLOW: Run decoil pipeline
        // 
        svs_gunzip_input = ch_lr_samplesheet
            .map({ meta, svs -> [ meta, svs ] })

        svs_gunzip_input
            .branch { meta, svs ->
                needs_gunzip: svs.getExtension() == 'gz'
                    return [meta, svs]
                ready: true
                    return [meta, svs]
            }
            .set { input_branched }

        gunzipped = GUNZIP(input_branched.needs_gunzip).gunzip
        all_gunzipped = gunzipped.mix(input_branched.ready)

        decoil_input_ch = ch_lr_samplesheet
            .map({ meta, bam, index, fastq, svs, cnvs -> [ meta, bam, index ] })
            .join(all_gunzipped)

        DECOIL (
            decoil_input_ch,
            ch_reference,
            SAMTOOLS_FAIDX.out.fai,
            ch_annotation
        )

        //
        // SUBWORKFLOW: Run CReSIL
        //
        cresil_input_ch = ch_lr_samplesheet
            .map({ meta, bam, index, fastq, svs, cnvs -> [ meta, fastq ] })

        CRESIL (
            ch_reads,
            ch_cresil_reference
        )

    }


    //
    // Collate and save software versions
    //
    softwareVersionsToYAML(ch_versions)
        .collectFile(
            storeDir: "${params.outdir}/pipeline_info",
            name: 'nf_core_'  +  'loop_software_'  + 'versions.yml',
            sort: true,
            newLine: true
        ).set { ch_collated_versions }


    emit:
    versions       = ch_versions                 // channel: [ path(versions.yml) ]

}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    THE END
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
