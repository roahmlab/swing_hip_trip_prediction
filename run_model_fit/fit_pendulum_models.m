%fit_pendulum_models

%Written by Shannon Danforth, 2022
%Load swing_phase_data and train three pendulum models 
%(elevating, delayed lowering, lowering) on all trials except one left-out trial.
%Then, simulate the left-out trial and compare to the ground truth.

clear;
close all;

%Specify the subject to fit (Subject000 - Subject015):
subject_name = 'Subject000';

%Define an 'inpath' variable where your data folder is located.
inpath = '~/Documents/deep_blue_data';

%Load the swing_phase_data for this subject.
load( sprintf( '%s/%s/swing_phase_data.mat', inpath, subject_name ) );

%Some parameters
n_points_for_interpolation = 100;

%% Get the minimum and maximum swing phase values across all tripped data.
% We'll use these values to normalize our phase variable to [0, 1].
min_phase_all = [];
max_phase_all = [];
%Loop through tripped trials:
for trial_idx = 1:length(swing_phase_data.tripped)
    %Get this trial's min and max phase values.
    min_phase_tmp = min(swing_phase_data.tripped{trial_idx}.phase);
    max_phase_tmp = max(swing_phase_data.tripped{trial_idx}.phase);
    %add them to arrays.
    min_phase_all = [min_phase_all; min_phase_tmp];
    max_phase_all = [max_phase_all; max_phase_tmp];
end
%find min and max of the arrays.
min_phase = min(min_phase_all);
max_phase = max(max_phase_all);
bounds.min_phase = min_phase;
bounds.max_phase = max_phase;
%(Note, in our "Predicting swing hip kinematics" paper, we find separate
%phase bounds for each recovery strategy. Here, we find one set of bounds
%for the entire dataset.)

%% Form three separate datasets corresponding to each strategy.
elev_dataset = [];
dl_dataset = [];
lower_dataset = [];
for trial_idx = 1:length(swing_phase_data.tripped)

    tmp_trial = swing_phase_data.tripped(trial_idx);
    tmp_recovery_type = swing_phase_data.tripped{trial_idx}.recovery_type;

    if strcmp( tmp_recovery_type, 'elevating' )
        elev_dataset = [elev_dataset; tmp_trial];
    elseif strcmp( tmp_recovery_type, 'delayed lowering' )
        dl_dataset = [dl_dataset; tmp_trial];
    elseif strcmp( tmp_recovery_type, 'lowering' )
        lower_dataset = [lower_dataset; tmp_trial];
    end

end

%Next, load subject parameters.
load( sprintf( '%s_info.mat', subject_name ) );
M = subject_info.mass;
H = subject_info.height;

%Parameters based on Winter anthropometric data:
params.m1 = 2*0.05*M + 0.497*M + 0.081*M;
params.m2 = 0.161*M;
params.l = 0.530*H - 0.285*H;
params.g = 9.81;

%% Fit the pendulum models.
%ELEVATING:
%First, check if there is more than one trial
if length(elev_dataset) > 1

    %Pick one trial to test, and train on the rest.
    test_idx = randi( [1 length(elev_dataset)], 1, 1 );
    train_idxs = setdiff( 1:length(elev_dataset), test_idx )';

    %Get the mean trajectories from the training dataset.
    [mean_elev, d_mean_elev] = get_pendulum_avg_states( elev_dataset(train_idxs), bounds, n_points_for_interpolation );
    mean_trajs.position = mean_elev;
    mean_trajs.velocity = d_mean_elev;

    disp('Fitting Elevating Pendulum Gains');
    K_elev = get_pendulum_opt_K( elev_dataset(train_idxs), bounds, params, mean_trajs );

    %Now, get our test trajectory
    pert_idxs = elev_dataset{test_idx}.pert_idxs;
    x_hip_all = [ elev_dataset{test_idx}.swing_hip_AP, elev_dataset{test_idx}.swing_hip_height, elev_dataset{test_idx}.swing_hip_flex_ext ];
    t_all = elev_dataset{test_idx}.phase;
    t_all = (t_all - bounds.min_phase)/(bounds.max_phase - bounds.min_phase);

    %differentiate to get velocity
    dt = t_all(2) - t_all(1);
    d_ap = ddt( x_hip_all(:, 1), dt );
    d_height = ddt( x_hip_all(:, 2), dt );
    d_angle = ddt( x_hip_all(:, 3), dt );
    
    %simulation starts right when trip occurs:
    ic = [ x_hip_all(pert_idxs(1),1), d_ap(pert_idxs(1)),...
        x_hip_all(pert_idxs(1),2), d_height(pert_idxs(1)),...
        x_hip_all(pert_idxs(1),3), d_angle(pert_idxs(1))];
    t = t_all( pert_idxs(1):end );

    [tsim, xsim, ~] = sim_pendulum_model( params, K_elev, ic, t, mean_trajs );

    %Plot.
    fig_num = 1;
    plot_pendulum_comparison( tsim, xsim, t_all, x_hip_all, t, ic, fig_num, 'Elevating' );

end

%DELAYED:
%First, check if there is more than one trial
if length(dl_dataset) > 1

    %Pick one trial to test, and train on the rest.
    test_idx = randi( [1 length(dl_dataset)], 1, 1 );
    train_idxs = setdiff( 1:length(dl_dataset), test_idx )';

    %Get the mean trajectories from the training dataset.
    [mean_dl, d_mean_dl] = get_pendulum_avg_states( dl_dataset(train_idxs), bounds, n_points_for_interpolation );
    mean_trajs.position = mean_dl;
    mean_trajs.velocity = d_mean_dl;

    disp('Fitting Delayed Lowering Pendulum Gains');
    K_dl = get_pendulum_opt_K( dl_dataset(train_idxs), bounds, params, mean_trajs );

    %Now, get our test trajectory
    pert_idxs = dl_dataset{test_idx}.pert_idxs;
    x_hip_all = [ dl_dataset{test_idx}.swing_hip_AP, dl_dataset{test_idx}.swing_hip_height, dl_dataset{test_idx}.swing_hip_flex_ext ];
    t_all = dl_dataset{test_idx}.phase;
    t_all = (t_all - bounds.min_phase)/(bounds.max_phase - bounds.min_phase);

    %differentiate to get velocity
    dt = t_all(2) - t_all(1);
    d_ap = ddt( x_hip_all(:, 1), dt );
    d_height = ddt( x_hip_all(:, 2), dt );
    d_angle = ddt( x_hip_all(:, 3), dt );
    
    %simulation starts right when trip occurs:
    ic = [ x_hip_all(pert_idxs(1),1), d_ap(pert_idxs(1)),...
        x_hip_all(pert_idxs(1),2), d_height(pert_idxs(1)),...
        x_hip_all(pert_idxs(1),3), d_angle(pert_idxs(1))];
    t = t_all( pert_idxs(1):end );

    [tsim, xsim, ~] = sim_pendulum_model( params, K_dl, ic, t, mean_trajs );

    %Plot.
    fig_num = 2;
    plot_pendulum_comparison( tsim, xsim, t_all, x_hip_all, t, ic, fig_num, 'Delayed Lowering' );

end

%LOWERING:
%First, check if there is more than one trial
if length(lower_dataset) > 1

    %Pick one trial to test, and train on the rest.
    test_idx = randi( [1 length(lower_dataset)], 1, 1 );
    train_idxs = setdiff( 1:length(lower_dataset), test_idx )';

    %Get the mean trajectories from the training dataset.
    [mean_lower, d_mean_lower] = get_pendulum_avg_states( lower_dataset(train_idxs), bounds, n_points_for_interpolation );
    mean_trajs.position = mean_lower;
    mean_trajs.velocity = d_mean_lower;

    disp('Fitting Lowering Pendulum Gains');
    K_dl = get_pendulum_opt_K( lower_dataset(train_idxs), bounds, params, mean_trajs );

    %Now, get our test trajectory
    pert_idxs = lower_dataset{test_idx}.pert_idxs;
    x_hip_all = [ lower_dataset{test_idx}.swing_hip_AP, lower_dataset{test_idx}.swing_hip_height, lower_dataset{test_idx}.swing_hip_flex_ext ];
    t_all = lower_dataset{test_idx}.phase;
    t_all = (t_all - bounds.min_phase)/(bounds.max_phase - bounds.min_phase);

    %differentiate to get velocity
    dt = t_all(2) - t_all(1);
    d_ap = ddt( x_hip_all(:, 1), dt );
    d_height = ddt( x_hip_all(:, 2), dt );
    d_angle = ddt( x_hip_all(:, 3), dt );
    
    %simulation starts right when trip occurs:
    ic = [ x_hip_all(pert_idxs(1),1), d_ap(pert_idxs(1)),...
        x_hip_all(pert_idxs(1),2), d_height(pert_idxs(1)),...
        x_hip_all(pert_idxs(1),3), d_angle(pert_idxs(1))];
    t = t_all( pert_idxs(1):end );

    [tsim, xsim, ~] = sim_pendulum_model( params, K_dl, ic, t, mean_trajs );

    %Plot.
    fig_num = 3;
    plot_pendulum_comparison( tsim, xsim, t_all, x_hip_all, t, ic, fig_num, 'Lowering' );

end