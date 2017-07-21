%% Compare high and low states of FC between 2 nodes - BOLD vs iEEG
% must first run plot_dFC_pair.m for both BOLD and iEEG

Patient=input('Patient: ','s');
runs=input('iEEG run (e.g. 1): ','s');
rest=input('Rest(1) or Sleep(0)? ','s');
Window_dur=input('Window duration (in sec): ','s'); 
roi1=input('Seed (e.g. AFS9): ','s');
roi2=input('Target to define high and low states (e.g. PIHS4): ','s');

runnum=['run' runs];
fsDir=getFsurfSubDir();
getECoGSubDir; global globalECoGDir;
parcOut=elec2Parc_v2([Patient],'DK',0);
elecNames = parcOut(:,1);

%% Load sliding window vectors
    if rest=='1'
cd([globalECoGDir '/Rest/' Patient '/Run' runs]);
elseif rest=='0'
    cd([globalECoGDir '/Sleep/' Patient '/Run' runs]);
    end
    
    BOLD=load([roi1 '_' Window_dur 'sec_windows_BOLD.mat']);
    iEEG=load([roi1 '_' Window_dur 'sec_windows_iEEG.mat']);
   
 %% Get target index number
roi2_num=strmatch(roi2,elecNames,'exact');

%% Find window indices for high and low seed-target FC states
target_BOLD_sw_ts=BOLD.seed_allwindows_fisher(roi2_num,:);
BOLD_high=find(target_BOLD_sw_ts>prctile(target_BOLD_sw_ts,66.6));
BOLD_low=find(target_BOLD_sw_ts<prctile(target_BOLD_sw_ts,33.3));
 
target_iEEG_sw_ts=iEEG.seed_allwindows_fisher(roi2_num,:);
iEEG_high=find(target_iEEG_sw_ts>prctile(target_iEEG_sw_ts,66.6));
iEEG_low=find(target_iEEG_sw_ts<prctile(target_iEEG_sw_ts,33.3));

%% Get average FC for all targets within high and within low states
BOLD_high_avg_roi2=mean(target_BOLD_sw_ts(BOLD_high))
BOLD_low_avg_roi2=mean(target_BOLD_sw_ts(BOLD_low))
iEEG_high_avg_roi2=mean(target_iEEG_sw_ts(iEEG_high))
iEEG_low_avg_roi2=mean(target_iEEG_sw_ts(iEEG_low))

BOLD_high_windows=BOLD.seed_allwindows_fisher(:,BOLD_high);
BOLD_low_windows=BOLD.seed_allwindows_fisher(:,BOLD_low);
iEEG_high_windows=iEEG.seed_allwindows_fisher(:,iEEG_high);
iEEG_low_windows=iEEG.seed_allwindows_fisher(:,iEEG_low);

mean_BOLD_high_windows=mean(BOLD_high_windows,2);
mean_BOLD_low_windows=mean(BOLD_low_windows,2);
mean_iEEG_high_windows=mean(iEEG_high_windows,2);
mean_iEEG_low_windows=mean(iEEG_low_windows,2);

%% Remove bad indices



%% Correlate BOLD vs iEEG (high and low FC states)












