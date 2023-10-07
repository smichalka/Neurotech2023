function [tempdata] = extractClassicEMG(dataChTimeTr,includedfeatures,totalTimepointWindow,timepointWindowBinSize)
%EXTRACTCLASSICEMG Extract features from EMG data
%   Input is an array with trials x time x ch
%   includedfeatures is from includedfeatures = {'bp2t20','bp20t40','bp40t56','bp64t80' ,'bp80t110','bp110t250', 'bp200t500',...
%        'rms', 'iemg','mmav1','mpv','var', 'mav', 'zeros', 'mfl', 'ssi', 'medianfreq', 'wamp',...
%        'lscale', 'wl', 'm2', 'damv' 'dasdv', 'dvarv', 'msr', 'ld', 'meanfreq', 'stdv', 'skew', 'kurt',...
%         'np'};

tempdata = [];
Fs = 1000;
includedchannels = 1:size(dataChTimeTr,1);
% Time windows and overlap (when breaking window up into multiple bins)
w.totaltimewindow = totalTimepointWindow; %start and stop in timepoints. If timepoints don't line up, this will select a slightly later time
w.timewindowbinsize = timepointWindowBinSize; %This should ideally divide into an equal number of time points
w.timewindowoverlap = 0; %Overlap of the time windows

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Create time bins to loop through in feature selection 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

w.starttimes = w.totaltimewindow(1):(w.timewindowbinsize-w.timewindowoverlap):w.totaltimewindow(2);
w.endtimes = ((w.totaltimewindow(1)+w.timewindowbinsize):(w.timewindowbinsize-w.timewindowoverlap):w.totaltimewindow(2))-1;
if w.totaltimewindow(2) - w.starttimes(end) <= w.timewindowoverlap %if increment is smaller than the overlap window
    w.starttimes(end) = []; %then remove the last one (avoids indexing problem, plus you've already used this data)
end
if length(w.starttimes) > length(w.endtimes)
    w.endtimes = [w.endtimes w.totaltimewindow(2)];
    %warning('The timewindowbinsize does not split evenly into the totaltimewindow, last window will be smaller')
    w.endtimes - w.starttimes;
end
w.alltimewindowsforfeatures = [w.starttimes; w.endtimes]; %(:,1) for first pair

w.numTW = size(w.alltimewindowsforfeatures,2);

 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Add features to the data table
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
for ch = includedchannels %not necessarily a linear index, so be careful
    for f = 1:length(includedfeatures)
        fvalues =[]; %clear and initialize fvalues
        for  tw = 1:w.numTW
            timewindowforfeatures = w.alltimewindowsforfeatures(:,tw);
            
            %timewindowepochidx = (find(EEG.times>=timewindowforfeatures(1),1)):(find(EEG.times>=timewindowforfeatures(2),1));
            % do usin time points instead of times
            timewindowepochidx = timewindowforfeatures(1):timewindowforfeatures(2);
            %mydata is a subset of the data for the channel,
            %timewindow, and selected indices (train/test and
            %conditions)
            mydata = squeeze(dataChTimeTr(ch,timewindowepochidx,:)); 
            %mytimes = EEG.times(timewindowepochidx);
            freqdata = abs(fft(mydata));
            % Note: because we're looping through multiple time
            % bins, it's important to  check the size of the
            % features going into fvalues. Should be trials x
            % feature 
            % Calcuate actual features by name in loop
            switch includedfeatures{f}
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                % Time domain features
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                case 'rms'
                    fvalues = [fvalues rms(mydata)'];                   
                case 'iemg'
                    fvalues = [fvalues sum(abs(mydata))'];
                case 'ssi' % Simple square integral - squared version of iEMG
                    fvalues = [fvalues sum(mydata.^2)'];
                    % This could instead be done with the integral, which gives a smaller but correlated number if rectified
                    %ctr = squeeze(cumtrapz(EEG.timessec(timewindowepochidx), abs(dataChTimeTr(ch,timewindowepochidx,:))));
                    %fvalues = ctr(end,:)'; % This could be useful if you
                    %wanted to take the diff between different increments.
                case 'm2' %second order moment, same as SSI but on the diff
                    fvalues = [fvalues sum(diff(mydata).^2)'];
                    
                case 'wl' %waveform length (extension of iEMG but based on difference);
                    fvalues = [fvalues (sum(abs(diff(mydata))))'];  
                case 'mav' %mean absolute value
                    fvalues = [fvalues mean(abs(mydata))'];
                case 'damv' %difference absolute mean value - modified version of the MAV but on the difference
                    fvalues = [fvalues mean(abs(diff(mydata)))'];
                    %Also known as average amplitude change (aac),  modified to run on the difference, then known as difference absolute mean value (DAMV) (Kim et al., 2011);
               
                
                case 'mpv'
                    mpv = [];
                    [row, col] = find(mydata > rms(mydata)); %index of peaks
                    for n = 1:size(mydata,2)      
                        mpv(n) = mean(mydata(row(col==n),n));
                    end
                    fvalues = [fvalues mpv'];
                    
                
                case 'mmav1'
                    low = prctile(mydata,25,1);
                    high = prctile(mydata,75,1);
                    weightedVals = mydata; %SWM: added :
                    weightedVals(weightedVals < low) = weightedVals(weightedVals < low)*.5;
                    weightedVals(weightedVals > high) = weightedVals(weightedVals > high)*.5;
                    fvalues = [fvalues mean(abs(weightedVals))'];
                case 'var'
                    fvalues = [fvalues var(mydata)'];
                case 'dvarv' %difference variance value
                    % same as using var func, so using var for
                    % ease of reading
                    %fvalues = [fvalues ((sum((diff(mydata)).^2))/(size(mydata,1)-2))'];
                    fvalues = [fvalues var(diff(mydata))'];
                
                case 'np' %number of peaks
                    np = sum(mydata > rms(mydata), 1);
                    fvalues = [fvalues np'];
                case 'dasdv' %difference absolute standard deviation value
                    fvalues = [fvalues sqrt(mean(diff(mydata).^2))'];
                
                case 'msr' %mean value of square root 
                    % Note: this deviates from original
                    % equation by using the abs to avoid
                    % complex numbers from the sqrt
                    fvalues = [fvalues (mean(sqrt(abs(mydata))))'];
                case 'ld' %log detector
                    fvalues = [fvalues exp(mean(log(abs(mydata))))'];
                case 'stdv' %standard deviation
                    fvalues = [fvalues (std(mydata))'];
                case 'skew' %skewness
                    fvalues = [fvalues (skewness(mydata))'];
                case 'kurt' %kurtosis
                    fvalues = [fvalues (kurtosis(mydata))'];
                   
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                % Frequency domain features
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                
                case 'bp2t20' % Band power                      
                    fvalues = [fvalues bandpower(mydata,Fs,[2 20])'];
                case 'bp20t40'             
                    fvalues = [fvalues bandpower(mydata,Fs,[20 40])'];
                case 'bp40t56'                       
                    fvalues = [fvalues bandpower(mydata,Fs,[40 56])'];
                case 'bp64t80'
                    fvalues = [fvalues bandpower(mydata,Fs,[64 80])'];
                case 'bp80t110'
                    fvalues = [fvalues bandpower(mydata,Fs,[80 110])'];
                case 'bp110t250'
                    fvalues = [fvalues bandpower(mydata,Fs,[110 250])'];
                case 'bp200t500'
                    fvalues = [fvalues bandpower(mydata,Fs,[256 500])'];
                
                case 'medianfreq' %median normalized frequency
                    %TODO: check this code. real after median? are these the right dims?
                    %fvalues = [fvalues (real(median(fft(mydata,'',1))))'];
                    %fvalues = [fvalues squeeze(real(median(fft(dataChTimeTr(ch,timewindowepochidx,:), '', 2), 2)))];
                    fvalues = [fvalues (medfreq(mydata,Fs))']; %Added 7/15/20
                case 'meanfreq' %mean normalized frequency
                    fvalues = [fvalues (meanfreq(mydata,Fs))']; 
                
                
                case 'mfp' %mean frequency peak - TODO: REMOVE FROM TOP FOR NOW
                    % potential error in how freqdata is used
                    % here - might want the freqs not their
                    % powers
                    [row, col] = find(freqdata > rms(freqdata)); 
                    for n = 1:size(freqdata,2)      
                        mfp(n) = mean(freqdata(row(col==n),n));
                    end
                    fvalues = [fvalues mfp];
                case 'stdpk'%standard deviation of peaks - TODO: REMOVE FROM TOP FOR NOW
                    % potential error in how freqdata is used
                    % here - might want the freqs not their
                    % powers
                    [row, col] = find(freqdata > rms(freqdata)); 
                    for n = 1:size(freqdata,2)      
                        stdpk(n) = std(freqdata(row(col==n),n));
                    end
                    fvalues = [fvalues stdpk];
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                % Other features
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                
                case 'wamp' % Wilson Amplitude %TODO: check this code
                    % There is almost definitely a better way to do
                    % this.
                    %threshold = 0.05;
                    %shifted = circshift(mydata,1,1);
                    %wamp_sum = sum(abs(mydata) + threshold < abs(shifted));
                    %shifted = circshift(dataChTimeTr(ch,timewindowepochidx, :), 1, 2);
                    %wamp_sum = sum(abs(dataChTimeTr(ch,timewindowepochidx, :)) + threshold < (abs(shifted)), 2);
                    threshold = 0.05;
                    wamp = sum((abs(diff(mydata)))>threshold);
                    fvalues = [fvalues wamp'];
                
                % case 'Hmob' %Hjorth mobility - TODO: REMOVE FROM TOP FOR NOW
                %     fvalues = [fvalues Mobility(mydata, mytimes)];
                % case 'hcom' %Hjorth Complexity - TODO: REMOVE FROM TOP FOR NOW
                %     HCom = Mobility((gradient(mydata)./gradient(mytimes)'), mytimes)./(Mobility(mydata, mytimes));
                %     fvalues = [fvalues HCom]; 
                    
                case 'zeros'
                    zcd = dsp.ZeroCrossingDetector;
                    fvalues = [fvalues double(zcd(mydata))'];
                case 'lscale'
                    fvalues = [fvalues lscale(mydata)'];
                %case 'dfa'
                %    fvalues = [fvalues DFAfunc(mydata,dfabinsize)];   
                    
                case 'mfl' %code double checked by Rishita on 7/6/2020
                    fvalues = [fvalues real(log10(sqrt(sum(diff(mydata).^2))))'];
                    %fvalues = [fvalues squeeze(real(log10(sqrt(sum(diff(dataChTimeTr(ch,timewindowepochidx,:)).^2, 2)))))];
                    
                otherwise
                    disp(strcat('unknown feature: ', includedfeatures{f},', skipping....'))
            end
        end

        % Make sure fvalues is the right shape !!!!!!!!!!!!!!!!!
        if size(squeeze(fvalues),1) ~= size(dataChTimeTr,3)
            warning(strcat('fvalues does not fit in data table, skipping feature: ', includedfeatures{f},...
                '. _  Please fix the code to align shapes. Num trials: ',num2str(size(dataChTimeTr,3)),...
                ' and size fvalues : ',num2str(size(fvalues))))
        else

            %This one puts them into a table
            for  tw = 1:w.numTW
                tempdata = [tempdata table(fvalues(:,tw),...
                    'VariableNames',string(strcat('Ch',num2str(ch), '_' ,includedfeatures{f}, '_' ,'Tw',num2str(tw))))];
            end
            
            % Put fvalues into a structure with appropriate feature name
            %eval(['tempdata.FEAT_ch' num2str(ch) '_' includedfeatures{f} ' = fvalues;']);
        end
    end
end

end

