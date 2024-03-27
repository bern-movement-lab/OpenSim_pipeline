function obj = removeTasks(obj, taskType, repetitionId)
%REMOVETASKS Remove tasks in tasks property by task type and repetition id.
%
%   This method searches the tasks property with partload.Task objects and
%   removes all tasks fullfilling the search criteria. The search criteria
%   can either only be a taskType or a combination of taskType and
%   repetitionId.
%
%   obj = obj.removeTasks(taskType)
%
%   Required Input Parameters:
%   taskType      - [1x1 string] Task type for tasks which should be removed.
%
%   obj = obj.removeTasks(taskType, repetitionId)
%
%   Optional Input Parameters:
%   repetitionId  - [1x1 string] Id of the repetition of the task which
%                           should be removed.
%
%   Return Values:
%   obj      - [1x1 tlsm.Subject] Instance of the subject object with the
%                           modified tasks property.
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
%   See also: tlsm.Subject, tlsm.Task, tlsm.Subject.addTask,
%   tlsm.Subject.findTasks

%   Copyright:      2020, Balgrist Campus
%   Author(s):      Lukas Connolly
%                   Philippe Baehler (BFH / Uni Bern, 2024)

if nargin < 3
    logicalIndices = obj.findTasks(taskType);
    if ~any(logicalIndices)
        warning('Could not remove tasks with type "%s" because no such task was found', taskType);
    end
else
    logicalIndices = obj.findTasks(taskType, repetitionId);
    if ~any(logicalIndices)
        warning('Could not remove task with type "%s" and repetitionId "%s" because no such task was found', taskType, repetitionId);
    end
end

obj.tasks = obj.tasks(~logicalIndices);

end
