[![Run on Brainlife.io](https://img.shields.io/badge/Brainlife-bl.app.1-blue.svg)](https://doi.org/10.25663/bl.app.1)

# app-roi2roitracking
This app will perform ensemble tracking between 2 or more cortical regions of interest (ROIs) from either a freesurfer parcellation or an atlas parcellation. First, the ROIs are registered to diffusion space using Freesurfer's mri_label2vol, and a white matter mask is generated in diffusion space, by running the create_wm_mask script. Then, tracking will be performed using mrtrix/0.2.12 by running the trackROI2ROI script. Finally, a classification structure will be generated using Vistasoft's bsc_mergeFGandClass and bsc_makeFGsFromClassification functions by running the classificationGenerator script.

#### Authors
- Brad Caron (bacaron@iu.edu)
- Ilaria Sani (isani01@rockefeller.edu)
- Soichi Hayashi (hayashi@iu.edu)
- Franco Pestilli (franpest@indiana.edu)

## Running the App 

### On Brainlife.io

You can submit this App online at [https://doi.org/10.25663/bl.app.37](https://doi.org/10.25663/bl.app.37 via the "Execute" tab.

### Running Locally (on your machine)

1. git clone this repo.
2. Inside the cloned directory, create `config.json` with something like the following content with paths to your input files.

```json
{
        "parcellation": "./input/parc/",
        "dtiinit": "./input/dtiinit/",
        "fsurfer": "./input/freesurfer/",
        "roiPair": "45,54",      
        "num_fibers": 500000,
        "max_num": 1000000,
        "stepsize": 0.2,
        "minlength": 10,
        "maxlength": 200,
        "num_repetitions": 1
}
```

### Sample Datasets

You can download sample datasets from Brainlife using [Brainlife CLI](https://github.com/brain-life/cli).

```
npm install -g brainlife
bl login
mkdir input
bl dataset download 5b4b8e1c58153f004fc0862f && mv 5b4b8e1c58153f004fc0862f input/parcellation
bl dataset download 5a14f50eeb00be0031340619 && mv 5a14f50eeb00be0031340619 input/dtiinit
bl dataset download 5a169eea143e7c00bdcf3b5e && mv 5a169eea143e7c00bdcf3b5e input/freesurfer

```


3. Launch the App by executing `main`

```bash
./main
```

## Output

The main outputs of this App is a 'track.tck' file, a folder called 'tracts' containing .json files for each tract, an 'output.mat' containing the classification structure, and a text file called 'output_fibercounts.txt' which contains information regarding the number of streamlines in each tract.

#### Product.json
The secondary output of this app is `product.json`. This file allows web interfaces, DB and API calls on the results of the processing. 

### Dependencies

This App requires the following libraries when run locally.

  - singularity: https://singularity.lbl.gov/
  - VISTASOFT: https://github.com/vistalab/vistasoft/
  - ENCODE: https://github.com/brain-life/encode
  - SPM 8 or 12
  - WMA: https://github.com/brain-life/wma
  - Freesurfer: https://hub.docker.com/r/brainlife/freesurfer/tags/6.0.0
  - mrtrix: https://hub.docker.com/r/brainlife/mrtrix_on_mcr/tags/1.0
  - jsonlab: https://github.com/fangq/jsonlab.git
