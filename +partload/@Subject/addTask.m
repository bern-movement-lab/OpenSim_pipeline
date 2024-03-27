function obj = addTask(obj, task)
%ADDTASK Add single task to tasks property.
%
%   This method adds a single instance of a partload.Task object to the 
%   tasks property of the subject. If a task with same taskType and 
%   repetitionId already exists, the previous version will be overwritten.
%
%   obj = obj.addTask(task)
%
%   Required Input Parameters:
%   task     - [1x1 partload.Task] Instance of tlsm.Task object to be appended
%                           to the subjects tasks property.
%
%   Return Values:
%   obj      - [1x1 partload.Subject] Instance of the subject object with the
%                           modified tasks property.
%
%   +Package: partload
%   @Class: Subject
%
%   See also: partload.Subject, partload.Task

%   Copyright:      2020, Balgrist Campus
%   Author(s):      Lukas Connolly
%                   Philippe Baehler (BFH / Uni Bern, 2024)

validateattributes(task,{'partload.Task'},{'scalar'});

if isempty(obj.tasks)
    obj.tasks = task;
else
    % check if task and repetition already exists and remove it when this
    % would be the case
    if any(obj.findTasks(task.taskType, task.repetitionId))
        obj = obj.removeTasks(task.taskType, task.repetitionId);
    end
    % append new task to tasks
    obj.tasks = [obj.tasks; task];
end