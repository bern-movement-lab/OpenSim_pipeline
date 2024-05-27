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