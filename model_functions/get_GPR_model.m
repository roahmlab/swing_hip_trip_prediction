function my_gpr_model = get_GPR_model( dataset, bounds,... 
    conf_interval, noise_params, scale_params, alpha, l, corr_coefs )

%Get GPR model for a training dataset and a set of parameters.
%Written by Xinyi Liu and Shannon Danforth, 2022
        
X = []; %Phase values, nx1
Y = []; %Response variable values from training dataset, nx3
        
for trial_idx = 1:length(dataset)

    %First, get our three hip states
   hip_traj = [ dataset{trial_idx}.swing_hip_AP, dataset{trial_idx}.swing_hip_height,...
       dataset{trial_idx}.swing_hip_flex_ext ];
   %And associated un-scaled phase:
   phase = dataset{trial_idx}.phase;
   %Now, scale the phase based on our phase bounds:
   phase = (phase - bounds.min_phase)./(bounds.max_phase - bounds.min_phase);

   %Add to array.
   X = [X; phase];
   Y = [Y; hip_traj];

end
        
%Sorting the X and Y arrays based on phase value:
[ X, sort_idxs ] = sort(X);
Y = Y(sort_idxs, :);

%Get the GPR model using X, Y, and the parameters.
my_gpr_model = multi_output_GPR_model( X, Y, noise_params, l, alpha, scale_params, corr_coefs );

%Create a vector representing 0-100% of phase, which we can use to generate
%a prediction:
full_phase = linspace(0, 1, 100)';
my_gpr_model.predict( full_phase, conf_interval );

end