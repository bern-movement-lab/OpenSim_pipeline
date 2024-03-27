function [this, newModelPath] = runOpenSimScalingTool( this )
%RUNOPENSIMSCALINGTOOL Run the OpenSim scaling tool.
%
%   [newModelPath] = ModelBuilder.runOpenSimScalingTool();
%
%   This method creates a copy of the scalingSetupFile Template within the
%   output directory. Then modifies all subject specific data values and
%   runs the OpenSim scaling tool after.
%
%   Outputs:
%   newModelPath  - [1x1 string] Full path of the newly created OpenSim
%                       model.
%
%   +Package: partload
%   @Class: ModelBuilder
%
%
%   See also: partload.ModelBuilder,
%   partload.ModelBuilder.createPatientSpecificModel

%   Copyright:      2020, Balgrist Campus
%   Author(s):      Lukas Connolly
%                   Philippe Baehler (BFH / Uni Bern, 2024)

disp('Started running OpenSim Scaling Tool');

% create subject specific scaling setup file from template
scalingSetupFile = this.createSpecificScalingSetupFile();

% copy Geometry files from template directory if not already existent,
% as there will be problems rendering the model in OpenSim if geometry
% files are not located at the same directory with the model
if ~exist( fullfile( this.modelDir, 'geometry' ), 'dir' )
    copyfile( fullfile( fileparts(this.modelTemplatePath), 'geometry' ), fullfile( this.modelDir, 'geometry' ) );
end

% run scaling tool
scaleTool = org.opensim.modeling.ScaleTool( scalingSetupFile );
scaleTool.setName( this.modelName );
scaleTool.setPathToSubject('');
scaleTool.run;

% Save the scaled model
this = this.loadNewOpenSimModel;
this.osModel.print(this.newModelPath);
% return path of new model
newModelPath = this.newModelPath;


% set InitialScaling factor
this.InitialScaling = true;
  
disp('Finished running OpenSim Scaling Tool');

end
