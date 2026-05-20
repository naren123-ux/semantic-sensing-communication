% create_hybrid_video.m
clear; clc; close all;

%% File names
inputVideo = "f1corner.mp4";
baselineVideo = "baseline_256_compressed.mp4";
hybridVideo = "hybrid_256_ai_compressed.mp4";
resultsFile = "ai_hybrid_results.txt";
figureFile = "figure_ai_hybrid_comparison.png";

%% Settings
targetSize = [256 256];
numFramesToUse = 60;
frameRate = 15;
qualityValue = 50;

%% Read input video
reader = VideoReader(inputVideo);

framesOriginal = {};
framesProcessed = {};

frameCount = 0;

while hasFrame(reader) && frameCount < numFramesToUse
    frame = readFrame(reader);
    frameCount = frameCount + 1;

    % Resize to 256x256
    frameSmall = imresize(frame, targetSize);

    %% Lightweight semantic-inspired preprocessing
    % The idea is to preserve the most useful driving/track region while
    % simplifying less important background detail before compression.

    % Slightly blur the full frame first
    frameBlur = imgaussfilt(frameSmall, 1.2);
    framePre = frameBlur;

    [h, w, ~] = size(frameSmall);

    % Define a central region of interest.
    % This keeps the main track/car view clearer.
    rowStart = round(0.25 * h);
    rowEnd   = round(0.95 * h);
    colStart = round(0.15 * w);
    colEnd   = round(0.85 * w);

    roi = frameSmall(rowStart:rowEnd, colStart:colEnd, :);

    % Preserve and lightly sharpen the useful region
    roi = imsharpen(roi);

    % Put the enhanced region back into the blurred frame
    framePre(rowStart:rowEnd, colStart:colEnd, :) = roi;

    framesOriginal{frameCount} = frameSmall;
    framesProcessed{frameCount} = framePre;
end

fprintf("Frames loaded: %d\n", frameCount);

%% Create fair baseline video: resized only
baselineWriter = VideoWriter(baselineVideo, "MPEG-4");
baselineWriter.FrameRate = frameRate;
baselineWriter.Quality = qualityValue;

open(baselineWriter);

for k = 1:frameCount
    writeVideo(baselineWriter, framesOriginal{k});
end

close(baselineWriter);

%% Create hybrid compressed video: semantic preprocessed frames
hybridWriter = VideoWriter(hybridVideo, "MPEG-4");
hybridWriter.FrameRate = frameRate;
hybridWriter.Quality = qualityValue;

open(hybridWriter);

for k = 1:frameCount
    writeVideo(hybridWriter, framesProcessed{k});
end

close(hybridWriter);

%% Compare file sizes
inputInfo = dir(inputVideo);
baselineInfo = dir(baselineVideo);
hybridInfo = dir(hybridVideo);

originalSizeMB = inputInfo.bytes / 1e6;
baselineSizeMB = baselineInfo.bytes / 1e6;
hybridSizeMB = hybridInfo.bytes / 1e6;

originalToHybridRatio = inputInfo.bytes / hybridInfo.bytes;
hybridReductionVsBaseline = (1 - hybridInfo.bytes / baselineInfo.bytes) * 100;

fprintf("\nFile size comparison:\n");
fprintf("Original input video size: %.3f MB\n", originalSizeMB);
fprintf("Baseline 256 compressed size: %.3f MB\n", baselineSizeMB);
fprintf("Hybrid compressed size: %.3f MB\n", hybridSizeMB);
fprintf("Original-to-hybrid compression ratio: %.2f\n", originalToHybridRatio);

fprintf("\nFair 256x256 comparison:\n");
fprintf("Hybrid reduction vs baseline: %.2f %%\n", hybridReductionVsBaseline);

%% Read hybrid video back and apply postprocessing
hybridReader = VideoReader(hybridVideo);

decodedFrames = {};
decodedCount = 0;

while hasFrame(hybridReader)
    decodedCount = decodedCount + 1;

    decoded = readFrame(hybridReader);

    %% Lightweight postprocessing
    % This slightly sharpens the decoded output after compression.
    decodedPost = imsharpen(decoded);

    decodedFrames{decodedCount} = decodedPost;
end

%% Display and save comparison figure
frameToShow = min(10, frameCount);

figure;
subplot(1,3,1);
imshow(framesOriginal{frameToShow});
title("Original resized frame");

subplot(1,3,2);
imshow(framesProcessed{frameToShow});
title("Semantic preprocessed frame");

subplot(1,3,3);
imshow(decodedFrames{frameToShow});
title("Decoded + postprocessed frame");

saveas(gcf, figureFile);

%% Quality metrics
originalGray = rgb2gray(framesOriginal{frameToShow});
decodedGray = rgb2gray(decodedFrames{frameToShow});

mseValue = immse(originalGray, decodedGray);
psnrValue = psnr(decodedGray, originalGray);
ssimValue = ssim(decodedGray, originalGray);

fprintf("\nFrame quality metrics:\n");
fprintf("MSE: %.4f\n", mseValue);
fprintf("PSNR: %.2f dB\n", psnrValue);
fprintf("SSIM: %.4f\n", ssimValue);

%% Save results to text file
fid = fopen(resultsFile, "w");

fprintf(fid, "AI-assisted hybrid compression prototype results\n");
fprintf(fid, "------------------------------------------------\n\n");
fprintf(fid, "Input video: %s\n", inputVideo);
fprintf(fid, "Frames used: %d\n", frameCount);
fprintf(fid, "Frame size: %d x %d\n", targetSize(1), targetSize(2));
fprintf(fid, "Frame rate: %d fps\n", frameRate);
fprintf(fid, "Video quality setting: %d\n\n", qualityValue);

fprintf(fid, "Preprocessing method:\n");
fprintf(fid, "A semantic-inspired region-of-interest approach was used.\n");
fprintf(fid, "The central driving region was preserved and lightly sharpened, while less important background regions were slightly blurred before compression.\n\n");

fprintf(fid, "File size comparison:\n");
fprintf(fid, "Original input video size: %.3f MB\n", originalSizeMB);
fprintf(fid, "Baseline 256 compressed size: %.3f MB\n", baselineSizeMB);
fprintf(fid, "Hybrid compressed size: %.3f MB\n", hybridSizeMB);
fprintf(fid, "Original-to-hybrid compression ratio: %.2f\n", originalToHybridRatio);
fprintf(fid, "Hybrid reduction vs baseline: %.2f %%\n\n", hybridReductionVsBaseline);

fprintf(fid, "Frame quality metrics:\n");
fprintf(fid, "MSE: %.4f\n", mseValue);
fprintf(fid, "PSNR: %.2f dB\n", psnrValue);
fprintf(fid, "SSIM: %.4f\n", ssimValue);

fclose(fid);

fprintf("\nSaved files:\n");
fprintf("%s\n", baselineVideo);
fprintf("%s\n", hybridVideo);
fprintf("%s\n", figureFile);
fprintf("%s\n", resultsFile);