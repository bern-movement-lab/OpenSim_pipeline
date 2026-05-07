# OpenSim_pipeline
OpenSim_pipeline is a complete analysis pipeline for processing subject data.

OpenSim_pipeline loads subject data captured with the vicon motion capture system. It builds subject-specific OpenSim models, and runs inverse kinematics (IK), inverse dynamics (ID), JointReaction (JRA) and Static optimization (SO) simulations. The results are exported to .csv files for further analysis.

# Installation
Install the environment and the all dependencies.
## Environment

### Matlab
MATLAB is a programming and numeric computing platform. Install MATLAB according to this default procedure:

https://ch.mathworks.com/help/install/ug/install-products-with-internet-connection.html

#### Required Matlab Toolboxes

- Robotics System Toolbox
- Statistics and Machine Learning Toolbox
- Signal Processing Toolbox

### OpenSim
OpenSim is an open-source musculoskeletal modeling and simulation software. Install it and configure the OpenSim scripting environment as it is descriebed in that article: 

(https://opensimconfluence.atlassian.net/wiki/spaces/OpenSim/pages/53089380/Scripting+with+Matlab)

## Required dependencies
### mat2os 
MAT2OS is the interface between MATLAB and OpenSim.
- **intern (GitLab)**:   https://gitlab.ti.bfh.ch/raubc2/mat2os
- **public (GitHub)**:   https://github.com/bern-movement-lab/mat2os

### tlsm 
TLSM (Thoracolumbar Spine Model) performs model building and simulation tasks.
- **intern (GitLab)**:     https://gitlab.ti.bfh.ch/raubc2/tlsm
- **public (GitHub)**:     https://github.com/bern-movement-lab/tlsm

### ezc3d
EZC3D is a reader written in C++ with binders for MATLAB. Install it according to the description for the right operating system.

- **Github**: https://github.com/pyomeca/ezc3d 

# How to use
1. Modify **"partload_pipeline_configuration.xml"** according to your needs
    - **subjects**: A list of subjects you want to simulate
    - **session**: A list of sessions you want to simulate
    - **inputPath**: The path to the folder where the data of your subjects are stored
    - **outputDir**: The path to the folder where you want to save the results
    - **dependencies**: The locations of the repositories of the dependencies
2. Open & run **"partload_pipeline.m"**

## Inputs
The input files are c3d files from the Vicon motion capture system in the structure as followed:

```
<input directory>/
├── <subject>/
        ├── <condition>/
                ├── file_1.c3d
                ├── file_2.c3d
                └── ...
```

## Outputs
```
partload-opensim/
    └── <subject>/
        ├── model/
        │   ├── Geometry/
        │   └── model files ...
        └── walk/
            └── <condition>/
                ├── input files/            <-- .mat / .mot / .trc
                ├── setup files/            <-- .xml            
                ├── InverseKinematics (IK)  <-- .csv / .log / .mot
                ├── InverseDynamics (ID)    <-- .csv / .log / .sto
                ├── JointReaction (JRA)     <-- .csv / .log / .sto
                └── StaticOptimization (SO) <-- .csv / .log / .sto /.xml

```

# How to contribute 
You are very welcome to contribute to the project, whether you are an external contributor or an internal member of the BFH.

## Guideline for Commit Messages
Commit code, must be any of the following:

    INI: Initialization: Add existing files to a repository. Normally only used for initialization.
    ENH: Enhancement: Add, improve, or remove functionality; change application behavior.
    FIX: Bugfix: Fix something that does not work correctly.
    STY: Style: Minor cosmetic changes to code (ie rename variables for clarify) that does not change the behavior of the code
    REF: Refactor: improve code organization or implementation for maintainability purposes. Also does not change behavior of code
    DOC: Documentation: documentation only change (source code or user documentation)
    TST: Test: adding or changing a test; does not affect application behavior

## Git structure
Set up your git structure as multi-remote on your local repository as described below.
#### mat2os (partial mirroring of the master branch)
        remote
        origin  git@gitlab.ti.bfh.ch:raubc2/mat2os.git (fetch)
        origin  git@gitlab.ti.bfh.ch:raubc2/mat2os.git (push)
        public  git@github.com:bern-movement-lab/mat2os.git (fetch)
        public  git@github.com:bern-movement-lab/mat2os.git (push)


		
#### tlsm (partial mirroring of the main branch)
        remote
        origin  git@gitlab.ti.bfh.ch:raubc2/tlsm.git (fetch)
        origin  git@gitlab.ti.bfh.ch:raubc2/tlsm.git (push)
        public  git@github.com:bern-movement-lab/tlsm (fetch)
        public  git@github.com:bern-movement-lab/tlsm (push)
		
		
#### partload (Subtree split with multi-remote setup)
        remote
		origin  git@gitlab.ti.bfh.ch:pateibe/research-projects/partload.git (fetch)
		origin  git@gitlab.ti.bfh.ch:pateibe/research-projects/partload.git (push)
		public  git@github.com:bern-movement-lab/OpenSim_pipeline.git (fetch)
		public  git@github.com:bern-movement-lab/OpenSim_pipeline.git (push)		



## Workflow contribution (OpenSim_pipeline)
- Work primariliy on **GitLab** `origin/main`, this is the source of truth
- Full development happens here
- May contain private/internal code
- "**OpenSim_Pipeline**"  is a subfolder of the main project "**partload**"

### Workflow Internal Contributors
1. Develop internally
    - creat feature branch
    - implement changes
    - merge into `origin/main`
2. Export internal subtree to public repository with temporary generated branch
    - `git subtree split --prefix=OpenSim_pipeline -b public-sync`
    - `git push -f public public-sync`
3. Create public Pull Request (PR)
    - Open PR on Github `public-sync → public/main`
    - Review on Github
4. Merge into public repository
    - Merge PR into public/main on Github
5. Delete temporary remote branch
    - `git push public --delete public-sync`

### Workflow external Contributors

1. External contributor opens PR
    - `fork -> feature branch -> PR to public/main`
2. PR will be reviewed and merged 



## Authors & Contributors

### Core Authors

- Lukas Connolly
- Marco Senteler
- Cedric Rauber
- Philippe Baehler

### Contributors

- Jana Ender
- [Michael Streit](https://github.com/1michaelstreit)
- [Patric Eichelberger](https://github.com/pelberger)

