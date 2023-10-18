function dt_iono = delay_iono(llh, azim, elev, TOW, param_iono)

% Ionosphric propagation delay
% based on the Klobuchar ionospheric model
%
% Syntax:
% dt_iono = delay_iono(llh, azim, elev, TOW, param_iono);
%
%
% Inputs : 
%   llh :   User coordinates (latitude, longitude expressed in radian)
%           (only the latitude and the longitude are used)
%           [3,1] vector
%   azim :  satellite azimuth angle (in radian)
%   elev :  satellite elevation angle (in radian)
%   TOW :   User GPS time (Time Of Week in sec)
%   param_iono : Structure containing the Klobuchar ionospheric model
%                with fields: .alpha0
%                             .alpha1
%                             .alpha2
%                             .alpha3
%                             .beta0
%                             .beta1
%                             .beta2
%                             .beta3
%
% Output : 
%   delay_iono : Ionospheric propagation delay (in sec)
%



% Klobuchar ionospheric model parameters
alpha0 = param_iono.alpha0;
alpha1 = param_iono.alpha1;
alpha2 = param_iono.alpha2;
alpha3 = param_iono.alpha3;

beta0 = param_iono.beta0;
beta1 = param_iono.beta1;
beta2 = param_iono.beta2;
beta3 = param_iono.beta3;


% Conversion to semi-circle
Phi_u = llh(1)/pi;    % user geodetic latitude (semi-circle)
Lambda_u = llh(2)/pi; % user geodetic longitude (semi-circle)
azim = azim/pi;
elev = elev/pi;

% Earth centered angle between user position and ionospheric
% intersection point (semi-circle) 1sc --> pi rad
Psi = 0.0137/(elev+0.11) - 0.022;

% latitude of ionospheric intersection point (semi-circle)
Phi_i = Phi_u + Psi*cos(pi*azim);
if (Phi_i > 0.416)
    Phi_i = 0.416;
elseif (Phi_i < -0.416)
    Phi_i = -0.416;
end

% longitude of ionospheric intersection point (semi-circle)
Lambda_i = Lambda_u + Psi*sin(pi*azim)/cos(pi*Phi_i);

% geomagnetic latitude of ionospheric intersection point (semi-circle)
Phi_m = Phi_i + 0.064*cos(pi*(Lambda_i-1.617));

% amplitude of the ionospheric delay
AMP = alpha0 + alpha1*Phi_m + alpha2*Phi_m^2 + alpha3*Phi_m^3;
if (AMP < 0)
    AMP = 0;
end

% period of the ionospheric delay
PER = beta0 + beta1*Phi_m + beta2*Phi_m^2 + beta3*Phi_m^3;
if (PER < 72000)
    PER = 72000;
end

% local time (in second)
t = 4.32e4*Lambda_i + TOW;
t = mod(t,86400);

% phase
x = 2*pi*(t-50400)/PER;

% slant factor
F = 1 + 16*(0.53-elev)^3;

if (abs(x)<1.57)
    dt_iono = F * (5e-9 + AMP*(1 - x^2/2 + x^4/24));
else
    dt_iono = F * 5e-9; % at night time delay=5nS
end


end

