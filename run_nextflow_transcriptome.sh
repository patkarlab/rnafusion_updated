#! /usr/bin/bash 
# This script will initiate the nf-core/rnafusion pipeline for whole transcriptome. The input is samplesheet.csv

samplesheet=$1
log_file=$2
sequences="/home/diagnostics/pipelines/nf-core/rnafusion/samples"

echo "sample,fastq_1,fastq_2,strandedness" > samplesheet.csv
for samples in `cat ${samplesheet}`
do 
	mkdir -p Final_Output/${samples}
	R1=$(ls $sequences/${samples}_S* | grep -i '_R1_')
	R2=$(ls $sequences/${samples}_S* | grep -i '_R2_')
	echo "$samples,$R1,$R2,forward" >> samplesheet.csv	
done 

nextflow run ./ --all --input samplesheet.csv --outdir /home/diagnostics/pipelines/nf-core/rnafusion --genome GRCh38 -profile docker -resume -with-report report-config.html > ${log_file}

> ${samplesheet}_bedmap
for i in `cat ${samplesheet}`
do
	echo "${i},${PWD}" >> ${samplesheet}_bedmap
done

#nextflow -C /home/diagnostics/pipelines/nf-core/rnafusion/scripts/custom.config run /home/diagnostics/pipelines/nf-core/rnafusion/scripts/transriptome.nf -entry COVERAGE -resume --input ${samplesheet}_bedmap > ${log_file}.coverage
