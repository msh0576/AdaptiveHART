clc; clear all; close all;


delta_t = 10;
th1_initial = 0.01;
th2_initial = 0.01;

%Task_period = [10 10 4]     %for event trigger, when event is triggered, stored data should be transfered according to arrive flowid
%Task_period_time_initial = Task_period * 10

Tf = 50;              
sensor_sampling_rate=5; %sampling rate
%delta_t=1/sensor_sampling_rate; %control period
step_count=Tf*sensor_sampling_rate; %total step count
sen_num = 2; % sensor number 




x1ini=2;
x2ini=5;
Xini=[x1ini;x2ini];
uini=0; 

x1sp=5.6;
x2sp=-5.2;

Xsp=[x1sp;x2sp];

%% RUN Wireless  Process Control Simulation
tic





Ydelay = zeros(step_count+1,sen_num);
Delay = 0;
ranD=[4 2 2 2 2]; %delayed time steps 

    
    delay1 = zeros(step_count+1,sen_num+1);

    yin=0;
    yin_d=0;
    ystore = Ydelay;
    count = 1;
    i = 0;

    structure.i = 0;
    structure.count = count;
    structure.yin = yin;
    structure.yin_d = yin_d;
    structure.delay1 = delay1;
    structure.ranD = ranD;







% -------------------------------------------
%   Trevor Slade
%   Brigham Young University
%   Prism Group 
%   Dr. Hedengren
% --------------------------------------------

% ------------------------------------------------
%         PARAMETERS
% ------------------------------------------------

% Set it up so calcs are made in SI units

% the variable h refers to height

% Diameters

%P.dP = .25;      % inner pipe diameter (inches)
%P.dT = 10;       % inner tank diameter (inches)
P.dP = .20;      % inner pipe diameter (inches)
P.dT = 12;       % inner tank diameter (inches)
%.15/12
% height

%P.hT = 18;       % inner tank height (inches)
P.hT = 20;       % inner tank height (inches)
% density

P.rho = 1;       % g/cm^3
P.g = 9.8;          % acceleration of gravity (m/s^2)

% Convert to SI (specifically cm and g)

P.dP = 6*P.dP;   % inner pipe diameter (centimeters)
P.dT = 2.54*P.dT;   % inner tank diameter (centimeters)
P.hT = 2.54*P.hT;   % inner tank height (centimeters)
P.g = P.g*100;      % acceleration of gravity (cm/s^2)

% coefficient for flow out of the bottom of the tanks

P.Cf_tanks = (pi*(P.dP/2)^2)*(P.rho^1.5)*sqrt(2*P.g);


% Constants (to make calculations easier

P.C_HM = P.rho*(pi*(P.dT/2)^2);  % Convert from dhdt to dmdt

P.C_CM = (pi*(P.dP/2)^2)*P.rho;  % Convert from velocity to mass flow

% Make it even more convenient...

P.C1 = P.C_CM/P.C_HM;
P.C2 = P.Cf_tanks/P.C_HM;

% Velocities (they are static as of now)

P.v1_max = 500;        % cm/s
P.v2_max = P.v1_max;     % cm/s


% --------------------
%  Plant 2
% --------------------


P2.dP = .25;      % inner pipe diameter (inches)
P2.dT = 10;       % inner tank diameter (inches)

% height

P2.hT = 40;       % inner tank height (inches)

% density

P2.rho = 1;       % g/cm^3
P2.g = 9.8;          % acceleration of gravity (m/s^2)

% Convert to SI (specifically cm and g)

P2.dP = 6*P2.dP;   % inner pipe diameter (centimeters)
P2.dT = 2.54*P2.dT;   % inner tank diameter (centimeters)
P2.hT = 2.54*P2.hT;   % inner tank height (centimeters)
P2.g = P2.g*100;      % acceleration of gravity (cm/s^2)

% coefficient for flow out of the bottom of the tanks

P2.Cf_tanks = (pi*(P2.dP/2)^2)*(P2.rho^1.5)*sqrt(2*P2.g);


% Constants (to make calculations easier

P2.C_HM = P2.rho*(pi*(P2.dT/2)^2);  % Convert from dhdt to dmdt

P2.C_CM = (pi*(P2.dP/2)^2)*P2.rho;  % Convert from velocity to mass flow

% Make it even more convenient...

P2.C1 = P2.C_CM/P2.C_HM;
P2.C2 = P2.Cf_tanks/P2.C_HM;

% Velocities (they are static as of now)

P2.v1_max = 500;        % cm/s
P2.v2_max = P2.v1_max;     % cm/s



