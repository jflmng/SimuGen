function M = TransX(d)
%TRANSX 3D (Homogeneous coordinate) Translation matrix along x-axis 

R = [1,0,0;...
    0,1,0;...
    0,0,1];

t = [d; 0; 0];

M = [R, t; zeros(1,3), 1];

end

