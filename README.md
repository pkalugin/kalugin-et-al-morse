# kalugin-et-al-morse
Code for MORSE project (Kalugin et al.)

Preprint link: https://www.biorxiv.org/content/10.1101/2025.01.26.634931v2

## Description of contents
1. Motor dipping code for Neurolabware Scanbox two-photon microscope
2. Preprocessing and Cellpose2.0 segmentation of MORSE recordings
3. Deformation quantification
4. Image alignment
5. 3D single-cell mask generation, quality control, signal extraction, and matching cells across probe recordings
6. Single-cell trace analysis and figure generation

## System requirements
The enclosed code has been successfully implemented in Matlab 2023b and python 3.10 running on Windows 10 22H2, Windows Server 2012R2, and Ubuntu 22.04.4 systems. Critical required dependencies in python include [Cellpose2.0](https://github.com/MouseLand/cellpose), [Caiman 10.2](https://github.com/flatironinstitute/CaImAn), and [napari](https://napari.org/stable/). Manual image rotation and anchor point placement was performed using the [BigStitcher](https://imagej.net/plugins/bigstitcher/) and [BigWarp](https://imagej.net/plugins/bigwarp) plugins running in ImageJ 1.54f. GPU acceleration was accomplished on NVIDIA GTX1070, RTX A4000, 3080Ti and 3090.

## Installation guide
We recommend creating a dedicated environment for all component packages using conda. Installation of all dependencies using conda and pip requires ~15 min.

## Instructions for use
The included folders are numbered in the order of the analysis workflow. Specific details of each component are as follows:
1. The Matlab code in this folder is used to control the movement of the motorized microscope objective arm of a Neurolabware Scanbox two-photon microscope. MORSE probe dipping across a 384-well plate as well as tiling across a set of predetermined regions of interest can be achieved.
2. The python code in this folder is used to perform Cellpose2.0 segmentation and probability map determination on MORSE recordings. First, the recording is downsampled by calculating means of sequential groups of imaging volumes across time and saving these as individual TIFF image stacks. Second, the custom Cellpose model (model_1 file) is applied to each of these TIFF stacks to produce probability maps.
3. The Matlab code in this folder is used to calculate deformation fields on the probability maps obtained above using the imregdemons function that calculates an optical flow warp field from each timepoint of each recording to a single reference timepoint.
4. The Matlab code in this folder is used to apply the deformation fields calculated above to the original fluorescence signals of the MORSE recordings, including upsampling of the deformations to the original temporal frequency of the recording. [npy-matlab](https://github.com/kwikteam/npy-matlab) is used to write the outputs in .npy format for downstream analysis in python.
5. The python code in this folder is used to perform activity-based segmentation of the MORSE recordings, quality control and manual correction of resultant 3D cell masks, and matching of masks across multiple recordings of the same probe using thin plate spline warping of manually-determined anchor points with BigWarp. The jupyter notebooks are numbered in the order of their usage, which involves:
  * An initial application of Caiman to determine a first estimate of cell masks from the time-downsampled MORSE recording (subject to SNR and signal brightness thresholds)
  * A GUI to manually curate this first estimate by discarding erroneous masks and merging masks that correspond to different parts of the same cell
  * Another GUI to manually recover masks with low SNR/signal that correspond to true cells and were erroneously discarded
  * A second application of Caiman to refine the curated masks above on the time-downsampled recording, and a GUI to ensure quality control of these outputs
  * A GUI to incorporate BigWarp alignment of several recordings of the same probe and manually confirm correct mask matching between pairs of recordings
  * A final application of Caiman to apply the curated and matched masks to the original MORSE recording at full temporal resolution
6. The python code in this folder is used to analyze the single sensor cell traces derived by the above pipelines and generate the figures and supplementary videos in the manuscript. Each jupyter notebook contains a set of outputs roughly corresponding to individual figures in the paper.
