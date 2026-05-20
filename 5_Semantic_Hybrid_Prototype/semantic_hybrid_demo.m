clear; clc; close all;

%% Hybrid semantic-inspired video compression demo
% This script tests a lightweight AI/semantic-inspired preprocessing and
% postprocessing layer around conventional H.264 video compression.

inputVideo = "f1corner.mp4";
outputVideo = "semantic_hybrid_output.mp4";

targetSize = [256 256];
numFramesToUse = 60;   % keep this small for testing

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

    % Lightweight preprocessing stage
    % This represents the "AI-assisted preprocessor" concept.
    % It improves useful visual structure before compression.
    framePre = imsharpen(frameSmall);
    framePre = imadjust(framePre, stretchlim(framePre), []);

    framesOriginal{frameCount} = frameSmall;
    framesProcessed{frameCount} = framePre;
end

fprintf("Frames loaded: %d\n", frameCount);

%% Write processed frames to H.264 MP4
writer = VideoWriter(outputVideo, "MPEG-4");
writer.FrameRate = 15;
writer.Quality = 50;   % lower = smaller file, higher = better quality

open(writer);

for k = 1:frameCount
    writeVideo(writer, framesProcessed{k});
end

close(writer);

fprintf("Compressed video saved as: %s\n", outputVideo);

%% Compare file sizes
inputInfo = dir(inputVideo);
outputInfo = dir(outputVideo);

fprintf("\nFile size comparison:\n");
fprintf("Original file size: %.2f MB\n", inputInfo.bytes / 1e6);
fprintf("Hybrid compressed file size: %.2f MB\n", outputInfo.bytes / 1e6);
fprintf("Compression ratio: %.2f\n", inputInfo.bytes / outputInfo.bytes);

%% Read back compressed video
compressedReader = VideoReader(outputVideo);

decodedFrames = {};
decodedCount = 0;

while hasFrame(compressedReader)
    decodedCount = decodedCount + 1;

    decoded = readFrame(compressedReader);

    % Lightweight postprocessing stage
    % This represents the "AI-assisted postprocessor" concept.
    decodedPost = imsharpen(decoded);

    decodedFrames{decodedCount} = decodedPost;
end

%% Display comparison
frameToShow = min(10, frameCount);

figure;
subplot(1,3,1);
imshow(framesOriginal{frameToShow});
title("Original resized frame");

subplot(1,3,2);
imshow(framesProcessed{frameToShow});
title("Preprocessed frame");

subplot(1,3,3);
imshow(decodedFrames{frameToShow});
title("Decoded + postprocessed frame");

%% Basic image quality check
originalGray = rgb2gray(framesOriginal{frameToShow});
decodedGray = rgb2gray(decodedFrames{frameToShow});

mseValue = immse(originalGray, decodedGray);
psnrValue = psnr(decodedGray, originalGray);
ssimValue = ssim(decodedGray, originalGray);

fprintf("\nFrame quality metrics:\n");
fprintf("MSE: %.4f\n", mseValue);
fprintf("PSNR: %.2f dB\n", psnrValue);
fprintf("SSIM: %.4f\n", ssimValue);