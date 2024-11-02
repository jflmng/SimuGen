function J = cylinderInertia(m,r,h)
% Inertia matrix for a cuboid
%   Detailed explanation goes here

J = m*diag([1/12*(3*r^2+h^2),1/12*(3*r^2+h^2),r^2/2]);

end

