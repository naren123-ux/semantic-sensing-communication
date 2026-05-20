clc;
clearvars -except videoFramesCell numFrames targetHeight targetWidth useGrayscale

if ~exist('videoFramesCell','var')
    error('Run prep_video_frames_diff.m first');
end

% =========================================================
% System parameters
% =========================================================
bitsPerQPSK = 2;
fftLen = 64;
cpLen  = 16;
numDataSubc = 48;
bitsPerOFDMSymbol = numDataSubc * bitsPerQPSK;   % 96 bits
snr_dB = 60;

% Coding/interleaving
interRows = 8;

% Difference-frame settings
% First frame: send full 8-bit grayscale
% Later frames: send signed pixel difference shifted by +255
% Difference range is [-255,255], so shifted range is [0,510]
% Needs 9 bits per pixel
keyFrameBitsPerPixel  = 8;
diffFrameBitsPerPixel = 9;

% Output
recoveredFrames = cell(numFrames,1);
outputVideoFile = 'recovered_f1corner_diff.avi';
writerObj = VideoWriter(outputVideoFile, 'Motion JPEG AVI');
writerObj.FrameRate = 10;
open(writerObj);

totalStart = tic;

prevFrameRec = [];

for k = 1:numFrames
    fprintf('\nProcessing frame %d / %d\n', k, numFrames);
    tFrame = tic;

    srcFrame = videoFramesCell{k};

    % -----------------------------------------------------
    % Build source bitstream
    % -----------------------------------------------------
    if k == 1
        % Key frame: raw grayscale pixels, 8 bits/pixel
        srcVals = double(srcFrame(:));
        srcBits = values_to_bits(srcVals, keyFrameBitsPerPixel);
        frameType = 'key';
        numBitsPerPixel = keyFrameBitsPerPixel;
    else
        % Difference frame: current - previous reconstructed
        diffVals = double(srcFrame(:)) - double(prevFrameRec(:));    % [-255,255]
        diffShifted = diffVals + 255;                                % [0,510]
        srcVals = diffShifted;
        srcBits = values_to_bits(srcVals, diffFrameBitsPerPixel);
        frameType = 'diff';
        numBitsPerPixel = diffFrameBitsPerPixel;
    end

    numSourceBits = length(srcBits);

    % -----------------------------------------------------
    % Hamming(7,4) encode
    % -----------------------------------------------------
    txBitsEnc = hamming74_encode(srcBits);

    % -----------------------------------------------------
    % Block interleave
    % -----------------------------------------------------
    txBitsInt = block_interleave(txBitsEnc, interRows);

    % -----------------------------------------------------
    % Pad to OFDM payload size
    % -----------------------------------------------------
    remBits = mod(length(txBitsInt), bitsPerOFDMSymbol);
    if remBits == 0
        padLen = 0;
    else
        padLen = bitsPerOFDMSymbol - remBits;
    end

    txBitsPad = [txBitsInt; zeros(padLen,1)];
    numPackets = length(txBitsPad) / bitsPerOFDMSymbol;

    % -----------------------------------------------------
    % Reshape bits into packets
    % -----------------------------------------------------
    txBitsMat = reshape(txBitsPad, bitsPerOFDMSymbol, numPackets);

    % -----------------------------------------------------
    % QPSK modulation
    % -----------------------------------------------------
    txQPSK = qpsk_mod_pi4_gray(txBitsMat(:));
    txQPSKMat = reshape(txQPSK, numDataSubc, numPackets);

    % -----------------------------------------------------
    % OFDM modulation
    % -----------------------------------------------------
    txWave = ofdm_modulate_batch(txQPSKMat, fftLen, cpLen);

    % -----------------------------------------------------
    % AWGN channel
    % -----------------------------------------------------
    rxWave = add_awgn(txWave, snr_dB);

    % -----------------------------------------------------
    % OFDM demodulation
    % -----------------------------------------------------
    rxQPSKMat = ofdm_demodulate_batch(rxWave, fftLen, cpLen, numPackets);

    % -----------------------------------------------------
    % QPSK demodulation
    % -----------------------------------------------------
    rxBits = qpsk_demod_pi4_gray(rxQPSKMat(:));

    % Remove OFDM padding
    rxBits = rxBits(1:length(txBitsInt));

    % -----------------------------------------------------
    % Deinterleave
    % -----------------------------------------------------
    rxBitsDeint = block_deinterleave(rxBits, interRows);

    % -----------------------------------------------------
    % Hamming decode
    % -----------------------------------------------------
    rxDecoded = hamming74_decode(rxBitsDeint);

    % Trim to exact source size
    rxDecoded = rxDecoded(1:numSourceBits);

    % -----------------------------------------------------
    % Bits -> values -> frame
    % -----------------------------------------------------
    rxVals = bits_to_values(rxDecoded, numBitsPerPixel);

    if k == 1
        % Key frame reconstruction
        frameRec = uint8(reshape(rxVals, targetHeight, targetWidth));
    else
        % Difference frame reconstruction
        rxDiff = double(rxVals) - 255;
        frameRecVec = double(prevFrameRec(:)) + rxDiff;
        frameRecVec = min(max(frameRecVec, 0), 255);
        frameRec = uint8(reshape(frameRecVec, targetHeight, targetWidth));
    end

    % Optional cleanup
    frameRec = simple_median_filter(frameRec);

    % Store and write
    recoveredFrames{k} = frameRec;
    prevFrameRec = frameRec;

    if useGrayscale
        frameRGB = cat(3, frameRec, frameRec, frameRec);
    else
        frameRGB = frameRec;
    end

    writeVideo(writerObj, frameRGB);

    % -----------------------------------------------------
    % Stats
    % -----------------------------------------------------
    srcFrameVec = double(srcFrame(:));
    recFrameVec = double(frameRec(:));

    mseVal = mean((srcFrameVec - recFrameVec).^2);

    fprintf('  Frame type        : %s\n', frameType);
    fprintf('  Source bits       : %d\n', numSourceBits);
    fprintf('  Encoded bits      : %d\n', length(txBitsEnc));
    fprintf('  OFDM packets      : %d\n', numPackets);
    fprintf('  MSE               : %.4f\n', mseVal);
    fprintf('  Frame time        : %.2f s\n', toc(tFrame));
end

close(writerObj);

assignin('base','recoveredFrames',recoveredFrames);

fprintf('\nDone. Total time = %.2f s\n', toc(totalStart));

% =========================================================
% Local functions
% =========================================================

function bits = values_to_bits(vals, numBits)
    vals = vals(:);
    bitsMat = de2bi(vals, numBits, 'left-msb');
    bits = reshape(bitsMat.', [], 1);
    bits = double(bits);
end

function vals = bits_to_values(bits, numBits)
    bits = bits(:);
    n = floor(length(bits)/numBits);
    bits = bits(1:n*numBits);
    bitsMat = reshape(bits, numBits, []).';
    vals = bi2de(bitsMat, 'left-msb');
end

function coded = hamming74_encode(bits)
    bits = bits(:);

    remLen = mod(length(bits), 4);
    if remLen ~= 0
        bits = [bits; zeros(4-remLen,1)];
    end

    data = reshape(bits, 4, []).';

    d1 = data(:,1);
    d2 = data(:,2);
    d3 = data(:,3);
    d4 = data(:,4);

    p1 = mod(d1 + d2 + d4, 2);
    p2 = mod(d1 + d3 + d4, 2);
    p3 = mod(d2 + d3 + d4, 2);

    codewords = [p1 p2 d1 p3 d2 d3 d4];
    coded = reshape(codewords.', [], 1);
end

function decoded = hamming74_decode(bits)
    bits = bits(:);

    n = floor(length(bits)/7);
    bits = bits(1:7*n);

    cw = reshape(bits, 7, []).';

    s1 = mod(cw(:,1) + cw(:,3) + cw(:,5) + cw(:,7), 2);
    s2 = mod(cw(:,2) + cw(:,3) + cw(:,6) + cw(:,7), 2);
    s3 = mod(cw(:,4) + cw(:,5) + cw(:,6) + cw(:,7), 2);

    syndrome = s1 + 2*s2 + 4*s3;

    for i = 1:size(cw,1)
        if syndrome(i) >= 1 && syndrome(i) <= 7
            cw(i, syndrome(i)) = mod(cw(i, syndrome(i)) + 1, 2);
        end
    end

    data = cw(:, [3 5 6 7]);
    decoded = reshape(data.', [], 1);
end

function y = block_interleave(x, rows)
    x = x(:);

    cols = ceil(length(x)/rows);
    padLen = rows*cols - length(x);
    xpad = [x; zeros(padLen,1)];

    mat = reshape(xpad, rows, cols);
    y = mat.';
    y = y(:);
end

function x = block_deinterleave(y, rows)
    y = y(:);

    cols = ceil(length(y)/rows);
    padLen = rows*cols - length(y);
    ypad = [y; zeros(padLen,1)];

    mat = reshape(ypad, cols, rows);
    mat = mat.';
    x = mat(:);

    x = x(1:length(y));
end

function symbols = qpsk_mod_pi4_gray(bits)
    bits = bits(:);

    if mod(length(bits),2) ~= 0
        bits = [bits; 0];
    end

    b = reshape(bits, 2, []).';
    symbols = zeros(size(b,1),1);

    for i = 1:size(b,1)
        if isequal(b(i,:), [0 0])
            symbols(i) = exp(1j*pi/4);
        elseif isequal(b(i,:), [0 1])
            symbols(i) = exp(1j*3*pi/4);
        elseif isequal(b(i,:), [1 1])
            symbols(i) = exp(1j*5*pi/4);
        else
            symbols(i) = exp(1j*7*pi/4);   % [1 0]
        end
    end
end

function bits = qpsk_demod_pi4_gray(symbols)
    symbols = symbols(:);

    ang = angle(symbols);
    ang(ang < 0) = ang(ang < 0) + 2*pi;

    ref = [pi/4, 3*pi/4, 5*pi/4, 7*pi/4];
    map = [0 0; 0 1; 1 1; 1 0];

    bits = zeros(2*length(symbols),1);

    for i = 1:length(symbols)
        d = abs(exp(1j*ang(i)) - exp(1j*ref));
        [~, idx] = min(d);
        bits(2*i-1:2*i) = map(idx,:).';
    end
end

function wave = ofdm_modulate_batch(dataSymbols, fftLen, cpLen)
    numDataSubc = size(dataSymbols,1);
    numPackets = size(dataSymbols,2);

    if fftLen ~= 64
        error('This version expects fftLen = 64.');
    end

    if numDataSubc ~= 48
        error('This version expects exactly 48 data subcarriers.');
    end

    % fftshift indexing, N = 64, DC index = 33
    dataIdx = [9:32 34:57];

    symLen = fftLen + cpLen;
    wave = zeros(symLen * numPackets, 1);

    ptr = 1;

    for p = 1:numPackets
        Xshift = zeros(fftLen,1);
        Xshift(dataIdx) = dataSymbols(:,p);

        X = ifftshift(Xshift);
        x = ifft(X, fftLen);

        xcp = [x(end-cpLen+1:end); x];
        wave(ptr:ptr+symLen-1) = xcp;
        ptr = ptr + symLen;
    end
end

function dataSymbols = ofdm_demodulate_batch(wave, fftLen, cpLen, numPackets)
    if fftLen ~= 64
        error('This version expects fftLen = 64.');
    end

    symLen = fftLen + cpLen;
    dataIdx = [9:32 34:57];

    dataSymbols = zeros(48, numPackets);

    ptr = 1;

    for p = 1:numPackets
        r = wave(ptr:ptr+symLen-1);
        r = r(cpLen+1:end);

        R = fft(r, fftLen);
        Rshift = fftshift(R);

        dataSymbols(:,p) = Rshift(dataIdx);

        ptr = ptr + symLen;
    end
end

function y = add_awgn(x, snr_dB)
    x = x(:);

    Px = mean(abs(x).^2);
    snrLin = 10^(snr_dB/10);
    noiseVar = Px / snrLin;

    n = sqrt(noiseVar/2) * (randn(size(x)) + 1j*randn(size(x)));
    y = x + n;
end

function out = simple_median_filter(img)
    [h, w] = size(img);
    out = img;

    for i = 2:h-1
        for j = 2:w-1
            block = img(i-1:i+1, j-1:j+1);
            out(i,j) = median(block(:));
        end
    end
end