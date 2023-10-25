% main_gnss.m
% Bureau d'etude Perception et Navigation D-SA302-TC 3A
% Elaboration d'un algorithme de navigation a partir des observables GPS

%--------------------------------------------------------------------------
clear variables; 
close all; 
clc;

addpath lib_gps
addpath lib_coordinates_conversion
addpath utilities
addpath utilities/lib_kml_creator
addpath navigator
%--------------------------------------------------------------------------



% *************************************************************************
% FLAGS
% *************************************************************************
Flag_spp    = 0;    % Flag to enable/disable single point positioning (spp)
Flag_propag = 1;    % Flag to enable/disable ionospheric and tropospheric corrections
Flag_nsv    = 0;    % Flag to enable/disable number of visible satellites configuration
Flag_kml    = 1;    % Flag to enable/disable KML display

% *************************************************************************



disp('-----------------------------------------------------------------');
if Flag_spp == 1
    disp('[main_gnss]: Single point positioning enabled.')
    data_dir = 'data/spp/';
else
    disp('[main_gnss]: Mobile point positioning enabled.')
    data_dir = 'data/mpp/';
end

if Flag_propag == 1
    disp('[main_gnss]: Ionospheric and tropospheric corrections enabled.')
else
    disp('[main_gnss]: Ionospheric and tropospheric corrections disabled.')
end

%--------------------------------------------------------------------------
% Load data
%--------------------------------------------------------------------------
files = dir([data_dir '*.mat']);

for q = 1:length(files) 
    load([data_dir files(q).name]); 
end

clear data_dir files q
%--------------------------------------------------------------------------


%--------------------------------------------------------------------------
% Measurements
%--------------------------------------------------------------------------
NSamp = GNSS_RAW.NSamp;    % (# samples) number of samples in experiment
disp(['[main_gnss]: Number of samples: ' num2str(NSamp)])
disp('-----------------------------------------------------------------');

gnss_meas.eph_gps   = GNSS_DATA.GPS_EPHEMERIS;
gnss_meas.iono      = GNSS_DATA.GPS_IONO;

% *************************************************************************
% EXERCICE 5, QUESTION 2: Root Mean Square Error (RMSE)
% *************************************************************************
if Flag_nsv == 1
    SVID    = cell(NSamp,1);
    NSV     = zeros(NSamp,1);
    for k = 1:NSamp
        SVID{k,1} = [8 10 11 18 20]; % set SVID vector 

        NSV(k)    = length(SVID{k,1});
    end
    if isempty(SVID{1,1})
        error('[main_gnss]: You must specify SVID vector line 79.')
    end
        
    disp(['[main_gnss]: Selecting satellites: [' num2str(SVID{1,1}) ']'])
else
    SVID    = GNSS_RAW.GPS.SVID;
    NSV     = GNSS_RAW.GPS.NSV;
end

%--------------------------------------------------------------------------
% Configuration
%--------------------------------------------------------------------------
user_config;

%--------------------------------------------------------------------------
% Structures and initialization
%--------------------------------------------------------------------------
nav         = init_nav(config);
posllh      = zeros(NSamp,3);
posecef     = zeros(NSamp,3);
%--------------------------------------------------------------------------
% Process
%--------------------------------------------------------------------------
disp('[main_gnss]: Launching process.')
for k = 1:NSamp
    
    % ---------------------------------------------------------------------
    % Set measurements for sample k
    % ---------------------------------------------------------------------
    gnss_meas.raw.NSamp         = GNSS_RAW.NSamp;
    gnss_meas.raw.time          = GNSS_RAW.time(k);
    gnss_meas.raw.TOW           = GNSS_RAW.TOW(k);
    gnss_meas.raw.GPS.NSV       = NSV(k);
    gnss_meas.raw.GPS.SVID      = SVID{k,1};
    gnss_meas.raw.GPS.PR_L1     = GNSS_RAW.GPS.PR_L1(k,:);
    gnss_meas.raw.GPS.DO_L1     = GNSS_RAW.GPS.DO_L1(k,:);
    gnss_meas.raw.GPS.CP_L1     = GNSS_RAW.GPS.CP_L1(k,:);
    gnss_meas.raw.GPS.CN0_L1    = GNSS_RAW.GPS.CN0_L1(k,:);
    
    
    % ---------------------------------------------------------------------
    % Navigator
    % ---------------------------------------------------------------------
    if (nav.enable_EKF && nav.valid && Flag_spp == 0)
        nav = gnss_nav_ekf(nav, gnss_meas);
    else
        nav = gnss_nav_wlmse(nav, gnss_meas);
    end
    
       
    % ---------------------------------------------------------------------
    % Save results
    % ---------------------------------------------------------------------
    posllh(k,:)         = nav.pos_llh;
    posecef(k,:)        = nav.pos_ecef;
    
    sav.P(:,:,k)        = nav.P;
    sav.Penu(:,:,k)     = nav.Penu;
    sav.sat_elev(k,:)   = nav.elev*180/pi;
    sav.sat_azim(k,:)   = nav.azim*180/pi;
    sav.dt_iono(k,:)    = nav.dt_iono; 
    sav.dt_tropo(k,:)   = nav.dt_tropo; 

    
end


%--------------------------------------------------------------------------
% Measurements from reference system
%--------------------------------------------------------------------------
if Flag_spp == 1 
    Llh_Station_Supaero = [43.56499794  1.47486366   206.671];
    Path_ref = (ones(NSamp,3).* Llh_Station_Supaero);
    ref_llh = Path_ref;
    n_sync  = 1:NSamp;
else
    ref_llh = [NOVATEL_DATA.Latitude NOVATEL_DATA.Longitude NOVATEL_DATA.H_Ell];
    n_sync = zeros(length(GNSS_RAW.TOW(1:NSamp)),1);
    for t = 1:length(GNSS_RAW.TOW(1:NSamp))
        n_sync(t) = find(NOVATEL_DATA.GPSTime == GNSS_POSLLH.TOW(t));
    end
end

%--------------------------------------------------------------------------
% Position in ENU frame.
%--------------------------------------------------------------------------
posenu_ref      = convert_llh2enu(ref_llh(n_sync,:),ref_llh(1,:),'deg');
posenu          = convert_llh2enu(posllh.*[180/pi 180/pi 1],ref_llh(1,:),'deg');
posenu_init     = convert_llh2enu(config.pos_init'.*[180/pi 180/pi 1],ref_llh(1,:),'deg');

%--------------------------------------------------------------------------
% ENU Standard deviation.
%--------------------------------------------------------------------------
sig_ee     = sqrt(squeeze(sav.Penu(1,1,1:NSamp)));
sig_nn     = sqrt(squeeze(sav.Penu(2,2,1:NSamp)));
sig_uu     = sqrt(squeeze(sav.Penu(3,3,1:NSamp)));

% *************************************************************************
% EXERCICE 4, QUESTION 2: Root Mean Square Error (RMSE)
% *************************************************************************

if Flag_spp == 1
    err_east    = sqrt(1/length(posenu_ref) * sum((posenu_ref(:,1) - posenu(:,1)).^2));    % East RMSE
    err_north   = sqrt(1/length(posenu_ref) * sum((posenu_ref(:,2) - posenu(:,2)).^2));    % North  RMSE
    h_err       = sqrt(err_east^2 + err_north^2);    % Horizontal RMSE

    
    disp(' ')
    disp(['East RMSE         : ' num2str(err_east) ' meters'])
    disp(['North RMSE        : ' num2str(err_north) ' meters'])
    disp(['Horizontal RMSE   : ' num2str(h_err) ' meters'])
    disp(' ')
end
% *************************************************************************


%% Plots
display_all;






