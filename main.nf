#!/usr/bin/env nextflow
/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    nf-core/loop
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    Github : https://github.com/nf-core/loop
    Website: https://nf-co.re/loop
    Slack  : https://nfcore.slack.com/channels/loop
----------------------------------------------------------------------------------------
*/

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT FUNCTIONS / MODULES / SUBWORKFLOWS / WORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { LOOP  } from './workflows/loop'
include { PIPELINE_INITIALISATION } from './subworkflows/local/utils_nfcore_loop_pipeline'
include { PIPELINE_COMPLETION     } from './subworkflows/local/utils_nfcore_loop_pipeline'
include { getGenomeAttribute      } from './subworkflows/local/utils_nfcore_loop_pipeline'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    GENOME PARAMETER VALUES
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

params.fasta = getGenomeAttribute('fasta')
params.gtf = getGenomeAttribute('gtf')

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    NAMED WORKFLOWS FOR PIPELINE
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

//
// WORKFLOW: Run main analysis pipeline depending on type of input
//
workflow NFCORE_LOOP {

    take:
    sr_samplesheet // channel: samplesheet read in from --input
    lr_samplesheet // channel: samplesheet read in from --input
    reference   // channel: reference genome read in from --genome
    annotation  // channel: annotation file read in from --gtf
    gurobi      // channel: gurobi licence file read in from --gurobi
    mosek
    aa_data
    cresil_reference

    main:

    //
    // WORKFLOW: Run pipeline
    //
    LOOP (
        sr_samplesheet,
        lr_samplesheet,
        reference,
        annotation,
        gurobi,
        mosek,
        aa_data,
        cresil_reference
    )

}
/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow {

    main:
    //
    // SUBWORKFLOW: Run initialisation tasks
    //
    PIPELINE_INITIALISATION (
        params.version,
        params.validate_params,
        params.monochrome_logs,
        args,
        params.outdir,
        params.sr_input,
        params.lr_input,
        params.fasta,
        params.genome,
        params.gtf,
        params.gurobi,
        params.mosek,
        params.aa_data,
        params.cresil_mmi,
        params.cresil_fa,
        params.cresil_rmsk,
        params.cresil_gene,
        params.cresil_cpg,
        params.cresil_fai

    )

    //
    // WORKFLOW: Run main workflow
    //
    NFCORE_LOOP (
        PIPELINE_INITIALISATION.out.samplesheet,
        PIPELINE_INITIALISATION.out.reference,
        PIPELINE_INITIALISATION.out.annotation,
        PIPELINE_INITIALISATION.out.gurobi,
        PIPELINE_INITIALISATION.out.mosek,
        PIPELINE_INITIALISATION.out.aa_data,
        PIPELINE_INITIALISATION.out.cresil_reference

    )

    //
    // SUBWORKFLOW: Run completion tasks
    //
    PIPELINE_COMPLETION (
        params.email,
        params.email_on_fail,
        params.plaintext_email,
        params.outdir,
        params.monochrome_logs,
        params.hook_url
    )

}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    THE END
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
