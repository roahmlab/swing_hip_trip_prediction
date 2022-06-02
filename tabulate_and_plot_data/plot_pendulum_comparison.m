function plot_pendulum_comparison( tsim, xsim, t_all, x_hip_all, t, ic, fig_num, recovery_label )

pred_color = [208 28 139]/255;

gt_lw = 2;
pred_lw = 4;
sz = 35;

figure(fig_num);
subplot(3,1,1); hold on;
title(recovery_label);
%first, plot ground truth traj.
pgt = plot( t_all, x_hip_all(:, 3), 'k', 'LineWidth', gt_lw );
%now, plot the simulation result
psim = plot( tsim, xsim(:, 5), 'Color', pred_color, 'LineWidth', pred_lw );
%now, scatter the initial condition
pic = scatter( t(1), ic(5), sz, 'k', 'filled' );
ylabel('Hip Angle (rad)', 'FontSize', 14);
legend( [pic, psim, pgt], {'Initial Condition', 'Dynamic Model Prediction', 'Ground Truth Trajectory'}, 'FontSize', 12 )

subplot(3,1,2); hold on;
%first, plot ground truth traj.
plot( t_all, x_hip_all(:, 2), 'k', 'LineWidth', gt_lw );
%now, plot the simulation result
plot( tsim, xsim(:, 3), 'Color', pred_color, 'LineWidth', pred_lw );
%now, scatter the initial condition
scatter( t(1), ic(3), sz, 'k', 'filled' );
ylabel('Hip Height (m)', 'FontSize', 14);

subplot(3,1,3); hold on;
%first, plot ground truth traj.
plot( t_all, x_hip_all(:, 1), 'k', 'LineWidth', gt_lw );
%now, plot the simulation result
plot( tsim, xsim(:, 1), 'Color', pred_color, 'LineWidth', pred_lw );
%now, scatter the initial condition
scatter( t(1), ic(1), sz, 'k', 'filled' );
ylabel('Hip AP Position (m)', 'FontSize', 14);
xlabel('Normalized Time', 'FontSize', 14);

end