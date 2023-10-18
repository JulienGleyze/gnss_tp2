function [dt_sat, dt_sat_dot] = satellite_clock(ephemeris, TOW_sv)

% Satellite clock offset and drift
%
% Syntax :
% dt_sat = satellite_clock(ephemeris, TOW_sv);
% [dt_sat, dt_sat_dot] = satellite_clock(ephemeris, TOW_sv);
%
%
% This function computes the satellite offset time at the satellite time.
% (Satellite offset only, tgd and dt_rel are not computed here)
% This offset is cancelled at the toc time. It is modelled as a quadratic 
% function. The parameters of this function are obtained from the 
% navigation message.
%
%
% Inputs :
%   ephemeris :  Ephemeris broadcast by the satellite
%   TOW_sv :     Satellite Time Of Week (in s)
%
%
% Outputs
%   dt_sat :      Satellite clock offset (in s)
%   dt_sat_dot :  Satellite clock drift (in s/s)
%


%--------------------------------------------------------------------------
% The ephemeris include :
%   - af0, af1, af2 which are the polynomial coefficients of the satellite
%           code phase offset
%   - toc which is the clock data reference time
%   - toe which is the ephemeris refence time
%   - tgd which is the estimated group delay differential
%--------------------------------------------------------------------------


toc = [ephemeris.toc];
af2 = [ephemeris.af2];
af1 = [ephemeris.af1];
af0 = [ephemeris.af0];
TOW_sv = TOW_sv(:)';

% *************************************************************************
% EXERCICE 2, QUESTION 3: Satellite clock corrections
% *************************************************************************
 dt_sat      = af0 + af1*(TOW_sv - toc) + af2*toc^2;
 dt_sat_dot  = af1*TOW_sv + af2*(TOW_sv^2 - 2*TOW_sv*toc);

% *************************************************************************
end



