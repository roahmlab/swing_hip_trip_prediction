function plot_NARX_comparison( net, resampled_data, recovery_label, fig_num )

plot_prediction = true;
plot_gt = true;

cond_dist_color = [208 28 139]/255; %pink
lw = 4;
sz = 35;

switch recovery_label
    case 'elevating'
        plot_title = 'Elevating';
    case 'delayed lowering'
        plot_title = 'Delayed Lowering';
    case 'lowering'
        plot_title = 'Lowering';
end

full_phase = resampled_data.full_phase;
t_all = resampled_data.t_all;
x_hip_all = resampled_data.x_hip_all;
bp = resampled_data.bp;
num_pts = resampled_data.num_pts;

%% hip angle:

figure(fig_num);

subplot( 3,1,1 ); hold on;
title(plot_title);
ylabel('Hip Angle (rad)', 'FontSize', 14);
legend_subplot = true;
pred_angle = net.angle;
x_pts = x_hip_all(:, 3);

plotting_code(pred_angle, x_pts, legend_subplot );

%% hip height

subplot(3,1,2); hold on;
ylabel('Hip Height (m)', 'FontSize', 14);
legend_subplot = false;
pred_height = net.height;
x_pts = x_hip_all(:, 2);

plotting_code( pred_height, x_pts, legend_subplot );

%% hip AP

subplot(3,1,3); hold on;
ylabel('Hip AP Position (m)', 'FontSize', 14);
xlabel('Normalized Time', 'FontSize', 14);
legend_subplot = false;

pred_AP = net.AP;
x_pts = x_hip_all(:, 1);

plotting_code( pred_AP, x_pts, legend_subplot );

    function plotting_code( conditional, x_pts, legend_subplot )
   
        %NARX PREDICTION:
        if plot_prediction
            if length(full_phase(bp+1:end)) == length(conditional)
                %mean:
                pnarx = plot( full_phase(bp+1:end), conditional, 'Color', cond_dist_color, 'LineWidth', lw );
            else
                %NARX model may have gotten cut off if it started blowing
                %up. Judt subtract some points off of full_phase.
                diff_idx = length(full_phase(bp+1:end)) - length(conditional);
                tmp_t = full_phase(bp+1:end - diff_idx);
                pnarx = plot( tmp_t, conditional, 'Color', cond_dist_color, 'LineWidth', lw );
            end
            
            %+ feedback delay points
            pfeed = scatter( t_all(max(1, bp - num_pts):bp), x_pts( max(1, bp - num_pts):bp ), sz, 'k', 'filled' );
            xlim([0, 1]);
        end
        
        %REAL DATA:
        if plot_gt
            if legend_subplot
                pgt = plot( t_all, x_pts, 'k', 'LineWidth', 2 );
            else
                plot( t_all, x_pts, 'k', 'LineWidth', 2 );
            end
        end
        if legend_subplot
            legend( [pfeed, pnarx, pgt], {'Feedback Delay Points', 'NARX Prediction', 'Ground Truth Trajectory'}, 'Location', 'South', 'Fontsize', 12);
        end  

    end

end