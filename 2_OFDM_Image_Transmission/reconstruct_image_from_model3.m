clc;

% Read received bits from Simulink output
rx = out.rxBits;

% Convert received frames/matrix into one column bitstream
rx = rx(:);

% Trim to original transmitted length
rx = rx(1:length(txBits));

% Convert bits back to bytes
rxBitMatrix = reshape(rx, 8, []).';
rxBytes = uint8(bi2de(rxBitMatrix, 'left-msb'));

% Rebuild image
rxImg = reshape(rxBytes, [H W C]);

% BER calculation
numBitErrors = sum(txBits ~= rx);
ber = numBitErrors / length(txBits);

disp(['Bit errors = ' num2str(numBitErrors)]);
disp(['BER = ' num2str(ber)]);

figure;
subplot(1,2,1);
imshow(img);
title('Original');

subplot(1,2,2);
imshow(rxImg);
title('Recovered');