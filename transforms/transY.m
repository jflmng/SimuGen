function M = TransY(d)
%TRANSY 3D (Homogeneous coordinate) Translation matrix along y-axis 

R = [1,0,0;...
    0,1,0;...
    0,0,1];

t = [0; d; 0];

M = [R, t; zeros(1,3), 1];

end

