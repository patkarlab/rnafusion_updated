#!/usr/bin/bash
# This script will generate a script to be run for metafuse

cff_file=$1
output_dir=$2
echo -e "#!/bin/bash\n"
echo "#DATABASE"
echo -e "database=/Users/maposto/MetaFusion-Clinical/MWE/historical_database.db\n"
echo "fusiontools=/Users/maposto/MetaFusion-Clinical/scripts"
echo "#REFERENCE FILES FILES"
echo "mkdir \$runs_dir"

echo "ref_dir=/Users/maposto/MetaFusion-Clinical/reference_files"
echo "gene_bed=\$ref_dir/new_bed.total.Oct-1-2020.uniq.bed"
echo "gene_info=\$ref_dir/Homo_sapiens.gene_info"
echo "genome_fasta=\$ref_dir/human_g1k_v37_decoy.fasta"
echo -e "recurrent_bedpe=\$ref_dir/blocklist_breakpoints.bedpe\n"

echo "outdir=/Users/maposto/${output_dir}"
echo "echo generating output in \$outdir"
echo "mkdir \$outdir"
echo -e "cff=/Users/maposto/${cff_file}\n"

echo "bash \${fusiontools}/MetaFusion.clinical.sh --outdir \$outdir \\"
echo "                 --cff \$cff  \\"
echo "                 --gene_bed \$gene_bed \\"
echo "                 --annotate_exons \\"
echo "                 --fusion_annotator \\"
echo "                 --genome_fasta \$genome_fasta \\"
echo "                 --gene_info \$gene_info \\"
echo "                 --num_tools=2  \\"
echo "                 --per_sample \\"
echo "                 --recurrent_bedpe \$recurrent_bedpe \\"
echo "                 --scripts \$fusiontools \\"
echo "                 --database \$database \\"
#echo "                 --update_hist \\"
echo "                 --ref_dir \$ref_dir"
