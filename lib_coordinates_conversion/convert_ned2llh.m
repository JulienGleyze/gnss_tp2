function [llh, J_ned2llh] = convert_ned2llh(xyz_ned, ref_llh, unit)

% Convert NED coordinates (North East Down)
% into corresponding WGS84 LLH coordinates
% (direct conversion from distance to angle)
%
% Syntax :
% llh = convert_ned2llh(xyz_ned, ref_llh);
% llh = convert_ned2llh(xyz_ned, ref_llh, unit);
% [llh, J_ned2llh] = convert_ned2llh(...);
%
%
% Input :
%   xyz_ned : Coordinates in the NED frame
%             [3,1] vector or [3,N] matrix
%             also accept [N,3] matrix if N>3
%
%   ref_llh : Origin of the NED frame (WGS84 LLH coordinates)
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
%         (same size as 'xyz_ned')
%
%   J_ned2llh : Jacobian matrix of the conversion
%
%
% External function:
%   local_radius
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

if (numel(ref_llh) == 3)
    ref_llh = ref_llh(:);
else
    error('Input ''ref_llh'' must be a [3,1] vector.');
end
%--------------------------------------------------------------------------



%--------------------------------------------------------------------------
% Latitude and longitude unit conversion (rad)
%--------------------------------------------------------------------------
coef_rad2unit = 1;
if (nargin > 2)
    if strncmpi(unit, 'deg', 3)
        coef_rad2unit = 180/pi;
    end
end

ref_llh(1:2) = ref_llh(1:2) / coef_rad2unit;
%--------------------------------------------------------------------------



%--------------------------------------------------------------------------
% Coordinates conversion
%--------------------------------------------------------------------------
% local Earth radius of curvature
[Rlat, Rlon] = local_radius(ref_llh, 'rad');

% conversion
llh = [ref_llh(1) + (xyz_ned(1,:) / Rlat); ...
       ref_llh(2) + (xyz_ned(2,:) / Rlon); ...
       ref_llh(3) -  xyz_ned(3,:)];
%--------------------------------------------------------------------------



%--------------------------------------------------------------------------
% Output : Conversion matrix
%--------------------------------------------------------------------------
J_ned2llh = [1/Rlat  0    0;
               0   1/Rlon 0;
               0     0   -1];
J_ned2llh(1:2, :) = J_ned2llh(1:2, :) * coef_rad2unit;
%--------------------------------------------------------------------------



%--------------------------------------------------------------------------
% Output : latitude and longitude unit conversion and transposition
%--------------------------------------------------------------------------
llh(1:2, :) = llh(1:2, :) * coef_rad2unit;

if is_transpose
    llh = llh';
end
%--------------------------------------------------------------------------

end

