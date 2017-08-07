%% iEEG functional connectivity within subject

%==========================================================================
% Written by Aaron Kucyi, LBCN, Stanford University
%==========================================================================

% Needed: manually created channel name-number mapping file (.xls format)
Patient=input('Patient name (folder name): ','s');
runname=input('Run (e.g. 2): ','s');
hemi=input('hemisphere (lh or rh): ','s');
depth=input('depth(1) or subdural(0)? ','s');
rest=input('Rest(1) Sleep(0) 7heaven (2)? ','s');
depth=str2num(depth);
% tdt=input('TDT data? (1=TDT,0=EDF): ','s');
% tdt=str2num(tdt);

%% Get file base name
getECoGSubDir; global globalECoGDir;
if rest=='1'
cd([globalECoGDir '/Rest/' Patient '/Run' runname]);
elseif rest=='0'
    cd([globalECoGDir '/Sleep/' Patient '/Run' runname]);
elseif rest=='2'
    cd([globalECoGDir '/7heaven/' Patient '/Run' runname]);
end
Mfile=dir('btf_aMpfff*');
if ~isempty(Mfile)
Mfile=Mfile(2,1).name;
else
    Mfile=dir('btf_aMfff*');
    Mfile=Mfile(2,1).name;
end
SCPfile=dir('SCP_*');
SCPfile=SCPfile(2,1).name;
SCP=spm_eeg_load([SCPfile]);

%% Load preprocessed iEEG data
if rest=='1'
cd([globalECoGDir '/Rest/' Patient '/Run' runname]);
elseif rest=='0'
    cd([globalECoGDir '/Sleep/' Patient '/Run' runname]);
elseif rest=='2'
    cd([globalECoGDir '/7heaven/' Patient '/Run' runname]);
end
if ~isempty(dir('pHFB*'))
HFB=spm_eeg_load(['pHFB' Mfile]);
HFB_slow=spm_eeg_load(['slowpHFB' Mfile]);
HFB_medium=spm_eeg_load(['bptf_mediumpHFB' Mfile]);
Alpha_medium=spm_eeg_load(['bptf_mediumpAlpha' Mfile]);
Beta1_medium=spm_eeg_load(['bptf_mediumpBeta1' Mfile]);
Beta2_medium=spm_eeg_load(['bptf_mediumpBeta2' Mfile]);
Gamma_medium=spm_eeg_load(['bptf_mediumpGamma' Mfile]);
Theta_medium=spm_eeg_load(['bptf_mediumpTheta' Mfile]);
Delta_medium=spm_eeg_load(['bptf_mediumpDelta' Mfile]);
else
HFB=spm_eeg_load(['HFB' Mfile]);
HFB_slow=spm_eeg_load(['slowHFB' Mfile]);
HFB_medium=spm_eeg_load(['bptf_mediumHFB' Mfile]);
Alpha_medium=spm_eeg_load(['bptf_mediumAlpha' Mfile]);
Beta1_medium=spm_eeg_load(['bptf_mediumBeta1' Mfile]);    
Beta2_medium=spm_eeg_load(['bptf_mediumBeta2' Mfile]); 
Gamma_medium=spm_eeg_load(['bptf_mediumGamma' Mfile]); 
Theta_medium=spm_eeg_load(['bptf_mediumTheta' Mfile]); 
Delta_medium=spm_eeg_load(['bptf_mediumDelta' Mfile]); 
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
if rest=='1'
cd([globalECoGDir '/Rest/' Patient '/Run' runname]);
elseif rest=='0'
    cd([globalECoGDir '/Sleep/' Patient '/Run' runname]);
elseif rest=='2'
    cd([globalECoGDir '/7heaven/' Patient '/Run' runname]);
end

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

for Beta2_medium_chan=1:size(HFB,1)
    Beta2_medium_ts(:,Beta2_medium_chan)=Beta2_medium(Beta2_medium_chan,:)';      
end

for Gamma_medium_chan=1:size(HFB,1)
    Gamma_medium_ts(:,Gamma_medium_chan)=Gamma_medium(Gamma_medium_chan,:)';      
end

for Delta_medium_chan=1:size(HFB,1)
    Delta_medium_ts(:,Delta_medium_chan)=Delta_medium(Delta_medium_chan,:)';      
end

for Theta_medium_chan=1:size(HFB,1)
    Theta_medium_ts(:,Theta_medium_chan)=Theta_medium(Theta_medium_chan,:)';      
end

for SCP_medium_chan=1:size(HFB,1)
    SCP_medium_ts(:,SCP_medium_chan)=SCP(SCP_medium_chan,:)';      
end

%% Remove bad channels

%% Transform time series from iEEG to iElvis order
HFB_iElvis=NaN(size(HFB_ts,1),length(chanlabels));
HFB_medium_iElvis=NaN(size(HFB_medium_ts,1),length(chanlabels));
alpha_medium_iElvis=NaN(size(Alpha_medium_ts,1),length(chanlabels));
SCP_medium_iElvis=NaN(size(SCP_medium_ts,1),length(chanlabels));
HFB_slow_iElvis=NaN(size(HFB_slow_ts,1),length(chanlabels));
Beta1_medium_iElvis=NaN(size(Beta1_medium_ts,1),length(chanlabels));
Beta2_medium_iElvis=NaN(size(Beta2_medium_ts,1),length(chanlabels));
Gamma_medium_iElvis=NaN(size(Gamma_medium_ts,1),length(chanlabels));
Theta_medium_iElvis=NaN(size(Theta_medium_ts,1),length(chanlabels));
Delta_medium_iElvis=NaN(size(Delta_medium_ts,1),length(chanlabels));

for i=1:length(chanlabels);
    curr_iEEG_chan=channumbers_iEEG(i);
    new_ind=iEEG_to_iElvis_chanlabel(i);
    HFB_iElvis(:,new_ind)=HFB_ts(:,curr_iEEG_chan);
    HFB_medium_iElvis(:,new_ind)=HFB_medium_ts(:,curr_iEEG_chan);
    alpha_medium_iElvis(:,new_ind)=Alpha_medium_ts(:,curr_iEEG_chan);
    SCP_medium_iElvis(:,new_ind)=SCP_medium_ts(:,curr_iEEG_chan);
    HFB_slow_iElvis(:,new_ind)=HFB_slow_ts(:,curr_iEEG_chan);
    Beta1_medium_iElvis(:,new_ind)=Beta1_medium_ts(:,curr_iEEG_chan);
    Beta2_medium_iElvis(:,new_ind)=Beta2_medium_ts(:,curr_iEEG_chan);
    Gamma_medium_iElvis(:,new_ind)=Gamma_medium_ts(:,curr_iEEG_chan);
    Theta_medium_iElvis(:,new_ind)=Theta_medium_ts(:,curr_iEEG_chan);
    Delta_medium_iElvis(:,new_ind)=Delta_medium_ts(:,curr_iEEG_chan);
end

%% Make FC matrix
HFB_corr=corrcoef(HFB_iElvis);
HFB_medium_corr=corrcoef(HFB_medium_iElvis);
alpha_medium_corr=corrcoef(alpha_medium_iElvis);
SCP_medium_corr=corrcoef(SCP_medium_iElvis);
HFB_slow_corr=corrcoef(HFB_slow_iElvis);
Beta1_medium_corr=corrcoef(Beta1_medium_iElvis);
Beta2_medium_corr=corrcoef(Beta2_medium_iElvis);
Gamma_medium_corr=corrcoef(Gamma_medium_iElvis);
Theta_medium_corr=corrcoef(Theta_medium_iElvis);
Delta_medium_corr=corrcoef(Delta_medium_iElvis);

save('HFB_corr','HFB_corr');
save('HFB_medium_corr','HFB_medium_corr');
save('alpha_medium_corr','alpha_medium_corr');
save('Beta1_medium_corr','Beta1_medium_corr');
save('Beta2_medium_corr','Beta2_medium_corr');
save('Theta_medium_corr','Theta_medium_corr');
save('Delta_medium_corr','Delta_medium_corr');
save('Gamma_medium_corr','Gamma_medium_corr');
save('SCP_medium_corr','SCP_medium_corr');
save('HFB_slow_corr','HFB_slow_corr');

