subjects = struct;
subjectDir = dir(dataDir);
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