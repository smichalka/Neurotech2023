function [res] = runMyModel(data)
%RUNMYMODEL Load and run your matlab model
%   res is the result. 1 for rock, 2 for paper, 3 for scissors
numCh = 4;

% This is your classifier (currentClassifier, or whatever you named it)
mymodel = load('simpleVarLDA.mat');

filt_data = zeros(size(data,1),numCh);
% Filter the data
for ch = 1:numCh
    filt_data(:,ch) = highpass(data(:,1+ch), 5,1000);
end

feats = extractFeaturesExample(filt_data',1:4,1000);



% You might want to confirm that mymodel.PredictorNames matches the feature
% name in feats

% You might want to check to see if the output of this is a 1,2, or 3. It
% should be a number.

res = mymodel.predict(feats);

end

