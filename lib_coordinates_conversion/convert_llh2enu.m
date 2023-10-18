function [xyz_enu, J_llh2enu] = convert_llh2enu(llh, ref_llh, unit)

% Convert WGS84 LLH coordinates
% into ENU coordinates (East North Up)
% (direct conversion from angle to distance)
%
% Syntax :
% xyz_enu = convert_llh2enu(llh, ref_llh);
% xyz_enu = convert_llh2enu(llh, ref_llh, unit);
% [xyz_enu, J_llh2enu] = convert_llh2enu(...);
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
%   xyz_enu : Converted coordinates in the ENU frame
%             (same size as 'llh')
%
%   J_llh2enu : Jacobian matrix of the conversion
%
%
% External function:
%   local_radius
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
% local Earth radius of curvature
[Rlat, Rlon] = local_radius(ref_llh, 'rad');

xyz_enu = [(llh(2,:) - ref_llh(2)) * Rlon; ...
           (llh(1,:) - ref_llh(1)) * Rlat; ...
           (llh(3,:) - ref_llh(3))];
%--------------------------------------------------------------------------



%--------------------------------------------------------------------------
% Output : transposition
%--------------------------------------------------------------------------
if is_transpose
    xyz_enu = xyz_enu';
end
%--------------------------------------------------------------------------



%--------------------------------------------------------------------------
% Output : Jacobian matrix
%--------------------------------------------------------------------------
if (nargout > 1)
    J_llh2enu = [ 0  Rlon 0;...
                 Rlat 0   0;...
                  0   0   1];
    J_llh2enu(:,1:2) = J_llh2enu(:,1:2) * coef_unit2rad;
end
%--------------------------------------------------------------------------

end

