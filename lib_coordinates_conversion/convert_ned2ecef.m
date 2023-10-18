function [xyz_ecef, R_ned2ecef] = convert_ned2ecef(xyz_ned, ref_ecef)

% Convert cartesian NED coordinates (North East Down)
% into WGS84 ECEF coordinates
%
% Syntax :
% xyz_ecef = convert_ned2ecef(xyz_ned, ref_ecef);
% [xyz_ecef, R_ned2ecef] = convert_ned2ecef(xyz_ned, ref_ecef);
%
%
% Input :
%   xyz_ned : Coordinates in the cartesian NED frame
%             [3,1] vector or [3,N] matrix
%             also accept [N,3] matrix if N>3
%   
%   ref_ecef : Origin of the NED frame (WGS84 ECEF coordinates)
%              [3,1] vector
%
%
% Output :
%   xyz_ecef : Converted WGS84 ECEF coordinates
%              (same size as 'xyz_ned')
%
%   R_ned2ecef : Rotation matrix between NED frame and ECEF frame
%                (jacobian matrix of the conversion)
%
%
% External function:
%   convert_ecef2llh
%


%--------------------------------------------------------------------------
% Input size verification
%--------------------------------------------------------------------------
if (size(xyz_ned, 1) == 3)
    is_transpose = false;
else
    xyz_ned = xyz_ned';
    is_transpose = true;
end

if (size(xyz_ned, 1) ~= 3)
    error('Input ''xyz_ned'' must be a [3,N] matrix.');
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
% axis are permuted from NED to UEN (Up East North)
% rotation along latitude and longitude
P = [0  0 -1; ...
     0  1  0; ...
     1  0  0];

ref_llh = convert_ecef2llh(ref_ecef, 'rad');
lat = ref_llh(1);
lon = ref_llh(2);

R_ned2ecef = rot_z(-lon) * rot_y(lat) * P;
d_xyz_ecef = R_ned2ecef * xyz_ned;

xyz_ecef = [ref_ecef(1) + d_xyz_ecef(1,:); ...
            ref_ecef(2) + d_xyz_ecef(2,:); ...
            ref_ecef(3) + d_xyz_ecef(3,:)];
%--------------------------------------------------------------------------



%--------------------------------------------------------------------------
% Output transposition
%--------------------------------------------------------------------------
if is_transpose
    xyz_ecef = xyz_ecef';
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

