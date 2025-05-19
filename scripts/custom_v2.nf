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

process fusviz_all_samples {
	publishDir "${PWD}/Final_Output/", mode: 'copy', pattern: 'sv_output'

	input:
		val all_samples 

	output:
		path "sv_output"

	script:
	"""
	mkdir -p sv_input

	sample_ids="${all_samples.join(' ')}"

	for sampleId in \$sample_ids; do
		mkdir -p sv_input/\$sampleId

		if [ -f ${PWD}/arriba/\${sampleId}.arriba.fusions.tsv ]; then
			cp ${PWD}/arriba/\$sampleId.arriba.fusions.tsv sv_input/\${sampleId}/Arriba.tsv
		fi

		if [ -f ${PWD}/fusioncatcher/\${sampleId}.fusioncatcher.fusion-genes.txt ]; then
			cp ${PWD}/fusioncatcher/\$sampleId.fusioncatcher.fusion-genes.txt sv_input/\${sampleId}/Fusioncatcher.txt
		fi

		if [ -f ${PWD}/starfusion/\${sampleId}.starfusion.fusion_predictions.tsv ]; then
			cp ${PWD}/starfusion/\$sampleId.starfusion.fusion_predictions.tsv sv_input/\${sampleId}/STAR-fusion.tsv
		fi
	done

	export PERL5LIB="\$PERL5LIB:/home/diagnostics/pipelines/nf-core/rnafusion/scripts/SV_standard/lib"

	perl ${params.sv_standard} --genome hg38 --type RNA --anno ${params.sv_anno} --input sv_input --output sv_output
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
	conda '/home/miniconda3/envs/new_base'
	errorStrategy 'ignore'
	publishDir "${PWD}/Final_Output/${sampleId}/", mode: 'copy', pattern: '*_metafuse_hg38.xlsx'
	input:
		tuple val(sampleId), file(cff_file)
	output:
		tuple val (sampleId), file ("*_metafuse_hg38.xlsx")
	script:
	"""
	if [ -s ${cff_file} ];then 
		mkdir ${sampleId}
		path=`realpath ${sampleId}`
		cp ${cff_file} ${sampleId}
		${params.metafus_gen} ${sampleId}/${cff_file} ${sampleId} > ${sampleId}/temp.sh
		# tool cutoff for docker 
		tool_cutoff=\$(grep -i 'num_tools' ${sampleId}/temp.sh | sed 's:[^0-9]::g')
		# No. of tools in the input cff file
		num_tools=\$(awk 'BEGIN{FS="\t"}{print \$11}' ${cff_file} | uniq | sort | wc -l)
		
		if [ \${num_tools} -ge \${tool_cutoff} ]; then
			docker run --entrypoint /bin/bash -v /home/diagnostics/pipelines/MetaFusion-Clinical:/Users/maposto/MetaFusion-Clinical -v \${path}:/Users/maposto/${sampleId} mapostolides/metafusion:readxl_writexl Users/maposto/${sampleId}/temp.sh
		fi	

		if [ -f ${sampleId}/final.n2.cluster.xlsx ];then
			# Filtering the output of metafuse 
			${params.filter_metafus} ${sampleId}/final.n2.cluster.xlsx ${sampleId}/${sampleId}_metafuse.xlsx

			# Adding it to the clinical fusions table in the historical_database			
			${params.metafus_append} ${sampleId}/${sampleId}_metafuse.xlsx > ${sampleId}/append_table.sh
			docker run --entrypoint /bin/bash -v /home/diagnostics/pipelines/MetaFusion-Clinical:/Users/maposto/MetaFusion-Clinical -v \${path}:/Users/maposto/${sampleId} mapostolides/metafusion:readxl_writexl Users/maposto/${sampleId}/append_table.sh

			# Converting the hg19 output to hg38
			${params.convert_metafus} hg19 hg38 ${sampleId}/${sampleId}_metafuse.xlsx ${sampleId}_metafuse_hg38.xlsx
		else
			${params.empty_excel} ${sampleId}_metafuse_hg38.xlsx
		fi		
	else
		${params.empty_excel} ${sampleId}_metafuse_hg38.xlsx
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
	fusviz_all_samples(file_copy.out.collect())
	cff_filegen(file_copy.out)
	metafusion(cff_filegen.out)
}
workflow.onComplete {
	log.info ( workflow.success ? "\n\nDone! Output in the 'Final_Output' directory \n" : "Oops .. something went wrong" )
}
