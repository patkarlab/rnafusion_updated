#!/usr/bin/env nextflow
nextflow.enable.dsl=2
log.info """
STARTING PIPELINE
=*=*=*=*=*=*=*=*=

Sample list: ${params.input}
"""

process cff_filegen {
	conda '/home/miniconda3/envs/new_base'
	input:
		tuple val(sampleId), path(read1)
	output:
		tuple val (sampleId), file ("*.cff")	
	script:
	"""
	${params.cffgen} hg38 hg37 ${sampleId} ${PWD}/Final_Output/${sampleId}/${sampleId}.starfusion.fusion_predictions.tsv ${PWD}/Final_Output/${sampleId}/${sampleId}.fusioncatcher.fusion-genes.txt ${PWD}/Final_Output/${sampleId}/${sampleId}.squid.fusions.annotated.txt
	"""
}

process metafusion {
	publishDir "${PWD}/Final_Output/${sampleId}/", mode: 'copy', pattern: '*_metafuse.xlsx'
	input:
		tuple val(sampleId), file(cff_file)
	output:
		tuple val (sampleId), file ("*_metafuse.xlsx")
	script:
	"""
	if [ -s ${cff_file} ];then 
		mkdir ${sampleId}
		path=`realpath ${sampleId}`
		cp ${cff_file} ${sampleId}
		${params.metafus_gen} ${sampleId}/${cff_file} ${sampleId} > ${sampleId}/temp.sh
		docker run --entrypoint /bin/bash -v /home/diagnostics/pipelines/MetaFusion-Clinical:/Users/maposto/MetaFusion-Clinical -v \${path}:/Users/maposto/${sampleId} mapostolides/metafusion:readxl_writexl Users/maposto/${sampleId}/temp.sh

		if [ -f ${sampleId}/final.n2.cluster.xlsx ];then
			ln -s ${sampleId}/final.n2.cluster.xlsx ${sampleId}_metafuse.xlsx
			# Filter the .xlsx and add it to the clinical fusions table in the historical_database
			# For temp use the .xlsx file as it is
			${params.metafus_append} ${sampleId}/final.n2.cluster.xlsx > ${sampleId}/append_table.sh
			docker run --entrypoint /bin/bash -v /home/diagnostics/pipelines/MetaFusion-Clinical:/Users/maposto/MetaFusion-Clinical -v \${path}:/Users/maposto/${sampleId} mapostolides/metafusion:readxl_writexl Users/maposto/${sampleId}/append_table.sh
		else
			touch ${sampleId}_metafuse.xlsx
		fi		
	else
		touch ${sampleId}_metafuse.xlsx
	fi
	"""
}

workflow COVERAGE {
	Channel
		.fromPath(params.input)
		.splitCsv(header:false)
		.set { samples_ch }

	main:
	cff_filegen(samples_ch) 
	metafusion(cff_filegen.out) 
}
