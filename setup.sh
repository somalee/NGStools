#!/bin/bash

#Exit on error immediately
set -e


#If you want a more verbose bash output
#set -x


this_prog=`basename $0`
CWD=`pwd`
echo "CWD=$CWD"

DATE=`date +"%F-%H-%M-%S"`
echo "DATE-TIME=$DATE"

#
# Change the DEFAULT_TOOLSDIR TO YOUR INSTALL HUB
#
DEFAULT_TOOLSDIR=/Users/somalee/Code/3PInstalls

#
# Default GATK installation
#
GATK_INSTALLATION=$DEFAULT_TOOLSDIR/gatk/GenomeAnalysisTK-2.0-39-gd091f72
GATK=$GATK_INSTALLATION/GenomeAnalysisTK.jar
echo "GATK=$GATK"

#
# Default samtools and bcftools installation
#
SAMTOOLS_INSTALLATION=$DEFAULT_TOOLSDIR/samtools/samtools-0.1.18
SAMTOOLS=$SAMTOOLS_INSTALLATION/samtools
echo "SAMTOOLS=$SAMTOOLS"

BCFTOOLS=$SAMTOOLS_INSTALLATION/bcftools/bcftools
echo "BCFTOOLS=$BCFTOOLS"

#
# Default vcftools installation
#
VCFTOOLS=$DEFAULT_TOOLSDIR/vcftools/vcftools_0.1.9/cpp/vcftools
echo "VCFTOOLS=$VCFTOOLS"


#
# Default picard tools
#
PICARD_INSTALLATION=$DEFAULT_TOOLSDIR/picard/picard-tools-1/picard-tools-1.74/
echo "PICARD INSTALLATION = $PICARD_INSTALLATION"

#
# BWA
#
BWA=$DEFAULT_TOOLSDIR/bwa/bwa-0.6.2/bwa
echo "BWA=$BWA"
