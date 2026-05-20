clc;
clear;

% =========================================================
% Original payload settings
% =========================================================
payloadBitsPerFrame = 96;
preambleBitsPerFrame = 96;

% =========================================================
% Generate one payload frame
% =========================================================
txPayloadBits = randi([0 1], payloadBitsPerFrame, 1);

% =========================================================
% Known preamble
% =========================================================
basePattern = [1;0;1;0;0;1;1;0];
preambleBits = repmat(basePattern, 12, 1);   % 96 bits

% =========================================================
% Hamming and framing reference values
% =========================================================
hammingInputBlock = 4;
hammingOutputBlock = 7;

encodedPayloadBits = (payloadBitsPerFrame / hammingInputBlock) * hammingOutputBlock;   % 168
paddedPayloadBits  = 192;
totalFrameBits     = preambleBitsPerFrame + paddedPayloadBits;                          % 288

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
assignin('base','encodedPayloadBits',encodedPayloadBits);
assignin('base','paddedPayloadBits',paddedPayloadBits);
assignin('base','totalFrameBits',totalFrameBits);

assignin('base','fftLen',fftLen);
assignin('base','cpLen',cpLen);
assignin('base','numDataSubc',numDataSubc);
assignin('base','bitsPerQPSKSymbol',bitsPerQPSKSymbol);
assignin('base','numOFDMSymbolsPerFrame',numOFDMSymbolsPerFrame);
assignin('base','snr_dB',snr_dB);

disp('Hamming Simulink setup complete.');
fprintf('Original payload bits   : %d\n', payloadBitsPerFrame);
fprintf('Encoded payload bits    : %d\n', encodedPayloadBits);
fprintf('Padded payload bits     : %d\n', paddedPayloadBits);
fprintf('Preamble bits           : %d\n', preambleBitsPerFrame);
fprintf('Total TX frame bits     : %d\n', totalFrameBits);
fprintf('OFDM symbols/frame      : %d\n', numOFDMSymbolsPerFrame);
fprintf('SNR (dB)                : %.1f\n', snr_dB);