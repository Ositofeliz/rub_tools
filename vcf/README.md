# Manipulating VCF files

VCF files are one of the most anoying data file format in bioinformatics, for their specifications are quite unclear on some points.
You can find it here: https://samtools.github.io/hts-specs/VCFv4.4.pdf

Fortunately, samtools offer a wonderfull set of tools to manipulate efficiently VCF files, but one can be a bit lost when it comes to find the right tool for want they want.

I might one day create folders for each case instead of having all of them here. But for now, I only have one script so...

## Content

1. VCF Chromosome Names Conversion


### 1. VCF Chromosome Names Conversion

`vcf_cnc.sh` 

This bash script takes a VCF file with the RefSeq chromosomes names, and creates a new vcf file with the commonly used chrN names. 

For example : NC_000001.11 corresponds to chromosome 1. It will be renamed chr1 in the output file

#### Dependencies

`samtools`

#### Command line

```sh
./vcf_cnc.sh INPUT_FILE_NAME.vcf.gz OUTPUT_FILE_NAME.vcf.gz

```
#### Why ?

You might have to compare to VCF files.
However, there is a great chance that the chromosome names are not the same between your two VCF files.

In my case, I had a VCF file from `GATK HaplotypeCaller`, that uses the reference genome GRCh38p14 with RefSeq names (NC_) that I needed to compare to a VCF file from HG002 of the Genome In a Bottle project (GIAB), where chromosome names are "chrN"

To compare them, I needed to use `bcftools intersect`, that requires both file to have the same chromosome names.

`bcftools` offers a way to rename chromosomes with a map file that makes the correspondance between the names of the two files.

However, it takes more than one step to do this, so I made a script to do this, because I'm lazy.

#### How ?

##### Step 1: Extract the chromosome names from the VCF RefSeq file

Your file might not contains all the chromosomes, the header might contains more than what is needed, so going through the CHROM columns of the VCF file to extract the chromosome names is a good way to make sure you'll have what you need.

```sh
bctools query -f '%CHROM\n' FILENAME.vcf.gz | uniq 
```

This command line will get all the chromosome names from the CHROM colums and will only display unique names found.

##### Step 2: Generating map file

This step converts the RefSeq names into a chrN and makes the map file of the corresponding names.

A regex detects the RefSeq name to convert it, with special cases for chromosomes X, Y and Mitochondrial genome (M).

It allows the program to be usable on future releases of GRCh38 (eg. NC_00001.11 becomes NC_00001.12).

##### Step 3: Generating a new VCF file with modified names

This step creates a new VCF file with the modified chromosome names. Chromosomes that are not in the map file will not be handled.
It uses `bcftools anotate --rename-chrs` to change the chromosome names.

##### Bonus step: Indexing the new VCF file

Because you'll need it.