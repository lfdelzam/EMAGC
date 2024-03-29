#!/bin/bash -l

err_report() {
    echo "Error on line $1 - script EMAGCpoly.sh"
    exit 1
}

trap 'err_report $LINENO' ERR
Usage="\nUsage: bash EMAGCpoly.sh [options]\n -D=<path to mag directory>\n -E=<MAG extention, default ".fa">\n -S=<min contig size for SNAP training, default=5000>\n -P=<threads>\n -B=<conda or module,busco environment or package name, e.g., -B="conda,busco_env">\n -K=<conda or module,MAKER environment or package name, e.g., -K="module,maker">\n -A=<conda or module,hmmer environment or package name, e.g., -A="conda,annot", default -A=skip>\n -L=<busco lineage (e.g., eukaryota_odb10) or auto, default=eukaryota_odb10>\n -N=<number of SNAP training, default=1>\n -U=<absolute path to protein db or none, default=none>\n -R=<absolute path to cDNA sequence file in fasta format from an alternate organism or none, default=none>\n -W=<absolute path to Pfam hmm database or none, default=none>\n -V=<E-value threshold used during Pfam annotation, e.g., -V='-E 0.001', default='--cut_ga'>\n -Q=<remove all temporary files, y for yes or n for no, default=no>\n -F=<Force the re-execution, yes or no, default=no>\n"
Description="Description:\nThis program predicts genes from Eukaryotic MAGs.\nIt first trains Augustus through BUSCO (>=v4.0.2).\nThen, it predicts genes from contigs longer than a specific size (defined by the user) using Augustus in the MAKER pipeline.\nThe resulting genes are used to train SNAP through MAKER.\nAfter SNAP training, genes are called from all contigs using SNAP and AUGUSTUS in MAKER.\nThe predicted proteins are then annotated against Pfam database\n"
Observation="Observation:\nIt can be used either the same or different virtual environments for BUSCO, MAKER and HMMER, e.g., conda activate busco, conda activate maker; or module load busco, module load maker.\nIf you need to load a module before the actual BUSCO or MAKER module, set it by entering both module names, e.g., -K='module,bioinfo-tools maker'\nIf you have already run the script, and only want to re-run MAKER (and not busco), then set -B=skip\nThe same goes if you want to skip MAKER -K=skip or Pfam annotation, -A=skip"
#*******     Argument parse **********************************************
if [ $# -eq 0 ]; then
    echo -e "\nNo arguments provided"
    echo -e "${Usage}"
    echo -e "${Description}"
    echo -e "${Observation}"
    exit 1
fi

###defaults
mag_ext=".fa"
mincontigsize=5000
Rmv_tmp=no
ProteinDB=none
RNAdb=none
SNAP_TR=1
Busco_Lineage=eukaryota_odb10
antENV=skip
pfamDB="Pfam-A.hmm"
#Evalue=0.001
Evalue="--cut_ga"
RI=no

for i in "$@"
do
case $i in
   -D=*|--mag_directory=*)
    if [ -z "${i#*=}" ];  then echo "value to argument -D No supplied"; exit 0; else path_to_MAGs_dir="${i#*=}"; fi
    shift # past argument
    ;;

   -E=*|--mag_ext=*)
    mag_ext="${i#*=}"
    shift # past argument
    ;;

    -S=*|--Min_contig_size=*)
    mincontigsize="${i#*=}"
    shift # past argument
    ;;

    -P=*|--CPUs=*)
    if [ -z "${i#*=}" ];  then echo "value to argument -P No supplied"; exit 0; else thr="${i#*=}"; fi
    shift # past argument
    ;;

    -B=*|--Busco_Environment=*)
    if [ -z "${i#*=}" ];  then echo "value to argument -B No supplied"; exit 0; else  BEnv="${i#*=}"; fi
    shift # past argument
    ;;

    -K=*|--Maker_Environment=*)
    if [ -z "${i#*=}" ];  then echo "value to argument -K No supplied"; exit 0; else  MKEnv="${i#*=}"; fi
    shift # past argument
    ;;

    -Q=*|--Remove_temp_files=*)
    Rmv_tmp="${i#*=}"
    shift # past argument
    ;;

    -U=*|--Protein_db=*)
    ProteinDB="${i#*=}"
    shift # past argument
    ;;

    -R=*|--RNA_db=*)
    RNAdb="${i#*=}"
    shift # past argument
    ;;

    -N=*|--Num_trg=*)
    SNAP_TR="${i#*=}"
    shift # past argument
    ;;

    -L=*|--Lineage=*)
    Busco_Lineage="${i#*=}"
    shift # past argument
    ;;

    -A=*|--Annotation_environment=*)
    antENV="${i#*=}"
    shift # past argument
    ;;

    -W=*|--Pfam_datadase_path=*)
    if [[ "$antENV" != skip ]] && [[ "$antENV" != none ]] && [ -z "${i#*=}" ]; then
      echo "value to argument -W No supplied"
      exit 0
    else pfamDB="${i#*=}"
    fi
    shift # past argument
    ;;

    -V=*|--E_value=*)
    Evalue="${i#*=}"
    shift # past argument
    ;;

    -F=*|--re_run=*)
    RI="${i#*=}"
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
#--checking paths -----
if [[ "$path_to_MAGs_dir" != /* ]]; then
    echo "Please provide an absolute path -D=/absolute/path/to/MAGs_dir"
    exit 0
fi
if [[ "$ProteinDB" != /* ]] && [[ "$ProteinDB" != none ]]; then
    echo "Please provide an absolute path -U=/absolute/path/to/Protein_DB"
    exit 0
fi
if [[ "$RNAdb" != /* ]] && [[ "$RNAdb" != none ]]; then
    echo "Please provide an absolute path -R=/absolute/path/to/cDNA_DB"
    exit 0
fi

if [[ "$antENV" != skip ]] && [[ "$antENV" != none ]] && [[ "$pfamDB" != /* ]]; then
    echo "Please provide an absolute path -W=/absolute/path/to/$pfamDB"
    exit 0
fi
#-----------------------
if [ "$RI" == yes ]; then echo "Option - Force the re-execution - activated"; fi
#***************************** Main ************************************
wkd=$(pwd)
#MAG_list
cd $path_to_MAGs_dir
Lgs=($(ls *$mag_ext))

#Running gene_calling for each MAG
for m in "${Lgs[@]}"
do
  cd $wkd
  name=$(echo ${m%$mag_ext}) #removing extention
  if [ ! -d "Gene_calling_$name" ]  || [ "$RI" == yes ]  || [ -z "$(ls -A "Gene_calling_$name")" ]; then
     mkdir -p Gene_calling_$name
     cd Gene_calling_$name
     mag_path="$path_to_MAGs_dir/$m"
     echo -e "INFO: ********  Starting gene calling on mag $m  ********* \n"
     bash $wkd/EMAGCsingle.sh -m=$mag_path -s=$mincontigsize -p=$thr -b="$BEnv" -k="$MKEnv" -q=$Rmv_tmp -u=$ProteinDB -r=$RNAdb -n=$SNAP_TR -l=$Busco_Lineage -a="$antENV" -w=$pfamDB -v=$Evalue -x=$wkd
     echo -e "\nINFO: ********  Gene calling on mag $m is done *********** \n"
  else
     echo "Directory Gene_calling_$name already exists and it is not empty"
  fi
done
