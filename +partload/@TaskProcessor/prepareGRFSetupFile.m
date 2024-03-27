function obj = prepareGRFSetupFile(obj)
%PREPAREGRFSETUPFILE Prepare GRF Setup File for analysis.
%
%   This method manipulates the GRF Setup File Template with analysis
%   specific data.
%
%   Included tasks:
%   1. For each associated forceplate ID (left or right foot) an external
%   force container is created within the objects container of the
%   template. In case of left Forceplate IDs the external force will be
%   applied to calcn_l, else calcn_r.
%
%   2. The datafile reference is set to the ground reaction force (GRF)
%   input file of the analysis (obj.motFile).
%
%   3. The modified GRF Setup file is saved in the setupFiles directory
%   within the analysis directory.
%
%   +Package: partload
%   @Class: TaskProcessor
%
%   See also: partload.TaskProcessor, partload.TaskProcessor.prepareSetupFiles

%   Copyright:      2020, Balgrist Campus
%   Author(s):      Lukas Connolly
%                   Philippe Baehler (BFH/Uni Bern, 2024)

forcePlateIds = sort(horzcat(obj.leftForceplateIDs,obj.rightForceplateIDs));

xmlFile = xmlread(fullfile(fileparts(mfilename('fullpath')), 'Templates', 'GRF_setup.xml'));

for i=1:numel(forcePlateIds)
    
    % select based on side membership which body to apply force to
    if ismember(forcePlateIds(i), obj.leftForceplateIDs)
        side = 'calcn_l';
    elseif ismember(forcePlateIds(i), obj.rightForceplateIDs)
        side = 'calcn_r';
    else
        continue;
    end
    
    % create external load container
    externalForceNode = xmlFile.createElement('ExternalForce');
    externalForceNode.setAttribute('name', sprintf('external_force_%d', i));
    
    % create specific subnodes with corresponding comments
    externalForceNode.appendChild(xmlFile.createComment(...
        'Name of the body the force is applied to.'));
    newNode = xmlFile.createElement('applied_to_body');
    newNode.appendChild(xmlFile.createTextNode(side));
    externalForceNode.appendChild(newNode);
    
    externalForceNode.appendChild(xmlFile.createComment(...
        'Name of the body the force is expressed in (default is ground).'));
    newNode = xmlFile.createElement('force_expressed_in_body');
    newNode.appendChild(xmlFile.createTextNode('ground'));
    externalForceNode.appendChild(newNode);
    
    externalForceNode.appendChild(xmlFile.createComment(...
        'Name of the body the point is expressed in (default is ground).'));
    newNode = xmlFile.createElement('point_expressed_in_body');
    newNode.appendChild(xmlFile.createTextNode('ground'));
    externalForceNode.appendChild(newNode);
    
    externalForceNode.appendChild(xmlFile.createComment(...
        'Identifier (string) to locate the force to be applied in the data source.'));
    newNode = xmlFile.createElement('force_identifier');
    newNode.appendChild(xmlFile.createTextNode(sprintf('ground_force_%d_v', forcePlateIds(i))));
    externalForceNode.appendChild(newNode);
    
    externalForceNode.appendChild(xmlFile.createComment(...
        'Identifier (string) to locate the point to be applied in the data source.'));
    newNode = xmlFile.createElement('point_identifier');
    newNode.appendChild(xmlFile.createTextNode(sprintf('ground_force_%d_p', forcePlateIds(i))));
    externalForceNode.appendChild(newNode);
    
    externalForceNode.appendChild(xmlFile.createComment(...
        'Identifier (string) to locate the torque to be applied in the data source.'));
    newNode = xmlFile.createElement('torque_identifier');
    newNode.appendChild(xmlFile.createTextNode(sprintf('ground_moment_%d_', forcePlateIds(i))));
    externalForceNode.appendChild(newNode);
    
    externalForceNode.appendChild(xmlFile.createComment(...
        'Name of the data source (Storage) that will supply the force data.'));
    newNode = xmlFile.createElement('data_source_name');
    externalForceNode.appendChild(newNode);
    
    % add created external force container to objects container
    xmlFile.getElementsByTagName('objects').item(0).appendChild(externalForceNode);
end

% set reference to correct ressource datafile (newly created .mot file)
xmlFile.getElementsByTagName('datafile').item(0).getFirstChild.setNodeValue(obj.motFile);

xmlwrite(obj.xmlSetupGRF, xmlFile);

end
