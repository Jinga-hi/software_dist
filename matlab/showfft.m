function showfft ( data, sampling_rate )
% Do an FFT plot of the input data at the
% given sampling rate.
Fs = sampling_rate;
T = 1/Fs;                     % Sample time
L = numel(data);                     % Length of signal
t = (0:L-1)*T;                % Time vector
NFFT = 2^nextpow2(L); % Next power of 2 from length of y
Y = fft(data,NFFT)/L;
f = Fs/2*linspace(0,1,NFFT/2+1);

% Plot single-sided amplitude spectrum.
plot(f,2*abs(Y(1:NFFT/2+1))) 
title('Single-Sided Amplitude Spectrum')
xlabel('Frequency (Hz)')
ylabel('|Y(f)|')

end

