function nav = init_nav(config)

% Navigator struct initialization
%
% Syntax :
% nav = msr_init_nav(config);
%
%
% Input :
%   config : receiver configuration struct
%
% Output :
%   nav    : navigator struct
%
%
%--------------------------------------------------------------------------
% Navigator struct description :
%--------------------------------------------------------------------------
% nav.t               : receiver "system" time      (in s)
% nav.TOW             : estimated GPS reference TOW (in s)
% nav.ix              : struct with the state vector index
% nav.X               : (Nx,1) estimated state vector with :
%                               (3,1) position ECEF (in m)
%                               (3,1) velocity ECEF (in m/s)
%                               (1,1) clock bias    (in m)
%                               (1,1) clock drift   (in m/s)
% nav.P               : (Nx,Nx) state covariance matrix
%
% nav.sig2_PR         : PseudoRange measurement variance at 30dBHz (m^2)
% nav.sig2_PV         : PseudoVelocity measurement variance at 30dBHz (m/s)^2
% 
% nav.pos_ecef        : (3,1) estimated position in ECEF frame (in m)
% nav.vel_ecef        : (3,1) estimated velocity in ECEF frame (in m/s)
% nav.pos_llh         : (3,1) estimated position in LLH frame  (in deg, deg, m)
% nav.Re2n            : (3,3) rotation matrix from ECEF to ENU
% 
%
% nav.enable_EKF      : Configuration flag for EKF activation
% nav.valid           : boolean set to 1 when the navigator has converged

%--------------------------------------------------------------------------

nav.c   = config.c;
nav.fL1 = config.fL1;
%--------------------------------------------------------------------------
% State vector index
nav.Nx              = 8;        % size of the state vector
nav.ix.pos          = 1:3;   	% position in llh coordinates
nav.ix.vel          = 4:6;      % velocity in WGS84 ECEF coordinates
nav.ix.clk_bias  	= 7;      	% clock bias (in m)
nav.ix.clk_drift   	= 8;     	% clock drift (in m/s)
%--------------------------------------------------------------------------

% Time
nav.t               = 0;           
nav.TOW             = 0;           

% State vector
pos_llh                    = config.pos_init;
nav.X                       = zeros(nav.Nx ,1); 
nav.X(nav.ix.pos)           = convert_llh2ecef(pos_llh, 'rad');   
nav.X(nav.ix.vel)           = [0; 0; 0];   
nav.X(nav.ix.clk_bias)   	= 0;           
nav.X(nav.ix.clk_drift)  	= 0;           
nav.P                       = zeros(nav.Nx); 
nav.Penu                    = zeros(nav.Nx);

% noise parameters
nav.sig2_PR         = config.sig2_PR;      
nav.sig2_PV         = config.sig2_PV;   
nav.sig2_pos      	= config.sig2_pos;
nav.sig2_vel     	= config.sig2_vel;
nav.sig2_clkbias	= config.sig2_clkbias;
nav.sig2_clkdrift  	= config.sig2_clkdrift;


% User related data (deduced from the state vector)
nav.pos_ecef        = convert_llh2ecef(pos_llh,'rad');    
nav.vel_ecef        = [0;0;0];     
nav.pos_llh         = pos_llh;     
nav.Re2n            = rotation_matrix_ecef2enu(pos_llh, 'rad');      
nav.elev            = zeros(1,32);
nav.azim            = zeros(1,32);
nav.dt_iono         = zeros(1,32);
nav.dt_tropo        = zeros(1,32);

% Flag
nav.enable_EKF      = config.enable_EKF;
nav.Flag_propag     = config.Flag_propag; 
nav.valid           = 0;                 
%--------------------------------------------------------------------------

end
