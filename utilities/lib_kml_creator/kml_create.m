function file = kml_create(traj, view_flag)
%function file = kml_create(traj, view_flag)
% Create a kml trajectory file
%
% kml_create(traj);
% OR
% kml_create(traj, view_flag);
%
%
% Inputs :
%	traj : Trajectory struct.
%          struct containing all the data of the trajectory
%
%	view_flag : boolean flag
%               if set to 1, open the kml file with GoogleEarth
%               (default value = 0)
%
%
% Outputs :
%	none
%
%
% Droits reserves ISAE.
% Contact : Benoit Priot
%             benoit.priot@isae.fr
%             (+33)5 61 33 83 66
%
%--------------------------------------------------------------------------
% Champs de la structure "traj"
%--------------------------------------------------------------------------
% traj.data.t
% traj.data.llh
% traj.data.range.SVID
% traj.data.range.link
% traj.data.ephemeris
% traj.file
% traj.lat_corr
% traj.lon_corr
% traj.h_corr
% traj.reference
% traj.color
% traj.link_color
% traj.comment
%--------------------------------------------------------------------------
%
% Documentation KML :
% http://code.google.com/intl/fr/apis/kml/documentation/kmlreference.html
% http://kml-samples.googlecode.com/svn/trunk/interactive/index.html
%


%--------------------------------------------------------------------------
% Creation et ecriture du fichier kml
%--------------------------------------------------------------------------
h = waitbar(0, 'writing kml: please wait');

% creation du fichier kml
file = traj.file;
xml_write('init', traj.file);

if (traj.data.nb_points > 0)
    % recuperation et formatage des donnees
    [data, ephemeris, option] = data_manager(traj);
    
    % gestion de la waitbar
    wb.Nmax = length(data.t)*(length(ephemeris)+2);
    wb.step = ceil(wb.Nmax / 200);
    wb.cmp  = 0;
    wb.h    = h;
    
    % ecriture du fichier kml
    xml_main_Document(data, ephemeris, option, wb);
else
    xml_empty_Document();
end

% fermeture de la waitbar
close(h);

% ouverture du fichier kml avec GoogleEarth
if (nargin < 2)
	view_flag = 0;
end
if (view_flag == 1)
    try
        if ispc
            winopen(file);
        elseif ismac
            cmd = 'open -a Google\ Earth ';
            fullfilename = fullfile(file);
            system([cmd fullfilename]);    
        elseif isunix
            cmd = 'google-earth-pro';
            fullfilename = fullfile(file);
            system([cmd ' ' fullfilename ' &'],'-echo'); 
        else
            error(); %#ok<LTARG>
        end
    catch
        disp(['kml_creator : Open the file ''' file '''.']);
    end
end

end % function create_file



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                             Sous-functions                              %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%



%--------------------------------------------------------------------------
function [data, ephemeris, option] = data_manager(traj)

% Import et conversion des donnees
%
% data.t              : vecteur temps de la trajectoire (en s)
% data.tstamp         : datation XML de la trajectoire (texte)
% data.llh            : coordonnees corrigees de la trajectoire
%                       [3xN] (latitude en deg, longitude en deg, hauteur en m)
% data.range          : liens satellites-recepteur
%                       [1xN] struct(SVID,val)
%
% data.t_sat          : vecteur temps de la constellation satellite (en s)
% data.tstamp_sat     : datation XML de la constellation satellite (texte)
% data.i_sat          : index de correspondance entre t et t_sat
%
% ephemeris           : liste des ephemerides satellites (cell)
%
% option.name         : nom de la trajectoire
% option.color        : couleur de la trajectoire
% option.lat          : information de latitude (en deg)
% option.lon          : information de longitude (en deg)
% option.h            : information de hauteur (en m)
% option.altitudeMode : mode de representation de la hauteur
% option.link_color   : seuils de valeur pour les couleur des liens satellites
% option.comment      : texte de description


% parametres :
dt   = 0.1; % resolution temporelle (en s)
Tsat = 10; % pas de calcul des positions satellites (en s)


% trie des donnees de position
[data.t, index] = unique(traj.data.t(1:traj.data.nb_points));

% position des points trace sous GE
option.lat    = traj.data.llh(1,index);
option.lon    = traj.data.llh(2,index);
option.h      = traj.data.llh(3,index);
data.llh(1,:) = traj.data.llh(1,index) + traj.lat_corr;
data.llh(2,:) = traj.data.llh(2,index) + traj.lon_corr;
data.llh(3,:) = traj.data.llh(3,index) + traj.h_corr;
data.range    = traj.data.range(index);

% "timestamps" de la trajectoire (affichage des points)
tstamp        = floor(data.t(:) / dt);
tstamp(2:end) = max(tstamp(2:end), tstamp(1:end-1)+1);
%tstamp       = [tstamp; tstamp(end) + 1];
data.tstamp   = int2str([tstamp; tstamp(end)+1]);


% recupere les "ephemeris" des satellites
% unicite des "ephemeris" des satellites (SVID)
Neph = numel(traj.data.ephemeris);
SVID = zeros(1, Neph);
for k = 1:Neph
    SVID(k) = traj.data.ephemeris{k}.SVID;
end
[tmp, index] = unique(SVID); %#ok<*ASGLU>
ephemeris    = traj.data.ephemeris(sort(index));
Nsat         = numel(ephemeris);

% "timestamps" satellite
if (Nsat > 0)
    [data.t_sat, idx_t, data.i_sat] = unique(floor(data.t ./ Tsat) .* Tsat);
    data.tstamp_sat                 = data.tstamp(idx_t, :);
    data.tstamp_sat(1,:)            = data.tstamp(1,:);
    data.tstamp_sat(end+1,:)        = data.tstamp(end,:);
end


% Import des options
[path, option.name] = fileparts(traj.file);
option.color = traj.color;

switch lower(traj.reference)
    case 'ground'
        option.altitudeMode = 'relativeToGround';
    case 'sea'
        option.altitudeMode = 'absolute';
    case '2d'
        option.altitudeMode = 'relativeToGround';
        data.llh(3,:)       = 0;
    otherwise
        disp('Warning: Unknown height reference.')
        disp('         ''sea'' is the default reference.')
        disp(' ')
        option.altitudeMode = 'absolute';
end


link_color = traj.link_color(~isnan(traj.link_color));
if isempty(link_color)
    option.link_color   = nan(1,3);
else
    link_color(end+1:3) = min(link_color);
    option.link_color   = sort(link_color(1:3));
end

option.comment = traj.comment;

end % data_manager



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                   Fonctions GoogleEarth "specifiques"                   %
% http://code.google.com/intl/fr/apis/kml/documentation/kmlreference.html %
% http://kml-samples.googlecode.com/svn/trunk/interactive/index.html      %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


function xml_empty_Document()

% initialisation du buffer
%xml_write('reset');


% texte xml
xml_write('string', '<?xml version="1.0" encoding="UTF-8"?>');
xml_write('string', '<!-- Droits reserves ISAE. Contact: benoit.priot@isae.fr -->');
xml_write('string', '');
xml_write('tag', ['kml xmlns="http://www.opengis.net/kml/2.2"' ...
                  ' xmlns:gx="http://www.google.com/kml/ext/2.2"']);

xml_write('tag', 'Document');
xml_description('empty file: no position data.');
xml_write('/tag', 'Document');
xml_write('/tag', 'kml');


xml_write('write');

end % xml_empty_Document


%--------------------------------------------------------------------------
function xml_main_Document(data, ephemeris, option, wb)
% fonction principale d'ecriture du fichier kml

nl = '\r\n';

% initialisation du buffer
%xml_write('reset');


% debut du texte xml
xml_write('string', '<?xml version="1.0" encoding="UTF-8"?>');
xml_write('string', '<!-- Droits reserves ISAE. Contact: benoit.priot@isae.fr -->');
xml_write('string', '');
xml_write('tag', ['kml xmlns="http://www.opengis.net/kml/2.2"' ...
                  ' xmlns:gx="http://www.google.com/kml/ext/2.2"']);


% debut du "Document" avec nom et commentaires
xml_write('tag', 'Document');
xml_write('elem', 'open', '1');
xml_write('elem', 'name', option.name);
if ~isempty(option.comment)
    xml_description([nl option.comment nl]);
end
str = ['color scale : ' nl ...
       '   green  > ' num2str(option.link_color(3)) nl ...
       '   yellow > ' num2str(option.link_color(2)) nl ...
       '   orange > ' num2str(option.link_color(1)) nl ...
       '   red    < ' num2str(min(option.link_color)) nl ...
       '   black : NaN' nl ...
       '   white : default'];
xml_write('string', ['<!--' nl str nl '-->']);



xml_LookAt(data.llh(:,1), option.altitudeMode, 1000);


% definition des styles
xml_define_Style(option.color);


% dossier de trajectoire et positions
xml_position_Folder(data, option, wb);
wb.cmp = wb.cmp + 2*length(data.t);


% dossier de constellation: satellites et ranges
Nsat = length(ephemeris);
if (Nsat > 0)
    % au moins un satellite: creation du dossier constellation
    xml_write('tag', 'Folder');
        xml_write('elem', 'name', 'satellites');
        xml_write('elem', 'styleUrl', '#constellation_style');
        xml_LookAt(data.llh(:,1), option.altitudeMode, 6.5e7);
        
        % creation d'un sous-dossier (satellite + range)
        % pour chaque satellites
        for k = 1:Nsat
            xml_satellite_Folder(data, ephemeris{k}, option, wb);
            wb.cmp = wb.cmp + length(data.t);
        end
        
        % % color scale (comment)
        % xml_buffer('tag', 'Placemark');
        % xml_buffer('elem', 'name', 'link color:');
        % desc_str = ['green &gt; ' num2str(option.link_color(3)) '\n' ...
        %     'yellow &gt; ' num2str(option.link_color(2)) '\n' ...
        %     'orange &gt; ' num2str(option.link_color(1)) '\n' ...
        %     'red &lt; ' num2str(min(option.link_color)) '\n' ...
        %     'black : NaN\n' ...
        %     'white : default\n'];
        % xml_Snippet(['\n' desc_str], 6);
        
    xml_write('/tag', 'Folder');
end

% fin du document
xml_write('/tag', 'Document');
xml_write('/tag', 'kml');

waitbar(1, wb.h, 'writing kml: complete');
xml_write('write');

end % xml_main_Document


%--------------------------------------------------------------------------
function xml_position_Folder(data, option, wb)
% fonction qui genere la trajectoire au sol et les positions des points

nl = '\r\n';

% affichage de la waitbar
cmp = wb.cmp + length(data.t)/2;
waitbar(cmp/wb.Nmax, wb.h, 'writing kml: groundpath');


% trajectoire sol (groundpath)
if (length(data.t) > 1)
    xml_write('tag', 'Placemark');
    xml_write('elem', 'name', 'groundpath');
    xml_write('elem', 'styleUrl', '#groundpath_style');
    xml_ground_LineString(data.llh);
    xml_write('/tag', 'Placemark');
end


% donnees de description
index = int2str((1:numel(data.t))');
time = num2str(data.t(:), '%.2f');
lat = num2str(option.lat(:), '%.7f');
lon = num2str(option.lon(:), '%.7f');
h = num2str(option.h(:), '%.2f');


% affichage de la waitbar
cmp = cmp + length(data.t)/2;
waitbar(cmp/wb.Nmax, wb.h, 'writing kml: positions');


% dossier de positions
xml_write('tag', 'Folder');
xml_write('elem', 'name', 'position');
xml_write('elem', 'styleUrl', '#position_list_style');
xml_LookAt(data.llh(:,1), option.altitudeMode, 500, 45);

for k = 1:length(data.t)
    % affichage de la waitbar
    if (mod((cmp+k), wb.step) < 1)
        waitbar((cmp+k)/wb.Nmax, wb.h);
    end
    
    % positions des points avec info bulle
    xml_write('tag', 'Placemark');
    xml_write('elem', 'styleUrl', '#position_style');
    desc_str = ['#' index(k,:) nl ...
                't = ' time(k,:) ' s' nl ...
                'lat = ' lat(k,:) ' deg' nl ...
                'lon = ' lon(k,:) ' deg' nl ...
                'h = ' h(k,:) ' m' nl];
    xml_write('elem', 'description', [nl desc_str]);
    xml_TimeSpan(data.tstamp(k,:), data.tstamp(k+1,:));
    xml_Point(data.llh(:,k), option.altitudeMode, '1');
    xml_write('/tag', 'Placemark');
end

xml_write('/tag', 'Folder');

end % xml_position_Folder


%--------------------------------------------------------------------------
function xml_satellite_Folder(data, ephemeris, option, wb)
% fonction qui trace un satellite et les liens satellite-recepteur


% affichage de la waitbar
cmp = wb.cmp;
waitbar(cmp/wb.Nmax, wb.h, ['writing kml: sat ' int2str(ephemeris.SVID)]);


% ID et trajectoire du satellite
id = ephemeris.SVID;
sat_name = ['sat ' int2str(id)];
sat_llh = kml_satellite_llh(ephemeris, data.t_sat);


% dossier "satellite" (satellite + lien)
xml_write('tag', 'Folder');
xml_write('elem', 'name', sat_name);
xml_write('elem', 'styleUrl', '#satellite_list_style');
xml_LookAt(sat_llh(:,1), option.altitudeMode, 3e7);

% positions satellite
for k = 1:length(data.t_sat)
    xml_write('tag', 'Placemark');
    xml_write('elem', 'styleUrl', '#satellite_style');
    xml_write('elem', 'name', sat_name);
    xml_TimeSpan(data.tstamp_sat(k,:), data.tstamp_sat(k+1,:));
    xml_Point(sat_llh(:,k), option.altitudeMode);
    xml_write('/tag', 'Placemark');
end

% liens satellite-recepteur (range)
for k = 1:length(data.t)
    % affichage de la waitbar
    if (mod((cmp+k), wb.step) < 1)
        waitbar((cmp+k)/wb.Nmax, wb.h);
    end
    
    % test si le satellite est dans la structure "range"
    n = find(data.range(k).SVID == id, 1);
    if ~isempty(n)
        xml_write('tag', 'Placemark');
        
        % couleur du lien satellite-recepteur
        if (isempty(data.range(k).link) || isnan(option.link_color(1)))
            xml_write('elem', 'styleUrl', '#link_style_white');
        else
            link_val = data.range(k).link(n);
            if isnan(link_val)
                xml_write('elem', 'styleUrl', '#link_style_black');
                
            elseif (link_val >= option.link_color(3))
                xml_write('elem', 'styleUrl', '#link_style_green');
                
            elseif (link_val >= option.link_color(2))
                xml_write('elem', 'styleUrl', '#link_style_yellow');
                
            elseif (link_val >= option.link_color(1))
                xml_write('elem', 'styleUrl', '#link_style_orange');
                
            else
                xml_write('elem', 'styleUrl', '#link_style_red');
            end
        end
        
        %{
        % degrade de couleur
        link_style.LineStyle.color = val2color(link_val, option.link_color);
        link_style.LineStyle.width = 2;
        xml_Style('', link_style);
        %}
        
        % coordonnees du lien satellite-recepteur
        link_llh = [data.llh(:,k), sat_llh(:,data.i_sat(k))];
        xml_TimeSpan(data.tstamp(k,:), data.tstamp(k+1,:));
        xml_LineString(link_llh, option.altitudeMode);
        xml_write('/tag', 'Placemark');
    end
end

xml_write('/tag', 'Folder');


end % xml_satellite_Folder


%--------------------------------------------------------------------------
function xml_define_Style(color)
% defini les styles utilise dans le fichier kml

% groundpath_style
groundpath_style.LineStyle.color = color;
groundpath_style.LineStyle.width = 3;
xml_Style('groundpath_style', groundpath_style);


% position_style
position_style.IconStyle.Icon           = 'dot';
position_style.IconStyle.scale          = 0.9;
position_style.IconStyle.color          = color;
position_style.LineStyle.color          = 'white';
position_style.LineStyle.width          = 1;
position_style.LabelStyle.scale         = 0;
position_style.BalloonStyle.displayMode = 'hide';
xml_Style('position_style_N', position_style);
position_style.BalloonStyle.displayMode = 'default';
xml_Style('position_style_H', position_style);
xml_StyleMap('position_style', '#position_style_N', '#position_style_H');


% position_list_style
position_list_style.ListStyle.ItemIcon     = position_style.IconStyle.Icon;
position_list_style.ListStyle.listItemType = 'checkHideChildren';
xml_Style('position_list_style', position_list_style);


% satellite_style
satellite_style.IconStyle.Icon   = 'satellite';
satellite_style.IconStyle.scale  = 20;
satellite_style.LabelStyle.scale = 0;
xml_Style('satellite_style_N', satellite_style);
satellite_style.LabelStyle.scale = 20;
xml_Style('satellite_style_H', satellite_style);
xml_StyleMap('satellite_style', '#satellite_style_N','#satellite_style_H');


% satellite_list_style
satellite_list_style.ListStyle.ItemIcon = satellite_style.IconStyle.Icon;
satellite_list_style.ListStyle.listItemType = 'checkHideChildren';
xml_Style('satellite_list_style', satellite_list_style);


% constellation_style
constellation_style.ListStyle.ItemIcon = satellite_style.IconStyle.Icon;
xml_Style('constellation_style', constellation_style);


% link_style
link_style.LineStyle.width = 3;
% link_style.LineStyle.gx_outerColor = 'black';
% link_style.LineStyle.gx_outerWidth = 0.3;

% link_style_green
link_style_green = link_style;
link_style_green.LineStyle.color = 'green';
xml_Style('link_style_green', link_style_green);

% link_style_yellow
link_style_yellow = link_style;
link_style_yellow.LineStyle.color = 'yellow';
xml_Style('link_style_yellow', link_style_yellow);

% link_style_orange
link_style_orange = link_style;
link_style_orange.LineStyle.color = 'orange';
xml_Style('link_style_orange', link_style_orange);

% link_style_red
link_style_red = link_style;
link_style_red.LineStyle.color = 'red';
xml_Style('link_style_red', link_style_red);

% link_style_white
link_style_white = link_style;
link_style_white.LineStyle.color = 'white';
xml_Style('link_style_white', link_style_white);

% link_style_black
link_style_black = link_style;
link_style_black.LineStyle.color = 'black';
xml_Style('link_style_black', link_style_black);

end % xml_define_Style


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                   Fonctions GoogleEarth "generiques"                    %
% http://code.google.com/intl/fr/apis/kml/documentation/kmlreference.html %
% http://kml-samples.googlecode.com/svn/trunk/interactive/index.html      %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


function xml_Point(llh, altitudeMode, extrude)
% llh = [3x1]
% altitudeMode = 'absolute'
%                'relativeToGround'
%                'clampToGround'
% extrude = '1' ou '0'

xml_write('tag', 'Point');
xml_write('elem', 'altitudeMode', altitudeMode);
if (nargin >= 3)
    xml_write('elem', 'extrude', extrude); end
xml_coordinates(llh);
xml_write('/tag', 'Point');

end % xml_Point


%--------------------------------------------------------------------------
function xml_LineString(llh, altitudeMode, extrude)
% llh = [3xN]
% altitudeMode = 'absolute'
%                'relativeToGround'
%                'clampToGround'
% extrude = '1' ou '0'

xml_write('tag', 'LineString');
xml_write('elem', 'altitudeMode', altitudeMode);
if (nargin >= 3)
    xml_write('elem', 'extrude', extrude); end
xml_coordinates(llh);
xml_write('/tag', 'LineString');

end % xml_LineString


%--------------------------------------------------------------------------
function xml_ground_LineString(llh)
% llh = [2xN] ou [3xN] (altitude ignoree)

xml_write('tag', 'LineString');
xml_write('elem', 'altitudeMode', 'clampToGround');
xml_write('elem', 'tessellate', '1');
xml_coordinates(llh(1:2, :));
xml_write('/tag', 'LineString');

end % xml_ground_LineString


%--------------------------------------------------------------------------
function xml_coordinates(llh)
% llh = [3xN] ou [2xN]
%   lat = llh(1,:);
%   lon = llh(2,:);
%   alt = llh(3,:); (optionnel)

nl = '\r\n';

switch size(llh, 1)
    case 2
        str = sprintf(['%.9f,%.9f' nl], llh([2 1], :));
    case 3
        str = sprintf(['%.9f,%.9f,%.3f' nl], llh([2 1 3], :));
    otherwise
        str = '';
end
xml_write('elem', 'coordinates', [nl str]);

end % xml_coordinates


%--------------------------------------------------------------------------
function xml_TimeStamp(time_str) %#ok<DEFNU>

xml_write('tag', 'TimeStamp');
xml_write('elem', 'when', time_str);
xml_write('/tag', 'TimeStamp');

end % xml_TimeStamp


%--------------------------------------------------------------------------
function xml_TimeSpan(begin_str, end_str)

nl = '\r\n';
str = ['<begin>' begin_str '</begin>' nl ...
       '<end>'   end_str   '</end>' nl];
xml_write('elem', 'TimeSpan', [nl str]);

end % xml_TimeSpan


%--------------------------------------------------------------------------
function xml_LookAt(llh, altitudeMode, range, tilt, heading)
% llh = [3x1]
% altitudeMode = 'absolute'
%                'relativeToGround'
%                'clampToGround'
% range = distance (en m)
% tilt   = angle (en deg)
% heading = angle (en deg)

xml_write('tag', 'LookAt');
xml_write('elem', 'latitude',  num2str(llh(1,1)));
xml_write('elem', 'longitude', num2str(llh(2,1)));
xml_write('elem', 'altitude',  num2str(llh(3,1)));
xml_write('elem', 'altitudeMode', altitudeMode);
xml_write('elem', 'range', num2str(range));
if (nargin >= 4)
    xml_write('elem', 'tilt', num2str(tilt)); end
if (nargin >= 5)
    xml_write('elem', 'heading', num2str(heading)); end
xml_write('/tag', 'LookAt');

end % xml_LookAt


%--------------------------------------------------------------------------
function xml_description(desc_str)

xml_write('elem', 'description', ['<![CDATA[ ' desc_str ' ]]>']);

end % xml_description


%--------------------------------------------------------------------------
function xml_Snippet(desc_str, maxLines) %#ok<DEFNU>

xml_write('tag', ['Snippet maxLines="' int2str(maxLines) '"']);
xml_write('string', ['<![CDATA[ ' desc_str ' ]]>']);
xml_write('/tag', 'Snippet');

end % xml_Snippet



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                    Fonctions de generation des styles                   %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


function xml_Style(id, Style)
% Style = struct (.sub_Style)

if ~isempty(id), id = [' id="' id '"']; end
xml_write('tag', ['Style' id]);

if isfield(Style, 'LineStyle')
    xml_LineStyle(Style.LineStyle); end

if isfield(Style, 'LabelStyle')
    xml_LabelStyle(Style.LabelStyle); end

if isfield(Style, 'IconStyle')
    xml_IconStyle(Style.IconStyle); end

if isfield(Style, 'BalloonStyle')
    xml_BalloonStyle(Style.BalloonStyle); end

if isfield(Style, 'ListStyle')
    xml_ListStyle(Style.ListStyle); end

xml_write('/tag', 'Style');

end % xml_Style


%--------------------------------------------------------------------------
function xml_StyleMap(id, normalStyle, highlightStyle)
% normalStyle = '#Style_id'
% highlightStyle = '#Style_id'

if ~isempty(id), id = [' id="' id '"']; end
xml_write('tag', ['StyleMap' id]);

xml_write('tag', 'Pair');
xml_write('elem', 'key', 'normal');
xml_write('elem', 'styleUrl', normalStyle);
xml_write('/tag', 'Pair');

xml_write('tag', 'Pair');
xml_write('elem', 'key', 'highlight');
xml_write('elem', 'styleUrl', highlightStyle);
xml_write('/tag', 'Pair');

xml_write('/tag', 'StyleMap');

end % xml_StyleMap


%--------------------------------------------------------------------------
function xml_LineStyle(LineStyle)
% LineStyle = struct.color = color_str
%                   .width = double
%                   .gx_outerColor = color_str
%                   .gx_outerWidth = double entre [0 1]

xml_write('tag', 'LineStyle');
if isfield(LineStyle, 'color')
    xml_write('elem', 'color', colorcode(LineStyle.color));
    xml_write('elem', 'colorMode', 'normal');
end
if isfield(LineStyle, 'width')
    xml_write('elem', 'width', num2str(LineStyle.width));
end
if isfield(LineStyle, 'gx_outerColor')
    xml_write('elem', 'gx:outerColor', colorcode(LineStyle.gx_outerColor));
end
if isfield(LineStyle, 'gx_outerWidth')
    xml_write('elem', 'gx:outerWidth', num2str(LineStyle.gx_outerWidth));
end
xml_write('/tag', 'LineStyle');

end % xml_LineStyle


%--------------------------------------------------------------------------
function xml_LabelStyle(LabelStyle)
% LabelStyle = struct.color = color_str
%                    .scale = double

xml_write('tag', 'LabelStyle');
if isfield(LabelStyle, 'color')
    xml_write('elem', 'color', colorcode(LabelStyle.color));
    xml_write('elem', 'colorMode', 'normal');
end
if isfield(LabelStyle, 'scale')
    xml_write('elem', 'scale', num2str(LabelStyle.scale));
end
xml_write('/tag', 'LabelStyle');

end % xml_LabelStyle
 

%--------------------------------------------------------------------------
function xml_BalloonStyle(BalloonStyle)
% BalloonStyle = struct.bgColor   = color_str
%                      .textColor = color_str
%                      .text      = str
%                      .displayMode = 'default' or 'hide'

xml_write('tag', 'BalloonStyle');
if isfield(BalloonStyle, 'bgColor')
    xml_write('elem', 'bgColor', colorcode(BalloonStyle.bgColor));
end
if isfield(BalloonStyle, 'textColor')
    xml_write('elem', 'textColor', colorcode(BalloonStyle.textColor));
end
if isfield(BalloonStyle, 'text')
    xml_write('elem', 'text', BalloonStyle.text);
end
if isfield(BalloonStyle, 'displayMode')
    xml_write('elem', 'displayMode', BalloonStyle.displayMode);
end
xml_write('/tag', 'BalloonStyle');

end % xml_BalloonStyle


%--------------------------------------------------------------------------
function xml_IconStyle(IconStyle)
% IconStyle = struct.color = color_str
%                   .scale = double
%                   .Icon  = str

xml_write('tag', 'IconStyle');
if isfield(IconStyle, 'color')
    xml_write('elem', 'color', colorcode(IconStyle.color));
    xml_write('elem', 'colorMode', 'normal');
end
if isfield(IconStyle, 'scale')
    xml_write('elem', 'scale', num2str(IconStyle.scale));
end
if isfield(IconStyle, 'Icon')
    xml_write('tag', 'Icon');
    xml_href(IconStyle.Icon);
    xml_write('/tag', 'Icon');
end
xml_write('/tag', 'IconStyle');

end % xml_IconStyle


%--------------------------------------------------------------------------
function xml_ListStyle(ListStyle)
% BalloonStyle = struct.listItemType = 'check'
%                                      'radioFolder'
%                                      'checkOffOnly'
%                                      'checkHideChildren'
%                      .bgColor      = color_str
%                      .ItemIcon     = str

xml_write('tag', 'ListStyle');
if isfield(ListStyle, 'listItemType')
    xml_write('elem', 'listItemType', num2str(ListStyle.listItemType));
end
if isfield(ListStyle, 'bgColor')
    xml_write('elem', 'bgColor', colorcode(ListStyle.bgColor));
end
if isfield(ListStyle, 'ItemIcon')
    xml_write('tag', 'ItemIcon');
    xml_href(ListStyle.ItemIcon);
    xml_write('/tag', 'ItemIcon');
end
xml_write('/tag', 'ListStyle');

end % xml_ListStyle


%--------------------------------------------------------------------------
function xml_href(Icon)
% Icon = str

switch Icon
    case 'diamond'
        link = ...
             'http://maps.google.com/mapfiles/kml/shapes/open-diamond.png';
        
    case 'triangle'
     	link = 'http://maps.google.com/mapfiles/kml/shapes/triangle.png';
        
    case 'circle'
      	link = 'http://maps.google.com/mapfiles/kml/shapes/donut.png';
        
    case 'dot'
      	link = ...
         'http://maps.google.com/mapfiles/kml/shapes/placemark_circle.png';
        
    case 'flag'
     	link = 'http://maps.google.com/mapfiles/kml/shapes/flag.png';
        
    case 'car'
     	link = 'http://maps.google.com/mapfiles/kml/shapes/cabs.png';
        
    case 'satellite'
     	link = 'Satellite-icon.png';
        
    otherwise
        link = Icon;
end
xml_write('elem', 'href', link);

end % xml_href


%--------------------------------------------------------------------------
function code = colorcode(color)
% color = str

switch lower(color)
    case {'w', 'white', ''}, code = 'ffffffff';
    case {'k', 'black'},   code = 'ff000000';
    case {'x', 'grey'},    code = 'ff777777';
    case {'g', 'green'},   code = 'ff00ff00';
    case {'y', 'yellow'},  code = 'ff00ffff';
    case {'o', 'orange'},  code = 'ff00a0ff';
    case {'r', 'red'},     code = 'ff0000ff';
    case {'b', 'blue'},    code = 'ffff0000';
    case {'c', 'cyan'},    code = 'ffffff00';
    case {'m', 'magenta'}, code = 'ffff00ff';
    otherwise, code = color;
end

end % colorcode


%--------------------------------------------------------------------------
function color = val2color(val, scale) %#ok<DEFNU>
% degrade de couleur: vert->jaune->rouge->noir

val = val(:);

r1 = (val - scale(1)) / (scale(2) - scale(1));
r2 = (val - scale(4)) / (scale(3) - scale(4));
r = min(r1, r2);
g = (val - scale(3)) / (scale(2) - scale(3));
b = zeros(size(val));
a = ones(size(val));

RR = val2hex(r);
GG = val2hex(g);
BB = val2hex(b);
AA = val2hex(a);

color = [AA BB GG RR];

color(isnan(val), :) = 'f'; % nan = white

end % val2color


%--------------------------------------------------------------------------
function hex = val2hex(val)

val = min(max(val,0),1);
val = floor(val * 255);
hex = lower(dec2hex(val, 2));

end % val2hex


%--------------------------------------------------------------------------



