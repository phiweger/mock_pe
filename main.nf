nextflow.enable.dsl = 2


process assemble {
    publishDir params.results, mode: 'copy', overwrite: true
    container 'nanozoo/shovill:1.1.0--1dafaa5'
    cpus 8
    memory '16 GB'

    input:
    tuple(val(name), path(p1), path(p2))

    output:
    tuple(val(name), path("${name}.fasta"))

    """
    shovill --cpus ${task.cpus} --ram 12 --outdir assembly --minlen 2000 --assembler megahit --trim --R1 ${p1} --R2 ${p2}
    mv assembly/contigs.fa ${name}.fasta
    """
}


process annotate {
    publishDir params.results, mode: 'copy', overwrite: true
    container 'nanozoo/prokka:1.14.6--773a90d'
    cpus 8

    input:
    tuple(val(name), path(assembly))

    output:
    path("anno/${name}.gff")

    """
    prokka --cpus ${task.cpus} --outdir anno --prefix ${name} ${assembly}
    """
}


workflow {
    /*
    nextflow run main.nf --genomes input.csv --results results
    */
    genomes = channel.fromPath(params.genomes, checkIfExists: true)
                     .splitCsv(header: false)
                     .map{ row -> tuple(row[0], row[1], row[2]) }
    genomes.view()
    assemble(genomes)
    annotate(assemble.out)
}

