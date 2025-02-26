classdef ModelBuilder
    %ModelBuilder Class to create a patient specific OpenSim model.
    %
    %   [object] = ModelBuilder('Optional Parameter 1', 'Value Parameter 1',
    %                'Optional Parameter 2', 'Value Parameter 2', ...);
    %
    %   This class facilitates the creation of a Patient Specific Model 
    %   in OpenSim. Required inputs are  a c3d (or trc) file from a motion 
    %   tracking trial in standing positon (static), as well as 
    %   anthropometric data from the subject (mass, height).
    %
    %   Optional Parameters:
    %   modelName            - [1x1 string] The name of the model. If this
    %                         value is not set, the name will be set from the
    %                         input c3d file.
    %   modelMass            - [1x1 double] Mass of the subject in kg.
    %   modelHeight          - [1x1 double] Height of the subject in cm.
    %   modelGender          - [1x1 string] Gender of the to model.
    %                         Either 'M' for male or 'F' for female.
    %   modelTemplatePath    - [1x1 string] Path of the template to use instead
    %                         of the default OpenSim template this script was
    %                         written for.
    %                         WARNING: Overwriting this parameter will probably
    %                         not work unless the new model is desgined closely
    %                         to the default template.
    %   outputDir            - [1x1 string] Path to directory where output
    %                         files shallbe saved at.
    %   labRotation          - [1x3 double] Magnitude of rotation in degrees
    %                         for the marker locations in the c3d file to
    %                         match the OpenSim coordinate system. (Euler
    %                         XYZ sequence)
    %                         Default: [0 0 0]
    %   scalingSetupFilePath - [1x1 string] Path of the scalin set-up template
    %                         to use instead of the default template this
    %                         script was written for.
    %                         WARNING: Overwriting this parameter will probably
    %                         not work unless the template is desgined closely
    %                         to the default template.
    %   scalingTimeRange     - [1x2 double] Time range of the input trc file
    %                         which shall be used for the OpenSim Scaling tool.
    %                         Default: [0 5]
    %   c3dStaticPath        - [1x1 string] File path of the c3d file from
    %                         which the patient specific model should be
    %                         derived from. If this value is not set, a GUI
    %                         window will appear and ask the user to select a
    %                         file in the file explorer.
    %   trcStaticPath        - [1x1 string] File path of the trc file from
    %                         which the patient specific model should be
    %                         derived from. If this value is not set, the
    %                         script will convert the c3d file with the
    %                         given lab rotations to create a new trc file.
    %
    %   customSpineAlignmentMethod - [1x1 string] Defines which custom spinal
    %                               alignment method for building the model
    %                               should be used.
    %                               Default: SagittalAlignment
    %                               Options: ["None", "SagittalAlignment"]
    %
    %
    %   Outputs:
    %   object               - [1x1 ModelBuilder] Instance of model builder,
    %                         ready to run methods to create patient specific
    %                         model.
    %
    %   Package: partload
    %
    %   Author(s):      Lukas Connolly (Balgrist Campus, 2020),
    %                   Cedric Rauber (Universität Bern, 2022)
    %                   Philippe Baehler (BFH / Uni Bern, 2024)

    properties
        % model properties
        modelName;
        modelMass;
        modelHeight;
        modelGender;
        modelTemplatePath;
        modelAge;

        % general trial properties
        outputDir;
        labRotation = [0 0 0];

        % static trial properties
        scalingSetupFilePath;
        scalingIntermediateSetupFilePath;
        scalingTimeRange = [0 5];
        c3dStaticPath;
        trcStaticPath;
    end

        properties(SetAccess=protected)
        osModel;
        osTemplateModel;
        osIntermediateModel;
        ScalingFactorForVertebra;
        InitialScaling = false;
    end

    properties(Access=protected)
        spaceToModelTransformation;
        templateJointCenters;
        genericJointCenters;
        intermediateJointCenters;
        finalJointCenters;
        calculatedJointCenters;
        JointAngles;
    end

    properties(Dependent=true)
        newModelPath;
        modelDir;
        newIntermediateModelPath;
    end

    methods
        function obj = ModelBuilder( varargin )
            for i=1:2:numel(varargin)
                if isprop(obj, varargin{i})
                    obj.(varargin{i}) = varargin{i+1};
                end
            end
        end

        function obj = set.modelName(obj, modelName)
            validateattributes(modelName,{'char'},{'scalartext','nonempty'});
            obj.modelName = modelName;
        end

        function modelName = get.modelName(obj)
            if ~isempty( obj.modelName )
                modelName = obj.modelName;
            elseif ~isempty( obj.c3dStaticPath )
                [~, modelName] = fileparts( obj.c3dStaticPath );
            else
                modelName = 'Unspecified';
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

        %  function obj = set.modelGender( obj, modelGender )
        %     validateattributes(modelGender,{'char'},{'scalartext'});
        %     options = {'M', 'F'};
        %     if ~any(strcmp(modelGender, options ))
        %         error('Error: Property "modelGender" must have one of following values: %s',...
        %             char(join(options, ', ')));
        %     end
        %     obj.modelGender = modelGender;
        % end

        function obj = set.modelTemplatePath(obj, modelTemplatePath)
            [~, ~, fileExt] = fileparts(modelTemplatePath);
            if( strcmp(fileExt, '.osim') && exist(modelTemplatePath, 'file') )
                obj.modelTemplatePath = modelTemplatePath;
            else
                error( 'Error: The modelTemplatePath is not of type .osim, or does not exist' );
            end
        end

        function modelTemplatePath = get.modelTemplatePath(obj)
            if ( isempty( obj.modelTemplatePath ) )
                obj.modelTemplatePath = obj.getTemplatePath( 'gait2392_simbody.osim' );
            end
            modelTemplatePath = obj.modelTemplatePath;
        end

        function obj = set.outputDir(obj, outputDir)
            if( exist(outputDir, 'dir') )
                obj.outputDir = outputDir;
            elseif(exist(fileparts(outputDir),'dir'))
                mkdir( outputDir );
                obj.outputDir = outputDir;
            else
                error( 'Error: The outputDir directory does not exist' );
            end
        end

        function outputDir = get.outputDir(obj)
            if ~isempty(obj.outputDir)
                outputDir = obj.outputDir;
            else
                outputDir = pwd;
            end
        end

        function obj = set.labRotation(obj, labRotation)
            validateattributes(labRotation,{'numeric'},{'size',[1 3],'>=',-180,'<=',180});
            obj.labRotation = labRotation;
        end

        function obj = set.trcStaticPath(obj, trcStaticPath)
            if( tlsm.utilities.isFileType(trcStaticPath, '.trc') && exist(trcStaticPath, 'file') )
                obj.trcStaticPath = trcStaticPath;
            else
                error( 'Error: The trcStaticPath is not of type .trc, or does not exist' );
            end
        end

        function trcStaticPath = get.trcStaticPath( obj )
            if ~isempty( obj.trcStaticPath )
                trcStaticPath = obj.trcStaticPath;
            elseif ~isempty( obj.c3dStaticPath )
                trcStaticPath = fullfile( obj.modelDir, [obj.modelName '.trc'] );
            else
                trcStaticPath = '';
            end
        end

        function obj = set.c3dStaticPath(obj, c3dStaticPath)
            if( tlsm.utilities.isFileType(c3dStaticPath, '.c3d') && exist(c3dStaticPath, 'file') )
                obj.c3dStaticPath = c3dStaticPath;
            else
                error( 'Error: The c3dStaticPath is not of type .c3d, or does not exist' );
            end
        end

        function obj = set.scalingSetupFilePath(obj, scalingSetupFilePath)
            if( tlsm.utilities.isFileType(scalingSetupFilePath, '.xml') && exist(scalingSetupFilePath, 'file') )
                obj.scalingSetupFilePath = scalingSetupFilePath;
            else
                error( 'Error: The scalingSetupFilePath is not of type .xml, or does not exist' );
            end
        end

        function scalingSetupFilePath = get.scalingSetupFilePath(obj)
            if ( isempty( obj.scalingSetupFilePath ) )
                obj.scalingSetupFilePath = obj.getTemplatePath( 'scalingSetUp_5.xml' );
            end
            scalingSetupFilePath = obj.scalingSetupFilePath;
        end

        function obj = set.scalingTimeRange(obj, scalingTimeRange)
            validateattributes(scalingTimeRange,{'numeric'},{'size',[1,2],'increasing'});
            obj.scalingTimeRange = scalingTimeRange;
        end

        function modelDir = get.modelDir(obj)
            modelDir = fullfile( obj.outputDir, obj.modelName, 'model' );
            if ~exist(modelDir, 'dir')
                mkdir(modelDir);
            end
        end

        function newModelPath = get.newModelPath(obj)
            newModelPath = fullfile( obj.modelDir, [obj.modelName '.osim'] );
        end

        function newIntermediateModelPath = get.newIntermediateModelPath(obj)
            newIntermediateModelPath = fullfile( obj.modelDir, [obj.modelName '_Intermediate.osim'] );
        end%function

    end%methods

        % upper level pipeline methods
    methods
        [obj, newModelPath] = createPatientSpecificModel( obj )
        [obj, newModelPath] = runOpenSimScalingTool( obj )
        [obj, newModelPath] = runAutomaticScalingTool(obj)
        createTools(obj)
    end%methods

    % lower level pipeline methods
    methods(Access = protected)
        obj = prepareTRCFile( obj )
        c3dAdapter = alignC3DData( obj, c3dAdapter )
        setupFilePath = createSpecificScalingSetupFile( obj )
        obj = loadNewOpenSimModel(obj, overwrite)
        obj = loadIntermediateOpenSimModel(obj, overwrite)
        obj = loadTemplateOpenSimModel(obj, overwrite)
        obj = repositionMarkers(obj)
        markerDistances = getTheoreticalMarkerDistancesForScaledModel( obj )
    end%methods

    methods(Access = protected, Static)
        function templatePath = getTemplatePath( name )
            templatePath = fullfile(fileparts(mfilename('fullpath')), 'Templates', name);
        end
    end

end%classdef
