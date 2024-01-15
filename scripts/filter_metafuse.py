#!/usr/bin/env python
# This script will filter the output of metafuse
import sys
import os
import pandas as pd
import openpyxl

metafuse_input = sys.argv[1]
metafuse_output = sys.argv[2]

xl_file = pd.read_excel(metafuse_input, sheet_name=None)
with pd.ExcelWriter(metafuse_output) as writer:
	for sheet_names in xl_file.keys():
		df = pd.read_excel(metafuse_input, sheet_name=sheet_names)
		df.fillna(value= -1 , inplace=True)
		if 'max_split_cnt' in df:
			df = df[df.max_split_cnt > 5]	# Filtering out fusions with <= 5 junction spanning reads
		df.to_excel(writer, sheet_name=sheet_names, index=False)	
