function setupFilePath = createSpecificScalingSetupFile( this )
%CREATESPECIFICSCALINGSETUPFILE Modifies scaling setup file template.
%
%   [setupFilePath] = ModelBuilder.createSpecificScalingSetupFile();
%
%   This method takes the set scaling setup file template and creates a
%   subject specific copy of it (including anthropometric data, etc.) and
%   locates it within the output directory.
%
%   Outputs:
%   setupFilePath  - [1x1 string] Full path of the newly created OpenSim
%                       scaling setup file.
%
%   +Package: partload
%   @Class: ModelBuilder
%
%
%   See also: partload.ModelBuilder,
%   tlsm.ModelBuilder.runOpenSimScalingTool

%   Copyright:      2020, Balgrist Campus
%   Author(s):      Lukas Connolly
%                   Philippe Baehler (BFH / Uni Bern, 2024)

this = this.prepareTRCFile;

%% load xml
if this.InitialScaling == false
    xmlDoc = xmlread(this.scalingSetupFilePath);
elseif this.InitialScaling == true
    xmlDoc = xmlread(this.scalingIntermediateSetupFilePath);
end
%% manipulate xml

xmlDoc.getElementsByTagName('time_range').item(0).getFirstChild.setData(num2str(this.scalingTimeRange));
xmlDoc.getElementsByTagName('time_range').item(1).getFirstChild.setData(num2str(this.scalingTimeRange));
xmlDoc.getElementsByTagName('model_file').item(0).getFirstChild.setData(this.modelTemplatePath);
xmlDoc.getElementsByTagName('marker_file').item(0).getFirstChild.setNodeValue(this.trcStaticPath);
xmlDoc.getElementsByTagName('marker_file').item(1).getFirstChild.setNodeValue(this.trcStaticPath);
xmlDoc.getElementsByTagName('mass').item(0).getFirstChild.setNodeValue(num2str(this.modelMass)); %setting patient-specific mass value on xml file
xmlDoc.getElementsByTagName('height').item(0).getFirstChild.setNodeValue(num2str(this.modelHeight)); %setting patient-specific height value on xml file
xmlDoc.getElementsByTagName('output_model_file').item(0).getFirstChild.setNodeValue(this.newModelPath);
xmlDoc.getElementsByTagName('output_model_file').item(1).getFirstChild.setNodeValue(this.newModelPath);

%% write xml

setupFilesDir = fullfile(this.modelDir, 'setupFiles');

if ~exist(setupFilesDir, 'dir')
    mkdir (setupFilesDir);
end

if this.InitialScaling == false
    setupFilePath = fullfile( setupFilesDir, [ this.modelName '_IntermediateScaleSetUp.xml'] );
    
elseif this.InitialScaling == true
    setupFilePath = fullfile( setupFilesDir, [ this.modelName '_FinalScaleSetUp.xml'] );
end

xmlwrite(setupFilePath, xmlDoc);

end
