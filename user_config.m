
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                        General Configuration                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Name of the kml file (GoogleEarth trajectory)
config.kml_file = 'navsol_trajectory';

% Color of the GoogleEarth trajectory
config.kml_color = 'b';

% Flag for satellite display on GoogleEarth
config.kml_plot_satellites = 0;

% Flag for time display on GoogleEarth :
% 1 : Time Of Week is used
% 0 : signal time is used
% (used only if "config.kml_plot_satellites = 0")
config.kml_use_TOW  = 1;

% Enable/disable EKF
config.enable_EKF   = 0; 

config.Flag_propag = Flag_propag;

%--------------------------------------------------------------------------
% Constants
config.c     = 2.99792458e8; % light speed = 2.99792458e8 m/s
config.fL1   = 1575.42e6;    % carrier frequency = 1.57542e9 Hz
%--------------------------------------------------------------------------



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                        Navigator Configuration                          %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%--------------------------------------------------------------------------
% Navigator general parameters
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
% State vector index
config.Nx           = 8;
config.ix.pos       = 1:3;
config.ix.vel       = 4:6;
config.ix.clk_bias 	= 7;
config.ix.clk_drift	= 8;
%--------------------------------------------------------------------------


% Position used to initialize the convergence of the LMS
% coordinates in ECEF frame
%config.pos_init = convert_llh2ecef([43.604652; 1.4442090000000007; 0], 'deg');
lat = 43.604652;
lon = 1.4442090000000007;
config.pos_init = [lat*pi/180; lon*pi/180; 145.76+50];


%--------------------------------------------------------------------------
% Measurement noise matrix parameters
%--------------------------------------------------------------------------
% PseudoRange measurement variance at 30dBHz (m^2)
config.sig2_PR = 7^2;

% PseudoVelocity measurement variance at 30dBHz (m/s)^2
config.sig2_PV = 1^2;



%--------------------------------------------------------------------------
% State noise matrix parameters for the EKF
%--------------------------------------------------------------------------
% used to compute the Q matrix of the Kalman filter (P = F*P*F' + Q)

Fmes = 4; % (Hz) Measurement sampling frequency 

% Variance of the position variations (m^2)
config.sig2_pos      = 0/Fmes;

% Variance of the velocity variations (in (m/s)^2)
% Related to the acceleration of the vehicule
config.sig2_vel      = 0.1^2;

% Variance of the clock bias variations (in m^2)
config.sig2_clkbias  = 0.5^2;

% Variance of the clock drift variations (in (m/s)^2)
config.sig2_clkdrift = 0.5^2;






