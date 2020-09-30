function dataOut = butterworth(dataIn,fs,fc)
[b,a] = butter(6,fc/(fs/2));
dataOut = filter(b,a,dataIn);
end