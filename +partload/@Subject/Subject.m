classdef Subject
    %Subject Class to hold information for a subject and run complete analysis.
    %
    %   [object] = tlsm.Subject('Optional Parameter 1', 'Value Parameter 1',
    %                'Optional Parameter 2', 'Value Parameter 2', ...);
    %
    %   This class is intended as a container to hold information for
    %   single subject. It allows to build a OpenSim model in combination
    %   with the tlsm.ModelBuilder class and process task simulations using
    %   the tlsm.TaskProcessor class.
    %
    %   Optional Parameters:
    %   subjectId            - [1x1 string] Id of the subject, used for naming.
    %
    %   labRotation          - [1x3 double] Magnitude of rotation in degrees
    %                           for the input data in the c3d file to match
    %                           the OpenSim coordinate system. (Euler XYZ
    %                           sequence)
    %                           Default: [0 0 0]
    %
    %
    %   outputDir            - [1x1 string] Path to directory where output
    %                           files shall be saved at.
    %                           Default: empty
    %
    %   modelMass            - [1x1 double] Mass of the subject in kg.
    %
    %   modelHeight          - [1x1 double] Height of the subject in cm.
    %
    %   modelGender          - [1x1 string] Gender of the subject.
    %                         Either 'M' for male or 'F' for female.
    %
    %   staticFilePath       - [1x1 string]  File path of the c3d file from
    %                           which the subject specific model should be
    %                           derived from. Typically a standing trial.
    %
    %   tasks                - [Nx1 tlsm.Subject] Dynamic tasks which
    %                           belong to the subject and should be
    %                           simulated/processed.
    %
    %   Package: partload
    %
    %   Author(s):      Lukas Connolly (Balgrist Campus, 2020),
    %                   Cedric Rauber (Universität Bern, 2022)

    properties
        subjectId % [1x1 string] Subject ID.
        labRotation = [0 0 0]; % [1x3 double] Magnitude of rotation in degrees for the input data in the c3d file to match the OpenSim coordinate system.
        outputDir % [1x1 string] Path to directory where output files shall be saved at.
        modelMass % [1x1 double] Mass of the subject in kg.
        modelHeight % [1x1 double] Height of the subject in cm.
        modelGender % % [1x1 string] Gender of the subject ('M' or 'F').
        staticFilePath % [1x1 string]  File path of the c3d file from which the subject specific model should be derived from.
        tasks % [Nx1 tlsm.Subject] Dynamic tasks which belong to the subject and should be simulated/processed.
        modelAge % [1x1 double] Age of the subject in years.
    end

    properties(Dependent)
        subjectDir % [1x1 string] Path to the subject directory. Is built from outputDir/subjectId.
        modelPath % [1x1 string] Path to the OpenSim model. Is "obj.subjectDir/model/(obj.subjectId).osim".
    end

    methods
        function obj = Subject(varargin)
            for i=1:2:numel(varargin)
                if isprop(obj, varargin{i})
                    obj.(varargin{i}) = varargin{i+1};
                elseif strcmp(varargin{1}, 'path')
                    obj = Subject.loadSubject(varargin{i+1});
                else
                    warning( 'WARNING: %s is not a valid property', varargin{1} );
                end%if
            end%for
        end%function

        function disp(obj)
            fprintf('-------------\n');
            fprintf('Subject ID: %s\n', obj.subjectId);
            fprintf('Gender: %s\n', obj.modelGender);
            fprintf('Weight: %.2f\n', obj.modelMass);
            fprintf('Height: %.2f\n', obj.modelHeight);
            fprintf('-------------\n');
            fprintf('%d Tasks\n\n', numel(obj.tasks));
            fprintf('%s %s\n',...
                pad('Type', 20),...
                'Num Repetitions' );
            taskIds = arrayfun(@(x)x.taskType, obj.tasks, 'UniformOutput', false);
            taskTypes = unique(taskIds,'stable');
            numPerTaskType = cellfun(@(x)sum(ismember(taskIds,x)),taskTypes,'un',0);
            for i=1:numel(taskTypes)
                fprintf('%s %d\n',...
                    pad(taskTypes{i},20),...
                    numPerTaskType{i});
            end%for
        end%function

        function obj = set.subjectId(obj, subjectId)
            validateattributes(subjectId,{'char'},{'scalartext','nonempty'});
            obj.subjectId = subjectId;
        end

        function obj = set.labRotation(obj, labRotation)
            validateattributes(labRotation,{'numeric'},{'size',[1 3],'>=',-180,'<=',180});
            obj.labRotation = labRotation;
        end

        function obj = set.outputDir(obj, outputDir)
            if( exist(outputDir, 'dir') )
                obj.outputDir = outputDir;
            else
                error( 'Error: The outputDir directory does not exist' );
            end
        end

        function obj = set.modelMass(obj, modelMass)
            validateattributes(modelMass,{'numeric'},{'scalar', 'nonnan', '>', 0, '<', 300 });
            obj.modelMass = modelMass;
        end

        function obj = set.modelHeight(obj, modelHeight)
            validateattributes(modelHeight,{'numeric'},{'scalar', 'nonnan', '>', 0, '<', 2.5 });
            obj.modelHeight = modelHeight;
        end

        function obj = set.modelAge(obj, modelAge)
            validateattributes(modelAge,{'numeric'},{'scalar', 'nonnan', '>', 0, '<', 120 });
            obj.modelAge = modelAge;
        end

        function obj = set.modelGender( obj, modelGender )
            validateattributes(modelGender,{'char'},{'scalartext'});
            options = {'M', 'F'};
            if ~any(strcmp(modelGender, options ))
                error('Error: Property "modelGender" must have one of following values: %s',...
                    char(join(options, ', ')));
            end
            obj.modelGender = modelGender;
        end

        function obj = set.staticFilePath(obj, staticFilePath)
            if( tlsm.utilities.isFileType(staticFilePath, '.c3d') && exist(staticFilePath, 'file') )
                obj.staticFilePath = staticFilePath;
            else
                error( 'Error: The staticFilePath is not of type .c3d, or does not exist' );
            end
        end

        function obj = set.tasks(obj, tasks)
            validateattributes(tasks,{'partload.Task'},{'column'});
            obj.tasks = tasks;
        end

        function outputDir = get.outputDir(obj)
            if ~isempty(obj.outputDir)
                outputDir = obj.outputDir;
            else
                %                 outputDir = pwd;
                %                 outputDir = 'P:\DATEN\FP\Partload\OpenSimData';
                if isunix && ~ismac
                    outputDir = '/home/patric/fast/matlab-output/partload-opensim';
                elseif isunix && ismac
                    outputDir = '/Users/patric/Matlab-Output/partload-opensim';
                else
                    outputDir = 'C:\Users\patric\matlab-output\partload-opensim';
                end
            end
        end

        function subjectDir = get.subjectDir(obj)
            if ~isempty(obj.subjectId)
                subjectDir = fullfile(obj.outputDir, obj.subjectId);
            else
                subjectDir = obj.outputDir;
            end
            if ~exist(subjectDir, 'dir')
                mkdir(subjectDir)
            end
        end

        function modelPath = get.modelPath(obj)
            modelPath = '';
            if ~isempty(obj.subjectId)
                modelPath = fullfile(obj.subjectDir, 'model', [obj.subjectId '.osim']);
            end
        end

        path = saveSubject(obj)
        obj = addTask(obj, task)
        obj = removeTasks(obj, taskType, repetitionId)
        logicalIndices = findTasks(obj, taskType, repetitionId)
        buildModel(obj, modelTemplatePath)
        simulateTasks(obj, taskType, repetitionId)
    end

    methods(Static)
        obj = loadSubject(path)
    end
end