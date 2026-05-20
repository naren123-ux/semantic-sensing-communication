clear;
clc;

videoFile = 'f1corner.mp4';

targetHeight = 64;
targetWidth  = 64;
useGrayscale = true;
maxFrames    = 20;

v = VideoReader(videoFile);

videoBitsCell   = {};
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

    bits = de2bi(frame(:), 8, 'left-msb');
    bits = bits.';
    bits = bits(:);
    bits = double(bits);

    videoBitsCell{frameCount} = bits;
end

numFrames    = frameCount;
bitsPerFrame = numel(videoBitsCell{1});

assignin('base','videoBitsCell',videoBitsCell);
assignin('base','videoFramesCell',videoFramesCell);
assignin('base','numFrames',numFrames);
assignin('base','targetHeight',targetHeight);
assignin('base','targetWidth',targetWidth);
assignin('base','useGrayscale',useGrayscale);
assignin('base','bitsPerFrame',bitsPerFrame);

disp('Video preparation complete.');
fprintf('Frames loaded: %d\n', numFrames);
fprintf('Frame size: %d x %d\n', targetHeight, targetWidth);
fprintf('Bits per frame: %d\n', bitsPerFrame);