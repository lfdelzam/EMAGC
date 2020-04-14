#!/usr/bin/env python3

import os
import argparse

usage = 'python extract_genes_with_pfam_best_hit.py [options]'
description = 'This program extracts genes with pfam hit (best hit) and prints out <genome_name>.fna, <genome_name>.faa and <genome_name>.gff files'

parser = argparse.ArgumentParser(description=description, usage=usage)
parser.add_argument('-i', dest='inf', help='input file, --tblout from hmmsearch', required=True)
parser.add_argument('-a', dest='a', help='input file, <mag_name>.gff from FINAL_RESULT', required=True)
parser.add_argument('-p', dest='p', help='input file, <mag_name>.all.maker.proteins.fasta from FINAL_RESULT', required=True)
parser.add_argument('-n', dest='n', help='input file, <mag_name>.all.maker.transcripts from FINAL_RESULT', required=True)
parser.add_argument('-o', dest='o', help='output directory,  default = Genes_with_Pfam_hit', default="Genes_with_Pfam_hit")

args = parser.parse_args()

best_hit = {}
scores = {}
short_name = {}

# functions


def extracting(filein, fileout):
    with open(filein, "r") as finp, open(fileout, "w") as foutp:
        non_first_line = False
        for line in finp:
            line = line.rstrip()
            if line.startswith(">"):
                copy = False
                id = line.split()[0][1:]
                if id in best_hit:
                    v = best_hit[id]
                    if non_first_line:
                        print("", file=foutp)
                    print("{} pfam_hit_{}_{} score: {} Protein_length: {}".format(v[0], v[1], v[2], v[3], v[4]), file=foutp)
                    copy = True
            else:
                if copy:
                    print(line, end="", file=foutp)
                    non_first_line = True
        print("", file=foutp)


def extracting_gff(filein, fileout):
    with open(filein, "r") as finp, open(fileout, "w") as foutp:
        print("##gff-version 3", file=foutp)
        for line in finp:
            line = line.rstrip()
            if line.startswith(">"):
                break
            elif not line.startswith("#"):
                if str(line.split()[2]) == "contig":
                    contig_line = line
                    copy_cl = True
                else:
                    idline = line.split()[8]
                    pre1 = idline.split(";")[0]
                    pre2 = pre1.replace("ID=", "")
                    pre3 = pre2.split(":")[0]
                    if pre3.endswith("-mRNA-1"):
                        sname = pre3.replace("-mRNA-1", "")
                    else:
                        sname = pre3
                    if sname in short_name:
                        if copy_cl:
                            print(contig_line, file=foutp)
                            copy_cl = False
                        non_name = sname.split("-")[0]+"-"
                        nline = line.replace(non_name, "")
                        print(nline, file=foutp)

# Reading Pfam annotation file

with open(args.inf, "r") as fin:
    for line in fin:
        line = line.rstrip()
        if not line.startswith("#"):
            line = line.split()
            target_name = line[0]
            shortname = target_name.replace("-mRNA-1", "")
            nonname = target_name.split("-")[0]+"-"
            name = target_name.replace(nonname, ">")
            query_name = line[2]
            query_accession = line[3]
            score = line[5]
            length = line[21].split("|")[8]
            if target_name in scores:
                if float(score) > float(scores[target_name]):
                    scores[target_name] = score
                    best_hit[target_name] = (name, query_name, query_accession, score, length)
            else:
                scores[target_name] = score
                best_hit[target_name] = (name, query_name, query_accession, score, length)
                short_name[shortname] = target_name

# Creating output directory
if not os.path.exists(args.o):
    os.mkdir(args.o)

# creating outputfiles in the new directory
mag_name = str(args.a).replace(".gff", "")

file_p = os.path.join(args.o, mag_name+".faa")
file_n = os.path.join(args.o, mag_name+".fna")
file_g = os.path.join(args.o, mag_name+".gff")

extracting(args.p, file_p)
extracting(args.n, file_n)
extracting_gff(args.a, file_g)
