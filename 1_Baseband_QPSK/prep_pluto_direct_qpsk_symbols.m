clear;
clc;

syms = exp(1j*pi/4) * [1; 1j; -1; -1j];
txSymbols = repmat(syms, 1000, 1);

assignin('base','txSymbols',txSymbols);

disp(['Number of symbols = ' num2str(length(txSymbols))])