# EMAGC
Eukaryotic Metagenome-Assembled Genome - Gene Calling

Description
===========

It predicts genes from Eukaryotic MAGs.

* It first trains Augustus through [BUSCO](https://busco.ezlab.org/busco_userguide.html)
* Then, it predicts genes from contigs longer than a specific size (defined by the user) 
    using [Augustus](http://augustus.gobics.de/) in the [MAKER](https://yandell-lab.org/software/maker.html) pipeline.
* The resulting genes are used to train [SNAP](https://github.com/KorfLab/SNAP) through MAKER.
* After SNAP training, genes are called from all contigs using SNAP and AUGUSTUS in MAKER.
* The predicted proteins are then annotated against the [Pfam](https://pfam.xfam.org/) database.


A comprehensive documentation for EMAGC is hosted on [readthedocs](https://emagc.readthedocs.io/en/latest/)
 

Installation
============

Clone the repository from GitHub:

    git clone https://github.com/lfdelzam/EMAGC

This directory contains the scripts:

     EMAGCpoly.sh
     EMAGCsingle.sh


Usage
=====

One MAG
-------

bash EMAGCsingle.sh [options]:

    -m=<absolute path to mag file>
    -s=<min contig size for SNAP training, default=5000>
    -p=<threads>
    -b=<conda or module,busco environment or package name, e.g -b="conda,busco_env">
    -k=<conda or module,MAKER environment or package name, e.g., -k="conda,maker_env">
    -a=<conda or module,hmmer environment or package name, e.g., -a="conda,annot_env", default -a=skip>
    -l=<busco lineage (e.g., eukaryota_odb10) or auto, default=eukaryota_odb10>
    -n=<number of SNAP training, default=1>
    -u=<absolute path to protein db or none, default=none>
    -r=<absolute path to cDNA sequence file in fasta format from an alternate organism or none, default=none>
    -w=<absolute path to Pfam hmm database or none, default=none>
    -v=<E-value threshold used during Pfam annotation, e.g., -v='-E 0.001', default='--cut_ga'>
    -q=<remove all temporary files, y for yes or n for no, default=no>

Several MAGs
------------

bash EMAGCpoly.sh [options]:

    -D=<path to mag directory>
    -E=<MAG extention, default ".fa">
    -S=<min contig size for SNAP training, default=5000>
    -P=<threads>
    -B=<conda or module,busco environment or package name, e.g., -B="conda,busco_env">
    -K=<conda or module,MAKER environment or package name, e.g., -K="module,maker">
    -A=<conda or module,hmmer environment or package name, e.g., -A="conda,annot", default -A=skip>
    -L=<busco lineage (e.g., eukaryota_odb10) or auto, default=eukaryota_odb10>
    -N=<number of SNAP training, default=1>
    -U=<absolute path to protein db or none, default=none>
    -R=<absolute path to cDNA sequence file in fasta format from an alternate organism or none, default=none>
    -W=<absolute path to Pfam hmm database or none, default=none>
    -V=<E-value threshold used during Pfam annotation, e.g., -V='-E 0.001', default='--cut_ga'>
    -Q=<remove all temporary files, y for yes or n for no, default=no>
    -F=<Force the re-execution, yes or no, default=no>
