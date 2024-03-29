% must first run detect_spontaneous_events.m for electrode

%% Defaults
getECoGSubDir; global globalECoGDir;
load('cdcol.mat');

%% Load electrode events
sub=input('Patient: ','s');
run_num=input('Run (e.g. 1): ','s');
electrode_trig=input('Electrode for spontaneous events (e.g. RPT1): ','s');
electrode_effect=input('Electrode to plot (e.g. RPG9): ','s');
cd([globalECoGDir filesep 'Rest' filesep sub filesep 'Run' run_num]);
display(['Select epoched file for trigger electrode']);
D=spm_eeg_load;

chan_num=indchannel(D,electrode_effect);

%% Plot
LBCN_plot_averaged_signal_epochs_Spon(D.fname,{electrode_effect},[],[-500 1500],1,electrode_trig)
mcond=ans(1,:); std_cond=ans(2,:);

  %plot(D.time),postCC_avg_alltrials,'LineWidth',2,'Color',cdcol.russet);
 %hold on;
  shadedErrorBar(D.time,mcond,std_cond,{'linewidth',2,'Color',cdcol.russet},0.8); 
  set(gca,'Fontsize',14,'Fontweight','bold','LineWidth',2,'TickDir','out','box','off');
line([D.time(1) D.time(end)],[0 0],'LineWidth',1,'Color','k');
h=vline(0,'k-');
    %title('post-RT-locked Correct Commission (city) activity');
    pause; close;