#! /usr/bin/env python
# This script will convert the metafuse output from hg38 to hg19
import sys
import os
import pandas as pd
import openpyxl
import re
from pyliftover import LiftOver

input_build = sys.argv[1]	# assembly version of the input files
output_build = sys.argv[2]	# assembly version of the output
metafuse_input = sys.argv[3]	# input excel file
metafuse_output = sys.argv[4]	# output excel file

# substituting 37 for 19
input_build = re.sub (r'37', "19", input_build, flags = re.IGNORECASE)
output_build = re.sub (r'37', "19", output_build, flags = re.IGNORECASE)
# substituting grch for hg
inbuild = re.sub ("grch","hg", input_build.lower(), flags = re.IGNORECASE)
outbuild = re.sub ("grch", "hg", output_build.lower(), flags = re.IGNORECASE)
print ("converting from "+ inbuild + " to " + outbuild)
lo = LiftOver(inbuild, outbuild)

default_output = ["chrgl", "NA", "NA", "NA"]
def liftover_funtion_ucsc (chromosome, position):
	chrom = str(chromosome)
	pos = int (position)
	#print (chrom, pos)
	output = lo.convert_coordinate(chrom, pos)
	if not output:
		output.append(default_output)
	return output

xl_file = pd.read_excel(metafuse_input, sheet_name=None)
with pd.ExcelWriter(metafuse_output) as writer:
	for sheet_names in xl_file.keys():
		df = pd.read_excel(metafuse_input, sheet_name=sheet_names)
		#for index, row in df.iterrows():
		#	print (index, row['chr1'], row['breakpoint_1'], row['chr2'], row['breakpoint_2'])
		for row in df.index:
			left_chr = df['chr1'][row]
			left_pos = df['breakpoint_1'][row]
			left_convert = liftover_funtion_ucsc(left_chr, left_pos)

			right_chr = df['chr2'][row]
			right_pos = df['breakpoint_2'][row]
			right_convert = liftover_funtion_ucsc(right_chr, right_pos)

			df.at[row, 'chr1'] = left_convert[0][0]
			df.at[row, 'breakpoint_1']= left_convert[0][1]
			df.at[row, 'chr2'] = right_convert[0][0]
			df.at[row, 'breakpoint_2'] = right_convert[0][1]

		df.rename(columns = {'exon1':'exon1_hg19', 'exon2':'exon2_hg19'}, inplace = True)
		df.to_excel(writer, sheet_name=sheet_names, index=False)	
