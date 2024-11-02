function [p] = openLoopModel(S_dot, S, U, IC, modelName, MIMO)

N = length(S);

if nargin < 5
    modelName = 'simgen_openloop';   
end
if nargin < 6
    MIMO = 'SISO';
end

% Create/open a simulink model
if ~exist(modelName)
    new_system(modelName)
else
    open_system(modelName)
    Simulink.BlockDiagram.deleteContents(modelName)
end

% Code generate the block for the plant dynamics
%matlabFunctionBlock(strcat(modelName,'/model_ode'), F, 'vars', [vars(idxY) vars(~idxY)]);
if ~isempty(U)
    matlabFunctionBlock(strcat(modelName,'/model_ode'), S_dot, 'vars', {S,U});
else        % no input (autonomous system)
    matlabFunctionBlock(strcat(modelName,'/model_ode'), S_dot, 'vars', {S}, 'Optimize', true);
end
p1 = gcbh;
p2 = add_block('simulink/Continuous/Integrator', strcat(modelName,'/Integrator') );
%add_block('simulink/Sinks/Scope', 'model/Scope')

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
p3 = add_block('simulink/Signal Routing/Demux', strcat(modelName,'/Demux'));
set_param(strcat(modelName,'/Demux'),'Outputs',num2str(N))
add_line(modelName, 'Integrator/1', 'Demux/1')
for k=1:N
    add_block('simulink/Sinks/Scope', strcat(modelName, '/', string(S(k))) )
    add_line(modelName, strcat('Demux/', num2str(k)), strcat(string(S(k)), '/1') )
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
p = [p1 p2 p3 p4];

% Rearrange so it looks nice
Simulink.BlockDiagram.arrangeSystem(modelName)

end

