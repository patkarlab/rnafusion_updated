#!/usr/bin/env python3
import sys
import os
import argparse
import numpy as np
import matplotlib.pyplot as plt
import matplotlib.colors as mcolors


def parse_arguments():
	parser = argparse.ArgumentParser(description="Generate log10-scaled exon coverage heatmap from BED-like files.")
	parser.add_argument('--output', required=True, help='Name of the output heatmap file (e.g. coverage_heatmap.pdf)')
	parser.add_argument('--samples', nargs='*', required=True, help='List of BED-like files to include in the heatmap')
	return parser.parse_args()

def parse_bed(filename):
	with open(filename) as f:
		for line in f:
			fields = line.strip().split()
			if len(fields) < 6:
				continue
			exon = fields[3]
			coverage = float(fields[5])
			yield exon, coverage

def main():
	args = parse_arguments()
	output_file = args.output
	input_files = args.samples

	if not output_file.endswith(".pdf"):
		output_file += ".pdf"

	# Collect and verify exon names across files
	ref_exons = None
	for bedfile in input_files:
		exons = [exon for exon, _ in parse_bed(bedfile)]
		if ref_exons is None:
			ref_exons = exons
		else:
			if len(exons) != len(ref_exons):
				print(f"❌ ERROR: File {bedfile} has a different exon list or order.")
				sys.exit(1)
	all_exons = ref_exons

	# Prepare matrix
	n_exons = len(all_exons)
	n_samples = len(input_files)
	exon_index = {exon: i for i, exon in enumerate(all_exons)}
	matrix = np.zeros((n_exons, n_samples), dtype=float)

	# Fill matrix with coverage values
	sample_names = []
	for j, bedfile in enumerate(input_files):
		filename = os.path.basename(bedfile)
		sample_name = filename.split('.')[0]
		sample_names.append(sample_name)
		for exon, cov in parse_bed(bedfile):
			i = exon_index[exon]
			matrix[i, j] = cov
	
	print(sample_names)

	# log10 scale (cap to 10^6)
	matrix = np.clip(matrix, 1, 1e4)
	log_matrix = np.log10(matrix)

	# Plot
	fig, ax = plt.subplots(figsize=(max(6, n_samples), max(8, n_exons / 8)))
	cmap = mcolors.LinearSegmentedColormap.from_list(
		"WYOR", ["white", "yellow", "orange", "red"]
	)
	im = ax.imshow(log_matrix, aspect='auto', cmap=cmap, vmin=0, vmax=4)

	# Axis labels
	ax.set_xticks(np.arange(n_samples))
	ax.set_xticklabels(sample_names, rotation=90, fontsize=8)
	ax.set_yticks(np.arange(n_exons))
	ax.set_yticklabels(all_exons, fontsize=8)
	ax.set_xlabel("Samples", fontsize=10)
	ax.set_ylabel("Exons", fontsize=10)
	ax.set_title("Log10 Coverage Heatmap", fontsize=12)

	# Colorbar
	cbar = plt.colorbar(im, ax=ax)
	cbar.set_label("log₁₀(Coverage)")

	plt.tight_layout()
	plt.savefig(output_file, dpi=300)
	plt.close()

	print(f"✅ Heatmap saved to {output_file}")
	print(f"Exons: {n_exons} | Samples: {n_samples}")


if __name__ == "__main__":
	main()
