function obj = readC3DFile(obj)
%READC3DFILE Read c3d file and load c3d adapter.
%
%   This method creates an instance of a c3d adapter based on the given
%   properties of the TaskProcessor class and assigns the new instance to
%   the c3dAdapter property of the task processor class object.
%
%   TaskProcesor properties which are considered are:
%   - c3dFile
%   - timeRange
%   - subjectId
%   - analysisName
%   - analysisNo
%   - inputFileDir (dependent of outputDir)
%   - labRotation
%
%   +Package: partload
%   @Class: TaskProcessor
%
%
%   See also: partload.TaskProcessor, mat2os.utilities.C3DAdapter

%   Copyright:      2020, Balgrist Campus
%   Author(s):      Lukas Connolly

if isempty(obj.c3dFile) || isempty(obj.outputDir)
    error('c3dFile and outputDir need to be set to properly read c3dFile');
end

%% prepare args to create c3d adapter

%arg fields for c3dAdapter
args = {'c3dPath', 'timeRange', 'subjectId', 'taskName', 'trialNumber', 'outputDir', 'labRotation', 'forcePlateOffsets'};
%properties of task processor to match
props = {'c3dFile', 'timeRange', 'subjectId', 'analysisName', 'analysisNo', 'inputFileDir', 'labRotation', 'forcePlateOffsets'};

argsUnfiltered = cell(numel(args)*2,1);

for i=1:numel(props)
    if ~isempty(obj.(props{i}))
        argsUnfiltered{i*2-1} = args{i};
        argsUnfiltered{i*2} = obj.(props{i});
    end
end

argsFiltered = argsUnfiltered(~cellfun(@isempty, argsUnfiltered));

%% create c3d adapter

obj.c3dAdapter = mat2os.utilities.C3DAdapter(argsFiltered{:});

disp(['Read c3d File: ' obj.c3dFile]);

end
