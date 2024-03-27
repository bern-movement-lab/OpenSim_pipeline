function timeRange = getWalkEvents(obj)
%GETWALKEVENTS Get start and endtime for walk events from the c3d file.
%
%   This method gets the start and end time for the task "walk" by
%   extracting the events set in the vicon post-processing for the heel
%   strike and foot off.
%   The start time is defined as heel strike of the left foot.
%   The end time is defined as the timepoint when the toe off of the right
%   foot occurs.
%
%   +Package: tlsm
%   @Class: EventDetector
%
%
%   See also: tlsm.EventDetector, tlsm.EventDetector.getEventTimestamps

%   Copyright:      2024, Bern Movement Lab
%   Author(s):      Philippe Baehler

gaitCycleDurationThreshold = 4; % seconds
window = 100; % samples

% read events from c3d file
[c3d, all_fp] = ezc3dRead(obj.c3dAdapter.c3dPath);

forceThreshold = 0.2*c3d.parameters.PROCESSING.Bodymass.DATA*9.81; %N      -> threshold to check if participant steps on force plate after the specified event

% extract relevant information from c3d struct
eventTimes = c3d.parameters.EVENT.TIMES.DATA(2,:);
eventLabels = c3d.parameters.EVENT.LABELS.DATA;
eventContext = c3d.parameters.EVENT.CONTEXTS.DATA;
eventDescription = c3d.parameters.EVENT.DESCRIPTIONS.DATA;

numEvents = length(eventLabels);

% loop through events and 
for eventIdx = 1:numEvents
    if strcmp(eventLabels{eventIdx}, 'Foot Strike') && strcmp(eventContext{eventIdx}, 'Left')
        % check forceplate data after event. Mean of recorded forces should
        % exceed the threshold otherwise the event chekced is not the one
        % where the participant steps on the forceplate
        eventIndex = round(eventTimes(eventIdx),2) * c3d.header.points.frameRate;
        if mean(all_fp(2).force(3,eventIndex:eventIndex+window) > forceThreshold)
            startTime = eventTimes(eventIdx);
        end%if
    elseif strcmp(eventLabels{eventIdx}, 'Foot Off') && strcmp(eventContext{eventIdx}, 'Right')
        eventIndex = round(eventTimes(eventIdx),2) * c3d.header.points.frameRate;
        if (mean(all_fp(1).force(3,eventIndex:eventIndex + window)) < forceThreshold) && (mean(all_fp(1).force(3,eventIndex-window:eventIndex)) < forceThreshold)
            endTime = eventTimes(eventIdx);
        end%if
    end%if
end%for

if (endTime - startTime) > gaitCycleDurationThreshold
    disp(['Cycle duration is larger than expected. Cycle duration: ', endTime - startTime, 'seconds']);
end%if

timeRange = [startTime, endTime];

end%function