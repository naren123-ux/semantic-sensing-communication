clear;
clc;
rng(42);   % fixed seed so payload is repeatable

% Known preamble: 64 bits, less repetitive than before
preambleBits = [
    1;1;0;1;0;0;1;1;
    0;1;1;0;1;0;0;1;
    1;0;0;1;1;1;0;0;
    0;0;1;1;0;1;1;0;
    1;0;1;1;0;0;1;0;
    0;1;0;0;1;1;1;0;
    1;1;0;0;1;0;1;1;
    0;0;1;0;1;1;0;1
];

% Random but repeatable payload: 200 bits
payloadBits = randi([0 1], 200, 1);

% One frame = preamble + payload
singleFrameBits = [preambleBits; payloadBits];

% Repeat frame many times so loops can settle
numRepeats = 50;
txFrameBits = repmat(singleFrameBits, numRepeats, 1);

% Push to base workspace for Simulink
assignin('base','preambleBits',preambleBits);
assignin('base','payloadBits',payloadBits);
assignin('base','singleFrameBits',singleFrameBits);
assignin('base','txFrameBits',txFrameBits);
assignin('base','numRepeats',numRepeats);

disp(['Preamble length = ' num2str(length(preambleBits)) ' bits'])
disp(['Payload length = ' num2str(length(payloadBits)) ' bits'])
disp(['Single frame length = ' num2str(length(singleFrameBits)) ' bits'])
disp(['Repeated TX length = ' num2str(length(txFrameBits)) ' bits'])
disp(['Number of repeats = ' num2str(numRepeats)])