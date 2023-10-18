function [nav] = gnss_nav_wlmse(nav, gnss_meas)


%--------------------------------------------------------------------------
% navigator INPUTS
%--------------------------------------------------------------------------
% external inputs 
t          = gnss_meas.raw.time;
TOWrx      = gnss_meas.raw.TOW;
PR_meas    = gnss_meas.raw.GPS.PR_L1;
DO_meas    = gnss_meas.raw.GPS.DO_L1;
CN0        = gnss_meas.raw.GPS.CN0_L1;

ephemeris  =  gnss_meas.eph_gps;
param_iono =  gnss_meas.iono;

% parameters (from : init_nav)

c           = nav.c;
fL1         = nav.fL1;
i_pos      	= nav.ix.pos;
i_vel    	= nav.ix.vel;
i_cb        = nav.ix.clk_bias;
i_cd        = nav.ix.clk_drift;
sig2_PR   	= nav.sig2_PR;
sig2_PV   	= nav.sig2_PV;

% memory (internal)
X          = nav.X;
P          = nav.P;
pos_llh    = nav.pos_llh;
Re2n       = nav.Re2n; 
nav_valid  = nav.valid;
%--------------------------------------------------------------------------



%--------------------------------------------------------------------------
% State model (prediction)
%--------------------------------------------------------------------------
% size of the state vector
Nx = length(X);


%--------------------------------------------------------------------------
% GNSS measurement model initialisation
SVID_meas  = gnss_meas.raw.GPS.SVID;        % satellites available (with measurements and ephemeris)
Nsv        = gnss_meas.raw.GPS.NSV;         % number of satellites available
Zmeas      = zeros(2*Nsv, 1);               % GNSS measurements vector
Znav       = zeros(2*Nsv, 1);             	% predicted measurements vector
H          = zeros(2*Nsv, Nx);           	% measurement model matrix
R          = eye(2*Nsv);                    % measurement noise matrix
sat_elev   = zeros(1,32);
sat_azim   = zeros(1,32);
%--------------------------------------------------------------------------
SVID_eph    = [ephemeris.SVID]; 	   % satellites with ephemeris data
SVID        = intersect(SVID_meas, SVID_eph);
SVID_pr     = find(~isnan(PR_meas));
SVID        = intersect(SVID,SVID_pr);
Nsv         = length(SVID);

TOWrx_ref = TOWrx - X(i_cb)/c;

%--------------------------------------------------------------------------
% Receiver state data for PR estimation
rx_state.TOWrx_ref      = TOWrx_ref;
rx_state.pos_ecef       = X(i_pos);
rx_state.vel_ecef       = X(i_vel);
rx_state.clk_bias       = X(i_cb);
rx_state.clk_drift      = X(i_cd);
rx_state.pos_llh        = pos_llh;
rx_state.Re2n           = nav.Re2n; 
rx_state.Flag_propag    = nav.Flag_propag;
%--------------------------------------------------------------------------

dtiono  = zeros(1,32);
dttropo = zeros(1,32);

%--------------------------------------------------------------------------
% GNSS measurement model (EKF and LMS)
%--------------------------------------------------------------------------
% for each satellite available
for m = 1:length(SVID)
    id = SVID(m);
    
    TOWsv_meas = TOWrx - PR_meas(id)/c;
    
    % Predicted measurements from the navigator state
    [PR_nav, PV_nav, los, elev, azim, dt_iono, dt_tropo] = PR_estimation(rx_state, TOWsv_meas, ephemeris(id), param_iono);
    
    % GNSS measurements and prediction
    Zmeas(m)        = PR_meas(id);
    Zmeas(m+Nsv)    = (-c/fL1) * DO_meas(id);   
    Znav(m)         = PR_nav;
    Znav(m+Nsv)     = PV_nav;
    
    
    
    % *********************************************************************
    % EXERCICE 1, QUESTION 3: Measurement model matrix
    % *********************************************************************
    H(m, i_pos)     = los';
    H(m, i_cb)      =  1;
    H(m+Nsv, i_vel) = los';
    H(m+Nsv, i_cd)  = 1;
    % *********************************************************************
    
    
    
    % Measurement noise matrix
    R(m,m)          = sig2_PR * 10.^((30-CN0(id))/10);
    R(m+Nsv,m+Nsv)  = sig2_PV * 10.^((30-CN0(id))/10);
    
    
    % Elevation, azimuth
    sat_elev(id)    = elev;
    sat_azim(id)    = azim;
    
    % Iono, tropo
    dtiono(id)      = dt_iono;
    dttropo(id)     = dt_tropo;
end

% Measurement innovation
DZ = Zmeas - Znav;
%--------------------------------------------------------------------------


%--------------------------------------------------------------------------
% Least Mean Square update
%--------------------------------------------------------------------------
if (Nsv >= 4)
    M    = H' / R;
    P    = inv(M * H);
    K    = P * M; 

    DX   = K * DZ;
    X    = X + DX;

    % Convergence test (geometrical condition : linearisation valid if <1km)
    nav_valid = (norm(DX(i_pos)) < 1000);
      
    % Covariance matrix in ENU frame
    Hc              = H(i_pos,i_pos)*Re2n;
    M               = Hc' ;
    Penu            = inv(M * Hc);
else
    disp(['[gnss_nav_wlmse]:  NAV LMS  no position.']);
end

%--------------------------------------------------------------------------


%--------------------------------------------------------------------------
% Update receiver state data for PR estimation
%--------------------------------------------------------------------------
pos_llh   = convert_ecef2llh(X(i_pos), 'rad');
Re2n      = rotation_matrix_ecef2enu(pos_llh, 'rad');

%--------------------------------------------------------------------------




%--------------------------------------------------------------------------
% OUTPUTS
%--------------------------------------------------------------------------

nav.t               = t; 
nav.X               = X;
nav.P               = P;
nav.Penu            = Penu;
nav.pos_llh         = pos_llh;
nav.pos_ecef        = X(i_pos);
nav.Re2n            = Re2n;
nav.elev            = sat_elev;
nav.azim            = sat_azim;
nav.dt_iono         = dtiono;
nav.dt_tropo        = dttropo;
nav.valid           = nav_valid;


end


