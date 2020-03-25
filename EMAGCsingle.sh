#!/bin/bash -l

err_report() {
    echo "Error on line $1 - script EMAGCsingle.sh"
    exit 1
}

trap 'err_report $LINENO' ERR
Usage='\nUsage: bash EMAGCsingle.sh [options]\n -m=<absolute path to mag file>\n -s=<min contig size for SNAP training, default=5000>\n -p=<threads>\n -b=<conda or module,busco environment or package name, e.g -b="conda,busco_env">\n -k=<conda or module,MAKER environment or package name, e.g., -k="module,maker">\n -a=<conda or module,hmmer environment or package name, e.g., -a="conda,annot", default -a=skip>\n -l=<busco lineage (e.g., eukaryota_odb10) or auto, default=eukaryota_odb10>\n -n=<number of SNAP training, default=1>\n -u=<absolute path to protein db or none, default=none>\n -r=<absolute path to cDNA sequence file in fasta format from an alternate organism or none, default=none>\n -w=<absolute path to Pfam hmm database or none, default=none>\n -v=<E-value threshold used during Pfam annotation, default=0.001>\n -q=<remove all temporary files, y for yes or n for no, default=no>\n'
Description="Description:\nThis program predicts genes from an Eukaryotic MAG.\nIt first trains Augustus through BUSCO V4.0.2.\nThen, it predicts genes from contigs longer than a specific size (defined by the user) using Augustus in the MAKER pipeline.\nThe resulting genes are used to train SNAP through MAKER.\nAfter SNAP training, genes are called from all contigs using SNAP and AUGUSTUS in MAKER.\nThe predicted proteins are then annotated against Pfam database\n"
Observation="Observation:\nIt can be used either the same or different virtual environments for BUSCO, MAKER and HMMER, e.g., conda activate busco, conda activate maker; or module load busco, module load maker.\nIf you need to load a module before the actual BUSCO or MAKER module, set it by entering both module names, e.g., -k='module,bioinfo-tools maker'\nIf you have already run the script, and only want to re-run MAKER (and not busco), then set -b=skip\nThe same goes if you want to skip MAKER -k=skip or Pfam annotation, -a=skip"
#*******     Argument parse **********************************************
if [ $# -eq 0 ]; then
echo -e "\nNo arguments provided"
echo -e "${Usage}"
echo -e "${Description}"
echo -e "${Observation}"
    exit 1
fi
###defaults
mincontig=5000
remove_tmp=no
proteinDB=none
RNADB=none
SNAP_trgs=1
busco_lineage=eukaryota_odb10
ANTENV=skip
PfamDB="Pfam-A.hmm"
evalue=0.001
real_pwd=$(pwd)

for i in "$@"
do
case $i in
   -m=*|--mag_file=*)
    if [ -z "${i#*=}" ];  then echo "value to argument -m No supplied"; exit 0
    else path_to_genome="${i#*=}"; fi
    shift # past argument
    ;;

    -s=*|--min_contig_size=*)
    mincontig="${i#*=}"
    shift # past argument
    ;;

    -v=*|--e_value=*)
    evalue="${i#*=}"
    shift # past argument
    ;;

    -p=*|--threads=*)
    if [ -z "${i#*=}" ];  then echo "value to argument -p No supplied"; exit 0
    else threads="${i#*=}"; fi
    shift # past argument
    ;;

    -b=*|--busco_environment=*)
    if [ -z "${i#*=}" ];  then echo "value to argument -b No supplied"; exit 0
    else BENV="${i#*=}"; fi
    shift # past argument
    ;;

    -k=*|--maker_environment=*)
    if [ -z "${i#*=}" ];  then echo "value to argument -k No supplied"; exit 0
    else MKENV="${i#*=}"; fi
    shift # past argument
    ;;

    -a=*|--annotation_environment=*)
    ANTENV="${i#*=}"
    shift # past argument
    ;;

    -w=*|--pfam_datadase_path=*)
    if [[ "$ANTENV" != skip ]] && [[ "$ANTENV" != none ]] && [ -z "${i#*=}" ]; then
      echo "value to argument -w No supplied"
      exit 0
    else PfamDB="${i#*=}"
    fi
    shift # past argument
    ;;

    -q=*|--remove_temp_files=*)
    remove_tmp="${i#*=}"
    shift # past argument
    ;;

    -u=*|--protein_db=*)
    proteinDB="${i#*=}"
    shift # past argument
    ;;

    -r=*|--rna_db=*)
    RNADB="${i#*=}"
    shift # past argument
    ;;

    -n=*|--num_trgs=*)
    SNAP_trgs="${i#*=}"
    shift # past argument
    ;;

    -l=*|--lineage=*)
    busco_lineage="${i#*=}"
    shift # past argument
    ;;

    -x=*|--realwd=*)
    real_pwd="${i#*=}"
    shift # past argument
    ;;

    *)
    echo -e "${Usage}"
    echo -e "${Description}"
    echo -e "${Observation}"
    exit 0
    ;;

esac
done

#--checking paths and removal option-----
if [[ "$proteinDB" != /* ]] && [[ "$proteinDB" != none ]]; then
    echo "Please provide an absolute path -u=/absolute/path/to/protein_DB"
    exit 0
fi

if [[ "$RNADB" != /* ]] && [[ "$RNADB" != none ]]; then
    echo "Please provide an absolute path -r=/absolute/path/to/cDNA_DB"
    exit 0
fi

if [[ "$ANTENV" != skip ]] && [[ "$ANTENV" != none ]] && [[ "$PfamDB" != /* ]]; then
    echo "Please provide an absolute path -w=/absolute/path/to/$PfamDB"
    exit 0
fi

if [[ "$remove_tmp" == y* ]] || [[ "$remove_tmp" == Y* ]]; then
  echo -e "\nWARNING: you have selected to remove all BUSCO (tmp_opt_BUSCO_$mag_name/, busco_downloads/)\nand MAKER ($mag_name.maker.output/, SNAP_training/, intermediate_steps.$mag_name.all.gff)\ntemporary files\n"
fi

#data name-----------
mg=$(echo $(basename $path_to_genome))
mag_name=$(echo ${mg%.*})
Aug_SPE="BUSCO_"$mag_name
workdir=$(pwd)

#***************************** Main ************************************
#### BUSCO ################################################################

if [[ "$BENV" != skip ]]; then #In case the user have already run BUSCO and doesn't want to run it again before evaluating new parameters in MAKER

    if [[ "$busco_lineage" == auto* ]] || [[ "$busco_lineage" == AUTO* ]]; then
      lineage="--auto-lineage-euk"
      echo -e "\n*** BUSCO auto-lineage has been selected. The flag $lineage will be used in BUSCO\n"
    else
      lineage="-l $busco_lineage"
      echo -e "\n*** The Lineage $busco_lineage has been selected. The flag $lineage will be used in BUSCO\n"
    fi

    benvr=$(echo $BENV | cut -d"," -f1)
    busco_env=$(echo $BENV | cut -d"," -f2)

    echo "INFO: Running BUSCO"

  #Setting Virtual Environment  -----------
    if [[ "$benvr" == "conda" ]]; then
      eval "$(conda shell.bash hook)"
      conda activate $busco_env
    elif [[ "$benvr" == "module" ]]; then
      module load $busco_env
    fi
  #---------------------------------------
    busco -i $path_to_genome -o $mag_name -m geno -q -f $lineage --long --cpu $threads

    mv $mag_name busco_output_$mag_name

    if [[ "$remove_tmp" == y* ]] || [[ "$remove_tmp" == Y* ]]; then
      rm -r tmp_opt_BUSCO_$mag_name
      rm -r busco_downloads
    fi

#    echo "INFO: BUSCO is done"

  #Deactivate Virtual Environment  -----------
    if [[ "$benvr" == "conda" ]]; then
      conda deactivate
    elif [[ "$benvr" == "module" ]]; then
      module unload $busco_env
    fi
#---------------------------------------
else
  echo "You have chosen not to run BUSCO"
fi
####################################################################

#### MAKER ################################################################

if [[ "$MKENV" != skip ]]; then
   menvr=$(echo $MKENV | cut -d"," -f1)
   maker_env=$(echo $MKENV | cut -d"," -f2)

#Creating AUGUSTUS specie and pred_gff to be used in MAKER
    cd busco_output_$mag_name
    lgs=($(ls -d run_*))
    cd $workdir

    for i in "${lgs[@]}"
      do
        if [ -d "busco_output_$mag_name/$i/augustus_output/retraining_parameters/$Aug_SPE" ]
           then
           DIRECTORY="busco_output_$mag_name/$i/augustus_output/retraining_parameters/$Aug_SPE"
#           GFF_DIRECTORY="busco_output_$mag_name/$i/augustus_output/gff"
#           cat $workdir/$GFF_DIRECTORY/*.gff > allgff
#           mkdir -p tmp_Pdb
#           mv allgff tmp_Pdb/augustus_pred.gff
        else
           echo -e "ERROR: AUGUSTUS training with BUSCO was unsuccesful. Directory busco_output_$mag_name/$i/augustus_output/retraining_parameters/$Aug_SPE doesn't exit, and Augustus specie $Aug_SPE cannot be created.\nIt is highly probable that $mag_name$mag_ext is not an Eukaryotic MAG"
           exit 0
        fi
    done

    echo "INFO: Starting with MAKER"

    #Setting Virtual Environment  -----------
    if [[ "$menvr" == "conda" ]]; then
      eval "$(conda shell.bash hook)"
      conda activate $maker_env
    elif [[ "$menvr" == "module" ]]; then
      module load $maker_env
    fi
    #---------------------------------------

    #starting
    echo "INFO: Creating MAKER config files"
    maker -CTL

    echo "INFO: Preparation steps - Step 1 of 2 - Generating gene dataset for training SNAP"
    echo "INFO:       Running RepeatMasker, ab-initio gene predictions with contigs longer than $mincontig bs"
    #Min_contig > cut-off to obtain better gene dataset, that will be used for training SNAP
    sed -i s/"^min_contig=1"/"min_contig=$mincontig"/ maker_opts.ctl

    #Setting number of threads for RepeatMasker and blast
    sed -i s/"^cpus=1"/"cpus=$threads"/ maker_opts.ctl

    if [[ "$proteinDB" == "none" ]] || [[ "$proteinDB" == "NONE" ]]; then
         echo "WARNING: Protein sequence file in fasta format has not been provided. Gene predicitons directly from protein homology is not possible"
    else
      #Changing maker_opts.ctl file to include protein sequence file and to enable gene predicitons directly from protein homology
      sed -i s/"^protein2genome=.*#"/"protein2genome=1 #"/ maker_opts.ctl

      Pdb=$(basename $proteinDB)
      mkdir -p tmp_Pdb
      ln -s $proteinDB tmp_Pdb/.
      sed -i s/"^protein=.*#"/"protein=tmp_Pdb\/$Pdb #"/ maker_opts.ctl
    fi

    if [[ "$RNADB" == "none" ]] || [[ "$RNADB" == "NONE" ]]; then
           echo "WARNING: cDNA sequence file in fasta format has not been provided. Gene predicitons directly from cDNA is not possible"
      else
      #Changing maker_opts.ctl file to include protein sequence file and to enable gene predicitons directly from cDNA
        sed -i s/"^est2genome=.*#"/"est2genome=1 #"/ maker_opts.ctl

        Rdb=$(basename $RNADB)
        mkdir -p tmp_Pdb
        ln -s $RNADB tmp_Pdb/.
    #altest= #EST/cDNA sequence file in fasta format from an alternate organism
        sed -i s/"^altest=.*#"/"altest=tmp_Pdb\/$Rdb #"/ maker_opts.ctl
      fi

    #Using Gff file prediction from BUSCO-Augusutus in Maker
    #####sed -i s/"^pred_gff=.*#"/"pred_gff=tmp_Pdb\/augustus_pred.gff #"/ maker_opts.ctl

    #Augustus predictions training dataset

    mkdir -p $AUGUSTUS_CONFIG_PATH/species/$Aug_SPE

    cp $DIRECTORY/* $AUGUSTUS_CONFIG_PATH/species/$Aug_SPE/.

    sed -i s/"^augustus_species=.*#"/"augustus_species=$Aug_SPE #"/ maker_opts.ctl

    #Keep all predicitons
    sed -i s/"^keep_preds=0"/"keep_preds=1"/ maker_opts.ctl

    #**************************  maker run 1 ********************************
    mkdir -p log_files
    maker -genome=$path_to_genome -base $mag_name 2> log_files/run_RepeatMasker_augustus_big_contigs.log

    #updating config file with RepeatMasker and Augustus results
    gff3_merge -d $mag_name.maker.output/$mag_name"_master_datastore_index.log"

    echo "Total mRNA predicted in this run : $(cut -f3 $mag_name.all.gff | grep -c 'mRNA')"
    echo "Max protein size: $(cut -f3,9 $mag_name.all.gff | grep '^mRNA' | cut -d '|' -f9 | sort -rn | head -1)"
    echo "Min protein size: $(cut -f3,9 $mag_name.all.gff | grep '^mRNA' | cut -d '|' -f9 | sort -n | head -1)"
    echo "Median protein size: $(cut -f3,9 $mag_name.all.gff | grep '^mRNA' | cut -d '|' -f9 | sort -n | awk ' { a[i++]=$1; } END { x=int((i+1)/2); if (x < (i+1)/2) print (a[x-1]+a[x])/2; else print a[x-1]; } ') "
    echo "Average protein size: $(cut -f3,9 $mag_name.all.gff | grep '^mRNA' | cut -d '|' -f9 | awk 'BEGIN{C=0}; {C=C+$1}; END{print C/NR}')"

    sed -i s/"^maker_gff=.*#"/"maker_gff=$mag_name.all.gff #"/ maker_opts.ctl

    echo "INFO: Preparation steps - Step 1 (of 2) is done"

    echo "INFO: Preparation steps - Step 2 of 2 - training SNAP"
    mkdir -p SNAP_training

    #####****####

    nt=$(echo $SNAP_trgs-1 | bc)
    x=1

    while [ $x -le $nt ]
    do
    echo "INFO:          Starting SNAP training - $x"
    cd SNAP_training/
    mkdir -p RUN$x
    cd RUN$x
    maker2zff $workdir/$mag_name.all.gff
    fathom genome.ann genome.dna -validate > snap_validate_output.txt
    fathom genome.ann genome.dna -categorize 1000
    fathom uni.ann uni.dna -export 1000 -plus
    forge export.ann export.dna
    cd $workdir
    hmm-assembler.pl $path_to_genome SNAP_training/RUN$x/. > $mag_name.$x.hmm
    sed -i s/"^snaphmm=.*#"/"snaphmm=$mag_name.$x.hmm #"/ maker_opts.ctl

    echo "INFO:         Running SNAP with training $x "

    maker -genome=$path_to_genome -base $mag_name 2> log_files/run_SNAP_run$x.log

    #updating config file with SNAP results
    gff3_merge -d $mag_name.maker.output/$mag_name"_master_datastore_index.log"

    echo "Total mRNA predicted in this run : $(cut -f3 $mag_name.all.gff | grep -c 'mRNA')"
    echo "Max protein size: $(cut -f3,9 $mag_name.all.gff | grep '^mRNA' | cut -d '|' -f9 | sort -rn | head -1)"
    echo "Min protein size: $(cut -f3,9 $mag_name.all.gff | grep '^mRNA' | cut -d '|' -f9 | sort -n | head -1)"
    echo "Median protein size: $(cut -f3,9 $mag_name.all.gff | grep '^mRNA' | cut -d '|' -f9 | sort -n | awk ' { a[i++]=$1; } END { x=int((i+1)/2); if (x < (i+1)/2) print (a[x-1]+a[x])/2; else print a[x-1]; } ') "
    echo "Average protein size: $(cut -f3,9 $mag_name.all.gff | grep '^mRNA' | cut -d '|' -f9 | awk 'BEGIN{C=0}; {C=C+$1}; END{print C/NR}')"

    x=$(( $x + 1 ))

    done

    ####***###

    echo "INFO:         Starting Final SNAP training"
    cd SNAP_training/
    mkdir -p RUN_final
    cd RUN_final
    maker2zff $workdir/$mag_name.all.gff
    fathom genome.ann genome.dna -validate > snap_validate_output.txt
    fathom genome.ann genome.dna -categorize 1000
    fathom uni.ann uni.dna -export 1000 -plus
    forge export.ann export.dna
    cd $workdir
    hmm-assembler.pl $path_to_genome SNAP_training/RUN_final/. > $mag_name.final.hmm
    #sed -i s/"^snaphmm=$mag_name.2.hmm"/"snaphmm=$mag_name.3.hmm"/ maker_opts.ctl
    sed -i s/"^snaphmm=.*#"/"snaphmm=$mag_name.final.hmm #"/ maker_opts.ctl

    echo "INFO: Preparation steps - Step 2 (of 2) is done"

    echo "INFO: Running final Prediction SNAP and Augustus, using all contigs"

    #modifying parameters for enlarging protein predictions and obtain statistics for all predictions and models
    sed -i s/"^min_contig=$mincontig"/"min_contig=1"/ maker_opts.ctl
    sed -i s/"^pred_stats=0"/"pred_stats=1"/ maker_opts.ctl
    #Gene predictions directly from protein and/or cDNA homology is deactivated
    sed -i s/"^protein2genome=.*#"/"protein2genome=0 #"/ maker_opts.ctl
    sed -i s/"^est2genome=.*#"/"est2genome=0 #"/ maker_opts.ctl

    #*********************  maker final run ***********************************
    maker -genome=$path_to_genome -base $mag_name 2> log_files/run_final_prediction.log

    echo "INFO: Merging results and printing them in FINAL_RESULT folder"
    #FINAL RESULT
    mkdir -p FINAL_RESULT
    cd FINAL_RESULT/
    gff3_merge -d $workdir/$mag_name.maker.output/$mag_name"_master_datastore_index.log"
    fasta_merge -d $workdir/$mag_name.maker.output/$mag_name"_master_datastore_index.log"

    echo "Total mRNA predicted in this run : $(cut -f3 $mag_name.all.gff | grep -c 'mRNA')"
    echo "Max protein size: $(cut -f3,9 $mag_name.all.gff | grep '^mRNA' | cut -d '|' -f9 | sort -rn | head -1)"
    echo "Min protein size: $(cut -f3,9 $mag_name.all.gff | grep '^mRNA' | cut -d '|' -f9 | sort -n | head -1)"
    echo "Median protein size: $(cut -f3,9 $mag_name.all.gff | grep '^mRNA' | cut -d '|' -f9 | sort -n | awk ' { a[i++]=$1; } END { x=int((i+1)/2); if (x < (i+1)/2) print (a[x-1]+a[x])/2; else print a[x-1]; } ') "
    echo "Average protein size: $(cut -f3,9 $mag_name.all.gff | grep '^mRNA' | cut -d '|' -f9 | awk 'BEGIN{C=0}; {C=C+$1}; END{print C/NR}')"

    echo "INFO: Now Predictions are ready and stored in the folder FINAL_RESULT/ "

    cd $workdir

    if [[ "$remove_tmp" == y* ]] || [[ "$remove_tmp" == Y* ]]; then
        rm -r $mag_name.maker.output
        rm -r SNAP_training
        rm $mag_name.all.gff
        if [ -d tmp_Pdb ]; then rm -r tmp_Pdb; fi
    fi

    #Deactivate virtual Environment-------
    if [[ "$menvr" == "conda" ]]; then
      conda deactivate
    elif [[ "$menvr" == "module" ]]; then
      module unload $maker_env
    fi
else
  echo "You have chosen not to run MAKER"
fi
#####################################################

#### hmmer ################################################################

if [[ "$ANTENV" != skip ]]; then
  antenvr=$(echo $ANTENV | cut -d"," -f1)
  ant_env=$(echo $ANTENV | cut -d"," -f2)

  if [[ "$antenvr" == "conda" ]]; then
    eval "$(conda shell.bash hook)"
    conda activate $ant_env
  elif [[ "$antenvr" == "module" ]]; then
    module load $ant_env
  fi

  echo "INFO: Starting with Pfam annotations"

  mkdir -p FINAL_RESULT
  cd FINAL_RESULT/
  mkdir -p annotation_pfam
  out1="annotation_pfam/Output_hmmsearch_pfam"
  out_dom="annotation_pfam/table_domain_hmmsearch_pfam"
  out_t="annotation_pfam/table_protein_hmmsearch_pfam"
  input_fasta="$mag_name.all.maker.proteins.fasta"
  hmmsearch --cpu $threads --noali -E $evalue -o $out1 --domtblout $out_dom --tblout $out_t $PfamDB $input_fasta
  annotated=$(grep -v "^#" $out_t | cut -d " " -f1 | sort -u | wc -l)
  echo "Total Pfam-annotated proteins $annotated (a hit per protein)"
  echo "INFO: Pfam-annotation is ready. Files stored in the folder FINAL_RESULT/annotation_pfam/"

  echo "Extracting sequences with pfam hit (best hit)"
  python $real_pwd/src/extract_genes_with_pfam_best_hit.py -i $out_t -p $input_fasta -n $mag_name.all.maker.transcripts.fasta -a $mag_name.all.gff
  echo "INFO: The Pfam annotated sequences (proteins.faa, genes.fna), and the corresponding annotation file (annotation.gff) are stored in the folder FINAL_RESULT/Genes_with_pfam_hit/"

  cd $workdir

  if [[ "$antenvr" == "conda" ]]; then
    conda deactivate
  elif [[ "$antenvr" == "module" ]]; then
    module unload $ant_env
  fi

else
  echo "You have chosen not to run Pfam annotation"
fi
#####################################################
