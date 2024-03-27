function timeRange = getSitDownEvents(obj)
%GETSITDOWNEVENTS Get start and endtime for sitDown events from kinematic data.
%
%   This method gets the start and end time for the task "sitDown" by
%   analysing the trajectory of the SACR (sacrum) marker.
%   The start time is defined as the timepoint when the vertical velocity
%   of the SACR marker exceeds 5% of the overall maximal SACR downward
%   vertical velocity for the first time.
%   The end time is defined as the timepoint when the backward sagital
%   velocity of the SACR marker falls below the 5% of the maximal sagital
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

requiredColumns = {'STRN_X', 'STRN_Y' 'Time'};
for i=1:numel(requiredColumns)
    if ~ismember(requiredColumns{i}, obj.markerTable.Properties.VariableNames)
        error('No marker data for %s in c3dAdapter', requiredColumns{i});
    end
end

% get marker displacements
strnX = obj.markerTable.STRN_X;
strnY = obj.markerTable.STRN_Y;

% get marker velocities
vStrnX = diff(strnX);
vStrnX = [vStrnX(1); vStrnX]; %add one element to beginning to get num elements = num frames

vStrnY = diff(strnY);
vStrnY = [vStrnY(1); vStrnY]; %add one element to beginning to get num elements = num frames

% get time data
time = obj.markerTable.Time;

% get event start depending on threshold vertical velocity
minVerticalVelocity = min(vStrnY);
thresholdVerticalVelocity = threshold * minVerticalVelocity;

startIX = find(vStrnY<thresholdVerticalVelocity,1);
if isempty(startIX)
    startIX = 1;
end

% get event end depending on threshold sagital velocity
[minSagitalVelocity, minSagitalVelocityIX] = min(vStrnX);
thresholdSagitalVelocity = threshold * minSagitalVelocity;

endIX = find(time>time(minSagitalVelocityIX) & vStrnX>thresholdSagitalVelocity,1);
if isempty(endIX)
    endIX = numel(time);
else
    endIX = endIX-1;
end

%get start time and end time for task
timeRange = [time(startIX) time(endIX)];

if(obj.savePlots)
    
    fig = figure;
    subplot(2,2,1);
    plot(time,strnY);
    hold all;
    plot(time(startIX),strnY(startIX),'>g', 'MarkerFaceColor', 'g');
    plot(time(endIX),strnY(endIX),'<r', 'MarkerFaceColor', 'r');
    title('Vertical Displacement STRN');
    xlabel('time [s]');
    ylabel('displacement [mm]');
    
    subplot(2,2,2);
    plot(time,strnX);
    hold all;
    plot(time(startIX),strnX(startIX),'>g', 'MarkerFaceColor', 'g');
    plot(time(endIX),strnX(endIX),'<r', 'MarkerFaceColor', 'r');
    title('Sagital Displacement STRN');
    xlabel('time [s]');
    ylabel('displacement [mm]');
    
    subplot(2,2,3);
    plot(time,vStrnY);
    hold all;
    plot(time(startIX),vStrnY(startIX),'>g', 'MarkerFaceColor', 'g');
    plot(time(endIX),vStrnY(endIX),'<r', 'MarkerFaceColor', 'r');
    title('Vertical Velocity STRN');
    xlabel('time [s]');
    ylabel('velocity [mm/frame]');
    
    subplot(2,2,4);
    plot(time,vStrnX);
    hold all;
    plot(time(startIX),vStrnX(startIX),'>g', 'MarkerFaceColor', 'g');
    plot(time(endIX),vStrnX(endIX),'<r', 'MarkerFaceColor', 'r');
    title('Sagital Velocity STRN');
    xlabel('time [s]');
    ylabel('velocity [mm/frame]');
    
    imgPath = fullfile(obj.c3dAdapter.outputDir, [obj.c3dAdapter.trialName '_EventDetector.png']);
    saveas(fig,imgPath);
    close(fig);
    
end

end
