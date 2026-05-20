clc;

rxRaw = out.rxRaw(:);
rxFilt = out.rxFilt(:);

disp(['Raw RX power = ' num2str(mean(abs(rxRaw).^2))])
disp(['RRC RX power = ' num2str(mean(abs(rxFilt).^2))])

figure;
scatter(real(rxRaw(1:min(4000,end))), imag(rxRaw(1:min(4000,end))), '.');
grid on;
axis equal;
title('Raw Pluto RX');

figure;
scatter(real(rxFilt(1:min(4000,end))), imag(rxFilt(1:min(4000,end))), '.');
grid on;
axis equal;
title('After RX RRC');

vsym = out.rxSym.signals.values(:);
vsym = vsym(abs(vsym) > 1e-6);

figure;
scatter(real(vsym(1:min(4000,end))), imag(vsym(1:min(4000,end))), '.');
grid on;
axis equal;
title('After Symbol Synchronizer');

vsync = out.rxSync.signals.values(:);
vsync = vsync(abs(vsync) > 1e-6);
vsyncPlot = vsync(abs(vsync) < 5);

figure;
scatter(real(vsyncPlot(1:min(4000,end))), imag(vsyncPlot(1:min(4000,end))), '.');
grid on;
axis equal;
title('After Carrier Synchronizer');

disp(['Mean |rxSym|^2 = ' num2str(mean(abs(vsym).^2))])
disp(['Mean |rxSync|^2 = ' num2str(mean(abs(vsync).^2))])