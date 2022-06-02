function params = get_optimal_GPR_params( dataset, bounds, conf_interval, n_points_for_interpolation, num_pts )

%This function sets up the fmincon problem to find optimal parameters for a
%GPR model.
%Written by Xinyi Liu and Shannon Danforth, 2022.

% initial condition for MO:
% x0[1:3]: noise parameter for ap, h, ang
% x0[4:6]: scale parameter for ap, h, ang
% x0[7]: alpha
% x0[8]: l
% x0[9:11]: rel. coefs (b12, b13, b23)
x0 = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
A = [];
b = [];
Aeq = [];
beq = [];
lb = [0, 0, 0, 0, 0, 0, 0, 0, -0.5, -0.5, -0.5];
ub = [0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5];
%Note, these are example ranges and x0 values; can be adjusted.

nonlcon = [];
options = optimoptions(@fmincon, 'OptimalityTolerance', 1.0000e-3);
params = fmincon( @conditional_prediction_error, x0, A, b, Aeq, beq, lb, ub, nonlcon, options );
params = params';

    function my_cost = conditional_prediction_error(x)
        
        %Define parameters from the x-values in this iteration
        noise_params = x(1:3); 
        scale_params = x(4:6); 
        alpha = x(7); 
        l = x(8);
        rel_coefs = x(9:11);
        
        %Get the GPR model using these parameters and training data.
        tmp_GPR_model = get_GPR_model( dataset, bounds,...
            conf_interval, noise_params, scale_params, alpha, l, rel_coefs );
        
        %We want to minimize the error between simulated and ground truth
        %trajectories of all the training trials of the same recovery strategy.
        count = 0;
        cost_sum = 0;
        for trial_idx = 1:length(dataset)
            
            count = count + 1;
            
            %Get the hip states for this training trial.
            xx_hip_all = [ dataset{trial_idx}.swing_hip_AP, dataset{trial_idx}.swing_hip_height,...
                dataset{trial_idx}.swing_hip_flex_ext ];
            %Get the post-trip-onset indices.
            pert_idxs = dataset{trial_idx}.pert_idxs;
            %Phase values:
            tt_all = dataset{trial_idx}.phase;
            %Now, scale the phase based on our phase bounds:
            tt_all = (tt_all - bounds.min_phase)./(bounds.max_phase - bounds.min_phase);
            
            %We want to simulate from the start of the perturbation:
            t_pert_start = tt_all(pert_idxs(1));

            %Interpolate the phase and hip states to have n_points points:
            t_all = interp1(linspace(0, 1, length(tt_all)), tt_all, linspace(0, 1,...
                n_points_for_interpolation));
            x_hip_all = interp1(tt_all, xx_hip_all, t_all);

            %Get the conditional prediction for this trial:
            [tmp_GPR_model, comparison_data] = get_GPR_conditional_prediction( tmp_GPR_model,...
                t_all, x_hip_all, t_pert_start, num_pts, conf_interval );
            
            %Get the  ground truth x_hip_all that's sampled at the right
            %amount of points.
            x_hip_all = comparison_data.x_hip_all;
            break_point = comparison_data.bp;

            % hip AP error:
            cond_AP = tmp_GPR_model.AP.conditional_mu;
            x_pts = x_hip_all((break_point+1):end, 1);
            err = cond_AP(~isnan(x_pts)) - x_pts(~isnan(x_pts));
            RMSE_AP = sqrt(sum(err .* err)/length(err));

            % hip height error:
            cond_height = tmp_GPR_model.height.conditional_mu;
            x_pts = x_hip_all((break_point+1):end, 2);
            err = cond_height(~isnan(x_pts)) - x_pts(~isnan(x_pts));
            RMSE_height = sqrt(sum(err .* err)/length(err));

            % hip angle error:
            cond_angle = tmp_GPR_model.angle.conditional_mu;
            x_pts = x_hip_all((break_point+1):end, 3);
            err = cond_angle(~isnan(x_pts)) - x_pts(~isnan(x_pts));
            RMSE_angle = sqrt(sum(err .* err)/length(err));
            
            tmp_cost = RMSE_AP + RMSE_height + RMSE_angle;
            cost_sum = cost_sum + tmp_cost;
            
        end
        
        my_cost = cost_sum / count;
        
    end

end