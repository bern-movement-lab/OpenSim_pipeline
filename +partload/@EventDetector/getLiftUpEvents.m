function timeRange = getLiftUpEvents(obj)
%GETLIFTUPEVENTS Get start and endtime for liftUp events from kinematic data.
%
%   This method gets the start and end time for the task "liftUp" by
%   analysing the trajectory of the C7 spinous marker.
%   The start time is defined as the timepoint when the vertical velocity
%   of the C7 marker exceeds 5% of the overall maximal C7 upward vertical
%   velocity for the first time.
%   The end time is defined as the timepoint when the upward vertical
%   velocity of the C7 marker falls below the 5% of the maximal vertical
%   velocity for the first time after the before defined start time.
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
%   See also: tlsm.EventDetector, tlsm.EventDetector.getEventTimestamps

%   Copyright:      2020, Balgrist Campus
%   Author(s):      Lukas Connolly

threshold = 0.05;

requiredColumns = {'C7_Y', 'Time'};
for i=1:numel(requiredColumns)
    if ~ismember(requiredColumns{i}, obj.markerTable.Properties.VariableNames)
        error('No marker data for %s in c3dAdapter', requiredColumns{i});
    end
end

%get vertical displacement of C7 marker
c7y = obj.markerTable.C7_Y;

%get vertical velocity of C7 marker
c7yv = diff(c7y);
c7yv = [c7yv(1); c7yv]; %add one element to beginning to get num elements = num frames

%get time from C3D
time = obj.markerTable.Time;

%get maximum velocity and set threshold velocity from it
maxVelocity = max(c7yv);
thresholdVelocity = threshold * maxVelocity;

%find indices for start of event (first time C7 vertical velocity is larger
%than threshold) and end time (first time after start event when velocity
%is smaller than threshold)
startIX = find(c7yv>thresholdVelocity,1);
if isempty(startIX)
    startIX = 1;
end

endIX = find(time>time(startIX) & c7yv<thresholdVelocity,1);
if isempty(endIX)
    endIX = numel(time);
else
    endIX = endIX-1;
end

%get start time and end time for task
timeRange = [time(startIX) time(endIX)];

if(obj.savePlots)
    
    fig = figure;
    subplot(2,1,1);
    plot(time,c7y);
    hold all;
    plot(time(startIX),c7y(startIX),'>g', 'MarkerFaceColor', 'g');
    plot(time(endIX),c7y(endIX),'<r', 'MarkerFaceColor', 'r');
    title('Vertical Displacement C7');
    xlabel('time [s]');
    ylabel('displacement [mm]');
    
    subplot(2,1,2);
    plot(time,c7yv);
    hold all;
    plot(time(startIX),c7yv(startIX),'>g', 'MarkerFaceColor', 'g');
    plot(time(endIX),c7yv(endIX),'<r', 'MarkerFaceColor', 'r');
    title('Vertical Velocity C7');
    xlabel('time [s]');
    ylabel('velocity [mm/frame]');
    
    imgPath = fullfile(obj.c3dAdapter.outputDir, [obj.c3dAdapter.trialName '_EventDetector.png']);
    saveas(fig,imgPath);
    close(fig);
    
end

end
