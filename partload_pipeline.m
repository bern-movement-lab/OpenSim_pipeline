%% partload_pipeline
% partload_pipeline - Complete analysis pipeline for processing subject data.
%
%   This script loads project configuration and subject data, builds
%   subject-specific OpenSim models, and runs inverse kinematics (IK)
%   and inverse dynamics (ID) simulations. The results are exported
%   to .csv files for further analysis.
%
%   Workflow:
%       1. adapt the configuration file for your needs
%       2. Run this script
%
%   Configuration:
%   The pipeline relies on an XML configuration file defining paths,
%   sessions, and subjects to simulate.
%
%   Dependencies:
%       - OpenSim (Java interface)
%       - ezc3d (C3D file reader)
%       - tlsm   (Model building and task simulation)
%       - mat2os (MATLAB to OpenSim interface)
%
%   Input:
%       - Motion capture data in .c3d format
%
%   Output:
%       - Subject-specific OpenSim models (.osim)
%       - Inverse dynamics results (.csv, .sto, .log)
%       - Inverse kinematics results (.csv, .mot, .log)
%       - Joint Reaction Analysis results (.csv, .sto, .log)
%       - Static optimization results (.csv, .sto)
%       - Exported .csv files for analysis
%
%
%   Author(s):      Philippe Bähler (BFH/Uni Bern, 2024),
%                   Jana Ender (BFH/ETH, 2024),
%                   Michael Streit (BFH/Uni Bern, 2025)


%% Init
close all;
clear all;
clc;      


import org.opensim.modeling.*      % Import OpenSim Libraries
myMatlabLog = JavaLogSink();
Logger.addSink(myMatlabLog)


%% Load the project data into a subject

% adjust the configuartion file for your task
cfg = readstruct('partload_pipeline_configuration.xml');
cfg = convertContainedStringsToChars(cfg);

if ~exist(cfg.paths.inputPath)
    error("Input Path does not exist")
end

addpath(cfg.dependencies.ezc3d);
addpath(cfg.dependencies.tlsm);
addpath(cfg.dependencies.mat2os);

sessToSimulate = strtrim(strsplit(cfg.sessions, ','));
subjectsToSimulate = strtrim(strsplit(cfg.subjects, ','));
% nfiles = 1:2; % process only one measurement; comment out for all

subjects = struct;
subjectDir = dir(cfg.paths.inputPath);
subjectCtr = 1;
for subjectIdx = 1:numel(subjectDir)
    subjectId = subjectDir(subjectIdx).name;
    if contains(subjectId, 'PL') && any(contains(subjectsToSimulate, subjectId))
        dirContent = dir(fullfile(subjectDir(subjectIdx).folder, subjectId));
        for dirContentIdx = 1:numel(dirContent)
            if dirContent(dirContentIdx).isdir && ~contains(dirContent(dirContentIdx).name, '.')
                if any(contains(sessToSimulate,dirContent(dirContentIdx).name))
                    files = dir(fullfile(dirContent(dirContentIdx).folder, ...
                        dirContent(dirContentIdx).name, '*.c3d'));
                    if ~isempty(files)
                        % subjectCtr = subjectCtr + 1;
                        subjects.(dirContent(dirContentIdx).name)(subjectCtr) = ...
                            partload.Subject('subjectId', subjectId, 'outputDir', cfg.paths.outputDir);
                        nfiles = 1:numel(files);
                        for filesIdx = nfiles
                            if contains(files(filesIdx).name, 'static')
                                subjects.(dirContent(dirContentIdx).name)(subjectCtr).staticFilePath = fullfile(...
                                    files(filesIdx).folder, files(filesIdx).name);
                                c3d = ezc3dRead(subjects.(dirContent(dirContentIdx).name)(subjectCtr).staticFilePath);
                                subjects.(dirContent(dirContentIdx).name)(subjectCtr).modelMass = ...
                                    c3d.parameters.PROCESSING.Bodymass.DATA; % mass in kg
                                subjects.(dirContent(dirContentIdx).name)(subjectCtr).modelHeight = ...
                                    c3d.parameters.PROCESSING.Height.DATA/1000; % height in m
                            elseif contains(files(filesIdx).name, 'walk')
                                sessionName = erase(files(filesIdx).name, [subjectId, '_']);
                                sessionName = erase(sessionName, '.c3d');
                                taskFilePath = fullfile(files(filesIdx).folder, files(filesIdx).name);
                                subjects.(dirContent(dirContentIdx).name)(subjectCtr) = ...
                                    subjects.(dirContent(dirContentIdx).name)(subjectCtr).addTask(...
                                        partload.Task('walk', sessionName, taskFilePath));
                            end%if
                        end%for
                    end%if
                end%if
            end%for
        end%for
        subjectCtr = subjectCtr + 1;
    end%if
end%for

%% generate and scale a model
condflds = fields(subjects);
for i = 1:numel(condflds)
    for j = 1:numel(subjects.(condflds{i}))
        if ~exist(subjects.(condflds{i})(j).modelPath, 'file')
            subjects.(condflds{i})(j).buildModel;
        end%if

        % Perform inverse kinematics and inverse dynamics simulation
        subjects.(condflds{i})(j).simulateTasks();
    end%for
end%for

%% 

exportVariables = ["time", "hip_adduction_l", "hip_adduction_r",...
    "hip_flexion_l", "hip_flexion_r", "hip_rotation_l", "hip_rotation_r",...
    "knee_angle_l", "knee_angle_r", "ankle_angle_l", "ankle_angle_r"];

exportVariables_id = ["time", "hip_flexion_r_moment", "hip_adduction_r_moment",...
    "hip_rotation_r_moment", "hip_flexion_l_moment", "hip_adduction_l_moment",...
    "hip_rotation_l_moment", "knee_angle_r_moment", "knee_angle_l_moment",...
    "ankle_angle_r_moment", "ankle_angle_l_moment"];

for condIdx = 1:numel(condflds)
    for subjectIdx = 1:numel(subjects.(condflds{condIdx}))
        folders = dir(fullfile(subjects.(condflds{condIdx})(subjectIdx).outputDir, ...
            subjects.(condflds{condIdx})(subjectIdx).subjectId));
        for folderIdx = 1:numel(folders)
            if strcmp(folders(folderIdx).name, 'walk')
                subfolder = dir(fullfile(subjects.(condflds{condIdx})(subjectIdx).outputDir, ...
                    subjects.(condflds{condIdx})(subjectIdx).subjectId, folders(folderIdx).name));
                for subfolderIdx = 1:numel(subfolder)
                    if ~contains(subfolder(subfolderIdx).name, '.')
                        exportTable_ik = table();
                        exportTable_id = table();
                        %                     figure

                        motFiles = dir(fullfile(subjects.(condflds{condIdx})(subjectIdx).outputDir, ...
                            subjects.(condflds{condIdx})(subjectIdx).subjectId, folders(folderIdx).name, ...
                            subfolder(subfolderIdx).name, '*.mot'));
                        stoFiles = dir(fullfile(subjects.(condflds{condIdx})(subjectIdx).outputDir, ...
                            subjects.(condflds{condIdx})(subjectIdx).subjectId, folders(folderIdx).name, ...
                            subfolder(subfolderIdx).name, '*.sto'));

                        for motFileIdx = 1:numel(motFiles)
                            motData = utilities.readMOTfile( ...
                                fullfile(motFiles(motFileIdx).folder, ...
                                motFiles(motFileIdx).name));
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

                            % export mot data to csv
                            exportTable_mot = struct2table(motData.Data);
                            [~, orgFileName, ~] = fileparts(motFiles(motFileIdx).name);
                            fileName = fullfile(motFiles(motFileIdx).folder, ...
                                [orgFileName, '.csv']);
                            writetable(exportTable_mot, fileName);
                        end%for

                        for stoFileIdx = 1:numel(stoFiles)
                            if contains(stoFiles(stoFileIdx).name, 'walk')
                                stoData = utilities.readSTOfile( ...
                                    fullfile(stoFiles(stoFileIdx).folder, ...
                                    stoFiles(stoFileIdx).name));
                                % export sto data to csv
                                exportTable_sto = struct2table(stoData.Data);
                                if contains(stoFiles(stoFileIdx).name, 'activation') % rename columns of muscle activation data
                                    columnNames = exportTable_sto.Properties.VariableNames;
                                    columnNames(2:end) = strcat(columnNames(2:end), '_activation');
                                    exportTable_sto.Properties.VariableNames = columnNames;
                                end
                                [~, orgFileName, ~] = fileparts(stoFiles(stoFileIdx).name);
                                fileName = fullfile(stoFiles(stoFileIdx).folder, ...
                                    [orgFileName, '.csv']);
                                writetable(exportTable_sto, fileName);
                            end%if
                        end%for
                    end%if
                end%for
            end%if
        end%for
    end%for
end%for