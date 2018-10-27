#!/bin/sh
filePath="/projects/micb405/resources/project_1/"

#make a project1 folder
mkdir ~/project1/

#go to project1
cd ~/project1/

#copy over the reference file
echo "copying over reference genome"
scp "${filePath}ref_genome.fasta" .

#index the reference
echo "indexing reference genome"
bwa index ref_genome.fasta

filteredDir="filtered_vcf"

for filepart in $(ls ${filePath} -1 | sed -n -e 's/^\(.*\)\([0-1].fastq.gz\)/\1/p'); do
	echo "---------------Processing library: $filepart--------------- "

	read1File="${filePath}${filepart}1.fastq.gz"
	read2File="${filePath}${filepart}2.fastq.gz"
	echo "$read1File $read2File"

    #look up at quality of FASTQ file using fastqc
    fastqc --threads 2 -o . "$read1File"
    fastqc --threads 2 -o . "$read2File"

	#map each read to the reference genome and convert to a bam file
	echo "aligning the sequence to reference and produce bam file"
	bwa mem ref_genome.fasta "$read1File" "$read2File" 2> "${filepart}.txt" | samtools view -b > "${filepart}aligned.bam"

    #echo "Performing flagstat on ${alignedBam}"
    echo "Performing flagstat on ${filepart}aligned.bam"
    samtools flagstat "${filepart}aligned.bam" > "${filepart}flagstatResults.txt"
    flagStatResult="${filepart}flagstatResults.txt"
    bash ~/flagStatScript.sh "$flagStatResult"
    if [ "$?" -eq 1 ]
    then
        mv "$flagStatResult" flaggedReads
    fi

	echo "sorting the bam file"
	samtools sort "${filepart}aligned.bam" -o "${filepart}aligned.sorted"

	echo "indexing the sam file"
	samtools index "${filepart}aligned.sorted"

	echo "generating a pileup file"
	samtools mpileup -q 30 -u -f ref_genome.fasta "${filepart}aligned.sorted" > "${filepart}.bcf" -I

	echo "variant calling"
	bcftools call -O v -mv "${filepart}.bcf" > "${filepart}.vcf"

	echo "filtered out variants with QUAL <200"
	bcftools filter --exclude "QUAL < 200" "${filepart}.vcf" 1> "${filepart}_filtered.vcf"
done

echo "running the python script"
python /projects/micb405/resources/vcf_to_fasta_het.py -x ~/project1/everything

echo "building the tree"
FastTree ~/project1/everything.fasta 1> ~/project1/everything.nwk
