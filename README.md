# ![nf-core/rnafusion](docs/images/nf-core-rnafusion_logo_light.png#gh-light-mode-only) ![nf-core/rnafusion](docs/images/nf-core-rnafusion_logo_dark.png#gh-dark-mode-only)

[![GitHub Actions CI Status](https://github.com/nf-core/rnafusion/workflows/nf-core%20CI/badge.svg)](https://github.com/nf-core/rnafusion/actions?query=workflow%3A%22nf-core+CI%22)
[![GitHub Actions Linting Status](https://github.com/nf-core/rnafusion/workflows/nf-core%20linting/badge.svg)](https://github.com/nf-core/rnafusion/actions?query=workflow%3A%22nf-core+linting%22)
[![AWS CI](https://img.shields.io/badge/CI%20tests-full%20size-FF9900?logo=Amazon%20AWS)](https://nf-co.re/rnafusion/results)
[![Cite with Zenodo](http://img.shields.io/badge/DOI-10.5281/zenodo.XXXXXXX-1073c8)](https://doi.org/10.5281/zenodo.XXXXXXX)

[![Nextflow](https://img.shields.io/badge/nextflow%20DSL2-%E2%89%A521.10.3-23aa62.svg)](https://www.nextflow.io/)
[![run with conda](http://img.shields.io/badge/run%20with-conda-3EB049?logo=anaconda)](https://docs.conda.io/en/latest/)
[![run with docker](https://img.shields.io/badge/run%20with-docker-0db7ed?logo=docker)](https://www.docker.com/)
[![run with singularity](https://img.shields.io/badge/run%20with-singularity-1d355c.svg)](https://sylabs.io/docs/)
[![Launch on Nextflow Tower](https://img.shields.io/badge/Launch%20%F0%9F%9A%80-Nextflow%20Tower-%234256e7)](https://tower.nf/launch?pipeline=https://github.com/nf-core/rnafusion)

[![Get help on Slack](http://img.shields.io/badge/slack-nf--core%20%23rnafusion-4A154B?logo=slack)](https://nfcore.slack.com/channels/rnafusion)
[![Follow on Twitter](http://img.shields.io/badge/twitter-%40nf__core-1DA1F2?logo=twitter)](https://twitter.com/nf_core)
[![Watch on YouTube](http://img.shields.io/badge/youtube-nf--core-FF0000?logo=youtube)](https://www.youtube.com/c/nf-core)

## Introduction

**nf-core/rnafusion** is a bioinformatics best-practice analysis pipeline for RNA sequencing analysis pipeline with curated list of tools for detecting and visualizing fusion genes.

The pipeline is built using [Nextflow](https://www.nextflow.io), a workflow tool to run tasks across multiple compute infrastructures in a very portable manner. It uses Docker/Singularity containers making installation trivial and results highly reproducible. The [Nextflow DSL2](https://www.nextflow.io/docs/latest/dsl2.html) implementation of this pipeline uses one container per process which makes it much easier to maintain and update software dependencies. Where possible, these processes have been submitted to and installed from [nf-core/modules](https://github.com/nf-core/modules) in order to make them available to all nf-core pipelines, and to everyone within the Nextflow community!

> GRCh38 is the only supported reference

| Tool                                                      |  Single-end reads  | Version  |
| --------------------------------------------------------- | :----------------: | :------: |
| [Arriba](https://github.com/suhrig/arriba)                |        :x:         | `2.2.1`  |
| [FusionCatcher](https://github.com/ndaniel/fusioncatcher) | :white_check_mark: |  `1.33`  |
| [Fusion-report](https://github.com/matq007/fusion-report) |         -          | `2.1.5`  |
| [Pizzly](https://github.com/pmelsted/pizzly)              |        :x:         | `0.37.3` |
| [Squid](https://github.com/Kingsford-Group/squid)         |        :x:         |  `1.5`   |
| [STAR-Fusion](https://github.com/STAR-Fusion/STAR-Fusion) | :white_check_mark: | `1.10.1` |

On release, automated continuous integration tests run the pipeline on a full-sized dataset on the AWS cloud infrastructure. This ensures that the pipeline runs on AWS, has sensible resource allocation defaults set to run on real-world datasets, and permits the persistent storage of results to benchmark between pipeline releases and other analysis sources. The results obtained from the full-sized test can be viewed on the [nf-core website](https://nf-co.re/rnafusion/results).

In rnafusion the full-sized test includes reference building and fusion detection. The test dataset is taken from [here](https://github.com/nf-core/test-datasets/tree/rnafusion/testdata/human).

## Pipeline summary

#### Build references

`--build_references` triggers a parallel workflow to build all references

1. Download ensembl fasta and gtf files
2. Create STAR index
3. Download arriba references
4. Download fusioncatcher references
5. Download pizzly references (kallisto index)
6. Download and build STAR-fusion references
7. Download fusion-report DBs

#### Main workflow

1. Input samplesheet check
2. Concatenate fastq files per sample
3. Read QC ([`FastQC`](https://www.bioinformatics.babraham.ac.uk/projects/fastqc/))
4. Arriba subworkflow
   - [STAR](https://github.com/alexdobin/STAR) alignment
   - [Samtool](https://github.com/samtools/samtools) sort
   - [Samtool](https://github.com/samtools/samtools) index
   - [Arriba](https://github.com/suhrig/arriba) fusion detection
   - [Arriba](https://github.com/suhrig/arriba) visualisation
5. Pizzly subworkflow
   - [Kallisto](https://pachterlab.github.io/kallisto/) quantification
   - [Pizzly](https://github.com/pmelsted/pizzly) fusion detection
6. Squid subworkflow
   - [STAR](https://github.com/alexdobin/STAR) alignment
   - [Samtools view](http://www.htslib.org/): convert sam output from STAR to bam
   - [Samtools sort](http://www.htslib.org/): bam output from STAR
   - [Squid](https://github.com/Kingsford-Group/squid) fusion detection
   - [Squid](https://github.com/Kingsford-Group/squid) annotate
7. STAR-fusion subworkflow
   - [STAR](https://github.com/alexdobin/STAR) alignment
   - [STAR-fusion](https://github.com/STAR-Fusion/STAR-Fusion) fusion detection
8. Fusioncatcher subworkflow
   - [FusionCatcher](https://github.com/ndaniel/fusioncatcher) fusion detection
9. Fusion-report subworkflow
   - Merge all fusions detected by the different tools
   - [Fusion-report](https://github.com/matq007/fusion-report)
10. FusionInspector subworkflow
    - [FusionInspector](https://github.com/FusionInspector/FusionInspector)
11. Present QC for raw reads ([`MultiQC`](http://multiqc.info/))
12. QC for mapped reads ([`QualiMap: BAM QC`](https://kokonech.github.io/qualimap/HG00096.chr20_bamqc/qualimapReport.html))
13. Index mapped reads ([samtools index](http://www.htslib.org/))
14. Collect metrics ([`picard CollectRnaSeqMetrics`](https://gatk.broadinstitute.org/hc/en-us/articles/360037057492-CollectRnaSeqMetrics-Picard-) and ([`picard MarkDuplicates`](https://gatk.broadinstitute.org/hc/en-us/articles/360037052812-MarkDuplicates-Picard-))

#### Secondary Workflow

1. Calculating coverage.
2. Sorting and indexing the bam file and saving it to the Output directory.
3. Copying all the output files from their respective folders to the Output directory.
4. Generating an input file (tsv) for FusViz.
5. Running metafusion.

For this workflow, following programs need to be installed and their complete paths need to be added in the params section of the `$PWD/scripts/custom.config`  

- SV_standard perl script from https://github.com/senzhaocode/SV_standard
- MetaFusion = Pull the docker container from https://github.com/ccmbioinfo/MetaFusion/wiki/metafusion_sop
- bedtools = bedtools executable path
- samtools = samtools executable path


## Quick Start

#### For running both the workflows, run the script `run_nextflow.sh` as follows:
```
./run_nextflow.sh samp.dat script.log

   - samp.dat = List of samples
   - script.log = log file
```
This script contains nextflow commands for running both the workflows. 
The correct bedfile will be used based on the panel name present in the sample id.
```console
nextflow run nf-core/rnafusion --input samplesheet.csv --outdir <OUTDIR> --genome GRCh38 --all -profile docker
```

```console
nextflow -C $PWD/scripts/custom.config run $PWD$/scripts/custom_v2.nf -entry COVERAGE --input <samplesheet_bedmap>
```




---


## Documentation

The nf-core/rnafusion pipeline comes with documentation about the pipeline [usage](https://nf-co.re/rnafusion/usage), [parameters](https://nf-co.re/rnafusion/parameters) and [output](https://nf-co.re/rnafusion/output).

## Credits

nf-core/rnafusion was written by Martin Proks ([@matq007](https://github.com/matq007)), Maxime Garcia ([@maxulysse](https://github.com/maxulysse)) and Annick Renevey ([@rannick](https://github.com/rannick))

We thank the following people for their help in the development of this pipeline:

- [Phil Ewels](https://github.com/ewels)
- [Rickard Hammarén](https://github.com/Hammarn)
- [Alexander Peltzer](https://github.com/apeltzer)
- [Praveen Raj](https://github.com/praveenraj2018)

## Contributions and Support

If you would like to contribute to this pipeline, please see the [contributing guidelines](.github/CONTRIBUTING.md).

For further information or help, don't hesitate to get in touch on the [Slack `#rnafusion` channel](https://nfcore.slack.com/channels/rnafusion) (you can join with [this invite](https://nf-co.re/join/slack)).

## Citations

If you use nf-core/rnafusion for your analysis, please cite it using the following doi: [10.5281/zenodo.3946477](https://doi.org/10.5281/zenodo.3946477)

An extensive list of references for the tools used by the pipeline can be found in the [`CITATIONS.md`](CITATIONS.md) file.

You can cite the `nf-core` publication as follows:

> **The nf-core framework for community-curated bioinformatics pipelines.**
>
> Philip Ewels, Alexander Peltzer, Sven Fillinger, Harshil Patel, Johannes Alneberg, Andreas Wilm, Maxime Ulysse Garcia, Paolo Di Tommaso & Sven Nahnsen.
>
> _Nat Biotechnol._ 2020 Feb 13. doi: [10.1038/s41587-020-0439-x](https://dx.doi.org/10.1038/s41587-020-0439-x).
