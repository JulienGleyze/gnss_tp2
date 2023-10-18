function traj = kml_addpos(traj, t, llh, SVID, link)

% Add positions to the trajectory
%
% traj = kml_addpos(traj, t, llh);
% OR
% traj = kml_addpos(traj, t, llh, SVID);
% traj = kml_addpos(traj, t, llh, SVID, link);
%
%
% Inputs :
%	traj : Trajectory struct.
%          struct containing all the data of the trajectory
%
%   t :    [1,N] vector or scalar ("t" and "llh" sizes must match)
%          Time of the positions
%          (use GPS TOW if you want to display the satellites positions)
%
%   llh :  [3,N] matrix or [3,1] vector ("t" and "llh" sizes must match)
%          LLH coordinates of the trajectory
%          (Lat, Lon in degrees; Height in m)
%
% Optionnal inputs :
%   SVID : [1,M] vector, list of the satellites in vision
%   link : [1,M] vector, strength of the signal of the satellites
%          (see the "link_color" option)
%
%
% Outputs :
%	traj : Updated trajectory struct.
%          struct containing all the data of the trajectory
%
%
% Droits réservés ISAE.
% Contact : Benoit Priot
%             benoit.priot@isae.fr
%             (+33)5 61 33 83 66
%



if (nargin < 4), SVID = []; end
if (nargin < 5)
    link = [];
elseif (numel(link) ~= numel(SVID))
    disp('Warning: ''link'' and ''SVID'' must have the same size.')
    link = [];
end

if (size(llh, 1) ~= 3)
    llh = llh';
end

if (size(llh, 1) ~= 3)
    error('Invalid input ''llh'' size.');
end

if (size(llh, 2) ~= numel(t))
    error('Invalid input ''t'' size.');
end

n = traj.data.nb_points;
for k = 1:numel(t)
    n = n+1;
    if (n > numel(traj.data.t))
        % increase position buffer
        m = ceil(n*1.2);
        traj.data.t(1,m) = traj.data.t(1,1);
        traj.data.llh(1:3,m) = traj.data.llh(1:3,1);
        traj.data.range(1,m) = traj.data.range(1,1);
    end
    
    traj.data.t(1,n) = t(k);
    traj.data.llh(1:3,n) = llh(:,k);
    traj.data.range(1,n).SVID = SVID(:);
    traj.data.range(1,n).link = link(:);
end
traj.data.nb_points = n;

end


