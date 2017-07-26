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

%% Remove bad indices (convert from iEEG to iElvis order)
load('all_bad_indices.mat');

% Load channel name-number mapping
cd([fsDir '/' Patient '/elec_recon']);
[channumbers_iEEG,chanlabels]=xlsread('channelmap.xls');

% Load channel names (in freesurfer/elec recon order)
chan_names=importdata([Patient '.electrodeNames'],' ');
fs_chanlabels={};

for chan=3:length(chan_names)
    chan_name=chan_names(chan); chan_name=char(chan_name);
    [a b]=strtok(chan_name); 
    bsize=size(strfind(b,' '),2);
    if bsize==2
    [c d]=strtok(b); 
    fs_chanlabels{chan,1}=[d(2) a];
    elseif bsize==3
    [c d]=strtok(b); [e f]=strtok(d);
    fs_chanlabels{chan,1}=[f(2) a c];
    end
end
fs_chanlabels=fs_chanlabels(3:end);

% create iEEG to iElvis chanlabel transformation vector
for i=1:length(chanlabels)
    iEEG_to_iElvis_chanlabel(i,:)=strmatch(chanlabels(i),fs_chanlabels(:,1),'exact');    
end
    for i=1:length(chanlabels)
iElvis_to_iEEG_chanlabel(i,:)=channumbers_iEEG(strmatch(fs_chanlabels(i,1),chanlabels,'exact'));
    end

% convert bad indices to iElvis
for i=1:length(all_bad_indices)
    ind_iElvis=find(iElvis_to_iEEG_chanlabel==all_bad_indices(i));
    if isempty(ind_iElvis)~=1
    bad_iElvis(i,:)=ind_iElvis;
    end
end
bad_chans=bad_iElvis(find(bad_iElvis>0));

mean_BOLD_high_windows(bad_chans)=[];
mean_iEEG_high_windows(bad_chans)=[];
mean_BOLD_low_windows(bad_chans)=[];
mean_iEEG_low_windows(bad_chans)=[];
mean_BOLD_high_windows(find(isfinite(mean_BOLD_high_windows)<1))=[];
mean_iEEG_high_windows(find(isfinite(mean_iEEG_high_windows)<1))=[];
mean_BOLD_low_windows(find(isfinite(mean_BOLD_low_windows)<1))=[];
mean_iEEG_low_windows(find(isfinite(mean_iEEG_low_windows)<1))=[];

%% Correlate BOLD vs iEEG (high and low FC states)

%nans_to_remove=find(isnan(mean_BOLD_high_windows)==1);
%mean_BOLD_high_windows(nans_to_remove)=[];
%mean_iEEG_high_windows(nans_to_remove)=[];
%mean_BOLD_low_windows(nans_to_remove)=[];
%mean_iEEG_low_windows(nans_to_remove)=[];










