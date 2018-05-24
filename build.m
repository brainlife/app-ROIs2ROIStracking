addpath(genpath('/N/u/brlife/git/vistasoft'))
addpath(genpath('/N/u/brlife/git/encode'))
addpath(genpath('/N/u/brlife/git/jsonlab'))
addpath(genpath('/N/u/brlife/git/spm'))
mcc -m -R -nodisplay -d compiled main
mcc -m -R -nodisplay -d classification classificationGenerator
mcc -m -R -nodisplay -d ROI roiGeneration
exit
