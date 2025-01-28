function obj = prepareSetupFiles(obj)
%PREPARESETUPFILES Prepare setup files and copy them to analysis directory.
%
%   This method runs the pipeline to prepare all setup and input files used
%   to run the IK->ID pipeline.
%
%   Included tasks:
%   1. Check if input file for force plates (GRF) has already been created,
%   if not the script assumes that input files haven't yet been created and
%   calls method tlsm.TaskProcessor.prepareInputFiles to create them.
%
%   2. Prepare GRF setup file by linking all forceplate IDs to the correct
%   foot and referencing the GRF input file (.mot). After manipulating the
%   template file the new version is saved to the analysis directory.
%
%   +Package: partload
%   @Class: TaskProcessor
%
%   See also: partload.TaskProcessor, tlsm.TaskProcessor.prepareInputFiles,
%   partload.TaskProcessor.prepareGRFSetupFile

%   Copyright:      2020, Balgrist Campus
%   Author(s):      Lukas Connolly

% check for required properties
obj = obj.checkForMissingProperties({'outputDir', 'c3dFile'});

if isempty(obj.c3dAdapter) || ~exist(obj.motFile, 'file')
    obj = obj.prepareInputFiles;
end

% copy IK_Setup.xml and Reserve_Actuators.xml to setupFiles dir
copyfile( fullfile( fileparts(mfilename('fullpath')), 'Templates', 'Reserve_Actuators_2.xml' ), obj.xmlSetupReserveActuators );
tlsm.utilities.fancyDisplay(sprintf('Copy Reserve Actuators Setup File to Setup File Dir:\n%s', obj.xmlSetupReserveActuators));

% get pelvis center of mass from model file
xmlDocModel = xmlread(obj.modelFile);
bodySetNode = xmlDocModel.getElementsByTagName('BodySet').item(0);
objectsNode = bodySetNode.getElementsByTagName('objects').item(0);
bodies = objectsNode.getElementsByTagName('Body');
pelvis_com = [];

for i = 0:bodies.getLength-1
    body = bodies.item(i);
    bodyName = char(body.getAttribute('name'));
    if strcmp(bodyName, 'pelvis')
        massCenterNode = body.getElementsByTagName('mass_center').item(0);
        if ~isempty(massCenterNode)
            massCenterStr = char(massCenterNode.getTextContent());
            massCenterValues = sscanf(massCenterStr, '%f %f %f');
            if ~isempty(massCenterValues)
                pelvis_com = massCenterValues(1);
            else
                error('Error: <mass_center> does not contain valid values.');
            end
        else
            error('Error: <mass_center> element not found for pelvis.')
        end
        break;
    end
end

% set pelvis center of mass in Reserve Actuators Setup File
xmlSetupFile = obj.xmlSetupReserveActuators;
xmlDocSetup = xmlread(xmlSetupFile);
forceSetNode = xmlDocSetup.getElementsByTagName('ForceSet').item(0);
objectsNode = forceSetNode.getElementsByTagName('objects').item(0);
valuesUpdated = false;
pointActuators = objectsNode.getElementsByTagName('PointActuator');

for i = 0:pointActuators.getLength-1
    pointActuator = pointActuators.item(i);
    actuatorName = char(pointActuator.getAttribute('name'));
    if ismember(actuatorName, {'FX', 'FY', 'FZ'})
        pointNode = pointActuator.getElementsByTagName('point').item(0);
        if ~isempty(pointNode)
            pointStr = char(pointNode.getTextContent());
            pointValues = sscanf(pointStr, '%f %f %f');
            pointValues(1) = pelvis_com;
            newPointStr = sprintf('%f %f %f', pointValues);
            pointNode.setTextContent(newPointStr);
            valuesUpdated = true;
        end
    end
end

if valuesUpdated
    xmlwrite(xmlSetupFile, xmlDocSetup);
end


% build GRF Setup File and save to setupFiles dir
obj.prepareGRFSetupFile;
disp(['Created GRF Setup File to Setup File Dir: ', obj.xmlSetupGRF, '\n']);

end
