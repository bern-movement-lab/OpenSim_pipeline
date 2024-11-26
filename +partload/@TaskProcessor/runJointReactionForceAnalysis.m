function runJointReactionForceAnalysis(obj)
%RUNJOINTREACTIONFORCEANALYSIS Run OpenSim JointReactionForces analyzer tool.
%
%   This method creates an instance of a JointReactionForces class with all
%   required properties and runs the analysis.
%
%   Before creating the JointReactionForces object, the method checks if the
%   input motion file (output of InverseKinematics) has already been
%   created, else it runs InverseKinematics first.
%
%   +Package: partload
%   @Class: TaskProcessor
%
%
%   See also: partload.TaskProcessor, mat2os.sim.JointReactionForces

%   Copyright:      2020, Balgrist Campus
%   Author(s):      Lukas Connolly
%                   Philippe Baehler (BFH/Uni Bern, 2024)

if ~exist(obj.soOutputFile, 'file')
    try
        obj.runStaticOptimization;
    catch
        warning('runStaticOptimization failed for %s!', obj.analysisTitle);
        return;
    end
end

genericArgs = obj.getGenericAnalysisArgs;

disp(['Started with joint reaction forces for ', obj.analysisTitle]);

jrf = mat2os.sim.JointReactionForces(...
    genericArgs{:},...
    'motionFile', obj.ikOutputFile,...
    'xmlSetupGRFFile', obj.xmlSetupGRF,...
    'xmlSetupActuators', obj.xmlSetupReserveActuators,...
    'muscleForcesFilePath', obj.soOutputFile,...
    'stepInterval', obj.stepInterval...
    );

% run simulation
% try 10 times to get clean output file
for k=1:10
    jrf.run()
    if obj.isValidJointReactionFile()
        break;
    elseif k == 10
        error('Failed to obtain valid joint reaction output file after 10 iterations for %s', obj.analysisTitle);
    end
end

disp(['Finished with joint reaction forces for ',obj.analysisTitle])


end
