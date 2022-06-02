function [mean_strat, d_mean_strat] = get_pendulum_avg_states( dataset, bounds, n_points_for_interpolation )

angle_strat = []; height_strat = []; ap_strat = [];
d_angle_strat = []; d_height_strat = []; d_ap_strat = [];

full_phase = linspace( 0, 1, n_points_for_interpolation )';

for trial_idx = 1:length(dataset)

    %get hip response variables
    xx_hip_all = [ dataset{trial_idx}.swing_hip_AP, dataset{trial_idx}.swing_hip_height, dataset{trial_idx}.swing_hip_flex_ext ];
    tt_all = dataset{trial_idx}.phase;
    tt_all = (tt_all - bounds.min_phase)/(bounds.max_phase - bounds.min_phase);
    t_all = interp1(linspace(0, 1, length(tt_all)), tt_all, linspace(0, 1,...
            n_points_for_interpolation));
    x_hip_all = interp1(tt_all, xx_hip_all, t_all); %(AP, height, angle)

    %differentiate
    dt = t_all(2) - t_all(1);
    d_ap = ddt( x_hip_all(:, 1), dt );
    d_height = ddt( x_hip_all(:, 2), dt );
    d_angle = ddt( x_hip_all(:, 3), dt );

    %find which idxs of full_phase our trial corresponds to
    [~, start_idx] = min( abs( t_all(1) - full_phase ) );
    [~, end_idx] = min( abs( t_all(end) - full_phase ) );
    n_phase = end_idx - start_idx + 1;

    %resample everything to be n_phase points
    x_hip_all = interp1( linspace(0,1,length(x_hip_all)), x_hip_all,...
        linspace(0,1,n_phase));
    d_ap_tmp = interp1( linspace(0,1,length(d_ap)), d_ap,...
        linspace(0,1,n_phase))';
    d_height_tmp = interp1( linspace(0,1,length(d_height)), d_height,...
        linspace(0,1,n_phase))';
    d_angle_tmp = interp1( linspace(0,1,length(d_angle)), d_angle,...
        linspace(0,1,n_phase))';

    %pad with NaNs
    ap = [ NaN(start_idx-1, 1); x_hip_all(:, 1); NaN(length(full_phase)-end_idx, 1) ];
    height = [ NaN(start_idx-1, 1); x_hip_all(:, 2); NaN(length(full_phase)-end_idx, 1) ];
    angle = [ NaN(start_idx-1, 1); x_hip_all(:, 3); NaN(length(full_phase)-end_idx, 1) ];
    d_ap = [ NaN(start_idx-1, 1); d_ap_tmp; NaN(length(full_phase)-end_idx, 1) ];
    d_height = [ NaN(start_idx-1, 1); d_height_tmp; NaN(length(full_phase)-end_idx, 1) ];
    d_angle = [ NaN(start_idx-1, 1); d_angle_tmp; NaN(length(full_phase)-end_idx, 1) ];

    angle_strat = [ angle_strat, angle  ]; 
    height_strat = [ height_strat, height ]; 
    ap_strat = [ ap_strat, ap ];
    d_angle_strat = [ d_angle_strat, d_angle ];
    d_height_strat = [ d_height_strat, d_height ];
    d_ap_strat = [ d_ap_strat, d_ap ];

end
   
%now, get mean positions/velocities
mean_strat = [ smooth(mean( ap_strat, 2, 'omitnan' )),...
    smooth(mean( height_strat, 2, 'omitnan' )),...
    smooth(mean( angle_strat, 2, 'omitnan' )) ];

d_mean_strat = [ smooth(mean( d_ap_strat, 2, 'omitnan' )),...
    smooth(mean( d_height_strat, 2, 'omitnan' )),...
    smooth(mean( d_angle_strat, 2, 'omitnan' )) ];