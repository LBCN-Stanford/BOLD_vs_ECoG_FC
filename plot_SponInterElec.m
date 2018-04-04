% must first run detect_spontaneous_events.m for electrode

%% Defaults
getECoGSubDir; global globalECoGDir;

%% Load electrode events
sub=input('Patient: ','s');
run_num=input('Run (e.g. 1): ','s');
electrode_trig=input('Electrode for spontaneous events (e.g. RPT1): ','s');
electrode_effect=input('Electrode to plot (e.g. RPG9): ','s');
cd([globalECoGDir filesep 'Rest' filesep sub filesep 'Run' run_num]);
D=spm_eeg_load;


%% Plot
LBCN_plot_averaged_signal_epochs_Spon(D.fname,{electrode_effect},[],[-1000 1500],1,electrode_trig)
