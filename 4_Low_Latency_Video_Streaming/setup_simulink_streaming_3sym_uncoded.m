clc;
clear;

payloadBitsPerFrame = 192;
preambleBitsPerFrame = 96;

txPayloadBits = randi([0 1], payloadBitsPerFrame, 1);

basePattern = [1;0;1;0;0;1;1;0];
preambleBits = repmat(basePattern, 12, 1);   % 96 bits

totalFrameBits = preambleBitsPerFrame + payloadBitsPerFrame;   % 288

fftLen = 64;
cpLen = 16;
numDataSubc = 48;
bitsPerQPSKSymbol = 2;
numOFDMSymbolsPerFrame = 3;
snr_dB = 30;

assignin('base','txPayloadBits',txPayloadBits);
assignin('base','preambleBits',preambleBits);

assignin('base','payloadBitsPerFrame',payloadBitsPerFrame);
assignin('base','preambleBitsPerFrame',preambleBitsPerFrame);
assignin('base','totalFrameBits',totalFrameBits);

assignin('base','fftLen',fftLen);
assignin('base','cpLen',cpLen);
assignin('base','numDataSubc',numDataSubc);
assignin('base','bitsPerQPSKSymbol',bitsPerQPSKSymbol);
assignin('base','numOFDMSymbolsPerFrame',numOFDMSymbolsPerFrame);
assignin('base','snr_dB',snr_dB);

disp('3-symbol uncoded setup complete.');
fprintf('Payload bits/frame  : %d\n', payloadBitsPerFrame);
fprintf('Preamble bits/frame : %d\n', preambleBitsPerFrame);
fprintf('Total frame bits    : %d\n', totalFrameBits);
fprintf('OFDM symbols/frame  : %d\n', numOFDMSymbolsPerFrame);
fprintf('SNR (dB)            : %.1f\n', snr_dB);