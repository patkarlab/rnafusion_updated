#!/usr/bin/env nextflow
nextflow.enable.dsl=2

log.info """
STARTING PIPELINE
=*=*=*=*=*=*=*=*=

Sample list: ${params.input}
"""

process coverage {
	input:
		tuple val(sampleId), path(read1)
	output:
		tuple val (sampleId), file ("${sampleId}.bed")
	script:
	"""
	#${params.bedtools} bamtobed -i $PWD/fusioninspector/${sampleId}.consolidated.bam > ${sampleId}.bed
	#${params.bedtools} bamtobed -i $PWD/star_for_arriba/${sampleId}.Aligned.out.bam | awk 'BEGIN{OFS="\t"}{ \$1="chr"\$1; print }' > ${sampleId}.bed
	#${params.bedtools} bamtobed -i $PWD/picard/${sampleId}.bam | awk 'BEGIN{OFS="\t"}{ \$1="chr"\$1; print }' > ${sampleId}.bed
	${params.bedtools} bamtobed -i $PWD/star_for_squid/${sampleId}.Aligned.sortedByCoord.out.bam | awk 'BEGIN{OFS="\t"}{ \$1="chr"\$1; print }' > ${sampleId}.bed
	#${params.bedtools} bamtobed -i $PWD/star_for_starfusion/${sampleId}.Aligned.sortedByCoord.out.bam | awk 'BEGIN{OFS="\t"}{ \$1="chr"\$1; print }' > ${sampleId}.bed
	#${params.bedtools} bamtobed -i $PWD/samtools/${sampleId}_chimeric.bam | awk 'BEGIN{OFS="\t"}{ \$1="chr"\$1; print }' > ${sampleId}.bed
	${params.bedtools} coverage -counts -a ${read1} -b ${sampleId}.bed > $PWD/Final_Output/${sampleId}/${sampleId}.counts_squid.bed
	"""
}

process bam {
	input:
		tuple val(sampleId), path(read1)
	output:
		tuple val (sampleId), file ("*")
	script:
	"""
	${params.samtools} sort $PWD/star_for_squid/${sampleId}.Aligned.sortedByCoord.out.bam -o ${sampleId}.sorted.bam
	${params.samtools} index ${sampleId}.sorted.bam
	cp ${sampleId}.sorted.bam* $PWD/Final_Output/${sampleId}/
	"""
}

process file_copy {
	input:
		tuple val(sampleId), file(sampleId_bed)
	output:
		val (sampleId)
	script:
	"""
	if [ -f ${PWD}/arriba/${sampleId}.arriba.fusions.tsv ]; then
		cp ${PWD}/arriba/${sampleId}.arriba.fusions.tsv ${PWD}/Final_Output/${sampleId}/
	fi

	if [ -f ${PWD}/arriba_visualisation/${sampleId}.pdf ]; then
		cp ${PWD}/arriba_visualisation/${sampleId}.pdf ${PWD}/Final_Output/${sampleId}/
	fi

	if [ -f ${PWD}/squid/${sampleId}.squid.fusions.annotated.txt ]; then
		cp ${PWD}/squid/${sampleId}.squid.fusions.annotated.txt ${PWD}/Final_Output/${sampleId}/
	fi

	if [ -f ${PWD}/pizzly/${sampleId}.pizzly.txt ]; then
		cp ${PWD}/pizzly/${sampleId}.pizzly.txt ${PWD}/Final_Output/${sampleId}/
	fi

	if [ -f ${PWD}/fusioncatcher/${sampleId}.fusioncatcher.fusion-genes.txt ]; then
		cp ${PWD}/fusioncatcher/${sampleId}.fusioncatcher.fusion-genes.txt ${PWD}/Final_Output/${sampleId}/
	fi

	if [ -f ${PWD}/fusioncatcher/${sampleId}.fusioncatcher.summary.txt ]; then
		${params.sed_sh} ${PWD}/fusioncatcher/${sampleId}.fusioncatcher.summary.txt
		cp ${PWD}/fusioncatcher/${sampleId}.fusioncatcher.summary.txt ${PWD}/Final_Output/${sampleId}/
	fi

	if [ -f ${PWD}/starfusion/${sampleId}.starfusion.fusion_predictions.tsv ]; then
		cp ${PWD}/starfusion/${sampleId}.starfusion.fusion_predictions.tsv ${PWD}/Final_Output/${sampleId}/
	fi

	if [ -d ${PWD}/fusionreport/${sampleId} ]; then
		cp -r ${PWD}/fusionreport/${sampleId} ${PWD}/Final_Output/${sampleId}/${sampleId}_fusionreport
	fi

	if [ -f ${PWD}/fusioninspector/${sampleId}.fusion_inspector_web.html ]; then 
		cp -r ${PWD}/fusioninspector/${sampleId}.fusion_inspector_web.html ${PWD}/Final_Output/${sampleId}/
	fi

	python3 ${params.merge_csvs_script} ${sampleId} ${PWD}/Final_Output/${sampleId}/${sampleId}.xlsx ${PWD}/Final_Output/${sampleId}/${sampleId}.counts_squid.bed ${PWD}/Final_Output/${sampleId}/${sampleId}.arriba.fusions.tsv ${PWD}/Final_Output/${sampleId}/${sampleId}.squid.fusions.annotated.txt ${PWD}/Final_Output/${sampleId}/${sampleId}.pizzly.txt ${PWD}/Final_Output/${sampleId}/${sampleId}.fusioncatcher.fusion-genes.txt ${PWD}/Final_Output/${sampleId}/${sampleId}.fusioncatcher.summary.txt ${PWD}/Final_Output/${sampleId}/${sampleId}.starfusion.fusion_predictions.tsv
	"""
}

process cff_filegen {
	conda '/home/miniconda3/envs/new_base'
	input:
		val(sampleId)
	output:
		tuple val (sampleId), file ("*.cff")	
	script:
	"""
	${params.cffgen} hg38 hg37 ${sampleId} ${PWD}/Final_Output/${sampleId}/${sampleId}.starfusion.fusion_predictions.tsv ${PWD}/Final_Output/${sampleId}/${sampleId}.fusioncatcher.fusion-genes.txt ${PWD}/Final_Output/${sampleId}/${sampleId}.squid.fusions.annotated.txt ${PWD}/Final_Output/${sampleId}/${sampleId}.arriba.fusions.tsv
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
			${params.empty_excel} ${sampleId}_metafuse.xlsx
		fi		
	else
		${params.empty_excel} ${sampleId}_metafuse.xlsx
	fi
	"""
}

workflow COVERAGE {
	Channel
		.fromPath(params.input)
		.splitCsv(header:false)
		.set { samples_ch }
	main:
	coverage(samples_ch)
	bam(samples_ch)
	file_copy(coverage.out)
	cff_filegen(file_copy.out)
	metafusion(cff_filegen.out)
}
