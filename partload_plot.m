close all;
clear all;
clc;

%% Load data from matlab-output

baseFolder = '/Users/jana/matlab-output/partload-opensim';

% Get all subject folders
subjects_output = dir(baseFolder);
subjects_output = subjects_output([subjects_output.isdir] & ~startsWith({subjects_output.name}, '.'));  % Filter directories

% Initialize cell arrays to store loaded data
allMatFiles = {};
allCsvFiles = {};

% Loop through each subject
for i = 1:length(subjects_output)
    subjectFolder = fullfile(baseFolder, subjects_output(i).name, 'walk');
    
    % Get all walking session folders for this subject (e.g., 'walk100_03', 'walk100_04', ...)
    sessions_output = dir(subjectFolder);
    sessions_output = sessions_output([sessions_output.isdir] & ~startsWith({sessions_output.name}, '.'));  % Filter directories
    
    % Loop through each walking session
    for j = 1:length(sessions_output)
        sessionFolder = fullfile(subjectFolder, sessions_output(j).name);
        
        % Load the .mat file from the 'input_files' folder
        inputFilesFolder = fullfile(sessionFolder, 'inputFiles');
        matFiles = dir(fullfile(inputFilesFolder, '*.mat'));
        eventData = load(fullfile(inputFilesFolder, matFiles.name));
            if isfield(eventData, 'struct') && isfield(eventData.struct, 'events')
                events = eventData.struct.events;
                allEvents(j) = events;
            end%if
        
        % Load the CSV file from the session folder
        csvFiles = dir(fullfile(sessionFolder, '*_InverseDynamics*.csv'));
        csvFilePath = fullfile(sessionFolder, csvFiles.name);
        csvData = readtable(csvFilePath);
        allCsvFiles{j} = csvData;
    end%for
end%for


%% Plot results

% Initialize a figure for the plot
figure;
hold on;  % To plot multiple trials on the same figure
rightFootColor = 'g';
leftFootColor = 'r';
lineWidth = 2;

% Loop through each gait trial
for trial = 1:size(sessions_output,1)
    csvData = allCsvFiles{trial};

    parameter_r = csvData.knee_angle_r_moment;
    parameter_l = csvData.knee_angle_l_moment;

    parameter_r = parameter_r/75.8;
    parameter_l = parameter_l/75.8;

    eventData = allEvents(trial);
    footStrike_Right = [eventData.Right_Foot_Strike];
    footStrike_Left = [eventData.Left_Foot_Strike];

    startTime_r = footStrike_Right(1);  
    endTime_r = footStrike_Right(2); 
    startTime_l = footStrike_Left(1);
    endTime_l = footStrike_Left(2);
    
    % Find the corresponding time indices in the CSV data
    time = csvData.time;
    gaitCycleIndices_r = (time >= startTime_r) & (time <= endTime_r);
    gaitCycleIndices_l = (time >= startTime_l) & (time <= endTime_l);

    parameterGaitCycle_r = parameter_r(gaitCycleIndices_r);
    parameterGaitCycle_l = parameter_l(gaitCycleIndices_l);
    timeGaitCycle_r = time(gaitCycleIndices_r);
    timeGaitCycle_l = time(gaitCycleIndices_l);
    
    % Normalize the time for the gait cycle to percentage (0-100%)
    timeGaitCycleNormalized_r = (timeGaitCycle_r - timeGaitCycle_r(1)) / (timeGaitCycle_r(end) - timeGaitCycle_r(1)) * 100;
    timeGaitCycleNormalized_l = (timeGaitCycle_l - timeGaitCycle_l(1)) / (timeGaitCycle_l(end) - timeGaitCycle_l(1)) * 100;
    
    p1 = plot(timeGaitCycleNormalized_r, parameterGaitCycle_r, 'g', 'LineWidth', lineWidth); % Right foot
    p2 = plot(timeGaitCycleNormalized_l, parameterGaitCycle_l, 'r', 'LineWidth', lineWidth); % Left foot

end

% Add labels and legend
xlabel('Gait Cycle (%)');
ylabel('Knee angle moment (Nm)');
title('Knee Angle Moment Across Gait Cycles');
legend([p1; p2], {'Right Foot', 'Left Foot'}, 'Location', 'best');
hold off;
