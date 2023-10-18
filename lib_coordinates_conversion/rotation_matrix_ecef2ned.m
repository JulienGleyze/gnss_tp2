function R_ecef2ned = rotation_matrix_ecef2ned(ref_llh, unit)

% Rotation matrix
% between WGS84 ECEF frame and cartesian NED frame (North East Down)
%
% Syntax :
% R_ecef2ned = rotation_matrix_ecef2ned(ref_llh);
% R_ecef2ned = rotation_matrix_ecef2ned(ref_llh, unit);
%
%
% Input :
%   ref_llh :  Origin of the NED frame (WGS84 LLH coordinates)
%              [latitude; longitude; (height)]
%              [2,1] or [3,1] vector
%
%	unit : latitude and longitude unit (optional)
%          accepted values : 'rad' (default)
%                            'deg'
%
%
% Output :
%   R_ecef2ned : rotation matrix between ECEF frame and NED frame
%
% External function:
%   none
%


%--------------------------------------------------------------------------
% Latitude and longitude unit conversion (rad)
%--------------------------------------------------------------------------
if (nargin > 1)
    if strncmpi(unit, 'deg', 3)
        ref_llh(1:2) = ref_llh(1:2) * pi/180;
    end
end
%--------------------------------------------------------------------------



%--------------------------------------------------------------------------
% Rotation matrix
%--------------------------------------------------------------------------
% rotation along longitude and latitude
% (the position is obtained in a Up East North frame)
% axis are permuted from UEN to NED

lat = ref_llh(1);
lon = ref_llh(2);

P = [0 0 1; ...
     0 1 0; ...
    -1 0 0];

R_ecef2ned = P * rot_y(-lat) * rot_z(lon);
%--------------------------------------------------------------------------

end



%--------------------------------------------------------------------------
% Sub-functions
%--------------------------------------------------------------------------

function R = rot_z(angle)
% Compute the rotation matrix of a rotation along the Z axis
%
% Input :
%   angle :     rotation angle (radian)
%
% Output :
%   R :         rotation matrix
%

R = [cos(angle) sin(angle) 0 ; ...
    -sin(angle) cos(angle) 0 ; ...
         0          0      1 ];
end

%--------------------------------------------------------------------------

function R = rot_y(angle)
% Compute the rotation matrix of a rotation along the Y axis
%
% Input :
%   angle :     rotation angle (radian)
%
% Output :
%   R :         rotation matrix

R = [cos(angle) 0 -sin(angle) ; ...
         0      1      0      ; ...
     sin(angle) 0  cos(angle) ];

end

%--------------------------------------------------------------------------

