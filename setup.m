% Setup script for SimuGen -- JF

% Get current path and add folders if needed
currentPath = path;
filepath = fileparts(mfilename('fullpath'));

pathstoadd = ["examples", ...
    "inertia", ...
    "KE", ...
    "matrices", ...
    "modelgeneration", ...
    "transforms"];

try
    for folder = pathstoadd
        if ~contains(currentPath, strcat(filepath, "\", folder))
            addpath(filepath, "\", folder);
            disp(strcat("Adding ", folder, "\ to MATLAB path."));
        end
    end
catch err
    warning(err);
end

clear currentPath pathstoadd folder filepath

disp('SimuGen setup complete.')
