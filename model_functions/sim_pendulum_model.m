function [tsim, xsim, comp_time] = sim_pendulum_model( params, K, x0, time, mean_trajs )

m1 = double(params.m1);
m2 = double(params.m2);
l = double(params.l);
g = double(params.g);

mean_pos = mean_trajs.position;
mean_vel = mean_trajs.velocity;
full_phase = linspace(0, 1, size(mean_vel, 1));

%re-shuffle:
mean_values = [mean_pos(:,1), mean_vel(:,1), mean_pos(:,2), mean_vel(:,2),...
    mean_pos(:,3), mean_vel(:,3)];

tic;
[ tsim, xsim ] = ode45( @dyn, time, x0 );
comp_time = toc;

    function x_dot = dyn( t, x )

        %x is 6x1: AP, d_AP, height, d_height, angle, d_angle
       
        %find input based on difference from mean_traj
        %first, find where we should be for this mean_traj:
        [~, t_idx] = min( abs( full_phase - t ) );

        %next, get the mean values at this time:
        mean_vals_tmp = mean_values(t_idx, :);
        
        %subtract to get err:
        err = mean_vals_tmp' - x;
        
        %get control inputs:
        u(1) = K(1)*err(1) + K(2)*err(2);
        u(2) = K(3)*err(3) + K(4)*err(4);
        u(3) = K(5)*err(5) + K(6)*err(6);
        
        ax = u(1)/m1;
        ay = u(2)/m1 - g;
        
        x_dot = [ x(2);
                ax;
                x(4);
                ay;
                x(6);
                -cos(x(5))/l*ax - sin(x(5))/l*ay - g/l*sin(x(5)) + 1/(m2*l^2)*u(3) ];

    end

end