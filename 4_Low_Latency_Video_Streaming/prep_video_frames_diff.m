clear;
clc;

videoFile = 'f1corner.mp4';

targetHeight = 64;
targetWidth  = 64;
useGrayscale = true;
maxFrames    = 20;

v = VideoReader(videoFile);

videoFramesCell = {};
frameCount = 0;

while hasFrame(v) && frameCount < maxFrames
    frame = readFrame(v);
    frameCount = frameCount + 1;

    frame = imresize(frame, [targetHeight targetWidth]);

    if useGrayscale
        frame = rgb2gray(frame);
    end

    videoFramesCell{frameCount} = frame;
end

numFrames = frameCount;

assignin('base','videoFramesCell',videoFramesCell);
assignin('base','numFrames',numFrames);
assignin('base','targetHeight',targetHeight);
assignin('base','targetWidth',targetWidth);
assignin('base','useGrayscale',useGrayscale);

disp('Difference-frame video preparation complete.');
fprintf('Frames loaded: %d\n', numFrames);
fprintf('Frame size: %d x %d\n', targetHeight, targetWidth);