addpath(genpath('/N/u/brlife/git/vistasoft'))
addpath(genpath('/N/u/brlife/git/encode'))
addpath(genpath('/N/u/brlife/git/jsonlab'))
addpath(genpath('/N/u/brlife/git/spm'))
addpath(genpath('/N/u/brlife/git/wma'))
%mcc -m -R -nodisplay -d compiled main
mcc -m -R -nodisplay -d classification classificationGenerator
exit
