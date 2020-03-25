Installation
============

Required software
^^^^^^^^^^^^^^^^^

* BUSCO >= 4.0.2
* MAKER
* python3

If you want to annotate the predicted proteins against the Pfam database:

* hmmer
* Pfam-A.hmm database

Tips for installing the required software
-----------------------------------------

The easiest and highly recommended way to install the required software is through conda in isolated environments.
Bellow, an example of how to install Miniconda3 (on Linux) and the pipeline is presented:

I. Installing miniconda (Linux)

Download miniconda::

    wget https://repo.continuum.io/miniconda/Miniconda3-latest-Linux-x86_64.sh

Then, execute the script::

    bash Miniconda3-latest-Linux-x86_64.sh

Answer "yes" to question. Then, close and then re-open your terminal window. Now the command conda will work.

It may be necessary to source, with the command::

    source ~/.bashrc

II. Software

To avoid package conflicts, we recommend to create independent virtual environments, as shown below:

MAKER
-----

Create a virtual environment for MAKER::

    conda create -n maker_env -c bioconda maker

It may be necessary to change RepeatMasker configuration. Please go to the RepeatMasker directory::

    cd maker_env/share/RepeatMasker/

and follows the instruction on https://wiki.hpcc.msu.edu/display/ITH/Installing+maker+using+conda
particularly, please watch the video: https://wiki.hpcc.msu.edu/download/attachments/29655183/repeatmasker-small-copy.mp4?version=1&modificationDate=1558377146559&api=v2

BUSCO
-----

BUSCO version must be 4.0.2 or higher.
Create a virtual environment for BUSCO::

    conda create -n busco_env -c bioconda busco


hmmer
-----

Create a virtual environment for hmmer::

    conda create -n annot_env -c bioconda hmmer


Download EMAGC
^^^^^^^^^^^^^^

Clone the repository from GitHub::

    git clone https://github.com/EnvGen/EMAGC


This directory contains the scripts:
   * EMAGCpoly.sh
   * EMAGCsingle.sh
   * src/extract_genes_with_pfam_best_hit.py
