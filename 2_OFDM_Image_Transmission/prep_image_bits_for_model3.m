clc;
clear;

% Load and resize image
img = imread('peppers.png');
img = imresize(img, [64 64]);

% Image dimensions
[H, W, C] = size(img);

% Convert image to byte stream
txBytes = img(:);

% Convert bytes to bits
txBits = reshape(de2bi(txBytes, 8, 'left-msb').', [], 1);

% Pad to multiple of 96 bits
padBits = mod(96 - mod(length(txBits), 96), 96);
if padBits == 96
    padBits = 0;
end

txBitsPadded = [txBits; zeros(padBits, 1)];

% Reshape into 96-bit frames
txFrames = reshape(txBitsPadded, 96, []).';

% Create discrete time vector: one frame per time step
t = (0:size(txFrames,1)-1)';

% Create timeseries for Simulink
txFramesTS = timeseries(txFrames, t);

% Push variables to base workspace
assignin('base', 'img', img);
assignin('base', 'H', H);
assignin('base', 'W', W);
assignin('base', 'C', C);
assignin('base', 'txBytes', txBytes);
assignin('base', 'txBits', txBits);
assignin('base', 'txBitsPadded', txBitsPadded);
assignin('base', 'txFrames', txFrames);
assignin('base', 'txFramesTS', txFramesTS);
assignin('base', 'padBits', padBits);

disp(['Original number of bits = ' num2str(length(txBits))]);
disp(['Padding bits added = ' num2str(padBits)]);
disp(['Total transmitted bits = ' num2str(length(txBitsPadded))]);
disp(['Number of 96-bit frames = ' num2str(size(txFrames,1))]);
disp('Framed image bitstream prepared for Model 3.');