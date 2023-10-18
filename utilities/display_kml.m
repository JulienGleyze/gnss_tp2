function display_kml(posllh, TOW, ephemeris, pathdir, config)

% if nargin < 5
%     % Name of the kml file (GoogleEarth trajectory)
%     config.kml_file = 'reference_trajectory';
% 
%     % Color of the GoogleEarth trajectory
%     config.kml_color = 'r';
% 
%     % Flag for satellite display on GoogleEarth
%     config.kml_plot_satellites = 1;
% 
%     % Flag for time display on GoogleEarth :
%     % 1 : Time Of Week is used
%     % 0 : signal time is used
%     % (used only if "config.kml_plot_satellites = 0")
%     config.kml_use_TOW = 0;
% end

cnt     = 0;
SVID    = [];

for k = 1:32
    if ~isempty(ephemeris(k).SVID)
        cnt = cnt + 1;
        SVID(cnt) = ephemeris(k).SVID;
    end
end

a = exist(pathdir, 'dir');
if a == 0
    mkdir(pathdir)
end

% -------------------------------------------------------------------------
% Check the number of files
nbkml       = length(config.kml_file);
unixfile    = [];
winfile     = cell(nbkml,1);

for ii = 1:nbkml
    file            = [pathdir config.kml_file{ii,1}];
    color           = config.kml_color{ii,1};
    llh             = posllh{ii,1};
    t               = TOW{ii,1};
    plot_satellites = config.kml_plot_satellites(ii);

    if plot_satellites == 1
        file = export2kml(file, t, llh, color, ephemeris);
    else
        file = export2kml(file, t, llh, color);
    end

    winfile{ii,1} = file;
    unixfile = [unixfile file ' '];
end    

% ouverture du fichier kml avec GoogleEarth
try
    if ispc
        for ii = 1:nbkml
            winopen(winfile{ii,1});
            pause(10);
        end
    elseif ismac
        cmd = 'open -a Google\ Earth ';
        fullfilename = fullfile(file);
        system([cmd fullfilename]);    
    elseif isunix
        cmd = 'google-earth-pro';
        %fullfilename = fullfile(file);
        system([cmd ' ' unixfile ' &'],'-echo');
        %system([cmd fullfilename ' &'],'-echo'); 
    else
        error(); %#ok<LTARG>
    end
catch
    disp(['kml_creator : Open the file ''' file '''.']);
end


% -------------------------------------------------------------------------

end