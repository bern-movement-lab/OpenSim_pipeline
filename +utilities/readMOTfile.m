function data = readMOTfile(mot_file)
    % open mot file
    fid = fopen(mot_file);
    % check if opening was sucesful
    if fid == -1
        error('MOT file not loaded');
    end
    
    isHeader = 1;
    headerLineNr = 1;
    dataLineNr = 1;
    
    data = struct('Header', [], 'Data', []);
    while ~feof(fid)
        currentLine = fgetl(fid);
        if ~isempty(currentLine)
            if isHeader 
                headerData = strsplit(currentLine);
                convData = erase(headerData{1}, '=');
                data.Header.(convData) = 0;
                headerLineNr = headerLineNr + 1;
            else
                if contains(currentLine, 'time')
                    lineNames = strsplit(currentLine);
                    for idx = 1:length(lineNames)
                        data.Data.(lineNames{idx})(1) = 0;
                    end%for
                else
                    values = strsplit(currentLine);
                    for idx = 2:length(values)
                        data.Data.(lineNames{idx-1})(dataLineNr,1) = str2double(values{idx});
                    end%for
                    dataLineNr = dataLineNr + 1;
                end%if
            end%if
        end%if
        if contains(currentLine, 'endheader')
            isHeader = 0;
        end%if
    end%while
end%function