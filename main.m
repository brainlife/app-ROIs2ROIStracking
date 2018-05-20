function [] = main()

if ~isdeployed
    switch getenv('ENV')
    case 'IUHPC'
        disp('loading paths (HPC)')
        addpath(genpath('/N/u/brlife/git/encode'))
        addpath(genpath('/N/u/brlife/git/vistasoft'))
        addpath(genpath('/N/u/brlife/git/jsonlab'))
    case 'VM'
        disp('loading paths (VM)')
        addpath(genpath('/usr/local/encode-mexed'))
        addpath(genpath('/usr/local/vistasoft'))
        addpath(genpath('/usr/local/jsonlab'))
    end
end

disp('running')
config = loadjson('config.json');
dt6config = loadjson(fullfile(config.dtiinit, '/dt6.json'));

%% Create an MRTRIX .b file from the bvals/bvecs of the shell chosen to run
mrtrix_bfileFromBvecs(fullfile(config.dtiinit,dt6config.files.alignedDwBvecs), fullfile(config.dtiinit,dt6config.files.alignedDwBvals), 'grad.b');
exit;
end
