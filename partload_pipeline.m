%% partload pipeline


%% Init
close all;
clear all;
clc;

% addpath('C:\Users\blp7\LocalWorkSpace\partload\partload');

%% Load the project data into a subject
if isunix && ~ismac
    CEPHpath = '/home/patric/mounts/research-PHY';
else
    CEPHpath = 'P:\LFE\G\Research-PHY';
end

dataDir = fullfile(CEPHpath,'DATEN/FP/Partload/ViconDataPROC');
% dataDir = 'P:\DATEN\FP\Partload\ViconDataPROC';

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
                            % c3d = ezc3dRead(subject(subjectCtr).staticFilePath);
                            % subject(subjectCtr).modelMass = c3d.parameters.PROCESSING.Bodymass.DATA; % mass in kg
                            % subject(subjectCtr).modelHeight = c3d.parameters.PROCESSING.Height.DATA/1000; % height in m
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

%% 

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

                    motFiles = dir(fullfile(subject(subjectIdx).outputDir, subject(subjectIdx).subjectId, folders(folderIdx).name, subfolder(subfolderIdx).name, '*.mot'));
                    stoFiles = dir(fullfile(subject(subjectIdx).outputDir, subject(subjectIdx).subjectId, folders(folderIdx).name, subfolder(subfolderIdx).name, '*.sto'));
                    
                    for motFileIdx = 1:numel(motFiles)
                        motData = utilities.readMOTfile(fullfile(motFiles(motFileIdx).folder, motFiles(motFileIdx).name));
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
                            exportTable_mot.(exportVariables{idxExpEntry}) = motData.Data.(exportVariables{idxExpEntry})';
                        end%for
                        
                        [~, orgFileName, ~] = fileparts(motFiles(motFileIdx).name);
                        fileName = fullfile(motFiles(motFileIdx).folder, [orgFileName, '.csv']);
                        writetable(exportTable_mot, fileName);
                    end%for
                    
                    for stoFileIdx = 1:numel(stoFiles)
                        if contains(stoFiles(stoFileIdx).name, 'walk')
                            stoData = utilities.readSTOfile(fullfile(stoFiles(stoFileIdx).folder, stoFiles(stoFileIdx).name));
                            % export sto data in csv
                            exportTable_sto = struct2table(stoData.Data);
                            [~, orgFileName, ~] = fileparts(stoFiles(stoFileIdx).name);
                            fileName = fullfile(stoFiles(stoFileIdx).folder, [orgFileName, '.csv']);
                            writetable(exportTable_sto, fileName);
                        end%if
                    end%for
                end%if
            end%for
        end%if
    end%for
end%for





%% extract events for ID



%% Perform inverse dynamics



%% Calculate partial forces and perform static optimization

