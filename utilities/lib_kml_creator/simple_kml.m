function simple_kml(file, t, llh, color, ephemeris, mes_gps)

% Create a kml trajectory file and open it in GoogleEarth
%   for compatibility. Use preferably "export2kml"
%
% simple_kml(file, t, llh);
% OR
% simple_kml(file, t, llh, color);
% simple_kml(file, t, llh, color, ephemeris);
% simple_kml(file, t, llh, color, ephemeris, mes_gps);
%
%
% Inputs :
%	file : Name of the kml file
%
%   t :    [1,N] vector or scalar ("t" and "llh" sizes must match)
%          Time of the positions
%          (use GPS TOW if you want to display the satellites positions)
%
%   llh :  [3,N] matrix or [3,1] vector ("t" and "llh" sizes must match)
%          LLH coordinates of the trajectory
%          (Lat, Lon in degrees; Height in m)
%
%   color : color of the trajectory (char string)
%
%   ephemeris : [1,M] struct containing the ephemeris or the almanac
%               of the satellites (must be in the ISAE standard format)
%
%   mes_gps : struct containing the raw GPS measurements
%             (in the ISAE/SCAN standard format v1)
%
%
% Droits réservés ISAE.
% Contact : Benoit Priot
%             benoit.priot@isae.fr
%             (+33)5 61 33 83 66
%



%--------------------------------------------------------------------------
% creation de la structure trajectoire avec le nom du fichier kml
traj = kml_init(file);
% file = traj.file;
%--------------------------------------------------------------------------


%--------------------------------------------------------------------------
% options du kml
if (nargin < 4)
    traj.color = 'white';  % 'white' par défaut
else
    traj.color = color;    % 'white' par défaut
end

% référence de l'altitude (sea, ground, 2D)
traj.reference = 'sea';    % 'sea' par défaut

% correction des coordonnées pour l'affichage
traj.lat_corr  = 0;        % (en °)   0 par défaut
traj.lon_corr  = 0;        % (en °)   0 par défaut
traj.h_corr    = -40;      % (en m) -40 par défaut
%--------------------------------------------------------------------------


%--------------------------------------------------------------------------
% ajout des "ephemerides" satellites
if ((nargin < 5) || ~isfield(ephemeris,'SVID'))
    ephemeris = struct('SVID', []);
else
    traj = kml_addsat(traj, ephemeris);
end
%--------------------------------------------------------------------------


%--------------------------------------------------------------------------
% ajout des positions de la trajectoire
if ((nargin < 6) || (length(mes_gps) < 1))
    traj = kml_addpos(traj, t, llh, [ephemeris.SVID]);
    
elseif (length(mes_gps) == 1)
    SVID = mes_gps(1).SVID;
    CN0  = mes_gps(1).CN0(SVID);
    traj = kml_addpos(traj, t, llh, SVID, CN0);
    
else
    if (size(llh, 1) ~= 3)
        llh = llh';
    end
    if (size(llh, 1) ~= 3)
        error('Invalid input ''llh'' size.');
    end
    if (size(llh, 2) ~= numel(t))
        error('Invalid input ''t'' size.');
    end
    
    t_mes  = [mes_gps.ITOW];
    dt_mes = diff(t_mes);
    dt_mes = min(dt_mes(dt_mes>0));
    
    for k = 1:length(t)
        
        [dt, n] = min(abs(t(k) - t_mes));
        if (dt < dt_mes)
            SVID = mes_gps(n).SVID;
            CN0  = mes_gps(n).CN0(SVID);
            traj = kml_addpos(traj, t(k), llh(:,k), SVID, CN0);
        else
            traj = kml_addpos(traj, t(k), llh(:,k));
        end
    end
end
%--------------------------------------------------------------------------


%--------------------------------------------------------------------------
% creation du fichier et ouverture avec GoogleEarth
kml_create(traj, 1);
%--------------------------------------------------------------------------

end


