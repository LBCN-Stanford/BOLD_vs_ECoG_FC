%% Detect spontaneous activation events at an electrode
condition=input('Rest (1) gradCPT (2) Sleep (3): ','s');

if condition=='1'
    condition='Rest';
elseif condition=='2'
    condition='gradCPT';
elseif condition=='3'
    condition='Sleep';
end
%% Defaults
act_prctile=5; % percentile for activation definition
cluster_size=40; % minimum number of consecutive samples (i.e., msecs) needed for event definition
time_gap=500; % minimum number of msec between consecutive events
srate=1000; % sampling rate (Hz)
getECoGSubDir; global globalECoGDir;

%% Load electrode time series
sub=input('Patient: ','s');
elec_name=input('Electrode name: ','s');
% electrode=input('Electrode number: ','s');
% electrode=str2num(electrode);
cd([globalECoGDir filesep condition filesep sub]);
load('runs.txt');

%% Loop through runs
for curr_run=1:length(runs)
    act_peaks=[]; act_peaks_to_plot=[]; diff_act_peaks=[]; onsets=[];
    cluster_check=[]; cluster_onsets=[]; cluster_onsets_time=[];
    cluster_distances=[]; isolated_cluster_ind=[]; isolated_cluster_onsets=[];
    run_num=runs(curr_run);
cd([globalECoGDir filesep condition filesep sub filesep 'Run' num2str(run_num)]);
D=spm_eeg_load;
elec_num=indchannel(D,elec_name);
elec_ts=D(elec_num,:);
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
LBCN_epoch_bc(D,events_file,[],'start',[-1500 1500],0,[],[],epoch_name);

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
end


   

