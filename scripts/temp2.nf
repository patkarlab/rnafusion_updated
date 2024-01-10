#!/usr/bin/env nextflow
nextflow.enable.dsl=2

params.index = "/home/diagnostics/pipelines/nf-core/rnafusion/scripts/index.csv"

process foo {
    //debug true
    input:
    tuple val(sampleId), file(read1), file(read2)

    script:
    """
    echo your_command --sample $sampleId --reads $read1 $read2
    """
}

workflow {
    Channel.fromPath(params.index) \
        | splitCsv(header:true) \
        | map { row-> tuple(row.sampleId, file(row.read1), file(row.read2)) } \
        | foo
}
