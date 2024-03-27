function buildModel(obj, modelTemplatePath)
%BUILDMODEL Build a subject specific OpenSim model from property values.
%
%   This method builds a subject specific OpenSim model from the subject
%   object instance property values using the tlsm.ModelBuilder class.
%
%   For this method to run properly following properties must be set
%   properly:
%       - subjectId
%       - modelMass
%       - modelHeight
%       - staticFilePath
%
%   +Package: partload
%   @Class: Subject
%
%   Quality Assurance
%   -----------------
%   Classification: [X] data processing  [ ] non-data processing
%   Testing:        [ ] functional test  [ ] runnable example    [ ] manual
%   Unit test:      -
%
%   See also: partload.Subject, tlsm.ModelBuilder

%   Author(s):      Lukas Connolly (Balgrist Campus, 2020),
%                   Cedric Rauber (Universität Bern, 2022),
%                   Philippe Baehler (BFH / Uni Bern, 2024)
requiredProps = {'subjectId', 'modelMass', 'modelHeight', 'staticFilePath'};
for i=1:numel(requiredProps)
    if isempty(obj.(requiredProps{i}))
        error('Property "%s" must be set properly to build model!', requiredProps{i});
    end%if
end%for

modelBuilder = partload.ModelBuilder(...
    'modelName', obj.subjectId,...
    'modelMass', obj.modelMass,...
    'modelHeight', obj.modelHeight,...
    'modelGender', obj.modelGender,...
    'c3dStaticPath', obj.staticFilePath,...
    'outputDir', obj.outputDir,...
    'labRotation', obj.labRotation...
    );

if nargin > 1
    modelBuilder.modelTemplatePath = modelTemplatePath;
end

modelBuilder.createPatientSpecificModel();

end%function

