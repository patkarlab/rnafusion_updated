#!/usr/bin/env nextflow
nextflow.enable.dsl=2

params.str = 'Hello world!'

log.info """
STARTING PIPELINE
=*=*=*=*=*=*=*=*=

Sample list: ${params.input}
"""

process splitLetters {
  input:
  	tuple val(sampleId), path(reads) 
  output:
    path 'chunk_*'

  """
  printf '${params.str}' | split -b 6 - chunk_
  echo "This is sampleid" ${sampleId} "after sampleid"
  echo ${reads} "after the path"
  mkdir -p /home/diagnostics/pipelines/nf-core/rnafusion/scripts/${sampleId}
  """
}

process convertToUpper {
  input:
    file x
  output:
    stdout

  """
  cat $x | tr '[a-z]' '[A-Z]'
  """
}

workflow {
	Channel
		.fromPath(params.input)
		.splitCsv(header:false)
		//.flatten()
		//.map{ row -> "${row[0]},${row[1]}" }
		.view () { row -> "${row[0]},${row[1]}" }		
		.set { samples_ch } 

	splitLetters(samples_ch) | flatten | convertToUpper | view { it.trim() }
}
