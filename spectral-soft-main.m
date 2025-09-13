clear; close all;

%% 1. Load and transform data 
T = readtable('data_part_1.csv', 'ReadVariableNames', true, 'VariableNamingRule', 'preserve'); % preserves original headers
Data = table2array(T(:, 2:21)); %
varNames = T.Properties.VariableNames(2:21);

% checks skeweness  
skewVals = skewness(Data, 0);
disp(table(varNames', skewVals', 'VariableNames', {'Variable', 'Skewness'}));

% Check time series ==> dataset doesnot have any time series and the interval at
% which wavelengths are captured is 1ns.

% Unknow or inconsistent physical units?? ==> data is properly cleaned and
% variable units are well defined. data contains many NA but matches the
% input validations. Not any ambiguous meanings so variables are clear to
% understand.

%% 2. Visuaalization Histograms: Optional 

nVars = size(Data, 2);
nCols = 5;               % Number of columns for subplot grid
nRows = ceil(nVars / nCols);

figure('Name', 'Histograms of Variables', 'NumberTitle', 'off');
for i = 1:nVars
    subplot(nRows, nCols, i);
    data_i = Data(:, i);
    data_i = data_i(~isnan(data_i));  % remove NaNs
    histogram(data_i, 'Normalization', 'probability');
    title(varNames{i}, 'Interpreter', 'none');
    xlabel('Value');
    ylabel('Probability');
    grid on;
end
sgtitle('Histograms of Raw Variables');

%% 2. Boxplot of variables before normalization

figure;
boxplot(Data, 'Labels', varNames, 'LabelOrientation', 'inline');
ylabel('Value');
grid on;

%% 2. Data Normalization + Missing values plot 

DataNorm = NaN(size(Data));

for c = 1:size(Data, 2)
    col = Data(:, c);
    mu = mean(col(~isnan(col)));
    sigma = std(col(~isnan(col)));
    DataNorm(:, c) = (col - mu) / sigma;
end

% Transpose for heatmap (variables as rows)
DataT = DataNorm';
nanMask = isnan(DataT);

% Replace all NaNs with O 
DataT_filled = DataT;
DataT_filled(nanMask) = 0;

%% 2. Heatmap visualization for missing values
figure;
imagesc(DataT_filled);

% Since heatmap() function doesnot support customr color mapping so built a
% custom one. we can move it later on to utils once report is finalized. 
cmap = [linspace(0,1,128)', linspace(0,1,128)', ones(128,1); ...
        ones(128,1), linspace(1,0,128)', linspace(1,0,128)'];
colormap(cmap);
colorbar;

hold on;
h_nan = imagesc(nanMask);
set(h_nan, 'AlphaData', double(nanMask), 'CData', zeros(size(DataT)));
hold off;

xlabel('Wavelengths');
yticks(1:nVars);
yticklabels(varNames);
ylabel('Variables');
title('Heatmap of Normalized Data with NaNs');
set(gca, 'YDir', 'normal');

fprintf('Number of observations: %d\n', size(Data, 1));
fprintf('Number of variables: %d\n', size(Data, 2));


%% This code line can be reduced. Lets' first ensure we have covered all the asked questions so it will be easier to finetune. 

%% 6. PCA and correlatioa  :: NEEDS to remove redundant information 

% check correlations among variables
figure;
imagesc(corr(Data, 'Rows', 'pairwise'));
title('Variable Correlation Matrix');
colormap("gray");
xticklabels(varNames);
yticklabels(varNames);
xtickangle(45);

% Replace remaining NaNs with column means before PCA
DataForPCA = DataNorm;
for c = 1:nVars
    col = DataForPCA(:, c);
    col(isnan(col)) = mean(col(~isnan(col)));
    DataForPCA(:, c) = col;
end

[coeff, score, latent, ~, explained] = pca(DataForPCA);

% Scree plot
figure;
plot(explained, '-o', 'LineWidth', 1.5);
xlabel('Principal Component');
ylabel('% Variance Explained');
title('Scree Plot');
grid on;

% Scores plot (PC1 vs PC2)
figure;
scatter(score(:,1), score(:,2), 50, 'filled');
xlabel('PC1');
ylabel('PC2');
title('PCA Scores Plot');
grid on;

% Biplot
figure;
biplot(coeff(:,1:2), 'Scores', score(:,1:2), 'VarLabels', varNames);
title('PCA Biplot');
