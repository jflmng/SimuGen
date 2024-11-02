function [] = stateFeedbackModel(S_dot, S, U, IC, K, S_op, U_op, modelName)

% Create a simulink model
if nargin < 7
    U_op = zeros(size(U));
    modelName = 'simgen_statefeedback';   
elseif nargin < 8
    modelName = 'simgen_statefeedback';   
end

if ~exist(modelName)
    new_system(modelName)
else
    open_system(modelName)
    Simulink.BlockDiagram.deleteContents(modelName)
end
    
% Start with the open-loop model
p = openLoopModel(S_dot, S, U, IC, modelName);

% Add the gain block and operating points
c1 = add_block('simulink/Sources/Constant', strcat(modelName,'/Operating Point'));
c2 = add_block('simulink/Math Operations/Sum', strcat(modelName,'/Sum'));
c3 = add_block('simulink/Math Operations/Gain', strcat(modelName,'/K'));
c4 = add_block('simulink/Sources/Constant', strcat(modelName,'/Input OP'));
c5 = add_block('simulink/Math Operations/Sum', strcat(modelName,'/Sum2'));
add_line(modelName, 'Integrator/1', 'Sum/1')
add_line(modelName, 'Operating Point/1', 'Sum/2')
add_line(modelName, 'Sum/1', 'K/1')
add_line(modelName, 'K/1', 'Sum2/1')
add_line(modelName, 'Input OP/1', 'Sum2/2')
add_line(modelName, 'Sum2/1', 'model_ode/2')

% Add a demux with scopes to show controller outputs
c6 = add_block('simulink/Signal Routing/Demux', strcat(modelName,'/Demux2'));
M = length(U);
set_param(strcat(modelName,'/Demux2'),'Outputs',num2str(M))
add_line(modelName, 'Sum2/1', 'Demux2/1')
for k=1:M
    add_block('simulink/Sinks/Scope', strcat(modelName, '/', string(U(k))) )
    add_line(modelName, strcat('Demux2/', num2str(k)), strcat(string(U(k)), '/1') )
end

% Set the operating point
set_param(strcat(modelName,'/Sum'), 'Inputs', '|+-')
OPstr = makeMatrixString(S_op);
set_param(strcat(modelName,'/Operating Point'), 'Value', OPstr)

% Set the input operating point
set_param(strcat(modelName,'/Sum2'), 'Inputs', '|++')
UOPstr = makeMatrixString(U_op);
set_param(strcat(modelName,'/Input OP'), 'Value', UOPstr)

% Convert the K into string to go in gain block
set_param(strcat(modelName,'/K'), 'Multiplication', 'Matrix(K*u)')
Kstr = makeMatrixString(K);
set_param(strcat(modelName,'/K'), 'Gain', Kstr)

Simulink.BlockDiagram.arrangeSystem(modelName)

% Make subsystems with the plant and controller model blocks
c = [c1 c2 c3 c4 c5 c6];
Simulink.BlockDiagram.createSubsystem(c);
s1 = gcbh;
set_param(s1, 'Name', 'Controller');

Simulink.BlockDiagram.createSubsystem(p);
s2 = gcbh;
set_param(s2, 'Name', 'Plant');

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
