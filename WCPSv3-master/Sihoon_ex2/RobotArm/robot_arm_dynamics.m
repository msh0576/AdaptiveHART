function [sys,x0,str,ts] = robot_arm_dynamics(t,x,u,flag,A,B,C,D)

switch flag
    
    %%%%%%%%%%%%%%%%%%
    % Initialization %
    %%%%%%%%%%%%%%%%%%
    case 0
        [sys,x0,str,ts]=mdlInitializeSizes(A,B,C,D);
        
        %%%%%%%%%%%%%%%
        % Derivatives %
        %%%%%%%%%%%%%%%
    case 1
        sys=mdlDerivatives(t,x,u,A,B,C,D);
        
        %%%%%%%%%%%
        % Outputs %
        %%%%%%%%%%%
    case 3
        sys=mdlOutputs(t,x,u,A,B,C,D);
        
    case {2, 4, 9}
        sys = [];
        
        %%%%%%%%%%%%%%%%%%%%
        % Unexpected flags %
        %%%%%%%%%%%%%%%%%%%%
    otherwise
        DAStudio.error('Simulink:blocks:unhandledFlag', num2str(flag));
        
end



function [sys,x0,str,ts] = mdlInitializeSizes(A,B,C,D)


%
% call simsizes for a sizes structure, fill it in and convert it to a
% sizes array.
%
% Note that in this example, the values are hard coded.  This is not a
% recommended practice as the characteristics of the block are typically
% defined by the S-function parameters.
%
sizes = simsizes;

sizes.NumContStates  = 2;
sizes.NumDiscStates  = 0;
sizes.NumOutputs     = 1;
sizes.NumInputs      = 1;
sizes.DirFeedthrough = 0;
sizes.NumSampleTimes = 1;   % at least one sample time is needed

sys = simsizes(sizes);

%
% initialize the initial conditions

x0  = [0; 0];

%
% str is always an empty matrix
%
str = [];

%
% initialize the array of sample times
%

ts  = [0 0];

% end mdlInitializeSizes

%==========================================================
% mdlDerivatives
% Return the derivatives for the continuous states.
%=============================================================================
%

function sys=mdlDerivatives(t,x,u,A,B,C,D)

sys = A*x + B*u;

function sys = mdlOutputs(t,x,u,A,B,C,D)
sys = C*x;
