function omega_cross = cross(omega)
%CROSS cross product matrix
omega_cross = [0, -omega(3), omega(2); ...
    omega(3), 0, -omega(1); ...
    -omega(2), omega(1), 0];     
% NB: the antisymmetric angular velocity tensor ("Cross product matrix")

end

