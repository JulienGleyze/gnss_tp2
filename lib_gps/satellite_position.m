function [pos_sat, vel_sat, dt_relat] = satellite_position(ephemeris, TOW_sv, TOW_rx)

% Satellite position and velocity in ECEF frame
%
% Syntax :
% pos_sat = satellite_position(ephemeris, TOW_sv, TOW_rx);
% [pos_sat, vel_sat, dt_relat] = satellite_position(ephemeris, TOW_sv, TOW_rx);
% [pos_sat, vel_sat, dt_relat] = satellite_position(ephemeris, TOW);
%
%
% This function computes the satellite position at the time TOW_sv
% TOW_rx is used to correct the earth rotation during travel time
% (travel time = TOW_rx - TOW_sv)
%
%
% Inputs :
%   ephemeris :  Ephemeris broadcast by the satellite
%   TOW_sv :     Satellite time (in s)
%
% Inputs (optionnal) :
%   TOW_rx :     Receiver time (in s) (for earth rotation correction)
%
%
% Outputs
%   pos_sat :   Position of the satellite (WGS84 ECEF coordinates) (in m)
%   vel_sat :   Velocity of the satellite (WGS84 ECEF coordinates) (in m/s)
%   dt_relat :  Relativistic correction (satellite time correction) (in s)
%
%
% NB:
% This function has been "vectorized" :
%   If TOW_sv and TOW_rx are vector of length N,
%   pos_sat is a 3xN matrix,
%   vel_sat is a 3xN matrix,
%   dt_relat is a 1xN matrix
%

%--------------------------------------------------------------------------
%% Input gestion
%--------------------------------------------------------------------------
TOW_sv = TOW_sv(:)';
if (nargin < 3)
    TOW_rx = TOW_sv;
else
    TOW_rx = TOW_rx(:)';
end
if (length(TOW_sv) ~= length(TOW_rx))
    error('"ts" and "tr" dimensions must agree.');
end

%--------------------------------------------------------------------------
%% Constants definition
%--------------------------------------------------------------------------
mu          = 3.986005e14;      % WGS 84 value of the Earth gravitational constant
c           = 2.99792458e8;     % speed of light in m/s
Omega_e_dot = 7.2921151467e-5;  % Earth's rotation rate in rad/s   

%--------------------------------------------------------------------------
%% Ephemeris parameters used for computing the satellite position
%--------------------------------------------------------------------------
toe       = ephemeris.toe;
e         = ephemeris.e;
sqrt_A    = ephemeris.sqrt_A;
i0        = ephemeris.i0;
i_dot     = ephemeris.i_dot;
Omega0    = ephemeris.Omega0;
Omega_dot = ephemeris.Omega_dot;
omega     = ephemeris.omega;
M0        = ephemeris.M0;
Delta_n   = ephemeris.Delta_n;
Cuc       = ephemeris.Cuc;
Cus       = ephemeris.Cus;
Crc       = ephemeris.Crc;
Crs       = ephemeris.Crs;
Cic       = ephemeris.Cic;
Cis       = ephemeris.Cis;

% The ephemeris include :
%   - af0, af1, af2 which are the polynomial coefficients of the satellite
%           code phase offset
%   - tgd which is the estimated group delay differential
%   - toc which is the clock data reference time
%   - toe which is the ephemeris refence time
%   - e which is the eccentricity
%   - sqrt_A which is the square root of the semi-major axis
%   - i0 which is the inclination angle at the reference time 
%   - i_dot which is the rate of change of inclination with time
%   - Omega0 which is the longitude of the ascending node 
%           at the beginning pf the GPS week
%   - Omega_dot which is the rate of change of rigth ascension of 
%           the ascending node  (RAAN)
%   - omega which is the argument of perigee
%   - M0 which is the mean anomaly at the reference time
%   - Delta_n which is the mean motion difference from the computed value
%   - Cuc and Cus which are the amplitudes of harmonic correction terms
%           for the computed argument of latitude
%   - Crc and Crs which are the amplitudes of harmonic correction terms
%           for the computed orbit radius
%   - Cic and Cis which are the amplitudes of harmonic correction terms
%           for the computed inclination angle


%--------------------------------------------------------------------------
%% Determination of the satellite position   
%--------------------------------------------------------------------------
% The equations are from the GPS interface specification IS-GPS-200D (p97)

A   = sqrt_A^2;         % semi-major axis
n0  = sqrt(mu / A^3);   % computed mean motion
                        % (angular velocity = 2*pi/T_orbit)
tk  = TOW_sv - toe;    	% time from ephemeris reference epoch
n   = n0 + Delta_n;   	% corrected mean motion
Mk  = M0 + n*tk;      	% mean anomaly

% Kepler's equation for eccentric anomaly (see slide 42)
% Mk=Ek-e.sin(Ek) must be solved by iteration
Ek0 = Mk;
Ek  = Mk + e*sin(Ek0);
while any(abs(Ek - Ek0) > 1e-9)
    Ek0 = Ek;
    Ek = Mk + e*sin(Ek);
end

nuk = atan2(sqrt(1 - e^2)*sin(Ek), cos(Ek)-e);	% true anomaly
                                                % (1-e*cos(Ek))>0
phik = nuk + omega;                             % argument of latitude
sin_2phik = sin(2*phik);
cos_2phik = cos(2*phik);

% Second harmonic perturbations
duk = Cus*sin_2phik + Cuc*cos_2phik;   % arg of latitude correction
drk = Crs*sin_2phik + Crc*cos_2phik;   % radius correction
dik = Cis*sin_2phik + Cic*cos_2phik;   % inclination correction

rk = A * (1 - e*cos(Ek)) + drk;     % corrected radius
uk = phik + duk;                    % corrected argument of latitude
ik = i0 + dik + i_dot*tk;           % corrected inclination
Omegak = Omega0 + Omega_dot*tk;     % argument of the RAAN
Omegak = Omegak - Omega_e_dot*TOW_rx; % correction of the Earth rotation

% position in orbital plane
rxk = rk .* cos(uk);
ryk = rk .* sin(uk);

% position of the satellite (WGS84 ECEF coordinates)
yik = ryk .* cos(ik);
xk = rxk .* cos(Omegak) - yik .* sin(Omegak);
yk = rxk .* sin(Omegak) + yik .* cos(Omegak);
zk = ryk .* sin(ik);

pos_sat = [xk; yk; zk];
%--------------------------------------------------------------------------



if (nargout < 2), return, end
%--------------------------------------------------------------------------
%% Determination of the satellite velocity 
%--------------------------------------------------------------------------

% mean anomaly
Mk_dot = n;

% eccentric anomaly
% Mk = Ek-e*sin(Ek)
Ek_dot = Mk_dot ./ (1 - e*cos(Ek));

% true anomaly
nuk_dot = Ek_dot .* sqrt(1 - e^2) ./ (1 - e*cos(Ek));

% Second harmonic perturbations
duk_dot = 2*nuk_dot .* (Cus*cos_2phik - Cuc*sin_2phik);
drk_dot = 2*nuk_dot .* (Crs*cos_2phik - Crc*sin_2phik);
dik_dot = 2*nuk_dot .* (Cis*cos_2phik - Cic*sin_2phik);

rk_dot = (A * e * Ek_dot .* sin(Ek)) + drk_dot;
uk_dot = nuk_dot + duk_dot;
ik_dot = i_dot + dik_dot;

% argument of the RAAN corrected of the Earth rotation
Omegak_dot = Omega_dot - Omega_e_dot;

% position in orbital plane
rxk_dot = (rk_dot .* cos(uk)) - (rk .* uk_dot .* sin(uk));
ryk_dot = (rk_dot .* sin(uk)) + (rk .* uk_dot .* cos(uk));

% position of the satellite (WGS84 ECEF coordinates)
yik_dot = (ryk_dot .* cos(ik)) - (ryk .* ik_dot .* sin(ik));

xk_dot = (rxk_dot - yik.*Omegak_dot) .* cos(Omegak) ...
        -(yik_dot + rxk.*Omegak_dot) .* sin(Omegak);
    
yk_dot = (rxk_dot - yik.*Omegak_dot) .* sin(Omegak) ...
        +(yik_dot + rxk.*Omegak_dot) .* cos(Omegak);
    
zk_dot = (ryk_dot .* sin(ik)) + (ryk .* ik_dot .* cos(ik));

vel_sat = [xk_dot; yk_dot; zk_dot];
%--------------------------------------------------------------------------



if (nargout < 3), return, end
%---------------------------------------------------------------------------
%% relativistic error
%--------------------------------------------------------------------------
F = -2 * sqrt(mu) / c^2;
dt_relat = F * e * sqrt_A * sin(Ek);                
%--------------------------------------------------------------------------

end



