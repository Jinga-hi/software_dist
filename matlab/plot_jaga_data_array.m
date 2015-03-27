
% Jinga-hi,Inc.
% 12/15/2014: v.2.4.1 
%
% TTL data is included. TTL was Read into y3 and display into a separate
% window TTL_DATA

% Samples(data_array) were read in for a plot. 
% Plot options are given. TRUNC_DATA, FFT_DATA, FILTER_DATA
% Other data_array will be generated: data_array_filtered (if it is filtered), data_array_truc (if the data is truncated),
% data_array_real_unit (if the data is displayed in real unit)

% Variables inherited from generate_jaga_data_array.m ; 
% =data_array, samples, nchans, sampling_rate


% PLOT_OPTIONS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
TTL_DATA=0;    % 1 if TTL info is in the data stream. 
TRUNC_DATA=0;  % 1 if you want to truncate the data samples to plot, if the array size is large, otherwise =0;

FFT_DATA=1;    %1 if you want to display FFT as well, otherwise=0;

FILTER_DATA=0; %IF you want the data to be filtered FILTER_DATA=1; otherwise =0; 
FL=300;     % Low end of bandpass range
FH=3000;    % High end of bandpass range
n_order=2;  % Order of Butterworth filter

REALUNIT_DATA=0;   % 1 if you want to display data in sec in x_axis and voltage value in y_axis. 
               % Otherwise, the x_axis is number of samples and y_axis is
               % ADC value
                             
% DATA_TRUNCATION OPTIONS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Truncate the size of the data

if TRUNC_DATA
    
     n_start=1;  % starting number of data points you want to read in   
     n_end=10000; % starting number of data points you want to read in 
            % if n_end-n_start is sampling frequency, then it is 1 sec of
            % data. 
            % If you want to use all data point, nstart=1,
            % n_end=length(data_array) can be used.
            
     data_array_trunc=data_array(n_start:n_end,:); 
     ttl_array_truc=y3(n_start:n_end);
           
   
else
     n_start=1;
     n_end=length(data_array);
        %if you don't truncate the data, data_array is copied to
        %data_array_trunc anyway
        %n_end(data_array) should be the same as length(y3)-currently has
        %some problems.
     
     data_array_trunc=data_array(n_start:n_end,:); 
     ttl_array_truc=y3(n_start:length(y3));

end
       
% DISPLAY REAL UNIT OPTION
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Average the first number of samples to find the average-a very very crude way
% to remove DC. One can implement a better way to remove DC e.g. single-pole

if REALUNIT_DATA
  nsample_ave=100; 
  LSB=0.17; %in uV unit
  array_length=length(data_array_trunc);

 for i=1:nchans
    yinitial_mean(i)=mean(data_array_trunc(1:array_length,i));   
 end  
    
 for i=1:nchans
      data_array_real_unit=(data_array_trunc-yinitial_mean(:,i))*LSB; 
 end
 
   
end
% SIGNAL_RANGE_OPTION
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


if not(REALUNIT_DATA)
   xmin =n_start; %axis[(xmin,xmax,ymin,ymax)is initially commented out in line 198.  To specify, remove %
   xmax =n_end;
   ymin =0;   %data range more relevant for neural signals
   ymax =63000;

else
   xmin =n_start*1000/sampling_rate;  %convert the sample data into time by dividing the sample counts by sampling_rate%
   xmax =n_end*1000/sampling_rate;
   ymin =-1000;                     %data range more relevant for neural signals
   ymax =1000;
    
end

if FILTER_DATA
   xmin=0;    %sec in x-axis and y-axis
   xmax=10;
   ymin=-250;
   ymax=250 
end


if FFT_DATA
xminff =FL;
xmaxff =FH;
yminff =0;  %data range more relevant for neural signals
ymaxff =100;
end 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   

% DISPLAY WINDOW SET UP
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


%PLOT_TTL_INFO ONLY WHEN TTL DATA Is INCORPORATE %%%%%%%%%%%%%%%%%%%%%%%%%

if TTL_DATA
    
 if not(REALUNIT_DATA)
    tFig = figure;
    set(tFig, 'Position', [200 1000 700 700])
    plot(ttl_array_truc)
    
 else
    tFig = figure;
    set(tFig, 'Position', [200 1000 700 700])
     
    x1=(n_start:length(y3))*1000/sampling_rate; %real unit in msec
    plot(x1,ttl_array_truc); %data value is TTL on/off
    ylim([-3 3]);
    xlabel('Time (msec)'); 
    ylabel('Digital Output of TTL '); 
 end
 
end    

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 

% PLOT_TIME_SERIES
if not(REALUNIT_DATA)
    
    hFig = figure;
    set(hFig, 'Position', [200 1000 700 700])
    plot(data_array_trunc(:,i))
    
 for i=1:nchans
    subplot (rows,columns, i) 
    
     if FILTER_DATA 
        data_array_filtered(:,i)=filtfilt(b,a,double(data_array_trunc(:,i)));
        plot(data_array_filtered(:,i))
     else 
        plot(data_array_trunc(:,i))     
             
  xlabel('Count or Sec'); 
  ylabel('Digital Output or uV '); 
  title(['Channel ' num2str(i)]);
  axis([xmin xmax ymin ymax])
     end
 end
end

 
if REALUNIT_DATA
   hFig = figure;
   set(hFig, 'Position', [200 1000 700 700])
   x1=(n_start:n_end)*1000/sampling_rate; %real unit in msec
   
  for i=1:nchans
    subplot (rows,columns, i) 
    
     if FILTER_DATA 
        data_array_filtered(:,i)=filtfilt(b,a,double(data_array_trunc(:,i)));
        plot(data_array_filtered(:,i))
    
     else    
     plot(x1,data_array_real_unit(:,i)*LSB); %data is 
    
     xlabel('Time(msec)'); 
     ylabel('Voltage Input (uV)'); %If it is filtered, uV scale may not be correct
     title(['Channel ' num2str(i)]);
     %axis([xmin xmax ymin ymax])
     end
   
  end
end
    

%PLOT_FFT
% SAMPLING_RATE and coefficients for FILTER_DATA
if FFT_DATA
Fs=sampling_rate;     
fn=Fs/2;  % Nyquist Frequency
Freq_band=[FL,FH]/(Fs/2); %make a vector form out of FH, FL;
[b,a] = butter(n_order, Freq_band, 'bandpass');

gFig=figure;
set(gFig, 'Position', [200 1000 700 700])

  for i=1:nchans
    
    subplot (rows,columns, i) 
    
     if FILTER_DATA
        data_filtered(:,i)=filtfilt(b,a,double(data_array_trunc(:,i)));
        dataf = data_array_filtered(:,i);  
        showfft(dataf-mean(dataf),sampling_rate)
        axis([xminff, xmaxff, yminff, ymaxff])
     else 
        dataf = data_array_trunc(:,i); 
        showfft(dataf-mean(dataf),sampling_rate)
        axis([xminff, xmaxff, yminff, ymaxff])
     end 
    
   end  
end   