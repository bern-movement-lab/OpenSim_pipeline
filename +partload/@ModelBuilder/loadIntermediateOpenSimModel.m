function obj = loadIntermediateOpenSimModel(obj, overwrite)
%LOADNEWOPENSIMMODEL Load the newly created OpenSim Model if not already loaded.
%
%   [ModelBuilder] = ModelBuilder.loadNewOpenSimModel( overwrite );
%
%   This method loads an instance of the subject specific Opensim Model and
%   sets it to the ModelBuilder "osModel" property. If the parameter
%   "overwrite" is set to false (default), the model is only loaded when
%   the property "osModel" has not been set yet.
%
%   Inputs:
%   obj         - [1x1 ModelBuilder] Instance of Modelbuilder class.
%
%   overwrite   - [1x1 boolean] Wether to overwrite osModel property when
%                   already set.
%                   Default = false
%
%   Outputs:
%   obj         - [1x1 ModelBuilder] Updated instance of Modelbuilder class.
%
%   +Package: partload
%   @Class: ModelBuilder
%
%   See also: partload.ModelBuilder, org.opensim.modeling.Model

%   Copyright:      2020, Balgrist Campus
%   Author(s):      Lukas Connolly
%                   Philippe Baehler (BFH/Uni Bern, 2024)

if ~exist( obj.newIntermediateModelPath, 'file' )
    error('This function requires the new OpenSim model (obj.newIntermediateModelPath) to already be created');
end

if nargin < 2
    overwrite = false;
end

if isempty(obj.osIntermediateModel) || overwrite
    obj.osIntermediateModel = org.opensim.modeling.Model( obj.newIntermediateModelPath );
    obj.osIntermediateModel.initSystem();
end

end
