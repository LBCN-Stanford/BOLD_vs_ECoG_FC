%% iEEG dynamic conditional correlation among all electrode pairs
% must first run BOLD_vs_ECoG_FC_corr_iElvis.m

%==========================================================================
% Written by Aaron Kucyi, LBCN, Stanford University
%==========================================================================

% Needed: manually created channel name-number mapping file (.xls format)
Patient=input('Patient name (folder name): ','s');
runname=input('Run (e.g. 2): ','s');
roi1=input('Seed electrode name (e.g. AFS9): ','s');
hemi=input('hemisphere (lh or rh): ','s');
depth=input('depth(1) or subdural(0)? ','s');
rest=input('Rest(1) or Sleep(0)? ','s');
depth=str2num(depth);

BOLD_run='run1';

parcOut=elec2Parc_v2([Patient],'DK',0);
%% Get file base name
fsDir=getFsurfSubDir();
getECoGSubDir; global globalECoGDir;
if rest=='1'
cd([globalECoGDir '/Rest/' Patient '/Run' runname]);
elseif rest=='0'
    cd([globalECoGDir '/Sleep/' Patient '/Run' runname]);
end
Mfile=dir('btf_aMpfff*');
if ~isempty(Mfile)
Mfile=Mfile(2,1).name;
else
    Mfile=dir('btf_aMfff*');
    Mfile=Mfile(2,1).name;
end

load('all_bad_indices.mat');

%% Load channel name-number mapping
cd([fsDir '/' Patient '/elec_recon']);
[channumbers_iEEG,chanlabels]=xlsread('channelmap.xls');

%% Load channel names (in freesurfer/elec recon order)
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

%% Load BOLD time series
% Load fMRI electrode time series (ordered according to iElvis)
cd([fsDir '/' Patient '/elec_recon/electrode_spheres']);

       for i=1:length(chanlabels)
    elec_num=num2str(i);
    BOLD_ts(:,i)=load(['elec' elec_num BOLD_run '_ts_GSR.txt']);
   end
total_bold=size(BOLD_ts,2);


%% Load preprocessed iEEG data
if rest=='1'
cd([globalECoGDir '/Rest/' Patient '/Run' runname]);
elseif rest=='0'
    cd([globalECoGDir '/Sleep/' Patient '/Run' runname]);
end

HFB=spm_eeg_load(['pHFB' Mfile]);
HFB_slow=spm_eeg_load(['slowpHFB' Mfile]);
HFB_medium=spm_eeg_load(['bptf_mediumpHFB' Mfile]);
Alpha_medium=spm_eeg_load(['bptf_mediumpAlpha' Mfile]);
Beta1_medium=spm_eeg_load(['bptf_mediumpBeta1' Mfile]);
Beta2_medium=spm_eeg_load(['bptf_mediumpBeta2' Mfile]);
Gamma_medium=spm_eeg_load(['bptf_mediumpGamma' Mfile]);
Theta_medium=spm_eeg_load(['bptf_mediumpTheta' Mfile]);
Delta_medium=spm_eeg_load(['bptf_mediumpDelta' Mfile]);

%% Load time series in iEEG order
if rest=='1'
cd([globalECoGDir '/Rest/' Patient '/Run' runname]);
elseif rest=='0'
    cd([globalECoGDir '/Sleep/' Patient '/Run' runname]);
end

    for i=1:length(chanlabels)
iElvis_to_iEEG_chanlabel(i,:)=channumbers_iEEG(strmatch(fs_chanlabels(i,1),chanlabels,'exact'));
end

% create iEEG to iElvis chanlabel transformation vector
for i=1:length(chanlabels)
    iEEG_to_iElvis_chanlabel(i,:)=strmatch(chanlabels(i),fs_chanlabels(:,1),'exact');    
end

%% Convert seed ROI name to numbers (iElvis space)
roi1_num=strmatch(roi1,parcOut(:,1),'exact');

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

%% Remove bad channels
HFB_medium_ts(:,all_bad_indices)=NaN;

%% Transform time series from iEEG to iElvis order
HFB_iElvis=NaN(size(HFB_ts,1),length(chanlabels));
HFB_medium_iElvis=NaN(size(HFB_medium_ts,1),length(chanlabels));
alpha_medium_iElvis=NaN(size(Alpha_medium_ts,1),length(chanlabels));
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
    HFB_slow_iElvis(:,new_ind)=HFB_slow_ts(:,curr_iEEG_chan);
    Beta1_medium_iElvis(:,new_ind)=Beta1_medium_ts(:,curr_iEEG_chan);
    Beta2_medium_iElvis(:,new_ind)=Beta2_medium_ts(:,curr_iEEG_chan);
    Gamma_medium_iElvis(:,new_ind)=Gamma_medium_ts(:,curr_iEEG_chan);
    Theta_medium_iElvis(:,new_ind)=Theta_medium_ts(:,curr_iEEG_chan);
    Delta_medium_iElvis(:,new_ind)=Delta_medium_ts(:,curr_iEEG_chan);
end

%% Label bad BOLD ROIs as NaN
iElvis_bad_indices=find(isnan(HFB_medium_iElvis(1,:))==1);
BOLD_ts(:,iElvis_bad_indices)=NaN;
roi_numbers=1:size(BOLD_ts,2);
roi_numbers(iElvis_bad_indices)=NaN;

%% normalize time series
BOLD_ts_norm=NaN(size(BOLD_ts,1),length(chanlabels));
for i=1:size(BOLD_ts,2)
    BOLD_ts_norm(:,i)=(BOLD_ts(:,i)-mean(BOLD_ts(:,i)))/std(BOLD_ts(:,i));
end

HFB_medium_iElvis_norm=NaN(size(HFB_medium_iElvis,1),length(chanlabels));
for i=1:size(HFB_medium_iElvis_norm,2)
    HFB_medium_iElvis_norm(:,i)=(HFB_medium_iElvis(:,i)-mean(HFB_medium_iElvis(:,i)))/std(HFB_medium_iElvis(:,i));
end

%% Remove NaN columns
NaNCols=any(isnan(BOLD_ts_norm));
BOLD_ts_norm=BOLD_ts_norm(:,~NaNCols);
HFB_medium_iElvis_norm=HFB_medium_iElvis_norm(:,~NaNCols);
roi_numbers(find(isnan(roi_numbers)==1))=[];

%% DCC seed to all others
seed_ind=find(roi_numbers==roi1_num);

BOLD_iElvis=NaN(size(BOLD_ts,1),length(chanlabels));

display(['Doing BOLD DCCs']);
BOLD_dcc_mat=NaN(length(BOLD_ts_norm),size(BOLD_ts_norm,2));
for i=1:size(BOLD_ts_norm,2)
    if i~=seed_ind
    ROI_pair=[BOLD_ts_norm(:,seed_ind) BOLD_ts_norm(:,i)];
   R=DCC(ROI_pair);
   BOLD_dcc=squeeze(R(1,2,:));
   BOLD_dcc_mat(:,i)=BOLD_dcc;
    end
end

display(['Doing iEEG HFB (0.1-1 Hz) DCCs']);
HFB_medium_dcc_mat=NaN(length(HFB_medium_iElvis_norm),size(HFB_medium_iElvis_norm,2));
for i=1:size(HFB_medium_iElvis_norm,2)
    if i~=seed_ind
    ROI_pair=[HFB_medium_iElvis_norm(:,seed_ind) HFB_medium_iElvis_norm(:,i)];
   R=DCC(ROI_pair);
   HFB_medium_dcc=squeeze(R(1,2,:));
   HFB_medium_dcc_mat(:,i)=HFB_medium_dcc;
    end
end
    
save('HFB_medium_dcc_mat','HFB_medium_dcc_mat');
save('BOLD_dcc_mat','BOLD_dcc_mat');

    
