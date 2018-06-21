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
load('TTL_onsets.mat');
iEEG_offset=TTL_onsets(1); % to subtract from PTB time
data_file=dir(['SHFBbtf*']);
data_file=data_file(2,1).name;
D=spm_eeg_load(data_file);
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

% remove clusters that are <1.5 seconds from run onset
event_onsets=isolated_cluster_onsets/srate;
ind_to_delete=find(event_onsets<1.5);
event_onsets(ind_to_delete)=[];
isolated_cluster_onsets(ind_to_delete)=[];

n_events=length(event_onsets);

% save onsets to events.mat file for epoching

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

% for gradCPT, determine how many events are after mountains (correct or
% error)
if condition=='gradCPT'
    true_mt_ind=[]; false_mt_ind=[];
    true_spAct_mt=[]; false_spAct_mt=[];
    load('CO_onsets_ECoG.mat'); load('CE_onsets_ECoG.mat');
    CO_onset_times=CO_onsets_ECoG-iEEG_offset;
    CE_onset_times=CE_onsets_ECoG-iEEG_offset;
    mt_onset_times=[CO_onset_times; CE_onset_times];
    event_times=D.time(isolated_cluster_onsets)-iEEG_offset;
    event_times=event_times';
    for i=1:length(event_times)
       events_vs_mt=event_times(i)-mt_onset_times;
       events_vs_mt(find(events_vs_mt<0))=[];
       if ~isempty(find(events_vs_mt<1)) % find events that are within 1 sec of mountain onsets
           true_mt_ind=[true_mt_ind; i];
       else false_mt_ind=[false_mt_ind; i];
       end
    end
    n_true_mt_ind=length(true_mt_ind);
    n_false_mt_ind=length(false_mt_ind);
    true_mt_ind_all(curr_run)=n_true_mt_ind;
    false_mt_ind_all(curr_run)=n_false_mt_ind;
    % save onset times of TRUE and FALSE events (in iEEG time) within run
    true_spAct_mt=event_times(true_mt_ind)+iEEG_offset;
    false_spAct_mt=event_times(false_mt_ind)+iEEG_offset;
    save([elec_name '_true_spAct'],'true_mt_ind');
    save([elec_name '_false_spAct'],'false_mt_ind');
end

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
close;
end

%% get proportion of events that follow mountain onsets 
if condition=='gradCPT'
    prc_true=sum(true_mt_ind_all)/(sum(true_mt_ind_all)+sum(false_mt_ind_all))
end


   

