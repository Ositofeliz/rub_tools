#!/bin/bash

# Stop scrip in case of error
set -e

# Checking arguments
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <input_vcf.gz> <output_vcf.gz>"
    exit 1
fi

# Variables
INPUT_VCF=$1                    # Input file name
OUTPUT_VCF=$2                   # Output file name
MAP_FILE="contig_mapping.txt"   # Map file for chromosome name conversion

# Step 1 : Extracting chromosome names for input VCF file
echo "Extracting chromosome names from $INPUT_VCF..."
CHROM_LIST=$(bcftools query -f '%CHROM\n' $INPUT_VCF | uniq)

# Step 2 : Generating map file
echo "Generating map file $MAP_FILE..."
> $MAP_FILE  # Initialize empty file

for CHROM in $CHROM_LIST; do
    if [[ $CHROM =~ ^NC_ ]]; then
        # Mapping chromosome names from NC_ to chrN
        if [[ $CHROM =~ ^NC_0*([0-9]+)\.[0-9]+$ ]]; then
            NUMBER=${BASH_REMATCH[1]}
            if ((NUMBER >= 1 && NUMBER <= 22)); then    # Convert autosomes (1 to 22)
                echo "$CHROM chr$NUMBER" >> $MAP_FILE
            elif ((NUMBER == 23)); then
                echo "$CHROM chrX" >> $MAP_FILE         # Special case: conversion for X (NC_000023.xxx)
            elif ((NUMBER == 24)); then
                echo "$CHROM chrY" >> $MAP_FILE         # Special case: conversion for Y (NC_000024.xxx)
            elif ((NUMBER > 24)); then
                echo "$CHROM chrM" >> $MAP_FILE         # Special case: conversion for mitochondrial "chromosome" (NC_0bunchofnumbers)
            fi
        fi
    fi
done

echo "Map file generated: $MAP_FILE"

# Étape 3 : Conversion des noms des chromosomes
echo "Converting chromosome names in $INPUT_VCF..."
bcftools annotate --rename-chrs $MAP_FILE $INPUT_VCF -Oz -o $OUTPUT_VCF
echo "VCF output file generated: $OUTPUT_VCF"

# Indexation du fichier de sortie
echo "Indexing output file $OUTPUT_VCF..."
bcftools index -t $OUTPUT_VCF

echo "Pipeline completed. Converted file available : $OUTPUT_VCF"
