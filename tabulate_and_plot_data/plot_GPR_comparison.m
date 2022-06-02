function plot_GPR_comparison( my_gpr_model, comparison_data, recovery_label, fig_num )

plot_joint = false;
plot_joint_mean = false;
plot_conditional = true;
plot_gt = true;


joint_dist_color = [77 172 38]/255; %green
cond_dist_color = [208 28 139]/255; %pink
lw = 4;
fa = 0.2;
sz = 35;

switch recovery_label
    case 'elevating'
        plot_title = 'Elevating';
    case 'delayed lowering'
        plot_title = 'Delayed Lowering';
    case 'lowering'
        plot_title = 'Lowering';
end

full_phase = comparison_data.full_phase;
t_all = comparison_data.t_all;
x_hip_all = comparison_data.x_hip_all;
bp = comparison_data.bp;
num_pts = comparison_data.num_pts;

trial_idxs = find(~isnan(t_all));
end_idx_all = trial_idxs(end);

trial_idxs_post = find(~isnan(t_all(bp+1:end)));
end_idx_post = trial_idxs_post(end);

%% hip angle:

figure(fig_num);
subplot( 3,1,1 ); hold on;
title(plot_title);
ylabel('Hip Angle (rad)', 'FontSize', 14);
legend_subplot = true;

joint_angle = my_gpr_model.angle.joint_mu;
w = my_gpr_model.angle.joint_ci;
joint_conf_angle = [joint_angle - w, joint_angle + w];

cond_angle = my_gpr_model.angle.conditional_mu;
w = my_gpr_model.angle.conditional_ci;
cond_conf_angle = [cond_angle - w, cond_angle + w];

x_pts = x_hip_all(:, 3);

plotting_code( joint_conf_angle, joint_angle, cond_conf_angle, cond_angle, x_pts, legend_subplot );

%% hip height

subplot(3,1,2); hold on;
ylabel('Hip Height (m)', 'FontSize', 14);
legend_subplot = false;

joint_height = my_gpr_model.height.joint_mu;
w = my_gpr_model.height.joint_ci;
joint_conf_height = [joint_height - w, joint_height + w];

cond_height = my_gpr_model.height.conditional_mu;
w = my_gpr_model.height.conditional_ci;
cond_conf_height = [cond_height - w, cond_height + w];

x_pts = x_hip_all(:, 2);

plotting_code( joint_conf_height, joint_height, cond_conf_height, cond_height, x_pts, legend_subplot );

%% hip AP

subplot(3,1,3); hold on;
ylabel('Hip AP Position (m)', 'FontSize', 14);
xlabel('Normalized Time', 'FontSize', 14);
legend_subplot = false;

joint_AP = my_gpr_model.AP.joint_mu;
w = my_gpr_model.AP.joint_ci;
joint_conf_AP = [joint_AP - w, joint_AP + w];

cond_AP = my_gpr_model.AP.conditional_mu;
w = my_gpr_model.AP.conditional_ci;
cond_conf_AP = [cond_AP - w, cond_AP + w];

x_pts = x_hip_all(:, 1);

plotting_code( joint_conf_AP, joint_AP, cond_conf_AP, cond_AP, x_pts, legend_subplot );

    function plotting_code( joint_conf, joint, conditional_conf, conditional, x_pts, legend_subplot )
        
        %JOINT DISTRIBUTION:
        if plot_joint
            inBetween = [joint_conf(:,1).', fliplr(joint_conf(:,2).')];
            if legend_subplot
                %conf:
                h1 = fill( [full_phase',fliplr(full_phase')], inBetween, joint_dist_color);
                h1.FaceAlpha = fa;
                h1.EdgeAlpha = 0;
                %mean:
                p1 = plot( full_phase, joint, 'Color', joint_dist_color, 'LineWidth', lw );
            else
                %conf:
                h = fill( [full_phase',fliplr(full_phase')], inBetween, joint_dist_color);
                h.FaceAlpha = fa;
                h.EdgeAlpha = 0;
                %mean:
                plot( full_phase, joint, 'Color', joint_dist_color, 'LineWidth', lw );
            end
        end
        
        if plot_joint_mean
            p1 = plot( full_phase, joint, 'Color', joint_dist_color, 'LineWidth', lw );
        end
        
        %CONDITIONAL DISTRIBUTION:
        if plot_conditional
            inBetween = [conditional_conf(1:end_idx_post,1).', fliplr(conditional_conf(1:end_idx_post,2).')];
            if legend_subplot
                %conf:
                h2 = fill( [full_phase(bp+1:end_idx_all)',fliplr(full_phase(bp+1:end_idx_all)')], inBetween, cond_dist_color);
                h2.FaceAlpha = fa;
                h2.EdgeAlpha = 0;
                %mean:
                p2 = plot( full_phase(bp+1:end_idx_all), conditional(1:end_idx_post), 'Color', cond_dist_color, 'LineWidth', lw );
                %+ conditional points
                s1 = scatter( t_all(max(1, bp - num_pts):bp), x_pts( max(1, bp - num_pts):bp ), sz, 'k', 'filled' );
            else
                %conf:
                h = fill( [full_phase(bp+1:end_idx_all)',fliplr(full_phase(bp+1:end_idx_all)')], inBetween, cond_dist_color);
                h.FaceAlpha = fa;
                h.EdgeAlpha = 0;
                %mean:
                plot( full_phase(bp+1:end_idx_all), conditional(1:end_idx_post), 'Color', cond_dist_color, 'LineWidth', lw );
                %+ conditional points
                scatter( t_all(max(1, bp - num_pts):bp), x_pts( max(1, bp - num_pts):bp ), sz, 'k', 'filled' );
            end
            xlim([0, 1]);
        end
        
        %REAL DATA:
        if plot_gt
            if legend_subplot
                p3 = plot( t_all, x_pts, 'k', 'LineWidth', 2 );
            else
                plot( t_all, x_pts, 'k', 'LineWidth', 2 );
            end
        end
        
        if legend_subplot
            if plot_joint && ~plot_conditional && ~plot_gt
                legend([p1, h1], {'Joint Distribution', 'Joint Confidence Interval'}, 'Location', 'South', 'Fontsize', 12);
            end
            if plot_joint && plot_conditional && ~plot_gt
                legend([p1, h1, s1, p2, h2], {'Joint Distribution', 'Joint Confidence Interval', 'Conditional Points', 'Conditional Prediction', 'Conditional Confidence Interval'}, 'Location', 'South', 'Fontsize', 12);
            end
            if plot_conditional && ~plot_joint && ~plot_gt
                legend([s1, p2, h2], {'Conditional Points', 'Conditional Prediction', 'Conditional Confidence Interval'}, 'Location', 'South', 'Fontsize', 12);
            end
            if plot_joint_mean && plot_conditional && ~plot_joint && ~plot_gt
                legend([p1, s1, p2, h2], {'GPR Distribution Mean', 'Conditional Points', 'Conditional Prediction', 'Conditional Confidence Interval'}, 'Location', 'South', 'Fontsize', 12);
            end
            if plot_conditional && plot_gt && ~plot_joint
                legend([s1, p2, h2, p3], {'Conditional Points', 'Conditional Prediction', 'Conditional Confidence Interval', 'Ground Truth Trajectory'}, 'Location', 'South', 'Fontsize', 12);
            end
            if plot_joint_mean && plot_conditional && plot_gt && ~plot_joint
                legend([p1, s1, p2, h2, p3], {'GPR Distribution Mean', 'Conditional Points', 'Conditional Prediction', 'Conditional Confidence Interval', 'Ground Truth Trajectory'}, 'Location', 'South', 'Fontsize', 12);
            end
            if plot_joint && plot_conditional && plot_gt
                legend([p1,h1,s1,p2,h2,p3], {'Joint Distribution', 'Joint Confidence Interval', 'Conditional Points', 'Conditional Prediction', 'Conditional Confidence Interval', 'Ground Truth Trajectory'}, 'Location', 'South', 'Fontsize', 12);
            end
        end

    end

end