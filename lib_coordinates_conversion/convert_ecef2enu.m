function [xyz_enu, R_ecef2enu] = convert_ecef2enu(xyz_ecef, ref_ecef)

% Convert WGS84 ECEF coordinates
% into a cartesian ENU frame (East North Up)
%
% Syntax :
% xyz_enu = convert_ecef2enu(xyz_ecef, ref_ecef);
% [xyz_enu, R_ecef2enu] = convert_ecef2enu(xyz_ecef, ref_ecef);
%
%
% Input :
%   xyz_ecef : WGS84 ECEF coordinates
%             [3,1] vector or [3,N] matrix
%             also accept [N,3] matrix if N>3
%   
%   ref_ecef : Origin of the ENU frame (WGS84 ECEF coordinates)
%              [3,1] vector
%
%
% Output :
%   xyz_enu : Converted coordinates in the cartesian ENU frame
%             (same size as 'xyz_ecef')
%
%   R_ecef2enu : rotation matrix between ECEF frame and ENU frame
%                (jacobian matrix of the conversion)
%
%
% External function:
% 	convert_ecef2llh
%


%--------------------------------------------------------------------------
% Input size verification
%--------------------------------------------------------------------------
if (size(xyz_ecef, 1) == 3)
    is_transpose = false;
else
    xyz_ecef = xyz_ecef';
    is_transpose = true;
end

if (size(xyz_ecef, 1) ~= 3)
    error('Input ''xyz_ecef'' must be a [3,N] matrix.');
end

if (numel(ref_ecef) == 3)
    ref_ecef = ref_ecef(:);
else
    error('Input ''ref_ecef'' must be a [3,1] vector.');
end
%--------------------------------------------------------------------------



%--------------------------------------------------------------------------
% Coordinates conversion
%--------------------------------------------------------------------------
% relative position in ECEF frame
d_xyz_ecef = [xyz_ecef(1,:) - ref_ecef(1); ...
              xyz_ecef(2,:) - ref_ecef(2); ...
              xyz_ecef(3,:) - ref_ecef(3)];

% rotation along longitude and latitude
% (the position is obtained in a Up East North frame)
% axis are permuted from UEN to ENU
ref_llh = convert_ecef2llh(ref_ecef, 'rad');
lat = ref_llh(1);
lon = ref_llh(2);

P = [0 1 0; ...
     0 0 1; ...
     1 0 0];

R_ecef2enu = P * rot_y(-lat) * rot_z(lon);
xyz_enu = R_ecef2enu * d_xyz_ecef;
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

