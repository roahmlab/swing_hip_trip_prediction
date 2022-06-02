function [ resampled_data ] = NARX_resample_and_pad_data( trial, bounds, num_pts, n_points_for_interpolation)
   
    pert_idxs = trial.pert_idxs;
    xx_hip_all = [ trial.swing_hip_AP, trial.swing_hip_height, trial.swing_hip_flex_ext ];

    tt_all = trial.phase;
    %Now, scale the phase based on our phase bounds:
    tt_all_og = (tt_all - bounds.min_phase)./(bounds.max_phase - bounds.min_phase);

    t_pert_start = tt_all_og(pert_idxs(1));
    t_all = interp1(linspace(0, 1, length(tt_all_og )), tt_all_og , linspace(0, 1,...
        n_points_for_interpolation));
    x_hip_all_og = interp1(tt_all_og , xx_hip_all, t_all);
    
    %full phase array:
    full_phase = linspace(0, 1, 100)';
    %first, get rid of points where t_all is less than 0:
    x_hip_all = x_hip_all_og( t_all >= 0, : );
    t_all = t_all( t_all >= 0 )';
    %and where t_all is greater than 1:
    x_hip_all = x_hip_all( t_all <= 1, : );
    t_all = t_all( t_all <= 1 )';
    
    %now find start_idx and end_idx
    [~, start_idx] = min( abs( full_phase - t_all(1) ) );
    [~, end_idx] = min( abs( full_phase - t_all(end) ) );
    n_phase = end_idx - start_idx + 1;
    
    %now, resample t_all and x_hip_all to be n_phase length
    t_all = interp1( linspace(0,1,length(t_all)), t_all, linspace(0,1,n_phase))';
    x_hip_all = interp1( linspace(0,1,size(x_hip_all, 1)), x_hip_all, linspace(0,1,n_phase));
    
    %and pad with NaNs
    tmp_t = NaN(100,1);
    tmp_t(start_idx:end_idx) = t_all;
    tmp_x = NaN(100,3);
    tmp_x(start_idx:end_idx, :) = x_hip_all;
    %redefine
    x_hip_all = tmp_x;
    t_all = tmp_t;
    
    %get post-pert idxs ("breaking point" for test trial when perturation occurs):
    [~, bp] = min(abs( full_phase - t_pert_start ));
    bp = bp - 1;
    
    %make sure we don't get NaNs in our conditional distribution:
    if bp - num_pts < start_idx
        num_pts = bp - start_idx;
    end

    % copied from get_conditional_dist_MO
    % a struct that contains info for plotting
    resampled_data.bp = bp;
    resampled_data.t_all = t_all;
    resampled_data.x_hip_all = x_hip_all;
    resampled_data.full_phase = full_phase;
    resampled_data.num_pts = num_pts;

end