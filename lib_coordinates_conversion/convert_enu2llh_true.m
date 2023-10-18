function [llh, J_enu2llh] = convert_enu2llh_true(xyz_enu, ref_llh, unit)

% Convert cartesian ENU coordinates (East North Up)
% into corresponding WGS84 LLH coordinates
% (true conversion between coordinate frames)
%
% Syntax :
% llh = convert_enu2llh_true(xyz_enu, ref_llh);
% llh = convert_enu2llh_true(xyz_enu, ref_llh, unit);
% [llh, J_enu2llh] = convert_enu2llh_true(...);
%
%
% Input :
%   xyz_enu : Coordinates in the cartesian ENU frame
%             [3,1] vector or [3,N] matrix
%             also accept [N,3] matrix if N>3
%
%   ref_llh : Origin of the ENU frame (WGS84 LLH coordinates)
%             [latitude; longitude; heigth]
%             [3,1] vector
%
%	unit : latitude and longitude unit (optional)
%          accepted values : 'rad' (default)
%                            'deg'
% 
%
% Output :
%   llh : Converted WGS84 LLH coordinates [latitude; longitude; heigth]
%         (same size as 'xyz_enu')
%
%   J_enu2llh : Jacobian matrix of the conversion
%               (only for the first position)
%
%
% External function:
%   convert_llh2ecef
%   convert_ecef2llh
%


%--------------------------------------------------------------------------
% Input size verification
%--------------------------------------------------------------------------
if (size(xyz_enu, 1) == 3)
    is_transpose = false;
else
    xyz_enu = xyz_enu';
    is_transpose = true;
end

if (size(xyz_enu, 1) ~= 3)
    error('Input ''xyz_enu'' must be a [3,N] matrix.');
end

if (numel(ref_llh) == 3)
    ref_llh = ref_llh(:);
else
    error('Input ''ref_llh'' must be a [3,1] vector.');
end
%--------------------------------------------------------------------------



%--------------------------------------------------------------------------
% Latitude and longitude unit convertion (to rad)
%--------------------------------------------------------------------------
coef_rad2unit = 1;
if (nargin > 2)
    if strncmpi(unit, 'deg', 3)
        coef_rad2unit = 180/pi;
    end
else
    unit = 'rad';
end

ref_llh(1:2) = ref_llh(1:2) / coef_rad2unit;
%--------------------------------------------------------------------------



%--------------------------------------------------------------------------
% Coordinates conversion (using ECEF)
%--------------------------------------------------------------------------
% conversion to WGS84 ECEF
ref_ecef = convert_llh2ecef(ref_llh, 'rad');

% axis are permuted from ENU to UEN (Up East North)
% rotation along latitude and longitude
P = [0 0 1; ...
     1 0 0; ...
     0 1 0];

lat = ref_llh(1);
lon = ref_llh(2);
R_enu2ecef = rot_z(-lon) * rot_y(lat) * P;
d_xyz_ecef = R_enu2ecef * xyz_enu;

xyz_ecef = [ref_ecef(1) + d_xyz_ecef(1,:); ...
            ref_ecef(2) + d_xyz_ecef(2,:); ...
            ref_ecef(3) + d_xyz_ecef(3,:)];


% conversion to WGS84 LLH
if (nargout <= 1)
    llh = convert_ecef2llh(xyz_ecef, unit);
else
    % Jacobian matrix
    [llh, J_ecef2llh] = convert_ecef2llh(xyz_ecef, unit);
    J_enu2llh = J_ecef2llh * R_enu2ecef;
end
%--------------------------------------------------------------------------



%--------------------------------------------------------------------------
% Output : transposition
if is_transpose
    llh = llh';
end
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

