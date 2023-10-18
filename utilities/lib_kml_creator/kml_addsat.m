function traj = kml_addsat(traj, ephemeris)

% Add satellites "ephemeris" to the trajectory structure.
% The satellites positions will be displayed in GoogleEarth
%
% traj = kml_addsat(traj, ephemeris);
%
%
% Inputs :
%	traj : Trajectory struct.
%          struct containing all the data of the trajectory
%
%   ephemeris : [1,N] struct containing the ephemeris or the almanac
%               of the satellites (in the ISAE/SCAN standard format)
%
%
% Outputs :
%	traj : Updated trajectory struct.
%          struct containing all the data of the trajectory
%
%
% Also valid "ephemeris" inputs:
% > WGS84 LLH (fix satellite) 
%       sat.SVID = 101;             % id of the satellite
%       sat.llh = [0; 20; 35e6];    % lat,lon in deg; h in m
% 
% > WGS84 ECEF (fix satellite)
%       sat.SVID = 102;              % id of the satellite
%       sat.ecef = [30e6; -20e6; 0]; % coordinates in the ECEF frame in m
%
%
% Droits réservés ISAE.
% Contact : Benoit Priot
%             benoit.priot@isae.fr
%             (+33)5 61 33 83 66
%

for k = 1:length(ephemeris)
    if iscell(ephemeris(k))
        tmp_eph = ephemeris{k};
    else
        tmp_eph = ephemeris(k);
    end
    
    % test de "validite"
    if isfield(tmp_eph, 'SVID')
        if (numel(tmp_eph.SVID) == 1)
            if ~isnan(tmp_eph.SVID)
                traj.data.ephemeris{1,end+1} = tmp_eph;
            end
        end
    end
end

end
