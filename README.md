# HPC Nextflow / nf-core Pipeline Setup

This repository provides instructions for setting up and running Nextflow-based nf-core pipelines on a High-Performance Computing (HPC) system. The setup process has been tailored for UCLA's Hoffman2 cluster. However, SGE clusters will follow similar installation steps. Alternatively, use the bash setup file for a more straightforward setup.

If you find this documentation useful, please consider leaving feedback!

## Prerequisites

- HPC Access: Ensure you have valid login credentials and the necessary permissions.


## Setup File Execution
Step 1: Login and spin up a node on your cluster
```
qrsh -l h_data=15G,h_rt=3:00:00,h_vmem=4G -pe shared 4
```
<br />Step 2: Upload the nextflow_setup.sh file to the desired directory
<br />Step 3: cd into the directory where the nextflow_setup.sh bash script lives
<br />Step 4: Execute the bash script by running the following code
```
bash nextflow_setup.sh
```
