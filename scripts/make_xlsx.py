#!/usr/bin/env python3
import openpyxl
import sys

infile = sys.argv[1]
wb = openpyxl.Workbook()
wb.save(infile)
