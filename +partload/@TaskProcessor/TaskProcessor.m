classdef TaskProcessor < mat2os.sim.Analysis
    %TASKPROCESSOR Class to run the IK->ID OpenSim Pipeline for a dynamic trial.
    %
    %   [object] = TaskProcessor('Optional Parameter 1', 'Value Parameter 1',
    %                'Optional Parameter 2', 'Value Parameter 2', ...);
    %
    %   This class facilitates the preparation and running of the OpenSim
    %   IK->ID OpenSim Pipeline. By preparing inputFiles from the c3d
    %   format to an OpenSim trajectory file (.trc) and OpenSim forceplate
    %   data file (.mot). If necessary allowing to split data for bipedal
    %   forcePlate acquisitions. Manipulating and copying required Setup
    %   Files to the Analysis directory (GRF, IK and ReserveActuators).
    %
    %   The TaskProcessor is a subclass of mat2os.sim.Analysis. Properties
    %   of the abstract parent class are not further described here, but
    %   are necessary to create a functioning TaskProcessor (e.g. modelFile
    %   and outputDir).
    %
    %   Possible Parameters:
    %   c3dFile              - [1x1 string] The path to the c3d file which
    %                           contains the required data (trajectories
    %                           and force plate data) of the dynamic task.
    %   timeRange            - [1x2 double] Start and endtime of the task
    %                           which shall be analysed within the acquisition.
    %   autoEvents           - [1x1 logical] Whether to set timeRange
    %                           automatically, if a EventDetector method exists
    %                           for the task type.
    %                           Default: true
    %   stepInterval         - [1x1 double] How often to record results during
    %                           the static optimization / joint reaction
    %                           analysis. A value of 1 means results are
    %                           recorded every 1 frame of motion data.
    %                           Default: 1
    %   labRotation          - [1x3 double] Magnitude of rotation in degrees
    %                           for the input data in the c3d file to match
    %                           the OpenSim coordinate system. (Euler XYZ
    %                           sequence)
    %                           Default: [0 0 0]
    %   leftForcePlateIds    - [1xN double] Ids of forceplates in the
    %                           acquisition, which shall be applied to the
    %                           left foot (calcn_l).
    %   rightForcePlateIds   - [1xN double] Ids of forceplates in the
    %                           acquisition, which shall be applied to the
    %                           right foot (calcn_r).
    %   forcePlateOffsets    - [1x1 struct] Offset values which should be
    %                           added to forcePlateData to compensate for
    %                           incorrect nulling of forcePlate during
    %                           during trial (or other uses...).
    %                           The fieldname of the struct should represent
    %                           the column of the forcedata to manipulate
    %                           and the value should be a [1x1 double] which
    %                           will be added to the forcePlateData by calling
    %                           the method "addForcePlateOffsets".
    %                           Default: empty
    %
    %   Package: partload
    %
    %   See also: mat2os.sim.Analysis
    %   Copyright:      2020, Balgrist Campus
    %   Author(s):      Lukas Connolly
    %                   Philippe Baehler (BFH/Uni Bern, 2024)
    
    properties
        c3dFile % [1x1 string] The path to the c3d file which contains the required data.
        timeRange % [1x2 double] Start and endtime of the task which shall be analysed within the acquisition.
        autoEvents = true; % [1x1 logical] Whether to set timeRange automatically, if a EventDetector method exists for the task type.
        stepInterval = 1; % [1x1 double] The interval of motion data frames to use for static optimization / joint reaction analysis.
        labRotation = [-1 1 -1]; % [1x3 double] Magnitude of rotation in degrees for the input data in the c3d file to match the OpenSim coordinate system.
        leftForceplateIDs = []; % [1xN double] Ids of forceplates in the acquisition, which shall be applied to the left foot (calcn_l).
        rightForceplateIDs = []; % [1xN double] Ids of forceplates in the acquisition, which shall be applied to the right foot (calcn_r).
        forcePlateOffsets % [1x1 struct] Offset values which should be added to the c3d forceplate data.
    end
    
    properties(Access=private)
        c3dAdapter
    end
    
    properties(Dependent)
        trcFile % [1x1 string] Path to output trc File. (not automatically created!)
        motFile % [1x1 string] Path to output mot File. (not automatically created!)
        xmlSetupGRF % [1x1 string] Path to GRF Setup File. (not automatically created!)
        xmlSetupGRFFile % [1x1 string] Path to GRF Setup File. (not automatically created!)
        xmlSetupReserveActuators % [1x1 string] Path to Reserve Actuators Setup File. (not automatically created!)
        ikOutputFile % [1x1 string] Path of the Inverse Kinematics Output File. (not automatically created!)
        soOutputFile % [1x1 string] Path of the Static Optimization Output File. (not automatically created!)
        jrOutputFile % [1x1 string] Path of the Joint Reaction Analysis Output File. (not automatically created!)
    end
    
    methods
        function obj = TaskProcessor(varargin)
            for i=1:2:numel(varargin)
                if isprop(obj, varargin{i})
                    obj.(varargin{i}) = varargin{i+1};
                else
                    warning( 'WARNING: %s is not a valid property', varargin{1} );
                end
            end
        end
        
        function obj = set.c3dFile(obj, c3dFile)
            if( mat2os.utilities.isFileType(c3dFile, '.c3d') && exist(c3dFile, 'file') )
                obj.c3dFile = c3dFile;
            else
                error( 'Error: The c3dFile is not of type .c3d, or does not exist' );
            end
        end
        
        function obj = set.timeRange(obj, timeRange)
            validateattributes(timeRange,{'numeric'},{'size',[1 2],'nonnegative','increasing'});
            obj.timeRange = timeRange;
        end
        
        % function obj = set.autoEvents(obj, autoEvents)
        %     validateattributes(autoEvents,{'logical'},{'scalar'});
        %     obj.autoEvents = autoEvents;
        % end
        
        function obj = set.stepInterval(obj, stepInterval)
            validateattributes(stepInterval,{'numeric'},{'scalar', 'nonnan', '>', 0 });
            obj.stepInterval = stepInterval;
        end
        
        function obj = set.labRotation(obj, labRotation)
            validateattributes(labRotation,{'numeric'},{'size',[1 3],'>=',-180,'<=',180});
            obj.labRotation = labRotation;
        end
        
        function obj = set.leftForceplateIDs(obj, leftForceplateIDs)
            validateattributes(leftForceplateIDs,{'numeric'},{'row','positive','integer'});
            obj.leftForceplateIDs = leftForceplateIDs;
        end
        
        function obj = set.rightForceplateIDs(obj, rightForceplateIDs)
            validateattributes(rightForceplateIDs,{'numeric'},{'row','positive','integer'});
            obj.rightForceplateIDs = rightForceplateIDs;
        end
        
        function obj = set.forcePlateOffsets(obj, forcePlateOffsets)
            if isempty(forcePlateOffsets)
                obj.forcePlateOffsets = [];
                return
            end
            if(~isstruct(forcePlateOffsets))
                error('The forcePlateOffsets variable must be of type "struct"');
            end
            fieldNames = fieldnames(forcePlateOffsets);
            for i=1:numel(fieldNames)
                value = forcePlateOffsets.(fieldNames{i});
                if ~isnumeric(value)
                    error('forcePlateOffsets.%s needs to be numeric', fieldNames{i});
                elseif ~isscalar(value)
                    error('forcePlateOffsets.%s needs to be a scalar value', fieldNames{i});
                end
            end
            obj.forcePlateOffsets = forcePlateOffsets;
        end
        
        function trcFile = get.trcFile(obj)
            if ~isempty(obj.c3dAdapter)
                trcFile = obj.c3dAdapter.trcPath;
            else
                trcFile = '';
            end
        end
        
        function motFile = get.motFile(obj)
            if ~isempty(obj.c3dAdapter)
                motFile = obj.c3dAdapter.motPath;
            else
                motFile = '';
            end
        end
        
        function xmlSetupGRF = get.xmlSetupGRF(obj)
            xmlSetupGRF = fullfile(obj.setupFileDir, sprintf('%s_GRF_Setup.xml', obj.analysisTitle));
        end
        
        function xmlSetupReserveActuators = get.xmlSetupReserveActuators(obj)
            xmlSetupReserveActuators = fullfile(obj.setupFileDir, sprintf('%s_ReserveActuators.xml', obj.analysisTitle));
        end
        
        function ikOutputFile = get.ikOutputFile(obj)
            ikOutputFile = fullfile(obj.analysisDir, sprintf('%s_InverseKinematics.mot', obj.analysisTitle));
        end
        
        function soOutputFile = get.soOutputFile(obj)
            soOutputFile = fullfile(obj.analysisDir, sprintf('%s_StaticOptimization_force.sto', obj.analysisTitle));
        end
        
        function jrOutputFile = get.jrOutputFile(obj)
            jrOutputFile = fullfile(obj.analysisDir, sprintf('%s_JointReaction_ReactionLoads.sto', obj.analysisTitle));
        end
        
        obj = readC3DFile(obj)
        obj = prepareInputFiles(obj)
        obj = prepareSetupFiles(obj)
        runInverseKinematics(obj)
        runStaticOptimization(obj)
        runJointReactionForceAnalysis(obj)
        valid = isValidJointReactionFile(obj)
        runInverseDynamics(obj)
        
    end
    
    methods(Access=private)
        obj = splitForcePlates(obj, fpIds2Split)
        obj = prepareGRFSetupFile(obj)
        args = getGenericAnalysisArgs(obj)
    end
end
