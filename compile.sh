#!/bin/bash
module load matlab/2017a

mkdir -p compiled
mkdir -p classification

cat > build.m <<END
addpath(genpath('/N/u/brlife/git/vistasoft'))
addpath(genpath('/N/u/brlife/git/encode'))
addpath(genpath('/N/u/brlife/git/jsonlab'))
addpath(genpath('/N/u/brlife/git/spm'))
mcc -m -R -nodisplay -d compiled main
mcc -m -R -nodisplay -d classification classificationGenerator
exit
END
matlab -nodisplay -nosplash -r build
