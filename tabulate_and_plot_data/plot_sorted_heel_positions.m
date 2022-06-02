%plot_sorted_heel_positions

%Written by Shannon Danforth, 2022
%Load swing_phase_data for one subject and create a figure that plots the
%heel position data (sagittal-plane heel anterior-posterior position and
%height) sorted into three recovery strategies.

clear;
close all;

%Specify the subject to plot (Subject000 - Subject015):
subject_name = 'Subject000';

%Define an 'inpath' variable where your data folder is located.
inpath = '~/Documents/deep_blue_data';

%Load the swing_phase_data for this subject.
load( sprintf( '%s/%s/swing_phase_data.mat', inpath, subject_name ) );

%% Get the minimum and maximum swing phase values across all the data.
% We'll use these values to normalize our phase variable to [0, 1].
min_phase_all = [];
max_phase_all = [];
%first, loop through nominal trials:
for trial_idx = 1:length(swing_phase_data.nominal)
    %Get this trial's min and max phase values.
    min_phase_tmp = min(swing_phase_data.nominal{trial_idx}.phase);
    max_phase_tmp = max(swing_phase_data.nominal{trial_idx}.phase);
    %add them to arrays.
    min_phase_all = [min_phase_all; min_phase_tmp];
    max_phase_all = [max_phase_all; max_phase_tmp];
end
%Next, loop through tripped trials:
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
%(Note, in our "Predicting swing hip kinematics" paper, we find separate
%phase bounds for each recovery strategy. Here, we found one set of bounds
%for the entire dataset.) 

%% Get an average nominal heel AP position and height, and plot it.
%Define a vector of 100 evenly-spaced points from 0 to 1.
full_phase = linspace(0, 1, 100);

%initialize arrays of nominal heel height and AP position
nom_height = [];
nom_AP = [];

%Loop through nominal trials
for trial_idx = 1:length(swing_phase_data.nominal)

    %Get the phase vector for this trial, then normalize it using the
    %phase bounds we found.
    phase = swing_phase_data.nominal{trial_idx}.phase;
    phase = (phase - min_phase)/(max_phase - min_phase);

    %Get the heel height and AP position.
    x_height = swing_phase_data.nominal{trial_idx}.swing_heel_height;
    x_AP = swing_phase_data.nominal{trial_idx}.swing_heel_AP;

    %find start_idx and end_idx of the full_phase array corresponding to
    %this trial (we're doing this we can stack all the nominal trials 
    %into a big array and take the mean).
    [~, start_idx] = min( abs( full_phase - phase(1) ) );
    [~, end_idx] = min( abs( full_phase - phase(end) ) );

    %Define a new phase vector that corresponds to full_phase.
    n_phase = end_idx - start_idx + 1;
    new_phase = linspace( phase(1), phase(end), n_phase );

    %Resample the heel height and AP position to n_phase points.
    x_height = interp1( phase, x_height, new_phase );
    x_AP = interp1( phase, x_AP, new_phase );

    %Pad with NaNs
    tmp_nom_height = NaN( 1, 100 );
    tmp_nom_height(start_idx:end_idx) = x_height;
    tmp_nom_AP = NaN( 1, 100 );
    tmp_nom_AP(start_idx:end_idx) = x_AP;

    %Stack onto our array of nominal trials.
    nom_height = [nom_height; tmp_nom_height];
    nom_AP = [nom_AP; tmp_nom_AP];

end
%Find mean of the nominal trials (Note: the ends may be jumpy. 
%Could add some smoothing at the ends to make it look better).
mean_heel_AP = mean(nom_AP, 1, 'omitnan');
mean_heel_height = mean(nom_height, 1, 'omitnan');

%Plot.
nom_lw = 3;
figure(1);
subplot(2,3,1); hold on;
title('Elevating');
ylabel('Heel AP Position');
pnom1 = plot( full_phase, mean_heel_AP, 'k', 'LineWidth', nom_lw );
subplot(2,3,2); hold on;
title('Delayed Lowering');
pnom2 = plot( full_phase, mean_heel_AP, 'k', 'LineWidth', nom_lw );
subplot(2,3,3); hold on;
title('Lowering');
pnom3 = plot( full_phase, mean_heel_AP, 'k', 'LineWidth', nom_lw );
subplot(2,3,4); hold on;
xlabel('Swing Phase Variable');
ylabel('Heel Height');
plot( full_phase, mean_heel_height, 'k', 'LineWidth', nom_lw );
subplot(2,3,5); hold on;
xlabel('Swing Phase Variable');
plot( full_phase, mean_heel_height, 'k', 'LineWidth', nom_lw );
subplot(2,3,6); hold on;
xlabel('Swing Phase Variable');
plot( full_phase, mean_heel_height, 'k', 'LineWidth', nom_lw );

%% Loop through the tripped trials and plot their data by sorted strategy.
trip_lw = 1.5;
sz = 20;
elevating_color = 1/255*[252,141,98];
delayed_color = 1/255*[102,194,165];
lowering_color = 1/255*[141,160,203];
for trial_idx = 1:length(swing_phase_data.tripped)

    %Get the normalized phase value
    phase = swing_phase_data.tripped{trial_idx}.phase;
    phase = (phase - min_phase)/(max_phase - min_phase);

    %Get the heel height and AP position.
    x_height = swing_phase_data.tripped{trial_idx}.swing_heel_height;
    x_AP = swing_phase_data.tripped{trial_idx}.swing_heel_AP;

    %Get the recovery type.
    recovery_type = swing_phase_data.tripped{trial_idx}.recovery_type;

    %Get the trip onset idx.
    trip_onset_idx = swing_phase_data.tripped{trial_idx}.pert_idxs(1);

    %Now, plot:
    if strcmp( recovery_type, 'elevating')
        figure(1);
        subplot(2,3,1); hold on;
        pelev = plot( phase, x_AP, 'Color', elevating_color, 'LineWidth', trip_lw );
        pelev_trip = scatter( phase(trip_onset_idx), x_AP(trip_onset_idx), sz, 'b', 'filled' );
        subplot(2,3,4); hold on;
        plot( phase, x_height, 'Color', elevating_color, 'LineWidth', trip_lw );
        scatter( phase(trip_onset_idx), x_height(trip_onset_idx), sz, 'b', 'filled' );
    elseif strcmp( recovery_type, 'delayed lowering')
        figure(1);
        subplot(2,3,2); hold on;
        pdl = plot( phase, x_AP, 'Color', delayed_color, 'LineWidth', trip_lw );
        pdl_trip = scatter( phase(trip_onset_idx), x_AP(trip_onset_idx), sz, 'b', 'filled' );
        subplot(2,3,5); hold on;
        plot( phase, x_height, 'Color', delayed_color, 'LineWidth', trip_lw );
        scatter( phase(trip_onset_idx), x_height(trip_onset_idx), sz, 'b', 'filled' );
    elseif strcmp( recovery_type, 'lowering')
        figure(1);
        subplot(2,3,3); hold on;
        plower = plot( phase, x_AP, 'Color', lowering_color, 'LineWidth', trip_lw );
        plower_trip = scatter( phase(trip_onset_idx), x_AP(trip_onset_idx), sz, 'b', 'filled' );
        subplot(2,3,6); hold on;
        plot( phase, x_height, 'Color', lowering_color, 'LineWidth', trip_lw );
        scatter( phase(trip_onset_idx), x_height(trip_onset_idx), sz, 'b', 'filled' );
    end

end

%Add legend.
subplot(2,3,1); legend( [pnom1, pelev, pelev_trip], {'Nominal', 'Elevating', 'Trip Onset'} ); 
subplot(2,3,2); legend( [pnom2, pdl, pdl_trip], {'Nominal', 'Delayed Lowering', 'Trip Onset'} ); 
subplot(2,3,3); legend( [pnom3, plower, plower_trip], {'Nominal', 'Lowering', 'Trip Onset'} ); 