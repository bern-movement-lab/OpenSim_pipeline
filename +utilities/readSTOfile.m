function data = readSTOfile(sto_file)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

    % open sto file
    fid = fopen(sto_file);
    % check if opening was succesful
    if fid == -1; error('STO file not loaded'); end
    
    isHeader = 1;
    headerLineNr = 1;
    dataLineNr = 1;
    data = struct('Header', [], 'Data', []);
    while ~feof(fid)
        currentLine = fgetl(fid);
        if ~isempty(currentLine)
            if isHeader
                headerData = strrep(currentLine, '=', ' ');
                headerData = strsplit(headerData);
                if contains(headerData{1}, 'endheader')
                    isHeader = 0;
                elseif contains(headerData{1}, '?xml')
                    data.Header.(headerData{2}) = headerData{3};
                else
                    if length(headerData) == 1 
                        data.Header.(headerData{1}) = [];
                    else 
                        headerData{1} = strrep(headerData{1}, '<', '');
                        if isempty(headerData{1})
                            headerData{1} = 'placeholder';
                        end%if
                        data.Header.(headerData{1}) = headerData{2};
                    end%if
                    headerLineNr = headerLineNr + 1;
                end%if
            else
                if contains(currentLine, 'time')
                    lineNames = strsplit(currentLine);
                    for idx = 1:length(lineNames)
                        data.Data.(lineNames{idx})(dataLineNr) = 0;
                    end%for
                else
                    values = strsplit(currentLine);
                    for idx = 2:length(values)
                        data.Data.(lineNames{idx-1})(dataLineNr) = str2double(values{idx});
                    end%for
                    dataLineNr = dataLineNr + 1;
                end%if
            end%if
        end%if
    end%while
end

