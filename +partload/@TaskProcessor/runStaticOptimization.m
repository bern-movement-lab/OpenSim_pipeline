function runStaticOptimization(obj)
%RUNSTATICOPTIMIZATION Run OpenSim StaticOptimization analyzer tool.
%
%   This method creates an instance of a StaticOptimization class with all
%   required properties and runs the analysis.
%
%   Before creating the StaticOptimization object, the method checks if the
%   input motion file (output of InverseKinematics) has already been
%   created, else it runs InverseKinematics first.
%
%   +Package: partload
%   @Class: TaskProcessor
%
%   Quality Assurance
%   -----------------
%   Classification: [X] data processing  [ ] non-data processing
%   Testing:        [ ] functional test  [ ] runnable example    [ ] manual
%   Unit test:      -
%
%   See also: tlsm.TaskProcessor, mat2os.sim.StaticOptimization

%   Copyright:      2020, Balgrist Campus
%   Author(s):      Lukas Connolly
%                   Philippe Baehler (BFH/Uni Bern, 2024)

if ~exist(obj.ikOutputFile, 'file')
    obj.runInverseKinematics;
end

genericArgs = obj.getGenericAnalysisArgs;

disp(['Started with static optimization for ', obj.analysisTitle]);

so = mat2os.sim.StaticOptimization(...
    genericArgs{:},...
    'motionFile', obj.ikOutputFile,...
    'xmlSetupGRFFile', obj.xmlSetupGRF,...
    'xmlSetupActuators', obj.xmlSetupReserveActuators,....
    'stepInterval', obj.stepInterval...
    );

so.run();

disp(['Finished with static optimization for ', obj.analysisTitle]);

end


