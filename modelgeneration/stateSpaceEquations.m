function [EOM_rhs, S] = stateSpaceEquations(EOM, X)
%STATESPACEEQUATIONS - A replacement for ODEToVectorField that works
% to symbolically calculate derivatives/Jacobians with symbolic toolbox

% EOM should be the equations of motion
% X is a cell array of symfuns for each generalised coordinate

% TO DO: Also make a descriptor state space version that does not decouple

N = length(X);

% % Decouple the equations first, in case second derivatives are in several
if N > 1
    parts = children(EOM);
    for ii = 1:N
        eq{ii} = parts{ii}{1} == parts{ii}{2};
    end
    for ii = 1:N
        for jj = [1:ii-1, ii+1:N]
            try
                eq{ii} = subs(eq{jj}, diff(X{jj},2), rhs(isolate(eq{ii}, diff(X{jj},2))));
            catch

            end
        end
    end
    EOM = vertcat(eq{:});
end

syms t      % assume this is the independent variable

% Create 'dot' variables for each symfun
for k = 1:N
    varName = char(X{k});
    X_dot{k} = str2sym(strcat(varName(1:end-3),'_dot(t)'));   % cut off '(t)', add '_dot(t)'
end

% Perform substitutions to reduce to first order using X_dot
for k = 1:N
    EOM = subs(EOM, diff(X{k},t), X_dot{k});
    EOM = subs(EOM, diff(X{k},2), diff(X_dot{k},t));
end

% Rearrange the resulting equations to have X_dot alone on LHS
kids = children(EOM);
if N > 1
    for k = 1:N
        eq{k} = isolate(kids{k}{1} == kids{k}{2}, diff(X_dot{k},t));
    end
else
    eq{1} = isolate(kids{1} == kids{2}, diff(X_dot{1},t));
end

% Assemble the nonlinear state space representation
EOM_SS = []; XX = {};
for k = 1:N
    EOM_SS = [EOM_SS; diff(X{k},t) == X_dot{k}; eq{k}];
    XX = {XX{:}, X{k}, X_dot{k}};
end

% Strip the '(t)'s and convert symfuns to symvars
for k = 1:2*N
    varName = char(XX{k});
    SS{k} = sym(strcat(upper(varName(1)), varName(2:end-3)));
end

% Sub vars into statespace equations and return RHS
EOM_rhs = subs(rhs(EOM_SS), XX, SS);

% Convert cell array of states to column vector
syms S [2*N 1]
for k = 1:2*N
    S(k) = SS{k};
end

% The following is a hack to remove '(t)' and change symfuns to sym
% EOM_rhs = str2sym(char(EOM_rhs));
EOM_rhs = EOM_rhs(t);       % Is this faster for large expressions?
EOM_rhs = simplify(EOM_rhs);

end