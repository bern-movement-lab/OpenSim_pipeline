classdef Task
    %TASK Class to hold information for a single task to be used in combination with the Subject class.
    %
    %   [object] = partload.Task(taskType, repetitionId, c3dPath, frameRange,
    %                'Optional Parameter 1', 'Value Parameter 1',
    %                'Optional Parameter 2', 'Value Parameter 2', ...);
    %
    %   This class is intended as a container to hold information for
    %   single tasks of a subject. It is typically used as a property in
    %   scalar or vector (multiple tasks) form in combination with the
    %   partload.Subject class.
    %
    %   Required Parameters:
    %   taskType              - [1x1 string] The type of the task, e.g.
    %                               gait, run etc.
    %   repetitionId          - [1x1 string] The id of the task repetition,
    %                               e.g. 'Rep01', 'Rep02' etc.
    %   c3dPath               - [1x1 string] The path to the c3d file which
    %                               contains the required data (trajectories
    %                               and force plate data) of the dynamic task.
    %   frameRange            - [1x2 double] Start and end frame of the task
    %                               which shall be analysed within the
    %                               acquisition.
    %
    %   Optional Parameters:
    %   leftForceplateIDs    - [1xN double] Ids of forceplates in the
    %                           acquisition, which shall be added to the
    %                           left foot (calcn_l).
    %   rightForceplateIDs   - [1xN double] Ids of forceplates in the
    %                           acquisition, which shall be added to the
    %                           right foot (calcn_r).
    %
    %   Package: partload
    %
    %   See also: partload.Subject, partload.TaskProcessor
    
    %   Copyright:      2020, Balgrist Campus
    %   Author(s):      Lukas Connolly
    %                   Philippe Baehler (BFH / Uni Bern, 2024)
    
    properties
        taskType % [1x1 string] The type of the task.
        repetitionId % [1x1 string] The id of the task repetition.
        c3dPath % [1x1 string] The path to the c3d file which contains the required kinematic data.
        frameRange % [1x2 double] Start and end frame of the task which shall be analysed within the acquisition.
        leftForceplateIDs % [1xN double] Ids of forceplates in the acquisition, which shall be added to the left foot.
        rightForceplateIDs % [1xN double] Ids of forceplates in the acquisition, which shall be added to the right foot.
    end

    methods
        function obj = Task(taskType,repetitionId, c3dPath, varargin)
      % function obj = Task(taskType,repetitionId, c3dPath, frameRange,varargin)
            obj.taskType = taskType;
            obj.repetitionId = repetitionId;
            obj.c3dPath = c3dPath;
            % obj.frameRange = frameRange;
            for i=1:2:numel(varargin)
                if isprop(obj, varargin{i})
                    obj.(varargin{i}) = varargin{i+1};
                else
                    warning( 'WARNING: %s is not a valid property', varargin{1} );
                end
            end
        end
        
        function obj = set.taskType(obj, taskType)
            validateattributes(taskType,{'char'},{'scalartext','nonempty'});
            obj.taskType = taskType;
        end
        
        function obj = set.repetitionId(obj, repetitionId)
            validateattributes(repetitionId,{'char'},{'scalartext','nonempty'});
            obj.repetitionId = repetitionId;
        end
        
        function obj = set.c3dPath(obj, c3dPath)
            if( tlsm.utilities.isFileType(c3dPath, '.c3d') && exist(c3dPath, 'file') )
                obj.c3dPath = c3dPath;
            else
                error( 'Error: The staticFilePath is not of type .c3d, or does not exist' );
            end
        end
        
        function obj = set.frameRange(obj, frameRange)
            validateattributes(frameRange,{'numeric'},{'size',[1 2],'nonnegative','increasing','integer'});
            obj.frameRange = frameRange;
        end
        
        function obj = set.leftForceplateIDs(obj, leftForceplateIDs)
            if isempty(leftForceplateIDs)
                obj.leftForceplateIDs = [];
            else
                validateattributes(leftForceplateIDs,{'numeric'},{'row','positive','integer'});
                obj.leftForceplateIDs = leftForceplateIDs;
            end
        end
        
        function obj = set.rightForceplateIDs(obj, rightForceplateIDs)
            if isempty(rightForceplateIDs)
                obj.rightForceplateIDs = [];
            else
                validateattributes(rightForceplateIDs,{'numeric'},{'row','positive','integer'});
                obj.rightForceplateIDs = rightForceplateIDs;
            end
        end
    end
end