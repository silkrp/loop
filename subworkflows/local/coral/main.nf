include { CORAL_SEED            } from '../../../modules/local/coral/seed/main'
include { CORAL_RECONSTRUCT     } from '../../../modules/local/coral/reconstruct/main'
include { CORAL_PLOT            } from '../../../modules/local/coral/plot/main'
include { CORAL_HSR             } from '../../../modules/local/coral/hsr/main'
include { CORAL_CYCLES2BED      } from '../../../modules/local/coral/cycles2bed/main'
include { CORAL_CYCLE           } from '../../../modules/local/coral/cycle/main'

workflow CORAL {
    take:
    ch_input    // channel: [ val(meta), path(bam), path(index), path(cnvs)]
    //ch_gurobi

    main:

    ch_versions = Channel.empty()

    coral_seed_input = ch_input
        .map({ meta, bam, index, cnvs -> [ meta, cnvs ] })
    //
    // MODULE: Run coral seed
    // 
    CORAL_SEED (
        coral_seed_input
    )
    //ch_versions = ch_versions.mix(CORAL_SEED.out.versions.first())

    non_empty_coral_seeds = CORAL_SEED.out.seed_bed
        .filter({ meta, seeds -> !file(seeds).isEmpty() })

    //
    // MODULE: Run coral reconstruct
    // 
    coral_reconstruct_input = ch_input
        .join(non_empty_coral_seeds)

    CORAL_RECONSTRUCT (
        coral_reconstruct_input,
        //ch_gurobi
    )

    //
    // MODULE: Run coral plot
    // 
    coral_plot_input = ch_input
        .join(CORAL_RECONSTRUCT.out.graph)
        .join(CORAL_RECONSTRUCT.out.cycles)

    CORAL_PLOT (
        coral_plot_input
    )

    // //
    // // MODULE: Run coral HSR
    // // 
    // coral_hsr_input = ch_input
    //     .join(CORAL_RECONSTRUCT.out.cycles)
    //     .join(CORAL_RECONSTRUCT.out.log)

    // CORAL_HSR (
    //     coral_hsr_input
    // )

    //
    // MODULE: Run coral cycles2bed
    // 
    CORAL_CYCLES2BED (
        CORAL_RECONSTRUCT.out.cycles
    )

    //
    // MODULE: Run coral cycle
    // 
    CORAL_CYCLE (
        CORAL_RECONSTRUCT.out.graph
    )

    emit:
    versions   = ch_versions
}
