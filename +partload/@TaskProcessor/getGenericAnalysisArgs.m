function args = getGenericAnalysisArgs(obj)
%GETGENERICANALYSISARGS Prepares cell array to pass to constructor of Analysis subclasses
%
%   This method creates a cell array with name-value pairs for all Analysis
%   Class properties which are populated and should be passed to new
%   instances of Analysis subclasses (e.g. InverseKinematics,
%   StaticOptimization).
%
%   +Package: tlsm
%   @Class: TaskProcessor
%
%   Quality Assurance
%   -----------------
%   Classification: [X] data processing  [ ] non-data processing
%   Testing:        [ ] functional test  [ ] runnable example    [ ] manual
%   Unit test:      -
%
%   See also: tlsm.TaskProcessor, mat2os.sim.Analysis

%   Copyright:      2020, Balgrist Campus
%   Author(s):      Lukas Connolly

%generic Analysis Args
props = {'analysisNo', 'analysisName', 'subjectId', 'remarks', 'modelFile', 'outputDir'};

argsUnfiltered = cell(numel(props)*2,1);

for i=1:numel(props)
    if ~isempty(obj.(props{i}))
        argsUnfiltered{i*2-1} = props{i};
        argsUnfiltered{i*2} = obj.(props{i});
    end
end

args = argsUnfiltered(~cellfun(@isempty, argsUnfiltered));

end
