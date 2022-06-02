function K = get_pendulum_opt_K( dataset, bounds, params, mean_trajs )

%some inital condition and bounds
x0 = [200 15 20000 500 2000 50];
A = [];
b = [];
Aeq = [];
beq = [];
lb = zeros(1,6);
ub = inf*ones(1,6);
nonlcon = [];
options = optimoptions(@fmincon, 'OptimalityTolerance', 1.0000e-4); %,'Algorithm','sqp'); % could also try it
K = fmincon(@costfunc, x0, A, b, Aeq, beq, lb, ub, nonlcon, options );

    function my_cost = costfunc(x)
        
        count = 0;
        cost_sum = 0;
        
        for trial_idx = 1:length(dataset)
            
            count = count + 1;
            
            pert_idxs = dataset{trial_idx}.pert_idxs;
            x_hip_all = [ dataset{trial_idx}.swing_hip_AP, dataset{trial_idx}.swing_hip_height, dataset{trial_idx}.swing_hip_flex_ext ];
            t_all = dataset{trial_idx}.phase;
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
            
            [tsim, xsim, ~] = sim_pendulum_model( params, x, ic, t, mean_trajs );
            
            if ~isa(xsim, 'double')
                xsim = double(xsim);
            end
            
            %in case fmincon stops prematurely for some reason...
            if size(xsim, 1) ~= length(t)
                cost_sum = cost_sum + 10000;
            else
                %compute error:
                err_p = x_hip_all( pert_idxs, : ) - xsim( :, [1 3 5] );
                err_p = sqrt( sum( err_p.^2 )./length(err_p) );
                err_v = [d_ap(pert_idxs), d_height(pert_idxs),...
                    d_angle(pert_idxs)] - xsim( :, [2 4 6] );
                err_v = sqrt( sum( err_v.^2 )./length(err_v) );

                cost_sum = cost_sum + sum(err_p) + sum(err_v);
            end
            
        end
        
        my_cost = cost_sum / count;
        
    end

end