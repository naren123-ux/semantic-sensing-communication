% 04_simulate_packet_loss.m
clear; clc; close all;

%% File names
payloadFile = "hybrid_payload_bytes.mat";
lostVideo = "reconstructed_hybrid_with_packet_loss.mp4";
summaryFile = "packet_loss_summary.txt";

%% Load payload
if ~isfile(payloadFile)
    error("Payload file not found. Run 02_create_sdr_payload.m first.");
end

load(payloadFile, "compressedBytes", "packetMatrix", "payloadLength", "numPackets");

%% Simulate packet loss
packetLossRate = 0.05; % 5 percent packet loss

receivedPackets = packetMatrix;
lostPackets = rand(1, numPackets) < packetLossRate;

receivedPackets(:, lostPackets) = 0;

lostPacketCount = sum(lostPackets);
packetRecoveryRate = (1 - lostPacketCount / numPackets) * 100;

fprintf("Simulated packet loss test:\n");
fprintf("Packet loss rate: %.2f %%\n", packetLossRate * 100);
fprintf("Lost packets: %d out of %d\n", lostPacketCount, numPackets);
fprintf("Packet recovery rate: %.2f %%\n", packetRecoveryRate);

%% Reconstruct damaged byte stream
recoveredBytes = receivedPackets(:);
recoveredBytes = recoveredBytes(1:numel(compressedBytes));

%% Save damaged video
fid = fopen(lostVideo, "wb");

if fid == -1
    error("Could not create packet loss video file.");
end

fwrite(fid, recoveredBytes, "uint8");
fclose(fid);

%% Byte error count
byteErrors = sum(compressedBytes ~= recoveredBytes);

fprintf("Packet loss video saved as: %s\n", lostVideo);
fprintf("Byte errors after packet loss: %d\n", byteErrors);

%% Save summary
fid = fopen(summaryFile, "w");

fprintf(fid, "Packet loss simulation summary\n");
fprintf(fid, "------------------------------\n\n");
fprintf(fid, "Payload file: %s\n", payloadFile);
fprintf(fid, "Damaged reconstructed video: %s\n", lostVideo);
fprintf(fid, "Packet loss rate: %.2f %%\n", packetLossRate * 100);
fprintf(fid, "Lost packets: %d out of %d\n", lostPacketCount, numPackets);
fprintf(fid, "Packet recovery rate: %.2f %%\n", packetRecoveryRate);
fprintf(fid, "Byte errors after packet loss: %d\n", byteErrors);

fprintf(fid, "\nNote:\n");
fprintf(fid, "Compressed MP4 files can be sensitive to packet loss because damage to header, index or prediction data may prevent correct decoding.\n");

fclose(fid);

fprintf("\nSaved files:\n");
fprintf("%s\n", lostVideo);
fprintf("%s\n", summaryFile);