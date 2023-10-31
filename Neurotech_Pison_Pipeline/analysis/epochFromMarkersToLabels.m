function [epochedData,gest_list] = epochFromMarkersToLabels(lsl_data,marker_data, numTPs)
%epochFromMarkersToLabels Turn continous data and LSL markers into data
%with equal time windows.  Sam Michalka 2023
%   lsl_data: raw recorded data
%   marker_data: data with timestamps of markers and marker numer
%   numTPs: how many timepoint to keep (length of signal to keep in points
%   (not time)




% Find all markers that indicate a rerecording and delete them
bad_marker = 99; % This is the marker number to indicate the trial was re-recorded due to error
% This is list of any markers that indicate a bad marker
idx_bad_markers = find(marker_data(:,2)==bad_marker);

% If there are bad markers
if size(idx_bad_markers,1) > 0


    % If there is a zero sent after each trial (matlab version)
  
    if sum(marker_data(:,2)==0) >0

        %Then we need to eliminate the marker and 0 marker before
        % Make list to include this index and the prior index (where the actual
        % trial starts)
        idx_bad_markers = [idx_bad_markers; (idx_bad_markers-1)];
    end
    % Otherwise, you can just eliminate the bad markers.


    if min(idx_bad_markers) < 1
        warning('Getting bad marker as first marker. Look at data for dropped markers')
        idx_bad_markers(idx_bad_markers<=0) = 1; % 
    end
    % Remove all bad markers and their trials from the marker data
    marker_data(idx_bad_markers,:) = [];
end



% Find the Marker onset for all non-zero markers
start_times = marker_data(marker_data(:,2)~=0,1);

% if gesture list doesn't exist (because gestures in marker_data
if ~exist("gest_list","var")
    gest_list = marker_data(marker_data(:,2)~=0,2);
end

% Check to make sure the number of markers matches the number of trials
if length(start_times) ~= length(gest_list)
    input("Number of markers does not match the gest_list. Please look at start_times code.")
end

% Empty data: channels x timepoints x trials
epochedData = zeros(4,numTPs,length(start_times));
% Find the closest data start to the timepoint
for i = 1:length(start_times)
    % find the row number of the time stamp that is closest to the start
    % time
    [~, idx ] = min(abs(lsl_data(:,1)-start_times(i)));

    % Check to see if the index is not too close to the end
    if (idx+numTPs-1) <= size(lsl_data,1)
        % For each trial, add to the epoched data
        epochedData(:,:,i) = lsl_data(idx:(idx+numTPs-1),2:5)';
    else
        % If it is too close to the end, you have to stop here.
        warning("Not enough datapoints in lsl_data relative to start_times + numTPs. Some trials removed.")
        idx
        numTPs
        size(lsl_data,1)
        % Then get rid of the extra trials in epochedData and break out of
        % this loop
        epochedData(:,:,i:end) = [];
        gest_list(i:end)= [];
        warning(strcat("Epoched data now has ",num2str(i)," trials, with ", num2str(size(start_times,1))," originally."));
        break
    end
end

end