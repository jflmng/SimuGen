function [p] = openLoopModel(S_dot, S, U, IC, modelName, MIMO)

% Check if S_dot is symbolic or a matlab function
if strcmp(class(S_dot),'sym')
    symbolic = true;
else
    symbolic = false;
end

N = length(S);
open_model = true;

if nargin < 5
    modelName = 'simugen_openloop';   
end
if nargin < 6
    MIMO = 'SISO';
end
if nargout >= 1
    open_model = false;
end

% Create/open a simulink model
if ~exist(modelName)
    new_system(modelName)
    % open_system(modelName)
    disp('Creating new Simulink model.')
else
    % open_system(modelName)
    disp('Overwriting Simulink model.')
    Simulink.BlockDiagram.deleteContents(modelName)
end

% Code generate the block for the plant dynamics
if symbolic
    %matlabFunctionBlock(strcat(modelName,'/model_ode'), F, 'vars', [vars(idxY) vars(~idxY)]);
    if ~isempty(U)
        matlabFunctionBlock(strcat(modelName,'/model_ode'), S_dot, 'vars', {S,U});
    else        % no input (autonomous system)
        matlabFunctionBlock(strcat(modelName,'/model_ode'), S_dot, 'vars', {S}, 'Optimize', true);
    end
    
    %add_block('simulink/Sinks/Scope', 'model/Scope')
else  
    add_block('simulink/User-Defined Functions/MATLAB Function', strcat(modelName,'/model_ode'))
    mat_func = get_param(strcat(modelName,'/model_ode'),'MATLABFunctionConfiguration');
    mat_func.FunctionScript = ['function dY = fcn(Y,D,D2)', newline, newline, ...
        'dY = ', S_dot, ';'];
    sf = sfroot();
    blk = sf.find('Path',strcat(modelName,'/model_ode'),'-isa','Stateflow.EMChart');
    inp = blk.Inputs;
    inp(2).Scope = 'Parameter';
    inp(3).Scope = 'Parameter';
end

p1 = gcbh;
p2 = add_block('simulink/Continuous/Integrator', strcat(modelName,'/Integrator') );

% To avoid errors for MIMO systems, add a mux for multidimensional inputs
% TO DO - currently this breaks the feedback models! only do this if asked
if strcmp(class(U),'sym') && strcmp(MIMO, 'MIMO')
    add_block('simulink/Signal Routing/Mux', strcat(modelName,'/Mux') );
    set_param(strcat(modelName,'/Mux'),'Inputs',num2str(length(U)))
    add_line(modelName, 'Mux/1', 'model_ode/2');
end

% Make some connections to form the feedback loop and integrate
add_line(modelName, 'model_ode/1', 'Integrator/1')
add_line(modelName, 'Integrator/1', 'model_ode/1')

% Add a demux with scopes to show outputs
if symbolic
    p3 = add_block('simulink/Signal Routing/Demux', strcat(modelName,'/Demux'));
    set_param(strcat(modelName,'/Demux'),'Outputs',num2str(N))
    add_line(modelName, 'Integrator/1', 'Demux/1')
    for k=1:N
        add_block('simulink/Sinks/Scope', strcat(modelName, '/', string(S(k))) )
        add_line(modelName, strcat('Demux/', num2str(k)), strcat(string(S(k)), '/1') )
    end
else    % If this is a PDE/Fd scheme, save the output to workspace
    p3 = add_block('simulink/Sinks/To Workspace', strcat(modelName,'/to_workspace'));
    add_line(modelName, 'Integrator/1', 'to_workspace/1');
end

% Set initial conditions so we don't get error
set_param(strcat(modelName,'/Integrator'),'InitialConditionSource','external')
p4 = add_block('simulink/Sources/Constant', strcat(modelName,'/Initial Conditions'));
add_line(modelName, 'Initial Conditions/1', 'Integrator/2')
set_param(strcat(modelName,'/Initial Conditions'), 'Value', IC);

% % Make a subsystem with the plant model blocks
% Simulink.BlockDiagram.arrangeSystem(modelName)
% Simulink.BlockDiagram.createSubsystem([p1 p2 p3 p4]);
% s1 = gcbh;
% set_param(s1, 'Name', 'Plant');
if symbolic
    p = [p1 p2 p3 p4];
else
    p = [p1 p2 p4];
end

% Rearrange so it looks nice and open the system
Simulink.BlockDiagram.arrangeSystem(modelName,FullLayout='true')

% If we did not call with an output argument, open system
if open_model
    open_system(modelName)
end

end

