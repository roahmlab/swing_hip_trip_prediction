%count_trip_trials

%Written by Shannon Danforth, 2022
%Load swing_phase_data and create a table that lists the breakdown of
%recovery strategies for each subject.

clear;

%Specify the subjects to tabulate (0-15):
subjects = 0:15;

%Define an 'inpath' variable where your data folder is located.
inpath = '~/Documents/deep_blue_data';

%Initialize the trial counts across all subjects.
elev_trials = 0;
dl_trials = 0;
lower_trials = 0;

%Initialize some cell arrays that we'll turn into a table.
subject_column = cell(length(subjects), 1);
trip_numbers = cell(length(subjects), 4);

%Loop through all subjects and load their data:
for subj_idx = 1:length(subjects)

    %Initialize the subject-specific trial counts.
    elev_subj_trials = 0;
    dl_subj_trials = 0;
    lower_subj_trials = 0;
    
    %Form a subject_name string.
    if subjects(subj_idx) < 10
        subject_name = sprintf( 'Subject00%s', num2str(subjects(subj_idx)) );
    else
        subject_name = sprintf( 'Subject0%s', num2str(subjects(subj_idx)) );
    end

    %Load the swing_phase_data for this subject.
    load( sprintf( '%s/%s/swing_phase_data.mat', inpath, subject_name ) );

    %Loop through all tripped trials.
    for trial_idx = 1:length(swing_phase_data.tripped)

        %Get this trial's recovery type.
        recovery_type = swing_phase_data.tripped{trial_idx}.recovery_type;

        %Now, add to the trial counts.
        if strcmp( recovery_type, 'elevating' )
            elev_trials = elev_trials + 1;
            elev_subj_trials = elev_subj_trials + 1;
        elseif strcmp( recovery_type, 'delayed lowering' )
            dl_trials = dl_trials + 1;
            dl_subj_trials = dl_subj_trials + 1;
        elseif strcmp( recovery_type, 'lowering' )
            lower_trials = lower_trials + 1;
            lower_subj_trials = lower_subj_trials + 1;
        end

    end

    %Get this subject's total trial count.
    total_subj_trials = elev_subj_trials + dl_subj_trials + lower_subj_trials;

    %Add to a cell array...
    trip_numbers{subj_idx, 1} = elev_subj_trials;
    trip_numbers{subj_idx, 2} = dl_subj_trials;
    trip_numbers{subj_idx, 3} = lower_subj_trials;
    trip_numbers{subj_idx, 4} = total_subj_trials;
    subject_column{subj_idx, 1} = subjects(subj_idx);

end

%Get total trials across all subjects.
total_trials = elev_trials + dl_trials + lower_trials;

%Make one more cell with total numbers.
total_cell{1, 1} = 'Total';
total_cell{1, 2} = elev_trials;
total_cell{1, 3} = dl_trials;
total_cell{1, 4} = lower_trials;
total_cell{1, 5} = total_trials;

%Form a big cell array.
C = [subject_column, trip_numbers; total_cell];

%Turn into a table and display.
T = cell2table(C, "VariableNames", ["Subject" "Elevating" "Delayed Lowering" "Lowering" "Total"]);
disp(T);