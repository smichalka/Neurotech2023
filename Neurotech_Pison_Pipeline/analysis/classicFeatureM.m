
%% Load the recent data
%addpath("../Neurotech2023/Neurotech_Pison_Pipeline/")

Fs = 1000;
numCh = 4;
epochedData =[];
labels = [];
% i is which folders you want to load from.
for i = 7:10
    % load the gesturelist and data
    load(strcat("../../../SSVEP/gestures/gest_",num2str(i),"/gestures.mat"));
    gest_data_name = dir(strcat("../../../SSVEP/gestures/gest_",num2str(i),"/lsl_data*.mat"));
    load(fullfile(gest_data_name.folder,gest_data_name.name))
    %gest_data = processData(fullfile(gest_data_name.folder,gest_data_name.name));

    % filter data (best to filter before chopping up to reduce artifacts)
    % First check to make sure Fs (samping frequency is correct)
    actualFs = 1/mean(diff(lsl_data(:,1)));

    filtered_lsl_data = [];
    filtered_lsl_data(:,1) = lsl_data(:,1);
    for ch = 1:numCh
        filtered_lsl_data(:,1+ch) = highpass(lsl_data(:,ch+1),5,Fs);
    end


    % Run script to epoch: output is ch x timepoints x trials
    [folderEpochedData,gesturelist] = epochFromMarkersToLabels(filtered_lsl_data,marker_data,1400,gesturelist);

    % Concatenate on the 3rd dimension (trials)
    epochedData = cat(3,epochedData,folderEpochedData);
    % Concatenate labels too
    labels = [labels; gesturelist'];


end

%% Realign the data and crop

% Set the number to 1400 for all data without realignment.
dataChTimeTr = alignToOnsetAndCrop(epochedData,1400);


label_names = unique(labels)

%% Plot some raw data
tr = 1:30;
figure;
colors = {'b','r','g'};
for ch = 1:numCh
    subplot(numCh,1,ch);
    for l = [2 3 1]%1:length(label_names)
        plot(squeeze(dataChTimeTr(ch,:,tr(labels(tr)==label_names(l)))),colors{l}); hold on
    end
    title(strcat('Ch ',num2str(ch)));
end

%% extract features from old code
allFeatureNames = {'bp2t20','bp20t40','bp40t56','bp64t80' ,'bp80t110','bp110t250', 'bp200t500',...
'rms', 'iemg','mmav1','mpv','var', 'mav', 'zeros', 'mfl', 'ssi', 'medianfreq', 'wamp',...
'lscale', 'wl', 'm2', 'damv' 'dasdv', 'dvarv', 'msr', 'ld', 'meanfreq', 'stdv', 'skew', 'kurt',...
'np'};
%% Choose features to include in feature extraction
%includedfeatures = {'bp80t110'};
extractedFeatureNames = {'var'};
%extractedFeatureNames = allFeatureNames([1,2,3,4,5,6,7])
%extractedFeatureNames = allFeatureNames;

% Put extracted features into a structure
featureData = extractClassicEMG(dataChTimeTr,extractedFeatureNames,[1 1400],1400);

numTWs = 2; %number of time windows (window size / bin size above)

%% Plot selected features
% Plot first 25 features

for tw = 1:numTWs
    figure
    pl=1;
    for i = 1:length(featureData.Properties.VariableNames)
        %tempfeat = eval(strcat('featureData.',extractedFeatureNames{i},'(:,',num2str(tw),')'));
        subplot(5,10,pl)
        
        histogram(featureData{labels==1,i},20,"Normalization","probability"); hold on
        histogram(featureData{labels==2,i},20,"Normalization","probability");
        histogram(featureData{labels==3,i},20,"Normalization","probability");
        title(featureData.Properties.VariableNames{i})
        pl = pl+1;
    end
end

%% Split data into train and test
try 
    load("lastCVpartition.mat")
    disp("loading prior training-test partition")
    if cvtt.NumObservations ~= length(labels)
        warning('Loaded cv partition does not match number of observations, delete or rename and rerun, making a temporary new one')
        cvtt = cvpartition(labels,"HoldOut",.5);
    end
catch
    cvtt = cvpartition(labels,"HoldOut",.5);
    save("./lastCVpartition.mat","cvtt");
    disp('Making new training-test partiton')
end

X_train = featureData(training(cvtt),:);
y_train = categorical(labels(training(cvtt)));
X_test = featureData(test(cvtt),:);
y_test = categorical(labels(test(cvtt)));

%% Do feature selection

% Loop through all feature types and build a model using all channels for
% each time window separately

validationPredictions = zeros(length(y_train),1);
featSelectionAccuracies = zeros(length(extractedFeatureNames),numTWs);
for tw = 1:numTWs
    for f = 1:length(extractedFeatureNames)
        idx_feat = find(contains(featureData.Properties.VariableNames,extractedFeatureNames(f)) ...
            & contains(featureData.Properties.VariableNames,strcat('Tw',num2str(tw))));
        
        
        % Perform cross-validation (just 2 fold for feature selection)
        KFolds = 2;
        cvp = cvpartition(y_train, 'KFold', KFolds);
    
        for fold = 1:KFolds
            trainingPredictors = X_train(cvp.training(fold), idx_feat);
            trainingResponse = y_train(cvp.training(fold));
            % Compute validation predictions
            validationPredictors = X_train(cvp.test(fold), idx_feat);
            % Make temporary  model
            featSelectionClassificationModel = fitcknn(trainingPredictors,trainingResponse);
            
            % Make predictions for validation set
            foldPredictions = featSelectionClassificationModel.predict(validationPredictors);
        
            % Store predictions in the original order
            validationPredictions(cvp.test(fold), :) = foldPredictions;
        end
    
        featSelectionAccuracies(f,tw) = sum(y_train==categorical(validationPredictions))./length(validationPredictions);
    end
    disp('For time window ')
    disp(num2str(tw))
    idx_featsOK = find(featSelectionAccuracies(:,tw)>.90);
    extractedFeatureNames(idx_featsOK)
end

%% plot accuracies
figure; plot(featSelectionAccuracies,'.-','LineWidth',2); xticks(1:length(extractedFeatureNames)); xticklabels(extractedFeatureNames);
title('Time windows are the lines'); ylabel('Accuracy'); legend(string(1:numTWs));

%% Select features

% Make sure that you're careful about the time windows
temp_idx = find(featSelectionAccuracies(:,1)>.9); % only looking at first time window here
% or do manual selection 
%temp_idx = [ 7:10];

selectedFeatureNamesToKeep = extractedFeatureNames(temp_idx)

idx_feats2keep = [];
for tw = 1 %This is the time windows you want to keep
    for f = 1:length(selectedFeatureNamesToKeep)
        % Find the matching featuer indices
        idx_feats2keep = [idx_feats2keep ...
            find(contains(featureData.Properties.VariableNames,...
            strcat(selectedFeatureNamesToKeep(f),'_Tw',num2str(tw))))];
    end
end
featureData.Properties.VariableNames(idx_feats2keep)

%% Run cross-validation on selected features

 % Perform cross-validation (just 2 fold for feature selection)
KFolds = 5;
cvp = cvpartition(y_train, 'KFold', KFolds);
validationPredictions = zeros(length(y_train),1);

for fold = 1:KFolds
    % Subset of training data for training for crossvalidation
    trainingPredictors = X_train(cvp.training(fold), idx_feats2keep);
    trainingResponse = y_train(cvp.training(fold));
    
    % Compute validation predictions
    validationPredictors = X_train(cvp.test(fold), idx_feats2keep);
    % Make temporary  model
    crossvalClassificationModel = fitcknn(trainingPredictors,trainingResponse);
    
    % Make predictions for validation set
    foldPredictions = crossvalClassificationModel.predict(validationPredictors);

    % Store predictions in the original order
    validationPredictions(cvp.test(fold), :) = foldPredictions;
end

validationPredictions = categorical(validationPredictions);

accuracy_training_crossval = sum(validationPredictions==y_train)./length(validationPredictions)
figure;
confchart_training_crosval = confusionchart(y_train,validationPredictions);
title("Cross-validation data confusion chart")

%% Make final model and run on test data

% Make model on all training data using the selected features
classificationModel = fitcknn(X_train(:,idx_feats2keep),y_train);

% Predict on the test data (make sure to use the same features)
predictions_test = classificationModel.predict(X_test(:,idx_feats2keep));
predictions_test = categorical(predictions_test);

accuracy_training_crossval = sum(predictions_test==y_test)./length(predictions_test)
figure;
confchart_training_crosval = confusionchart(y_test,predictions_test);
title("Test data confusion chart")
