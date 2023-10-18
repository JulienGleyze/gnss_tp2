function [PR, PV, los, elev, azim, dt_iono, dt_tropo] = PR_estimation(rx_state, TOWsv, ephemeris, param_iono)

% Compute estimated GNSS measurements from ephemeris data
%
% Syntax :
% [PR, PV, los, elev, azim] = PR_estimation(rx_state, TOWsv, ephemeris, param_iono);
%
%
% INPUTS :
%   rx_state   : receiver state data struct
%   TOWsv      : satellite transmission Time Of Week (in s, satellite clock)
%   ephemeris  : ephemeris struct (one satellite only)
%   param_iono : ionospheric parameters struct
%
% OUTPUTS :
%   PR         : PseudoRange         (in m)
%   PV         : PseudoVelocity      (in m/s)
%   los        : Line Of Sight unit vector in ECEF frame
%   elev       : satellite elevation (in rad)
%   azim       : satellite azimuth   (in rad)
%

%--------------------------------------------------------------------------
% Receiver state data struct description :
%--------------------------------------------------------------------------
% rx_state.TOWrx_ref : receiver GPS reference TOW            (in s)
% rx_state.pos_ecef  : (3,1) receiver position in ECEF frame (in m)
% rx_state.vel_ecef  : (3,1) receiver velocity in ECEF frame (in m/s)
% rx_state.clk_bias  : receiver clock bias                   (in m)
% rx_state.clk_drift : receiver clock drift                  (in m/s)
% rx_state.pos_llh;  : (3,1) receiver position in LLH frame  (in deg, deg, m)
% rx_state.Re2n      : (3,3) rotation matrix from ECEF to ENU
% rx_state.valid     : boolean set to 1 when the navigator has converged
%--------------------------------------------------------------------------


%--------------------------------------------------------------------------
% Constants
c   = 2.99792458e8; % light speed (m/s)
%--------------------------------------------------------------------------


%--------------------------------------------------------------------------
% Receiver state data
%--------------------------------------------------------------------------
TOWrx_ref   = rx_state.TOWrx_ref;
pos_ecef    = rx_state.pos_ecef;
vel_ecef    = rx_state.vel_ecef;
clk_bias    = rx_state.clk_bias;
clk_drift   = rx_state.clk_drift;
pos_llh     = rx_state.pos_llh;
Re2n        = rx_state.Re2n;
Flag_propag = rx_state.Flag_propag;

%--------------------------------------------------------------------------

dt_iono     = 0;
dt_tropo    = 0;
%--------------------------------------------------------------------------
% Satellite parameters
%--------------------------------------------------------------------------
% Signal emission time (satellite time)
[dt_sat, dt_sat_dot] = satellite_clock(ephemeris, TOWsv);
TOWsv_ref = TOWsv - dt_sat;

% Satellite position (ECEF frame)
[pos_sat, vel_sat, dt_rel] = satellite_position(ephemeris, TOWsv_ref, TOWrx_ref);

% Range and line of sight
range   = norm(pos_ecef - pos_sat);     % satellite-receiver distance
los     = (pos_ecef - pos_sat) / range; % satellite-receiver unit vector in ECEF frame
%--------------------------------------------------------------------------



%--------------------------------------------------------------------------
% Azimuth and elevation of the satellite (in radian)
%--------------------------------------------------------------------------
los_enu      = Re2n * los;                      % los in ENU frame
azim         = atan2(-los_enu(1), -los_enu(2)); % azimuth in ENU frame
elev         = asin(-los_enu(3));               % elevation in ENU frame
% *************************************************************************



% *************************************************************************
% EXERCICE 2, QUESTION 5: PseudoRange estimate with corrections
% *************************************************************************
% receiver clock bias correction
PR = range + clk_bias;

% satellite clock bias correction
PR = PR - c*dt_sat;

% tgd correction
PR = PR + c*ephemeris.tgd;

% t_relativ correction
PR = PR - c*dt_rel;


if Flag_propag
    % ionospheric model: use delay_iono function
    if ~isempty(param_iono) % if ionospheric parameters are present in ephemeris
        dt_iono = delay_iono(pos_llh, azim, elev, TOWrx_ref, param_iono);
        PR      = PR + c*dt_iono;                                         
    end

    % tropospheric model: use delay_tropo function
    dt_tropo    = delay_tropo(elev, pos_llh(3));
    PR          = PR + c*dt_tropo;
end
% *************************************************************************


%--------------------------------------------------------------------------
% Pseudo Velocity estimate (related to Doppler measurements)
vel_los = los' * (vel_ecef - vel_sat); % relative radial velocity
PV      = vel_los + clk_drift - c*dt_sat_dot;
%--------------------------------------------------------------------------

end