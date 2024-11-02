function J = cuboidInertia(m,dx,dy,dz)
% Inertia matrix for a cuboid
%   Detailed explanation goes here

J = 1/12*m*diag([dy^2+dz^2,dx^2+dz^2,dx^2+dy^2]);

end

