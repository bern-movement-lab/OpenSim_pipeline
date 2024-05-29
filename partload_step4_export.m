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