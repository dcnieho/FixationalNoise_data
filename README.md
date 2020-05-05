This repository contains the data and analysis code used and developed for the articles:
- Niehorster, D.C., Zemblys, R. & Holmqvist, K. (in press). Is apparent fixational drift in eye-tracking data due to filters or eyeball rotation? Behavior Research Methods
- Niehorster, D.C., Zemblys, R., Beelders, T. & Holmqvist, K. (in press). Characterizing gaze position signals and synthesizing noise during fixations in eye-tracking data. Behavior Research Methods

When using the data or analysis code in this repository, please cite both papers. The fixational eye movement data generator used in Niehorster, Zemblys, Beelders & Holmqvist (in press) can be found [here](https://github.com/dcnieho/FixationalNoise_generator).

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
   - First run `c_makeRInput.m` and then the `R/analyze.r` script. `R/analyze.r` should be run twice, to generate output both for 95th and 99th percentile exclusion criteria. See line 10 in that script.
   - Then execute `d_plotROutput.m` to make the figure.
   - Alternatively, you can directly execute `d_plotROutput.m`, since the output of the `c_makeRInput.m` and the `R/analyze.r` scripts is included in this repository.

Tested on MATLAB R2020a


## Data disclaimer, limitations and conditions of release
By downloading this data set, you expressly agree to the following conditions of release and acknowledge the following disclaimers issued by the authors:

### A. Conditions of Release
Data are available by permission of the authors. Use of data in publications, either digital or hardcopy, must be cited as follows: 
- Niehorster, D.C., Zemblys, R. & Holmqvist, K. (in press). Is apparent fixational drift in eye-tracking data due to filters or eyeball rotation? Behavior Research Methods.
- Niehorster, D.C., Zemblys, R., Beelders, T. & Holmqvist, K. (in press). Characterizing gaze position signals and synthesizing noise during fixations in eye-tracking data. Behavior Research Methods.

### B. Disclaimer of Liability
The authors shall not be held liable for any improper or incorrect use or application of the data provided, and assume no responsibility for the use or application of the data or interpretations based on the data, or information derived from interpretation of the data. In no event shall the authors be liable for any direct, indirect or incidental damage, injury, loss, harm, illness or other damage or injury arising from the release, use or application of these data. This disclaimer of liability applies to any direct, indirect, incidental, exemplary, special or consequential damages or injury, even if advised of the possibility of such damage or injury, including but not limited to those caused by any failure of performance, error, omission, defect, delay in operation or transmission, computer virus, alteration, use, application, analysis or interpretation of data.

### C. Disclaimer of Accuracy of Data
No warranty, expressed or implied, is made regarding the accuracy, adequacy, completeness, reliability or usefulness of any data provided. These data are provided "as is." All warranties of any kind, expressed or implied, including but not limited to fitness for a particular use, freedom from computer viruses, the quality, accuracy or completeness of data or information, and that the use of such data or information will not infringe any patent, intellectual property or proprietary rights of any party, are disclaimed. The user expressly acknowledges that the data may contain some nonconformities, omissions, defects, or errors. The authors do not warrant that the data will meet the user’s needs or expectations, or that all nonconformities, omissions, defects, or errors can or will be corrected. The authors are not inviting reliance on these data, and the user should always verify actual data.
