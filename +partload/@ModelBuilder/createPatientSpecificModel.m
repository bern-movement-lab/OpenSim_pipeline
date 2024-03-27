function [obj, newModelPath] = createPatientSpecificModel(obj)
%CREATEPATIENTSPECIFICMODEL Run complete model bulding pipeline.
%
%   [newModelPath] = ModelBuilder.createPatientSpecificModel();
%
%   obj method runs the complete pipeline to create a patient specific
%   model for OpenSim with default parameters.
%
%   Outputs:
%   newModelPath  - [1x1 string] Full path of the newly created OpenSim
%                       model.
%
%   +Package: partload
%   @Class: ModelBuilder
%
%
%   See also: partload.ModelBuilder

%   Author(s):      Lukas Connolly (Balgrist Campus, 2020),
%                   Cedric Rauber (Universität Bern, 2022)
%                   Philippe Baehler (BFH/Uni Bern, 2024)


disp('Started creating subject specific model');

obj = obj.runOpenSimScalingTool();

disp('Finished creating subject specific model');

% return path of new model
newModelPath = obj.newModelPath;

end
