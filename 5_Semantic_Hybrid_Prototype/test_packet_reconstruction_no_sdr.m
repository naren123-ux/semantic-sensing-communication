% 03_test_packet_reconstruction_no_sdr.m
clear; clc; close all;

%% File names
payloadFile = "hybrid_payload_bytes.mat";
reconstructedVideo = "reconstructed_hybrid_no_sdr.mp4";
summaryFile = "packet_reconstruction_no_sdr_summary.txt";

%% Load payload
if ~isfile(payloadFile)
    error("Payload file not found. Run 02_create_sdr_payload.m first.");
end

load(payloadFile, "compressedBytes", "packetMatrix", "payloadLength", "numPackets");

fprintf("Loaded packetised payload.\n");
fprintf("Original payload size: %d bytes\n", numel(compressedBytes));
fprintf("Number of packets: %d\n", numPackets);

%% Reconstruct byte stream from packet matrix
recoveredBytes = packetMatrix(:);
recoveredBytes = recoveredBytes(1:numel(compressedBytes));

%% Write recovered bytes back to MP4
fid = fopen(reconstructedVideo, "wb");

if fid == -1
    error("Could not create reconstructed video file.");
end

fwrite(fid, recoveredBytes, "uint8");
fclose(fid);

%% Check byte accuracy
byteErrors = sum(compressedBytes ~= recoveredBytes);

fprintf("Reconstructed video saved as: %s\n", reconstructedVideo);
fprintf("Byte errors: %d\n", byteErrors);

if byteErrors == 0
    fprintf("Perfect reconstruction before SDR transmission.\n");
else
    fprintf("Reconstruction contains byte errors.\n");
end

%% Save summary
fid = fopen(summaryFile, "w");

fprintf(fid, "Packet reconstruction test without SDR\n");
fprintf(fid, "--------------------------------------\n\n");
fprintf(fid, "Payload file: %s\n", payloadFile);
fprintf(fid, "Reconstructed video: %s\n", reconstructedVideo);
fprintf(fid, "Original payload size: %d bytes\n", numel(compressedBytes));
fprintf(fid, "Payload per packet: %d bytes\n", payloadLength);
fprintf(fid, "Number of packets: %d\n", numPackets);
fprintf(fid, "Byte errors: %d\n", byteErrors);

if byteErrors == 0
    fprintf(fid, "Result: Perfect reconstruction before SDR transmission.\n");
else
    fprintf(fid, "Result: Reconstruction contains byte errors.\n");
end

fclose(fid);

fprintf("\nSaved files:\n");
fprintf("%s\n", reconstructedVideo);
fprintf("%s\n", summaryFile);