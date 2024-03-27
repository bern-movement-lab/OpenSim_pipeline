function obj = loadTemplateOpenSimModel(obj, overwrite)
%LOADTEMPLATEOPENSIMMODEL Load the Template OpenSim Model if not already loaded.
%
%   [ModelBuilder] = ModelBuilder.loadTemplateOpenSimModel( overwrite );
%
%   This method loads an instance of the template Opensim Model and
%   sets it to the ModelBuilder "osTemplateModel" property. If the parameter
%   "overwrite" is set to false (default), the model is only loaded when
%   the property "osTemplateModel" has not been set yet.
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

if ~exist( obj.modelTemplatePath, 'file' )
    error('This function requires the template OpenSim model (obj.modelTemplatePath) to exist');
end

if nargin < 2
    overwrite = false;
end

if isempty(obj.osTemplateModel) || overwrite
    obj.osTemplateModel = org.opensim.modeling.Model( obj.modelTemplatePath );
    obj.osTemplateModel.initSystem();
end
end
