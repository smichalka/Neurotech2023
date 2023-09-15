function data = processData(lsl_mat)
    load(lsl_mat);
    starts = [];
    ends = [];
    markerNos = [];
    i = size(marker_data, 1);
    while i > 0
        % get endtime 
        curr_end = marker_data(i, 1);
        % shift index back to see the start time
        i = i - 1;
        data = marker_data(i, 2);
        % if index is not in markerNos
        if sum(markerNos==data)==0
            markerNos(end+1) = data;
            starts(end+1) = marker_data(i, 1)
            ends(end+1) = curr_end
        end
        i = i - 1;
    end
    data = cell(numel(starts),1);
    for i = 1:numel(starts)
        inds = (lsl_data(:,1) > starts(i)) & (lsl_data(:,1) < ends(i));
        data{i} = lsl_data(inds, 2:5);
    end
end