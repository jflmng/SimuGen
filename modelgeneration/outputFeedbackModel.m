function [] = outputFeedbackModel(S_dot, S, U, IC, K, S_op, sys_est, C, U_op, modelName)

% Create a simulink model
if nargin < 9
    U_op = zeros(size(U));
    modelName = 'simgen_outputfeedback';   
elseif nargin < 10
    modelName = 'simgen_outputfeedback';   
end

if ~exist(modelName)
    new_system(modelName)
else
    open_system(modelName)
    Simulink.BlockDiagram.deleteContents(modelName)
end
    
% Start with the open-loop model
p = openLoopModel(S_dot, S, U, IC, modelName);

% Add the state feedback gain block and operating points
add_block('simulink/Sources/Constant', strcat(modelName,'/Operating Point'));
c2 = add_block('simulink/Math Operations/Sum', strcat(modelName,'/Sum'));
c3 = add_block('simulink/Math Operations/Gain', strcat(modelName,'/K'));
c4 = add_block('simulink/Sources/Constant', strcat(modelName,'/Input OP'));
c5 = add_block('simulink/Math Operations/Sum', strcat(modelName,'/SumIOP'));

add_line(modelName, 'Operating Point/1', 'Sum/2')
add_line(modelName, 'Sum/1', 'K/1')
add_line(modelName, 'K/1', 'SumIOP/1')
add_line(modelName, 'Input OP/1', 'SumIOP/2')
add_line(modelName, 'SumIOP/1', 'model_ode/2')

% Add a demux with scopes to show controller outputs
c6 = add_block('simulink/Signal Routing/Demux', strcat(modelName,'/Demux2'));
M = length(U);
set_param(strcat(modelName,'/Demux2'),'Outputs',num2str(M))
add_line(modelName, 'SumIOP/1', 'Demux2/1')
for k=1:M
    add_block('simulink/Sinks/Scope', strcat(modelName, '/', string(U(k))) )
    add_line(modelName, strcat('Demux2/', num2str(k)), strcat(string(U(k)), '/1') )
end

% Add the system output gain block
pC = add_block('simulink/Math Operations/Gain', strcat(modelName,'/C'));
Cstr = makeMatrixString(C);
set_param(strcat(modelName,'/C'), 'Gain', Cstr)
set_param(strcat(modelName,'/C'), 'Multiplication', 'Matrix(K*u)')
add_line(modelName, 'Integrator/1', 'C/1')

% Add the observer/estimator state space system
c1 = add_block('simulink/Continuous/State-Space', strcat(modelName,'/Estimator'));

% Must empty parameters first or we get a dimension error
n = size(sys_est.A,1);
set_param(strcat(modelName,'/Estimator'), 'A', '[]')
set_param(strcat(modelName,'/Estimator'), 'B', '[]')
set_param(strcat(modelName,'/Estimator'), 'C', '[]')
set_param(strcat(modelName,'/Estimator'), 'D', '[]')
Astr = makeMatrixString(sys_est.A);
Bstr = makeMatrixString(sys_est.B);
Cstr = makeMatrixString(sys_est.C(end-n+1:end,:));     % just take the 'state' part
Dstr = makeMatrixString(sys_est.D(end-n+1:end,:));
set_param(strcat(modelName,'/Estimator'), 'A', Astr)
set_param(strcat(modelName,'/Estimator'), 'B', Bstr)
set_param(strcat(modelName,'/Estimator'), 'C', Cstr)
set_param(strcat(modelName,'/Estimator'), 'D', Dstr)
add_line(modelName, 'C/1', 'Estimator/1')
add_line(modelName, 'Estimator/1', 'Sum/1')

% Set the operating point
set_param(strcat(modelName,'/Sum'), 'Inputs', '|+-')
OPstr = makeMatrixString(S_op);
set_param(strcat(modelName,'/Operating Point'), 'Value', OPstr)

% Set the input operating point
set_param(strcat(modelName,'/SumIOP'), 'Inputs', '|++')
UOPstr = makeMatrixString(U_op);
set_param(strcat(modelName,'/Input OP'), 'Value', UOPstr)

% Convert the K into string to go in gain block
set_param(strcat(modelName,'/K'), 'Multiplication', 'Matrix(K*u)')
Kstr = makeMatrixString(K);
set_param(strcat(modelName,'/K'), 'Gain', Kstr)

% Add a scope for viewing the observer error
add_block('simulink/Math Operations/Sum', strcat(modelName,'/Sum2'));
set_param(strcat(modelName,'/Sum2'), 'Inputs', '+-|')
add_block('simulink/Sinks/Scope', strcat(modelName, '/Estimator Errors'))
add_line(modelName, 'Sum2/1', 'Estimator Errors/1')
add_line(modelName, 'Estimator/1', 'Sum2/2')
add_line(modelName, 'Integrator/1', 'Sum2/1')

% Arrange before we create any subsystems
Simulink.BlockDiagram.arrangeSystem(modelName)

% Make a subsystem with the plant model blocks
Simulink.BlockDiagram.createSubsystem([p pC]);
s1 = gcbh;
set_param(s1, 'Name', 'Plant');
% Simulink.BlockDiagram.arrangeSystem(modelName)

% Make a subsystem with the controller blocks
Simulink.BlockDiagram.createSubsystem([c1 c2 c3 c4 c5 c6]);
s1 = gcbh;
set_param(s1, 'Name', 'Controller');
% Simulink.BlockDiagram.arrangeSystem(modelName)

% Final arrangement
Simulink.BlockDiagram.arrangeSystem(modelName)

end

% Helper function to create strings for the simulink dialogs
function str = makeMatrixString(M)

    Kdim = size(M);
    str = '[';
    for row = 1:Kdim(1)
        str = strcat(str, num2str(M(row,:)), ';');
    end
    str = strcat(str,']');

end
