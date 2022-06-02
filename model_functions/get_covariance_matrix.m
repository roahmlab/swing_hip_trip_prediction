function K = get_covariance_matrix(x1,x2,l,alpha)

    [X1, X2] = meshgrid(x1, x2);
    K = rational_quadratic_kernel( X1, X2, l, alpha )';

end