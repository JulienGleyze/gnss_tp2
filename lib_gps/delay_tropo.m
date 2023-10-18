function dt_tropo = delay_tropo(elev, height, T0, P0, E0)

% Tropospheric propagation delay
%
% Syntax:
% dt_tropo = delay_tropo(elev, height);
% dt_tropo = delay_tropo(elev, height, T0, P0, E0);
%
%
% Inputs :
%   elev :   elevation angle of the satellite (in rad)
%   height : antenna height (in m)
%
% Inputs (optionnal) :
%   T0 : temperature at h=0 (in °celcius)  (default : 20)
%   P0 : pressure at h=0    (in millibar)  (default : 1013.2)
%   E0 : humidity ratio                    (default : 0.5)
% 
%  NB: for T0 and P0, if you want to use the values at the antenna level,
%      put the height input to 0
%
%
% Outputs :
%   dt_tropo : Tropospheric propagation delay (in s)
%


% Default values
if (nargin < 3)
    T0 = 20; % temperature
end
if (nargin < 4)
    P0 = 1013.2; % pressure
end
if (nargin < 5)
    E0 = 0.5; % humidity ratio
end

% Constantes
c = 2.99792458e8;


% Atmospheric condition at the antenna level
T = T0 + 273.16 - 6.5e-3*height;
P = P0 * (1 - 2.26e-5*height)^(5.225);
ee = 6.108 * E0 * exp((17.15*T - 4684)/(T - 38.45));


% "dry" (pressure) tropospheric path (in m)
Nd = 1e-6 * 77.6248/T;
Hd = 5 * 0.002277 /Nd;
d_dry = P * Nd * mapping_func(Hd, elev);


% "wet" (humidity) tropospheric path (in m)
Nw = 1e-6 * (-12.92/T + 3.1719e5/(T*T));
Hw = 5 * 0.002277 * (1255/T + 0.5)/Nw;
d_wet = ee * Nw * mapping_func(Hw, elev);


% total tropospheric delay
dt_tropo = (d_dry + d_wet)/c;

end

%--------------------------------------------------------------------------
% Sub-function
%--------------------------------------------------------------------------

function s = mapping_func(H, elev)

Re = 6378137;	% Earth Radius mean value at the equator

a = -sin(elev) / H; %m^-1
b = -cos(elev)*cos(elev) / (2*Re*H); %m^-2

A = zeros(9,1);
A(1) = 1;                      %m^0
A(2) = 4*a;                    %m^-1
A(3) = 6*a^2 + 4*b;            %m^-2
A(4) = 4*a*(a^2 +3*b);         %m^-3
A(5) = a^4 + 12*a^2*b + 6*b^2; %m^-4
A(6) = 4*a*b*(a^2 +3*b);       %m^-5
A(7) = b^2*(6*a^2 +4*b);       %m^-6
A(8) = 4*a*b^3;                %m^-7
A(9) = b^4;                    %m^-8

R = sqrt((Re + H)*(Re + H) - Re*Re*cos(elev)*cos(elev));
R = R - Re*sin(elev); %m

% s = 0;
% for k = 1:9
%     s = s + (A(k) * (R^k)/k);
% end

s = 0;
for k = 9:-1:1
    s = (s + A(k)/k)*R;
end

end

