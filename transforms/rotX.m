function M = rotX(theta)
%ROTX 3D (Homogeneous coordinate) Rotation matrix around x-axis 

R = [1,0,0;...
    0,cos(theta),-sin(theta);...
    0,sin(theta),cos(theta)];

t = [0; 0; 0];

M = [R, t; zeros(1,3), 1];

if isnumeric(theta)
    M = round(M,15);  
    % remove entries near zero when theta = pi e.g.
end

end

