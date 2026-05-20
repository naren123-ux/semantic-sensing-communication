clc;

% Take receive-filtered signal
x = out.rxFilt(:);

% Remove near-zero padding if present
x = x(abs(x) > 1e-6);

% For QPSK, raise to 4th power to remove modulation
x4 = x.^4;

% Estimate frequency offset from average phase increment
dphi = angle(conj(x4(1:end-1)) .* x4(2:end));
mean_dphi = mean(dphi);

Fs = 1e6;   % Pluto baseband sample rate
freqOffsetEst = (mean_dphi * Fs) / (2*pi*4);

disp(['Estimated coarse CFO = ' num2str(freqOffsetEst) ' Hz'])

% Correct the frequency offset
n = (0:length(x)-1).';
xCorr = x .* exp(-1j*2*pi*freqOffsetEst*n/Fs);

% Plot before correction
figure;
scatter(real(x(1:min(5000,end))), imag(x(1:min(5000,end))), '.');
grid on;
axis equal;
title('Before coarse CFO correction');

% Plot after correction
figure;
scatter(real(xCorr(1:min(5000,end))), imag(xCorr(1:min(5000,end))), '.');
grid on;
axis equal;
title('After coarse CFO correction');

% Now matched-filter output is still oversampled.
% Take every 4th sample as a rough quick-look symbol stream.
xDown = xCorr(1:4:end);

figure;
scatter(real(xDown(1:min(3000,end))), imag(xDown(1:min(3000,end))), '.');
grid on;
axis equal;
title('After coarse CFO correction and rough 4x downsample');