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
copyfile( fullfile( fileparts(mfilename('fullpath')), 'Templates', 'Reserve_Actuators_3.xml' ), obj.xmlSetupReserveActuators );
tlsm.utilities.fancyDisplay(sprintf('Copy Reserve Actuators Setup File to Setup File Dir:\n%s', obj.xmlSetupReserveActuators));

% build GRF Setup File and save to setupFiles dir
obj.prepareGRFSetupFile;
disp(['Created GRF Setup File to Setup File Dir: ', obj.xmlSetupGRF, '\n']);

end
