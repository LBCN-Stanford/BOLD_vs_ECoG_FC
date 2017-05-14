%% iEEG functional connectivity within subject

%==========================================================================
% Written by Aaron Kucyi, LBCN, Stanford University
%==========================================================================

% Needed: manually created channel name-number mapping file (.xls format)
Patient=input('Patient name (folder name): ','s');
runname=input('Run (e.g. 2): ','s');
hemi=input('hemisphere (lh or rh): ','s');
depth=input('depth(1) or subdural(0)? ','s');
depth=str2num(depth);
% tdt=input('TDT data? (1=TDT,0=EDF): ','s');
% tdt=str2num(tdt);

%% Get file base name
getECoGSubDir; global globalECoGDir;
cd([globalECoGDir '/Rest/' Patient '/Run' runname]);
Mfile=dir('btf_aMpfff*');
if ~isempty(Mfile)
Mfile=Mfile(2,1).name;
else
    Mfile=dir('btf_aMfff*');
    Mfile=Mfile(2,1).name;
end

%% Load preprocessed iEEG data 
cd([globalECoGDir '/Rest/' Patient '/Run' runname]);
if ~isempty(dir('pHFB*'))
HFB=spm_eeg_load(['pHFB' Mfile]);
HFB_slow=spm_eeg_load(['slowpHFB' Mfile]);
HFB_medium=spm_eeg_load(['bptf_mediumpHFB' Mfile]);
Alpha_medium=spm_eeg_load(['bptf_mediumpAlpha' Mfile]);
Beta1_medium=spm_eeg_load(['bptf_mediumpBeta1' Mfile]);
else
HFB=spm_eeg_load(['HFB' Mfile]);
HFB_slow=spm_eeg_load(['slowHFB' Mfile]);
HFB_medium=spm_eeg_load(['bptf_mediumHFB' Mfile]);
Alpha_medium=spm_eeg_load(['bptf_mediumAlpha' Mfile]);
Beta1_medium=spm_eeg_load(['bptf_mediumBeta1' Mfile]);    
    
end

%% defaults
HFB_spike_exclusion=0; HFB_zthresh=50; % exclude channels with HFB z-score spikes exceeding threshold
BOLD_pipeline=1; % 1=GSR, 2=ICA-AROMA
BOLD_smooth=1; % 1=smoothing, 0=no spatial smoothing (for GSR)
Coords=1; % 1 = .PIAL, 2=brainmask_coords.mat
autocorr_thr=1; % remove electrode pairs with this threshold in HFB (0.1-1Hz) corr
sphere=1; % 1 for 6-mm sphere BOLD ROIs, 0 for single-voxel BOLD ROIs
tf_type=1; % 1 = morlet; 2 = hilbert
PIALVOX=1; % use PIALVOX coordinates

fsDir=getFsurfSubDir();
%Load channel name-number mapping
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

% Calculate iEEG FC
cd([globalECoGDir '/Rest/' Patient '/Run' runname]);

    for i=1:length(chanlabels)
iElvis_to_iEEG_chanlabel(i,:)=channumbers_iEEG(strmatch(fs_chanlabels(i,1),chanlabels,'exact'));
end

% create iEEG to iElvis chanlabel transformation vector
for i=1:length(chanlabels)
    iEEG_to_iElvis_chanlabel(i,:)=strmatch(chanlabels(i),fs_chanlabels(:,1),'exact');    
end

%% Load time series of all channels (in iEEG order) 
for HFB_chan=1:size(HFB,1)
    HFB_ts(:,HFB_chan)=HFB(HFB_chan,:)';    
end

for HFB_slow_chan=1:size(HFB,1)
    HFB_slow_ts(:,HFB_slow_chan)=HFB_slow(HFB_slow_chan,:)';      
end

for HFB_medium_chan=1:size(HFB,1)
    HFB_medium_ts(:,HFB_medium_chan)=HFB_medium(HFB_medium_chan,:)';      
end

for Alpha_medium_chan=1:size(HFB,1)
    Alpha_medium_ts(:,Alpha_medium_chan)=Alpha_medium(Alpha_medium_chan,:)';      
end

for Beta1_medium_chan=1:size(HFB,1)
    Beta1_medium_ts(:,Beta1_medium_chan)=Beta1_medium(Beta1_medium_chan,:)';      
end

%% Remove bad channels

%% Transform time series from iEEG to iElvis order
HFB_medium_iElvis=NaN(size(HFB_medium_ts,1),length(chanlabels));
alpha_medium_iElvis=NaN(size(Alpha_medium_ts,1),length(chanlabels));

for i=1:length(chanlabels);
    curr_iEEG_chan=channumbers_iEEG(i);
    new_ind=iEEG_to_iElvis_chanlabel(i);
    HFB_medium_iElvis(:,new_ind)=HFB_medium_ts(:,curr_iEEG_chan);
    alpha_medium_iElvis(:,new_ind)=Alpha_medium_ts(:,curr_iEEG_chan);
end

%% Make FC matrix
HFB_medium_corr=corrcoef(HFB_medium_iElvis);
alpha_medium_corr=corrcoef(alpha_medium_iElvis);
save('HFB_medium_corr','HFB_medium_corr');
save('alpha_medium_corr','alpha_medium_corr');

