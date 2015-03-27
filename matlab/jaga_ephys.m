% jaga_ephys.m
% Copyright 2013-2015 Jinga-hi, Inc.
% v.2.4.1 is mostly for plot_jaga_data_array.m

% v.2.0.(no modifictation on this particular file since v.2.0)
% v2.0 2014-09-07
% Capture data from a JAGA device and write to disk.
% Optionally, display the data and/or filter during capture.

clc;
udprx('close');
clear functions
close all

% what version of the MEX are we running?
% port number for network
ver = udprx('version');
portno = 55000;

% USERS' INPUT PARAMETERS 
%=====================================================================================
%======================================================================================
% Directory to save data to.

SAVEDIR = '/Users/Mee/Desktop';

% If you want the date to be displayed 1, otherwise 0
% If you want the date to be filtered 1, otherwise 0

PLOT_DATA = 1;
FILTER_DATA = 0;

% Range of y axis
ymin=25000;
ymax=45000;

% number of channels to display
% tell the MEX how many channels there are, MEX shall return the # of
% samples per channel (per acquisition read)
nchans = 16;

% If you decided to filter, designate the upper and lower bound
fl = 2000; % lower edge of the passband (Hz)
fu = 3000; % upper edge of the passband (Hz)

%====================================================================================
%====================================================================================
%====================================================================================

clock = 24000000;

% display option
if nchans == 16
    Fs = clock / 57 / 30;
    rows = 4
    columns = 4
end
if nchans == 8
    Fs = clock / 60 / 20;
    rows = 2
    columns = 4
end

if nchans == 4
    Fs = clock / 60 / 20;
    rows = 2
    columns = 2
end

if nchans == 2
    Fs = clock / 60 / 20;
    rows = 2
    columns = 1
end


if nchans == 1
    Fs = clock / 60 / 20;
    rows = 1
    columns = 1
end

% End of display option


if FILTER_DATA % then we need to provide the filter coefficients
    %
    % design bandpass butterworth filter
    %
    %Fs = 62000000/260/22; % sampling rate example-defined up there.
    %fl = 2000; % lower edge of the passband (Hz)
    %fu = 3000; % upper edge of the passband (Hz)
    % if you have the signal-processing toolbox available, the following
    % function is equivalent to [b,a]=butter(2,[fl fu]./(Fs/2),'bandpass');
    
[b,a] = make_butter_bandpass(1/Fs, fl, fu);
end


PLOT_STROBE = 100; % how often to plot (in number of packets).  
%If you have less no. channels than 16 channel, then reduce this number. e.g 10 for 1 channel.

ndisplay = 10; % how many packets to plot at a time
% provide a directory into which the MEX shall store a binary file
% containing all of the samples.
% If you have less no. of channels than 16 channel, reduce this number.
% e.g. 1 for 1 channel


% establish connection between MATLAB and instrument
%
if FILTER_DATA
    nsamples = udprx('open', portno, nchans, SAVEDIR, b, a);
else
    nsamples = udprx('open', portno, nchans, SAVEDIR);
end
N = nsamples*nchans; % total number of samples per data packet
%
% setup the  plotting
%
if PLOT_DATA
    hfig = figure;
    set(hfig, 'Position', [200 1000 1000 1000])
    pause(0.1);
    max_samples = N * ndisplay;
    samplebuf = nan.*ones(1, max_samples);
    xaxis_range = [1 ndisplay*nsamples];
    yaxis_range = [ymin ymax];
end
%
% while (forever), keep acquiring, and periodically plot the data
%
packet_count = 0;
plot_index = 1;
while 1
    packet = udprx('read');
    if 1==numel(packet)
        if PLOT_DATA
            packet_count = packet_count + 1;
            if PLOT_STROBE - packet_count < ndisplay
                next_index = plot_index + N;
                samplebuf(plot_index:next_index-1) = packet.samples;
                plot_index = mod(next_index, max_samples);  % Wrap at max_samples
            end
            if 0==PLOT_STROBE || 0==mod(packet_count,PLOT_STROBE)
                packet_count = 0;
                % plot raw data
                for ichan=1:nchans
                    subplot(rows,columns,ichan);
                    plot(samplebuf(ichan:nchans:end))
                    xlim(xaxis_range);
                    ylim(yaxis_range);            
                end
                drawnow;
            end 
        end
    end            
end
% To terminate, press ^C at the command line
udprx('close');
clear functions
