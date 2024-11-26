function obj = prepareTRCFile(obj)
%PREPARETRCFILE Prepares TRC file for scaling, converts from C3D format if necessary.
%
%   This method checks if the file specified by the trcStaticPath property
%   exists. If this criteria is not fullfilled the method checks for an
%   existing c3d file. If such a file exists, the method uses the mat2os
%   C3D adapter to convert the c3d file to trc, else the method errors.
%
%   +Package: partload
%   @Class: ModelBuilder
%
%
%   See also: partload.ModelBuilder, mat2os.utilities.C3DAdapter

%   Copyright:      2020, Balgrist Campus
%   Author(s):      Lukas Connolly
%                   Philippe Baehler (BFH / Uni Bern, 2024)

if exist(obj.trcStaticPath, 'file')
    return;
end

if ~exist(obj.c3dStaticPath, 'file')
    error('C3D Static file path not set, can not prepare TRC File.');
end

% prepare C3D Adapter
c3dAdapter = mat2os.utilities.C3DAdapter(...
    'c3dPath', obj.c3dStaticPath,...
    'outputDir', obj.modelDir,...
    'subjectId', obj.modelName,...
    'labRotation', obj.labRotation );

c3dAdapter = c3dAdapter.rotateData();

% if obj.alignC3dData
%     c3dAdapter = obj.alignC3DData( c3dAdapter );
% end

c3dAdapter.writeTRC();

t0 = c3dAdapter.markers.data.Time(1);
t1 = c3dAdapter.markers.data.Time(end);
obj.scalingTimeRange = [t0 t1];

end
