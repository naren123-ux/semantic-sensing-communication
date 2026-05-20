clc;

% Known transmitted pattern
txBits = patternBits(:);

% Logged receive-filtered samples
x = out.rxFilt(:);

% Remove tiny padded values if present
x = x(abs(x) > 1e-8);

% Parameters
sps = 4;
rots = [1, 1j, -1, -1j];
rotNames = {'0 deg','90 deg','180 deg','270 deg'};

bestBER = inf;
bestOffset = NaN;
bestRotation = '';
bestRxBits = [];
bestSyms = [];

for offset = 1:sps
    z = x(offset:sps:end);

    for r = 1:4
        zr = z * rots(r);

        rxBitsTest = zeros(2*length(zr),1);

        for k = 1:length(zr)
            ang = angle(zr(k));
            if ang < 0
                ang = ang + 2*pi;
            end

            % Hard-decision mapping for pi/4 Gray QPSK assumption
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

        L = min(length(txBits), length(rxBitsTest));
        [~, ber] = biterr(txBits(1:L), rxBitsTest(1:L));

        fprintf('Offset %d, Rotation %s, BER = %.4f\n', offset, rotNames{r}, ber);

        if ber < bestBER
            bestBER = ber;
            bestOffset = offset;
            bestRotation = rotNames{r};
            bestRxBits = rxBitsTest;
            bestSyms = zr;
        end
    end
end

fprintf('\nBest offset = %d\n', bestOffset);
fprintf('Best rotation = %s\n', bestRotation);
fprintf('Best BER = %.4f\n', bestBER);

% Plot best recovered symbol stream
figure;
scatter(real(bestSyms(1:min(4000,end))), imag(bestSyms(1:min(4000,end))), '.');
grid on;
axis equal;
title(sprintf('Best offline symbol stream: offset %d, rotation %s', bestOffset, bestRotation));
xlabel('I');
ylabel('Q');