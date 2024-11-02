function M = DHparams(theta,d,r,alpha)
%DHPARAMS transformation defined by Denavit Hartenburg parameters

M = rotZ(theta)*transZ(d)*transX(r)*rotX(alpha);

end
