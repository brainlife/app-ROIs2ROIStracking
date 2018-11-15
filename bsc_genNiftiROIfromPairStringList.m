function bsc_genNiftiROIfromPairStringList(atlas,ROIstring, smoothKernel)
% bsc_genNiftiROIfromStringList(atlas,ROIstring, smoothKernel)
%
% Given a string list of rois (in the specified format) loops over
% the list and generates nifti ROI files for each 
%
%  INPUTS:
%  -atlas: path to an atlas or an atlas.
%
%  -ROIstring:  a string list of atlas based roi specifications from the
%  atlas that you would like merged into a single ROI.  eg: '2 56 30 54; 34
%  654 \n 25 45 56; 23 \n 456 34; 35 75'.  Must correspond to the values in
%  the atlas nifti itself.
%
%  OUTPUTS: none.  Saves down the niftis.  NOTE SAVES DOWN THE NIFTIS AS
%  ROI1 ROI2 ROI3 Etc.  Ignores origional naming convention.  Subsequent
%  steps must separately keep track of this.
%
%  NOTE:  Makes a call to mri_convert, so requires that FreeSurfer be
%  installed and set up properly.
%
%  (C) Daniel Bullock 2018 Bloomington, Indiana

if ~isdeployed
    addpath(genpath('/N/u/brlife/git/jsonlab'))
    addpath(genpath('/N/u/brlife/git/vistasoft'))
    addpath(genpath('/N/u/brlife/git/wma_tools'))
end

config=loadjson('config.json')
atlas=config.atlas;
smoothKernel=config.smoothKernel;
ROIstring=config.roiPairs;
atlas=niftiRead(atlas);

fprintf('Generating ROIs for the following indicies: \n %s',ROIstring);
stringCells = splitlines(ROIstring);

for iROIs=1:length(stringCells)
    ROInums=str2num(stringCells{iROIs});
    %% run the merge roi function
    [mergedROI] =bsc_roiFromAtlasNums(atlas,ROInums, smoothKernel);
    
    %% save it and ouput the nii and name
    currROIName=strcat('/roi/ROI',num2str(iROIs));
    [~, ~]=dtiRoiNiftiFromMat (mergedROI,atlas,currROIName,smoothKernel);
end
end

