/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT MODULES / SUBWORKFLOWS / FUNCTIONS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
include { paramsSummaryMap                      } from 'plugin/nf-schema'
include { softwareVersionsToYAML                } from '../subworkflows/nf-core/utils_nfcore_pipeline'
include { methodsDescriptionText                } from '../subworkflows/local/utils_nfcore_loop_pipeline'

// SUBWORKFLOWS
include { SPECTRE                               } from '../subworkflows/local/spectre/main'
include { CORAL                                 } from '../subworkflows/local/coral/main'
include { NANOMONSV                             } from '../subworkflows/local/nanomonsv/main'
include { DECOIL                                } from '../subworkflows/local/decoil/main'
include { CRESIL                                } from '../subworkflows/local/cresil/main'

// MODULES
include { SAMTOOLS_FAIDX                        } from '../modules/local/samtools/faidx/main'
include { CNVKIT_BATCH                          } from '../modules/local/cnvkit/batch/main'
include { CNVKIT_EXPORT                         } from '../modules/local/cnvkit/export/main'
include { FORMAT_CNVS                           } from '../modules/local/format_cnvs/main'
include { BCFTOOLS_QUERY                        } from '../modules/local/bcftools/query/main'
include { AMPLICONSUITE_AA                      } from '../modules/local/ampliconsuite/aa/main'
include { SNIFFLES                              } from '../modules/nf-core/sniffles/main'
include { GUNZIP                                } from '../modules/nf-core/gunzip/main'

//include { DEEPVARIANT_RUNDEEPVARIANT    } from '../modules/local/deepvariant/rundeepvariant/main'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow LOOP {

    take:
    ch_samplesheet // channel: samplesheet read in from --input
    ch_reference   // channel: reference genome read in from --genome
    ch_annotation  // channel: annotation file read in from --gtf
    ch_cnn         // channel: cnn target reference file read in from --cnn
    ch_gurobi      // channel: gurobi licence file read in from --gurobi
    ch_mosek       // channel: mosek licence file read in from --mosek
    ch_aa_data 
    ch_cnv_calls 
    ch_reads
    ch_cresil_reference
    
    main:

    ch_versions = Channel.empty()

    ch_samplesheet_lr = ch_samplesheet
        .map({ meta, lr_bam, lr_index, sr_bam, sr_index -> [ meta, lr_bam, lr_index ] })

    ch_samplesheet_sr = ch_samplesheet
        .map({ meta, lr_bam, lr_index, sr_bam, sr_index -> [ meta, sr_bam, sr_index ] })


    //
    // MODULE: Generate .fai index for FASTA
    //
    SAMTOOLS_FAIDX (
        ch_reference
    )
    ch_versions = ch_versions.mix(SAMTOOLS_FAIDX.out.versions.first())


    //////////////////////////////////////
    //////////////////////////////////////
    ////////// SHORT READ 
    //////////////////////////////////////
    //////////////////////////////////////
    //
    // Logic for picking which short-read CNV caller to use
    //
    if (params.sr_cnv_caller == 'cnvkit') {

        // if CNVkit is chosen, use the built in cnvkit caller in the amplicon architect pipeline
        if (params.sr_matched) {
            
            sr_tumour = ch_samplesheet_sr
                .filter({ meta, bam, index -> meta.type == 'tumour' })
                .map({ meta, bam, index -> [[id: meta.id, type: 'paired'], bam, index ] })

            sr_normal = ch_samplesheet_sr
                .filter({ meta, bam, index -> meta.type == 'normal' })
                .map({ meta, bam, index -> [[id: meta.id, type: 'paired'], bam, index ] })

            aa_input = sr_tumour
                .join(sr_normal)
                .map({ meta, tumour_bam, tumour_index, normal_bam, normal_index -> [ meta, tumour_bam, tumour_index, normal_bam, normal_index, [] ] })

        } else {

            aa_input = ch_samplesheet_sr
                .filter({ meta, bam, index -> meta.type == 'tumour' })
                .map({ meta, tumour_bam, tumour_index -> [ meta, tumour_bam, tumour_index, [], [], [] ] })

        }


    } else if (params.sr_cnv_caller == "own") {
        
        aa_input = ch_samplesheet_sr
            .filter({ meta, bam, index -> meta.type == 'tumour' })
            .map({ meta, bam, index -> [ [id: meta.id], bam, index ] })
            .join(ch_cnv_calls)
            .map({ meta, bam, index, bed -> [ meta, bam, index, [], [], bed ] })

    } else {

        error "Unknown short-read CNV caller: '${params.sr_cnv_caller}'. Please choose one of: cnvkit. Alternatively, you can supply your own CNV call .bed file using --sr-cnv-calls"

    }

    // 
    // MODULE: Run amplicon architect on short-read bam file
    //
    AMPLICONSUITE_AA (
        aa_input,
        ch_mosek,
        ch_aa_data
    )

    
    //////////////////////////////////////
    //////////////////////////////////////
    ////////// LONG READ 
    //////////////////////////////////////
    //////////////////////////////////////
    // Logic for picking which CNV caller to use
    //
    if (params.cnv_caller == 'cnvkit') {
        
        //
        // If the pipeline is run in matched mode create a channel with tumour:normal bam pairs
        // otherwise create a channel with only tumour samples and an empty normal file
        //
        if (params.matched) {
            
            ch_tumour = ch_samplesheet_lr
                .filter({ meta, bam, index -> meta.type == 'tumour' })
                .map({ meta, bam, index -> [[id: meta.id, type: 'paired'], bam ] })
                
            ch_normal = ch_samplesheet_lr
                .filter({ meta, bam, index -> meta.type == 'normal' })
                .map({ meta, bam, index -> [[id: meta.id, type: 'paired'], bam ] })
                
            matched_bam_ch = ch_tumour
                .join(ch_normal)

            cnn_reference = [[],[]]

        } else {

            matched_bam_ch = ch_samplesheet_lr
                .filter({ meta, bam, index -> meta.type == 'tumour' })
                .map({ meta, bam, index -> [[id: meta.id, type: 'paired'], bam, [] ] })

            cnn_reference = ch_cnn

        }

        // 
        // MODULE: CNVKit CNV calling
        //
        CNVKIT_BATCH (
            matched_bam_ch,
            ch_reference,
            SAMTOOLS_FAIDX.out.fai,
            [[],[]],
            cnn_reference,
            false
        )

        cnv_ch = CNVKIT_BATCH.out.cns_call
            .map({ meta, cns -> [[id: meta.id, type: 'tumour'], cns ] })


    } else if (params.cnv_caller == 'spectre') {
        
        //
        // SUBWORKFLOW: Spectre CNV calling
        //
        spectre_input_ch = ch_samplesheet_lr
            .filter({ meta, bam, index -> meta.type == 'tumour' })

        SPECTRE (
            spectre_input_ch,
            ch_reference
        )

        //
        // MODULE: Uncompress CNV bed file and format ready for CoRAL
        //
        FORMAT_CNVS (
            SPECTRE.out.spectre_cnv_bed
        )

        cnv_ch = FORMAT_CNVS.out.gunzip

    } else if (params.cnv_caller == "own") {


    } else {

        error "Unknown CNV caller: '${params.cnv_caller}'. Please choose one of: cnvkit. Alternatively, you can supply your own CNV call .bed file using --cnv-calls"

    }

    //
    // SUBWORKFLOW: Run CoRAL ecDNA prediction using CNV calls
    //
    coral_input_ch = ch_samplesheet_lr
        .filter({ meta, bam, index -> meta.type == 'tumour' })
        .join(cnv_ch)

    CORAL (
        coral_input_ch
        //ch_gurobi
    )

    //
    // Logic for picking which SV caller to use
    //
    if (params.sv_caller == "nanomonsv") {

        // SUBWORKFLOW: Run Nanomonsv pipeline
        //
        NANOMONSV (
            ch_samplesheet_lr,
            ch_reference
        )

        sv_ch = NANOMONSV.out.vcf
            .map({ meta, vcf -> [[id: meta.id, type: 'tumour'], vcf ] })

    } else if (params.sv_caller == 'sniffles') {
        
        //
        // MODULE: Run sniffles SV caller
        //
        tumour_only_samplesheet = ch_samplesheet_lr
            .filter({ meta, bam, index -> meta.type == 'tumour' })

        SNIFFLES (
            tumour_only_samplesheet,
            ch_reference,
            [[],[]],
            true, 
            true
        )

        //
        // MODULE: Uncompress the vcf file ready for decoil
        //
        GUNZIP (
            SNIFFLES.out.vcf
        )

        sv_ch = GUNZIP.out.gunzip

    } else if (params.sv_caller == "own") {

        // TODO nf-core: input your own vcf file instead of using on of these variant callers
        // TODO nf-core: Add in SAVANA, although this is not yet supported by decoil
        // might need to make it so that it it read in through an input file 
        // that way we can link the bed file with each of the samples
        
    } else {

        error "Unknown SV caller: '${params.sv_caller}'. Please choose one of: nanomonsv, sniffles"

    }

    //
    // SUBWORKFLOW: Run decoil pipeline
    // 
    decoil_input_ch = ch_samplesheet_lr
        .join(sv_ch)

    DECOIL (
        decoil_input_ch,
        ch_reference,
        SAMTOOLS_FAIDX.out.fai,
        ch_annotation
    )


    //
    // SUBWORKFLOW: Run CReSIL
    //
    CRESIL (
        ch_reads,
        ch_cresil_reference
    )


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
