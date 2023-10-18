function traj = kml_init(file)

% Create and initialize a trajectory structure
% This structure is used to create a kml file
%
% traj_struct = kml_init(file);
%
%
% Inputs :
%	file : Name of the kml file
%
%
% Outputs :
%	traj_struct : Trajectory structure.
%                 struct containing all the data of the trajectory
%
%
% Droits réservés ISAE.
% Contact : Benoit Priot
%             benoit.priot@isae.fr
%             (+33)5 61 33 83 66
%


[path, name] = fileparts(file);
if ~isempty(name)
    traj.file = fullfile(path, [name '.kml']);
else
    traj.file = 'trajectory.kml';
end

traj.color = 'white';
traj.lat_corr = 0; %1.5e-5;
traj.lon_corr = 0;
traj.h_corr = -40;
traj.reference = 'sea';
traj.link_color = [25 30 35];
traj.comment = '';

traj.data.nb_points = 0;
traj.data.t = 0;
traj.data.llh = zeros(3,1);
traj.data.range = struct('SVID',[], 'link', []);
traj.data.ephemeris = {};

end
