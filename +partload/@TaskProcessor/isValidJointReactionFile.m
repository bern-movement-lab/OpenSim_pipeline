function valid = isValidJointReactionFile(obj)
%ISVALIDJOINTREACTIONFILE Checks the validity of the joint reaction analysis output file.
%
%   This method checks the existence of a valid joint reaction analysis
%   output file and returns a logical true if a valid file exists and false
%   if not.
%
%   Checks that are executed:
%       - Check if file exists
%       - Check if data contains no unreadable elements (e.g. -nan(ind))
%       - Check if data contains no NaNs
%       - Check if data contains only numbers in the range of -10^9 to 10^9
%
%   +Package: partload
%   @Class: TaskProcessor
%
%
%   See also: partload.TaskProcessor,
%   tpartload.TaskProcessor.runJointReactionForceAnalysis
%   Copyright:      2020, Balgrist Campus
%   Author(s):      Lukas Connolly

if ~exist(obj.jrOutputFile, 'file')
    disp('-------------------');
    disp('File does not exist');
    disp('-------------------');
    valid = false;
    return;
end

%import values
imported = importdata(obj.jrOutputFile,'\t');
data = imported.data;

%assume valid to begin with
valid = true;

%check if unreadable data was present (numColumns will not match with
%header description)
if size(imported.textdata,2) ~= size(data,2)
    disp('-----------------------------');
    disp('Data contains unreadable data');
    disp('       e.g.: -nan(ind)       ');
    disp('-----------------------------');
    valid = false;
end

%check if data contains NANs
hasNans = any(isnan(data(:)));
if hasNans
    disp('------------------');
    disp('Data contains NaNs');
    disp('------------------');
    valid = false;
end

%check if any extremly large numbers are in
data = abs(data);
hasLargeNumbers = any(data(data>10e9));
if hasLargeNumbers
    disp('--------------------------------');
    disp('Data contains very large numbers');
    disp('--------------------------------');
    valid = false;
end

end
