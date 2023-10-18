function [xyz_ned, J_llh2ned] = convert_llh2ned(llh, ref_llh, unit)

% Convert WGS84 LLH coordinates
% into NED coordinates (North East Down)
% (direct conversion from angle to distance)
%
% Syntax :
% xyz_ned = convert_llh2enu(llh, ref_llh);
% xyz_ned = convert_llh2enu(llh, ref_llh, unit);
% [xyz_ned, J_llh2ned] = convert_llh2ned(...);
%
%
% Input :
%   llh : WGS84 LLH coordinates [latitude; longitude; heigth]
%             [3,1] vector or [3,N] matrix
%             also accept [N,3] matrix if N>3
%   
%   ref_llh : Origin of the NED frame (WGS84 LLH coordinates)
%             [3,1] vector
%
%	unit : latitude and longitude unit (optional)
%          accepted values : 'rad' (default)
%                            'deg'
%
%
% Output :
%   xyz_ned : Converted coordinates in the NED frame
%             (same size as 'llh')
%
%   J_llh2ned : Jacobian matrix of the conversion
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

xyz_ned = [(llh(1,:) - ref_llh(1)) * Rlat; ...
           (llh(2,:) - ref_llh(2)) * Rlon; ...
          -(llh(3,:) - ref_llh(3))];
%--------------------------------------------------------------------------



%--------------------------------------------------------------------------
% Output transposition
%--------------------------------------------------------------------------
if is_transpose
    xyz_ned = xyz_ned';
end
%--------------------------------------------------------------------------



%--------------------------------------------------------------------------
% Output : Jacobian matrix
%--------------------------------------------------------------------------
if (nargout > 1)
    J_llh2ned = [Rlat 0   0;...
                  0  Rlon 0;...
                  0   0  -1];
    J_llh2ned(:,1:2) = J_llh2ned(:,1:2) * coef_unit2rad;
end
%--------------------------------------------------------------------------

end

