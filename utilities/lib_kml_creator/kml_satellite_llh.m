function llh_sat = kml_satellite_llh(ephemeris, t)

% This function computes the satellite position in WGS84 LLH frame
% Support GPS ephemeris, GPS almanac, WGS84 llh, WGS84 xyz
% (subfunction)
%
% llh_sat = kml_satellite_llh(ephemeris, t);
%
%
% Inputs :
%   ephemeris :         GPS ephemeris, GPS almanac, WGS84 llh, WGS84 ecef
%   t:                  Satellite time (GPS TOW)
%
% Outputs :
%   llh_sat :           Satellite coordinates (WGS 84 llh in deg, deg, m)
%
%
% Droits reserves ISAE.
% Contact : Benoit Priot
%             benoit.priot@isae.fr
%             (+33)5 61 33 83 66
%

t = t(:)';

if isfield(ephemeris, 'llh')
    llh(1:3,1)  = ephemeris.llh;
    llh_sat     = repmat(llh, 1, length(t));
    
elseif isfield(ephemeris, 'ecef')
    ecef(1:3,1) = ephemeris.ecef;
    llh_sat     = repmat(ecef_2_llh(ecef), 1, length(t));
    
elseif isfield(ephemeris, 'toa')
    xyz_sat     = gps_almanac(ephemeris, t);
    llh_sat     = ecef_2_llh(xyz_sat);
    
elseif isfield(ephemeris, 'toe')
    xyz_sat     = gps_ephemeris(ephemeris, t);
    llh_sat     = ecef_2_llh(xyz_sat);
    
else
    error('Unknown ephemeris.')
end

end % function kml_satellite_llh



%--------------------------------------------------------------------------
% Sub-functions
%--------------------------------------------------------------------------

function xyz_sat = gps_ephemeris(ephemeris, t)

% Warning : this is a subfunction, not to be used alone
%
% Computes the satellite position at the time t, from the gps ephemeris
% return an error if the ephemeris is invalid
%
% xyz_sat = gps_ephemeris(ephemeris, t);
% gps_ephemeris(ephemeris);
%
%
% Inputs :
%   ephemeris :         ephemeris broadcast by the satellite
%   t:                  Satellite time (GPS TOW)
%
% Outputs :
%   xyz_sat :           Satellite coordinates in ECEF frame
%                       (WGS 84 xyz)


%-----------------------------------------------------------------
% Ephemeris parameters used for computing the satellite position :
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

toe(1)       = ephemeris.toe;
e(1)         = ephemeris.e;
sqrt_A(1)    = ephemeris.sqrt_A;
i0(1)        = ephemeris.i0;
i_dot(1)     = ephemeris.i_dot;
Omega0(1)    = ephemeris.Omega0;
Omega_dot(1) = ephemeris.Omega_dot;
omega(1)     = ephemeris.omega;
M0(1)        = ephemeris.M0;
Delta_n(1)   = ephemeris.Delta_n;
Cuc(1)       = ephemeris.Cuc;
Cus(1)       = ephemeris.Cus;
Crc(1)       = ephemeris.Crc;
Crs(1)       = ephemeris.Crs;
Cic(1)       = ephemeris.Cic;
Cis(1)       = ephemeris.Cis;

if any(isnan([toe, e, sqrt_A, i0, i_dot, Omega0, Omega_dot, omega, ...
              M0, Delta_n, Cuc, Cus, Crc, Crs, Cic, Cis]))
    error('invalid ephemeris.')
end

if (nargin == 1) || isempty(t)
    xyz_sat = zeros(3,0);
    return
end
%-----------------------------------------------------------------


% WGS 84 parameters
mu = 3.986005e14;      % WGS 84 value of the Earth gravitational constant
Omega_e_dot = 7.2921151467e-5; % Earth's rotation rate in rd/s   


%-----------------------------------------
% Determination of the satellite position   
%-----------------------------------------
t = t(:)';

a = sqrt_A .^2;        % semi-major axis
n0 = sqrt(mu ./ (a.^3));    % average angular velocity = 2pi/T_orbit
tk = t - toe;          % time from ephemeris reference epoch
tk = mod(tk + 302400, 604800) - 302400;
n = n0 + Delta_n;       % correction of the average angular velocity
Mk = M0 + (n .* tk);         % mean anomaly

% The Kepler's equation for eccentric anomaly
% Mk=Ek-e.sin(Ek) must be solved by iteration 
Ek = zeros(size(t)); tmp_Ek = ones(size(t));    
while any(abs(Ek - tmp_Ek) > 1e-9)
    tmp_Ek = Ek;
    Ek = Mk + e.*sin(tmp_Ek);
end
   
% The orbit radius and the satellite position is computed
rk  = a .* (1 - e.*cos(Ek));  
rxk = a .* (cos(Ek) - e); 
ryk = a .* sqrt(1 - e.^2) .* sin(Ek);

% The true anomaly is computed
nuk = atan2(ryk, rxk);

% The argument of latitude (omega +nu) is computed
phik = nuk + omega; 
   
% Second harmonic perturbations must be considered
delta_uk = (Cus .* sin(2*phik)) + (Cuc .* cos(2*phik));   % Arg of latitude correction
delta_rk = (Crs .* sin(2*phik)) + (Crc .* cos(2*phik));   % Radius correction
delta_ik = (Cis .* sin(2*phik)) + (Cic .* cos(2*phik));   % Inclination correction
   
% correction are applied
uk = phik + delta_uk;               % corrected argument of latitude
rk = rk + delta_rk;                 % corrected radius 
ik = i0 + delta_ik + (i_dot .* tk);        % corrected inclination

% Argument of the RAAN
Omegak = Omega0 + (Omega_dot .* tk) - (Omega_e_dot .* t);

% Satellite position in orbital plane after correction
rxk = rk .* cos(uk);
ryk = rk .* sin(uk);

% Expression of the position in the ECEF frame
xk = rxk.*cos(Omegak) - ryk.*cos(ik).*sin(Omegak);
yk = rxk.*sin(Omegak) + ryk.*cos(ik).*cos(Omegak);
zk = ryk.*sin(ik);

xyz_sat = [xk; yk; zk];

end %function gps_ephemeris

%--------------------------------------------------------------------------

function xyz_sat = gps_almanac(almanac, t)

% Warning : this is a subfunction, not to be used alone
%
% Computes the satellite position at the time t, from the gps almanac
% return an error if the almanac is invalid
%
% xyz_sat = gps_almanac(almanac, t);
% gps_almanac(almanac);
%
%
% Inputs :
%   almanac :           almanac broadcast by the satellite
%   t:                  Satellite time (GPS TOW)
%
% Outputs :
%   xyz_sat :           Satellite coordinates in ECEF frame
%                       (WGS 84 xyz)


%---------------------------------------------------------------
% Almanac parameters used for computing the satellite position :
%   - toa which is the almanac refence time
%   - e which is the eccentricity
%   - sqrt_A which is the square root of the semi-major axis
%   - delta_i which is the correction of the inclination angle
%   - Omega0 which is the longitude of the ascending node 
%           at the beginning pf the GPS week
%   - Omega_dot which is the rate of change of rigth ascension of 
%           the ascending node  (RAAN)
%   - omega which is the argument of perigee
%   - M0 which is the mean anomaly at the reference time

toa(1)       = almanac.toa;
e(1)         = almanac.e;
sqrt_A(1)    = almanac.sqrt_A;
delta_i(1)   = almanac.delta_i;
Omega0(1)    = almanac.Omega0;
Omega_dot(1) = almanac.Omega_dot;
omega(1)     = almanac.omega;
M0(1)        = almanac.M0;

if any(isnan([toa, e, sqrt_A, delta_i, Omega0, Omega_dot, omega M0]))
    error('invalid almanach.')
end

if (nargin == 1) || isempty(t)
    xyz_sat = zeros(3,0);
    return
end
%---------------------------------------------------------------


% WGS 84 parameters
mu = 3.986005e14;      % WGS 84 value of the Earth gravitational constant
Omega_e_dot = 7.2921151467e-5; % Earth's rotation rate in rd/s


%-----------------------------------------
% Determination of the satellite position   
%-----------------------------------------
t = t(:)';

a = sqrt_A.^2;        % semi-major axis
n0 = sqrt(mu/a^3);    % average angular velocity = 2pi/T_orbit
tk = t - toa;          % time from almanac reference epoch
tk = mod(tk + 302400, 604800) - 302400;
Mk = M0 + (n0 .* tk);         % mean anomaly

% The Kepler's equation for eccentric anomaly
% Mk=Ek-e.sin(Ek) must be solved by iteration 
Ek = zeros(size(t)); tmp_Ek = ones(size(t));    
while any(abs(Ek - tmp_Ek) > 1e-9)
    tmp_Ek = Ek;
    Ek = Mk + e.*sin(tmp_Ek);
end
   
% The orbit radius and the satellite position is computed
rk  = a .* (1 - e.*cos(Ek));  
rxk = a .* (cos(Ek) - e); 
ryk = a .* sqrt(1 - e.^2) .* sin(Ek);

% The true anomaly is computed
nuk = atan2(ryk, rxk);

% The argument of latitude (omega +nu) is computed
uk = nuk + omega; 
   
% correction are applied
ik = 0.3*pi + delta_i;        % corrected inclination

% Argument of the RAAN
Omegak = Omega0 + (Omega_dot .* tk) - (Omega_e_dot .* t);

% Satellite position in orbital plane after correction
rxk = rk .* cos(uk);
ryk = rk .* sin(uk);

% Expression of the position in the CIRS
xk = rxk.*cos(Omegak) - ryk.*cos(ik).*sin(Omegak);
yk = rxk.*sin(Omegak) + ryk.*cos(ik).*cos(Omegak);
zk = ryk.*sin(ik);

xyz_sat = [xk; yk; zk];

end %function gps_almanac

%--------------------------------------------------------------------------

function llh = ecef_2_llh(xyz)

% Convert geocentric (ECEF) to geodetic (llh) coordinates
%
% llh = ecef_2_llh(xyz)
%
% xyz : <3xN> Geocentric Cartesian coordinates (in m)
% llh : <3xN> Geodetic coordinates [latitude Longitude Height] (in deg,deg,m)
%               Refer to the WGS84 ellipsoid

% From the function ecef2geodetic of the Aerospace Toolbox
% Copyright 2005-2008 The MathWorks, Inc.
% $Revision: 1.1.6.3 $  $Date: 2008/04/03 03:17:08 $

% Reference
% ---------
% Paul R. Wolf and Bon A. Dewitt, "Elements of Photogrammetry with
% Applications in GIS," 3rd Ed., McGraw-Hill, 2000 (Appendix F-3).

% Implementation Notes from Rob Comer
% -----------------------------------
% The implementation below follows Wolf and DeWitt quite literally,
% with a few important exceptions required to ensure good numerical
% behavior:
%
% 1) I used ATAN2 rather than ATAN in the formulas for beta and phi.  This
%    avoids division by zero (or a very small number) for points on (or
%    near) the Z-axis.
%
% 2) Likewise, I used ATAN2 instead of ATAN when computing beta from phi
%    (conversion from geodetic to parametric latitude), ensuring
%    stability even for points at very high latitudes.
%
% 3) Finally, I avoided dividing by cos(phi) -- also problematic at high
%    latitudes -- in the calculation of h, the height above the ellipsoid.
%    Wold and Dewitt give
%
%                   h = sqrt(X^2 + Y^2)/cos(phi) - N.
%
%    The trick is to notice an alternative formula that involves division
%    by sin(phi) instead of cos(phi), then take a linear combination of the
%    two formulas weighted by cos(phi)^2 and sin(phi)^2, respectively. This
%    eliminates all divisions and, because of the identity cos(phi)^2 +
%    sin(phi)^2 = 1 and the fact that both formulas give the same h, the
%    linear combination is also equal to h.
%
%    To obtain the alternative formula, we simply rearrange
%
%                   Z = [N(1 - e^2) + h]sin(phi)
%    into
%                   h = Z/sin(phi) - N(1 - e^2).
%
%    The linear combination is thus
%
%        h = (sqrt(X^2 + Y^2)/cos(phi) - N) cos^2(phi)
%            + (Z/sin(phi) - N(1 - e^2))sin^2(phi)
%
%    which simplifies to
%
%      h = sqrt(X^2 + Y^2)cos(phi) + Zsin(phi) - N(1 - e^2sin^2(phi)).
%
%    From here it's not hard to verify that along the Z-axis we have
%    h = Z - b and in the equatorial plane we have h = sqrt(X^2 + Y^2) - a.

% Ellipsoid constants
a = 6378137.0000;       % earth semimajor axis in meters
b = 6356752.3142;       % earth semiminor axis in meters
e2 = (1 - (b/a)^2);     % Square excentricity
ep2 = e2 / (1 - e2);  	% Square of second eccentricity
f = 1 - sqrt(1 - e2); 	% Flattening

% ECEF coordinates
x = xyz(1,:);
y = xyz(2,:);
z = xyz(3,:);

% Longitude
lambda = atan2(y,x);

% Distance from Z-axis
rho = hypot(x,y);

% Bowring's formula for initial parametric (beta) and geodetic (phi) latitudes
beta = atan2(z, (1 - f) * rho);
phi = atan2(z   + b * ep2 * sin(beta).^3,...
            rho - a * e2  * cos(beta).^3);

% Fixed-point iteration with Bowring's formula
% (typically converges within two or three iterations)
betaNew = atan2((1 - f)*sin(phi), cos(phi));
count = 0;
while any(beta(:) ~= betaNew(:)) && count < 5
    beta = betaNew;
    phi = atan2(z   + b * ep2 * sin(beta).^3,...
                rho - a * e2  * cos(beta).^3);
    betaNew = atan2((1 - f)*sin(phi), cos(phi));
    count = count + 1;
end

% Calculate ellipsoidal height from the final value for latitude
sinphi = sin(phi);
N = a ./ sqrt(1 - e2 * sinphi.^2);
h = rho .* cos(phi) + (z + e2 * N .* sinphi) .* sinphi - N;


llh = [phi*180/pi; lambda*180/pi; h];

end % function ecef_2_llh

%--------------------------------------------------------------------------


