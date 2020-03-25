Usage
=====

Go to the directory EMAGC::

    cd EMAGC


One MAG
^^^^^^^

bash EMAGCsingle.sh [options] ::

    -m=<absolute path to mag file>
    -s=<min contig size for SNAP training, default=10000>
    -p=<threads>
    -b=<conda or module,busco environment or package name, e.g -b="conda,busco_env">
    -k=<conda or module,MAKER environment or package name, e.g., -k="conda,maker_env">
    -a=<conda or module,hmmer environment or package name, e.g., -a="conda,annot_env", default -a=skip>
    -l=<busco lineage (e.g., eukaryota_odb10) or auto, default=eukaryota_odb10>
    -n=<number of SNAP training, default=1>
    -u=<absolute path to protein db or none, default=none>
    -r=<absolute path to cDNA sequence file in fasta format from an alternate organism or none, default=none>
    -w=<absolute path to Pfam hmm database or none, default=none>
    -v=<E-value threshold used during Pfam annotation, default=0.001>
    -q=<remove all temporary files, y for yes or n for no, default=no>

Several MAGs
^^^^^^^^^^^^

bash EMAGCpoly.sh [options] ::

    -D=<absolute path to mag directory>
    -E=<MAG extention, default ".fa">
    -S=<min contig size for SNAP training, default=10000>
    -P=<threads>
    -B=<conda or module,busco environment or package name, e.g., -B="conda,busco_env">
    -K=<conda or module,MAKER environment or package name, e.g., -K="conda,maker_env">
    -A=<conda or module,hmmer environment or package name, e.g., -A="conda,annot_env", default -A=skip>
    -L=<busco lineage (e.g., eukaryota_odb10) or auto, default=eukaryota_odb10>
    -N=<number of SNAP training, default=1>
    -U=<absolute path to protein db or none, default=none>
    -R=<absolute path to cDNA sequence file in fasta format from an alternate organism or none, default=none>
    -W=<absolute path to Pfam hmm database or none, default=none>
    -V=<E-value threshold used during Pfam annotation, default=0.001>
    -Q=<remove all temporary files, y for yes or n for no, default=no>
    -F=<Force the re-execution, yes or no, default=no>
