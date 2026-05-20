clear;
clc;

patternBits = repmat([0;0; 0;1; 1;1; 1;0], 200, 1);

assignin('base','patternBits',patternBits);

disp(['Pattern length = ' num2str(length(patternBits)) ' bits'])