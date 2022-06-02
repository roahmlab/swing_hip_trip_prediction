%fit_GPR_models

%Written by Shannon Danforth and Xinyi Liu, 2022
%Load swing_phase_data and train three multi-output GPR models 
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

conf_interval = 95; %Confidence interval for GPR model
n_points_for_interpolation = 100; %Number of points to re-sample our data
num_pts = 15; %Max number of points to condition prediction on.

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
%% Fit the GPR models.

%ELEVATING:
%First, check if there is more than one trial
if length(elev_dataset) > 1

    %Pick one trial to test, and train on the rest.
    test_idx = randi( [1 length(elev_dataset)], 1, 1 );
    train_idxs = setdiff( 1:length(elev_dataset), test_idx )';

    disp('Computing Elevating GPR Parameters');

    %Solve an fmincon problem to find the best parameter values.
    params = get_optimal_GPR_params( elev_dataset(train_idxs), bounds, conf_interval, n_points_for_interpolation, num_pts );

    %Define parameters for model from output:
    noise_params = params(1:3); 
    scale_params = params(4:6); 
    alpha = params(7); 
    l = params(8);
    rel_coefs = params(9:11);

    %get GPR model using these parameters:
    elevating_GPR_model = get_GPR_model( elev_dataset(train_idxs), bounds, conf_interval, noise_params, scale_params, alpha, l, rel_coefs );

    %Simulate and plot the left-out trial.
    %Get the hip states for this training trial.
    xx_hip_all = [ elev_dataset{test_idx}.swing_hip_AP,...
        elev_dataset{test_idx}.swing_hip_height,...
        elev_dataset{test_idx}.swing_hip_flex_ext ];
    %Get the post-trip-onset indices.
    pert_idxs = elev_dataset{test_idx}.pert_idxs;
    %Phase values:
    tt_all = elev_dataset{test_idx}.phase;
    %Now, scale the phase based on our phase bounds:
    tt_all = (tt_all - bounds.min_phase)./(bounds.max_phase - bounds.min_phase);
    
    %We want to simulate from the start of the perturbation:
    t_pert_start = tt_all(pert_idxs(1));

    %Interpolate the phase and hip states to have n_points points:
    t_all = interp1(linspace(0, 1, length(tt_all)), tt_all, linspace(0, 1,...
        n_points_for_interpolation));
    x_hip_all = interp1(tt_all, xx_hip_all, t_all);

    %Get the conditional prediction for this trial:
    [elevating_GPR_model, comparison_data] = get_GPR_conditional_prediction( elevating_GPR_model,...
        t_all, x_hip_all, t_pert_start, num_pts, conf_interval );

    %Plot.
    fig_num = 1;
    plot_GPR_comparison( elevating_GPR_model, comparison_data, 'elevating',...
        fig_num );

end

%DELAYED LOWERING:
%First, check if there is more than one trial
if length(dl_dataset) > 1

    %Pick one trial to test, and train on the rest.
    test_idx = randi( [1 length(dl_dataset)], 1, 1 );
    train_idxs = setdiff( 1:length(dl_dataset), test_idx )';

    disp('Computing Delayed Lowering GPR Parameters');

    %Solve an fmincon problem to find the best parameter values.
    params = get_optimal_GPR_params( dl_dataset(train_idxs), bounds, conf_interval, n_points_for_interpolation, num_pts );

    %Define parameters for model from output:
    noise_params = params(1:3); 
    scale_params = params(4:6); 
    alpha = params(7); 
    l = params(8);
    rel_coefs = params(9:11);

    %get GPR model using these parameters:
    dl_GPR_model = get_GPR_model( dl_dataset(train_idxs), bounds, conf_interval, noise_params, scale_params, alpha, l, rel_coefs );

    %Simulate and plot the left-out trial.
    %Get the hip states for this training trial.
    xx_hip_all = [ dl_dataset{test_idx}.swing_hip_AP,...
        dl_dataset{test_idx}.swing_hip_height,...
        dl_dataset{test_idx}.swing_hip_flex_ext ];
    %Get the post-trip-onset indices.
    pert_idxs = dl_dataset{test_idx}.pert_idxs;
    %Phase values:
    tt_all = dl_dataset{test_idx}.phase;
    %Now, scale the phase based on our phase bounds:
    tt_all = (tt_all - bounds.min_phase)./(bounds.max_phase - bounds.min_phase);
    
    %We want to simulate from the start of the perturbation:
    t_pert_start = tt_all(pert_idxs(1));

    %Interpolate the phase and hip states to have n_points points:
    t_all = interp1(linspace(0, 1, length(tt_all)), tt_all, linspace(0, 1,...
        n_points_for_interpolation));
    x_hip_all = interp1(tt_all, xx_hip_all, t_all);

    %Get the conditional prediction for this trial:
    [dl_GPR_model, comparison_data] = get_GPR_conditional_prediction( dl_GPR_model,...
        t_all, x_hip_all, t_pert_start, num_pts, conf_interval );

    %Plot.
    fig_num = 2;
    plot_GPR_comparison( dl_GPR_model, comparison_data, 'delayed lowering',...
        fig_num );

end

%LOWERING:
%First, check if there is more than one trial
if length(lower_dataset) > 1

    %Pick one trial to test, and train on the rest.
    test_idx = randi( [1 length(lower_dataset)], 1, 1 );
    train_idxs = setdiff( 1:length(lower_dataset), test_idx )';

    disp('Computing Lowering GPR Parameters');

    %Solve an fmincon problem to find the best parameter values.
    params = get_optimal_GPR_params( lower_dataset(train_idxs), bounds, conf_interval, n_points_for_interpolation, num_pts );

    %Define parameters for model from output:
    noise_params = params(1:3); 
    scale_params = params(4:6); 
    alpha = params(7); 
    l = params(8);
    rel_coefs = params(9:11);

    %get GPR model using these parameters:
    lowering_GPR_model = get_GPR_model( lower_dataset(train_idxs), bounds, conf_interval, noise_params, scale_params, alpha, l, rel_coefs );

    %Simulate and plot the left-out trial.
    %Get the hip states for this training trial.
    xx_hip_all = [ lower_dataset{test_idx}.swing_hip_AP,...
        lower_dataset{test_idx}.swing_hip_height,...
        lower_dataset{test_idx}.swing_hip_flex_ext ];
    %Get the post-trip-onset indices.
    pert_idxs = lower_dataset{test_idx}.pert_idxs;
    %Phase values:
    tt_all = lower_dataset{test_idx}.phase;
    %Now, scale the phase based on our phase bounds:
    tt_all = (tt_all - bounds.min_phase)./(bounds.max_phase - bounds.min_phase);
    
    %We want to simulate from the start of the perturbation:
    t_pert_start = tt_all(pert_idxs(1));

    %Interpolate the phase and hip states to have n_points points:
    t_all = interp1(linspace(0, 1, length(tt_all)), tt_all, linspace(0, 1,...
        n_points_for_interpolation));
    x_hip_all = interp1(tt_all, xx_hip_all, t_all);

    %Get the conditional prediction for this trial:
    [lowering_GPR_model, comparison_data] = get_GPR_conditional_prediction( lowering_GPR_model,...
        t_all, x_hip_all, t_pert_start, num_pts, conf_interval );

    %Plot.
    fig_num = 3;
    plot_GPR_comparison( lowering_GPR_model, comparison_data, 'lowering',...
        fig_num );

end