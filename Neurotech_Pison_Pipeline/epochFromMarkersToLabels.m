function [epochedData,gest_list] = epochFromMarkersToLabels(lsl_data,marker_data, numTPs, gest_list)
%epochFromMarkersToLabels Turn continous data and LSL markers into data
%with equal time windows
%   lsl_data: raw recorded data
%   marker_data: data with timestamps of markers and marker numer
%   numTPs: how many timepoint to keep (length of signal to keep in points
%   (not time)
%   gest_list: list of the gestures (just use this to make sure lengths are
%   the same

% Find the Marker onset for all non-zero markers
start_times = marker_data(marker_data(:,2)~=0,1);
% Check to make sure the number of markers matches the number of trials
if length(start_times) ~= length(gest_list)
    warning("Number of markers does not match the gest_list. Please look at start_times code.")
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