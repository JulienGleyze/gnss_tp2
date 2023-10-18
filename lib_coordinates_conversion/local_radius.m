function [Rlat, Rlon, R0lat, R0lon] = local_radius(llh, unit)

% Compute local latitude and longitude radius
%
% Syntax :
% [Rlat, Rlon] = local_radius(llh);
% [Rlat, Rlon] = local_radius(llh, unit);
% [Rlat, Rlon, R0lat, R0lon] = local_radius(...);
%
%
% Input :
%   llh : WGS84 LLH coordinates
%         [latitude; longitude; heigth]
%         [3,1] vector
%
%	unit : latitude and longitude unit (optional)
%          accepted values : 'rad' (default)
%                            'deg'
% 
%
% Output :
%   Rlat : local latitude radius (in meter), include the height
%   Rlon : local longitude radius (in meter), include the height
%   R0lat : meridian radius (in meter)
%   R0lon : transverse radius (in meter)
%
%
% External function:
%   none
%


%--------------------------------------------------------------------------
% Input size verification
%--------------------------------------------------------------------------
if (numel(llh) ~= 3)
    error('Input ''llh'' must be a [3,1] vector.');
end
%--------------------------------------------------------------------------



%--------------------------------------------------------------------------
% Latitude and longitude unit conversion (rad)
%--------------------------------------------------------------------------
if (nargin > 1)
    if strncmpi(unit, 'deg', 3)
        llh(1:2) = llh(1:2) * pi/180;
    end
end
%--------------------------------------------------------------------------



%--------------------------------------------------------------------------
% Coordinates conversion
%--------------------------------------------------------------------------
% WGS84 parameters
a = 6378137.0000;        % Earth semimajor axis in meters
b = 6356752.3142;        % Earth semiminor axis in meters
e2 = 1 - (b/a).^2;       % Earth square eccentricity

% local Earth radius of curvature
lat = llh(1);
h = llh(3);
tmp = 1 - (e2 * sin(lat)^2);
R0lat = a * (1 - e2) / (tmp^1.5); % meridian radius
R0lon = a / sqrt(tmp);            % transverse radius

% local latitude, longitude radius
Rlat = R0lat + h;
Rlon = (R0lon + h) * cos(lat);
%--------------------------------------------------------------------------


end

