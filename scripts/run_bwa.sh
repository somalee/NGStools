#!/bin/bash

#Exit on error immediately
set -e

#If you want a more verbose bash output
#set -ex

echo "PATH=$PATH"


SETUP_FILE="/Users/somalee/Code/NGStools/setup.sh"
cmd="source $SETUP_FILE"
eval $cmd || { echo $cmd; echo "Command failed"; exit 1; }


#
# Currently only supports Frag data
#
DEFAULT_LIBRARY=Frag

#
# These are populated in the BAM file, can be chaged on the command line
#
DEFAULT_PLATFORM=ION
DEFAULT_PLATFORM_UNIT=barcode_0000
DEFAULT_RGID=1234
DEFAULT_SAMPLENAME=sample_0000
DEFAULT_SEQUENCING_CENTER=Individual

#
# Needed for Picard processing, can be changed on the command line
#

DEFAULT_MAX_THREADS=4

#
# Change at run time
#
DEFAULT_REF=/Users/somalee/Code/NGStools/test/references/e_coli_dh10b.fasta
DEFAULT_READ=/Users/somalee/Code/NGStools/test/ion/BEA-629f.subset.fastq

CWD=`pwd`
echo "CWD=$CWD"

DATE=`date +"%F-%H-%M-%S"`
echo "DATE-TIME=$DATE"
DEFAULT_OUTDIR=$CWD/$DATE/output 

#
# Debug is off by default
#
PREVIEW=0

die() {
	echo $1
	exit -1
}

usage() {
	cat <<EOF

Usage: 
$1 [OPTION]... [--VAR=VALUE]...
To assign environment variables (e.g. REF), specify them as --VAR=<value>

Description: Runs BWASW version of BWA. Accepts a reference and a read file and outputs a BWASW aligned BAM file. Reference file is indexed on the fly. Uses Picard library for sam2bam conversion and samtools for bam file flagstat.

Options:
  --help             display this help message
  --preview          Preview commands instead of doing anything, off my default


Constrained Variables:
  --platform         ION|PACBIO; Default is $DEFAULT_PLATFORM

Required Variables:

  --ref=<string>     [FASTA pathname] Default is $DEFAULT_REF
  --read=<string>    [FASTQ pathname] Default is $DEFAULT_READ
  --out=<sring>      Analysis ouput dir. Default is $DEFAULT_OUTDIR

Optional Variables:

  --punit=<string>   Platform Unit: Default is $DEFAULT_PLATFORM_UNIT
  --rgid=<string>    Read Group ID: Default is $DEFAULT_RGID
  --sname=<string>   Sample Name: Default is $DEFAULT_SAMPLENAME
  --center=<string>  Sequencing Center: Default is $DEFAULT_SEQUENCING_CENTER

  --threads=<int>   Max threads: Default is $DEFAULT_MAX_THREADS

EOF
}
parse_opt() {
	local prev
	local optarg
	local opt

	for opt
	do
		if [ -n "$prev" ]; then
			eval "$prev=\$opt"
			prev=
			continue
		fi

		optarg=`expr "x$opt" : 'x[^=]*=\(.*\)'`
		case $opt in

			--ref | -ref)
				prev=REF ;;
			--ref=* | -ref=* )
				REF=$optarg ;;
			--read | -read)
				prev=READ ;;
			--read=* | -read=* )
				READ=$optarg ;;
			--out | -out)
				prev=OUTDIR ;;
			--out=* | -out=* )
				OUTDIR=$optarg ;;
			--platform | -platform)
				prev=PLATFORM ;;
			--platform=* | -platform=* )
				PLATFORM=$optarg ;;
			--punit | -punit)
				prev=PUNIT ;;
			--punit=* | -punit=* )
				PUNIT=$optarg ;;
			--rgid | -rgid)
				prev=RGID ;;
			--rgid=* | -rgid=* )
				RGID=$optarg ;;
			--sname | -sname)
				prev=SNAME ;;
			--sname=* | -sname=* )
				SNAME=$optarg ;;
			--center | -center)
				prev=CENTER ;;
			--center=* | -center=* )
				CENTER=$optarg ;;
			--threads | -threads)
				prev=THREADS ;;
			--threads=* | -threads=* )
				THREADS=$optarg ;;
			--preview | -preview)
			        PREVIEW=1 ;;
			--help | -help)
				usage $this_prog
				exit
				;;
			-*)
				cat <<EOF
Error: unrecognized option $opt
Try $this_prog --help for more information.

EOF
				exit -1
				;;
		esac
	done
}


function run_setup()
{
    echo "LIBRARY=$DEFAULT_LIBRARY"

    test -n "$PLATFORM" || PLATFORM=$DEFAULT_PLATFORM
    echo "PLATFORM=$PLATFORM"

    if [ $PLATFORM == "PACBIO" ]; then
        echo "PacBio specific bwasw parameters are used"
    elif [ $PLATFORM == "ION" ]; then
        echo "Default bwasw parameters used. There appears to be no recommended parameters for Ion data at this time"
    else
        echo "Platform not supported. Data must be from PACBIO or ION platforms"
        exit 1;
    fi

    test -n "$PUNIT" || PUNIT=$DEFAULT_PLATFORM_UNIT
    echo "PLATFORM_UNIT=$PUNIT"

    test -n "$RGID" || RGID=$DEFAULT_RGID
    echo "RGID=$RGID"

    test -n "$SNAME" || SNAME=$DEFAULT_SAMPLENAME
    echo "SAMPLENAME=$SNAME"

    test -n "$CENTER" || CENTER=$DEFAULT_SEQUENCING_CENTER
    echo "SEQUENCING CENTER=$CENTER"

    test -n "$THREADS" || THREADS=$DEFAULT_MAX_THREADS
    echo "THREADS=$THREADS"

    test -n "$REF" || REF=$DEFAULT_REF
    echo "REFERENCE=$REF"

     if [ ! -f $REF ]; then
	 echo "$REF is not a file.";
	 exit 1;
     else
	 if [ ! -r $REF ]; then
	     echo "$REF is not readable"; 
	     exit 1;
	 fi
     fi
     
     test -n "$READ" || READ=$DEFAULT_READ
     echo "READ=$READ"
     
     if [ ! -f "$READ" ]; then
	 echo "$READ is not a file.";
	 exit 1;
     else
	 if [ ! -r "$READ" ]; then
	     echo "$READ is not readable"; 
	     exit 1;
	 fi	 
     fi
    
     test -n "$OUTDIR" || OUTDIR=$DEFAULT_OUTDIR
     echo "ANALYSISDIR=$OUTDIR"
     
     echo "Creating $OUTDIR"
     cmd="mkdir -p $OUTDIR"
     echo
     echo $cmd
     if [ $PREVIEW = "0" ]; then 
	 eval $cmd || { echo "Command failed"; exit 1; } 
	 
	cmd="pushd $OUTDIR"   #Not sure if the tools will work without this step
	echo $cmd
	eval $cmd || { echo "Command failed"; exit 1; } 

	WD=`pwd`
	echo "WD=$WD"

	#
	# BWA wants to write the reference index file in the reference directory
	# So we need to copy where write permission exists
	#
	NEW_REF=`basename $REF .fasta`".fasta"
	cmd="cp $REF ."
	echo $cmd
	eval $cmd || { echo "Command failed"; exit 1; } 
	REF=$NEW_REF
	echo "NEW REFERENCE=$REF"

	#
	# Book keeping, verbose output 
	#
	cmd="ln -svf \"$READ\" inseq"
	eval $cmd || { echo "Command failed"; exit 1; } 

    fi

}

function run_bwa()
{
    ALIGNMENT_SAM=$1

    #
    # Index the reference file for BWA, Note that this step needs to happen ONLY once per reference. 
    # It takes a short time for small FASTA files and therefore the step is left un-optimized."
    #
    cmd="$BWA index -a bwtsw $REF"
    echo
    echo "Creating BWA reference index files ..."
    echo $cmd
    if [ $PREVIEW = "0" ]; then 
	eval $cmd || { echo "Command failed"; exit 1; } 
    fi

    #
    # -t Number of threads
    # -H hardclip, default is soft
    #
    OPTIONS="bwasw -t $DEFAULT_MAX_THREADS -H"

    #
    # Use options recommended for PacBio
    # -b mismatch penalty
    # -q gap open penalty
    # -r gap extension penalty
    # -z Number of candidates
    #
    if [ $PLATFORM == "PACBIO" ]; then

    OPTIONS="$OPTIONS -b 5 -q 2 -r 1 -z 10"
    fi
    

    cmd="$BWA $OPTIONS $REF \"$READ\" > ${ALIGNMENT_SAM}"
  
    echo
    echo "Running BWA alignment ..."
    echo $cmd
    if [ $PREVIEW = "0" ]; then 
	eval $cmd || { echo "Command failed"; exit 1; } 
    fi
}


function run_map()
{

    ALIGNMENT_SAM=bwa_aln.sam

    run_bwa $ALIGNMENT_SAM

    ALIGNMENT_BAM=bwa_aln.bam

    #
    # SAM2BAM, coordinate sorting, add read group info
    #

    cmd="java -Xmx2g -jar $PICARD_INSTALLATION/AddOrReplaceReadGroups.jar VERBOSITY=DEBUG VALIDATION_STRINGENCY=LENIENT COMPRESSION_LEVEL=5 MAX_RECORDS_IN_RAM=10000 CREATE_INDEX=true CREATE_MD5_FILE=false INPUT=$ALIGNMENT_SAM OUTPUT=$ALIGNMENT_BAM SORT_ORDER=coordinate RGID=$RGID RGLB=$DEFAULT_LIBRARY RGPL=$PLATFORM RGPU=$PUNIT RGSM=$SNAME RGCN=$CENTER"
    
    echo
    echo "Running SAM to BAM conversion; sorting in coordinate order; indexing BAM; adding read group infomation ..."
    echo $cmd
    if [ $PREVIEW = "0" ]; then 
	eval $cmd || { echo "Command failed"; exit 1; } 
    fi

    if [ -f $ALIGNMENT_BAM ]; then
	cmd="$SAMTOOLS flagstat $ALIGNMENT_BAM"
	echo
	echo "Running flagstat ..."
	echo $cmd
	if [ $PREVIEW = "0" ]; then 
	    eval $cmd || { echo "Command failed"; exit 1; } 
	fi
    fi


}

parse_opt $@ && \
run_setup && \
run_map





