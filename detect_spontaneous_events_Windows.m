%% Detect spontaneous activation events at an electrode
%% Do it seprately for independent 100-sec windows that are classified as low/high FC within run based on <0.1 Hz HFB FC

condition=input('Rest (1) gradCPT (2): ','s');

if condition=='1'
    condition='Rest';
elseif condition=='2'
    condition='gradCPT';
end
%% Defaults
chop_sec=60; % number of seconds to chop from beginning of time series (to avoid filter edge effect)
window_length=100; % number of seconds per independent windows
act_prctile=5; % percentile for activation definition
cluster_size=20; % minimum number of consecutive samples (i.e., msecs) needed for event definition
time_gap=500; % minimum number of msec between consecutive events
srate=1000; % sampling rate (Hz)
getECoGSubDir; global globalECoGDir;

%% Load electrode time series
sub=input('Patient: ','s');
run_num=input('Run (e.g. 1): ','s');
electrode1=input('Electrode number (for spontaneous activations): ','s');
electrode2=input('Electrode number (for defining high/low FC windows): ','s');
electrode1=str2num(electrode1); electrode2=str2num(electrode2);

%% Load slow <0.1 Hz HFB file and electrode time series
cd([globalECoGDir filesep condition filesep sub filesep 'Run' run_num]);
    filenames=dir('slow*');
        for i=1:length(filenames)
        curr_name=filenames(i).name;
        if ~isempty(strfind(curr_name,'HFB'))
            filename=curr_name;
        end
        end
        D=spm_eeg_load(filename);
        
%% Extract FC in independent 100-sec windows 
            if chop_sec~=0
    chop_samples=chop_sec*srate;
    else
        chop_samples=1;
            end   
            % delete first 30 seconds
 elec1_ts=D(electrode1,chop_samples:size(D,2))';   
 elec2_ts=D(electrode2,chop_samples:size(D,2))';  
 
 elec1_ts_norm=(elec1_ts-mean(elec1_ts))/std(elec1_ts);
 elec2_ts_norm=(elec2_ts-mean(elec2_ts))/std(elec2_ts);

 samples_per_window=window_length*srate;
 num_windows=floor(length(elec1_ts_norm)/samples_per_window);
 start_sample=1;
 for i=1:num_windows 
     window_elec1_ts=elec1_ts_norm(start_sample:start_sample+samples_per_window);
     window_elec2_ts=elec2_ts_norm(start_sample:start_sample+samples_per_window);
     window_FC(i,:)=corr(window_elec1_ts,window_elec2_ts);
     window_start_indices(i,:)=start_sample;
     start_sample=start_sample+samples_per_window;
 end
 pause    
 
 %% Get start indices of windows with low FC (lower than median value)
 window_start_indices(find(window_FC<median(window_FC)));
 
 
%% Load smoothed HFB (unfiltered) time series for electrode to use for spActivations
% delete first 30 secs
  D=spm_eeg_load;
  elec_ts=D(electrode1,chop_samples:size(D,2))'; 
elec_name=char(D.chanlabels(electrode1));      
    
%% Detect top act_prctile time points
act_peaks=find(elec_ts>prctile(elec_ts,100-act_prctile));
act_peaks_to_plot=NaN(length(elec_ts),1);
act_peaks_to_plot(act_peaks)=0;

%% Define clusters of activation time points
diff_act_peaks=diff(act_peaks);

% find cluster onsets
for i=1:length(diff_act_peaks) 
    if i==1
        onsets(i)=NaN;
    elseif diff_act_peaks(i)==1 && diff_act_peaks(i-1)~=1
        onsets(i)=1;
    else
        onsets(i)=NaN;
    end
end
% pad the onsets time series with NaNs at the end
diff_act_peaks=[diff_act_peaks NaN(1,cluster_size)];

% remove short clusters (using cluster_size)
for i=1:length(onsets)
    if onsets(i)==1
      cluster_check=diff_act_peaks(i:i+cluster_size-1); 
      if sum(cluster_check)==cluster_size;
          cluster_onsets(i)=1;
      else
          cluster_onsets(i)=NaN;
      end
    else
        cluster_onsets(i)=NaN;
    end
end

% remove clusters that are too close in time (using time_gap)
cluster_onsets_time=act_peaks(cluster_onsets==1);
cluster_distances=diff(cluster_onsets_time);
isolated_cluster_ind=find(cluster_distances>time_gap);
isolated_cluster_onsets=cluster_onsets_time(isolated_cluster_ind+1);

n_events=length(isolated_cluster_onsets)

%% TO ADD
%% Get clusters that are within low correlation windows for <0.1 Hz FC

% save onsets to events.mat file for epoching
event_onsets=isolated_cluster_onsets/srate;
events.categories(1).name=[elec_name ' Activations'];
events.categories(1).categNum=1;
events.categories(1).numEvents=length(event_onsets);
events.categories(1).start=event_onsets;
events.categories(1).duration=[ones(length(event_onsets),1)*.05]'; % Set all durations to .05 sec
events.categories(1).stimNum=1:length(event_onsets);
save_name=(['events_' elec_name]);
save(save_name,'events');

% Epoch
events_file=['events_' elec_name '.mat'];
epoch_name=['e' elec_name];
LBCN_epoch_bc(D,events_file,[],'start',[-1000 1500],0,[],[],epoch_name);

% plot 10 random example events
example_events=randsample(isolated_cluster_onsets,10);
for i=1:length(example_events)
    plot_start=example_events(i)-10; % start plot at 10 data points before cluster onset
    plot_end=example_events(i)+200;
    subplot(2,5,i)
    plot(elec_ts(plot_start:plot_end));
    hold on;
    plot(act_peaks_to_plot(plot_start:plot_end),'r');
    hold on;
end
pause; close;

