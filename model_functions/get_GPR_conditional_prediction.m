function [my_gpr_model, comparison_data, comp_time] = get_GPR_conditional_prediction( my_gpr_model,...
    t_all_og, x_hip_all_og, t_pert_start, num_pts, conf_interval )

%This function computes the conditional distribution of hip states.
%Written by Shannon Danforth, 2022.

%% Pad the trajecotry with NaNs so it can line up with the mean joint distribution.
%x_hip_all_og is the entire trajectory of hip angles, not just after
%perturbation.
%but it doesn't necessarily go from phase in [0,1], it starts/stops at
%other phase values.
%t_all and x_hip_all have 100 entires right now, so we will
%re-interpolate them to correspond to the same phase vals.
%and then pad with NaNs on either side.

%Full phase array:
full_phase = linspace(0, 1, 100)';
%First, get rid of points where t_all is less than 0 (there shouldn't be any, but just in case):
x_hip_all = x_hip_all_og( t_all_og >= 0, : );
t_all = t_all_og( t_all_og >= 0 )';
%And where t_all is greater than 1:
x_hip_all = x_hip_all( t_all <= 1, : );
t_all = t_all( t_all <= 1 )';

%Now find start_idx and end_idx
[~, start_idx] = min( abs( full_phase - t_all(1) ) );
[~, end_idx] = min( abs( full_phase - t_all(end) ) );
n_phase = end_idx - start_idx + 1;

%Now, resample t_all and x_hip_all to be n_phase length
t_all = interp1( linspace(0,1,length(t_all)), t_all, linspace(0,1,n_phase) )';
x_hip_all = interp1( linspace(0,1,size(x_hip_all, 1)), x_hip_all, linspace(0,1,n_phase) );

%And pad with NaNs
tmp_t = NaN(100,1);
tmp_t(start_idx:end_idx) = t_all;
tmp_x = NaN(100,3);
tmp_x(start_idx:end_idx, :) = x_hip_all;
%Redefine
x_hip_all = tmp_x;
t_all = tmp_t;

%Get post-pert idxs ("breaking point" for test trial when perturation occurs):
[~, bp] = min( abs( full_phase - t_pert_start ) );
if bp == start_idx
    %do nothing.
else
    bp = bp - 1;
end

%make sure we don't get NaNs in our conditional distribution:
if bp - num_pts < start_idx
    num_pts = bp - start_idx;
end

%% now define a weight based on our desired confidence interval percentage

alpha = 1 - conf_interval/100;
%t-value for confidence interval
wt = -norminv(alpha/2);

%% get those conditional distriutions!
%use handwritten GPR model.

tic;

my_gpr_model.conditional_predict(full_phase, x_hip_all, bp,...
    num_pts, wt);

comp_time = toc;

my_gpr_model.AP.joint_mu = my_gpr_model.joint_Mu(:,1);
my_gpr_model.AP.joint_ci = my_gpr_model.joint_Ci(:,1);
my_gpr_model.AP.conditional_mu = my_gpr_model.conditional_Mu(:,1);
my_gpr_model.AP.conditional_ci = my_gpr_model.conditional_Ci(:,1);

my_gpr_model.height.joint_mu = my_gpr_model.joint_Mu(:,2);
my_gpr_model.height.joint_ci = my_gpr_model.joint_Ci(:,2);
my_gpr_model.height.conditional_mu = my_gpr_model.conditional_Mu(:,2);
my_gpr_model.height.conditional_ci = my_gpr_model.conditional_Ci(:,2);

my_gpr_model.angle.joint_mu = my_gpr_model.joint_Mu(:,3);
my_gpr_model.angle.joint_ci = my_gpr_model.joint_Ci(:,3);
my_gpr_model.angle.conditional_mu = my_gpr_model.conditional_Mu(:,3);
my_gpr_model.angle.conditional_ci = my_gpr_model.conditional_Ci(:,3);

%a struct that contains info for plotting/comparison.
comparison_data.bp = bp;
comparison_data.t_all = t_all;
comparison_data.x_hip_all = x_hip_all;
comparison_data.full_phase = full_phase;
comparison_data.num_pts = num_pts;

end