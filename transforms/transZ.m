function M = TransZ(d)
%TRANSZ 3D (Homogeneous coordinate) Translation matrix along z-axis 

R = [1,0,0;...
    0,1,0;...
    0,0,1];

t = [0; 0; d];

M = [R, t; zeros(1,3), 1];

end

