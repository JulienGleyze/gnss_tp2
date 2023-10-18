%% Plots

if Flag_spp == 1
    marker_ref = '+r';
    marker_nav = '*';
else
    marker_ref = 'r';
    marker_nav = ' ';
end

%--------------------------------------------------------------------------
% ENU trajectory display
%--------------------------------------------------------------------------
gray   = [.7 .7 .7];
blue   = [0 .4470 .7410];
yellow = [.9290 .6940 .1250];

figure,
subplot(3,2,[2 4 6])
h1 = plot(posenu(2:NSamp,1),posenu(2:NSamp,2),marker_nav);hold on; grid on;
h2 = plot(posenu_ref(:,1),posenu_ref(:,2),marker_ref); 
title('Trajectory')
xlabel('East (meters)')
ylabel('North (meters)')
if Flag_spp == 1
    h3 = error_ellipse(posenu_ref(:,1:2),sav.Penu(1:2,1:2,NSamp),3);
    legend([h1 h2 h3], 'Navsol','Reference','Error ellipse' )
    set(h1,'Color',gray)
    set(h3,'Color',yellow)
else
    legend([h1 h2], 'Navsol','Reference')
    set(h1,'Color',blue)
end

%--------------------------------------------------------------------------
% ENU trajectory error display
%--------------------------------------------------------------------------
if Flag_spp == 1
    subplot(3,2,1)
    h111 = plot(3*sig_ee,'Color',yellow); grid on; hold on;
    h112 = plot(-3*sig_ee,'Color',yellow);
    h113 = plot(posenu(:,1));
    h114 = plot(posenu_ref(:,1),'r');
    title('Position and Positioning Error')
    xlabel('Sample');
    ylabel('East (meters)')
    legend('3*sig','-3*sig','Navsol', 'Reference')
    set(h113,'Color',blue)
    subplot(3,2,3)
    h121 = plot(3*sig_nn,'Color',yellow); grid on; hold on;
    h122 = plot(-3*sig_nn,'Color',yellow);
    h123 = plot(posenu(:,2));
    h124 = plot(posenu_ref(:,2),'r');
    xlabel('Sample');
    ylabel('North (meters)')
    set(h123,'Color',blue)
    subplot(3,2,5)
    h131 = plot(3*sig_uu,'Color',yellow); grid on; hold on;
    h132 = plot(-3*sig_uu,'Color',yellow);
    h133 = plot(posenu(:,3));
    h134 = plot(posenu_ref(:,3),'r');
    xlabel('Sample');
    ylabel('Up (meters)')
    set(h133,'Color',blue)
else
    subplot(3,2,1)
    h111 = plot(posenu(:,1) + 3*sig_ee,'Color',yellow); grid on; hold on;
    h112 = plot(posenu(:,1) - 3*sig_ee,'Color',yellow);
    h113 = plot(posenu(:,1));
    h114 = plot(posenu_ref(:,1),'r');
    title('Position and Positioning Error')
    xlabel('Sample');
    ylabel('East (meters)')
    legend('3*sig','-3*sig','Navsol', 'Reference')
    set(h113,'Color',blue)
    subplot(3,2,3)
    h121 = plot(posenu(:,2) + 3*sig_ee,'Color',yellow); grid on; hold on;
    h122 = plot(posenu(:,2) - 3*sig_ee,'Color',yellow);
    h123 = plot(posenu(:,2));
    h124 = plot(posenu_ref(:,2),'r');
    xlabel('Sample');
    ylabel('North (meters)')
    set(h123,'Color',blue)
    subplot(3,2,5)
    h131 = plot(posenu(:,3) + 3*sig_uu,'Color',yellow); grid on; hold on;
    h132 = plot(posenu(:,3) -3*sig_uu,'Color',yellow);
    h133 = plot(posenu(:,3));
    h134 = plot(posenu_ref(:,3),'r');
    xlabel('Sample');
    ylabel('Up (meters)')
    set(h133,'Color',blue)
end
set(gcf, 'Units', 'Normalized', 'OuterPosition', [0, 0.55, 0.45, 0.45]);

%--------------------------------------------------------------------------
% Skyplot
%--------------------------------------------------------------------------
if Flag_spp == 1   
    disp('-----------------------------------------------------------------');
    samp = NSamp;
    PRN = find(sav.sat_elev(samp,:) ~= 0);
    elev = sav.sat_elev(samp,PRN);
    azim = sav.sat_azim(samp,PRN);
    skyplot(PRN,azim,elev,'deg');
    set(gcf, 'Units', 'Normalized', 'OuterPosition', [0, 0.005, 0.45, 0.45]);
end

%--------------------------------------------------------------------------


%--------------------------------------------------------------------------
% Propagation corrections display
%--------------------------------------------------------------------------
if Flag_spp == 1 && Flag_propag == 1
    PRN = find(sav.sat_elev(NSamp,:) ~= 0);
    
    leg={};
    for m=1:length(PRN)
        leg=[leg(:)', {num2str(PRN(m))}];
    end
    figure,
    subplot(2,1,1)
    plot(config.c*sav.dt_iono(1:NSamp,PRN));grid on;
    title('Propagation errors'); 
    xlabel('Sample');
    ylabel('ionospheric correction (meters)')
    legend(leg{:})
    subplot(2,1,2)
    plot(config.c*sav.dt_tropo(1:NSamp,PRN));grid on;
    xlabel('Sample');
    ylabel('tropospheric correction (meters)')
    set(gcf, 'Units', 'Normalized', 'OuterPosition', [0.55, 0.55, 0.45, 0.45]);
end

%--------------------------------------------------------------------------


%--------------------------------------------------------------------------
% CN0 display
%--------------------------------------------------------------------------
leg={};
for m=1:length(SVID{NSamp})
    PRN     = sort(SVID{NSamp});
    leg     = [leg(:)', {num2str(PRN(m))}];
end
figure,
plot(GNSS_RAW.GPS.CN0_L1(1:NSamp,PRN));grid on;
xlabel('Sample');
ylabel('C/N0 (dB.Hz)')
legend(leg{:})
set(gcf, 'Units', 'Normalized', 'OuterPosition', [0.55, 0.005, 0.45, 0.45]);

%--------------------------------------------------------------------------



%--------------------------------------------------------------------------
% Google Earth Display
%--------------------------------------------------------------------------
if Flag_kml == 1
    pathdir = [pwd '/kml_result/'];
    
    llh = posllh;
    llh(:,1:2) = llh(:,1:2)*180/pi; 
    
    disp('[main_gnss] Launching KML trajectory display.')
    disp(['[main_gnss] Saving KML file in ' pathdir])
    
    if Flag_spp == 0
        
        if config.enable_EKF == 1
            navkml_file             = 'navsol_mpp_ekf';
        else
            navkml_file             = 'navsol_mpp_wlmse';
        end
        config.kml_file             = {'reference_trajectory'; navkml_file};
        config.kml_plot_satellites  = [0;1];
        config.kml_color            = {'r';'b'};
        llh                         = {ref_llh(n_sync,:);llh};
        TOW                         = {NOVATEL_DATA.GPSTime(n_sync,:);GNSS_RAW.TOW(1:NSamp)};    
        
        display_kml(llh, TOW, GNSS_DATA.GPS_EPHEMERIS, pathdir, config);

    else
        posinit                     = config.pos_init'.*ones(NSamp,3);
        posinit(:,1:2)              = posinit(:,1:2)*180/pi;
        config.kml_plot_satellites  = [1;0];
        config.kml_file             = {'navsol_spp'; 'pos_init_spp'};
        config.kml_color            = {'b';'g'};
        llh                         = {llh;posinit};
        TOW                         = {GNSS_RAW.TOW(1:NSamp);GNSS_RAW.TOW(1:NSamp)};
        
        display_kml(llh, TOW, GNSS_DATA.GPS_EPHEMERIS, pathdir, config);

    end
end