function timeRange = getEventTimestamps(obj)
%GETEVENTTIMESTAMPS Get start and endtime for set task from set c3dAdapter.
%
%   This method checks if the c3dAdapter and task properties are set and
%   sets the timeRange if not set, before calling the task specific method
%   to get start and endtime of the task.
%
%   +Package: tlsm
%   @Class: EventDetector
%
%   Quality Assurance
%   -----------------
%   Classification: [X] data processing  [ ] non-data processing
%   Testing:        [ ] functional test  [ ] runnable example    [ ] manual
%   Unit test:      -
%
%   See also: tlsm.EventDetector, tlsm.TaskProcessor.prepareInputFiles

%   Copyright:      2020, Balgrist Campus
%   Author(s):      Lukas Connolly

if isempty(obj.c3dAdapter) || isempty(obj.task)
    error('The property c3dAdapter and task must be set!');
end

if isempty(obj.timeRange)
    warning('The property timeRange is not set, the EventDetector will start at the first frame of the C3DFile');
    obj.timeRange = [0 Inf];
end

timeRange = obj.(['get' upper(obj.task(1)) obj.task(2:end) 'Events']);

end
