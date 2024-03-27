function obj = prepareInputFiles(obj)
%PREPAREINPUTFILES Prepare input files from c3d and copy them to analysis dir.
%
%   This method runs the pipeline to prepare all input files used to run
%   the IK->ID pipeline.
%
%   Included tasks:
%   1. Read c3d File and create instance of c3d Adapter.
%
%   2. Rotate data as specified by labRotation property.
%
%   3. Split forcePlate data which are assigned to left and right foot at
%       the same time.
%
%   4. Set timeRange from marker trajectories if EventDetector method
%       exists and autoEvents is set to true.
%
%   5. Write Output Files to Input Files Analysis Directory.
%       - Trajectory File (.trc)
%       - Forceplate Data (.mot)
%
%   +Package: tlsm
%   @Class: TaskProcessor
%
%   See also: partload.TaskProcessor, partload.TaskProcessor.prepareInputFiles,
%   partload.TaskProcessor.readC3DFile, partload.TaskProcessor.splitForcePlates,
%   mat2os.utilities.C3DAdapter

%   Copyright:      2020, Balgrist Campus
%   Author(s):      Lukas Connolly
%                   Philippe Baehler (BFH/Uni Bern, 2024)

% check that all necessary props are set
obj = obj.checkForMissingProperties({'outputDir', 'c3dFile'});

% set c3dAdapter
obj = obj.readC3DFile;

% rotate data (needs to be done before splitting GRF, to work with all lab rotations)
obj.c3dAdapter = obj.c3dAdapter.rotateData;
disp('Rotated c3d Data');

% % rotate data depending on startOrientation;
% if ~strcmp(obj.startOrientation, 'forward')
%     switch obj.startOrientation
%         case 'backward'
%             obj.c3dAdapter.labRotation = [0 180 0];
%         case 'right'
%             obj.c3dAdapter.labRotation = [0 -90 0];
%         case 'left'
%             obj.c3dAdapter.labRotation = [0 90 0];
%         otherwise
%             warning('Invalid startOrientation. labRotation set to [0 0 0]');
%             obj.c3dAdapter.labRotation = [0 0 0];
%     end
%     obj.c3dAdapter = obj.c3dAdapter.rotateData;
%     tlsm.utilities.fancyDisplay('Rotated c3d Data according to startOrientation');
% end

% add forceplate offsets if necessary
if ~isempty(obj.forcePlateOffsets)
    obj.c3dAdapter = obj.c3dAdapter.addForcePlateOffsets;
    tlsm.utilities.fancyDisplay('Added c3d forcePlateData Offsets');
end

% split forceplate data if necessary
fpIds2Split = intersect(obj.leftForceplateIDs, obj.rightForceplateIDs);
if ~isempty(fpIds2Split)
    obj = obj.splitForcePlates(fpIds2Split);
    printf('Split Forceplate Data for Forceplate IDs: %s', num2str(fpIds2Split));
end

% set forceplate columns to export
forcePlateIds = union(obj.leftForceplateIDs, obj.rightForceplateIDs);
if ~isempty(forcePlateIds)
    obj.c3dAdapter.forcePlateIds = forcePlateIds;
end

% set events from kinematic data if computational method is implemented
if obj.autoEvents
    eventDetector = tlsm.EventDetector('c3dAdapter', obj.c3dAdapter);
    if ~isempty(eventDetector.task)
        obj.timeRange = eventDetector.getEventTimestamps;
        obj.c3dAdapter.timeRange = obj.timeRange;
        printf('Auto Detected Start and End Event: %fs to %fs', obj.timeRange(1), obj.timeRange(2));
    end
end

% rotate, trim data and write output files (trc and mot)
obj.c3dAdapter.writeTRC;
disp(['Wrote .trc File: ', obj.trcFile,  '\n']);
obj.c3dAdapter.writeMOT;
disp(['Wrote .mot File: ', obj.motFile, '\n']);
obj.c3dAdapter.saveInfos;

end
