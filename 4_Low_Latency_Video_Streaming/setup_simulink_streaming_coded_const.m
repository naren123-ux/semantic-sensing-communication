clc;
clear;

% =========================================================
% Original payload
% =========================================================
payloadBitsPerFrame = 96;
preambleBitsPerFrame = 96;

txPayloadBits = randi([0 1], payloadBitsPerFrame, 1);

% =========================================================
% Known preamble
% =========================================================
basePattern = [1;0;1;0;0;1;1;0];
preambleBits = repmat(basePattern, 12, 1);   % 96 bits

% =========================================================
% Precompute Hamming-coded bits in MATLAB
% =========================================================
txCodedBits = zeros(168,1);

for k = 1:24
    idxIn = (k-1)*4 + 1;
    d = txPayloadBits(idxIn:idxIn+3);

    d1 = d(1);
    d2 = d(2);
    d3 = d(3);
    d4 = d(4);

    p1 = mod(d1 + d2 + d4, 2);
    p2 = mod(d1 + d3 + d4, 2);
    p3 = mod(d2 + d3 + d4, 2);

    cw = [p1; p2; d1; p3; d2; d3; d4];

    idxOut = (k-1)*7 + 1;
    txCodedBits(idxOut:idxOut+6) = cw;
end

% =========================================================
% Pad coded bits to 192
% =========================================================
txCodedBitsPadded = zeros(192,1);
txCodedBitsPadded(1:168) = txCodedBits;

% =========================================================
% Reference full frame
% =========================================================
txFrameBits = [preambleBits; txCodedBitsPadded];   % 288 bits total

% =========================================================
% OFDM settings
% =========================================================
fftLen = 64;
cpLen = 16;
numDataSubc = 48;
bitsPerQPSKSymbol = 2;
numOFDMSymbolsPerFrame = 3;
snr_dB = 30;

assignin('base','txPayloadBits',txPayloadBits);
assignin('base','txCodedBits',txCodedBits);
assignin('base','txCodedBitsPadded',txCodedBitsPadded);
assignin('base','preambleBits',preambleBits);
assignin('base','txFrameBits',txFrameBits);

assignin('base','payloadBitsPerFrame',payloadBitsPerFrame);
assignin('base','preambleBitsPerFrame',preambleBitsPerFrame);

assignin('base','fftLen',fftLen);
assignin('base','cpLen',cpLen);
assignin('base','numDataSubc',numDataSubc);
assignin('base','bitsPerQPSKSymbol',bitsPerQPSKSymbol);
assignin('base','numOFDMSymbolsPerFrame',numOFDMSymbolsPerFrame);
assignin('base','snr_dB',snr_dB);

disp('Coded-constant Simulink setup complete.');
fprintf('Original payload bits   : %d\n', payloadBitsPerFrame);
fprintf('Coded bits              : %d\n', length(txCodedBits));
fprintf('Padded coded bits       : %d\n', length(txCodedBitsPadded));
fprintf('Total TX frame bits     : %d\n', length(txFrameBits));
fprintf('SNR (dB)                : %.1f\n', snr_dB);