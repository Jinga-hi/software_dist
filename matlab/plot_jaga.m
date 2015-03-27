function samples = plot_jaga(infile)

% Set these parameters in case this is a file without headers
nchans = 8;  % Number of channels
Fs = 1000;  % Sampling frequency
header_size = 20;

% IF you want the data to be filtered FILTER_DATA=1; otherwise =0; 
FILTER_DATA=0;
FH=3000    % High end of bandpass range
FL=300     % Low end of bandpass range
n_order=2  % Order of Butterworth filter

% Add your x axis (how many samples you want to read in) and the y axis
% (value of ADC)
 xmin = 0;
 xmax = 5000;
 

if FILTER_DATA
   ymin=-500;
   ymax=500;
else     
    ymin=0;
    ymax=65535;

    %ymin=21000;
    %ymax=41000;
end 


% peek into the file and extract channel count and sampling rate from the
% very 1st header
fid = fopen(infile,'rb');
x = fread(fid,header_size,'uint8=>uint8'); % read in as bytes
first_timestamp = typecast(x(1:8), 'double');
time_epoch = datenum('1970', 'yyyy'); 
time_string = time_epoch + first_timestamp / 86400.0;
time_string = datestr(time_string, 'yyyymmdd HH:MM:SS.FFF')
first_header = typecast(x(9:header_size),'uint16');
header_version = first_header(1)
possible_nchans = double(first_header(2));
fclose(fid);

if header_version == 0 & any (possible_nchans == [1 2 4 8 16]) 
    % This file does have headers, so use the read values
    nchans = possible_nchans
    Fs = double(first_header(4)); % sampling rate in Hz
    has_header = 1
else
    has_header = 0
end

% now that we know the channel count, we know how many samples per datagram.
if 16==nchans
    nsamples = 43;
elseif 8==nchans
    nsamples = 86;
elseif 4==nchans
    nsamples = 125;
elseif 2==nchans
    nsamples = 250;
elseif 1==nchans
    nsamples = 500;
end

% each UDP datagram consists of a 12-byte header and payload
payload_size = nchans*nsamples*2
datagram_size = payload_size + (has_header * header_size); % bytes

% now read all the data, in one fell swoop
fid = fopen(infile,'rb');
x = fread(fid,inf,'uint8=>uint8'); % read in as bytes
fclose(fid);
nbytes = numel(x);

% now march through each UDP datagram and remove the header info
ndatagrams = nbytes / datagram_size;

% allocate space for the payloads
payloads = zeros(ndatagrams*payload_size,1,'uint8');

% now march through each datagram and strip out the header
for ii=1:ndatagrams
    % indices into the data containing the header
    idx1 = (ii-1)*datagram_size + 1;
    idx2 = ii*datagram_size;
    % indices into the data with the header removed
    idx3 = (ii-1)*payload_size + 1;
    idx4 = ii*payload_size;
    
    payloads(idx3:idx4) = x(idx1+(has_header*header_size):idx2);
end

% now, cast to 16-bit and grab just the relevant samples out of the
% payloads
samples = typecast(payloads,'uint16');

% If we read a file with headers, save just the samples to a new file
if has_header
    [path,name,ext] = fileparts(infile);
    outfile = fullfile(path,[name '_no_headers.dat']);
    fid = fopen(outfile,'wb+');
    fwrite(fid,samples,'uint16');
    fclose(fid);
    % Read in the data with headers stripped
    %fid = fopen(outfile,'r');
    %samples=fread(fid, 'uint16','ieee-le');
    %fclose(fid)
end


if 16==nchans
    rows = 4;
    columns = 4;
elseif 8==nchans
    rows = 2;
    columns = 4;
elseif 4==nchans
    rows = 2;
    columns = 2;
elseif 2==nchans
    rows = 2;
    columns = 1;    
elseif 1==nchans
    rows = 1;
    columns = 1;
end

close all;

% FILTER_DATA process
if FILTER_DATA
fn=Fs/2;  % Nyquist Frequency
Freq_band=[FL,FH]/(Fs/2) %make a vector form out of FH, FL;
[b,a] = butter(n_order, Freq_band, 'bandpass');
end
% 


for i=1:nchans
    %subplot(rows, columns, i)
    subplot(columns, rows, i)

% data can be either filtered or not filtered.
       if FILTER_DATA
       data=filtfilt(b,a,double(samples(i:nchans:end)));
       else
       data = samples(i:nchans:end);
       end  
    
    plot((1:length(data)), data); 
    title(['Chan ' num2str(i)]);
    axis([xmin xmax ymin ymax])
    
end

figure;

% plot FFTs
% To reduce computational time comment out the FFT section
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

L = numel(samples)/nchans;
NFFT = 2^nextpow2(L);  % Shehrzad's version: 19872; 
% generate x-axis for FFT plots
f = Fs/2*linspace(0,1,NFFT/2+1);

for chan=1:nchans
    % Calculate FFT after removing the DC offset
    Y = fft(double(samples(chan:nchans:end) - mean(samples(chan:nchans:end))),NFFT);
    subplot(columns, rows, chan)
    plot(f,2*abs(Y(1:NFFT/2+1)));
    xlim([FL FH])
    title(['Chan ' num2str(chan)]);
    xlabel('Hz');
    ylabel('|Y(f)|');
    
end
%End of FFT
%section%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
