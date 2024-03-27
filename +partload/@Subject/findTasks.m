function logicalIndices = findTasks(obj, taskType, repetitionId)
%FINDTASKS Find tasks in tasks property by task type and repetition id.
%
%   This method searches the tasks property with partload.Task objects and
%   returns a logical array, which allows selecting tasks by taskType and
%   optionally also by repetitionId.
%
%   logicalIndices = obj.findTasks(taskType)
%
%   Required Input Parameters:
%   taskType      - [1x1 string] Task type for tasks which should be found.
%
%   logicalIndices = obj.findTasks(taskType, repetitionId)
%
%   Optional Input Parameters:
%   repetitionId  - [1x1 string] Id of the repetition of th etask which
%                           should be found.
%
%   Return Values:
%   logicalIndice - [Nx1 logical] Logical value for each task in the tasks
%                           property. true for values which fullfill search
%                           criteria. False for all other tasks.
%
%   +Package: partload
%   @Class: Subject
%
%   Quality Assurance
%   -----------------
%   Classification: [X] data processing  [ ] non-data processing
%   Testing:        [ ] functional test  [ ] runnable example    [ ] manual
%   Unit test:      -
%
%   See also: partload.Subject, partload.Task

%   Copyright:      2020, Balgrist Campus
%   Author(s):      Lukas Connolly

if nargin < 3
    logicalIndices = arrayfun(@(o)strcmp(o.taskType, taskType), obj.tasks);
else
    logicalIndices = arrayfun(@(o)strcmp(o.taskType, taskType) && strcmp(o.repetitionId, repetitionId), obj.tasks);
end

end