clc;

txPreamble = preambleBits(:);
txPayload  = payloadBits(:);

% Fixed-size logged signals
tx = out.txBits(:);
rxRaw = out.rxRaw(:);
rxFilt = out.rxFilt(:);

disp(['Raw RX power = ' num2str(mean(abs(rxRaw).^2))])
disp(['RRC RX power = ' num2str(mean(abs(rxFilt).^2))])

figure;
scatter(real(rxRaw(1:min(3000,end))), imag(rxRaw(1:min(3000,end))), '.');
grid on;
axis equal;
title('Raw Pluto RX');

figure;
scatter(real(rxFilt(1:min(3000,end))), imag(rxFilt(1:min(3000,end))), '.');
grid on;
axis equal;
title('After RX RRC');

% Variable-size logged signals
vsym = out.rxSym.signals.values(:);
vsym = vsym(abs(vsym) > 1e-3);

figure;
scatter(real(vsym(1:min(5000,end))), imag(vsym(1:min(5000,end))), '.');
grid on;
axis equal;
title('After Symbol Synchronizer');

vsync = out.rxSync.signals.values(:);
vsync = vsync(abs(vsync) > 1e-3);

disp(['Mean |rxSym|^2 = ' num2str(mean(abs(vsym).^2))])
disp(['Mean |rxSync|^2 = ' num2str(mean(abs(vsync).^2))])

% Clipped display version just for easier viewing
vsyncPlot = vsync(abs(vsync) < 5);

figure;
scatter(real(vsyncPlot(1:min(5000,end))), imag(vsyncPlot(1:min(5000,end))), '.');
grid on;
axis equal;
title('After Carrier Synchronizer (clipped display)');

% Test all 4 QPSK rotations
rots = [1, 1j, -1, -1j];
rotNames = {'0 deg','90 deg','180 deg','270 deg'};

bestOverallScore = -1;
bestOverallBER = inf;
bestOverallRotation = '';
bestOverallIdx = NaN;

for r = 1:4
    z = vsync * rots(r);

    % Hard-decision QPSK demod with pi/4 Gray mapping assumption
    rxBitsTest = zeros(2*length(z),1);

    for k = 1:length(z)
        ang = angle(z(k));
        if ang < 0
            ang = ang + 2*pi;
        end

        if ang >= 0 && ang < pi/2
            bits = [0;0];
        elseif ang >= pi/2 && ang < pi
            bits = [0;1];
        elseif ang >= pi && ang < 3*pi/2
            bits = [1;1];
        else
            bits = [1;0];
        end

        rxBitsTest(2*k-1:2*k) = bits;
    end

    % Find best preamble location first
    bestScore = -1;
    bestIdx = 1;

    for k = 1:length(rxBitsTest)-length(txPreamble)+1
        score = sum(rxBitsTest(k:k+length(txPreamble)-1) == txPreamble);
        if score > bestScore
            bestScore = score;
            bestIdx = k;
        end
    end

    payloadStart = bestIdx + length(txPreamble);
    payloadEnd   = payloadStart + length(txPayload) - 1;

    fprintf('\nRotation %s\n', rotNames{r});
    fprintf('Best preamble score = %d\n', bestScore);
    fprintf('Best preamble start = %d\n', bestIdx);

    if payloadEnd <= length(rxBitsTest)
        rxPayload = rxBitsTest(payloadStart:payloadEnd);
        [numErr, ber] = biterr(txPayload, rxPayload);

        fprintf('Payload bit errors = %d\n', numErr);
        fprintf('Payload BER = %.4f\n', ber);

        if bestScore > bestOverallScore || (bestScore == bestOverallScore && ber < bestOverallBER)
            bestOverallScore = bestScore;
            bestOverallBER = ber;
            bestOverallRotation = rotNames{r};
            bestOverallIdx = bestIdx;
        end
    else
        fprintf('Not enough bits for payload extraction\n');
    end
end

fprintf('\nBest overall rotation = %s\n', bestOverallRotation);
fprintf('Best overall score = %d\n', bestOverallScore);
fprintf('Best overall frame start = %d\n', bestOverallIdx);
fprintf('Best overall payload BER = %.4f\n', bestOverallBER);