function M = rotY(theta)
%ROTY 3D (Homogeneous coordinate) Rotation matrix around y-axis 

R = [cos(theta),0,sin(theta);...
    0,1,0;...
    -sin(theta),0,cos(theta)];

t = [0; 0; 0];

M = [R, t; zeros(1,3), 1];

if isnumeric(theta)
    M = round(M,15);  
    % remove entries near zero when theta = pi e.g.
end

end

