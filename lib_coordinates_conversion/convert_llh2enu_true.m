function [xyz_enu, J_llh2enu] = convert_llh2enu_true(llh, ref_llh, unit)

% Convert WGS84 LLH coordinates
% into cartesian ENU coordinates (East North Up)
% (true conversion between coordinate frames)
%
% Syntax :
% xyz_enu = convert_llh2enu_true(llh, ref_llh);
% xyz_enu = convert_llh2enu_true(llh, ref_llh, unit);
% [xyz_enu, J_llh2enu] = convert_llh2enu_true(...);
%
%
% Input :
%   llh : WGS84 LLH coordinates [latitude; longitude; heigth]
%             [3,1] vector or [3,N] matrix
%             also accept [N,3] matrix if N>3
%   
%   ref_llh : Origin of the ENU frame (WGS84 LLH coordinates)
%             [3,1] vector
%
%	unit : latitude and longitude unit (optional)
%          accepted values : 'rad' (default)
%                            'deg'
%
%
% Output :
%   xyz_enu : Converted coordinates in the cartesian ENU frame
%             (same size as 'llh')
%
%   J_llh2enu : Jacobian matrix of the conversion
%               (only for the first position)
%
%
% External function:
%   convert_llh2ecef
%


%--------------------------------------------------------------------------
% Input size verification
%--------------------------------------------------------------------------
if (size(llh, 1) == 3)
    is_transpose = false;
else
    llh = llh';
    is_transpose = true;
end

if (size(llh, 1) ~= 3)
    error('Input ''llh'' must be a [3,N] matrix.');
end

if (numel(ref_llh) == 3)
    ref_llh = ref_llh(:);
else
    error('Input ''ref_llh'' must be a [3,1] vector.');
end
%--------------------------------------------------------------------------



%--------------------------------------------------------------------------
% Latitude and longitude unit conversion (to rad)
%--------------------------------------------------------------------------
coef_unit2rad = 1;
if (nargin > 2)
    if strncmpi(unit, 'deg', 3)
        coef_unit2rad = pi/180;
    end
end

llh(1:2,:) = llh(1:2,:) * coef_unit2rad;
ref_llh(1:2) = ref_llh(1:2) * coef_unit2rad;
%--------------------------------------------------------------------------



%--------------------------------------------------------------------------
% Coordinates conversion
%--------------------------------------------------------------------------
% LLH to ECEF
if (nargout > 1)
    [xyz_ecef, J_llh2ecef] = convert_llh2ecef(llh, 'rad');
else
    xyz_ecef = convert_llh2ecef(llh, 'rad');
end

ref_ecef = convert_llh2ecef(ref_llh, 'rad');


% relative position in ECEF frame
d_xyz_ecef = [xyz_ecef(1,:) - ref_ecef(1); ...
              xyz_ecef(2,:) - ref_ecef(2); ...
              xyz_ecef(3,:) - ref_ecef(3)];


% ECEF to ENU:
% rotation along longitude and latitude
% (the position is obtained in a Up East North frame)
% axis are permuted from UEN to ENU
lat = ref_llh(1);
lon = ref_llh(2);

P = [0 1 0; ...
     0 0 1; ...
     1 0 0];
R_ecef2enu = P * rot_y(-lat) * rot_z(lon);

xyz_enu = R_ecef2enu * d_xyz_ecef;
%--------------------------------------------------------------------------



%--------------------------------------------------------------------------
% Output : Jacobian matrix
%--------------------------------------------------------------------------
if (nargout > 1)
    J_llh2enu = R_ecef2enu * J_llh2ecef;
    J_llh2enu(:, 1:2) = J_llh2enu(:, 1:2) * coef_unit2rad;
end
%--------------------------------------------------------------------------



%--------------------------------------------------------------------------
% Output : transposition
%--------------------------------------------------------------------------
if is_transpose
    xyz_enu = xyz_enu';
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

