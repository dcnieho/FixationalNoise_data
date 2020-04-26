This repository contains the data and analysis code used and developed for the articles:
- Niehorster, D.C., Zemblys, R. & Holmqvist, K. (under review). Is apparent fixational drift in eye-tracking data due to filters or eyeball rotation? Behavior Research Methods
- Niehorster, D.C., Zemblys, R., Beelders, T. & Holmqvist, K. (in press). Characterizing gaze position signals and synthesizing noise during fixations in eye-tracking data. Behavior Research Methods

When using the data in this repository, please cite both papers. The fixational eye movement data generator using in Niehorster, D.C., Zemblys, R., Beelders, T. & Holmqvist, K. (in press) can be found [here](https://github.com/dcnieho/FixationalNoise_generator).

For more information or questions, e-mail: dcnieho@gmail.com. The latest version of this repository is available
from www.github.com/dcnieho/FixationalNoise_data

The algorithms in this repository are licensed under the Creative Commons Attribution 4.0 (CC BY 4.0) license. The data are licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 4.0 (CC NC-BY-SA 4.0) license.

To generate the data-based figures in the above two papers, run the following scripts in order:
1. `a_makeWindows_AE.m` and `a_makeWindows_human.m`.
2. `b_processWindows.m`.
3. Plots are then made with:
   - `c_makePlots_AE.m`;
   - `c_makePlots_human.m`; and
   - `c_makePlots_humanAndAE.m`.
4. Tables are then made with:
   - `c_makeTables.m`.
5. To generate Figure 8 in Niehorster, Zemblys, Beelders & Holmqvist (in press):
   - First run `c_makeRInput.m` and then the `R/anal.r` script. `R/anal.r` should be run twice, to generate output both for 95th and 99th percentile exclusion criteria. See line 10 in that script.
   - Then execute `d_plotROutput.m` to make the figure.
   - Alternatively, you can directly execute `d_plotROutput.m`, since the output of the `c_makeRInput.m` and the `R/anal.r` scripts is included in this repository.

Tested on MATLAB R2020a
