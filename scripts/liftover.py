#!/usr/bin/env python3
# This script will convert the coordinates between different assemblies 
import os, sys, re, csv
from pyliftover import LiftOver

input_build = sys.argv[1]			# assembly version of the input files
output_build = sys.argv[2]			# assembly version of the output
sample_name = sys.argv[3]			# Sample name
star_fusion_outfile = sys.argv[4]	# output file from star fusion
FusionCatcher = sys.argv[5]			# output file from FusionCatcher
squid = sys.argv[6] 				# output file from squid
pizzly = sys.argv[7]				# output file from pizzly
arriba = sys.argv[8]				# output file from arriba

output_file = open(sample_name + '.cff','w')
# substituting 37 for 19
input_build = re.sub (r'37', "19", input_build, flags = re.IGNORECASE)		
output_build = re.sub (r'37', "19", output_build, flags = re.IGNORECASE)	
# substituting grch for hg
inbuild = re.sub ("grch","hg", input_build.lower(), flags = re.IGNORECASE)
outbuild = re.sub ("grch", "hg", output_build.lower(), flags = re.IGNORECASE)
print ("converting from "+ inbuild + " to " + outbuild)
lo = LiftOver(inbuild, outbuild)

#def liftover_function_ensembl(chromosome, position):
def liftover_funtion_ucsc (chromosome, position):
	chrom = str(chromosome)
	pos = int (position)
	#print (chrom, pos)
	output = lo.convert_coordinate(chrom, pos)
	return output

if os.path.getsize(star_fusion_outfile) != 0:
	with open (star_fusion_outfile,'r') as sftsv:		
		sftsv_handle = csv.reader(sftsv, delimiter = '\t')
		header = next (sftsv_handle)
		for sftsv_values in sftsv_handle:
			fusion_name = sftsv_values[0]
			junction_read_count = sftsv_values[1]	# Junction-crossing reads
			spanning_frag_count = sftsv_values[2]	# Reads spanning the junction 
			
			leftgene = sftsv_values[6]
			LeftBreakpoint = sftsv_values[7]
			left_chr = 'chr' + ''.join( LeftBreakpoint.split(':')[0] )
			left_pos = LeftBreakpoint.split(':')[1]
			convert = liftover_funtion_ucsc(left_chr, left_pos)
			left_chr_convert = convert[0][0]
			left_chr_convert = re.sub ("chr","", left_chr_convert, flags = re.IGNORECASE)
			left_pos_convert = convert[0][1]

			rightgene = sftsv_values[8]
			RightBreakpoint = sftsv_values[9]
			right_chr = 'chr' + ''.join( RightBreakpoint.split(':')[0] )
			right_pos = RightBreakpoint.split(':')[1]
			convert_right = liftover_funtion_ucsc(right_chr, right_pos)
			right_chr_convert = convert_right[0][0]
			right_chr_convert = re.sub ("chr","", right_chr_convert, flags = re.IGNORECASE)
			right_pos_convert = convert_right[0][1]	

			if ('gl' not in left_chr_convert) and ('gl' not in right_chr_convert):	# Removing regions which were not mapped in hg19
				#print (leftgene, left_chr_convert, left_pos_convert, rightgene, RightBreakpoint, right_chr_convert, right_pos_convert)
				print ( left_chr_convert, left_pos_convert, "NA", right_chr_convert, right_pos_convert, "NA", "NA",sample_name, "Tumor", "Leukemia", "star_fusion", junction_read_count, spanning_frag_count, fusion_name.split('--')[0], "NA",fusion_name.split('--')[1], "NA", file=output_file, sep="\t")						
else:
	print ("star fusion output was empty")

if os.path.getsize(FusionCatcher) != 0:
	with open (FusionCatcher, 'r') as fctsv:	
		fctsv_handle = csv.reader(fctsv, delimiter = "\t")
		header = next (fctsv_handle)
		for fctsv_values in fctsv_handle:
			left_gene = fctsv_values[0]
			right_gene = fctsv_values[1]
			split_cnt = fctsv_values[5]	# Junction-crossing reads
			span_cnt = -1

			left_fusion_point = fctsv_values[8]
			left_chr = 'chr' + ''.join(left_fusion_point.split(':')[0])
			left_pos = 	left_fusion_point.split(':')[1]
			left_convert = liftover_funtion_ucsc(left_chr, left_pos)
			left_chr_convert = left_convert[0][0]
			left_chr_convert = re.sub ("chr","", left_chr_convert, flags = re.IGNORECASE)
			left_pos_convert = left_convert[0][1]

			right_fusion_point = fctsv_values[9]
			right_chr = 'chr' + ''.join(right_fusion_point.split(':')[0])
			right_pos = right_fusion_point.split(':')[1]
			right_convert = liftover_funtion_ucsc(right_chr, right_pos)
			right_chr_convert = right_convert[0][0]
			right_chr_convert = re.sub ("chr","", right_chr_convert, flags = re.IGNORECASE)
			right_pos_convert = right_convert[0][1]

			#print (left_chr_convert, left_pos_convert, "NA", right_chr_convert, right_pos_convert, "NA", "NA",sample_name, "Tumor", "Leukemia", "fusion_catcher", split_cnt, span_cnt, left_gene, "NA", right_gene, "NA", sep="\t")
			if ('gl' not in left_chr_convert) and ('gl' not in right_chr_convert):	# Removing regions which were not mapped in hg19
				print (left_chr_convert, left_pos_convert, "NA", right_chr_convert, right_pos_convert, "NA", "NA",sample_name, "Tumor", "Leukemia", "fusion_catcher", split_cnt, span_cnt, left_gene, "NA", right_gene, "NA", file=output_file, sep="\t")
				#print (left_chr_convert, right_chr_convert)
else:
	print ("Fusion Catcher output was empty")

if os.path.getsize(squid) != 0:
	with open (squid, 'r') as stsv:
		stsv_handle = csv.reader(stsv, delimiter = "\t")
		header = next (stsv_handle)
		for stsv_values in stsv_handle:
			if "non-fusion-gene" not in stsv_values[10]:
				left_gene = stsv_values[11].split(':')[0]
				right_gene = stsv_values[11].split(':')[1]

				left_chr = 'chr' + ''.join(stsv_values[0])
				left_pos = stsv_values[1]
				left_convert = liftover_funtion_ucsc(left_chr, left_pos)
				left_chr_convert = left_convert[0][0]
				left_chr_convert = re.sub ("chr","", left_chr_convert, flags = re.IGNORECASE)
				left_pos_convert = left_convert[0][1]
				split_cnt = stsv_values[7]
				span_cnt = -1
	
				right_chr = 'chr' + ''.join(stsv_values[3])
				right_pos = stsv_values[4]
				right_convert = liftover_funtion_ucsc(right_chr, right_pos)
				right_chr_convert = right_convert[0][0]
				right_chr_convert = re.sub ("chr","", right_chr_convert, flags = re.IGNORECASE)
				right_pos_convert = right_convert[0][1]
	
				if ('gl' not in left_chr_convert) and ('gl' not in right_chr_convert):  # Removing regions which were not mapped in hg19
					print ( left_chr_convert, left_pos_convert, "NA", right_chr_convert, right_chr_convert, "NA", "NA",sample_name, "Tumor", "Leukemia", "squid", split_cnt, span_cnt, left_gene, "NA", right_gene, "NA", file=output_file, sep="\t")
else:
	print ("Squid output was empty")

if os.path.getsize(pizzly) != 0:
	with open (pizzly,'r') as ptsv:
		ptsv_handle = csv.reader(ptsv, delimiter = '\t')
		header = next(ptsv_handle)
		for plines in ptsv_handle:
			

else:
	print ("pizzly output was empty")

output_file.close()