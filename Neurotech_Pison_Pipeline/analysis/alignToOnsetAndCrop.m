function [outputData] = alignToOnsetAndCrop(inputChTimeTr,truncatedSignalLength)
%alignToOnsetAndCrop: Try to find gesture onset and crop to numTPs in
%length
%   Detailed explanation goes here

numCh = size(inputChTimeTr,1);
numTrials = size(inputChTimeTr,3);
avgRMSthresh = .4; % Threshold of the average rescaled RMS
movingAvgTimepoints = 10;

for ch = 1:numCh
    for tr = 1:numTrials
        % Extract the signal
        sig = squeeze(inputChTimeTr(ch,:,tr));
        % find the moving RMS 
        movingRMS(ch,:,tr) = movmean(sig.^2, movingAvgTimepoints);
        rescalemovingRMS(ch,:,tr) = rescale(movingRMS(ch,:,tr));
    end
    
end



% mean of the moving RMS across channels after rescale from 0 to 1
%chmeanmovingRMS = squeeze(mean(rescale(movingRMS),1));
chmeanmovingRMS = squeeze(mean(rescalemovingRMS,1));


% find threshold
idx_thresh = zeros(1,numTrials);
for tr = 1:numTrials
    try
        ch1th =  find(rescalemovingRMS(1,:,tr)>avgRMSthresh,1,'first');
        ch2th =  find(rescalemovingRMS(2,:,tr)>avgRMSthresh,1,'first');
        ch3th =  find(rescalemovingRMS(3,:,tr)>avgRMSthresh,1,'first');
        ch4th =  find(rescalemovingRMS(4,:,tr)>avgRMSthresh,1,'first');

        idx_thresh(tr) = find(chmeanmovingRMS(:,tr)>avgRMSthresh,1,'first');
    catch
        % If you can't find something that fits, decrease the threshold
        if idx_thresh(tr) > size(inputChTimeTr,2) - truncatedSignalLength
            idx_thresh(tr) = find(chmeanmovingRMS(:,tr)> (avgRMSthresh -.2),1,'first');
        end
    end
end

% Go back 120 time points to get beginning of signal
idx_thresh = idx_thresh - 70;

% make sure no zeros

idx_thresh(idx_thresh <= 0) = 1;

% Crop (truncate) the data based on onset
for tr = 1:numTrials
    % if signal too close to end
    if (idx_thresh(tr) + truncatedSignalLength) > size(inputChTimeTr,2)
        idx_thresh(tr) = size(inputChTimeTr,2)-truncatedSignalLength+1;
        
        
    end
    outputData(:,:,tr) = inputChTimeTr(:,idx_thresh(tr):(idx_thresh(tr)+truncatedSignalLength-1),tr);

end



end