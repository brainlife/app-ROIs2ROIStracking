#!/bin/bash

## Ilaria Sani - 20180313
## Human Engogenous Attention Network
## (modified after Ilaria Sani - 20170117 - NHP Endogenous Attention Network)
## (modified after Brent McPherson)
## (Modified by Dan Bullock and Soichi Hayashis 20181126)
##
## MRTRIX PRE-PROCESSING (no need for WM mask for humans)
## This script process DTI data with MRTRIX, i.e. prepares the data for tracking
## it also creates a WM mask
## 
## NEEDS:
## 1. $dwi.mif
## 2. grads.b 
## 3. mask.mif 

#make the script to fail if any of the command fails.
set -e

#show commands executed (mainly for debugging)
set -x

########### DEFINE PATHS #####################
export PATH=$PATH:/usr/lib/mrtrix/bin

BGRAD="grad.b"
input_nii_gz=$(jq -r .dwi config.json)
BVALS=$(jq -r .bvals config.json)
BVECS=$(jq -r .bvecs config.json)
fsurfer=`jq -r '.freesurfer' config.json`
NUM=`jq -r '.num_fibers' config.json`
MAXNUM=`jq -r '.max_num' config.json`
STEPSIZE=`jq -r '.stepsize' config.json`
MINLENGTH=`jq -r '.minlength' config.json`
MAXLENGTH=`jq -r '.maxlength' config.json`
NUM_REPETITIONS=`jq -r '.num_repetitions' config.json`
WMMK=wm_mask.mif

#generate grad.b from bvecs/bvals
#load bvals/bvecs
bvals=$(cat $BVALS)
bvecs_x=$(cat $BVECS | head -1)
bvecs_y=$(cat $BVECS | head -2 | tail -1)
bvecs_z=$(cat $BVECS | tail -1)
#convert strings to array of numbers
bvecs_x=($bvecs_x)
bvecs_y=($bvecs_y)
bvecs_z=($bvecs_z)
#output grad.b
i=0
true > grad.b
for bval in $bvals; do
    echo ${bvecs_x[$i]} ${bvecs_y[$i]} ${bvecs_z[$i]} $bval >> grad.b
    i=$((i+1))
done

#if max_lmax is empty, auto calculate
MAXLMAX=`jq -r '.max_lmax' config.json`
if [[ $MAXLMAX == "null" || -z $MAXLMAX ]]; then
    echo "max_lmax is empty... determining which lmax to use from .bvals"
    MAXLMAX=`./calculatelmax.py`
    echo "using MAXLMAX:$MAXLMAX"
fi

if [ ! -f dwi.mif ]; then
    mrconvert $input_nii_gz dwi.mif -quiet
fi

if [ ! -f b0.mif ]; then
    mrconvert mask_anat.nii.gz b0.mif -quiet
fi

if [ ! -f $WMMK ]; then
    mrconvert wm_anat.nii.gz $WMMK -quiet
fi

#roi is either passed in by rois in config.json or generated when parc is set through main
for ROI in $(cat ROIfiles.txt)
do
   mrconvert ${ROI}.nii.gz ${ROI}.mif -quiet
done 

## create a t2-mask from b0
if [ -f mask.mif ]; then
	echo "t2-mask from b0 already exists...skipping"
else
	time average dwi.mif -axis 3 - | threshold - - | median3D - - | median3D - mask.mif
	ret=$?
	if [ ! $ret -eq 0 ]; then
		exit $ret
	fi
fi

## fit diffusion model
if [ -f dt.mif ]; then
	echo "diffusion tensor already exists...skipping"
else
	time dwi2tensor dwi.mif -grad $BGRAD dt.mif
	ret=$?
	if [ ! $ret -eq 0 ]; then
		exit $ret
	fi
fi

## create FA image
if [ -f fa.mif ]; then
	echo "FA image already exists...skipping"
else
	time tensor2FA dt.mif - | mrmult - mask.mif fa.mif
	ret=$?
	if [ ! $ret -eq 0 ]; then
		exit $ret
	fi
fi

## create rgb eingenvectors
if [ -f ev.mif ]; then
	echo "RGB eigenvectors already exists...skipping"
else
	time tensor2vector dt.mif - | mrmult - mask.mif ev.mif
	if [ ! $ret -eq 0 ]; then
		exit $ret
	fi
fi

## create single fiber mask
if [ -f sf.mif ]; then
	echo "Single fiber mask already exists...skipping"
else
	time erode mask.mif -npass 3 - | mrmult fa.mif - - | threshold - -abs 0.7 sf.mif
	if [ ! $ret -eq 0 ]; then
		exit $ret
	fi
fi

## create response numbers for CSD fit
for (( i_lmax=2; i_lmax<=$MAXLMAX; i_lmax+=2 )); do
	if [ -f response${i_lmax}.txt ]; then
    		echo "response${i_lmax}.txt already exist... skipping"
	else
    	time estimate_response -quiet dwi.mif sf.mif -grad $BGRAD -lmax $i_lmax response${i_lmax}.txt
    	ret=$?
    	if [ ! $ret -eq 0 ]; then
        exit $ret
    	fi
	fi
done

## fit csd model
for (( i_lmax=2; i_lmax<=$MAXLMAX; i_lmax+=2 )); do
# Perform CSD in each white matter voxel
	lmaxout=csd${i_lmax}.mif
	if [ -s $lmaxout ]; then
		echo "$lmaxout already exist - skipping csdeconv"
	else
		time csdeconv -quiet dwi.mif -grad $BGRAD response${i_lmax}.txt -lmax $i_lmax -mask mask.mif $lmaxout
		ret=$?
		if [ ! $ret -eq 0 ]; then
			exit $ret
		fi
	fi
done

################# ROI2ROI TRACKING ############################

# convert text list
ROIfilesString=`cat ROIfiles.txt`
SAVEIFS=$IFS
IFS='
'
ROISList=($ROIfilesString)

nTracts=$(ls rois/*.mif | wc -l)
for (( i=0; i<=$nTracts; i+=2 )); do
    for i_tratk in $(seq $NUM_REPETITIONS); do
        echo ${i_track}
        for (( i_lmax=2; i_lmax<=$MAXLMAX; i_lmax+=2 )); do
            for curv in 0.5 1 2 3 4; do
                out=tract$((i/2+1))_lmax${i_lmax}_crv${curv}_${i_track}.tck
                timeout 3600 streamtrack -quiet SD_PROB csd${i_lmax}.mif tmp.tck \
                    -mask $WMMK \
                    -grad $BGRAD \
                    -number $NUM \
                    -maxnum $MAXNUM \
                    -curvature $curv \
                    -step $STEPSIZE \
                    -minlength $MINLENGTH \
                    -length $MAXLENGTH \
                    -seed ${ROISList[$((i))]}.mif \
                    -include ${ROISList[$((i))]}.mif \
                    -include ${ROISList[$((i+1))]}.mif \
                    -stop
                mv tmp.tck $out
            done
        done
     done
    ## concatenate tracts

    prefix=tract$((i/2+1))
    echo prefix
    paramSweepTracks=$(ls *${prefix}*.tck )
    echo paramSweepTracks
    cat_tracks ${prefix}.tck $(ls *${prefix}*.tck | head -1) $(ls *${prefix}*.tck | tail -n+2)
    if [ ! $ret -eq 0 ]; then
        exit $ret
    fi
    rm -rf ${holder[*]}
    ## tract info
    track_info tract$((i/2+1)).tck > track_info$((i/2+1)).txt
    if [[ $((i/2+1)) == 1 ]];then
        mv track_info$((i/2+1)).txt track_info.txt
    fi
    
done
IFS=$SAVEIFS
################# CREATE CLASSIFICATION STRUCTURE ###############
./compiled/classificationNamesGenerator

################# CLEANUP #######################################
rm -rf *.mif*
rm -rf grad.b
rm -rf *response*.txt
rm -rf *.nii.gz

