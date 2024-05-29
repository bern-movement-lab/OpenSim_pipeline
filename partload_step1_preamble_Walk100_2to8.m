%% Init
worklocal = false;

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
    dataDir = CEPHpath;
else
    dataDir = fullfile(CEPHpath,'DATEN/FP/Partload/DataForOpenSim');
    % dataDir = 'P:\DATEN\FP\Partload\ViconDataPROC';
end

sessToSimulate = {'Walk100'};
% subjectsToSimulate = {'PL02','PL03','PL04','PL05','PL06','PL07','PL08'};
subjectsToSimulate = {'PL08'};