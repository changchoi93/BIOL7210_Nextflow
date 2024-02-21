#!/usr/bin/env nextflow

// Define input parameters to be used.
params.data = "$baseDir" 

// Create a channel to read in the data file paths.
reads_ch = channel.fromFilePairs(params.data + '/*{1,2}.fastq')

// Step 1: Trimming fastq files using Fastp as our tool of choice
process trimReads {
    // Define the inputs to the process - in this case, two paired end read files in fastq format.
    input:
    tuple val(pairId), file(read1)

    // Define the outputs of the process - in this case, two paired trimmed fastq files.
    output:
    tuple val(pairId), file("${pairId}_trimmed_R1.fastq"), file("${pairId}_trimmed_R2.fastq")

    // The actual command to run the tool of choice - in this case, fastp.
    script:
    """
    fastp -i ${read1[0]} -I ${read1[1]} -o ${pairId}_trimmed_R1.fastq -O ${pairId}_trimmed_R2.fastq
    """
}

// Step 2: Creating a fasta assembly using spades as our tool of choice
process assemble {
    // Define the inputs to the process - in this case, two paired trimmed fastq files.
    input:
    tuple val(pairId), file("${pairId}_trimmed_R1.fastq"), file("${pairId}_trimmed_R2.fastq")

    // Define the outputs of the process - in this case, an assembled fasta file.
    output:
    file "${pairId}/contigs.fasta" 

    // The actual command to run the tool of choice - in this case, spades.
    script:
    """
    spades.py -1 ${pairId}_trimmed_R1.fastq -2 ${pairId}_trimmed_R2.fastq -o ${pairId} --phred-offset 33
    """
}

// Define the workflow execution
workflow {
    // Execute the processes in the correct order.
    trimReads(reads_ch)
    assemble(trimReads.out)
}
