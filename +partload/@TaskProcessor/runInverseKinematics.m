function runInverseKinematics(obj)
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

if ~exist(obj.trcFile, 'file') || ~exist(obj.xmlSetupIK, 'file')
    obj = obj.prepareSetupFiles;
end

genericArgs = obj.getGenericAnalysisArgs;

disp(['Started with inverse kinematics for ', obj.analysisTitle]);

ik = mat2os.sim.InverseKinematics(...
    genericArgs{:},...
    'timeRange', obj.timeRange,...
    'trcFile', obj.trcFile,...
    'xmlSetupFileTemplate', fullfile( fileparts(mfilename('fullpath')), 'Templates', 'IK_setup_2.xml' )...
    );

ik.run();

disp(['Finished with inverse kinematics for ', obj.analysisTitle]);
end