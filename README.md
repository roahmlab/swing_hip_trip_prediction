# swing\_hip\_trip\_prediction

This code provides examples of fitting the three different models (Gaussian process regression, NARX, and pendulum) compared in our paper: S. M. Danforth, X. Liu, M. J. Ward, P.D. Holmes, and R. Vasudevan, "Predicting sagittal-plane swing hip kinematics in response to trips," *Robotics and Automation Letters*, 2022.

First, go to <https://doi.org/10.7302/pvhg-q324> to download the 16-subject dataset from University of Michigan's Deep Blue Data.

This repository uses the `swing_phase_data` files in MATLAB to train and test predictive models of swing hip motion. The folder `run_model_fit` contains three scripts (one for each model) where you can load a subject's data, train a model on all trip trials but one, and test the left-out trial. Note you will have to update the `inpath` variable at the beginning of each script depending on where you keep the trip dataset. To fit the models and plot the results, these scripts call functions from the `model_functions` and `tabulate_and_plot_data` folders.

I've also included two other scripts for analyzing the data in `tabulate_and_plot_data`. The first, `count_trip_trials.mat`, produces a table that lists the number of each type of recovery used for each subject. The second, `plot_sorted_heel_positions.mat`, produces a figure of sorted heel AP positions and heights (elevating, delayed lowering, and lowering) for a chosen subject. The latter script provides examples for how to compute an average nominal trial and how to normalize the phase variable from [0,1]. Note that for our paper we used separate phase bounds for each strategy (because elevating trials tend to last longer than delayed lowering and lowering trials), but here we use the same bounds for all in the interest of simplicity.

#### Team

* Shannon Danforth (PhD Candidate, Mechanical Engineering, University of Michigan)
* Xinyi Liu (MS Student, Electrical Engineering and Computer Science, University of Michigan)
* Martin Ward (Research Engineer, Naval Architecture and Marine Engineering, University of Michigan)
* Patrick Holmes (Research Engineer, Mechanical Engineering, University of Michigan)
* Ram Vasudevan (Associate Professor, Mechanical Engineering and Robotics Institute, University of Michigan)
