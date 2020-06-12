
% Jinga-hi,Inc.

% v.2.4.2 (This file has v.2.4.2) 
% 2/5/2014; REAL_UNIT can be read 
% 12/15/2014: Data will be read in a csv format.  The data will not be processed without DC removal.  

clear;
data=csvread('example_ts_matlab.csv');
%data=csvread('iljoob_2015-02-05_15-06-17_jaga_samplesml.csv');

% data_array (:,1) is the time in usec with a floting point since 1970. 
% It is a very larger number hard to plot.
% If you want the elapsed time since the first time staamp you can change it to data(:,1)-data(1,1)
% plot(data(:,1)-data(1,1),data(:,2))
% example of plot time elasped since the first time vs. channel 1.


% Information for a plot
nchans=16; %number of channels
sampling_rate=14035;
TTL_input=1;

REAL_UNIT=1; %If you want the voltage output rather than ADC value.
n_ave=100; 
LSB=0.17; %in uV unit
  
jaga_csv_data_array(:,1)=data(:,1)-data(1,1); %the elapsed time since the start of the experiement, not abolute timestamps
    
    for i=1:nchans
    jaga_csv_data_array(:,i+1)=data(:,i+1);
    end

    if REAL_UNIT
 for i=1:nchans
    yinitial_mean(i)=mean(jaga_csv_data_array(1:n_ave,i+1));   
 end  
    
 for i=1:nchans
      jaga_csv_data_real(:,i+1)=(jaga_csv_data_array(:,i+1)-yinitial_mean(:,i))*LSB; 
 end
    end 
    
%Example Plot (time and channel #1)

%    plot(jaga_csv_data_array(:,1), jaga_csv_data_array(:,2))
     plot(jaga_csv_data_array(:,1), jaga_csv_data_real(:,2)) % plot this if REAL_UNIT
    xlabel('Time(Sec)'); 
    ylabel('Voltage Output (uV)'); 
   
    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%