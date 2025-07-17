█ ▄▄▄ ▄▄▄ ▄▄▄▄  
█ █ █ █ █ █ █
█ ▀▄▄▄▀ ▀▄▄▄▀ █▄▄▄▀
█ █  
 ▀

## Introduction

**loop** is an nextflow pipeline designed to run a range of ecDNA (extrachromosomal DNA) prediction algorithms on both short-read and long-read whole-genome sequencing (WGS) data.

The pipeline supports the following tools:

### Short-read WGS data

- **[AmpliconArchitect](https://github.com/virajbdeshpande/AmpliconArchitect)** – Detects focal amplifications and reconstructs ecDNA structures from short-read sequencing.

### Long-read WGS data

- **[CoRAL](https://github.com/AmpliconSuite/CoRAL)** – Predicts circular DNA structures using long-read data and copy number information.
- **[Decoil](https://github.com/madagiurgiu25/decoil-pre)** – A long-read–based method for detecting and characterising ecDNAs from SV calls.
- **[CReSIL](https://github.com/visanuwan/cresil)** – Uses long-reads to identify ecDNAs via consensus polishing and graph-based analysis.

## Usage

> [!NOTE]
> If you are new to Nextflow and nf-core, please refer to [this page](https://nf-co.re/docs/usage/installation) on how to set-up Nextflow. Make sure to [test your setup](https://nf-co.re/docs/usage/introduction#how-to-run-a-pipeline) with `-profile test` before running the workflow on actual data.

<!-- TODO nf-core: Describe the minimum required steps to execute the pipeline, e.g. how to prepare samplesheets.
     Explain what rows and columns represent. For instance (please edit as appropriate):

First, prepare a samplesheet with your input data that looks as follows:

`samplesheet.csv`:

```csv
sample,fastq_1,fastq_2
CONTROL_REP1,AEG588A1_S1_L002_R1_001.fastq.gz,AEG588A1_S1_L002_R2_001.fastq.gz
```

Each row represents a fastq file (single-end) or a pair of fastq files (paired end).

-->

Now, you can run the pipeline using:

<!-- TODO nf-core: update the following command to include all required parameters for a minimal example -->

```bash
nextflow run main.nf \
   -profile <docker/singularity/.../institute> \
    --sr_input ./sr_samplesheet.csv \
    --lr_input ./lr_samplesheet.csv \
    --outdir <OUTDIR> \
    --genome GRCh38 \
    --gurobi ~/gurobi/gurobi.lic \
    --mosek ~/mosek/mosek.lic \
    --aa_data ../data_repo \
    --cresil_mmi ../cresil_reference/reference.mmi \
    --cresil_fa ../cresil_reference/reference.fa \
    --cresil_rmsk ../cresil_reference/reference.rmsk.bed \
    --cresil_gene ../cresil_reference/reference.gene.bed \
    --cresil_cpg ../cresil_reference/reference.cpg.bed \
    --cresil_fai ../cresil_reference/reference.fa.fai
```

> [!WARNING]
> Please provide pipeline parameters via the CLI or Nextflow `-params-file` option. Custom config files including those provided by the `-c` Nextflow option can be used to provide any configuration _**except for parameters**_; see [docs](https://nf-co.re/docs/usage/getting_started/configuration#custom-configuration-files).

For more details and further functionality, please refer to the [usage documentation](https://nf-co.re/loop/usage) and the [parameter documentation](https://nf-co.re/loop/parameters).

## Pipeline output

The pipeline will output results from each of the ecDNA prediction algorithms selected. These can be found in the specfiied output directory. Please refer to the individual tool repositories for detailed output information.
