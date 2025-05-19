import pandas as pd
import os, sys
import re

args = sys.argv
sample = args[1]
outfile = args[2]
coverage = args[3]
arriba = args[4]
squid = args[5]
pizzly = args[6]
fusioncatcher_fusion_genes = args[7]
fusioncatcher_summary = args[8]
starfusion = args[9]

csvfilenames=[ coverage, arriba, squid, pizzly, fusioncatcher_fusion_genes, fusioncatcher_summary, starfusion]
writer = pd.ExcelWriter(outfile)
for csvfilename in csvfilenames:
	if (os.path.exists(csvfilename)) and (os.path.getsize(csvfilename) != 0):
		sheetname=os.path.split(csvfilename)[1]
		df = pd.read_csv(csvfilename, sep = '\t')
		print('process file:', csvfilename, 'shape:', df.shape)
		new_sheet_name = os.path.splitext(sheetname)[0]
		new_sheet_name = re.sub (sample,"", new_sheet_name, flags = re.IGNORECASE)
		df.to_excel(writer,sheet_name=new_sheet_name, index=False)
writer.close()
