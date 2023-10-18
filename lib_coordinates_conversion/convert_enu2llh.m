function [llh, J_enu2llh] = convert_enu2llh(xyz_enu, ref_llh, unit)

% Convert ENU coordinates (East North Up)
% into corresponding WGS84 LLH coordinates
% (direct conversion from distance to angle)
% 
% Syntax :
% llh = convert_enu2llh(xyz_enu, ref_llh);
% llh = convert_enu2llh(xyz_enu, ref_llh, unit);
% [llh, J_enu2llh] = convert_enu2llh(...);
%
%
% Input :
%   xyz_enu : Coordinates in the ENU frame
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
%
%
% External function:
%   local_radius
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
llh = [ref_llh(1) + (xyz_enu(2,:) / Rlat); ...
       ref_llh(2) + (xyz_enu(1,:) / Rlon); ...
       ref_llh(3) +  xyz_enu(3,:)];
%--------------------------------------------------------------------------



%--------------------------------------------------------------------------
% Output : Conversion matrix
%--------------------------------------------------------------------------
J_enu2llh = [  0   1/Rlat 0;
             1/Rlon  0    0;
               0     0    1];
J_enu2llh(1:2, :) = J_enu2llh(1:2, :) * coef_rad2unit;
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

