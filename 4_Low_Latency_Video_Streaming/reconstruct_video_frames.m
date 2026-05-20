clc;

if ~exist('videoBitsCell','var')
    error('Run prep_video_frames.m first');
end

% Keep a default packet in base workspace so Simulink Constant block resolves
assignin('base','txFrameBits',zeros(96,1));

packetBits = 96;   % OFDM packet payload in current model
repFactor = 3;     % repetition coding factor

recoveredFrames = cell(numFrames,1);

outputVideoFile = 'recovered_f1corner_better.avi';
writerObj = VideoWriter(outputVideoFile, 'Motion JPEG AVI');
writerObj.FrameRate = 5;
open(writerObj);

for k = 1:numFrames
    fprintf('\nProcessing frame %d / %d\n', k, numFrames);

    % Original source bits for this frame
    srcBits = double(videoBitsCell{k}(:));
    numSourceBits = length(srcBits);

    % Repetition encode
    txBitsEncoded = repelem(srcBits, repFactor);

    % Pad encoded stream to multiple of packet size
    remainder = mod(length(txBitsEncoded), packetBits);
    if remainder == 0
        padLen = 0;
    else
        padLen = packetBits - remainder;
    end

    txBitsPadded = [txBitsEncoded; zeros(padLen,1)];
    numPackets = length(txBitsPadded) / packetBits;

    fprintf('Original bits = %d, encoded bits = %d, padded bits = %d, packets = %d\n', ...
        numSourceBits, length(txBitsEncoded), length(txBitsPadded), numPackets);

    rxBitsRecovered = zeros(length(txBitsPadded),1);

    for p = 1:numPackets
        fprintf('  Packet %d / %d\n', p, numPackets);

        idxStart = (p-1)*packetBits + 1;
        idxEnd   = p*packetBits;

        txFrameBits = txBitsPadded(idxStart:idxEnd);
        txFrameBits = double(txFrameBits(:));
        assignin('base','txFrameBits',txFrameBits);

        out = sim('model7_video_qpsk_ofdm');

        rxBits = out.rxFrameBits;
        rxBits = double(rxBits(:));

        rxPacket = zeros(packetBits,1);
        L = min(packetBits, length(rxBits));
        rxPacket(1:L) = rxBits(1:L);

        rxBitsRecovered(idxStart:idxEnd) = rxPacket;
    end

    % Remove padding
    rxBitsRecovered = rxBitsRecovered(1:length(txBitsEncoded));

    % Majority vote decode
    rxBitsRecovered = rxBitsRecovered(:);
    usableLen = floor(length(rxBitsRecovered)/repFactor)*repFactor;
    rxBitsRecovered = rxBitsRecovered(1:usableLen);

    rxTriples = reshape(rxBitsRecovered, repFactor, []).';
    rxDecoded = sum(rxTriples, 2) >= 2;
    rxDecoded = double(rxDecoded(:));

    % Trim back to original frame bit count
    rxDecoded = rxDecoded(1:numSourceBits);

    % Convert bits back to pixels
    rxBytes = reshape(rxDecoded, 8, []).';
    rxPixels = bi2de(rxBytes, 'left-msb');

    if useGrayscale
        frameRec = uint8(reshape(rxPixels, targetHeight, targetWidth));

        % Optional smoothing for nicer appearance
        frameRec = medfilt2(frameRec, [3 3]);

        recoveredFrames{k} = frameRec;

        frameRGB = cat(3, frameRec, frameRec, frameRec);
        writeVideo(writerObj, frameRGB);
    else
        frameRec = uint8(reshape(rxPixels, targetHeight, targetWidth, 3));
        recoveredFrames{k} = frameRec;
        writeVideo(writerObj, frameRec);
    end

    fprintf('Frame %d complete\n', k);
end

close(writerObj);

assignin('base','recoveredFrames',recoveredFrames);

disp(['Recovered video written to: ' outputVideoFile])