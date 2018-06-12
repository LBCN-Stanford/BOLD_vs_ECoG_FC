%% Detect spontaneous activation events at an electrode
condition=input('Rest (1) gradCPT (2): ','s');

if condition=='1'
    condition='Rest'
elseif condition=='2'
    condition='gradCPT'
end
%% Defaults
act_prctile=5; % percentile for activation definition
cluster_size=50; % minimum number of consecutive samples (i.e., msecs) needed for event definition
time_gap=500; % minimum number of msec between consecutive events
srate=1000; % sampling rate (Hz)
getECoGSubDir; global globalECoGDir;
load('cdcol.mat');

%% Load electrode time series
sub=input('Patient: ','s');
run_num=input('Run (e.g. 1): ','s');
elec_name=input('Electrode name: ','s');
%electrode=str2num(electrode);
cd([globalECoGDir filesep condition filesep sub filesep 'Run' run_num]);
D=spm_eeg_load;
elec_num=indchannel(D,elec_name);
elec_ts=D(elec_num,:);
%elec_name=char(D.chanlabels(electrode));
%% Detect top act_prctile time points
cutoff=prctile(elec_ts,100-act_prctile);
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


% plot example segment with 2 clusters
isolated_clusters_secs=isolated_cluster_onsets/1000;
ind2plot=find(diff(isolated_clusters_secs)<2); % less than 2 seconds between 2 clusters

%diff(act_peaks_to_plot);
elec_peak_ts=elec_ts;
elec_peak_ts(elec_ts<cutoff)=NaN;


figure1=figure('Position', [200, 600, 800, 250]);
    plot_start=isolated_cluster_onsets(ind2plot(1))-1000; % start plot at 1000 data points before cluster onset
    plot_end=isolated_cluster_onsets(ind2plot(1))+2000;
    cluster1_onset=1000;
    cluster2_onset=cluster1_onset+isolated_cluster_onsets(ind2plot(1)+1)-isolated_cluster_onsets(ind2plot(1))
    p1=plot(elec_ts(plot_start:plot_end));
    p1.LineWidth=1; p1.Color=cdcol.grey;
    hold on;
    p2=plot(elec_peak_ts(plot_start:plot_end));
    p2.LineWidth=2; p2.Color=cdcol.russet;
    xlim([0,length(plot_start:plot_end)]);
xlabel(['Time (ms)']); ylabel(['HFB Power']);
h1=vline(cluster1_onset,'k-.');
h1=vline(cluster2_onset,'k-.');
set(gcf,'color','w');
set(gca,'Fontsize',14,'Fontweight','bold','LineWidth',2,'TickDir','out','box','off');



 end_ind=end_time*iEEG_sampling;
 time=(1:end_ind)/iEEG_sampling;
 FigHandle = figure('Position', [200, 600, 900, 250]);
title({[elec1 ' vs ' elec2]; ['r = ' num2str(elec_FC)]} ,'Fontsize',12);
xlabel(['Time (sec)']); ylabel(['Signal']);
set(gca,'Fontsize',18,'LineWidth',2,'TickDir','out','box','off');
hold on;
p=plot(time,elec1_ts_norm(1:end_ind),time,elec2_ts_norm(1:end_ind));
p(1).LineWidth=2; p(1).Color=cdcol.lightblue;
p(2).LineWidth=2; p(2).Color=cdcol.russet;
xlim([0,time(end)]);
legend([elec1],[elec2]);
