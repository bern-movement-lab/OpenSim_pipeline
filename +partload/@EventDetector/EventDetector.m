classdef EventDetector
    %EVENTDETECTOR Class to get start and end time for task programmatically.
    %
    %   [object] = EventDetector('Optional Parameter 1', 'Value Parameter 1',
    %                'Optional Parameter 2', 'Value Parameter 2', ...);
    %
    %   This class finds start and end times for tasks by analysing
    %   kinematic marker trajectories and distinguishing task specific
    %   patterns.
    %
    %   Possible Parameters:
    %   c3dAdapter   - [1x1 mat2os.utilities.C3DAdapter] An instance of a
    %                           C3D Adapter which contains the required
    %                           marker trajectories.
    %                           ATTENTION: If c3d Data should be rotated or
    %                           cropped, this should be done before adding
    %                           c3dAdapter to this class.
    %                           Default: empty
    %
    %   timeRange    - [1x2 double] Start and endtime of the data
    %                           which shall be analysed within the acquisition.
    %                           If this value is not set and the set
    %                           c3dAdapter has a timeRange specified this
    %                           will be used.
    %                           Default: empty
    %
    %   task         - [1x1 string] Name of the task pattern which should
    %                           be looked for. Other task names can not be
    %                           set. If task is not set and c3dAdapter has
    %                           taskName set, this value will be used if it
    %                           is a valid task.
    %                           Implemented tasks are:
    %                               - liftUp
    %                               - liftDown
    %                               - sitUp
    %                               - sitDown
    %                               - walk
    %                           Default: empty
    %
    %   savePlots    - [1x1 logical] Defines whether plot of analysed kinematic
    %                           data and start and endtimes should be saved
    %                           to output directory of c3dAdapter.
    %                           Default: true
    %
    %   Package: tlsm
    %
    %   Quality Assurance
    %   -----------------
    %   Classification: [X] data processing  [ ] non-data processing
    %   Testing:        [ ] functional test  [ ] runnable example    [ ] manual
    %   Unit test:      -
    %
    %   See also: mat2os.utilities.C3DAdapter,
    %   tlsm.TaskProcessor.prepareInputFiles
    
    %   Copyright:      2020, Balgrist Campus
    %   Author(s):      Lukas Connolly
    %                   Philippe Baehler (BFH/Uni Bern, 2024)
    
    
    properties
        c3dAdapter % [1x1 mat2os.utilities.C3DAdapter] An instance of a C3D Adapter which contains the required marker trajectories.
        timeRange % [1x2 double] Start and end time of the data which shall be analysed within the acquisition.
        task % [1x1 string] Name of the task pattern which should looked for.
        savePlots = true; % [1x1 logical] Defines whether plot of analysed kinematic data and start and endtimes should be saved.
    end
    
    properties (Constant)
        implementedTasks = {... % [1xN cell] All implemented taskNames with appropiate methods to get start and end time for events.
            'liftUp',...
            'liftDown',...
            'sitUp',...
            'sitDown',...
            'walk'...
            };
    end
    
    properties(Dependent)
        markerTable % [NxM table] Marker data from c3d Adapter.
    end
    
    methods
        function obj = EventDetector(varargin)
            for i=1:2:numel(varargin)
                if isprop(obj, varargin{i})
                    obj.(varargin{i}) = varargin{i+1};
                else
                    warning( 'WARNING: %s is not a valid property', varargin{1} );
                end
            end
        end
        
        function obj = set.c3dAdapter(obj, c3dAdapter)
            validateattributes(c3dAdapter,{'mat2os.utilities.C3DAdapter'},{'scalar'});
            obj.c3dAdapter = c3dAdapter;
        end
        
        function obj = set.savePlots(obj, savePlots)
            validateattributes(savePlots,{'logical'},{'scalar'});
            obj.savePlots = savePlots;
        end
        
        function obj = set.task(obj, task)
            validateattributes(task,{'char'},{'scalartext'});
            if ~any(strcmp(obj.implementedTasks, task))
                error(['Task "%s" has not yet been implemented. '...
                    'So far only following tasks are available: %s'],...
                    task, strjoin(obj.implementedTasks, ', '));
            end
            obj.task = task;
        end
        
        function task = get.task(obj)
            if isempty(obj.task)
                task = '';
                if ~isempty(obj.c3dAdapter)
                    if ~isempty(obj.c3dAdapter.taskName) && ...
                            any(strcmp(obj.implementedTasks, obj.c3dAdapter.taskName))
                        task = obj.c3dAdapter.taskName;
                    end
                end
            else
                task = obj.task;
            end
        end
        
        function timeRange = get.timeRange(obj)
            if isempty(obj.timeRange)
                timeRange = [0 Inf];
                if ~isempty(obj.c3dAdapter)
                    if ~isempty(obj.c3dAdapter.timeRange)
                        timeRange = obj.c3dAdapter.timeRange;
                    end
                end
            else
                timeRange = obj.timeRange;
            end
        end
        
        function markerTable = get.markerTable(obj)
            markerTable = [];
            if ~isempty(obj.c3dAdapter)
                if isstruct(obj.c3dAdapter.markers)
                    markerTable = obj.c3dAdapter.markers.data;
                    % filter time points if necessary
                    if any(obj.timeRange)
                        markerTable = markerTable( markerTable.Time >= obj.timeRange(1) &...
                            markerTable.Time <= obj.timeRange(2), : );
                    end
                end
            end
        end
        
        timeRange = getEventTimestamps(obj)
        
    end
    
    methods(Access=private)
        timeRange = getLiftUpEvents(obj)
        timeRange = getLiftDownEvents(obj)
        timeRange = getSitUpEvents(obj)
        timeRange = getSitDownEvents(obj)
        timeRange = getWalkEvents(obj)
    end
    
end
