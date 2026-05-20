clear;
clc;

videoFile = 'f1corner.mp4';

% Better quality settings
targetHeight = 32;
targetWidth  = 32;
useGrayscale = true;
maxFrames    = 3;

v = VideoReader(videoFile);

videoBitsCell = {};
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

numFrames = frameCount;
bitsPerFrame = numel(videoBitsCell{1});

assignin('base','videoBitsCell',videoBitsCell);
assignin('base','videoFramesCell',videoFramesCell);
assignin('base','numFrames',numFrames);
assignin('base','targetHeight',targetHeight);
assignin('base','targetWidth',targetWidth);
assignin('base','useGrayscale',useGrayscale);
assignin('base','bitsPerFrame',bitsPerFrame);

% Default packet for Simulink Constant block
packetBits = 96;
defaultBits = videoBitsCell{1}(:);
defaultBits = double(defaultBits);

if length(defaultBits) < packetBits
    defaultBits = [defaultBits; zeros(packetBits - length(defaultBits),1)];
else
    defaultBits = defaultBits(1:packetBits);
end

assignin('base','txFrameBits',defaultBits);

disp(['Loaded video: ' videoFile])
disp(['Frames processed = ' num2str(numFrames)])
disp(['Frame size = ' num2str(targetHeight) ' x ' num2str(targetWidth)])
disp(['Bits per frame = ' num2str(bitsPerFrame)])
disp('Default txFrameBits packet created in base workspace')