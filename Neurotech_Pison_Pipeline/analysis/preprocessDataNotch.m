function [epochedData,gesturelist] = preprocessDataNotch(lsl_data,marker_data)
%preprocessData Filter and epoch the data
%   

Fs = 1000;
numCh = 4;
epochedData =[];
labels = [];

    

% filter data (best to filter before chopping up to reduce artifacts)
% First check to make sure Fs (samping frequency is correct)
actualFs = 1/mean(diff(lsl_data(:,1)));
if abs(diff(actualFs - Fs )) > 50
    warning("Actual Fs and Fs are quite different. Please check sampling frequency.")
end

filtered_lsl_data = [];
filtered_lsl_data(:,1) = lsl_data(:,1);
for ch = 1:numCh
    x = highpass(lsl_data(:,ch+1),5,Fs);
    x = bandstop(x,[58 62],Fs);
    x = bandstop(x,[118 122],Fs);
    filtered_lsl_data(:,1+ch) = bandstop(x,[178 182],Fs);
end


% Run script to epoch: output is ch x timepoints x trials
[epochedData,gesturelist] = epochFromMarkersToLabels(filtered_lsl_data,marker_data,1400);


end
