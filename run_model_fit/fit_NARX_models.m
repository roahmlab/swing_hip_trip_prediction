%fit_NARX_models

%Written by Shannon Danforth and Xinyi Liu, 2022
%Load swing_phase_data and train three multi-output NARX models 
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
num_pts = 15; %Max number of points to use as feedback points in NARX model.
%Some NARX options:
trainFcn = 'trainlm';  % Levenberg-Marquardt backpropagation.'trainlm' is usually fastest.
inputDelays = 1; 
feedbackDelays = 1:num_pts;
hiddenLayerSize = 7;

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
%% Fit the NARX models.

%ELEVATING:
%First, check if there is more than one trial
if length(elev_dataset) > 1

    %Pick one trial to test, and train on the rest.
    test_idx = randi( [1 length(elev_dataset)], 1, 1 );
    train_idxs = setdiff( 1:length(elev_dataset), test_idx )';

    disp('Fitting Elevating NARX Model');

    %Fit Narx model:
    [X, y] = get_NARX_phi_response( elev_dataset(train_idxs), bounds, num_pts, n_points_for_interpolation );
    [elev_net, ~, ~, ~] = get_NARX_closed_loop( X, y, 1, num_pts, hiddenLayerSize, trainFcn );

    test_data = NARX_resample_and_pad_data( elev_dataset{test_idx}, bounds, num_pts, n_points_for_interpolation);
    num_pts_tmp = test_data.num_pts;

    bp = test_data.bp;
    phi = test_data.t_all;
    x_hip_all = test_data.x_hip_all;

    %get X_test and T_test.
    res_all = test_data.x_hip_all;
    X_test = phi( (bp+1-num_pts_tmp):end )';
    T_test = res_all((bp+1-num_pts_tmp):end,: )';

    X_test = num2cell(X_test,1);
    T_test = num2cell(T_test,1);        
    
    [x_test, xi_test, ai_test, t_test] = preparets( elev_net, X_test, {}, T_test );

    sim_all = sim( elev_net, x_test, xi_test, ai_test );
    sim_all = cell2mat(sim_all)';
    prediction.AP = sim_all(:,1);
    prediction.height = sim_all(:,2);
    prediction.angle = sim_all(:,3);

    fig_num = 1;
    plot_NARX_comparison( prediction, test_data, 'elevating', fig_num );

end

%DELAYED LOWERING:
%First, check if there is more than one trial
if length(dl_dataset) > 1

    %Pick one trial to test, and train on the rest.
    test_idx = randi( [1 length(dl_dataset)], 1, 1 );
    train_idxs = setdiff( 1:length(dl_dataset), test_idx )';

    disp('Fitting Delayed Lowering NARX Model');

    %Fit Narx model:
    [X, y] = get_NARX_phi_response( dl_dataset(train_idxs), bounds, num_pts, n_points_for_interpolation );
    [dl_net, ~, ~, ~] = get_NARX_closed_loop( X, y, 1, num_pts, hiddenLayerSize, trainFcn );

    test_data = NARX_resample_and_pad_data( dl_dataset{test_idx}, bounds, num_pts, n_points_for_interpolation);
    num_pts_tmp = test_data.num_pts;

    bp = test_data.bp;
    phi = test_data.t_all;
    x_hip_all = test_data.x_hip_all;

    %get X_test and T_test.
    res_all = test_data.x_hip_all;
    X_test = phi( (bp+1-num_pts_tmp):end )';
    T_test = res_all((bp+1-num_pts_tmp):end,: )';

    X_test = num2cell(X_test,1);
    T_test = num2cell(T_test,1);        
    
    [x_test, xi_test, ai_test, t_test] = preparets( dl_net, X_test, {}, T_test );

    sim_all = sim( dl_net, x_test, xi_test, ai_test );
    sim_all = cell2mat(sim_all)';
    prediction.AP = sim_all(:,1);
    prediction.height = sim_all(:,2);
    prediction.angle = sim_all(:,3);

    fig_num = 2;
    plot_NARX_comparison( prediction, test_data, 'delayed lowering', fig_num );

end

%LOWERING:
%First, check if there is more than one trial
if length(lower_dataset) > 1

    %Pick one trial to test, and train on the rest.
    test_idx = randi( [1 length(lower_dataset)], 1, 1 );
    train_idxs = setdiff( 1:length(lower_dataset), test_idx )';

    disp('Fitting Lowering NARX Model');

    %Fit Narx model:
    [X, y] = get_NARX_phi_response( lower_dataset(train_idxs), bounds, num_pts, n_points_for_interpolation );
    [lower_net, ~, ~, ~] = get_NARX_closed_loop( X, y, 1, num_pts, hiddenLayerSize, trainFcn );

    test_data = NARX_resample_and_pad_data( lower_dataset{test_idx}, bounds, num_pts, n_points_for_interpolation);
    num_pts_tmp = test_data.num_pts;

    bp = test_data.bp;
    phi = test_data.t_all;
    x_hip_all = test_data.x_hip_all;

    %get X_test and T_test.
    res_all = test_data.x_hip_all;
    X_test = phi( (bp+1-num_pts_tmp):end )';
    T_test = res_all((bp+1-num_pts_tmp):end,: )';

    X_test = num2cell(X_test,1);
    T_test = num2cell(T_test,1);        
    
    [x_test, xi_test, ai_test, t_test] = preparets( lower_net, X_test, {}, T_test );

    sim_all = sim( lower_net, x_test, xi_test, ai_test );
    sim_all = cell2mat(sim_all)';
    prediction.AP = sim_all(:,1);
    prediction.height = sim_all(:,2);
    prediction.angle = sim_all(:,3);

    fig_num = 3;
    plot_NARX_comparison( prediction, test_data, 'lowering', fig_num );

end