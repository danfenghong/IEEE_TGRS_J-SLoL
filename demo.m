clc;
clear;
close all;

addpath('Data');
addpath('Functions');

load MSI_IndinePine.mat;
[~, ~, z_ms] = size(data_MS_HR);
MSI = data_MS_HR / max(max(max(data_MS_HR)));

HSI = (double(imread('19920612_AVIRIS_IndianPine_Site3.tif')));
HSI = HSI / max(max(max(HSI)));
[m, n, z_hsi] = size(HSI);

TR = imread('IndianTR123_temp123.tif');
TE = imread('IndianTE123_temp123.tif');

OR_HSI = HSI(:, 1 : 45, :);
OR_MSI = MSI(:, 1 : 45, :);

OS_HSI = HSI(:, 46 : end, :);
OS_MSI = MSI(:, 46 : end, :);

MSI2d = hyperConvert2d(MSI);
HSI2d = hyperConvert2d(HSI);

OR_HSI2d = hyperConvert2d(OR_HSI);
OR_MSI2d = hyperConvert2d(OR_MSI);

OS_HSI2d = hyperConvert2d(OS_HSI);
OS_MSI2d = hyperConvert2d(OS_MSI);

TR2d = double(hyperConvert2d(TR));
TE2d = double(hyperConvert2d(TE));

%% dictionary initialization using K-means clustering
k=1024;
opts = statset('Display','final');
rng(1);
[~, D_G] = kmeans([OR_HSI2d; OR_MSI2d]',k,'Start','uniform','Replicates',1,'MaxIter',10000,'Options',opts);

% paramter setting
alfa = 1;
beta = 0.001;
gamma = 0.1;
eta = 0.0001;
maxiter = 1000;

% low-rank dictionary learning (D_step)
[D_H, ~] = D_Step([OR_HSI2d; alfa * OR_MSI2d], D_G', beta, gamma, maxiter);

% sparse recovery (S_step)
X = S_Step(OS_MSI2d, D_H(221 : end, :), eta, 1000);


OS_HSI_EST = D_H(1 : 220, :) * X;
RC_HSI2d = [OR_HSI2d, OS_HSI_EST];
RC_HSI = hyperConvert3d(RC_HSI2d, 145, 145, 220); % reconstruction HSI

% quantitative evaluation

% RMSE
rmse = RMSE(HSI, RC_HSI)

% PSNR
psnr = PSNR(HSI, RC_HSI)

% SAD
sad = XSAM(HSI2d, RC_HSI2d)

% SSIM
M = zeros(1, z_hsi);
for i = 1 : z_hsi
    M(1, i) = ssim_index(255*mat2gray(HSI(:, :, i)), 255 * mat2gray(RC_HSI(:, :, i)));
end
ssim = mean(M)

% ERGAS
ergas = ErrRelGlobAdimSyn(HSI, RC_HSI)


%% classification evalution
TR_label = TR2d(:, TR2d > 0);
TE_label = TE2d(:, TE2d > 0);

TR_samples = RC_HSI2d(:, TR2d > 0);
TE_samples = RC_HSI2d(:, TE2d > 0);

% KNN classifier 
mdl = ClassificationKNN.fit(TR_samples',TR_label','NumNeighbors',1,'distance','euclidean'); 
characterClass= predict(mdl,TE_samples'); 
[M,oa,pa,ua,kappa] = confusionMatrix( TE_label', characterClass );