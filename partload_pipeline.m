%% partload pipeline

%% Init
close all;
clear all;
clc;
worklocal = true;

import org.opensim.modeling.* 
myMatlabLog = JavaLogSink();
Logger.addSink(myMatlabLog);

%% Load the project data into a subject
if isunix && ~ismac
    if worklocal
        disp('not yet handled')
    else
        CEPHpath = '/home/patric/mounts/research-PHY';
    end
elseif isunix && ismac
    if worklocal
        disp('not yet handled')
    else
        CEPHpath = '/Volumes/Research-PHY';
    end
else
    if worklocal
        CEPHpath = 'C:\localdata\PartloadDataForMOLApp';
    else
        CEPHpath = ['\\bfh.ch'];
    end
end

if worklocal
    dataDir = '/Users/jana/Documents/BME/Masterarbeit/partload/DataForOpenSim';
else
    dataDir = fullfile(CEPHpath,'DATEN/FP/Partload/DataForMOLApp');
    % dataDir = 'P:\DATEN\FP\Partload\ViconDataPROC';
end

sessToSimulate = {'Walk100'};
subjectsToSimulate = {'PL04'};
% nfiles = 1:2; % process only one measurement; comment out for all

subjects = struct;
subjectDir = dir(dataDir);
subjectCtr = 1;
for subjectIdx = 1:numel(subjectDir)
    subjectId = subjectDir(subjectIdx).name;
    if contains(subjectId, 'PL') && contains(subjectsToSimulate, subjectId)
        dirContent = dir(fullfile(subjectDir(subjectIdx).folder, subjectId));
        for dirContentIdx = 1:numel(dirContent)
            if dirContent(dirContentIdx).isdir && ~contains(dirContent(dirContentIdx).name, '.')
                if any(contains(sessToSimulate,dirContent(dirContentIdx).name))
                    files = dir(fullfile(dirContent(dirContentIdx).folder, ...
                        dirContent(dirContentIdx).name, '*.c3d'));
                    if ~isempty(files)
                        % subjectCtr = subjectCtr + 1;
                        subjects.(dirContent(dirContentIdx).name)(subjectCtr) = ...
                            partload.Subject('subjectId', subjectId);
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