Description
===========

This program predicts genes from Eukaryotic MAGs.

* It first trains Augustus through BUSCO (https://busco.ezlab.org/busco_userguide.html).
* Then, it predicts genes from contigs longer than a specific size (defined by the user) using Augustus in the MAKER pipeline (https://yandell-lab.org/software/maker.html).
* The resulting genes are used to train SNAP through MAKER.
* After SNAP training, genes are called from all contigs using SNAP and AUGUSTUS in MAKER.
* The predicted proteins are then annotated against the Pfam database (https://pfam.xfam.org/) using hmmsearch (http://eddylab.org/software/hmmer3/3.1b2/Userguide.pdf).

Observation:

* It can be used either the same or different virtual environments for BUSCO, MAKER, and HMMER, e.g., conda activate busco, conda activate maker, or module load busco, conda activate maker.
* We highly recommend using miniconda and independent virtual environments for each software.
* If you need to load a module before the actual BUSCO or MAKER module, set it by entering both module names, e.g., -K='module,bioinfo-tools busco'.
* If you have already run the script, and only want to re-run MAKER (and not busco), then set -B=skip
* The same goes if you want to skip MAKER -K=skip or Pfam annotation, -A=skip.


Contents
========

.. toctree::
   :maxdepth: 3

   Installation
   Usage
   Output


