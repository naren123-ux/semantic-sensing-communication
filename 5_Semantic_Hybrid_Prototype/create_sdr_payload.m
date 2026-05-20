% 02_create_sdr_payload.m
clear; clc; close all;

%% File names
hybridVideo = "hybrid_256_ai_compressed.mp4";
payloadFile = "hybrid_payload_bytes.mat";
summaryFile = "sdr_payload_summary.txt";

%% Read compressed video as binary byte payload
fid = fopen(hybridVideo, "rb");

if fid == -1
    error("Could not open hybrid video file. Run 01_create_hybrid_video.m first.");
end

compressedBytes = fread(fid, inf, "uint8");
fclose(fid);

payloadSizeBytes = numel(compressedBytes);

fprintf("Compressed video converted to byte payload.\n");
fprintf("Payload size: %d bytes\n", payloadSizeBytes);

%% Packetise payload
payloadLength = 500; % bytes per packet

numPackets = ceil(payloadSizeBytes / payloadLength);
packetMatrix = zeros(payloadLength, numPackets, "uint8");

for p = 1:numPackets
    startIndex = (p - 1) * payloadLength + 1;
    endIndex = min(p * payloadLength, payloadSizeBytes);

    packetData = compressedBytes(startIndex:endIndex);
    packetMatrix(1:numel(packetData), p) = packetData;
end

fprintf("Number of packets: %d\n", numPackets);
fprintf("Payload per packet: %d bytes\n", payloadLength);

%% Save payload for SDR transmission
save(payloadFile, "compressedBytes", "packetMatrix", "payloadLength", "numPackets");

%% Save summary
fid = fopen(summaryFile, "w");

fprintf(fid, "SDR payload preparation summary\n");
fprintf(fid, "-------------------------------\n\n");
fprintf(fid, "Hybrid compressed video: %s\n", hybridVideo);
fprintf(fid, "Payload size: %d bytes\n", payloadSizeBytes);
fprintf(fid, "Payload per packet: %d bytes\n", payloadLength);
fprintf(fid, "Number of packets: %d\n", numPackets);
fprintf(fid, "Saved payload file: %s\n", payloadFile);

fclose(fid);

fprintf("\nSaved files:\n");
fprintf("%s\n", payloadFile);
fprintf("%s\n", summaryFile);