function skyplot(sv,azim,elev,unit)

% SKYPLOT	Produces satellite skyplot.
%           Input:
%             sv    = vector of PRN numbers 
%             azim  = azimuth in deg or rad
%             elev  = elevation in deg or rad
%             unit  = 'rad' or 'deg'  
% Call: skyplot(sv,azim,elev,unit)
% http://www.geologie.ens.fr/~ecalais/teaching/gps-geodesy/solutions-to-gps-geodesy/

%--------------------------------------------------------------------------
% Latitude and longitude unit conversion (rad)
%--------------------------------------------------------------------------
coef_unit2rad = 1;
if strncmpi(unit, 'deg', 3)
    coef_unit2rad = pi/180;
end

azim = azim * coef_unit2rad;
%--------------------------------------------------------------------------

figure, polarplot(0,90);
pax = gca;
pax.ThetaDir            = 'clockwise';
pax.ThetaZeroLocation   = 'top';
pax.ThetaTickLabels     = {'N' ,'30' ,'60' ,'E' ,'120' ,'150' ,'S' ,'210' ,'240' ,'O' ,'300' ,'330'};
pax.RMinorGrid          = 'on';
pax.RGrid               = 'on';
pax.RDir                = 'reverse';
pax.RLim                = [0 90];
hold on;


%disp(['-------------']);
%disp(['[skyplot]: Producing sky plot...']);


for i=1:length(sv)
    polarplot(azim(i),elev(i),'.b','MarkerSize',25); hold on
    text(azim(i)+0.1,elev(i),num2str(sv(i)),'color','r','FontWeight','bold','FontSize',12);
end
%drawnow;