%% partload pipeline


%% Init
close all;
clear all;
clc;

% addpath('C:\Users\blp7\LocalWorkSpace\partload\partload');

%% Load the project data into a subject

% dataDir = 'P:\LFE\G\Research-PHY\DATEN\FP\Partload\ViconDataPROC';

dataDir = 'P:\DATEN\FP\Partload\ViconDataPROC';

subjectDir = dir(dataDir);
subjectCtr = 0;
for subjectIdx = 1:numel(subjectDir)
    subjectId = subjectDir(subjectIdx).name;
    if contains(subjectId, 'PL')
        dirContent = dir(fullfile(subjectDir(subjectIdx).folder, subjectId));
        for dirContentIdx = 1:numel(dirContent)
            if dirContent(dirContentIdx).isdir && ~contains(dirContent(dirContentIdx).name, '.')
                files = dir(fullfile(dirContent(dirContentIdx).folder, dirContent(dirContentIdx).name, '*.c3d'));
                if ~isempty(files)
                    subjectCtr = subjectCtr + 1;
                    subject(subjectCtr) = partload.Subject('subjectId', subjectId);
                    for filesIdx = 1:numel(files)
                        if contains(files(filesIdx).name, 'static')
                            subject(subjectCtr).staticFilePath = fullfile(files(filesIdx).folder, files(filesIdx).name);
                            c3d = ezc3dRead(subject(subjectCtr).staticFilePath);
                            subject(subjectCtr).modelMass = c3d.parameters.PROCESSING.Bodymass.DATA; % mass in kg
                            subject(subjectCtr).modelHeight = c3d.parameters.PROCESSING.Height.DATA/1000; % height in m
                        elseif contains(files(filesIdx).name, 'walk')
                            sessionName = erase(files(filesIdx).name, [subjectId, '_']);
                            sessionName = erase(sessionName, '.c3d');
                            taskFilePath = fullfile(files(filesIdx).folder, files(filesIdx).name);
                            subject(subjectCtr) = subject(subjectCtr).addTask(partload.Task('walk', sessionName, taskFilePath));
                        end%if
                    end%for
                end%if
            end%for
        end%for
    end%if
end%for


%% generate and scale a model
for idx = 2:numel(subject)
    if ~exist(subject(idx).modelPath, 'file')
        subject(idx).buildModel;
    end%if

    % Perform inverse kinematics and inverse dynamics simulation
    subject(idx).simulateTasks();
    
end%for

%% create plot to IK

exportVariables = ["time", "hip_adduction_l", "hip_adduction_r",...
    "hip_flexion_l", "hip_flexion_r", "hip_rotation_l", "hip_rotation_r",...
    "knee_angle_l", "knee_angle_r", "ankle_angle_l", "ankle_angle_r"];

exportVariables_id = ["time", "hip_flexion_r_moment", "hip_adduction_r_moment",...
    "hip_rotation_r_moment", "hip_flexion_l_moment", "hip_adduction_l_moment",...
    "hip_rotation_l_moment", "knee_angle_r_moment", "knee_angle_l_moment",...
    "ankle_angle_r_moment", "ankle_angle_l_moment"];

for subjectIdx = 1:numel(subject)
    folders = dir(fullfile(subject(subjectIdx).outputDir, subject(subjectIdx).subjectId));
    for folderIdx = 1:numel(folders)
        if strcmp(folders(folderIdx).name, 'walk')
            subfolder = dir(fullfile(subject(subjectIdx).outputDir, subject(subjectIdx).subjectId, folders(folderIdx).name));
            for subfolderIdx = 1:numel(subfolder)
                if ~contains(subfolder(subfolderIdx).name, '.')
                    exportTable_ik = table();
                    exportTable_id = table();
%                     figure

                    ikFiles = dir(fullfile(subject(subjectIdx).outputDir, subject(subjectIdx).subjectId, folders(folderIdx).name, subfolder(subfolderIdx).name, '*.mot'));
                    idFiles = dir(fullfile(subject(subjectIdx).outputDir, subject(subjectIdx).subjectId, folders(folderIdx).name, subfolder(subfolderIdx).name, '*.sto'));
                    
                    for ikfileIdx = 1:numel(ikFiles)
                        ikdata = utilities.readMOTfile(fullfile(ikFiles(ikfileIdx).folder, ikFiles(ikfileIdx).name));
%                         subplot(2,1,1)
%                         plot(ikdata.Data.time, ikdata.Data.hip_flexion_r),
%                         hold on;
%                         plot(ikdata.Data.time, ikdata.Data.hip_flexion_l);
%                         title('hip')
%                         legend('right', 'left')
% 
%                         subplot(2,1,2)
%                         plot(ikdata.Data.time, ikdata.Data.knee_angle_r);
%                         hold on;
%                         plot(ikdata.Data.time, ikdata.Data.knee_angle_l);
%                         title('knee')
%                         legend('right', 'left')
                        
                        % export mot data in csv
                        for idxExpEntry = 1:numel(exportVariables)
                            exportTable_ik.(exportVariables{idxExpEntry}) = ikdata.Data.(exportVariables{idxExpEntry})';
                        end%for
                        
                        [~, orgFileName, ~] = fileparts(ikFiles(ikfileIdx).name);
                        fileName = fullfile(ikFiles(ikfileIdx).folder, [orgFileName, '.csv']);
                        writetable(exportTable_ik, fileName);
                    end%for
                    
                    for idfileIdx = 1:numel(idFiles)
                        if contains(idFiles(idfileIdx).name, 'walk')
                            iddata = utilities.readSTOfile(fullfile(idFiles(idfileIdx).folder, idFiles(idfileIdx).name));

                            for idxExpEntry = 1:numel(exportVariables_id)
                                exportTable_id.(exportVariables_id{idxExpEntry}) = iddata.Data.(exportVariables_id{idxExpEntry})';
                            end%for
                            [~, orgFileName, ~] = fileparts(idFiles(idfileIdx).name);
                            fileName = fullfile(idFiles(idfileIdx).folder, [orgFileName, '.csv']);
                            writetable(exportTable_id, fileName);
                        end%if
                        
                    end%for
%                     sgtitle(['Subject: ' subject(1).subjectId, ', Trial: ', subfolder(subfolderIdx).name])

                end%if
            end%for
        end%if
    end%for
end%for





%% extract events for ID



%% Perform inverse dynamics



%% Calculate partial forces and perform static optimization

