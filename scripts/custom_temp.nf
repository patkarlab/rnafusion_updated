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

	script:
	"""
	#${params.bedtools} bamtobed -i $PWD/star_for_arriba/${sampleId}.Aligned.out.bam | awk 'BEGIN{OFS="\t"}{ \$1="chr"\$1; print }' > ${sampleId}.bed
	${params.bedtools} bamtobed -i $PWD/picard/${sampleId}.bam | awk 'BEGIN{OFS="\t"}{ \$1="chr"\$1; print }' > ${sampleId}.bed
	${params.bedtools} coverage -counts -a ${read1} -b ${sampleId}.bed > $PWD/Final_Output/${sampleId}/${sampleId}.counts.bed
	"""
}


workflow COVERAGE {
	Channel
		.fromPath(params.input)
		.splitCsv(header:false)
		.view () { row -> "${row[0]},${row[1]}" }
		.set { samples_ch }

	main:
	coverage(samples_ch)
}
