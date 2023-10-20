function [epochedData,gest_list] = epochFromMarkersToLabels(lsl_data,marker_data, numTPs)
%epochFromMarkersToLabels Turn continous data and LSL markers into data
%with equal time windows
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
    % Make list to include this index and the prior index (where the actual
    % trial starts)
    idx_bad_markers = [idx_bad_markers; (idx_bad_markers-1)];
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

    % For each trial, add to the epoched data
    epochedData(:,:,i) = lsl_data(idx:(idx+numTPs-1),2:5)';
end

end