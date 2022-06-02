function element_ij = rational_quadratic_kernel(xi,xj, l, alpha)
% KERNEL_RATIONAL_QUADRATIC: The rational quadratic kernel allows us to model data varying at multiple scales.
% Notation adopted from https://www.cs.cmu.edu/~epxing/Class/10708-15/notes/10708_scribe_lecture21.pdf
 element_ij = power(1 + (xi - xj).*(xi - xj) / (2 * alpha * l*l), -alpha);

end