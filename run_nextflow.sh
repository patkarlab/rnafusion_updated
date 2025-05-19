#! /usr/bin/bash 
# This script will initiate the nf-core/rnafusion pipeline. The input is samplesheet.csv

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

#nextflow run ./ --all --input samplesheet.csv --outdir /home/diagnostics/pipelines/nf-core/rnafusion --genome GRCh38 -profile docker -resume -with-report report-config.html > ${log_file}
#nextflow run ./ --all --input samplesheet.csv --outdir /home/diagnostics/pipelines/nf-core/rnafusion --genome GRCh38 -profile docker > ${log_file}

> ${samplesheet}_bedmap
for i in `cat ${samplesheet}`
do
	bed=$( echo ${i} | awk 'BEGIN{FS="-";OFS=""}{ $1="" ; print tolower($2)}' )
	case $bed in
		"ball" | "kmt2a" | "ball_tall" | "etv6runx1nv2" | "tcf3pbx1nv2" | "kmt2aaff1nv2" | "pax5etv6" | "etv6abl1" | "pax5eln" | "dux4igh" | "ebf1pdgfrb" | "ighdux4" | "tcf3pbx1" | "p190" | "etv6runx1" | "p210" | "etv6runx1i" | "kmt2aaff1" | "mef2dbcl9" | "inv2" | "inv1" | "lsc" | "fusionvallsc" | "csfir" | "mef2d" | "lyfu" | "etv6" | "runx1" | "abl1" | "dux4" | "fgfr1" | "jak2" | "pax5" | "tcf3" | "crlf2" | "pdgfrb" | "abl" | "igh" | "znf384" | "epor")
		bedfile="/home/diagnostics/pipelines/nf-core/rnafusion/bedfiles/BALLlymphoid_fusion02062022_hg38.bed"
		;;
		"tall")
		bedfile="/home/diagnostics/pipelines/nf-core/rnafusion/bedfiles/T-ALL02062022_hg38.bed"
		;;
		"myfu" | "eofu" | "kmt2amllt3" | "crebbp" | "myh11" | "mecom" | "1" | "2" | "3" | "4" | "nup98" | "alk" | "alk1" | "picam" | "mllt10" | "pdgfra" | "pdgra" | "picalm" | "nup214" | "aml" | "cbfb" | "cbfa2t3")
		bedfile="/home/diagnostics/pipelines/nf-core/rnafusion/bedfiles/myeloid_fusion02062022_hg38.bed"
		;;
		"abg" | "rar" | "f" | "f1" | "f3")
		bedfile="/home/diagnostics/pipelines/nf-core/rnafusion/bedfiles/research_new_RARA_hg38.bed"
		;;
		"rarb" | "rarbg")
		bedfile="/home/diagnostics/pipelines/nf-core/rnafusion/bedfiles/RAR_BG_final_hg38.bed"
		;;
		"rara")
		bedfile="/home/diagnostics/pipelines/nf-core/rnafusion/bedfiles/RARA_hg38.bed"
		;;
		"r" | "rna" | "lp1")
		bedfile="/home/diagnostics/pipelines/nf-core/rnafusion/bedfiles/TALL_RNA_hg38_ensembl.bed"
		;;
		"p190" | "p210" | "cdna" | "normal")
		bedfile="/home/diagnostics/pipelines/nf-core/rnafusion/bedfiles/RADICAL_hg38.bed"
		;;
		"rarabg")
		bedfile="/home/diagnostics/pipelines/nf-core/rnafusion/bedfiles/RAR_ABG_hg38.bed"
		;;
		#"newalp" | "newalp_rna" | "rna")
		#bedfile="/home/diagnostics/pipelines/nf-core/rnafusion/bedfiles/Leukemia_Panel_Myeloid_2023_Feb_hg38_sortd.bed"
		#;;
		*)
		echo "could not map the panel name to a directory, ${i} ${bed}"
		exit 1
	esac
echo "${i},${bedfile}" >> ${samplesheet}_bedmap
done

#nextflow -C /home/diagnostics/pipelines/nf-core/rnafusion/scripts/custom.config run /home/diagnostics/pipelines/nf-core/rnafusion/scripts/custom_v2.nf -entry COVERAGE -resume --input ${samplesheet}_bedmap > ${log_file}.coverage

nextflow -C /home/diagnostics/pipelines/nf-core/rnafusion/scripts/custom.config run /home/diagnostics/pipelines/nf-core/rnafusion/scripts/custom_v2.nf -entry COVERAGE --input ${samplesheet}_bedmap > ${log_file}.coverage

#for samples in `cat ${samplesheet}`
#do
#	cp arriba/${samples}.arriba.fusions.tsv arriba_visualisation/${samples}.pdf Final_Output/${samples}
#	cp squid/${samples}.squid.*.txt Final_Output/${samples}
#	cp pizzly/${samples}.pizzly.txt Final_Output/${samples}
#	cp fusioncatcher/${samples}.fusioncatcher.fusion-genes.txt fusioncatcher/${samples}.fusioncatcher.summary.txt Final_Output/${samples}
#	cp starfusion/${samples}.starfusion.fusion_predictions.tsv Final_Output/${samples}
#	cp -r fusionreport/${samples} Final_Output/${samples}/${samples}_fusionreport
#	cp -r fusioninspector/${samples}.fusion_inspector_web.html Final_Output/${samples}/
#done
