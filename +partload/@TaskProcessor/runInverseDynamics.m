function runInverseDynamics(obj)
%RUNINVERSEKINEMATICS Run OpenSim InverseKinematics analyzer tool.
%
%   This method creates an instance of a InverseKinematics class with all
%   required properties and runs the analysis.
%
%   Before creating the InverseKinematics object, the method checks if all
%   required input and setup files have already been created, else it
%   creates them.
%
%   +Package: partload
%   @Class: TaskProcessor
%
%   See also: partload.TaskProcessor, mat2os.sim.InverseKinematics

%   Copyright:      2020, Balgrist Campus
%   Author(s):      Lukas Connolly
%                   Philippe Baehler (BFH/Uni Bern, 2024)

if ~exist(obj.ikOutputFile, 'file')
    obj.runInverseKinematics;
end

genericArgs = obj.getGenericAnalysisArgs;

disp(['Started with inverse dynamics for ', obj.analysisTitle]);

id = mat2os.sim.InverseDynamics(...
    genericArgs{:},...
    'timeRange', obj.timeRange,...
    'xmlSetupGRFFile', obj.xmlSetupGRF,...
    'xmlSetupFileTemplate', fullfile( fileparts(mfilename('fullpath')), 'Templates', 'ID_setup.xml' ),...
    'coordinatesFile', obj.ikOutputFile ...
    );

id.run();

disp(['Finished with inverse dynamics for ', obj.analysisTitle]);

end
