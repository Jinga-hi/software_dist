
% Jinga-hi,Inc.
% Downloadable with v.2.4 plot_jaga_data_array.m

% v.2.4.1 is mostly for plot_jaga_data_array.m
% v.2.0.(no modifictation on this particular file)
% v.2.0
% Generate data_array from JAGA recording. Import jaga_samples.dat and
% create a data_array. No plotting. 

clear;
infile='2015-02-10_18-22-34_jaga_samples.dat';

% Remove Header and covert this into a data array
% Header info==============================================================
header_size=10;

fid0 = fopen(infile, 'r');
x=fread(fid0,'uint16','ieee-le');
numel(x)
fclose(fid0);

if x(7)==32784   % Figure out whether TTL is on
    TTL_DATA=1;

else
    TTL_DATA=0;
end

nchans=x(6)   % Number of channels 
sampling_rate=x(8);  % Sampling_rate
%==========================================================================


% data format
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


if 16==nchans
    % 43/8=5.3 -> 6 bytes -> 3 uint16 values
    ttldata_size= 3;
elseif 8==nchans
    % 86/8=10.75 -> 11 -> 6 uint16 values
    ttldata_size= 6;
elseif 4==nchans
    %125/8=15.6 -> 16 -> 8 uint16 values
    ttldata_size= 8;
elseif 2==nchans
    % 250/8=31.25 -> 32 -> 16 uint16 values
    ttldata_size= 16;
elseif 1==nchans
    % 500/8=62.5 -> 63 -> 32 uint16 values
    ttldata_size= 32;
end

if not(TTL_DATA)
    ttldata_size=0;
end


sample_size=nchans*nsamples;
bu_size=header_size+sample_size+ttldata_size;
% as an example: 518 for 4 channels TTL= 10 header + 125*4 samplesize + 8 values read in 16
% bit
ifinal=numel(x)/bu_size-1;

% nrepeat=0;
% nstart=nrepeat*bu_size+1;
% nend=nstart+bu_size-1;
% 
% y=x(nstart:nend);   %One block data-header-sample-ttl
% y1=y(nstart:nstart+header_size-1);
% y2=y(header_size+1:header_size+sample_size);
% y3=y(nend-ttldata_size+1:nend);

y2 = [];
y3 = [];
for i=0:ifinal

nstart=i*bu_size+1;
nend=nstart+bu_size-1;

  y=x(nstart:nend); %another chuck of datagram (header+samples+TTL data)

  %for j=1:header_size  %Don't repeat header values
  %     y1(end+1)=y(j);
  %end
  
  for k=header_size+1:header_size+sample_size;
      y2(end+1)=y(k);
  end
  
  % ttl_data_byte_swap
  bits_read = 0;
  for l=header_size+sample_size+1:numel(y)
     
%      for m=16:-1:1
%            yswap = swapbytes(uint16(y(l)));
%            y3(end+1)=bitget(yswap, m);
%           bits_read = bits_read + 1;
%           if mod(bits_read, nsamples) == 0
%               break
%           end
%      end
%%%%%%%%%%%%%%%%%%Faster way to construct the TTL bit  %%%%%%%%%%%%%%%%%%%
       for m=8:23
           bits_read = bits_read + 1;
           if mod(bits_read, nsamples) == 0
               break
           end  % if mod
           y3(end+1) = bitget(y(l), mod(15-m, 16) + 1);  % 8->1, then 16->9
           %y3(end+1) = bitget(y(l), m);
       end % for m
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%  

  end
end
   
% WINDOW SET UP
if 16==nchans
    rows = 4;
    columns = 4;
elseif 8==nchans
    rows = 4;
    columns = 2;
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

%  Converting the samples into a data-array
    array_length=length(y2)/nchans;
    data_array=zeros(array_length,nchans);
    size(data_array)
    data_array(:,1)=(1:array_length);
    
    for i=1:nchans
    data_array(:,i)=y2(i:nchans:end);
    end
    
    samples = data_array;
    
   
