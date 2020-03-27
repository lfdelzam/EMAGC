Installation
============

Required software
^^^^^^^^^^^^^^^^^

`BUSCO <https://busco.ezlab.org/>`_ >= 4.0.2

`MAKER <https://yandell-lab.org/software/maker_install.html/>`_   

`python3 <https://www.python.org/>`_

If you want to annotate the predicted proteins against the Pfam database:

`hmmer <http://hmmer.org/>`_

`Pfam-A.hmm database <https://pfam.xfam.org/>`_

Tips for installing the required software
-----------------------------------------

The easiest and highly recommended way to install the required software is through conda in isolated environments.
Bellow, an example of how to install Miniconda3 (on Linux) and the pipeline is presented:

I. Installing `miniconda <https://docs.conda.io/en/latest/miniconda.html/>`_ (Linux)

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

and follows the instruction `on the link <https://wiki.hpcc.msu.edu/display/ITH/Installing+maker+using+conda/>`_. 
Particularly, please watch the `video <https://wiki.hpcc.msu.edu/download/attachments/29655183/repeatmasker-small-copy.mp4?version=1&modificationDate=1558377146559&api=v2>`_

BUSCO
-----

BUSCO version must be 4.0.2 or higher.
Create a virtual environment for BUSCO::

    conda create -n busco_env -c bioconda -c conda-forge busco


hmmer
-----

Create a virtual environment for hmmer::

    conda create -n annot_env -c bioconda -c conda-forge hmmer python


Download EMAGC
^^^^^^^^^^^^^^

Clone the repository from GitHub::

    git clone https://github.com/lfdelzam/EMAGC


This directory contains the scripts:

   * EMAGCpoly.sh
   * EMAGCsingle.sh
   * src/extract_genes_with_pfam_best_hit.py
