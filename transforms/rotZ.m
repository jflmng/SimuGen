function M = RotZ(theta)
%ROTZ 3D (Homogeneous coordinate) Rotation matrix around z-axis 

R = [cos(theta),-sin(theta),0;...
    sin(theta),cos(theta),0;...
    0,0,1];

t = [0; 0; 0];

M = [R, t; zeros(1,3), 1];

if isnumeric(theta)
    M = round(M,15);  
    % remove entries near zero when theta = pi e.g.
end

end

