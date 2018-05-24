function [] = classificationGenerator()

switch getenv('ENV')
    case 'IUHPC'
        disp('loading paths for IUHPC')
        addpath(genpath('/N/u/brlife/git/vistasoft'))
        addpath(genpath('/N/u/brlife/git/jsonlab'))
        addpath(genpath('/N/u/brlife/git/encode'))
        addpath(genpath('/N/u/brlife/git/spm'))
    case 'VM'
        disp('loading paths for Jetstream VM')
        addpath(genpath('/usr/local/vistasoft'))
        addpath(genpath('/usr/local/jsonlab'))
        addpath(genpath('/usr/local/encode'))
        addpath(genpath('/usr/local/spm'))
end

topdir = pwd;
rois=dir('*.tck*');
for ii = 1:length(rois); 
    fgPath{ii} = fullfile(topdir,rois(ii).name);
end

[mergedFG, classification]=bsc_mergeFGandClass(fgPath);
fg_classified = bsc_makeFGsFromClassification(classification,mergedFG);

save('output.mat','classification','fg_classified','-v7.3');

tracts = fg2Array(fg_classified);

mkdir('tracts');

% Make colors for the tracts
%cm = parula(length(tracts));
cm = distinguishable_colors(length(tracts));
for it = 1:length(tracts)
   tract.name   = strrep(tracts(it).name, '_', ' ');
   all_tracts(it).name = strrep(tracts(it).name, '_', ' ');
   all_tracts(it).color = cm(it,:);
   tract.color  = cm(it,:);

   %tract.coords = tracts(it).fibers;
   %pick randomly up to 1000 fibers (pick all if there are less than 1000)
   fiber_count = min(1000, numel(tracts(it).fg.fibers));
   tract.coords = tracts(it).fg.fibers(randperm(fiber_count)); 
   
   savejson('', tract, fullfile('tracts',sprintf('%i.json',it)));
   all_tracts(it).filename = sprintf('%i.json',it);
   clear tract
end

savejson('', all_tracts, fullfile('tracts/tracts.json'));

for i = 1 : length(fg_classified)
    name = fg_classified(i).name;
    num_fibers = length(fg_classified(i).fg.fibers);
    
    fibercounts(i) = num_fibers;
    tract_info{i,1} = name;
    tract_info{i,2} = num_fibers;
end

T = cell2table(tract_info);
T.Properties.VariableNames = {'Tracts', 'FiberCount'};

writetable(T, 'output_fibercounts.txt');


exit;
end



