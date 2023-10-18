% Ce fichier est un récapitulatif de la syntaxe des fonction de:
% "lib_kml_creator"
%
% Droits réservés ISAE.
% Contact : Benoit Priot
%             benoit.priot@isae.fr
%             (+33)5 61 33 83 66
%



%% initialisation de la structure trajectoire avec le nom du fichier kml
traj = kml_init('trajectory.kml');



%--------------------------------------------------------------------------
%% options de la trajectoire

% couleur de la trajectoire
% white, grey, black, blue, red, green, cyan, magenta, yellow, orange
traj.color      = 'white';    % 'white' par défaut

% référence de l'altitude (sea, ground, 2D)
traj.reference  = 'sea';      % 'sea' par défaut

% correction des coordonnées pour l'affichage
traj.lat_corr   = 0;          % (en °)   0 par défaut
traj.lon_corr   = 0;          % (en °)   0 par défaut
traj.h_corr     = -40;        % (en m) -40 par défaut

% seuils de valeur pour la couleur des liens satellites
% couleurs correspondantes : vert, jaune, orange, rouge
traj.link_color = [35 30 25]; % [35 30 25] par défaut

% Commentaire inclu dans le fichier kml
traj.comment    = 'exemple de fichier kml';
%--------------------------------------------------------------------------



%--------------------------------------------------------------------------
%% ajout des satellites

% ephemerides GPS
traj     = kml_addsat(traj, ephemeris);

% almanachs GPS
traj     = kml_addsat(traj, almanac);

% coordonnées WGS84 LLH (satellite fixe) 
sat.SVID = 100;              % id du satellite
sat.llh  = [0; 20; 35e6];    % lat, lon en deg, h en m
traj     = kml_addsat(traj, sat);

% coordonnées WGS84 ECEF (satellite fixe)
sat.SVID = 102;              % id du satellite
sat.ecef = [30e6; -20e6; 0]; % coordonnees dans le repere ECEF en m
traj     = kml_addsat(traj, sat);
%--------------------------------------------------------------------------



%--------------------------------------------------------------------------
%% ajout des positions de la trajectoire
% latitude en °, longitude en °, altitude en m
% pour afficher correctement la position des satellites, t = TOW GPS

% ajout d'un tableau de positions
traj = kml_addpos(traj, t, llh);

% ajout de la position avec les satellites en vision
traj = kml_addpos(traj, t, llh, SVID);

% variation de la couleur du lien satellite-recepteur
traj = kml_addpos(traj, t, llh, SVID, CN0);
%--------------------------------------------------------------------------



%--------------------------------------------------------------------------
%% création du fichier

% creation simple du fichier kml
kml_create(traj);

% creation du fichier kml et ouverture avec GoogleEarth
kml_create(traj, 1);
%--------------------------------------------------------------------------




%--------------------------------------------------------------------------
%% création directe du fichier kml

% tableau de positions
export2kml('trajectory.kml', t, llh);

% choix de la couleur
export2kml('trajectory.kml', t, llh, 'white');

% ajout de la position des satellites
export2kml('trajectory.kml', t, llh, color, ephemeris);

% utilisation des mesures GPS pour les liens satellites
export2kml('trajectory.kml', t, llh, color, ephemeris, mes_gps);
%--------------------------------------------------------------------------


