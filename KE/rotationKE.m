function KE = rotation(J,omega)
%ROTATION Kinetic energy due to rotating part

KE = 1/2*omega.'*J*omega;

end

