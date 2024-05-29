function simulateTasks(obj, taskType, repetitionId)
%SIMULATETASKS Simulate full IK->ID analysis pipeline.
%
%   This method runs the full partload. TaskProcessor pipeline for each 
%   task of the subject tasks property. If a subject specific model has not
%   been created yet, the method first runs the method 
%   partload.Subject.buildModel.
%
%   Optional Input Parameters:
%   taskType      - [1x1 string] Task type for tasks which should be simulated.
%   repetitionId  - [1x1 string] Id of the repetition of the task which
%                           should be simulated.
%
%   After completing the simulations all figures created by the
%   eventDetector are copied to the directory:
%       {obj.subjectDir}/images/eventDetector
%
%   +Package: partload
%   @Class: Subject
%
%
%   See also: partload.Subject, partload.TaskProcessor

%   Copyright:      2020, Balgrist Campus
%   Author(s):      Lukas Connolly
%                   Philippe Baehler (BFH/Uni Bern, 2024)

% make sure model exists, else create one.
if ~exist(obj.modelPath, 'file')
    obj.buildModel;
end

tasks = obj.tasks;

if nargin > 2
    tasks = tasks(obj.findTasks(taskType, repetitionId));
elseif nargin > 1
    tasks = tasks(obj.findTasks(taskType));
end

for i=1:numel(tasks)
    
    task = tasks(i);
        
    disp(['Started with task ', task.taskType, ' ', task.repetitionId ' for ', obj.subjectId]);

    c3d = ezc3dRead(task.c3dPath);
    %% create time array differently or start with 0s!!!
%     task.frameRange = [c3d.header.points.firstFrame, c3d.header.points.lastFrame];
    task.frameRange = [0, (c3d.header.points.lastFrame -c3d.header.points.firstFrame)];
    
    taskProcessor = partload.TaskProcessor(...
        'outputDir', obj.outputDir, ...
        'subjectId', obj.subjectId,...
        'analysisName', task.taskType,...
        'analysisNo', task.repetitionId,...
        'modelFile', obj.modelPath,...
        'c3dFile', task.c3dPath,...
        'timeRange', task.frameRange / 200,...
        'labRotation', obj.labRotation...
        );
    
    if ~isempty(task.leftForceplateIDs)
        taskProcessor.leftForceplateIDs = task.leftForceplateIDs;
    end
    
    if ~isempty(task.rightForceplateIDs)
        taskProcessor.rightForceplateIDs = task.rightForceplateIDs;
    end

    % run simulation
    taskProcessor.runInverseDynamics;
    taskProcessor.runJointReactionForceAnalysis;
    
    % convert outputs to csv
    motFiles = dir(fullfile(taskProcessor.analysisDir, '*.mot'));
    for motFileIdx = 1:numel(motFiles)
        motData = utilities.readMOTfile( ...
            fullfile(motFiles(motFileIdx).folder, ...
            motFiles(motFileIdx).name));

        % export mot data to csv
        exportTable_mot = struct2table(motData.Data);
        [~, orgFileName, ~] = fileparts(motFiles(motFileIdx).name);
        fileName = fullfile(motFiles(motFileIdx).folder, ...
            [orgFileName, '.csv']);
        writetable(exportTable_mot, fileName);
    end
    stoFiles = dir(fullfile(taskProcessor.analysisDir, '*.sto'));
    for stoFileIdx = 1:numel(stoFiles)
        if contains(stoFiles(stoFileIdx).name, 'walk')
            stoData = utilities.readSTOfile( ...
                fullfile(stoFiles(stoFileIdx).folder, ...
                stoFiles(stoFileIdx).name));
            % export sto data to csv
            exportTable_sto = struct2table(stoData.Data);
            [~, orgFileName, ~] = fileparts(stoFiles(stoFileIdx).name);
            fileName = fullfile(stoFiles(stoFileIdx).folder, ...
                [orgFileName, '.csv']);
            writetable(exportTable_sto, fileName);
        end
    end
    
    disp(['Finished with task ', task.taskType, ' ', task.repetitionId, ' for ' obj.subjectId]);
end