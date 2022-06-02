function [Phi, y] = get_NARX_phi_response(dataset, bounds, num_pts, n_points_for_interpolation)  

    Phi = []; %phase vals
    y = []; %hip height vals (height)/ hip AP position vals (AP)/ hip flex-ext angle vals (angle)
    for trial_idx = 1:length(dataset)

       resampled_data = NARX_resample_and_pad_data( dataset{trial_idx}, bounds, num_pts, n_points_for_interpolation );
       
       %first, get our three hip states
       res_all = resampled_data.x_hip_all;
       
       phi = resampled_data.t_all;
       
       Phi = [Phi, phi'];
       y = [y, res_all'];

    end 
    
    Phi = num2cell(Phi,1);
    y = num2cell(y,1);
    
end