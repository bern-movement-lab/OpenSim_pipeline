%% Init
worklocal = true;

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
    dataDir = fullfile(CEPHpath,'DATEN/FP/Partload/DataForMOLApp');
    % dataDir = 'P:\DATEN\FP\Partload\ViconDataPROC';
end

sessToSimulate = {'Walk15kg'};
subjectsToSimulate = {'PL09','PL10','PL11','PL12','PL13','PL14','PL15'};
subjectsToSimulate = {'PL11','PL12','PL13','PL14','PL15'};