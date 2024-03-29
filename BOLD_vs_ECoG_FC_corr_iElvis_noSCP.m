%% Main function to compare BOLD vs iEEG functional connectivity within subject

%==========================================================================
% Written by Aaron Kucyi, LBCN, Stanford University
%==========================================================================

% Needed: manually created channel name-number mapping file (.xls format)
Patient=input('Patient name (folder name): ','s');
runname=input('Run (e.g. 2): ','s');
chanmap=input('channelmap.xls (1) or channelmap2.xls (2) ','s');
%hemi=input('hemisphere (lh or rh): ','s');
depth=input('depth(1) or subdural(0)? ','s');
rest=input('Rest(1) Sleep(0) gradCPT (2) MMR (3)? ','s');
distance_exclusion=input('exclude short-distance pairs (1)? ','s');
if distance_exclusion=='1'
dist_thr=input('How short (mm)? ','s');
end
depth=str2num(depth);
%BOLD_run=input('BOLD run # (e.g. run1): ','s');
BOLD_run='run1';
tdt=input('TDT data? (1=TDT,0=EDF): ','s');
BOLD_pipeline=input('BOLD pipeline (1=GSR, 2=AROMA, 3=NoGSR, 4=aCompCor): ' ,'s'); % 1=GSR, 2=ICA-AROMA
plotting=input('plot all (0) HFB 0.1-1Hz (1)  alpha (2) HFB <0.1Hz (3) beta1 (4) beta2 (5) Theta (6) Delta (7) Gamma (8) SCP (9) HFB unfiltered (a) HFB >1Hz (b)? ','s');
tdt=str2num(tdt);
BOLD_pipeline=str2num(BOLD_pipeline);

if tdt==0
rm_last=1; else rm_last=0; % remove last iEEG chan (e.g. if it is reference)
end

if depth==0
PIALVOX=1; % use PIALVOX coordinates
else
    PIALVOX=0;
end

%% Get hemisphere file base name
getECoGSubDir; global globalECoGDir;

if rest=='1'
cd([globalECoGDir '/Rest/' Patient]);
elseif rest=='0'
    cd([globalECoGDir '/Sleep/' Patient]);
elseif rest=='2'
    cd([globalECoGDir '/gradCPT/' Patient]);
elseif rest=='3'
    cd([globalECoGDir '/MMR/' Patient]);
end

if depth=='0'
hemi=importdata(['hemi.txt']); 
hemi=char(hemi);
end
if rest=='1'
cd([globalECoGDir '/Rest/' Patient '/Run' runname]);
elseif rest=='0'
    cd([globalECoGDir '/Sleep/' Patient '/Run' runname]);
elseif rest=='2'
    cd([globalECoGDir '/gradCPT/' Patient '/Run' runname]);
elseif rest=='3'
    cd([globalECoGDir '/MMR/' Patient '/Run' runname]);
end

Mfile=dir('btf_aMpfff*');
% SCPfile=dir('SCP_*');
% SCPfile=SCPfile(2,1).name;
if ~isempty(Mfile)
Mfile=Mfile(2,1).name;
else
    Mfile=dir('btf_aMfff*');
    Mfile=Mfile(2,1).name;
end
    

%% TO MODIFY
if tdt==0
rm_last=1; else rm_last=0; % remove last iEEG chan (e.g. if it is reference)
end

%% Defaults
Chop=10000; % chop first 10 seconds of each time series
use_bad=1; % use bad channel labels from HFB (0.1-1 Hz) file
HFB_spike_exclusion=1; HFB_zthresh=50; % exclude channels with HFB z-score spikes exceeding threshold
BOLD_smooth=1; % 1=smoothing, 0=no spatial smoothing (for GSR)
Coords=1; % 1 = .PIAL, 2=brainmask_coords.mat
autocorr_thr=1; % remove electrode pairs with this threshold in HFB (0.1-1Hz) corr
sphere=1; % 1 for 6-mm sphere BOLD ROIs, 0 for single-voxel BOLD ROIs
tf_type=1; % 1 = morlet; 2 = hilbert
output_elecs=1; % output plots for each electrode
if distance_exclusion=='1'
distance_thr=str2num(dist_thr); % Exclude electrode pairs below this distance apart
end

fsDir=getFsurfSubDir();
% set # of edge data points to delete from iEEG data
edge=10;
%Load channel name-number mapping
cd([fsDir '/' Patient '/elec_recon']);
if chanmap=='1'
[channumbers_iEEG,chanlabels]=xlsread('channelmap.xls');
elseif chanmap=='2'
[channumbers_iEEG,chanlabels]=xlsread('channelmap2.xls');
end

% Load electrode coordinates
if Coords==1;
vox=dlmread([Patient '.PIAL'],' ',2,0);
elseif Coords==2;
    load('brainmask_coords.mat');
    vox=brainmask_coords;
end

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

% elseif depth==1
%  for chan=3:length(chan_names)
%     chan_name=chan_names(chan); chan_name=char(chan_name);
%     fs_chanlabels{chan,1}=strtok(chan_name);   
%  end
% end
fs_chanlabels=fs_chanlabels(3:end);

% Make node file with all electrodes
nodes=[vox ones(size(vox,1),2)]; nodes=num2cell(nodes);
blank_names=cell(1,length(vox)); blank_names(:)={'-'}; blank_names=blank_names';

nodes=[nodes blank_names];
a=cell2mat(nodes(:,1)); b=cell2mat(nodes(:,2));c=cell2mat(nodes(:,3)); d=cell2mat(nodes(:,4)); e=cell2mat(nodes(:,5));

fid=fopen('example.node','w');
for i=1:size(a,1)
    fprintf(fid,'%d %d %d %d %d %s\n',a(i),b(i),c(i),d(i),e(i),blank_names{i});    
end
fclose(fid);

%% Get electrode names
parcOut=elec2Parc_v2(Patient,'DK',0);

%% Load channel name-network number mapping
if depth==2
    cd([fsDir '/' Patient '/elec_recon']);
   RAS_coords=dlmread([Patient '.LEPTO'],' ',2,0); 
   
parcOut=elec2Parc(Patient,[fsDir '/' Patient '/label/' hemi '.parc_result_' BOLD_run '.annot']);
Yeo_parcOut=elec2Parc(Patient,'Y17');
channetworks=parcOut(:,2);
channetworks_Yeo=Yeo_parcOut(:,2);

Yeo_DMN_Core=strfind(channetworks_Yeo,'17Networks_16');
channetworks_Yeo(find(~cellfun(@isempty,Yeo_DMN_Core)==1))={'01'};
Yeo_MTL_subsystem=strfind(channetworks_Yeo,'17Networks_15');
channetworks_Yeo(find(~cellfun(@isempty,Yeo_MTL_subsystem)==1))={'02'};
Yeo_dmPFC_subsystem=strfind(channetworks_Yeo,'17Networks_17');
channetworks_Yeo(find(~cellfun(@isempty,Yeo_dmPFC_subsystem)==1))={'04'};
Yeo_Limbic=strfind(channetworks_Yeo,'17Networks_10');
channetworks_Yeo(find(~cellfun(@isempty,Yeo_Limbic)==1))={'05'};
Yeo_auditory=strfind(channetworks_Yeo,'17Networks_14');
channetworks_Yeo(find(~cellfun(@isempty,Yeo_auditory)==1))={'07'};
Yeo_FPN=strfind(channetworks_Yeo,'17Networks_11');
channetworks_Yeo(find(~cellfun(@isempty,Yeo_FPN)==1))={'08'};
Yeo_FPN=strfind(channetworks_Yeo,'17Networks_13');
channetworks_Yeo(find(~cellfun(@isempty,Yeo_FPN)==1))={'08'};
Yeo_FPN=strfind(channetworks_Yeo,'17Networks_12');
channetworks_Yeo(find(~cellfun(@isempty,Yeo_FPN)==1))={'08'};
Yeo_VAN=strfind(channetworks_Yeo,'17Networks_7');
channetworks_Yeo(find(~cellfun(@isempty,Yeo_VAN)==1))={'03'};
Yeo_VAN=strfind(channetworks_Yeo,'17Networks_8');
channetworks_Yeo(find(~cellfun(@isempty,Yeo_VAN)==1))={'03'};
Yeo_SMN=strfind(channetworks_Yeo,'17Networks_4');
channetworks_Yeo(find(~cellfun(@isempty,Yeo_SMN)==1))={'09'};
Yeo_SMN=strfind(channetworks_Yeo,'17Networks_3');
channetworks_Yeo(find(~cellfun(@isempty,Yeo_SMN)==1))={'09'};
Yeo_Visual=strfind(channetworks_Yeo,'17Networks_1');
channetworks_Yeo(find(~cellfun(@isempty,Yeo_Visual)==1))={'10'};
Yeo_Visual=strfind(channetworks_Yeo,'17Networks_2');
channetworks_Yeo(find(~cellfun(@isempty,Yeo_Visual)==1))={'10'};
Yeo_DAN=strfind(channetworks_Yeo,'17Networks_6');
channetworks_Yeo(find(~cellfun(@isempty,Yeo_DAN)==1))={'06'};
Yeo_DAN=strfind(channetworks_Yeo,'17Networks_5');
channetworks_Yeo(find(~cellfun(@isempty,Yeo_DAN)==1))={'06'};
Yeo_Language=strfind(channetworks_Yeo,'parsopercularis');
channetworks_Yeo(find(~cellfun(@isempty,Yeo_Language)==1))={'11'};
Yeo_noNetwork=strfind(channetworks_Yeo,'17Networks_9');
channetworks_Yeo(find(~cellfun(@isempty,Yeo_noNetwork)==1))={'12'};

DMN=strfind(channetworks,'17Networks_10');
channetworks(find(~cellfun(@isempty,DMN)==1))={'1'};
DMN=strfind(channetworks,'17Networks_15');
channetworks(find(~cellfun(@isempty,DMN)==1))={'1'};
DMN=strfind(channetworks,'17Networks_16');
channetworks(find(~cellfun(@isempty,DMN)==1))={'1'};
DMN=strfind(channetworks,'17Networks_14');
channetworks(find(~cellfun(@isempty,DMN)==1))={'1'};
FPN=strfind(channetworks,'17Networks_11');
channetworks(find(~cellfun(@isempty,FPN)==1))={'2'};
FPN=strfind(channetworks,'17Networks_13');
channetworks(find(~cellfun(@isempty,FPN)==1))={'2'};
FPN=strfind(channetworks,'17Networks_12');
channetworks(find(~cellfun(@isempty,FPN)==1))={'2'};
VAN=strfind(channetworks,'17Networks_7');
channetworks(find(~cellfun(@isempty,VAN)==1))={'3'};
VAN=strfind(channetworks,'17Networks_8');
channetworks(find(~cellfun(@isempty,VAN)==1))={'3'};
SMN=strfind(channetworks,'17Networks_4');
channetworks(find(~cellfun(@isempty,SMN)==1))={'4'};
SMN=strfind(channetworks,'17Networks_3');
channetworks(find(~cellfun(@isempty,SMN)==1))={'4'};
Visual=strfind(channetworks,'17Networks_1');
channetworks(find(~cellfun(@isempty,Visual)==1))={'5'};
Visual=strfind(channetworks,'17Networks_2');
channetworks(find(~cellfun(@isempty,Visual)==1))={'5'};
DAN=strfind(channetworks,'17Networks_6');
channetworks(find(~cellfun(@isempty,DAN)==1))={'6'};
DAN=strfind(channetworks,'17Networks_5');
channetworks(find(~cellfun(@isempty,DAN)==1))={'6'};
Language=strfind(channetworks,'17Networks_17');
channetworks(find(~cellfun(@isempty,Language)==1))={'7'};
Language=strfind(channetworks,'parsopercularis');
channetworks(find(~cellfun(@isempty,Language)==1))={'7'};
noNetwork=strfind(channetworks,'17Networks_9');
channetworks(find(~cellfun(@isempty,noNetwork)==1))={'8'};

channetworks_iElvis=str2num(cell2mat(channetworks));
Yeo_channetworks_iElvis=str2num(cell2mat(channetworks_Yeo));


% Configure for plotting networks on surface
% Yeo_CoreDMN_ind=find(Yeo_channetworks_iElvis==1);
% Yeo_CoreDMN_coords=RAS_coords(Yeo_CoreDMN_ind,1:3);
% Yeo_CoreDMN_coords=[Yeo_CoreDMN_coords,ones(length(Yeo_CoreDMN_coords),1)];
% Yeo_CoreDMN_names=strread(num2str(1:length(Yeo_CoreDMN_coords)),'%s');

Yeo_DAN_ind=find(Yeo_channetworks_iElvis==6);
Yeo_DAN_coords=RAS_coords(Yeo_DAN_ind,1:3);
Yeo_DAN_coords=[Yeo_DAN_coords,ones(length(Yeo_DAN_coords),1)];
Yeo_DAN_names=strread(num2str(1:length(Yeo_DAN_coords)),'%s');

Yeo_VAN_ind=find(Yeo_channetworks_iElvis==3);
Yeo_VAN_coords=RAS_coords(Yeo_VAN_ind,1:3);
Yeo_VAN_coords=[Yeo_VAN_coords,ones(length(Yeo_VAN_coords),1)];
Yeo_VAN_names=strread(num2str(1:length(Yeo_VAN_coords)),'%s');
end

%% Load preprocessed iEEG data 
if rest=='1'
cd([globalECoGDir '/Rest/' Patient '/Run' runname]);
elseif rest=='0'
    cd([globalECoGDir '/Sleep/' Patient '/Run' runname]);
elseif rest=='2'
    cd([globalECoGDir '/gradCPT/' Patient '/Run' runname]);
elseif rest=='3'
    cd([globalECoGDir '/MMR/' Patient '/Run' runname]);
end

%SCP=spm_eeg_load([SCPfile]);

if ~isempty(dir('pHFB*'))
Alpha=spm_eeg_load(['pAlpha' Mfile]);
% Beta1=spm_eeg_load(['pBeta1' Mfile]);
% Beta2=spm_eeg_load(['pBeta2' Mfile]);
% Delta=spm_eeg_load(['pDelta' Mfile]);
% Theta=spm_eeg_load(['pTheta' Mfile]);
% Gamma=spm_eeg_load(['pGamma' Mfile]);
HFB=spm_eeg_load(['pHFB' Mfile]);
HFB_slow=spm_eeg_load(['slowpHFB' Mfile]);
HFB_medium=spm_eeg_load(['bptf_mediumpHFB' Mfile]);
% Alpha_medium=spm_eeg_load(['bptf_mediumpAlpha' Mfile]);
% Beta1_medium=spm_eeg_load(['bptf_mediumpBeta1' Mfile]);
% Beta2_medium=spm_eeg_load(['bptf_mediumpBeta2' Mfile]);
% Delta_medium=spm_eeg_load(['bptf_mediumpDelta' Mfile]);
% Theta_medium=spm_eeg_load(['bptf_mediumpTheta' Mfile]);
% Gamma_medium=spm_eeg_load(['bptf_mediumpGamma' Mfile]);
HFB_fast=spm_eeg_load(['fastpHFB' Mfile]);
% Alpha_fast=spm_eeg_load(['fastpAlpha' Mfile]);
% Beta1_fast=spm_eeg_load(['fastpBeta1' Mfile]);
% Beta2_fast=spm_eeg_load(['fastpBeta2' Mfile]);
% Delta_fast=spm_eeg_load(['fastpDelta' Mfile]);
% Theta_fast=spm_eeg_load(['fastpTheta' Mfile]);
% Gamma_fast=spm_eeg_load(['fastpGamma' Mfile]);

else
    
% Alpha=spm_eeg_load(['HFB' Mfile]);
% Beta1=spm_eeg_load(['Beta1' Mfile]);
% Beta2=spm_eeg_load(['Beta2' Mfile]);
% Delta=spm_eeg_load(['Delta' Mfile]);
% Theta=spm_eeg_load(['Theta' Mfile]);
% Gamma=spm_eeg_load(['Gamma' Mfile]);
HFB=spm_eeg_load(['HFB' Mfile]);
HFB_slow=spm_eeg_load(['slowHFB' Mfile]);
HFB_medium=spm_eeg_load(['bptf_mediumHFB' Mfile]);
% Alpha_medium=spm_eeg_load(['bptf_mediumAlpha' Mfile]);
% Beta1_medium=spm_eeg_load(['bptf_mediumBeta1' Mfile]);    
% Beta2_medium=spm_eeg_load(['bptf_mediumBeta2' Mfile]);
% Delta_medium=spm_eeg_load(['bptf_mediumDelta' Mfile]);
% Theta_medium=spm_eeg_load(['bptf_mediumTheta' Mfile]);
% Gamma_medium=spm_eeg_load(['bptf_mediumGamma' Mfile]);       
end

% Load fMRI electrode time series (ordered according to iElvis)
cd([fsDir '/' Patient '/elec_recon/electrode_spheres']);

if BOLD_pipeline==1 && sphere==1 && BOLD_smooth==1 && PIALVOX==0
%     if Coords==1;
for i=1:length(chanlabels)
    elec_num=num2str(i);
    BOLD_ts(:,i)=load(['elec' elec_num BOLD_run '_ts_FSL.txt']);
end

elseif BOLD_pipeline==1 && sphere==1 && BOLD_smooth==0 && PIALVOX==0
    for i=1:length(chanlabels)
    elec_num=num2str(i);
    BOLD_ts(:,i)=load(['elec' elec_num BOLD_run '_ts_nosmooth.txt']);
end

elseif BOLD_pipeline==1 && sphere==0 && PIALVOX==0
   for i=1:length(chanlabels)
    elec_num=num2str(i);
    BOLD_ts(:,i)=load(['elec' elec_num BOLD_run '_ts_FSL_1vox.txt']);
   end

elseif BOLD_pipeline==1 && PIALVOX==1
    display(['using PIALVOX coordinates'])
       for i=1:length(chanlabels)
    elec_num=num2str(i);
    BOLD_ts(:,i)=load(['elec' elec_num BOLD_run '_ts_GSR.txt']);
   end

elseif BOLD_pipeline==2
  for i=1:length(chanlabels)
    elec_num=num2str(i);
    BOLD_ts(:,i)=load(['elec' elec_num BOLD_run '_ts_AROMA.txt']);  
  end  

elseif BOLD_pipeline==3
  for i=1:length(chanlabels)
    elec_num=num2str(i);
    BOLD_ts(:,i)=load(['elec' elec_num BOLD_run '_ts_NoGSR.txt']);  
  end  

  elseif BOLD_pipeline==4
  for i=1:length(chanlabels)
    elec_num=num2str(i);
    BOLD_ts(:,i)=load(['elec' elec_num BOLD_run '_ts_aCompCor.txt']);  
  end  
end

total_bold=size(BOLD_ts,2);

if rest=='1'
cd([globalECoGDir '/Rest/' Patient '/Run' runname]);
elseif rest=='0'
    cd([globalECoGDir '/Sleep/' Patient '/Run' runname]);
elseif rest=='2'
    cd([globalECoGDir '/gradCPT/' Patient '/Run' runname]);
elseif rest=='3'
    cd([globalECoGDir '/MMR/' Patient '/Run' runname]);
end
   iElvis_to_iEEG_chanlabel=[]; iEEG_to_iElvis_chanlabel=[];
% create iElvis to iEEG chanlabel transformation vector
if depth==2
for i=1:length(chanlabels)
    curr_ind=channumbers_iEEG(strmatch(parcOut(i,1),chanlabels,'exact'));
    if ~isempty(curr_ind)
iElvis_to_iEEG_chanlabel=[iElvis_to_iEEG_chanlabel; curr_ind];
    end
end

% create iEEG to iElvis chanlabel transformation vector
for i=1:length(chanlabels)
    curr_ind=strmatch(chanlabels(i),parcOut(:,1),'exact');
    if ~isempty(curr_ind)
    iEEG_to_iElvis_chanlabel=[iEEG_to_iElvis_chanlabel ; curr_ind];    
    end
end
end

if depth~=2 
    for i=1:length(chanlabels)
        curr_ind=channumbers_iEEG(strmatch(fs_chanlabels(i,1),chanlabels,'exact'));
%iElvis_to_iEEG_chanlabel(i,:)=channumbers_iEEG(strmatch(fs_chanlabels(i,1),chanlabels,'exact'));
 if ~isempty(curr_ind)
iElvis_to_iEEG_chanlabel=[iElvis_to_iEEG_chanlabel; curr_ind];
 end
end

% create iEEG to iElvis chanlabel transformation vector
for i=1:length(chanlabels)
    curr_ind=strmatch(chanlabels(i),fs_chanlabels(:,1),'exact');
    %iEEG_to_iElvis_chanlabel(i,:)=strmatch(chanlabels(i),fs_chanlabels(:,1),'exact'); 
     if ~isempty(curr_ind)
    iEEG_to_iElvis_chanlabel=[iEEG_to_iElvis_chanlabel; curr_ind];
     end
end
    
end

% Transform iElvis networks to iEEG order
% %for i=1:length(chanlabels)
% for i=1:max(iElvis_to_iEEG_chanlabel);
%     new_ind=find(iElvis_to_iEEG_chanlabel==i);
%     channetworks_EEG(i,:)=channetworks_iElvis(new_ind);
% end
% chan_numbers_networks_iEEG=[channumbers_iEEG channetworks_iEEG];

%% Load time series of all channels (in iEEG order)  
if rm_last==1
for HFB_chan=1:total_bold;
    HFB_ts(:,HFB_chan)=HFB(HFB_chan,:)';      
end

% for Alpha_chan=1:total_bold;
%     Alpha_ts(:,Alpha_chan)=Alpha(Alpha_chan,:)';      
% end
% 
% for Beta1_chan=1:total_bold;
%     Beta1_ts(:,Beta1_chan)=Beta1(Beta1_chan,:)';      
% end
% 
% for Beta2_chan=1:total_bold;
%     Beta2_ts(:,Beta2_chan)=Beta2(Beta2_chan,:)';      
% end
% 
% for Delta_chan=1:total_bold;
%     Delta_ts(:,Delta_chan)=Delta(Delta_chan,:)';      
% end
% 
% for Theta_chan=1:total_bold;
%     Theta_ts(:,Theta_chan)=Theta(Theta_chan,:)';      
% end

% for Gamma_chan=1:total_bold;
%     Gamma_ts(:,Gamma_chan)=Gamma(Gamma_chan,:)';      
% end

for HFB_slow_chan=1:total_bold;
    HFB_slow_ts(:,HFB_slow_chan)=HFB_slow(HFB_slow_chan,:)';      
end

for HFB_medium_chan=1:total_bold;
    HFB_medium_ts(:,HFB_medium_chan)=HFB_medium(HFB_medium_chan,:)';      
end

% for Alpha_medium_chan=1:total_bold;
%     Alpha_medium_ts(:,Alpha_medium_chan)=Alpha_medium(Alpha_medium_chan,:)';      
% end
% 
% for Beta1_medium_chan=1:total_bold;
%     Beta1_medium_ts(:,Beta1_medium_chan)=Beta1_medium(Beta1_medium_chan,:)';      
% end
% 
% for Beta2_medium_chan=1:total_bold;
%     Beta2_medium_ts(:,Beta2_medium_chan)=Beta2_medium(Beta2_medium_chan,:)';      
% end
% 
% for Theta_medium_chan=1:total_bold;
%     Theta_medium_ts(:,Theta_medium_chan)=Theta_medium(Theta_medium_chan,:)';      
% end
% for Delta_medium_chan=1:total_bold;
%     Delta_medium_ts(:,Delta_medium_chan)=Delta_medium(Delta_medium_chan,:)';      
% end
% 
% for Gamma_medium_chan=1:total_bold;
%     Gamma_medium_ts(:,Gamma_medium_chan)=Gamma_medium(Gamma_medium_chan,:)';      
% end

% for HFB_fast_chan=1:total_bold;
%     HFB_fast_ts(:,HFB_fast_chan)=HFB_fast(HFB_fast_chan,:)';      
% end

% for Alpha_fast_chan=1:total_bold;
%     Alpha_fast_ts(:,Alpha_fast_chan)=Alpha_fast(Alpha_fast_chan,:)';      
% end
% 
% for Beta1_fast_chan=1:total_bold;
%     Beta1_fast_ts(:,Beta1_fast_chan)=Beta1_fast(Beta1_fast_chan,:)';      
% end
% 
% for Beta2_fast_chan=1:total_bold;
%     Beta2_fast_ts(:,Beta2_fast_chan)=Beta2_fast(Beta2_fast_chan,:)';      
% end
% 
% for Theta_fast_chan=1:total_bold;
%     Theta_fast_ts(:,Theta_fast_chan)=Theta_fast(Theta_fast_chan,:)';      
% end
% for Delta_fast_chan=1:total_bold;
%     Delta_fast_ts(:,Delta_fast_chan)=Delta_fast(Delta_fast_chan,:)';      
% end
% 
% for Gamma_fast_chan=1:total_bold;
%     Gamma_fast_ts(:,Gamma_fast_chan)=Gamma_fast(Gamma_fast_chan,:)';      
% end

% for SCP_medium_chan=1:total_bold;
%     SCP_medium_ts(:,SCP_medium_chan)=SCP(SCP_medium_chan,:)';      
% end

else

% for Alpha_chan=1:size(Alpha,1)
%     Alpha_ts(:,Alpha_chan)=Alpha(Alpha_chan,:)';    
% end
% 
% for Beta1_chan=1:size(Beta1,1)
%     Beta1_ts(:,Beta1_chan)=Beta1(Beta1_chan,:)';    
% end
% 
% for Beta2_chan=1:size(Beta2,1)
%     Beta2_ts(:,Beta2_chan)=Beta2(Beta2_chan,:)';    
% end
% 
% for Theta_chan=1:size(Theta,1)
%     Theta_ts(:,Theta_chan)=Theta(Theta_chan,:)';    
% end
% 
% for Delta_chan=1:size(Delta,1)
%     Delta_ts(:,Delta_chan)=Delta(Delta_chan,:)';    
% end
% 
% for Gamma_chan=1:size(Gamma,1)
%     Gamma_ts(:,Gamma_chan)=Gamma(Gamma_chan,:)';    
% end 
    
for HFB_chan=1:size(HFB,1)
    HFB_ts(:,HFB_chan)=HFB(HFB_chan,:)';    
end

for HFB_slow_chan=1:size(HFB,1)
    HFB_slow_ts(:,HFB_slow_chan)=HFB_slow(HFB_slow_chan,:)';      
end

for HFB_medium_chan=1:size(HFB,1)
    HFB_medium_ts(:,HFB_medium_chan)=HFB_medium(HFB_medium_chan,:)';      
end

% for Alpha_medium_chan=1:size(HFB,1)
%     Alpha_medium_ts(:,Alpha_medium_chan)=Alpha_medium(Alpha_medium_chan,:)';      
% end
% 
% for Beta1_medium_chan=1:size(HFB,1)
%     Beta1_medium_ts(:,Beta1_medium_chan)=Beta1_medium(Beta1_medium_chan,:)';      
% end
% 
% for Beta2_medium_chan=1:size(HFB,1)
%     Beta2_medium_ts(:,Beta2_medium_chan)=Beta2_medium(Beta2_medium_chan,:)';      
% end
% 
% for Theta_medium_chan=1:size(HFB,1)
%     Theta_medium_ts(:,Theta_medium_chan)=Theta_medium(Theta_medium_chan,:)';      
% end
% 
% for Delta_medium_chan=1:size(HFB,1)
%     Delta_medium_ts(:,Delta_medium_chan)=Delta_medium(Delta_medium_chan,:)';      
% end
% 
% for Gamma_medium_chan=1:size(HFB,1)
%     Gamma_medium_ts(:,Gamma_medium_chan)=Gamma_medium(Gamma_medium_chan,:)';      
% end
% 
% for HFB_fast_chan=1:size(HFB,1)
%     HFB_fast_ts(:,HFB_fast_chan)=HFB_fast(HFB_fast_chan,:)';      
% end

% for Alpha_fast_chan=1:size(HFB,1)
%     Alpha_fast_ts(:,Alpha_fast_chan)=Alpha_fast(Alpha_fast_chan,:)';      
% end
% 
% for Beta1_fast_chan=1:size(HFB,1)
%     Beta1_fast_ts(:,Beta1_fast_chan)=Beta1_fast(Beta1_fast_chan,:)';      
% end
% 
% for Beta2_fast_chan=1:size(HFB,1)
%     Beta2_fast_ts(:,Beta2_fast_chan)=Beta2_fast(Beta2_fast_chan,:)';      
% end
% 
% for Theta_fast_chan=1:size(HFB,1)
%     Theta_fast_ts(:,Theta_fast_chan)=Theta_fast(Theta_fast_chan,:)';      
% end
% 
% for Delta_fast_chan=1:size(HFB,1)
%     Delta_fast_ts(:,Delta_fast_chan)=Delta_fast(Delta_fast_chan,:)';      
% end
% 
% for Gamma_fast_chan=1:size(HFB,1)
%     Gamma_fast_ts(:,Gamma_fast_chan)=Gamma_fast(Gamma_fast_chan,:)';      
% end

% for SCP_medium_chan=1:size(HFB,1)
%     SCP_medium_ts(:,SCP_medium_chan)=SCP(SCP_medium_chan,:)';      
% end

end

% Chop iEEG time series (delete beginning time points) 
% change 'Chop' variable at beginning of code to change 
% Alpha_ts=Alpha_ts(Chop:length(Alpha_ts),:);
% Beta1_ts=Beta1_ts(Chop:length(Beta1_ts),:);
% Beta2_ts=Beta2_ts(Chop:length(Beta2_ts),:);
% Theta_ts=Theta_ts(Chop:length(Theta_ts),:);
% Delta_ts=Delta_ts(Chop:length(Delta_ts),:);
% Gamma_ts=Gamma_ts(Chop:length(Gamma_ts),:);
HFB_ts=HFB_ts(Chop:length(HFB_ts),:);
HFB_slow_ts=HFB_slow_ts(Chop:length(HFB_slow_ts),:);
HFB_medium_ts=HFB_medium_ts(Chop:length(HFB_medium_ts),:);
% Alpha_medium_ts=Alpha_medium_ts(Chop:length(Alpha_medium_ts),:);
% Beta1_medium_ts=Beta1_medium_ts(Chop:length(Beta1_medium_ts),:);
% Beta2_medium_ts=Beta2_medium_ts(Chop:length(Beta2_medium_ts),:);
% Theta_medium_ts=Theta_medium_ts(Chop:length(Theta_medium_ts),:);
% Delta_medium_ts=Delta_medium_ts(Chop:length(Delta_medium_ts),:);
% Gamma_medium_ts=Gamma_medium_ts(Chop:length(Gamma_medium_ts),:);
%SCP_medium_ts=SCP_medium_ts(Chop:length(SCP_medium_ts),:);
% HFB_fast_ts=HFB_fast_ts(Chop:length(HFB_fast_ts),:);
% Alpha_fast_ts=Alpha_fast_ts(Chop:length(Alpha_fast_ts),:);
% Beta1_fast_ts=Beta1_fast_ts(Chop:length(Beta1_fast_ts),:);
% Beta2_fast_ts=Beta2_fast_ts(Chop:length(Beta2_fast_ts),:);
% Theta_fast_ts=Theta_fast_ts(Chop:length(Theta_fast_ts),:);
% Delta_fast_ts=Delta_fast_ts(Chop:length(Delta_fast_ts),:);
% Gamma_fast_ts=Gamma_fast_ts(Chop:length(Gamma_fast_ts),:);
%BOLD_ts_iEEG_space=NaN(length(BOLD_ts),max(iElvis_to_iEEG_chanlabel));

%% Transform BOLD to iEEG space

for i=1:length(iElvis_to_iEEG_chanlabel)
    new_ind=iElvis_to_iEEG_chanlabel(i);
    elec_BOLD_ts=BOLD_ts(:,i);    
    BOLD_ts_iEEG_space(:,new_ind)=elec_BOLD_ts;
end

% vox_iEEG_space=[];
% %% Transform elec coordinates to iEEG order 
% for i=1:length(iElvis_to_iEEG_chanlabel)
%     new_ind=iElvis_to_iEEG_chanlabel(i);
%     elec_coord=vox(i,:);
%     vox_iEEG_space(new_ind,:)=elec_coord;
% end

% Transform network labels to iEEG order
if depth==2
for i=1:length(iElvis_to_iEEG_chanlabel)
    new_ind=iElvis_to_iEEG_chanlabel(i);
    elec_network_Yeo=Yeo_channetworks_iElvis(i);
    Yeo_network_iEEG_space(:,new_ind)=elec_network_Yeo;
    elec_network=channetworks_iElvis(i);
    network_iEEG_space(:,new_ind)=elec_network;
end
end



%% Find channels with HFB z-score spikes for exclusion
if use_bad==1
bad_indices=HFB_medium.badchannels; 
else
    bad_indices=[];
end
% use bad indices from HFB 0.1-1Hz file (where bursts were excluded) 

if HFB_spike_exclusion==1
for i=1:length(iElvis_to_iEEG_chanlabel);
    HFB_z=(HFB_ts(:,i)-mean(HFB_ts(:,i)))/std(HFB_ts(:,i));
    HFB_max=max(HFB_z);
    if HFB_max>HFB_zthresh;
        display(['Channel ' HFB.chanlabels{i} ' excluded due to HFB spikes']);
       bad_indices=[bad_indices i];         
    end   
end
end


%% Change bad channels, WM channels, and channels with overlapping coordinates to NaN
for i=1:length(bad_indices)
%     Gamma_ts(:,bad_indices(i))=NaN;
%     Delta_ts(:,bad_indices(i))=NaN;
%     Theta_ts(:,bad_indices(i))=NaN;
%     Beta2_ts(:,bad_indices(i))=NaN;
%     Beta1_ts(:,bad_indices(i))=NaN;
%     Alpha_ts(:,bad_indices(i))=NaN;
    HFB_ts(:,bad_indices(i))=NaN;
    HFB_slow_ts(:,bad_indices(i))=NaN;
    HFB_medium_ts(:,bad_indices(i))=NaN;
%     Alpha_medium_ts(:,bad_indices(i))=NaN;
%     Beta1_medium_ts(:,bad_indices(i))=NaN;
%     Beta2_medium_ts(:,bad_indices(i))=NaN;
%     Theta_medium_ts(:,bad_indices(i))=NaN;
%     Delta_medium_ts(:,bad_indices(i))=NaN;
%     Gamma_medium_ts(:,bad_indices(i))=NaN;
%     HFB_fast_ts(:,bad_indices(i))=NaN;
%     Alpha_fast_ts(:,bad_indices(i))=NaN;
%     Beta1_fast_ts(:,bad_indices(i))=NaN;
%     Beta2_fast_ts(:,bad_indices(i))=NaN;
%     Theta_fast_ts(:,bad_indices(i))=NaN;
%     Delta_fast_ts(:,bad_indices(i))=NaN;
%     Gamma_fast_ts(:,bad_indices(i))=NaN;
    %SCP_medium_ts(:,bad_indices(i))=NaN;
    BOLD_ts_iEEG_space(:,bad_indices(i))=NaN;
    if depth==2
    network_iEEG_space(bad_indices(i))=NaN;
    Yeo_network_iEEG_space(bad_indices(i))=NaN;
    end
    %vox_iEEG_space(bad_indices(i),:)=NaN;
end

overlap_elec=find((BOLD_ts_iEEG_space(1,:))==0); % WM and overlapping electrodes
for i=1:length(overlap_elec)
%     Theta_ts(:,overlap_elec(i))=NaN;
%     Delta_ts(:,overlap_elec(i))=NaN;
%     Gamma_ts(:,overlap_elec(i))=NaN;
%     Beta2_ts(:,overlap_elec(i))=NaN;
%     Beta1_ts(:,overlap_elec(i))=NaN;
%     Alpha_ts(:,overlap_elec(i))=NaN;
    HFB_ts(:,overlap_elec(i))=NaN;
    HFB_slow_ts(:,overlap_elec(i))=NaN;
    HFB_medium_ts(:,overlap_elec(i))=NaN;
%     Alpha_medium_ts(:,overlap_elec(i))=NaN;
%     Beta1_medium_ts(:,overlap_elec(i))=NaN;
%     Beta2_medium_ts(:,overlap_elec(i))=NaN;
%     Theta_medium_ts(:,overlap_elec(i))=NaN;
%     Delta_medium_ts(:,overlap_elec(i))=NaN;
%     Gamma_medium_ts(:,overlap_elec(i))=NaN;
%     HFB_fast_ts(:,overlap_elec(i))=NaN;
%     Alpha_fast_ts(:,overlap_elec(i))=NaN;
%     Beta1_fast_ts(:,overlap_elec(i))=NaN;
%     Beta2_fast_ts(:,overlap_elec(i))=NaN;
%     Theta_fast_ts(:,overlap_elec(i))=NaN;
%     Delta_fast_ts(:,overlap_elec(i))=NaN;
%     Gamma_fast_ts(:,overlap_elec(i))=NaN;
    %SCP_medium_ts(:,overlap_elec(i))=NaN;
    BOLD_ts_iEEG_space(:,overlap_elec(i))=NaN;
    if depth==2
    network_iEEG_space(overlap_elec(i))=NaN;
    Yeo_network_iEEG_space(overlap_elec(i))=NaN;
    end
    %vox_iEEG_space(overlap_elec(i),:)=NaN;
end

more_bad=[];
% Change any remaining NaNs in BOLD to NaNs in iEEG
for i=1:length(BOLD_ts_iEEG_space(1,:))
    if isnan(BOLD_ts_iEEG_space(1,i))==1
        more_bad=[more_bad i];
%          Alpha_ts(:,i)=NaN;
%          Beta1_ts(:,i)=NaN;
%          Beta2_ts(:,i)=NaN;
%          Theta_ts(:,i)=NaN;
%          Delta_ts(:,i)=NaN;
%          Gamma_ts(:,i)=NaN;
        HFB_ts(:,i)=NaN;
     HFB_slow_ts(:,i)=NaN;
     HFB_medium_ts(:,i)=NaN;
%      Alpha_medium_ts(:,i)=NaN;
%      Beta1_medium_ts(:,i)=NaN;
%      Beta2_medium_ts(:,i)=NaN;
%      Theta_medium_ts(:,i)=NaN;
%      Delta_medium_ts(:,i)=NaN;
%      Gamma_medium_ts(:,i)=NaN;
%      HFB_fast_ts(:,i)=NaN;
%      Alpha_fast_ts(:,i)=NaN;
%      Beta1_fast_ts(:,i)=NaN;
%      Beta2_fast_ts(:,i)=NaN;
%      Theta_fast_ts(:,i)=NaN;
%      Delta_fast_ts(:,i)=NaN;
%      Gamma_fast_ts(:,i)=NaN;
     %SCP_medium_ts(:,i)=NaN;
     if depth==2
     network_iEEG_space(i)=NaN;
     Yeo_network_iEEG_space(i)=NaN;
     end
     %vox_iEEG_space(i,:)=NaN;              
    end
end
all_bad_indices=more_bad;
save('all_bad_indices','all_bad_indices');

%% Transform iEEG and BOLD to iElvis order
BOLD_iElvis=NaN(size(BOLD_ts,1),length(chanlabels));

HFB_iElvis=NaN(size(HFB_ts,1),length(chanlabels));

for i=1:length(chanlabels);
    curr_iEEG_chan=channumbers_iEEG(i);
    new_ind=iEEG_to_iElvis_chanlabel(i);
    HFB_iElvis(:,new_ind)=HFB_ts(:,curr_iEEG_chan);
end

Alpha_iElvis=NaN(size(Alpha_ts,1),length(chanlabels));

for i=1:length(chanlabels);
    curr_iEEG_chan=channumbers_iEEG(i);
    new_ind=iEEG_to_iElvis_chanlabel(i);
    Alpha_iElvis(:,new_ind)=Alpha_ts(:,curr_iEEG_chan);
end

Beta1_iElvis=NaN(size(Beta1_ts,1),length(chanlabels));

for i=1:length(chanlabels);
    curr_iEEG_chan=channumbers_iEEG(i);
    new_ind=iEEG_to_iElvis_chanlabel(i);
    Beta1_iElvis(:,new_ind)=Beta1_ts(:,curr_iEEG_chan);
end

Beta2_iElvis=NaN(size(Beta2_ts,1),length(chanlabels));

for i=1:length(chanlabels);
    curr_iEEG_chan=channumbers_iEEG(i);
    new_ind=iEEG_to_iElvis_chanlabel(i);
    Beta2_iElvis(:,new_ind)=Beta2_ts(:,curr_iEEG_chan);
end

Theta_iElvis=NaN(size(Theta_ts,1),length(chanlabels));

for i=1:length(chanlabels);
    curr_iEEG_chan=channumbers_iEEG(i);
    new_ind=iEEG_to_iElvis_chanlabel(i);
    Theta_iElvis(:,new_ind)=Theta_ts(:,curr_iEEG_chan);
end

Delta_iElvis=NaN(size(Delta_ts,1),length(chanlabels));

for i=1:length(chanlabels);
    curr_iEEG_chan=channumbers_iEEG(i);
    new_ind=iEEG_to_iElvis_chanlabel(i);
    Delta_iElvis(:,new_ind)=Delta_ts(:,curr_iEEG_chan);
end

Gamma_iElvis=NaN(size(Gamma_ts,1),length(chanlabels));

for i=1:length(chanlabels);
    curr_iEEG_chan=channumbers_iEEG(i);
    new_ind=iEEG_to_iElvis_chanlabel(i);
    Gamma_iElvis(:,new_ind)=Gamma_ts(:,curr_iEEG_chan);
end

for i=1:length(chanlabels);
    curr_iEEG_chan=channumbers_iEEG(i);
    new_ind=iEEG_to_iElvis_chanlabel(i);
    BOLD_iElvis(:,new_ind)=BOLD_ts_iEEG_space(:,curr_iEEG_chan);
end

for i=1:length(chanlabels);
    curr_iEEG_chan=channumbers_iEEG(i);
    new_ind=iEEG_to_iElvis_chanlabel(i);
    HFB_medium_iElvis(:,new_ind)=HFB_medium_ts(:,curr_iEEG_chan);
end

HFB_medium_iElvis=NaN(size(HFB_medium_ts,1),length(chanlabels));

for i=1:length(chanlabels);
    curr_iEEG_chan=channumbers_iEEG(i);
    new_ind=iEEG_to_iElvis_chanlabel(i);
    HFB_medium_iElvis(:,new_ind)=HFB_medium_ts(:,curr_iEEG_chan);
end

HFB_slow_iElvis=NaN(size(HFB_slow_ts,1),length(chanlabels));

for i=1:length(chanlabels);
    curr_iEEG_chan=channumbers_iEEG(i);
    new_ind=iEEG_to_iElvis_chanlabel(i);
    HFB_slow_iElvis(:,new_ind)=HFB_slow_ts(:,curr_iEEG_chan);
end

Alpha_medium_iElvis=NaN(size(Alpha_medium_ts,1),length(chanlabels));

for i=1:length(chanlabels);
    curr_iEEG_chan=channumbers_iEEG(i);
    new_ind=iEEG_to_iElvis_chanlabel(i);
    Alpha_medium_iElvis(:,new_ind)=Alpha_medium_ts(:,curr_iEEG_chan);
end

Beta1_medium_iElvis=NaN(size(Beta1_medium_ts,1),length(chanlabels));

for i=1:length(chanlabels);
    curr_iEEG_chan=channumbers_iEEG(i);
    new_ind=iEEG_to_iElvis_chanlabel(i);
    Beta1_medium_iElvis(:,new_ind)=Beta1_medium_ts(:,curr_iEEG_chan);
end

Beta2_medium_iElvis=NaN(size(Beta2_medium_ts,1),length(chanlabels));

for i=1:length(chanlabels);
    curr_iEEG_chan=channumbers_iEEG(i);
    new_ind=iEEG_to_iElvis_chanlabel(i);
    Beta2_medium_iElvis(:,new_ind)=Beta2_medium_ts(:,curr_iEEG_chan);
end

Theta_medium_iElvis=NaN(size(Theta_medium_ts,1),length(chanlabels));

for i=1:length(chanlabels);
    curr_iEEG_chan=channumbers_iEEG(i);
    new_ind=iEEG_to_iElvis_chanlabel(i);
    Theta_medium_iElvis(:,new_ind)=Theta_medium_ts(:,curr_iEEG_chan);
end

Delta_medium_iElvis=NaN(size(Delta_medium_ts,1),length(chanlabels));

for i=1:length(chanlabels);
    curr_iEEG_chan=channumbers_iEEG(i);
    new_ind=iEEG_to_iElvis_chanlabel(i);
    Delta_medium_iElvis(:,new_ind)=Delta_medium_ts(:,curr_iEEG_chan);
end

Gamma_medium_iElvis=NaN(size(Gamma_medium_ts,1),length(chanlabels));

for i=1:length(chanlabels);
    curr_iEEG_chan=channumbers_iEEG(i);
    new_ind=iEEG_to_iElvis_chanlabel(i);
    Gamma_medium_iElvis(:,new_ind)=Gamma_medium_ts(:,curr_iEEG_chan);
end

%SCP_medium_iElvis=NaN(size(SCP_medium_ts,1),length(chanlabels));

for i=1:length(chanlabels);
    curr_iEEG_chan=channumbers_iEEG(i);
    new_ind=iEEG_to_iElvis_chanlabel(i);
    %SCP_medium_iElvis(:,new_ind)=SCP_medium_ts(:,curr_iEEG_chan);
end

HFB_fast_iElvis=NaN(size(HFB_fast_ts,1),length(chanlabels));

for i=1:length(chanlabels);
    curr_iEEG_chan=channumbers_iEEG(i);
    new_ind=iEEG_to_iElvis_chanlabel(i);
    HFB_fast_iElvis(:,new_ind)=HFB_fast_ts(:,curr_iEEG_chan);
end

Alpha_fast_iElvis=NaN(size(Alpha_fast_ts,1),length(chanlabels));

for i=1:length(chanlabels);
    curr_iEEG_chan=channumbers_iEEG(i);
    new_ind=iEEG_to_iElvis_chanlabel(i);
    Alpha_fast_iElvis(:,new_ind)=Alpha_fast_ts(:,curr_iEEG_chan);
end

Beta1_fast_iElvis=NaN(size(Beta1_fast_ts,1),length(chanlabels));

for i=1:length(chanlabels);
    curr_iEEG_chan=channumbers_iEEG(i);
    new_ind=iEEG_to_iElvis_chanlabel(i);
    Beta1_fast_iElvis(:,new_ind)=Beta1_fast_ts(:,curr_iEEG_chan);
end

Beta2_fast_iElvis=NaN(size(Beta2_fast_ts,1),length(chanlabels));

for i=1:length(chanlabels);
    curr_iEEG_chan=channumbers_iEEG(i);
    new_ind=iEEG_to_iElvis_chanlabel(i);
    Beta2_fast_iElvis(:,new_ind)=Beta2_fast_ts(:,curr_iEEG_chan);
end

Theta_fast_iElvis=NaN(size(Theta_fast_ts,1),length(chanlabels));

for i=1:length(chanlabels);
    curr_iEEG_chan=channumbers_iEEG(i);
    new_ind=iEEG_to_iElvis_chanlabel(i);
    Theta_fast_iElvis(:,new_ind)=Theta_fast_ts(:,curr_iEEG_chan);
end

Delta_fast_iElvis=NaN(size(Delta_fast_ts,1),length(chanlabels));

for i=1:length(chanlabels);
    curr_iEEG_chan=channumbers_iEEG(i);
    new_ind=iEEG_to_iElvis_chanlabel(i);
    Delta_fast_iElvis(:,new_ind)=Delta_fast_ts(:,curr_iEEG_chan);
end

Gamma_fast_iElvis=NaN(size(Gamma_fast_ts,1),length(chanlabels));

for i=1:length(chanlabels);
    curr_iEEG_chan=channumbers_iEEG(i);
    new_ind=iEEG_to_iElvis_chanlabel(i);
    Gamma_fast_iElvis(:,new_ind)=Gamma_fast_ts(:,curr_iEEG_chan);
end

%% Get vox coordinates (iElvis order) and remove bad indices
vox(find(isnan(BOLD_iElvis(1,:))),:)=NaN;

%% calculate FC in BOLD and ECoG
slow_allcorr=corrcoef(HFB_slow_iElvis); slow_column=slow_allcorr(:);
medium_allcorr=corrcoef(HFB_medium_iElvis); medium_column=medium_allcorr(:);
alpha_allcorr=corrcoef(Alpha_iElvis); alpha_column=alpha_allcorr(:);
beta1_allcorr=corrcoef(Beta1_iElvis); beta1_column=beta1_allcorr(:);
beta2_allcorr=corrcoef(Beta2_iElvis); beta2_column=beta2_allcorr(:);
Theta_allcorr=corrcoef(Theta_iElvis); Theta_column=Theta_allcorr(:);
Delta_allcorr=corrcoef(Delta_iElvis); Delta_column=Delta_allcorr(:);
Gamma_allcorr=corrcoef(Gamma_iElvis); Gamma_column=Gamma_allcorr(:);
HFB_allcorr=corrcoef(HFB_iElvis); HFB_column=HFB_allcorr(:);
alpha_medium_allcorr=corrcoef(Alpha_medium_iElvis); alpha_medium_column=alpha_medium_allcorr(:);
beta1_medium_allcorr=corrcoef(Beta1_medium_iElvis); beta1_medium_column=beta1_medium_allcorr(:);
beta2_medium_allcorr=corrcoef(Beta2_medium_iElvis); beta2_medium_column=beta2_medium_allcorr(:);
Theta_medium_allcorr=corrcoef(Theta_medium_iElvis); Theta_medium_column=Theta_medium_allcorr(:);
Delta_medium_allcorr=corrcoef(Delta_medium_iElvis); Delta_medium_column=Delta_medium_allcorr(:);
Gamma_medium_allcorr=corrcoef(Gamma_medium_iElvis); Gamma_medium_column=Gamma_medium_allcorr(:);
HFB_fast_allcorr=corrcoef(HFB_fast_iElvis); HFB_fast_column=HFB_fast_allcorr(:);
alpha_fast_allcorr=corrcoef(Alpha_fast_iElvis); alpha_fast_column=alpha_fast_allcorr(:);
beta1_fast_allcorr=corrcoef(Beta1_fast_iElvis); beta1_fast_column=beta1_fast_allcorr(:);
beta2_fast_allcorr=corrcoef(Beta2_fast_iElvis); beta2_fast_column=beta2_fast_allcorr(:);
Theta_fast_allcorr=corrcoef(Theta_fast_iElvis); Theta_fast_column=Theta_fast_allcorr(:);
Delta_fast_allcorr=corrcoef(Delta_fast_iElvis); Delta_fast_column=Delta_fast_allcorr(:);
Gamma_fast_allcorr=corrcoef(Gamma_fast_iElvis); Gamma_fast_column=Gamma_fast_allcorr(:);
%SCP_allcorr=corrcoef(SCP_medium_iElvis); SCP_column=SCP_allcorr(:);
BOLD_allcorr=corrcoef(BOLD_iElvis); BOLD_column=BOLD_allcorr(:);

slow_mat=slow_allcorr; slow_mat(find(slow_mat==1))=NaN; slow_mat(find(BOLD_allcorr>0.999))=NaN;
medium_mat=medium_allcorr; medium_mat(find(medium_mat==1))=NaN; medium_mat(find(BOLD_allcorr>0.999))=NaN;
alpha_mat=alpha_allcorr; alpha_mat(find(alpha_mat==1))=NaN; alpha_mat(find(BOLD_allcorr>0.999))=NaN;
beta1_mat=beta1_allcorr; beta1_mat(find(beta1_mat==1))=NaN; beta1_mat(find(BOLD_allcorr>0.999))=NaN;
beta2_mat=beta2_allcorr; beta2_mat(find(beta2_mat==1))=NaN; beta2_mat(find(BOLD_allcorr>0.999))=NaN;
Theta_mat=Theta_allcorr; Theta_mat(find(Theta_mat==1))=NaN; Theta_mat(find(BOLD_allcorr>0.999))=NaN;
Delta_mat=Delta_allcorr; Delta_mat(find(Delta_mat==1))=NaN; Delta_mat(find(BOLD_allcorr>0.999))=NaN;
Gamma_mat=Gamma_allcorr; Gamma_mat(find(Gamma_mat==1))=NaN; Gamma_mat(find(BOLD_allcorr>0.999))=NaN;
HFB_fast_mat=HFB_fast_allcorr; HFB_fast_mat(find(HFB_fast_mat==1))=NaN; HFB_fast_mat(find(BOLD_allcorr>0.999))=NaN;
alpha_fast_mat=alpha_fast_allcorr; alpha_fast_mat(find(alpha_fast_mat==1))=NaN; alpha_fast_mat(find(BOLD_allcorr>0.999))=NaN;
beta1_fast_mat=beta1_fast_allcorr; beta1_fast_mat(find(beta1_fast_mat==1))=NaN; beta1_fast_mat(find(BOLD_allcorr>0.999))=NaN;
beta2_fast_mat=beta2_fast_allcorr; beta2_fast_mat(find(beta2_fast_mat==1))=NaN; beta2_fast_mat(find(BOLD_allcorr>0.999))=NaN;
Theta_fast_mat=Theta_fast_allcorr; Theta_fast_mat(find(Theta_fast_mat==1))=NaN; Theta_fast_mat(find(BOLD_allcorr>0.999))=NaN;
Delta_fast_mat=Delta_fast_allcorr; Delta_fast_mat(find(Delta_fast_mat==1))=NaN; Delta_fast_mat(find(BOLD_allcorr>0.999))=NaN;
Gamma_fast_mat=Gamma_fast_allcorr; Gamma_fast_mat(find(Gamma_fast_mat==1))=NaN; Gamma_fast_mat(find(BOLD_allcorr>0.999))=NaN;
HFB_mat=HFB_allcorr; HFB_mat(find(HFB_mat==1))=NaN; HFB_mat(find(BOLD_allcorr>0.999))=NaN;
alpha_medium_mat=alpha_medium_allcorr; alpha_medium_mat(find(alpha_medium_mat==1))=NaN; alpha_medium_mat(find(BOLD_allcorr>0.999))=NaN;
beta1_medium_mat=beta1_medium_allcorr; beta1_medium_mat(find(beta1_medium_mat==1))=NaN; beta1_medium_mat(find(BOLD_allcorr>0.999))=NaN;
beta2_medium_mat=beta2_medium_allcorr; beta2_medium_mat(find(beta2_medium_mat==1))=NaN; beta2_medium_mat(find(BOLD_allcorr>0.999))=NaN;
Theta_medium_mat=Theta_medium_allcorr; Theta_medium_mat(find(Theta_medium_mat==1))=NaN; Theta_medium_mat(find(BOLD_allcorr>0.999))=NaN;
Delta_medium_mat=Delta_medium_allcorr; Delta_medium_mat(find(Delta_medium_mat==1))=NaN; Delta_medium_mat(find(BOLD_allcorr>0.999))=NaN;
Gamma_medium_mat=Gamma_medium_allcorr; Gamma_medium_mat(find(Gamma_medium_mat==1))=NaN; Gamma_medium_mat(find(BOLD_allcorr>0.999))=NaN;
%SCP_mat=SCP_allcorr; SCP_mat(find(SCP_mat==1))=NaN; SCP_mat(find(BOLD_allcorr>0.999))=NaN;
BOLD_mat=BOLD_allcorr; BOLD_mat(find(BOLD_mat>0.999))=NaN;

% remove diagonal and lower triangle
BOLD_column_ones=BOLD_column;
%medium_column(find(medium_column==0))=NaN; 
medium_column(find(BOLD_column_ones>0.999))=NaN; medium_column(isnan(medium_column))=[];
%slow_column(find(slow_column==0))=NaN; 
slow_column(BOLD_column_ones>0.999)=NaN; slow_column(isnan(slow_column))=[];
alpha_column(BOLD_column_ones>0.999)=NaN; alpha_column(isnan(alpha_column))=[];
beta1_column(BOLD_column_ones>0.999)=NaN; beta1_column(isnan(beta1_column))=[];
beta2_column(BOLD_column_ones>0.999)=NaN; beta2_column(isnan(beta2_column))=[];
Theta_column(BOLD_column_ones>0.999)=NaN; Theta_column(isnan(Theta_column))=[];
Delta_column(BOLD_column_ones>0.999)=NaN; Delta_column(isnan(Delta_column))=[];
Gamma_column(BOLD_column_ones>0.999)=NaN; Gamma_column(isnan(Gamma_column))=[];
HFB_column(BOLD_column_ones>0.999)=NaN; HFB_column(isnan(HFB_column))=[];
alpha_medium_column(BOLD_column_ones>0.999)=NaN; alpha_medium_column(isnan(alpha_medium_column))=[];
beta1_medium_column(BOLD_column_ones>0.999)=NaN; beta1_medium_column(isnan(beta1_medium_column))=[];
beta2_medium_column(BOLD_column_ones>0.999)=NaN; beta2_medium_column(isnan(beta2_medium_column))=[];
Theta_medium_column(BOLD_column_ones>0.999)=NaN; Theta_medium_column(isnan(Theta_medium_column))=[];
Delta_medium_column(BOLD_column_ones>0.999)=NaN; Delta_medium_column(isnan(Delta_medium_column))=[];
Gamma_medium_column(BOLD_column_ones>0.999)=NaN; Gamma_medium_column(isnan(Gamma_medium_column))=[];
HFB_fast_column(BOLD_column_ones>0.999)=NaN; HFB_fast_column(isnan(HFB_fast_column))=[];
alpha_fast_column(BOLD_column_ones>0.999)=NaN; alpha_fast_column(isnan(alpha_fast_column))=[];
beta1_fast_column(BOLD_column_ones>0.999)=NaN; beta1_fast_column(isnan(beta1_fast_column))=[];
beta2_fast_column(BOLD_column_ones>0.999)=NaN; beta2_fast_column(isnan(beta2_fast_column))=[];
Theta_fast_column(BOLD_column_ones>0.999)=NaN; Theta_fast_column(isnan(Theta_fast_column))=[];
Delta_fast_column(BOLD_column_ones>0.999)=NaN; Delta_fast_column(isnan(Delta_fast_column))=[];
Gamma_fast_column(BOLD_column_ones>0.999)=NaN; Gamma_fast_column(isnan(Gamma_fast_column))=[];
%SCP_column(BOLD_column_ones>0.999)=NaN; SCP_column(isnan(SCP_column))=[];
%BOLD_column(find(BOLD_column==0))=NaN; 
BOLD_column(find(BOLD_column_ones>0.999))=NaN; BOLD_column(isnan(BOLD_column))=[];

% Calculate distances
distances=zeros(size(vox,1));
for i = 1:size(vox,1)
 coord = vox(i,:);
     for ii = 1:size(vox,1)
         distances(i,ii)=sqrt((vox(ii,1)-coord(1))^2+(vox(ii,2)-coord(2))^2+(vox(ii,3)-coord(3))^2);
     end
end

distances(find(BOLD_allcorr>0.999))=NaN;
distance_column=distances(:);
distance_column(find(BOLD_column_ones>0.999))=NaN; distance_column(isnan(distance_column))=[];


% Remove short distance electrodes (<15mm euclidean)
BOLD_column_longrange=BOLD_column; medium_column_longrange=medium_column; slow_column_longrange=slow_column; 
alpha_column_longrange=alpha_column; beta1_column_longrange=beta1_column; beta2_column_longrange=beta2_column;
Theta_column_longrange=Theta_column; Delta_column_longrange=Delta_column; Gamma_column_longrange=Gamma_column;
HFB_column_longrange=HFB_column;
alpha_medium_column_longrange=alpha_medium_column; beta1_medium_column_longrange=beta1_medium_column; beta2_medium_column_longrange=beta2_medium_column;
Theta_medium_column_longrange=Theta_medium_column; Delta_medium_column_longrange=Delta_medium_column; Gamma_medium_column_longrange=Gamma_medium_column;
HFB_fast_column_longrange=HFB_fast_column;
alpha_fast_column_longrange=alpha_fast_column; beta1_fast_column_longrange=beta1_fast_column; beta2_fast_column_longrange=beta2_fast_column;
Theta_fast_column_longrange=Theta_fast_column; Delta_fast_column_longrange=Delta_fast_column; Gamma_fast_column_longrange=Gamma_fast_column;
%SCP_column_longrange=SCP_column;
% BOLD_column_longrange(find(distance_column<15))=[];
% medium_column_longrange(find(distance_column<15))=[];
% slow_column_longrange(find(distance_column<15))=[];

% Binary split dataset by distance
% long_dist_ind=find(distance_column>median(distance_column));
% short_dist_ind=find(distance_column<median(distance_column));
% BOLD_long=BOLD_column(long_dist_ind); BOLD_short=BOLD_column(short_dist_ind);
% medium_long=medium_column(long_dist_ind); medium_short=medium_column(short_dist_ind);
% slow_long=slow_column(long_dist_ind); slow_short=slow_column(short_dist_ind);
% alpha_long=alpha_column(long_dist_ind); alpha_short=alpha_column(short_dist_ind);
% beta1_long=beta1_column(long_dist_ind); beta1_short=beta1_column(short_dist_ind);

if depth~=2
   BOLD_scatter=BOLD_column;
   medium_scatter=medium_column;
   slow_scatter=slow_column;
   alpha_scatter=alpha_column;
   beta1_scatter=beta1_column;
   beta2_scatter=beta2_column;
   Theta_scatter=Theta_column;
   Delta_scatter=Delta_column;
   Gamma_scatter=Gamma_column;
   HFB_scatter=HFB_column;
   alpha_medium_scatter=alpha_medium_column;
   beta1_medium_scatter=beta1_medium_column;
   beta2_medium_scatter=beta2_medium_column;
   Theta_medium_scatter=Theta_medium_column;
   Delta_medium_scatter=Delta_medium_column;
   Gamma_medium_scatter=Gamma_medium_column;
   HFB_fast_scatter=HFB_fast_column;
   alpha_fast_scatter=alpha_fast_column;
   beta1_fast_scatter=beta1_fast_column;
   beta2_fast_scatter=beta2_fast_column;
   Theta_fast_scatter=Theta_fast_column;
   Delta_fast_scatter=Delta_fast_column;
   Gamma_fast_scatter=Gamma_fast_column;
   %SCP_scatter=SCP_column;
   distance_scatter=distance_column;
end
% calculate FC and distance within each network

% Remove any ROIs that have overlapping coordinates
%% Extract network time-courses from Yeo networks
if depth==2
Yeo_CoreDMN_BOLD_ts=BOLD_ts_iEEG_space(:,find(Yeo_network_iEEG_space==1));
Yeo_CoreDMN_ECoG_medium_ts=HFB_medium_ts(:,find(Yeo_network_iEEG_space==1));
Yeo_CoreDMN_ECoG_slow_ts=HFB_slow_ts(:,find(Yeo_network_iEEG_space==1));
Yeo_CoreDMN_ECoG_alpha_ts=Alpha_medium_ts(:,find(Yeo_network_iEEG_space==1));
Yeo_CoreDMN_ECoG_beta1_ts=Beta1_medium_ts(:,find(Yeo_network_iEEG_space==1));
Yeo_CoreDMN_ECoG_beta2_ts=Beta2_medium_ts(:,find(Yeo_network_iEEG_space==1));
Yeo_CoreDMN_ECoG_Theta_ts=Theta_medium_ts(:,find(Yeo_network_iEEG_space==1));
Yeo_CoreDMN_ECoG_Delta_ts=Delta_medium_ts(:,find(Yeo_network_iEEG_space==1));
Yeo_CoreDMN_ECoG_Gamma_ts=Gamma_medium_ts(:,find(Yeo_network_iEEG_space==1));
Yeo_CoreDMN_vox=vox_iEEG_space(find(Yeo_network_iEEG_space==1),:);

Yeo_CoreDMN_BOLD_corr=corrcoef(Yeo_CoreDMN_BOLD_ts); Yeo_CoreDMN_BOLD_column=Yeo_CoreDMN_BOLD_corr(:);
Yeo_CoreDMN_BOLD_column(find(Yeo_CoreDMN_BOLD_column==1))=NaN; Yeo_CoreDMN_BOLD_column(isnan(Yeo_CoreDMN_BOLD_column))=[];
Yeo_CoreDMN_medium_corr=corrcoef(Yeo_CoreDMN_ECoG_medium_ts); Yeo_CoreDMN_medium_column=Yeo_CoreDMN_medium_corr(:);
Yeo_CoreDMN_medium_column(find(Yeo_CoreDMN_medium_column==1))=NaN; Yeo_CoreDMN_medium_column(isnan(Yeo_CoreDMN_medium_column))=[];
Yeo_CoreDMN_slow_corr=corrcoef(Yeo_CoreDMN_ECoG_slow_ts); Yeo_CoreDMN_slow_column=Yeo_CoreDMN_slow_corr(:);
Yeo_CoreDMN_slow_column(find(Yeo_CoreDMN_slow_column==1))=NaN; Yeo_CoreDMN_slow_column(isnan(Yeo_CoreDMN_slow_column))=[];
Yeo_CoreDMN_alpha_corr=corrcoef(Yeo_CoreDMN_ECoG_alpha_ts); Yeo_CoreDMN_alpha_column=Yeo_CoreDMN_alpha_corr(:);
Yeo_CoreDMN_alpha_column(find(Yeo_CoreDMN_alpha_column==1))=NaN; Yeo_CoreDMN_alpha_column(isnan(Yeo_CoreDMN_alpha_column))=[];
Yeo_CoreDMN_beta1_corr=corrcoef(Yeo_CoreDMN_ECoG_beta1_ts); Yeo_CoreDMN_beta1_column=Yeo_CoreDMN_beta1_corr(:);
Yeo_CoreDMN_beta1_column(find(Yeo_CoreDMN_beta1_column==1))=NaN; Yeo_CoreDMN_beta1_column(isnan(Yeo_CoreDMN_beta1_column))=[];
Yeo_CoreDMN_beta2_corr=corrcoef(Yeo_CoreDMN_ECoG_beta2_ts); Yeo_CoreDMN_beta2_column=Yeo_CoreDMN_beta2_corr(:);
Yeo_CoreDMN_beta2_column(find(Yeo_CoreDMN_beta2_column==1))=NaN; Yeo_CoreDMN_beta2_column(isnan(Yeo_CoreDMN_beta2_column))=[];
Yeo_CoreDMN_Delta_corr=corrcoef(Yeo_CoreDMN_ECoG_Delta_ts); Yeo_CoreDMN_Delta_column=Yeo_CoreDMN_Delta_corr(:);
Yeo_CoreDMN_Delta_column(find(Yeo_CoreDMN_Delta_column==1))=NaN; Yeo_CoreDMN_Delta_column(isnan(Yeo_CoreDMN_Delta_column))=[];
Yeo_CoreDMN_Theta_corr=corrcoef(Yeo_CoreDMN_ECoG_Theta_ts); Yeo_CoreDMN_Theta_column=Yeo_CoreDMN_Theta_corr(:);
Yeo_CoreDMN_Theta_column(find(Yeo_CoreDMN_Theta_column==1))=NaN; Yeo_CoreDMN_Theta_column(isnan(Yeo_CoreDMN_Theta_column))=[];
Yeo_CoreDMN_Gamma_corr=corrcoef(Yeo_CoreDMN_ECoG_Gamma_ts); Yeo_CoreDMN_Gamma_column=Yeo_CoreDMN_Gamma_corr(:);
Yeo_CoreDMN_Gamma_column(find(Yeo_CoreDMN_Gamma_column==1))=NaN; Yeo_CoreDMN_Gamma_column(isnan(Yeo_CoreDMN_Gamma_column))=[];

Yeo_DAN_BOLD_ts=BOLD_ts_iEEG_space(:,find(Yeo_network_iEEG_space==6));
Yeo_DAN_ECoG_medium_ts=HFB_medium_ts(:,find(Yeo_network_iEEG_space==6));
Yeo_DAN_ECoG_slow_ts=HFB_slow_ts(:,find(Yeo_network_iEEG_space==6));
Yeo_DAN_ECoG_alpha_ts=Alpha_medium_ts(:,find(Yeo_network_iEEG_space==6));
Yeo_DAN_ECoG_beta1_ts=Beta1_medium_ts(:,find(Yeo_network_iEEG_space==6));
Yeo_DAN_ECoG_beta2_ts=Beta2_medium_ts(:,find(Yeo_network_iEEG_space==6));
Yeo_DAN_ECoG_Theta_ts=Theta_medium_ts(:,find(Yeo_network_iEEG_space==6));
Yeo_DAN_ECoG_Delta_ts=Delta_medium_ts(:,find(Yeo_network_iEEG_space==6));
Yeo_DAN_ECoG_Gamma_ts=Gamma_medium_ts(:,find(Yeo_network_iEEG_space==6));
Yeo_DAN_vox=vox_iEEG_space(find(Yeo_network_iEEG_space==6),:);

Yeo_DAN_BOLD_corr=corrcoef(Yeo_DAN_BOLD_ts); Yeo_DAN_BOLD_column=Yeo_DAN_BOLD_corr(:);
Yeo_DAN_BOLD_column(find(Yeo_DAN_BOLD_column==1))=NaN; Yeo_DAN_BOLD_column(isnan(Yeo_DAN_BOLD_column))=[];
Yeo_DAN_medium_corr=corrcoef(Yeo_DAN_ECoG_medium_ts); Yeo_DAN_medium_column=Yeo_DAN_medium_corr(:);
Yeo_DAN_medium_column(find(Yeo_DAN_medium_column==1))=NaN; Yeo_DAN_medium_column(isnan(Yeo_DAN_medium_column))=[];
Yeo_DAN_slow_corr=corrcoef(Yeo_DAN_ECoG_slow_ts); Yeo_DAN_slow_column=Yeo_DAN_slow_corr(:);
Yeo_DAN_slow_column(find(Yeo_DAN_slow_column==1))=NaN; Yeo_DAN_slow_column(isnan(Yeo_DAN_slow_column))=[];
Yeo_DAN_alpha_corr=corrcoef(Yeo_DAN_ECoG_alpha_ts); Yeo_DAN_alpha_column=Yeo_DAN_alpha_corr(:);
Yeo_DAN_alpha_column(find(Yeo_DAN_alpha_column==1))=NaN; Yeo_DAN_alpha_column(isnan(Yeo_DAN_alpha_column))=[];
Yeo_DAN_beta1_corr=corrcoef(Yeo_DAN_ECoG_beta1_ts); Yeo_DAN_beta1_column=Yeo_DAN_beta1_corr(:);
Yeo_DAN_beta1_column(find(Yeo_DAN_beta1_column==1))=NaN; Yeo_DAN_beta1_column(isnan(Yeo_DAN_beta1_column))=[];
Yeo_DAN_beta1_corr=corrcoef(Yeo_DAN_ECoG_beta1_ts); Yeo_DAN_beta1_column=Yeo_DAN_beta1_corr(:);
Yeo_DAN_beta1_column(find(Yeo_DAN_beta1_column==1))=NaN; Yeo_DAN_beta1_column(isnan(Yeo_DAN_beta1_column))=[];
Yeo_DAN_beta2_corr=corrcoef(Yeo_DAN_ECoG_beta2_ts); Yeo_DAN_beta2_column=Yeo_DAN_beta2_corr(:);
Yeo_DAN_beta2_column(find(Yeo_DAN_beta2_column==1))=NaN; Yeo_DAN_beta2_column(isnan(Yeo_DAN_beta2_column))=[];
Yeo_DAN_Theta_corr=corrcoef(Yeo_DAN_ECoG_Theta_ts); Yeo_DAN_Theta_column=Yeo_DAN_Theta_corr(:);
Yeo_DAN_Theta_column(find(Yeo_DAN_Theta_column==1))=NaN; Yeo_DAN_Theta_column(isnan(Yeo_DAN_Theta_column))=[];
Yeo_DAN_Delta_corr=corrcoef(Yeo_DAN_ECoG_Delta_ts); Yeo_DAN_Delta_column=Yeo_DAN_Delta_corr(:);
Yeo_DAN_Delta_column(find(Yeo_DAN_Delta_column==1))=NaN; Yeo_DAN_Delta_column(isnan(Yeo_DAN_Delta_column))=[];
Yeo_DAN_Gamma_corr=corrcoef(Yeo_DAN_ECoG_Gamma_ts); Yeo_DAN_Gamma_column=Yeo_DAN_Gamma_corr(:);
Yeo_DAN_Gamma_column(find(Yeo_DAN_Gamma_column==1))=NaN; Yeo_DAN_Gamma_column(isnan(Yeo_DAN_Gamma_column))=[];

Yeo_VAN_BOLD_ts=BOLD_ts_iEEG_space(:,find(Yeo_network_iEEG_space==3));
Yeo_VAN_ECoG_medium_ts=HFB_medium_ts(:,find(Yeo_network_iEEG_space==3));
Yeo_VAN_ECoG_slow_ts=HFB_slow_ts(:,find(Yeo_network_iEEG_space==3));
Yeo_VAN_ECoG_alpha_ts=Alpha_medium_ts(:,find(Yeo_network_iEEG_space==3));
Yeo_VAN_ECoG_beta1_ts=Beta1_medium_ts(:,find(Yeo_network_iEEG_space==3));
Yeo_VAN_ECoG_beta2_ts=Beta2_medium_ts(:,find(Yeo_network_iEEG_space==3));
Yeo_VAN_ECoG_Theta_ts=Theta_medium_ts(:,find(Yeo_network_iEEG_space==3));
Yeo_VAN_ECoG_Delta_ts=Delta_medium_ts(:,find(Yeo_network_iEEG_space==3));
Yeo_VAN_ECoG_Gamma_ts=Gamma_medium_ts(:,find(Yeo_network_iEEG_space==3));
Yeo_VAN_vox=vox_iEEG_space(find(Yeo_network_iEEG_space==3),:);

Yeo_VAN_BOLD_corr=corrcoef(Yeo_VAN_BOLD_ts); Yeo_VAN_BOLD_column=Yeo_VAN_BOLD_corr(:);
Yeo_VAN_BOLD_column(find(Yeo_VAN_BOLD_column==1))=NaN; Yeo_VAN_BOLD_column(isnan(Yeo_VAN_BOLD_column))=[];
Yeo_VAN_medium_corr=corrcoef(Yeo_VAN_ECoG_medium_ts); Yeo_VAN_medium_column=Yeo_VAN_medium_corr(:);
Yeo_VAN_medium_column(find(Yeo_VAN_medium_column==1))=NaN; Yeo_VAN_medium_column(isnan(Yeo_VAN_medium_column))=[];
Yeo_VAN_slow_corr=corrcoef(Yeo_VAN_ECoG_slow_ts); Yeo_VAN_slow_column=Yeo_VAN_slow_corr(:);
Yeo_VAN_slow_column(find(Yeo_VAN_slow_column==1))=NaN; Yeo_VAN_slow_column(isnan(Yeo_VAN_slow_column))=[];
Yeo_VAN_alpha_corr=corrcoef(Yeo_VAN_ECoG_alpha_ts); Yeo_VAN_alpha_column=Yeo_VAN_alpha_corr(:);
Yeo_VAN_alpha_column(find(Yeo_VAN_alpha_column==1))=NaN; Yeo_VAN_alpha_column(isnan(Yeo_VAN_alpha_column))=[];
Yeo_VAN_beta1_corr=corrcoef(Yeo_VAN_ECoG_beta1_ts); Yeo_VAN_beta1_column=Yeo_VAN_beta1_corr(:);
Yeo_VAN_beta1_column(find(Yeo_VAN_beta1_column==1))=NaN; Yeo_VAN_beta1_column(isnan(Yeo_VAN_beta1_column))=[];
Yeo_VAN_beta2_corr=corrcoef(Yeo_VAN_ECoG_beta2_ts); Yeo_VAN_beta2_column=Yeo_VAN_beta2_corr(:);
Yeo_VAN_beta2_column(find(Yeo_VAN_beta2_column==1))=NaN; Yeo_VAN_beta2_column(isnan(Yeo_VAN_beta2_column))=[];
Yeo_VAN_Theta_corr=corrcoef(Yeo_VAN_ECoG_Theta_ts); Yeo_VAN_Theta_column=Yeo_VAN_Theta_corr(:);
Yeo_VAN_Theta_column(find(Yeo_VAN_Theta_column==1))=NaN; Yeo_VAN_Theta_column(isnan(Yeo_VAN_Theta_column))=[];
Yeo_VAN_Delta_corr=corrcoef(Yeo_VAN_ECoG_Delta_ts); Yeo_VAN_Delta_column=Yeo_VAN_Delta_corr(:);
Yeo_VAN_Delta_column(find(Yeo_VAN_Delta_column==1))=NaN; Yeo_VAN_Delta_column(isnan(Yeo_VAN_Delta_column))=[];
Yeo_VAN_Gamma_corr=corrcoef(Yeo_VAN_ECoG_Gamma_ts); Yeo_VAN_Gamma_column=Yeo_VAN_Gamma_corr(:);
Yeo_VAN_Gamma_column(find(Yeo_VAN_Gamma_column==1))=NaN; Yeo_VAN_Gamma_column(isnan(Yeo_VAN_Gamma_column))=[];
end

%% Extract network time-courses from IndiPar networks
if depth==2
DMN_BOLD_ts=BOLD_ts_iEEG_space(:,find(network_iEEG_space==1));
DMN_ECoG_medium_ts=HFB_medium_ts(:,find(network_iEEG_space==1));
DMN_ECoG_slow_ts=HFB_slow_ts(:,find(network_iEEG_space==1));
DMN_ECoG_alpha_ts=Alpha_medium_ts(:,find(network_iEEG_space==1));
DMN_ECoG_beta1_ts=Beta1_medium_ts(:,find(network_iEEG_space==1));
DMN_ECoG_beta2_ts=Beta2_medium_ts(:,find(network_iEEG_space==1));
DMN_ECoG_Theta_ts=Theta_medium_ts(:,find(network_iEEG_space==1));
DMN_ECoG_Delta_ts=Delta_medium_ts(:,find(network_iEEG_space==1));
DMN_ECoG_Gamma_ts=Gamma_medium_ts(:,find(network_iEEG_space==1));
DMN_vox=vox_iEEG_space(find(network_iEEG_space==1),:);

DMN_BOLD_corr=corrcoef(DMN_BOLD_ts); DMN_BOLD_column=DMN_BOLD_corr(:);
DMN_BOLD_column(find(DMN_BOLD_column==1))=NaN; DMN_BOLD_column(isnan(DMN_BOLD_column))=[];
DMN_medium_corr=corrcoef(DMN_ECoG_medium_ts); DMN_medium_column=DMN_medium_corr(:);
DMN_medium_column(find(DMN_medium_column==1))=NaN; DMN_medium_column(isnan(DMN_medium_column))=[];
DMN_slow_corr=corrcoef(DMN_ECoG_slow_ts); DMN_slow_column=DMN_slow_corr(:);
DMN_slow_column(find(DMN_slow_column==1))=NaN; DMN_slow_column(isnan(DMN_slow_column))=[];
DMN_alpha_corr=corrcoef(DMN_ECoG_alpha_ts); DMN_alpha_column=DMN_alpha_corr(:);
DMN_alpha_column(find(DMN_alpha_column==1))=NaN; DMN_alpha_column(isnan(DMN_alpha_column))=[];
DMN_beta1_corr=corrcoef(DMN_ECoG_beta1_ts); DMN_beta1_column=DMN_beta1_corr(:);
DMN_beta1_column(find(DMN_beta1_column==1))=NaN; DMN_beta1_column(isnan(DMN_beta1_column))=[];
DMN_beta2_corr=corrcoef(DMN_ECoG_beta2_ts); DMN_beta2_column=DMN_beta2_corr(:);
DMN_beta2_column(find(DMN_beta2_column==1))=NaN; DMN_beta2_column(isnan(DMN_beta2_column))=[];
DMN_Theta_corr=corrcoef(DMN_ECoG_Theta_ts); DMN_Theta_column=DMN_Theta_corr(:);
DMN_Theta_column(find(DMN_Theta_column==1))=NaN; DMN_Theta_column(isnan(DMN_Theta_column))=[];
DMN_Delta_corr=corrcoef(DMN_ECoG_Delta_ts); DMN_Delta_column=DMN_Delta_corr(:);
DMN_Delta_column(find(DMN_Delta_column==1))=NaN; DMN_Delta_column(isnan(DMN_Delta_column))=[];
DMN_Gamma_corr=corrcoef(DMN_ECoG_Gamma_ts); DMN_Gamma_column=DMN_Gamma_corr(:);
DMN_Gamma_column(find(DMN_Gamma_column==1))=NaN; DMN_Gamma_column(isnan(DMN_Gamma_column))=[];

FPN_BOLD_ts=BOLD_ts_iEEG_space(:,find(network_iEEG_space==2));
FPN_ECoG_medium_ts=HFB_medium_ts(:,find(network_iEEG_space==2));
FPN_ECoG_slow_ts=HFB_slow_ts(:,find(network_iEEG_space==2));
FPN_ECoG_alpha_ts=Alpha_medium_ts(:,find(network_iEEG_space==2));
FPN_ECoG_beta1_ts=Beta1_medium_ts(:,find(network_iEEG_space==2));
FPN_ECoG_beta2_ts=Beta2_medium_ts(:,find(network_iEEG_space==2));
FPN_ECoG_Theta_ts=Theta_medium_ts(:,find(network_iEEG_space==2));
FPN_ECoG_Delta_ts=Delta_medium_ts(:,find(network_iEEG_space==2));
FPN_ECoG_Gamma_ts=Gamma_medium_ts(:,find(network_iEEG_space==2));
FPN_vox=vox_iEEG_space(find(network_iEEG_space==2),:);

FPN_BOLD_corr=corrcoef(FPN_BOLD_ts); FPN_BOLD_column=FPN_BOLD_corr(:);
FPN_BOLD_column(find(FPN_BOLD_column==1))=NaN; FPN_BOLD_column(isnan(FPN_BOLD_column))=[];
FPN_medium_corr=corrcoef(FPN_ECoG_medium_ts); FPN_medium_column=FPN_medium_corr(:);
FPN_medium_column(find(FPN_medium_column==1))=NaN; FPN_medium_column(isnan(FPN_medium_column))=[];
FPN_slow_corr=corrcoef(FPN_ECoG_slow_ts); FPN_slow_column=FPN_slow_corr(:);
FPN_slow_column(find(FPN_slow_column==1))=NaN; FPN_slow_column(isnan(FPN_slow_column))=[];
FPN_alpha_corr=corrcoef(FPN_ECoG_alpha_ts); FPN_alpha_column=FPN_alpha_corr(:);
FPN_alpha_column(find(FPN_alpha_column==1))=NaN; FPN_alpha_column(isnan(FPN_alpha_column))=[];
FPN_beta1_corr=corrcoef(FPN_ECoG_beta1_ts); FPN_beta1_column=FPN_beta1_corr(:);
FPN_beta1_column(find(FPN_beta1_column==1))=NaN; FPN_beta1_column(isnan(FPN_beta1_column))=[];
FPN_beta2_corr=corrcoef(FPN_ECoG_beta2_ts); FPN_beta2_column=FPN_beta2_corr(:);
FPN_beta2_column(find(FPN_beta2_column==1))=NaN; FPN_beta2_column(isnan(FPN_beta2_column))=[];
FPN_Theta_corr=corrcoef(FPN_ECoG_Theta_ts); FPN_Theta_column=FPN_Theta_corr(:);
FPN_Theta_column(find(FPN_Theta_column==1))=NaN; FPN_Theta_column(isnan(FPN_Theta_column))=[];
FPN_Delta_corr=corrcoef(FPN_ECoG_Delta_ts); FPN_Delta_column=FPN_Delta_corr(:);
FPN_Delta_column(find(FPN_Delta_column==1))=NaN; FPN_Delta_column(isnan(FPN_Delta_column))=[];
FPN_Gamma_corr=corrcoef(FPN_ECoG_Gamma_ts); FPN_Gamma_column=FPN_Gamma_corr(:);
FPN_Gamma_column(find(FPN_Gamma_column==1))=NaN; FPN_Gamma_column(isnan(FPN_Gamma_column))=[];

VAN_BOLD_ts=BOLD_ts_iEEG_space(:,find(network_iEEG_space==3));
VAN_ECoG_medium_ts=HFB_medium_ts(:,find(network_iEEG_space==3));
VAN_ECoG_slow_ts=HFB_slow_ts(:,find(network_iEEG_space==3));
VAN_ECoG_alpha_ts=Alpha_medium_ts(:,find(network_iEEG_space==3));
VAN_ECoG_beta1_ts=Beta1_medium_ts(:,find(network_iEEG_space==3));
VAN_ECoG_beta2_ts=Beta2_medium_ts(:,find(network_iEEG_space==3));
VAN_ECoG_Theta_ts=Theta_medium_ts(:,find(network_iEEG_space==3));
VAN_ECoG_Delta_ts=Delta_medium_ts(:,find(network_iEEG_space==3));
VAN_ECoG_Gamma_ts=Gamma_medium_ts(:,find(network_iEEG_space==3));
VAN_vox=vox_iEEG_space(find(network_iEEG_space==3),:);

VAN_BOLD_corr=corrcoef(VAN_BOLD_ts); VAN_BOLD_column=VAN_BOLD_corr(:);
VAN_BOLD_column(find(VAN_BOLD_column==1))=NaN; VAN_BOLD_column(isnan(VAN_BOLD_column))=[];
VAN_medium_corr=corrcoef(VAN_ECoG_medium_ts); VAN_medium_column=VAN_medium_corr(:);
VAN_medium_column(find(VAN_medium_column==1))=NaN; VAN_medium_column(isnan(VAN_medium_column))=[];
VAN_slow_corr=corrcoef(VAN_ECoG_slow_ts); VAN_slow_column=VAN_slow_corr(:);
VAN_slow_column(find(VAN_slow_column==1))=NaN; VAN_slow_column(isnan(VAN_slow_column))=[];
VAN_alpha_corr=corrcoef(VAN_ECoG_alpha_ts); VAN_alpha_column=VAN_alpha_corr(:);
VAN_alpha_column(find(VAN_alpha_column==1))=NaN; VAN_alpha_column(isnan(VAN_alpha_column))=[];
VAN_beta1_corr=corrcoef(VAN_ECoG_beta1_ts); VAN_beta1_column=VAN_beta1_corr(:);
VAN_beta1_column(find(VAN_beta1_column==1))=NaN; VAN_beta1_column(isnan(VAN_beta1_column))=[];
VAN_beta2_corr=corrcoef(VAN_ECoG_beta2_ts); VAN_beta2_column=VAN_beta2_corr(:);
VAN_beta2_column(find(VAN_beta2_column==1))=NaN; VAN_beta2_column(isnan(VAN_beta2_column))=[];
VAN_Theta_corr=corrcoef(VAN_ECoG_Theta_ts); VAN_Theta_column=VAN_Theta_corr(:);
VAN_Theta_column(find(VAN_Theta_column==1))=NaN; VAN_Theta_column(isnan(VAN_Theta_column))=[];
VAN_Delta_corr=corrcoef(VAN_ECoG_Delta_ts); VAN_Delta_column=VAN_Delta_corr(:);
VAN_Delta_column(find(VAN_Delta_column==1))=NaN; VAN_Delta_column(isnan(VAN_Delta_column))=[];
VAN_Gamma_corr=corrcoef(VAN_ECoG_Gamma_ts); VAN_Gamma_column=VAN_Gamma_corr(:);
VAN_Gamma_column(find(VAN_Gamma_column==1))=NaN; VAN_Gamma_column(isnan(VAN_Gamma_column))=[];

SMN_BOLD_ts=BOLD_ts_iEEG_space(:,find(network_iEEG_space==4));
SMN_ECoG_medium_ts=HFB_medium_ts(:,find(network_iEEG_space==4));
SMN_ECoG_slow_ts=HFB_slow_ts(:,find(network_iEEG_space==4));
SMN_ECoG_alpha_ts=Alpha_medium_ts(:,find(network_iEEG_space==4));
SMN_ECoG_beta1_ts=Beta1_medium_ts(:,find(network_iEEG_space==4));
SMN_ECoG_beta2_ts=Beta2_medium_ts(:,find(network_iEEG_space==4));
SMN_ECoG_Theta_ts=Theta_medium_ts(:,find(network_iEEG_space==4));
SMN_ECoG_Delta_ts=Delta_medium_ts(:,find(network_iEEG_space==4));
SMN_ECoG_Gamma_ts=Gamma_medium_ts(:,find(network_iEEG_space==4));
SMN_vox=vox_iEEG_space(find(network_iEEG_space==4),:);

SMN_BOLD_corr=corrcoef(SMN_BOLD_ts); SMN_BOLD_column=SMN_BOLD_corr(:);
SMN_BOLD_column(find(SMN_BOLD_column==1))=NaN; SMN_BOLD_column(isnan(SMN_BOLD_column))=[];
SMN_medium_corr=corrcoef(SMN_ECoG_medium_ts); SMN_medium_column=SMN_medium_corr(:);
SMN_medium_column(find(SMN_medium_column==1))=NaN; SMN_medium_column(isnan(SMN_medium_column))=[];
SMN_slow_corr=corrcoef(SMN_ECoG_slow_ts); SMN_slow_column=SMN_slow_corr(:);
SMN_slow_column(find(SMN_slow_column==1))=NaN; SMN_slow_column(isnan(SMN_slow_column))=[];
SMN_alpha_corr=corrcoef(SMN_ECoG_alpha_ts); SMN_alpha_column=SMN_alpha_corr(:);
SMN_alpha_column(find(SMN_alpha_column==1))=NaN; SMN_alpha_column(isnan(SMN_alpha_column))=[];
SMN_beta1_corr=corrcoef(SMN_ECoG_beta1_ts); SMN_beta1_column=SMN_beta1_corr(:);
SMN_beta1_column(find(SMN_beta1_column==1))=NaN; SMN_beta1_column(isnan(SMN_beta1_column))=[];
SMN_beta2_corr=corrcoef(SMN_ECoG_beta2_ts); SMN_beta2_column=SMN_beta2_corr(:);
SMN_beta2_column(find(SMN_beta2_column==1))=NaN; SMN_beta2_column(isnan(SMN_beta2_column))=[];
SMN_Theta_corr=corrcoef(SMN_ECoG_Theta_ts); SMN_Theta_column=SMN_Theta_corr(:);
SMN_Theta_column(find(SMN_Theta_column==1))=NaN; SMN_Theta_column(isnan(SMN_Theta_column))=[];
SMN_Delta_corr=corrcoef(SMN_ECoG_Delta_ts); SMN_Delta_column=SMN_Delta_corr(:);
SMN_Delta_column(find(SMN_Delta_column==1))=NaN; SMN_Delta_column(isnan(SMN_Delta_column))=[];
SMN_Gamma_corr=corrcoef(SMN_ECoG_Gamma_ts); SMN_Gamma_column=SMN_Gamma_corr(:);
SMN_Gamma_column(find(SMN_Gamma_column==1))=NaN; SMN_Gamma_column(isnan(SMN_Gamma_column))=[];

Visual_BOLD_ts=BOLD_ts_iEEG_space(:,find(network_iEEG_space==5));
Visual_ECoG_medium_ts=HFB_medium_ts(:,find(network_iEEG_space==5));
Visual_ECoG_slow_ts=HFB_slow_ts(:,find(network_iEEG_space==5));
Visual_ECoG_alpha_ts=Alpha_medium_ts(:,find(network_iEEG_space==5));
Visual_ECoG_beta1_ts=Beta1_medium_ts(:,find(network_iEEG_space==5));
Visual_ECoG_beta2_ts=Beta2_medium_ts(:,find(network_iEEG_space==5));
Visual_ECoG_Theta_ts=Theta_medium_ts(:,find(network_iEEG_space==5));
Visual_ECoG_Delta_ts=Delta_medium_ts(:,find(network_iEEG_space==5));
Visual_ECoG_Gamma_ts=Gamma_medium_ts(:,find(network_iEEG_space==5));
Visual_vox=vox_iEEG_space(find(network_iEEG_space==5),:);

Visual_BOLD_corr=corrcoef(Visual_BOLD_ts); Visual_BOLD_column=Visual_BOLD_corr(:);
Visual_BOLD_column(find(Visual_BOLD_column==1))=NaN; Visual_BOLD_column(isnan(Visual_BOLD_column))=[];
Visual_medium_corr=corrcoef(Visual_ECoG_medium_ts); Visual_medium_column=Visual_medium_corr(:);
Visual_medium_column(find(Visual_medium_column==1))=NaN; Visual_medium_column(isnan(Visual_medium_column))=[];
Visual_slow_corr=corrcoef(Visual_ECoG_slow_ts); Visual_slow_column=Visual_slow_corr(:);
Visual_slow_column(find(Visual_slow_column==1))=NaN; Visual_slow_column(isnan(Visual_slow_column))=[];
Visual_alpha_corr=corrcoef(Visual_ECoG_alpha_ts); Visual_alpha_column=Visual_alpha_corr(:);
Visual_alpha_column(find(Visual_alpha_column==1))=NaN; Visual_alpha_column(isnan(Visual_alpha_column))=[];
Visual_beta1_corr=corrcoef(Visual_ECoG_beta1_ts); Visual_beta1_column=Visual_beta1_corr(:);
Visual_beta1_column(find(Visual_beta1_column==1))=NaN; Visual_beta1_column(isnan(Visual_beta1_column))=[];
Visual_beta2_corr=corrcoef(Visual_ECoG_beta2_ts); Visual_beta2_column=Visual_beta2_corr(:);
Visual_beta2_column(find(Visual_beta2_column==1))=NaN; Visual_beta2_column(isnan(Visual_beta2_column))=[];
Visual_Theta_corr=corrcoef(Visual_ECoG_Theta_ts); Visual_Theta_column=Visual_Theta_corr(:);
Visual_Theta_column(find(Visual_Theta_column==1))=NaN; Visual_Theta_column(isnan(Visual_Theta_column))=[];
Visual_Delta_corr=corrcoef(Visual_ECoG_Delta_ts); Visual_Delta_column=Visual_Delta_corr(:);
Visual_Delta_column(find(Visual_Delta_column==1))=NaN; Visual_Delta_column(isnan(Visual_Delta_column))=[];
Visual_Gamma_corr=corrcoef(Visual_ECoG_Gamma_ts); Visual_Gamma_column=Visual_Gamma_corr(:);
Visual_Gamma_column(find(Visual_Gamma_column==1))=NaN; Visual_Gamma_column(isnan(Visual_Gamma_column))=[];

DAN_BOLD_ts=BOLD_ts_iEEG_space(:,find(network_iEEG_space==6));
DAN_ECoG_medium_ts=HFB_medium_ts(:,find(network_iEEG_space==6));
DAN_ECoG_slow_ts=HFB_slow_ts(:,find(network_iEEG_space==6));
DAN_ECoG_alpha_ts=Alpha_medium_ts(:,find(network_iEEG_space==6));
DAN_ECoG_beta1_ts=Beta1_medium_ts(:,find(network_iEEG_space==6));
DAN_ECoG_beta2_ts=Beta2_medium_ts(:,find(network_iEEG_space==6));
DAN_ECoG_Theta_ts=Theta_medium_ts(:,find(network_iEEG_space==6));
DAN_ECoG_Delta_ts=Delta_medium_ts(:,find(network_iEEG_space==6));
DAN_ECoG_Gamma_ts=Gamma_medium_ts(:,find(network_iEEG_space==6));
DAN_vox=vox_iEEG_space(find(network_iEEG_space==6),:);

DAN_BOLD_corr=corrcoef(DAN_BOLD_ts); DAN_BOLD_column=DAN_BOLD_corr(:);
DAN_BOLD_column(find(DAN_BOLD_column==1))=NaN; DAN_BOLD_column(isnan(DAN_BOLD_column))=[];
DAN_medium_corr=corrcoef(DAN_ECoG_medium_ts); DAN_medium_column=DAN_medium_corr(:);
DAN_medium_column(find(DAN_medium_column==1))=NaN; DAN_medium_column(isnan(DAN_medium_column))=[];
DAN_slow_corr=corrcoef(DAN_ECoG_slow_ts); DAN_slow_column=DAN_slow_corr(:);
DAN_slow_column(find(DAN_slow_column==1))=NaN; DAN_slow_column(isnan(DAN_slow_column))=[];
DAN_alpha_corr=corrcoef(DAN_ECoG_alpha_ts); DAN_alpha_column=DAN_alpha_corr(:);
DAN_alpha_column(find(DAN_alpha_column==1))=NaN; DAN_alpha_column(isnan(DAN_alpha_column))=[];
DAN_beta1_corr=corrcoef(DAN_ECoG_beta1_ts); DAN_beta1_column=DAN_beta1_corr(:);
DAN_beta1_column(find(DAN_beta1_column==1))=NaN; DAN_beta1_column(isnan(DAN_beta1_column))=[];
DAN_beta2_corr=corrcoef(DAN_ECoG_beta2_ts); DAN_beta2_column=DAN_beta2_corr(:);
DAN_beta2_column(find(DAN_beta2_column==1))=NaN; DAN_beta2_column(isnan(DAN_beta2_column))=[];
DAN_Theta_corr=corrcoef(DAN_ECoG_Theta_ts); DAN_Theta_column=DAN_Theta_corr(:);
DAN_Theta_column(find(DAN_Theta_column==1))=NaN; DAN_Theta_column(isnan(DAN_Theta_column))=[];
DAN_Delta_corr=corrcoef(DAN_ECoG_Delta_ts); DAN_Delta_column=DAN_Delta_corr(:);
DAN_Delta_column(find(DAN_Delta_column==1))=NaN; DAN_Delta_column(isnan(DAN_Delta_column))=[];
DAN_Gamma_corr=corrcoef(DAN_ECoG_Gamma_ts); DAN_Gamma_column=DAN_Gamma_corr(:);
DAN_Gamma_column(find(DAN_Gamma_column==1))=NaN; DAN_Gamma_column(isnan(DAN_Gamma_column))=[];

Language_BOLD_ts=BOLD_ts_iEEG_space(:,find(network_iEEG_space==7));
Language_ECoG_medium_ts=HFB_medium_ts(:,find(network_iEEG_space==7));
Language_ECoG_slow_ts=HFB_slow_ts(:,find(network_iEEG_space==7));
Language_ECoG_alpha_ts=Alpha_medium_ts(:,find(network_iEEG_space==7));
Language_ECoG_beta1_ts=Beta1_medium_ts(:,find(network_iEEG_space==7));
Language_ECoG_beta2_ts=Beta2_medium_ts(:,find(network_iEEG_space==7));
Language_ECoG_Theta_ts=Theta_medium_ts(:,find(network_iEEG_space==7));
Language_ECoG_Delta_ts=Delta_medium_ts(:,find(network_iEEG_space==7));
Language_ECoG_Gamma_ts=Gamma_medium_ts(:,find(network_iEEG_space==7));
Language_vox=vox_iEEG_space(find(network_iEEG_space==7),:);

Language_BOLD_corr=corrcoef(Language_BOLD_ts); Language_BOLD_column=Language_BOLD_corr(:);
Language_BOLD_column(find(Language_BOLD_column==1))=NaN; Language_BOLD_column(isnan(Language_BOLD_column))=[];
Language_medium_corr=corrcoef(Language_ECoG_medium_ts); Language_medium_column=Language_medium_corr(:);
Language_medium_column(find(Language_medium_column==1))=NaN; Language_medium_column(isnan(Language_medium_column))=[];
Language_slow_corr=corrcoef(Language_ECoG_slow_ts); Language_slow_column=Language_slow_corr(:);
Language_slow_column(find(Language_slow_column==1))=NaN; Language_slow_column(isnan(Language_slow_column))=[];
Language_alpha_corr=corrcoef(Language_ECoG_alpha_ts); Language_alpha_column=Language_alpha_corr(:);
Language_alpha_column(find(Language_alpha_column==1))=NaN; Language_alpha_column(isnan(Language_alpha_column))=[];
Language_beta1_corr=corrcoef(Language_ECoG_beta1_ts); Language_beta1_column=Language_beta1_corr(:);
Language_beta1_column(find(Language_beta1_column==1))=NaN; Language_beta1_column(isnan(Language_beta1_column))=[];
Language_beta2_corr=corrcoef(Language_ECoG_beta2_ts); Language_beta2_column=Language_beta2_corr(:);
Language_beta2_column(find(Language_beta2_column==1))=NaN; Language_beta2_column(isnan(Language_beta2_column))=[];
Language_Theta_corr=corrcoef(Language_ECoG_Theta_ts); Language_Theta_column=Language_Theta_corr(:);
Language_Theta_column(find(Language_Theta_column==1))=NaN; Language_Theta_column(isnan(Language_Theta_column))=[];
Language_Delta_corr=corrcoef(Language_ECoG_Delta_ts); Language_Delta_column=Language_Delta_corr(:);
Language_Delta_column(find(Language_Delta_column==1))=NaN; Language_Delta_column(isnan(Language_Delta_column))=[];
Language_Gamma_corr=corrcoef(Language_ECoG_Gamma_ts); Language_Gamma_column=Language_Gamma_corr(:);
Language_Gamma_column(find(Language_Gamma_column==1))=NaN; Language_Gamma_column(isnan(Language_Gamma_column))=[];

% Create time series and distances ordered by network
BOLD_network_order_ts=[DMN_BOLD_ts,FPN_BOLD_ts,VAN_BOLD_ts,SMN_BOLD_ts,Visual_BOLD_ts,DAN_BOLD_ts,Language_BOLD_ts];
medium_network_order_ts=[DMN_ECoG_medium_ts,FPN_ECoG_medium_ts,VAN_ECoG_medium_ts,SMN_ECoG_medium_ts,Visual_ECoG_medium_ts,DAN_ECoG_medium_ts,Language_ECoG_medium_ts];
slow_network_order_ts=[DMN_ECoG_slow_ts,FPN_ECoG_slow_ts,VAN_ECoG_slow_ts,SMN_ECoG_slow_ts,Visual_ECoG_slow_ts,DAN_ECoG_slow_ts,Language_ECoG_slow_ts];
alpha_network_order_ts=[DMN_ECoG_alpha_ts,FPN_ECoG_alpha_ts,VAN_ECoG_alpha_ts,SMN_ECoG_alpha_ts,Visual_ECoG_alpha_ts,DAN_ECoG_alpha_ts,Language_ECoG_alpha_ts];
beta1_network_order_ts=[DMN_ECoG_beta1_ts,FPN_ECoG_beta1_ts,VAN_ECoG_beta1_ts,SMN_ECoG_beta1_ts,Visual_ECoG_beta1_ts,DAN_ECoG_beta1_ts,Language_ECoG_beta1_ts];
beta2_network_order_ts=[DMN_ECoG_beta2_ts,FPN_ECoG_beta2_ts,VAN_ECoG_beta2_ts,SMN_ECoG_beta2_ts,Visual_ECoG_beta2_ts,DAN_ECoG_beta2_ts,Language_ECoG_beta2_ts];
Theta_network_order_ts=[DMN_ECoG_Theta_ts,FPN_ECoG_Theta_ts,VAN_ECoG_Theta_ts,SMN_ECoG_Theta_ts,Visual_ECoG_Theta_ts,DAN_ECoG_Theta_ts,Language_ECoG_Theta_ts];
Delta_network_order_ts=[DMN_ECoG_Delta_ts,FPN_ECoG_Delta_ts,VAN_ECoG_Delta_ts,SMN_ECoG_Delta_ts,Visual_ECoG_Delta_ts,DAN_ECoG_Delta_ts,Language_ECoG_Delta_ts];
Gamma_network_order_ts=[DMN_ECoG_Gamma_ts,FPN_ECoG_Gamma_ts,VAN_ECoG_Gamma_ts,SMN_ECoG_Gamma_ts,Visual_ECoG_Gamma_ts,DAN_ECoG_Gamma_ts,Language_ECoG_Gamma_ts];
vox_network_order=[DMN_vox;FPN_vox;VAN_vox;SMN_vox;Visual_vox;DAN_vox;Language_vox];

DMN_BOLD_order_ts=[DMN_BOLD_ts,VAN_BOLD_ts,DAN_BOLD_ts,FPN_BOLD_ts];
DMN_medium_order_ts=[DMN_ECoG_medium_ts,VAN_ECoG_medium_ts,DAN_ECoG_medium_ts,FPN_ECoG_medium_ts];
DMN_slow_order_ts=[DMN_ECoG_slow_ts,VAN_ECoG_slow_ts,DAN_ECoG_slow_ts,FPN_ECoG_slow_ts];
DMN_alpha_order_ts=[DMN_ECoG_alpha_ts,VAN_ECoG_alpha_ts,DAN_ECoG_alpha_ts,FPN_ECoG_alpha_ts];
DMN_beta1_order_ts=[DMN_ECoG_beta1_ts,VAN_ECoG_beta1_ts,DAN_ECoG_beta1_ts,FPN_ECoG_beta1_ts];
DMN_beta2_order_ts=[DMN_ECoG_beta2_ts,VAN_ECoG_beta2_ts,DAN_ECoG_beta2_ts,FPN_ECoG_beta2_ts];
DMN_Theta_order_ts=[DMN_ECoG_Theta_ts,VAN_ECoG_Theta_ts,DAN_ECoG_Theta_ts,FPN_ECoG_Theta_ts];
DMN_Delta_order_ts=[DMN_ECoG_Delta_ts,VAN_ECoG_Delta_ts,DAN_ECoG_Delta_ts,FPN_ECoG_Delta_ts];
DMN_Gamma_order_ts=[DMN_ECoG_Gamma_ts,VAN_ECoG_Gamma_ts,DAN_ECoG_Gamma_ts,FPN_ECoG_Gamma_ts];
DMN_vox_order=[DMN_vox;VAN_vox;DAN_vox;FPN_vox];

% Calculate global HFB/alpha/beta
global_HFB=mean(medium_network_order_ts,2);
global_alpha=mean(alpha_network_order_ts,2);
global_beta1=mean(beta1_network_order_ts,2);

% Remove ROIs with overlapping coordinates
for i=1:length(vox_network_order)
    y1=vox_network_order(i,2);
difference=y1-vox_network_order(:,2);
 if length(find(difference==0))>1
    slow_network_order_ts(:,i)=NaN;
    medium_network_order_ts(:,i)=NaN;
    alpha_network_order_ts(:,i)=NaN;
    beta1_network_order_ts(:,i)=NaN;
    beta2_network_order_ts(:,i)=NaN;
    Theta_network_order_ts(:,i)=NaN;
    Delta_network_order_ts(:,i)=NaN;
    Gamma_network_order_ts(:,i)=NaN;
    BOLD_network_order_ts(:,i)=NaN;
    vox_network_order(i,:)=NaN;
 end  
end


for i=1:size(DMN_vox_order,1)
    y1=DMN_vox_order(i,2);
difference=y1-DMN_vox_order(:,2);
 if length(find(difference==0))>1
    DMN_slow_order_ts(:,i)=NaN;
    DMN_medium_order_ts(:,i)=NaN;
    DMN_alpha_order_ts(:,i)=NaN;
    DMN_beta1_order_ts(:,i)=NaN;
    DMN_beta2_order_ts(:,i)=NaN;
    DMN_Theta_order_ts(:,i)=NaN;
    DMN_Delta_order_ts(:,i)=NaN;
    DMN_Gamma_order_ts(:,i)=NaN;
    DMN_BOLD_order_ts(:,i)=NaN;
    DMN_vox_order(i,:)=NaN;
 end  
end

BOLD_ordered_corr=corrcoef(BOLD_network_order_ts);
medium_ordered_corr=corrcoef(medium_network_order_ts);
slow_ordered_corr=corrcoef(slow_network_order_ts);
alpha_ordered_corr=corrcoef(alpha_network_order_ts);
beta1_ordered_corr=corrcoef(beta1_network_order_ts);
beta2_ordered_corr=corrcoef(beta2_network_order_ts);
Theta_ordered_corr=corrcoef(Theta_network_order_ts);
Delta_ordered_corr=corrcoef(Delta_network_order_ts);
Gamma_ordered_corr=corrcoef(Gamma_network_order_ts);

DMN_BOLD_ordered_corr=corrcoef(DMN_BOLD_order_ts);
DMN_medium_ordered_corr=corrcoef(DMN_medium_order_ts);
DMN_slow_ordered_corr=corrcoef(DMN_slow_order_ts);
DMN_alpha_ordered_corr=corrcoef(DMN_alpha_order_ts);
DMN_beta1_ordered_corr=corrcoef(DMN_beta1_order_ts);
DMN_beta2_ordered_corr=corrcoef(DMN_beta2_order_ts);
DMN_Theta_ordered_corr=corrcoef(DMN_Theta_order_ts);
DMN_Delta_ordered_corr=corrcoef(DMN_Delta_order_ts);
DMN_Gamma_ordered_corr=corrcoef(DMN_Gamma_order_ts);

distances_DMN_order=zeros(size(DMN_vox_order,1));
for i = 1:size(DMN_vox_order,1)
 coord = DMN_vox_order(i,:);
     for ii = 1:size(DMN_vox_order,1)
         distances_DMN_order(i,ii)=sqrt((DMN_vox_order(ii,1)-coord(1))^2+(DMN_vox_order(ii,2)-coord(2))^2+(DMN_vox_order(ii,3)-coord(3))^2);
     end
end

distances_network_order=zeros(size(vox_network_order,1));
for i = 1:size(vox_network_order,1)
 coord = vox_network_order(i,:);
     for ii = 1:size(vox_network_order,1)
         distances_network_order(i,ii)=sqrt((vox_network_order(ii,1)-coord(1))^2+(vox_network_order(ii,2)-coord(2))^2+(vox_network_order(ii,3)-coord(3))^2);
     end
end

% BOLD_ordered_corr(find(BOLD_ordered_corr==1))=0;
% medium_ordered_corr(find(medium_ordered_corr==1))=0;
% slow_ordered_corr(find(slow_ordered_corr==1))=0;
[x,y]=find(BOLD_ordered_corr==1);
for i=1:length(x)
    distances_network_order(x(i),y(i))=NaN;
end


BOLD_scatter=nonzeros(triu(BOLD_ordered_corr)'); 
slow_scatter=nonzeros(triu(slow_ordered_corr)');
medium_scatter=nonzeros(triu(medium_ordered_corr)');
alpha_scatter=nonzeros(triu(alpha_ordered_corr)');
beta1_scatter=nonzeros(triu(beta1_ordered_corr)');
beta2_scatter=nonzeros(triu(beta2_ordered_corr)');
Theta_scatter=nonzeros(triu(Theta_ordered_corr)');
Delta_scatter=nonzeros(triu(Delta_ordered_corr)');
Gamma_scatter=nonzeros(triu(Gamma_ordered_corr)');
distance_scatter=nonzeros(triu(distances_network_order)');

% set bad indices: HFB medium corr >0.8; BOLD corr=1;
remove_ind=[find(BOLD_scatter==1); find(medium_scatter>autocorr_thr & medium_scatter<1)];

 medium_scatter(remove_ind)=[];
 slow_scatter(remove_ind)=[];
 alpha_scatter(remove_ind)=[];
 beta1_scatter(remove_ind)=[];
 distance_scatter(remove_ind)=[];
BOLD_scatter(remove_ind)=[];
end

%% exclude electrode pairs below distance threshold
if distance_exclusion=='1'
    display(['Excluding pairs that are <' num2str(distance_thr) 'mm apart']);
distance_scatter(find(distance_scatter<distance_thr))=NaN;
medium_scatter(isnan(distance_scatter))=[];
slow_scatter(isnan(distance_scatter))=[];
alpha_scatter(isnan(distance_scatter))=[];
beta1_scatter(isnan(distance_scatter))=[];
beta2_scatter(isnan(distance_scatter))=[];
Theta_scatter(isnan(distance_scatter))=[];
Delta_scatter(isnan(distance_scatter))=[];
Gamma_scatter(isnan(distance_scatter))=[];
HFB_scatter(isnan(distance_scatter))=[];
alpha_medium_scatter(isnan(distance_scatter))=[];
beta1_medium_scatter(isnan(distance_scatter))=[];
beta2_medium_scatter(isnan(distance_scatter))=[];
Theta_medium_scatter(isnan(distance_scatter))=[];
Delta_medium_scatter(isnan(distance_scatter))=[];
Gamma_medium_scatter(isnan(distance_scatter))=[];
HFB_fast_scatter(isnan(distance_scatter))=[];
 alpha_fast_scatter(isnan(distance_scatter))=[];
beta1_fast_scatter(isnan(distance_scatter))=[];
beta2_fast_scatter(isnan(distance_scatter))=[];
Theta_fast_scatter(isnan(distance_scatter))=[];
Delta_fast_scatter(isnan(distance_scatter))=[];
Gamma_fast_scatter(isnan(distance_scatter))=[];
%SCP_scatter(isnan(SCP_scatter))=[];
BOLD_scatter(isnan(distance_scatter))=[];
distance_scatter(isnan(distance_scatter))=[];
end

%% Binary split short and long distances
long_dist_ind=find(distance_scatter>median(distance_scatter));
short_dist_ind=find(distance_scatter<median(distance_scatter));
BOLD_long=BOLD_scatter(long_dist_ind); BOLD_short=BOLD_scatter(short_dist_ind);
medium_long=medium_scatter(long_dist_ind); medium_short=medium_scatter(short_dist_ind);
slow_long=slow_scatter(long_dist_ind); slow_short=slow_scatter(short_dist_ind);
alpha_long=alpha_scatter(long_dist_ind); alpha_short=alpha_scatter(short_dist_ind);
beta1_long=beta1_scatter(long_dist_ind); beta1_short=beta1_scatter(short_dist_ind);
beta2_long=beta2_scatter(long_dist_ind); beta2_short=beta2_scatter(short_dist_ind);
Theta_long=Theta_scatter(long_dist_ind); Theta_short=Theta_scatter(short_dist_ind);
Delta_long=Delta_scatter(long_dist_ind); Delta_short=Delta_scatter(short_dist_ind);
Gamma_long=Gamma_scatter(long_dist_ind); Gamma_short=Gamma_scatter(short_dist_ind);
HFB_long=HFB_scatter(long_dist_ind); HFB_short=HFB_scatter(short_dist_ind);

alpha_medium_long=alpha_medium_scatter(long_dist_ind); alpha_medium_short=alpha_medium_scatter(short_dist_ind);
beta1_medium_long=beta1_medium_scatter(long_dist_ind); beta1_medium_short=beta1_medium_scatter(short_dist_ind);
beta2_medium_long=beta2_medium_scatter(long_dist_ind); beta2_medium_short=beta2_medium_scatter(short_dist_ind);
Theta_medium_long=Theta_medium_scatter(long_dist_ind); Theta_medium_short=Theta_medium_scatter(short_dist_ind);
Delta_medium_long=Delta_medium_scatter(long_dist_ind); Delta_medium_short=Delta_medium_scatter(short_dist_ind);
Gamma_medium_long=Gamma_medium_scatter(long_dist_ind); Gamma_medium_short=Gamma_medium_scatter(short_dist_ind);

HFB_fast_long=HFB_fast_scatter(long_dist_ind); HFB_fast_short=HFB_fast_scatter(short_dist_ind);
alpha_fast_long=alpha_fast_scatter(long_dist_ind); alpha_fast_short=alpha_fast_scatter(short_dist_ind);
beta1_fast_long=beta1_fast_scatter(long_dist_ind); beta1_fast_short=beta1_fast_scatter(short_dist_ind);
beta2_fast_long=beta2_fast_scatter(long_dist_ind); beta2_fast_short=beta2_fast_scatter(short_dist_ind);
Theta_fast_long=Theta_fast_scatter(long_dist_ind); Theta_fast_short=Theta_fast_scatter(short_dist_ind);
Delta_fast_long=Delta_fast_scatter(long_dist_ind); Delta_fast_short=Delta_fast_scatter(short_dist_ind);
Gamma_fast_long=Gamma_fast_scatter(long_dist_ind); Gamma_fast_short=Gamma_fast_scatter(short_dist_ind);

%SCP_long=SCP_scatter(long_dist_ind); SCP_short=SCP_scatter(short_dist_ind);

if depth==2
[x,y]=find(DMN_BOLD_ordered_corr==1);
for i=1:length(x)
    distances_DMN_order(x(i),y(i))=NaN;
end

DMN_BOLD_scatter=nonzeros(triu(DMN_BOLD_ordered_corr)'); 
DMN_medium_scatter=nonzeros(triu(DMN_medium_ordered_corr)'); DMN_medium_scatter(find(DMN_BOLD_scatter==1))=[];
DMN_slow_scatter=nonzeros(triu(DMN_slow_ordered_corr)'); DMN_slow_scatter(find(DMN_BOLD_scatter==1))=[];
DMN_slow_scatter=nonzeros(triu(DMN_slow_ordered_corr)'); DMN_slow_scatter(find(DMN_BOLD_scatter==1))=[];
DMN_alpha_scatter=nonzeros(triu(DMN_alpha_ordered_corr)'); DMN_alpha_scatter(find(DMN_BOLD_scatter==1))=[];
DMN_beta1_scatter=nonzeros(triu(DMN_beta1_ordered_corr)'); DMN_beta1_scatter(find(DMN_BOLD_scatter==1))=[];
DMN_beta2_scatter=nonzeros(triu(DMN_beta2_ordered_corr)'); DMN_beta2_scatter(find(DMN_BOLD_scatter==1))=[];
DMN_Theta_scatter=nonzeros(triu(DMN_Theta_ordered_corr)'); DMN_Theta_scatter(find(DMN_BOLD_scatter==1))=[];
DMN_Delta_scatter=nonzeros(triu(DMN_Delta_ordered_corr)'); DMN_Delta_scatter(find(DMN_BOLD_scatter==1))=[];
DMN_Gamma_scatter=nonzeros(triu(DMN_Gamma_ordered_corr)'); DMN_Gamma_scatter(find(DMN_BOLD_scatter==1))=[];
distance_DMN_scatter=nonzeros(triu(distances_DMN_order)'); distance_DMN_scatter(find(DMN_BOLD_scatter==1))=[];
DMN_BOLD_scatter(find(DMN_BOLD_scatter==1))=[];

% Correlate inter-network FC of all Yeo DMN Core and Salience/DAN pairs
for i=1:size(Yeo_CoreDMN_ECoG_medium_ts,2);
   for j=1:size(Yeo_VAN_ECoG_medium_ts,2);
       Yeo_CoreDMN_vs_SN_HFBmedium(i,j)=corr(Yeo_CoreDMN_ECoG_medium_ts(:,i),Yeo_VAN_ECoG_medium_ts(:,j));    
   end
end

for i=1:size(Yeo_CoreDMN_ECoG_slow_ts,2);
   for j=1:size(Yeo_VAN_ECoG_slow_ts,2);
       Yeo_CoreDMN_vs_SN_HFBslow(i,j)=corr(Yeo_CoreDMN_ECoG_slow_ts(:,i),Yeo_VAN_ECoG_slow_ts(:,j));    
   end
end

for i=1:size(Yeo_CoreDMN_ECoG_alpha_ts,2);
   for j=1:size(Yeo_VAN_ECoG_alpha_ts,2);
       Yeo_CoreDMN_vs_SN_alpha(i,j)=corr(Yeo_CoreDMN_ECoG_alpha_ts(:,i),Yeo_VAN_ECoG_alpha_ts(:,j));    
   end
end

for i=1:size(Yeo_CoreDMN_ECoG_beta1_ts,2);
   for j=1:size(Yeo_VAN_ECoG_beta1_ts,2);
       Yeo_CoreDMN_vs_SN_beta1(i,j)=corr(Yeo_CoreDMN_ECoG_beta1_ts(:,i),Yeo_VAN_ECoG_beta1_ts(:,j));    
   end
end

for i=1:size(Yeo_CoreDMN_ECoG_medium_ts,2);
   for j=1:size(Yeo_DAN_ECoG_medium_ts,2);
       Yeo_CoreDMN_vs_DAN_HFBmedium(i,j)=corr(Yeo_CoreDMN_ECoG_medium_ts(:,i),Yeo_DAN_ECoG_medium_ts(:,j));    
   end
end

for i=1:size(Yeo_CoreDMN_ECoG_slow_ts,2);
   for j=1:size(Yeo_DAN_ECoG_slow_ts,2);
       Yeo_CoreDMN_vs_DAN_HFBslow(i,j)=corr(Yeo_CoreDMN_ECoG_slow_ts(:,i),Yeo_DAN_ECoG_slow_ts(:,j));    
   end
end

for i=1:size(Yeo_CoreDMN_ECoG_alpha_ts,2);
   for j=1:size(Yeo_DAN_ECoG_alpha_ts,2);
       Yeo_CoreDMN_vs_DAN_alpha(i,j)=corr(Yeo_CoreDMN_ECoG_alpha_ts(:,i),Yeo_DAN_ECoG_alpha_ts(:,j));    
   end
end

for i=1:size(Yeo_CoreDMN_ECoG_beta1_ts,2);
   for j=1:size(Yeo_DAN_ECoG_beta1_ts,2);
       Yeo_CoreDMN_vs_DAN_beta1(i,j)=corr(Yeo_CoreDMN_ECoG_beta1_ts(:,i),Yeo_DAN_ECoG_beta1_ts(:,j));    
   end
end

% Find peak anticorrelation pairs and locations
Yeo_CoreDMN_iEEG_ind=find(Yeo_network_iEEG_space==1);
Yeo_CoreDMN_iElvis_ind=iEEG_to_iElvis_chanlabel(Yeo_CoreDMN_iEEG_ind);
Yeo_CoreDMN_coords=RAS_coords(Yeo_CoreDMN_iElvis_ind,1:3);
Yeo_CoreDMN_coords=[Yeo_CoreDMN_coords,ones(length(Yeo_CoreDMN_coords),1)];
Yeo_CoreDMN_names=strread(num2str(1:length(Yeo_CoreDMN_coords)),'%s');



% Correlate mean inter-network FC (BOLD and ECoG)
DMN_BOLD_mean_ts=mean(DMN_BOLD_ts,2); DMN_ECoG_slow_mean_ts=mean(DMN_ECoG_slow_ts,2);
SN_BOLD_mean_ts=mean(VAN_BOLD_ts,2); SN_ECoG_slow_mean_ts=mean(VAN_ECoG_slow_ts,2);
DAN_BOLD_mean_ts=mean(DAN_BOLD_ts,2); DAN_ECoG_slow_mean_ts=mean(DAN_ECoG_slow_ts,2);
FPN_BOLD_mean_ts=mean(FPN_BOLD_ts,2); FPN_ECoG_slow_mean_ts=mean(FPN_ECoG_slow_ts,2);

Yeo_CoreDMN_BOLD_mean_ts=mean(Yeo_CoreDMN_BOLD_ts,2); Yeo_CoreDMN_ECoG_slow_mean_ts=mean(Yeo_CoreDMN_ECoG_slow_ts,2);
Yeo_VAN_BOLD_mean_ts=mean(Yeo_VAN_BOLD_ts,2); Yeo_VAN_ECoG_slow_mean_ts=mean(Yeo_VAN_ECoG_slow_ts,2);
Yeo_DAN_BOLD_mean_ts=mean(Yeo_DAN_BOLD_ts,2); Yeo_DAN_ECoG_slow_mean_ts=mean(Yeo_DAN_ECoG_slow_ts,2);

DMN_ECoG_medium_mean_ts=mean(DMN_ECoG_medium_ts,2);
DMN_ECoG_alpha_mean_ts=mean(DMN_ECoG_alpha_ts,2);
DMN_ECoG_beta1_mean_ts=mean(DMN_ECoG_beta1_ts,2);
SN_ECoG_medium_mean_ts=mean(VAN_ECoG_medium_ts,2);
SN_ECoG_alpha_mean_ts=mean(VAN_ECoG_alpha_ts,2);
SN_ECoG_beta1_mean_ts=mean(VAN_ECoG_beta1_ts,2);
DAN_ECoG_medium_mean_ts=mean(DAN_ECoG_medium_ts,2);
DAN_ECoG_alpha_mean_ts=mean(DAN_ECoG_alpha_ts,2);
DAN_ECoG_beta1_mean_ts=mean(DAN_ECoG_beta1_ts,2);
FPN_ECoG_medium_mean_ts=mean(FPN_ECoG_medium_ts,2);
FPN_ECoG_alpha_mean_ts=mean(FPN_ECoG_alpha_ts,2);
FPN_ECoG_beta1_mean_ts=mean(FPN_ECoG_beta1_ts,2);

Yeo_CoreDMN_ECoG_medium_mean_ts=mean(Yeo_CoreDMN_ECoG_medium_ts,2);
Yeo_CoreDMN_ECoG_alpha_mean_ts=mean(Yeo_CoreDMN_ECoG_alpha_ts,2);
Yeo_CoreDMN_ECoG_beta1_mean_ts=mean(Yeo_CoreDMN_ECoG_beta1_ts,2);
Yeo_VAN_ECoG_medium_mean_ts=mean(Yeo_VAN_ECoG_medium_ts,2);
Yeo_VAN_ECoG_alpha_mean_ts=mean(Yeo_VAN_ECoG_alpha_ts,2);
Yeo_VAN_ECoG_beta1_mean_ts=mean(Yeo_VAN_ECoG_beta1_ts,2);
Yeo_DAN_ECoG_medium_mean_ts=mean(Yeo_DAN_ECoG_medium_ts,2);
Yeo_DAN_ECoG_alpha_mean_ts=mean(Yeo_DAN_ECoG_alpha_ts,2);
Yeo_DAN_ECoG_beta1_mean_ts=mean(Yeo_DAN_ECoG_beta1_ts,2);

% Correlate FC of all individual DMN elctrodes with electrodes in other networks
for i=1:size(DMN_BOLD_ts,2)
    for j=1:size(VAN_BOLD_ts,2)
       DMN_SN_BOLD_corr(i,j)=corr(DMN_BOLD_ts(:,i),VAN_BOLD_ts(:,j));
    end
end

for i=1:size(DMN_ECoG_slow_ts,2)
    for j=1:size(VAN_ECoG_slow_ts,2)
       DMN_SN_ECoG_slow_corr(i,j)=corr(DMN_ECoG_slow_ts(:,i),VAN_ECoG_slow_ts(:,j));
    end
end

for i=1:size(DMN_ECoG_medium_ts,2)
    for j=1:size(VAN_ECoG_medium_ts,2)
       DMN_SN_ECoG_medium_corr(i,j)=corr(DMN_ECoG_medium_ts(:,i),VAN_ECoG_medium_ts(:,j));
    end
end

for i=1:size(Yeo_CoreDMN_ECoG_medium_ts,2)
    for j=1:size(Yeo_VAN_ECoG_medium_ts,2)
       Yeo_DMN_SN_ECoG_medium_corr(i,j)=corr(Yeo_CoreDMN_ECoG_medium_ts(:,i),Yeo_VAN_ECoG_medium_ts(:,j));
    end
end

for i=1:size(Yeo_CoreDMN_ECoG_medium_ts,2)
    for j=1:size(Yeo_DAN_ECoG_medium_ts,2)
       Yeo_DMN_DAN_ECoG_medium_corr(i,j)=corr(Yeo_CoreDMN_ECoG_medium_ts(:,i),Yeo_DAN_ECoG_medium_ts(:,j));
    end
end

% Correlate HFB vs alpha over time in each electrode
for i=1:size(medium_network_order_ts,2)
    HFB_alpha_corr(i)=corr(medium_network_order_ts(:,i),alpha_network_order_ts(:,i));
end
mean_HFB_alpha_corr=mean(HFB_alpha_corr,2);

% Correlate HFB vs beta1 over time in each electrode
for i=1:size(medium_network_order_ts,2)
    HFB_beta1_corr(i)=corr(medium_network_order_ts(:,i),beta1_network_order_ts(:,i));
end
mean_HFB_beta1_corr=mean(HFB_beta1_corr,2);
end
% for correlation matrix labeling
if depth==2
DMN_interval=size(DMN_BOLD_corr,1);
FPN_interval=DMN_interval+size(FPN_BOLD_corr,1);
VAN_interval=FPN_interval+size(VAN_BOLD_corr,1);
SMN_interval=VAN_interval+size(SMN_BOLD_corr,1);
Visual_interval=SMN_interval+size(Visual_BOLD_corr,1);
DAN_interval=Visual_interval+size(DAN_BOLD_corr,1);
Language_interval=DAN_interval+size(Language_BOLD_corr,1);
end
edge_color=[0.6 0.6 0.6];
edge_width=2.5;

%% Save distance matrix (iElvis order)
save('distances','distances');

%% Make plots
mkdir BOLD_ECoG_figs
cd BOLD_ECoG_figs

%% correlation matrices
if depth==2
   
FigHandle = figure(1);
set(FigHandle,'Position',[50, 50, 400, 300]);
imagesc(BOLD_ordered_corr); h=colorbar('vert'); colormap copper
set(h,'fontsize',16);
title(['BOLD FC matrix '])
hold on;
h1=rectangle('position',[.5 .5 size(DMN_BOLD_corr,1) size(DMN_BOLD_corr,1)]);
set(h1,'EdgeColor',edge_color,'linewidth',edge_width);
h1=rectangle('position',[DMN_interval+.5 DMN_interval+.5 size(FPN_BOLD_corr,1) size(FPN_BOLD_corr,1)]);
set(h1,'EdgeColor',edge_color,'linewidth',edge_width);
h1=rectangle('position',[FPN_interval+.5 FPN_interval+.5 size(VAN_BOLD_corr,1) size(VAN_BOLD_corr,1)]);
set(h1,'EdgeColor',edge_color,'linewidth',edge_width);
h1=rectangle('position',[VAN_interval+.5 VAN_interval+.5 size(SMN_BOLD_corr,1) size(SMN_BOLD_corr,1)]);
set(h1,'EdgeColor',edge_color,'linewidth',edge_width);
h1=rectangle('position',[SMN_interval+.5 SMN_interval+.5 size(Visual_BOLD_corr,1) size(Visual_BOLD_corr,1)]);
set(h1,'EdgeColor',edge_color,'linewidth',edge_width);
h1=rectangle('position',[Visual_interval+.5 Visual_interval+.5 size(DAN_BOLD_corr,1) size(DAN_BOLD_corr,1)]);
set(h1,'EdgeColor',edge_color,'linewidth',edge_width);
h1=rectangle('position',[DAN_interval+.5 DAN_interval+.5 size(Language_BOLD_corr,1) size(Language_BOLD_corr,1)]);
set(h1,'EdgeColor',edge_color,'linewidth',edge_width);
set(gcf,'PaperPositionMode','auto');
print -depsc2 BOLD_FC_mat.eps

FigHandle = figure(2);
set(FigHandle,'Position',[50, 500, 400, 300]);
imagesc(medium_ordered_corr,[-0.1 0.4]); h=colorbar('vert'); colormap copper
set(h,'fontsize',16);
title(['ECoG HFB (0.1-1 Hz) FC matrix '])
hold on;
h1=rectangle('position',[.5 .5 size(DMN_BOLD_corr,1) size(DMN_BOLD_corr,1)]);
set(h1,'EdgeColor',edge_color,'linewidth',edge_width);
h1=rectangle('position',[DMN_interval+.5 DMN_interval+.5 size(FPN_BOLD_corr,1) size(FPN_BOLD_corr,1)]);
set(h1,'EdgeColor',edge_color,'linewidth',edge_width);
h1=rectangle('position',[FPN_interval+.5 FPN_interval+.5 size(VAN_BOLD_corr,1) size(VAN_BOLD_corr,1)]);
set(h1,'EdgeColor',edge_color,'linewidth',edge_width);
h1=rectangle('position',[VAN_interval+.5 VAN_interval+.5 size(SMN_BOLD_corr,1) size(SMN_BOLD_corr,1)]);
set(h1,'EdgeColor',edge_color,'linewidth',edge_width);
h1=rectangle('position',[SMN_interval+.5 SMN_interval+.5 size(Visual_BOLD_corr,1) size(Visual_BOLD_corr,1)]);
set(h1,'EdgeColor',edge_color,'linewidth',edge_width);
h1=rectangle('position',[Visual_interval+.5 Visual_interval+.5 size(DAN_BOLD_corr,1) size(DAN_BOLD_corr,1)]);
set(h1,'EdgeColor',edge_color,'linewidth',edge_width);
h1=rectangle('position',[DAN_interval+.5 DAN_interval+.5 size(Language_BOLD_corr,1) size(Language_BOLD_corr,1)]);
set(h1,'EdgeColor',edge_color,'linewidth',edge_width);
set(gcf,'PaperPositionMode','auto');
print -depsc2 HFB_FC_mat.eps

FigHandle = figure(3);
set(FigHandle,'Position',[500, 50, 400, 300]);
imagesc(alpha_ordered_corr,[-0.1 0.4]); h=colorbar('vert'); colormap copper
set(h,'fontsize',16);
title(['ECoG alpha (0.1-1 Hz) FC matrix '])
hold on;
h1=rectangle('position',[.5 .5 size(DMN_BOLD_corr,1) size(DMN_BOLD_corr,1)]);
set(h1,'EdgeColor',edge_color,'linewidth',edge_width);
h1=rectangle('position',[DMN_interval+.5 DMN_interval+.5 size(FPN_BOLD_corr,1) size(FPN_BOLD_corr,1)]);
set(h1,'EdgeColor',edge_color,'linewidth',edge_width);
h1=rectangle('position',[FPN_interval+.5 FPN_interval+.5 size(VAN_BOLD_corr,1) size(VAN_BOLD_corr,1)]);
set(h1,'EdgeColor',edge_color,'linewidth',edge_width);
h1=rectangle('position',[VAN_interval+.5 VAN_interval+.5 size(SMN_BOLD_corr,1) size(SMN_BOLD_corr,1)]);
set(h1,'EdgeColor',edge_color,'linewidth',edge_width);
h1=rectangle('position',[SMN_interval+.5 SMN_interval+.5 size(Visual_BOLD_corr,1) size(Visual_BOLD_corr,1)]);
set(h1,'EdgeColor',edge_color,'linewidth',edge_width);
h1=rectangle('position',[Visual_interval+.5 Visual_interval+.5 size(DAN_BOLD_corr,1) size(DAN_BOLD_corr,1)]);
set(h1,'EdgeColor',edge_color,'linewidth',edge_width);
h1=rectangle('position',[DAN_interval+.5 DAN_interval+.5 size(Language_BOLD_corr,1) size(Language_BOLD_corr,1)]);
set(h1,'EdgeColor',edge_color,'linewidth',edge_width);
set(gcf,'PaperPositionMode','auto');
print -depsc2 alpha_FC_mat.eps

FigHandle = figure(4);
set(FigHandle,'Position',[500, 500, 400, 300]);
imagesc(beta1_ordered_corr,[-0.1 0.4]); h=colorbar('vert'); colormap copper
set(h,'fontsize',16);
title(['ECoG beta1 (13-29 Hz) FC matrix '])
hold on;
h1=rectangle('position',[.5 .5 size(DMN_BOLD_corr,1) size(DMN_BOLD_corr,1)]);
set(h1,'EdgeColor',edge_color,'linewidth',edge_width);
h1=rectangle('position',[DMN_interval+.5 DMN_interval+.5 size(FPN_BOLD_corr,1) size(FPN_BOLD_corr,1)]);
set(h1,'EdgeColor',edge_color,'linewidth',edge_width);
h1=rectangle('position',[FPN_interval+.5 FPN_interval+.5 size(VAN_BOLD_corr,1) size(VAN_BOLD_corr,1)]);
set(h1,'EdgeColor',edge_color,'linewidth',edge_width);
h1=rectangle('position',[VAN_interval+.5 VAN_interval+.5 size(SMN_BOLD_corr,1) size(SMN_BOLD_corr,1)]);
set(h1,'EdgeColor',edge_color,'linewidth',edge_width);
h1=rectangle('position',[SMN_interval+.5 SMN_interval+.5 size(Visual_BOLD_corr,1) size(Visual_BOLD_corr,1)]);
set(h1,'EdgeColor',edge_color,'linewidth',edge_width);
h1=rectangle('position',[Visual_interval+.5 Visual_interval+.5 size(DAN_BOLD_corr,1) size(DAN_BOLD_corr,1)]);
set(h1,'EdgeColor',edge_color,'linewidth',edge_width);
h1=rectangle('position',[DAN_interval+.5 DAN_interval+.5 size(Language_BOLD_corr,1) size(Language_BOLD_corr,1)]);
set(h1,'EdgeColor',edge_color,'linewidth',edge_width);
set(gcf,'PaperPositionMode','auto');
print -depsc2 beta1_FC_mat.eps
pause; close('all');
end

electrode_pairs=num2str(length(BOLD_column));
[r p]=corr(fisherz(slow_scatter),fisherz(BOLD_scatter));
slow_vs_BOLD_r=num2str(r); slow_vs_BOLD_p=num2str(p);
[r p]=corr(fisherz(slow_scatter),fisherz(BOLD_scatter),'type','Spearman');
slow_vs_BOLD_Spearman=num2str(r); slow_vs_BOLD_Spearman_p=num2str(p);

[r p]=corr(fisherz(medium_scatter),fisherz(BOLD_scatter));
medium_vs_BOLD_r=num2str(r); medium_vs_BOLD_p=num2str(p);
[r p]=corr(fisherz(medium_scatter),fisherz(BOLD_scatter),'type','Spearman');
medium_vs_BOLD_Spearman=num2str(r); medium_vs_BOLD_Spearman_p=num2str(p);

[r p]=corr(fisherz(alpha_scatter),fisherz(BOLD_scatter));
alpha_vs_BOLD_r=num2str(r); alpha_vs_BOLD_p=num2str(p);
[r p]=corr(fisherz(alpha_scatter),fisherz(BOLD_scatter),'type','Spearman');
alpha_vs_BOLD_Spearman=num2str(r); alpha_vs_BOLD_Spearman_p=num2str(p);

[r p]=corr(fisherz(beta1_scatter),fisherz(BOLD_scatter));
beta1_vs_BOLD_r=num2str(r); beta1_vs_BOLD_p=num2str(p);
[r p]=corr(fisherz(beta1_scatter),fisherz(BOLD_scatter),'type','Spearman');
beta1_vs_BOLD_Spearman=num2str(r); beta1_vs_BOLD_Spearman_p=num2str(p);

[r p]=corr(fisherz(beta2_scatter),fisherz(BOLD_scatter));
beta2_vs_BOLD_r=num2str(r); beta2_vs_BOLD_p=num2str(p);
[r p]=corr(fisherz(beta2_scatter),fisherz(BOLD_scatter),'type','Spearman');
beta2_vs_BOLD_Spearman=num2str(r); beta2_vs_BOLD_Spearman_p=num2str(p);

[r p]=corr(fisherz(Theta_scatter),fisherz(BOLD_scatter));
Theta_vs_BOLD_r=num2str(r); Theta_vs_BOLD_p=num2str(p);
[r p]=corr(fisherz(Theta_scatter),fisherz(BOLD_scatter),'type','Spearman');
Theta_vs_BOLD_Spearman=num2str(r); Theta_vs_BOLD_Spearman_p=num2str(p);

[r p]=corr(fisherz(Delta_scatter),fisherz(BOLD_scatter));
Delta_vs_BOLD_r=num2str(r); Delta_vs_BOLD_p=num2str(p);
[r p]=corr(fisherz(Delta_scatter),fisherz(BOLD_scatter),'type','Spearman');
Delta_vs_BOLD_Spearman=num2str(r); Delta_vs_BOLD_Spearman_p=num2str(p);

[r p]=corr(fisherz(Gamma_scatter),fisherz(BOLD_scatter));
Gamma_vs_BOLD_r=num2str(r); Gamma_vs_BOLD_p=num2str(p);
[r p]=corr(fisherz(Gamma_scatter),fisherz(BOLD_scatter),'type','Spearman');
Gamma_vs_BOLD_Spearman=num2str(r); Gamma_vs_BOLD_Spearman_p=num2str(p);

[r p]=corr(fisherz(HFB_scatter),fisherz(BOLD_scatter));
HFB_vs_BOLD_r=num2str(r); HFB_vs_BOLD_p=num2str(p);
[r p]=corr(fisherz(HFB_scatter),fisherz(BOLD_scatter),'type','Spearman');
HFB_vs_BOLD_Spearman=num2str(r); HFB_vs_BOLD_Spearman_p=num2str(p);

[r p]=corr(fisherz(alpha_medium_scatter),fisherz(BOLD_scatter));
alpha_medium_vs_BOLD_r=num2str(r); alpha_medium_vs_BOLD_p=num2str(p);
[r p]=corr(fisherz(alpha_medium_scatter),fisherz(BOLD_scatter),'type','Spearman');
alpha_medium_vs_BOLD_Spearman=num2str(r); alpha_medium_vs_BOLD_Spearman_p=num2str(p);

[r p]=corr(fisherz(beta1_medium_scatter),fisherz(BOLD_scatter));
beta1_medium_vs_BOLD_r=num2str(r); beta1_medium_vs_BOLD_p=num2str(p);
[r p]=corr(fisherz(beta1_medium_scatter),fisherz(BOLD_scatter),'type','Spearman');
beta1_medium_vs_BOLD_Spearman=num2str(r); beta1_medium_vs_BOLD_Spearman_p=num2str(p);

[r p]=corr(fisherz(beta2_medium_scatter),fisherz(BOLD_scatter));
beta2_medium_vs_BOLD_r=num2str(r); beta2_medium_vs_BOLD_p=num2str(p);
[r p]=corr(fisherz(beta2_medium_scatter),fisherz(BOLD_scatter),'type','Spearman');
beta2_medium_vs_BOLD_Spearman=num2str(r); beta2_medium_vs_BOLD_Spearman_p=num2str(p);

[r p]=corr(fisherz(Theta_medium_scatter),fisherz(BOLD_scatter));
Theta_medium_vs_BOLD_r=num2str(r); Theta_medium_vs_BOLD_p=num2str(p);
[r p]=corr(fisherz(Theta_medium_scatter),fisherz(BOLD_scatter),'type','Spearman');
Theta_medium_vs_BOLD_Spearman=num2str(r); Theta_medium_vs_BOLD_Spearman_p=num2str(p);

[r p]=corr(fisherz(Delta_medium_scatter),fisherz(BOLD_scatter));
Delta_medium_vs_BOLD_r=num2str(r); Delta_medium_vs_BOLD_p=num2str(p);
[r p]=corr(fisherz(Delta_medium_scatter),fisherz(BOLD_scatter),'type','Spearman');
Delta_medium_vs_BOLD_Spearman=num2str(r); Delta_medium_vs_BOLD_Spearman_p=num2str(p);

[r p]=corr(fisherz(Gamma_medium_scatter),fisherz(BOLD_scatter));
Gamma_medium_vs_BOLD_r=num2str(r); Gamma_medium_vs_BOLD_p=num2str(p);
[r p]=corr(fisherz(Gamma_medium_scatter),fisherz(BOLD_scatter),'type','Spearman');
Gamma_medium_vs_BOLD_Spearman=num2str(r); Gamma_medium_vs_BOLD_Spearman_p=num2str(p);

[r p]=corr(fisherz(HFB_fast_scatter),fisherz(BOLD_scatter));
HFB_fast_vs_BOLD_r=num2str(r); HFB_fast_vs_BOLD_p=num2str(p);
[r p]=corr(fisherz(HFB_fast_scatter),fisherz(BOLD_scatter),'type','Spearman');
HFB_fast_vs_BOLD_Spearman=num2str(r); HFB_fast_vs_BOLD_Spearman_p=num2str(p);

[r p]=corr(fisherz(alpha_fast_scatter),fisherz(BOLD_scatter));
alpha_fast_vs_BOLD_r=num2str(r); alpha_fast_vs_BOLD_p=num2str(p);
[r p]=corr(fisherz(alpha_fast_scatter),fisherz(BOLD_scatter),'type','Spearman');
alpha_fast_vs_BOLD_Spearman=num2str(r); alpha_fast_vs_BOLD_Spearman_p=num2str(p);

[r p]=corr(fisherz(beta1_fast_scatter),fisherz(BOLD_scatter));
beta1_fast_vs_BOLD_r=num2str(r); beta1_fast_vs_BOLD_p=num2str(p);
[r p]=corr(fisherz(beta1_fast_scatter),fisherz(BOLD_scatter),'type','Spearman');
beta1_fast_vs_BOLD_Spearman=num2str(r); beta1_fast_vs_BOLD_Spearman_p=num2str(p);

[r p]=corr(fisherz(beta2_fast_scatter),fisherz(BOLD_scatter));
beta2_fast_vs_BOLD_r=num2str(r); beta2_fast_vs_BOLD_p=num2str(p);
[r p]=corr(fisherz(beta2_fast_scatter),fisherz(BOLD_scatter),'type','Spearman');
beta2_fast_vs_BOLD_Spearman=num2str(r); beta2_fast_vs_BOLD_Spearman_p=num2str(p);

[r p]=corr(fisherz(Theta_fast_scatter),fisherz(BOLD_scatter));
Theta_fast_vs_BOLD_r=num2str(r); Theta_fast_vs_BOLD_p=num2str(p);
[r p]=corr(fisherz(Theta_fast_scatter),fisherz(BOLD_scatter),'type','Spearman');
Theta_fast_vs_BOLD_Spearman=num2str(r); Theta_fast_vs_BOLD_Spearman_p=num2str(p);

[r p]=corr(fisherz(Delta_fast_scatter),fisherz(BOLD_scatter));
Delta_fast_vs_BOLD_r=num2str(r); Delta_fast_vs_BOLD_p=num2str(p);
[r p]=corr(fisherz(Delta_fast_scatter),fisherz(BOLD_scatter),'type','Spearman');
Delta_fast_vs_BOLD_Spearman=num2str(r); Delta_fast_vs_BOLD_Spearman_p=num2str(p);

[r p]=corr(fisherz(Gamma_fast_scatter),fisherz(BOLD_scatter));
Gamma_fast_vs_BOLD_r=num2str(r); Gamma_fast_vs_BOLD_p=num2str(p);
[r p]=corr(fisherz(Gamma_fast_scatter),fisherz(BOLD_scatter),'type','Spearman');
Gamma_fast_vs_BOLD_Spearman=num2str(r); Gamma_fast_vs_BOLD_Spearman_p=num2str(p);


% [r p]=corr(fisherz(SCP_scatter),fisherz(BOLD_scatter));
% SCP_vs_BOLD_r=num2str(r); SCP_vs_BOLD_p=num2str(p);
% [r p]=corr(fisherz(SCP_scatter),fisherz(BOLD_scatter),'type','Spearman');
% SCP_vs_BOLD_Spearman=num2str(r); SCP_vs_BOLD_Spearman_p=num2str(p);

% control for other frequencies
[r,p]=partialcorr(fisherz(alpha_medium_scatter),fisherz(BOLD_scatter),medium_scatter);
alpha_HFB_medium_partial=num2str(r);
[r,p]=partialcorr(fisherz(medium_scatter),fisherz(BOLD_scatter),alpha_medium_scatter);
HFB_alpha_medium_partial=num2str(r);
[r,p]=partialcorr(fisherz(medium_scatter),fisherz(BOLD_scatter),beta1_medium_scatter);
HFB_beta1_medium_partial=num2str(r);
[r,p]=partialcorr(fisherz(beta1_medium_scatter),fisherz(BOLD_scatter),medium_scatter);
beta1_HFB_medium_partial=num2str(r);
[r,p]=partialcorr(fisherz(medium_scatter),fisherz(BOLD_scatter),beta2_medium_scatter);
HFB_beta2_medium_partial=num2str(r);
[r,p]=partialcorr(fisherz(beta2_medium_scatter),fisherz(BOLD_scatter),medium_scatter);
beta2_HFB_medium_partial=num2str(r);
[r,p]=partialcorr(fisherz(medium_scatter),fisherz(BOLD_scatter),Theta_medium_scatter);
HFB_Theta_medium_partial=num2str(r);
[r,p]=partialcorr(fisherz(Theta_medium_scatter),fisherz(BOLD_scatter),medium_scatter);
Theta_HFB_medium_partial=num2str(r);
[r,p]=partialcorr(fisherz(medium_scatter),fisherz(BOLD_scatter),Delta_medium_scatter);
HFB_Delta_medium_partial=num2str(r);
[r,p]=partialcorr(fisherz(Delta_medium_scatter),fisherz(BOLD_scatter),medium_scatter);
Delta_HFB_medium_partial=num2str(r);
[r,p]=partialcorr(fisherz(medium_scatter),fisherz(BOLD_scatter),Gamma_medium_scatter);
HFB_Gamma_medium_partial=num2str(r);
[r,p]=partialcorr(fisherz(Gamma_medium_scatter),fisherz(BOLD_scatter),medium_scatter);
Gamma_HFB_medium_partial=num2str(r);
[r,p]=partialcorr(fisherz(medium_scatter),fisherz(BOLD_scatter),Gamma_medium_scatter);
HFB_Gamma_medium_partial=num2str(r);
[r,p]=partialcorr(fisherz(Gamma_medium_scatter),fisherz(BOLD_scatter),medium_scatter);
Gamma_HFB_medium_partial=num2str(r);
% [r,p]=partialcorr(fisherz(medium_scatter),fisherz(BOLD_scatter),SCP_scatter);
% HFB_SCP_medium_partial=num2str(r);
% [r,p]=partialcorr(fisherz(SCP_scatter),fisherz(BOLD_scatter),medium_scatter);
% SCP_HFB_medium_partial=num2str(r);

% control for distance
[r,p]=partialcorr(fisherz(slow_scatter),fisherz(BOLD_scatter),distance_scatter);
slow_partial=num2str(r);
[r,p]=partialcorr(fisherz(medium_scatter),fisherz(BOLD_scatter),distance_scatter);
medium_partial=num2str(r);
[r,p]=partialcorr(fisherz(alpha_scatter),fisherz(BOLD_scatter),distance_scatter);
alpha_partial=num2str(r);
[r,p]=partialcorr(fisherz(beta1_scatter),fisherz(BOLD_scatter),distance_scatter);
beta1_partial=num2str(r);
[r,p]=partialcorr(fisherz(beta2_scatter),fisherz(BOLD_scatter),distance_scatter);
beta2_partial=num2str(r);
[r,p]=partialcorr(fisherz(Theta_scatter),fisherz(BOLD_scatter),distance_scatter);
Theta_partial=num2str(r);
[r,p]=partialcorr(fisherz(Delta_scatter),fisherz(BOLD_scatter),distance_scatter);
Delta_partial=num2str(r);
[r,p]=partialcorr(fisherz(Gamma_scatter),fisherz(BOLD_scatter),distance_scatter);
Gamma_partial=num2str(r);
[r,p]=partialcorr(fisherz(HFB_scatter),fisherz(BOLD_scatter),distance_scatter);
HFB_partial=num2str(r);
[r,p]=partialcorr(fisherz(alpha_medium_scatter),fisherz(BOLD_scatter),distance_scatter);
alpha_medium_partial=num2str(r);
[r,p]=partialcorr(fisherz(beta1_medium_scatter),fisherz(BOLD_scatter),distance_scatter);
beta1_medium_partial=num2str(r);
[r,p]=partialcorr(fisherz(beta2_medium_scatter),fisherz(BOLD_scatter),distance_scatter);
beta2_medium_partial=num2str(r);
[r,p]=partialcorr(fisherz(Theta_medium_scatter),fisherz(BOLD_scatter),distance_scatter);
Theta_medium_partial=num2str(r);
[r,p]=partialcorr(fisherz(Delta_medium_scatter),fisherz(BOLD_scatter),distance_scatter);
Delta_medium_partial=num2str(r);
[r,p]=partialcorr(fisherz(Gamma_medium_scatter),fisherz(BOLD_scatter),distance_scatter);
Gamma_medium_partial=num2str(r);
[r,p]=partialcorr(fisherz(HFB_fast_scatter),fisherz(BOLD_scatter),distance_scatter);
HFB_fast_partial=num2str(r);
[r,p]=partialcorr(fisherz(alpha_fast_scatter),fisherz(BOLD_scatter),distance_scatter);
alpha_fast_partial=num2str(r);
[r,p]=partialcorr(fisherz(beta1_fast_scatter),fisherz(BOLD_scatter),distance_scatter);
beta1_fast_partial=num2str(r);
[r,p]=partialcorr(fisherz(beta2_fast_scatter),fisherz(BOLD_scatter),distance_scatter);
beta2_fast_partial=num2str(r);
[r,p]=partialcorr(fisherz(Theta_fast_scatter),fisherz(BOLD_scatter),distance_scatter);
Theta_fast_partial=num2str(r);
[r,p]=partialcorr(fisherz(Delta_fast_scatter),fisherz(BOLD_scatter),distance_scatter);
Delta_fast_partial=num2str(r);
[r,p]=partialcorr(fisherz(Gamma_fast_scatter),fisherz(BOLD_scatter),distance_scatter);
Gamma_fast_partial=num2str(r);

% [r,p]=partialcorr(fisherz(SCP_scatter),fisherz(BOLD_scatter),distance_scatter);
% SCP_partial=num2str(r);

if depth==2
[r p]=corr(DMN_medium_scatter,DMN_BOLD_scatter);
DMN_medium_vs_BOLD_r=num2str(r); DMN_medium_vs_BOLD_p=num2str(p);
[r p]=corr(DMN_slow_scatter,DMN_BOLD_scatter);
DMN_slow_vs_BOLD_r=num2str(r); DMN_slow_vs_BOLD_p=num2str(p);
[r,p]=partialcorr(DMN_slow_scatter,DMN_BOLD_scatter,distance_DMN_scatter);
DMN_slow_partial=num2str(r);
[r,p]=partialcorr(DMN_medium_scatter,DMN_BOLD_scatter,distance_DMN_scatter);
DMN_medium_partial=num2str(r);
end

[r,p]=corr(fisherz(BOLD_short),fisherz(medium_short));
medium_vs_BOLD_short=num2str(r);
[r,p]=corr(fisherz(BOLD_short),fisherz(medium_short),'type','Spearman');
medium_vs_BOLD_short_Spearman=num2str(r);

[r,p]=corr(fisherz(BOLD_long),fisherz(medium_long));
medium_vs_BOLD_long=num2str(r);
[r,p]=corr(fisherz(BOLD_long),fisherz(medium_long),'type','Spearman');
medium_vs_BOLD_long_Spearman=num2str(r);

[r,p]=corr(fisherz(BOLD_short),fisherz(slow_short));
slow_vs_BOLD_short=num2str(r);
[r,p]=corr(fisherz(BOLD_long),fisherz(slow_long));
slow_vs_BOLD_long=num2str(r);

%% Distance histogram
figure(1)
histogram(distance_scatter);
title(['Euclidean distances among all electrodes']);
pause; close;

%% Plot correlations with all frequencies
corr_allfreqs=[str2num(Delta_vs_BOLD_r) str2num(Theta_vs_BOLD_r) str2num(alpha_vs_BOLD_r) str2num(beta1_vs_BOLD_r) str2num(beta2_vs_BOLD_r) str2num(Gamma_vs_BOLD_r) str2num(medium_vs_BOLD_r)]

    plot(1:length(corr_allfreqs),corr_allfreqs','k.--', ...
        'LineWidth',2,'Color',[.7 .7 .7],'MarkerSize',25,'MarkerEdgeColor',[.5 .5 .5]);
    ylim([0 0.8]);
       set(gca,'Xtick',0:1:8)
 set(gca,'XTickLabel',{'','δ', 'θ','α','β1','β2','γ','HFB'})
 set(gca,'Fontsize',14,'FontWeight','bold','LineWidth',2,'TickDir','out');
   set(gca,'box','off'); 
set(gcf,'color','w');
ylabel('BOLD-iEEG (0.1-1 Hz) FC correlation (r)'); 

pause; close;

%% Slow vs medium vs BOLD
figure(1)
scatter(fisherz(BOLD_scatter),fisherz(slow_scatter),'MarkerEdgeColor','k','MarkerFaceColor',[0 0 1]); 
h=lsline; set(h(1),'color',[0 0 1],'LineWidth',3);
set(gca,'Fontsize',14,'FontWeight','bold','LineWidth',2,'TickDir','out');
set(gcf,'color','w');
title({['Slow (<0.1 Hz) HFB ECoG vs BOLD (0.01-0.1Hz) FC']; ['r = ' slow_vs_BOLD_r ' p = ' slow_vs_BOLD_p]; ...
    ['Spearman ρ = ' slow_vs_BOLD_Spearman]; ['Partial (distance-corrected) r = ' slow_partial]},'Fontsize',12);
xlabel('BOLD pair-wise FC');
ylabel('Slow pair-wise FC');
set(gcf,'PaperPositionMode','auto');
if BOLD_pipeline==1
print -depsc2 HFB_slow_vs_BOLD_GSR.eps
elseif BOLD_pipeline==2
    print -depsc2 HFB_slow_vs_BOLD_AROMA.eps
elseif BOLD_pipeline==3  
    print -depsc2 HFB_slow_vs_BOLD_NoGSR.eps
elseif BOLD_pipeline==4
    print -depsc2 HFB_slow_vs_BOLD_aCompCor.eps
end
pause; close;

figure(2)
scatter(fisherz(BOLD_scatter),fisherz(medium_scatter),'MarkerEdgeColor','k','MarkerFaceColor',[1 0 0]); 
h=lsline; set(h(1),'color',[1 0 0],'LineWidth',3);
set(gca,'Fontsize',16,'FontWeight','bold','LineWidth',2,'TickDir','out');
set(gcf,'color','w');
title({['Medium (0.1-1 Hz) HFB ECoG vs BOLD (0.01-0.1Hz) FC']; ['r = ' medium_vs_BOLD_r ' p = ' medium_vs_BOLD_p ]; ...
    ['Spearman ρ = ' medium_vs_BOLD_Spearman]; ['Partial (distance-corrected) r = ' medium_partial]; ...
    ['Partial (alpha-corrected) r = ' HFB_alpha_medium_partial]} ,'Fontsize',12); 
xlabel('BOLD pair-wise FC');
ylabel('Medium pair-wise FC');
set(gcf,'PaperPositionMode','auto');
if BOLD_pipeline==1
print -depsc2 HFB_medium_vs_BOLD_GSR.eps
elseif BOLD_pipeline==2
  print -depsc2 HFB_medium_vs_BOLD_AROMA.eps  
  elseif BOLD_pipeline==3  
    print -depsc2 HFB_medium_vs_BOLD_NoGSR.eps
elseif BOLD_pipeline==4
    print -depsc2 HFB_medium_vs_BOLD_aCompCor.eps
end
pause; close;

figure(1)
scatter(fisherz(BOLD_scatter),fisherz(HFB_fast_scatter),'MarkerEdgeColor','k','MarkerFaceColor',[0 0 1]); 
h=lsline; set(h(1),'color',[0 0 1],'LineWidth',3);
set(gca,'Fontsize',14,'FontWeight','bold','LineWidth',2,'TickDir','out');
set(gcf,'color','w');
title({['Fast (>1 Hz) HFB ECoG vs BOLD (0.01-0.1Hz) FC']; ['r = ' HFB_fast_vs_BOLD_r ' p = ' HFB_fast_vs_BOLD_p]; ...
    ['Spearman ρ = ' HFB_fast_vs_BOLD_Spearman]; ['Partial (distance-corrected) r = ' HFB_fast_partial]},'Fontsize',12);
xlabel('BOLD pair-wise FC');
ylabel('Fast pair-wise FC');
set(gcf,'PaperPositionMode','auto');
if BOLD_pipeline==1
print -depsc2 HFB_fast_vs_BOLD_GSR.eps
elseif BOLD_pipeline==2
    print -depsc2 HFB_fast_vs_BOLD_AROMA.eps
elseif BOLD_pipeline==3  
    print -depsc2 HFB_fast_vs_BOLD_NoGSR.eps
elseif BOLD_pipeline==4
    print -depsc2 HFB_fast_vs_BOLD_aCompCor.eps
end
pause; close;

figure(3)
scatter(fisherz(BOLD_scatter),fisherz(alpha_medium_scatter),'MarkerEdgeColor','k','MarkerFaceColor',[0 0 1]); 
h=lsline; set(h(1),'color',[0 0 1],'LineWidth',3);
set(gca,'Fontsize',14,'FontWeight','bold','LineWidth',2,'TickDir','out');
set(gcf,'color','w');
title({['Medium (0.1-1 Hz) alpha ECoG vs BOLD (0.01-0.1Hz) FC']; ['r = ' alpha_medium_vs_BOLD_r ' p = ' alpha_medium_vs_BOLD_p ]; ...
    ['Spearman ρ = ' alpha_medium_vs_BOLD_Spearman]; ['Partial (distance-corrected) r = ' alpha_medium_partial]; ...
    ['Partial (HFB-corrected) r = ' alpha_HFB_medium_partial]} ,'Fontsize',12);
xlabel('BOLD pair-wise FC');
ylabel('Medium alpha pair-wise FC');
set(gcf,'PaperPositionMode','auto');
if BOLD_pipeline==1
print -depsc2 alpha_medium_vs_BOLD_GSR.eps
elseif BOLD_pipeline==2
  print -depsc2 alpha_medium_vs_BOLD_AROMA.eps  
  elseif BOLD_pipeline==3  
    print -depsc2 alpha_medium_vs_BOLD_NoGSR.eps
elseif BOLD_pipeline==4
    print -depsc2 alpha_medium_vs_BOLD_aCompCor.eps
end
pause; close;

figure(4)
scatter(fisherz(BOLD_scatter),fisherz(beta1_medium_scatter),'MarkerEdgeColor','k','MarkerFaceColor',[0 1 0]); 
h=lsline; set(h(1),'color',[0 1 0],'LineWidth',3);
set(gca,'Fontsize',14,'FontWeight','bold','LineWidth',2,'TickDir','out');
set(gcf,'color','w');
title({['Medium (0.1-1 Hz) beta1 ECoG vs BOLD (0.01-0.1Hz) FC']; ['r = ' beta1_medium_vs_BOLD_r ' p = ' beta1_medium_vs_BOLD_p ]; ...
    ['Spearman ρ = ' beta1_medium_vs_BOLD_Spearman]; ['Partial (distance-corrected) r = ' beta1_medium_partial]; ...
    ['Partial (HFB-corrected) r = ' beta1_HFB_medium_partial]} ,'Fontsize',12);
xlabel('BOLD pair-wise FC');
ylabel('Medium beta1 pair-wise FC');
set(gcf,'PaperPositionMode','auto');
if BOLD_pipeline==1
print -depsc2 beta1_medium_vs_BOLD_GSR.eps
elseif BOLD_pipeline==2
 print -depsc2 beta1_medium_vs_BOLD_AROMA.eps
 elseif BOLD_pipeline==3  
    print -depsc2 beta1_medium_vs_BOLD_NoGSR.eps
elseif BOLD_pipeline==4
    print -depsc2 beta1_medium_vs_BOLD_aCompCor.eps
end
pause; close;

figure(4)
scatter(fisherz(BOLD_scatter),fisherz(beta2_medium_scatter),'MarkerEdgeColor','k','MarkerFaceColor',[0 1 0]); 
h=lsline; set(h(1),'color',[0 1 0],'LineWidth',3);
set(gca,'Fontsize',14,'FontWeight','bold','LineWidth',2,'TickDir','out');
set(gcf,'color','w');
title({['Medium (0.1-1 Hz) beta2 ECoG vs BOLD (0.01-0.1Hz) FC']; ['r = ' beta2_medium_vs_BOLD_r ' p = ' beta2_medium_vs_BOLD_p ]; ...
    ['Spearman ρ = ' beta2_medium_vs_BOLD_Spearman]; ['Partial (distance-corrected) r = ' beta2_medium_partial]; ...
    ['Partial (HFB-corrected) r = ' beta2_HFB_medium_partial]} ,'Fontsize',12);
xlabel('BOLD pair-wise FC');
ylabel('Medium beta2 pair-wise FC');
set(gcf,'PaperPositionMode','auto');
if BOLD_pipeline==1
print -depsc2 beta2_medium_vs_BOLD_GSR.eps
elseif BOLD_pipeline==2
 print -depsc2 beta2_medium_vs_BOLD_AROMA.eps
 elseif BOLD_pipeline==3  
    print -depsc2 beta2_medium_vs_BOLD_NoGSR.eps
elseif BOLD_pipeline==4
    print -depsc2 beta2_medium_vs_BOLD_aCompCor.eps
end
pause; close;

figure(4)
scatter(fisherz(BOLD_scatter),fisherz(Theta_medium_scatter),'MarkerEdgeColor','k','MarkerFaceColor',[0 1 0]); 
h=lsline; set(h(1),'color',[0 1 0],'LineWidth',3);
set(gca,'Fontsize',14,'FontWeight','bold','LineWidth',2,'TickDir','out');
set(gcf,'color','w');
title({['Medium (0.1-1 Hz) Theta ECoG vs BOLD (0.01-0.1Hz) FC']; ['r = ' Theta_medium_vs_BOLD_r ' p = ' Theta_medium_vs_BOLD_p ]; ...
    ['Spearman ρ = ' Theta_medium_vs_BOLD_Spearman]; ['Partial (distance-corrected) r = ' Theta_medium_partial]; ...
    ['Partial (HFB-corrected) r = ' Theta_HFB_medium_partial]} ,'Fontsize',12);
xlabel('BOLD pair-wise FC');
ylabel('Medium Theta pair-wise FC');
set(gcf,'PaperPositionMode','auto');
if BOLD_pipeline==1
print -depsc2 Theta_medium_vs_BOLD_GSR.eps
elseif BOLD_pipeline==2
 print -depsc2 Theta_medium_vs_BOLD_AROMA.eps
 elseif BOLD_pipeline==3  
    print -depsc2 Theta_medium_vs_BOLD_NoGSR.eps
elseif BOLD_pipeline==4
    print -depsc2 Theta_medium_vs_BOLD_aCompCor.eps
end
pause; close;

figure(4)
scatter(fisherz(BOLD_scatter),fisherz(Delta_medium_scatter),'MarkerEdgeColor','k','MarkerFaceColor',[0 1 0]); 
h=lsline; set(h(1),'color',[0 1 0],'LineWidth',3);
set(gca,'Fontsize',14,'FontWeight','bold','LineWidth',2,'TickDir','out');
set(gcf,'color','w');
title({['Medium (0.1-1 Hz) Delta ECoG vs BOLD (0.01-0.1Hz) FC']; ['r = ' Delta_medium_vs_BOLD_r ' p = ' Delta_medium_vs_BOLD_p ]; ...
    ['Spearman ρ = ' Delta_medium_vs_BOLD_Spearman]; ['Partial (distance-corrected) r = ' Delta_medium_partial]; ...
    ['Partial (HFB-corrected) r = ' Delta_HFB_medium_partial]} ,'Fontsize',12);
xlabel('BOLD pair-wise FC');
ylabel('Medium Delta pair-wise FC');
set(gcf,'PaperPositionMode','auto');
if BOLD_pipeline==1
print -depsc2 Delta_medium_vs_BOLD_GSR.eps
elseif BOLD_pipeline==2
 print -depsc2 Delta_medium_vs_BOLD_AROMA.eps
 elseif BOLD_pipeline==3  
    print -depsc2 Delta_medium_vs_BOLD_NoGSR.eps
elseif BOLD_pipeline==4
    print -depsc2 Delta_medium_vs_BOLD_aCompCor.eps
end
pause; close;

figure(4)
scatter(fisherz(BOLD_scatter),fisherz(Gamma_medium_scatter),'MarkerEdgeColor','k','MarkerFaceColor',[0 1 0]); 
h=lsline; set(h(1),'color',[0 1 0],'LineWidth',3);
set(gca,'Fontsize',14,'FontWeight','bold','LineWidth',2,'TickDir','out');
set(gcf,'color','w');
title({['Medium (0.1-1 Hz) Gamma ECoG vs BOLD (0.01-0.1Hz) FC']; ['r = ' Gamma_medium_vs_BOLD_r ' p = ' Gamma_medium_vs_BOLD_p ]; ...
    ['Spearman ρ = ' Gamma_medium_vs_BOLD_Spearman]; ['Partial (distance-corrected) r = ' Gamma_medium_partial]; ...
    ['Partial (HFB-corrected) r = ' Gamma_HFB_medium_partial]} ,'Fontsize',12);
xlabel('BOLD pair-wise FC');
ylabel('Medium Gamma pair-wise FC');
set(gcf,'PaperPositionMode','auto');
if BOLD_pipeline==1
print -depsc2 Gamma_medium_vs_BOLD_GSR.eps
elseif BOLD_pipeline==2
 print -depsc2 Gamma_medium_vs_BOLD_AROMA.eps
 elseif BOLD_pipeline==3  
    print -depsc2 Gamma_medium_vs_BOLD_NoGSR.eps
elseif BOLD_pipeline==4
    print -depsc2 Gamma_medium_vs_BOLD_aCompCor.eps
end
pause; close;

% figure(4)
% scatter(fisherz(BOLD_scatter),fisherz(SCP_scatter),'MarkerEdgeColor','k','MarkerFaceColor',[0 1 0]); 
% h=lsline; set(h(1),'color',[0 1 0],'LineWidth',3);
% set(gca,'Fontsize',14,'FontWeight','bold','LineWidth',2,'TickDir','out');
% set(gcf,'color','w');
% title({['Medium (0.1-1 Hz) SCP ECoG vs BOLD (< 1Hz) FC']; ['r = ' SCP_vs_BOLD_r ' p = ' SCP_vs_BOLD_p ]; ...
%     ['Spearman ρ = ' SCP_vs_BOLD_Spearman]; ['Partial (distance-corrected) r = ' SCP_partial]; ...
%     ['Partial (HFB-corrected) r = ' SCP_HFB_medium_partial]} ,'Fontsize',12);
% xlabel('BOLD pair-wise FC');
% ylabel('Medium SCP pair-wise FC');
% set(gcf,'PaperPositionMode','auto');
% if BOLD_pipeline==1
% print -depsc2 SCP_vs_BOLD_GSR.eps
% elseif BOLD_pipeline==2
%  print -depsc2 SCP_vs_BOLD_AROMA.eps
%  elseif BOLD_pipeline==3  
%     print -depsc2 SCP_vs_BOLD_NoGSR.eps
% elseif BOLD_pipeline==4
%     print -depsc2 SCP_vs_BOLD_aCompCor.eps
% end
% pause; close;

figure(1)
scatter(fisherz(BOLD_long),fisherz(medium_long),'MarkerEdgeColor','k','MarkerFaceColor',[1 0 0]); 
h=lsline; set(h(1),'color',[1 0 0],'LineWidth',3);
set(gca,'Fontsize',14,'FontWeight','bold','LineWidth',2,'TickDir','out');
set(gcf,'color','w');
title({['Long distance pairs: Medium (0.1-1 Hz) HFB ECoG vs BOLD (0.01-0.1Hz) FC']; ...
     ['r = ' medium_vs_BOLD_long]; ['Spearman ρ = ' medium_vs_BOLD_long_Spearman]} ,'Fontsize',12);
xlabel('BOLD pair-wise FC');
ylabel('Medium pair-wise FC');
set(gcf,'PaperPositionMode','auto');
if BOLD_pipeline==1
print -depsc2 HFB_longdist_vs_BOLD_GSR.eps
elseif BOLD_pipeline==2
   print -depsc2 HFB_longdist_vs_BOLD_AROMA.eps 
elseif BOLD_pipeline==3  
    print -depsc2 HFB_longdist_vs_BOLD_NoGSR.eps
elseif BOLD_pipeline==4
    print -depsc2 HFB_longdist_vs_BOLD_aCompCor.eps
    end
close;

figure(2)
scatter(fisherz(BOLD_short),fisherz(medium_short),'MarkerEdgeColor','k','MarkerFaceColor',[1 0 0]); 
h=lsline; set(h(1),'color',[1 0 0],'LineWidth',3);
set(gca,'Fontsize',14,'FontWeight','bold','LineWidth',2,'TickDir','out');
set(gcf,'color','w');
title({['Short distance pairs: Medium (0.1-1 Hz) HFB ECoG vs BOLD (0.01-0.1Hz) FC']; ...
    ['r = ' medium_vs_BOLD_short];['Spearman ρ = ' medium_vs_BOLD_short_Spearman]} ,'Fontsize',12); 
xlabel('BOLD pair-wise FC');
ylabel('Medium pair-wise FC');
set(gcf,'PaperPositionMode','auto');
if BOLD_pipeline==1
print -depsc2 HFB_shortdist_vs_BOLD_GSR.eps
elseif BOLD_pipeline==2
print -depsc2 HFB_shortdist_vs_BOLD_AROMA.eps
elseif BOLD_pipeline==3  
    print -depsc2 HFB_shortdist_vs_BOLD_NoGSR.eps
elseif BOLD_pipeline==4
    print -depsc2 HFB_shortdist_vs_BOLD_aCompCor.eps

end
close;

%% unfiltered ECoG plots
figure(4)
scatter(fisherz(BOLD_scatter),fisherz(HFB_scatter),'MarkerEdgeColor','k','MarkerFaceColor',[0 1 0]); 
h=lsline; set(h(1),'color',[0 1 0],'LineWidth',3);
set(gca,'Fontsize',14,'FontWeight','bold','LineWidth',2,'TickDir','out');
set(gcf,'color','w');
title({['HFB (unfiltered) ECoG vs BOLD (0.01-0.1Hz) FC']; ['r = ' HFB_vs_BOLD_r ' p = ' HFB_vs_BOLD_p ]; ...
    ['Spearman ρ = ' HFB_vs_BOLD_Spearman]; ['Partial (distance-corrected) r = ' HFB_partial]},'Fontsize',12);
xlabel('BOLD pair-wise FC');
ylabel('HFB pair-wise FC');
set(gcf,'PaperPositionMode','auto');
if BOLD_pipeline==1
print -depsc2 HFB_vs_BOLD_GSR.eps
elseif BOLD_pipeline==2
 print -depsc2 HFB_vs_BOLD_AROMA.eps
 elseif BOLD_pipeline==3  
    print -depsc2 HFB_vs_BOLD_NoGSR.eps
elseif BOLD_pipeline==4
    print -depsc2 HFB_vs_BOLD_aCompCor.eps
end
close;

figure(4)
scatter(fisherz(BOLD_scatter),fisherz(alpha_scatter),'MarkerEdgeColor','k','MarkerFaceColor',[0 1 0]); 
h=lsline; set(h(1),'color',[0 1 0],'LineWidth',3);
set(gca,'Fontsize',14,'FontWeight','bold','LineWidth',2,'TickDir','out');
set(gcf,'color','w');
title({['alpha (unfiltered) ECoG vs BOLD (0.01-0.1Hz) FC']; ['r = ' alpha_vs_BOLD_r ' p = ' alpha_vs_BOLD_p ]; ...
    ['Spearman ρ = ' alpha_vs_BOLD_Spearman]; ['Partial (distance-corrected) r = ' alpha_partial]},'Fontsize',12);
xlabel('BOLD pair-wise FC');
ylabel('alpha pair-wise FC');
set(gcf,'PaperPositionMode','auto');
if BOLD_pipeline==1
print -depsc2 alpha_vs_BOLD_GSR.eps
elseif BOLD_pipeline==2
 print -depsc2 alpha_vs_BOLD_AROMA.eps
 elseif BOLD_pipeline==3  
    print -depsc2 alpha_vs_BOLD_NoGSR.eps
elseif BOLD_pipeline==4
    print -depsc2 alpha_vs_BOLD_aCompCor.eps
end
close;

if BOLD_pipeline==1
    mkdir('GSR'); cd('GSR');
elseif BOLD_pipeline==2
    mkdir('AROMA'); cd('AROMA');
    elseif BOLD_pipeline==3
    mkdir('NoGSR'); cd('NoGSR');
       elseif BOLD_pipeline==4
    mkdir('aCompCor'); cd('aCompCor');
end
 
%% Save FC matrices
HFB_medium_mat=medium_mat;
save('BOLD_mat','BOLD_mat');
save('Delta_medium_mat','Delta_medium_mat');
save('Theta_medium_mat','Theta_medium_mat');
save('alpha_medium_mat','alpha_medium_mat');
save('beta1_medium_mat','beta1_medium_mat');
save('beta2_medium_mat','beta2_medium_mat');
save('Gamma_medium_mat','Gamma_medium_mat');
save('HFB_medium_mat','HFB_medium_mat');



%% Plot ECoG vs BOLD for each seed electrode
distances_nan=distances;
distances_nan(find(distances_nan==0))=NaN;

for i=1:length(BOLD_mat);
 
    if sum(~isnan(BOLD_mat(:,i)))>0
    use_elec=1;
 curr_elec_BOLD=BOLD_mat(:,i);
 curr_elec_HFB_medium=medium_mat(:,i);
 curr_elec_alpha_medium=alpha_medium_mat(:,i);
 curr_elec_beta1_medium=beta1_medium_mat(:,i);
 curr_elec_beta2_medium=beta2_medium_mat(:,i);
 curr_elec_Theta_medium=Theta_medium_mat(:,i);
 curr_elec_Delta_medium=Delta_medium_mat(:,i);
 curr_elec_Gamma_medium=Gamma_medium_mat(:,i);
  curr_elec_HFB_fast=HFB_fast_mat(:,i);
 curr_elec_alpha_fast=alpha_fast_mat(:,i);
 curr_elec_beta1_fast=beta1_fast_mat(:,i);
 curr_elec_beta2_fast=beta2_fast_mat(:,i);
 curr_elec_Theta_fast=Theta_fast_mat(:,i);
 curr_elec_Delta_fast=Delta_fast_mat(:,i);
 curr_elec_Gamma_fast=Gamma_fast_mat(:,i);
  curr_elec_HFB=HFB_mat(:,i);
 curr_elec_alpha=alpha_mat(:,i);
 curr_elec_beta1=beta1_mat(:,i);
 curr_elec_beta2=beta2_mat(:,i);
 curr_elec_Theta=Theta_mat(:,i);
 curr_elec_Delta=Delta_mat(:,i);
 curr_elec_Gamma=Gamma_mat(:,i);
 
 %curr_elec_SCP=SCP_mat(:,i);
 curr_elec_HFB_slow=slow_mat(:,i);
 curr_elec_distance=distances_nan(:,i);
 curr_elec_BOLD(isnan(curr_elec_BOLD))=[];
 curr_elec_HFB(isnan(curr_elec_HFB))=[];
 curr_elec_alpha(isnan(curr_elec_alpha))=[];
 curr_elec_beta1(isnan(curr_elec_beta1))=[];
 curr_elec_beta2(isnan(curr_elec_beta2))=[];
 curr_elec_Theta(isnan(curr_elec_Theta))=[];
 curr_elec_Delta(isnan(curr_elec_Delta))=[];
 curr_elec_Gamma(isnan(curr_elec_Gamma))=[];
  curr_elec_HFB_medium(isnan(curr_elec_HFB_medium))=[];
 curr_elec_alpha_medium(isnan(curr_elec_alpha_medium))=[];
 curr_elec_beta1_medium(isnan(curr_elec_beta1_medium))=[];
 curr_elec_beta2_medium(isnan(curr_elec_beta2_medium))=[];
 curr_elec_Theta_medium(isnan(curr_elec_Theta_medium))=[];
 curr_elec_Delta_medium(isnan(curr_elec_Delta_medium))=[];
 curr_elec_Gamma_medium(isnan(curr_elec_Gamma_medium))=[];
   curr_elec_HFB_fast(isnan(curr_elec_HFB_fast))=[];
 curr_elec_alpha_fast(isnan(curr_elec_alpha_fast))=[];
 curr_elec_beta1_fast(isnan(curr_elec_beta1_fast))=[];
 curr_elec_beta2_fast(isnan(curr_elec_beta2_fast))=[];
 curr_elec_Theta_fast(isnan(curr_elec_Theta_fast))=[];
 curr_elec_Delta_fast(isnan(curr_elec_Delta_fast))=[];
 curr_elec_Gamma_fast(isnan(curr_elec_Gamma_fast))=[];
 %curr_elec_SCP(isnan(curr_elec_SCP))=[];
 curr_elec_HFB_slow(isnan(curr_elec_HFB_slow))=[];
 curr_elec_distance(isnan(curr_elec_distance))=[];
 
 curr_elec_BOLD=fisherz(curr_elec_BOLD);
 curr_elec_HFB=fisherz(curr_elec_HFB);
 curr_elec_alpha=fisherz(curr_elec_alpha);
 curr_elec_beta1=fisherz(curr_elec_beta1);
 curr_elec_beta2=fisherz(curr_elec_beta2);
 curr_elec_Theta=fisherz(curr_elec_Theta);
 curr_elec_Delta=fisherz(curr_elec_Delta);
 curr_elec_Gamma=fisherz(curr_elec_Gamma);
  curr_elec_HFB_medium=fisherz(curr_elec_HFB_medium);
 curr_elec_alpha_medium=fisherz(curr_elec_alpha_medium);
 curr_elec_beta1_medium=fisherz(curr_elec_beta1_medium);
 curr_elec_beta2_medium=fisherz(curr_elec_beta2_medium);
 curr_elec_Theta_medium=fisherz(curr_elec_Theta_medium);
 curr_elec_Delta_medium=fisherz(curr_elec_Delta_medium);
 curr_elec_Gamma_medium=fisherz(curr_elec_Gamma_medium);
   curr_elec_HFB_fast=fisherz(curr_elec_HFB_fast);
 curr_elec_alpha_fast=fisherz(curr_elec_alpha_fast);
 curr_elec_beta1_fast=fisherz(curr_elec_beta1_fast);
 curr_elec_beta2_fast=fisherz(curr_elec_beta2_fast);
 curr_elec_Theta_fast=fisherz(curr_elec_Theta_fast);
 curr_elec_Delta_fast=fisherz(curr_elec_Delta_fast);
 curr_elec_Gamma_fast=fisherz(curr_elec_Gamma_fast);
 %curr_elec_SCP=fisherz(curr_elec_SCP);
 
 curr_elec_HFB_slow=fisherz(curr_elec_HFB_slow);
 elec_BOLD_HFB_corr=corr(curr_elec_BOLD,curr_elec_HFB);
 elec_BOLD_alpha_corr=corr(curr_elec_BOLD,curr_elec_alpha);
 elec_BOLD_beta1_corr=corr(curr_elec_BOLD,curr_elec_beta1);
 elec_BOLD_beta2_corr=corr(curr_elec_BOLD,curr_elec_beta2);
 elec_BOLD_Theta_corr=corr(curr_elec_BOLD,curr_elec_Theta);
 elec_BOLD_Delta_corr=corr(curr_elec_BOLD,curr_elec_Delta);
 elec_BOLD_Gamma_corr=corr(curr_elec_BOLD,curr_elec_Gamma);
  elec_BOLD_HFB_medium_corr=corr(curr_elec_BOLD,curr_elec_HFB_medium);
 elec_BOLD_alpha_medium_corr=corr(curr_elec_BOLD,curr_elec_alpha_medium);
 elec_BOLD_beta1_medium_corr=corr(curr_elec_BOLD,curr_elec_beta1_medium);
 elec_BOLD_beta2_medium_corr=corr(curr_elec_BOLD,curr_elec_beta2_medium);
 elec_BOLD_Theta_medium_corr=corr(curr_elec_BOLD,curr_elec_Theta_medium);
 elec_BOLD_Delta_medium_corr=corr(curr_elec_BOLD,curr_elec_Delta_medium);
 elec_BOLD_Gamma_medium_corr=corr(curr_elec_BOLD,curr_elec_Gamma_medium);
 elec_BOLD_HFB_fast_corr=corr(curr_elec_BOLD,curr_elec_HFB_fast);
 elec_BOLD_alpha_fast_corr=corr(curr_elec_BOLD,curr_elec_alpha_fast);
 elec_BOLD_beta1_fast_corr=corr(curr_elec_BOLD,curr_elec_beta1_fast);
 elec_BOLD_beta2_fast_corr=corr(curr_elec_BOLD,curr_elec_beta2_fast);
 elec_BOLD_Theta_fast_corr=corr(curr_elec_BOLD,curr_elec_Theta_fast);
 elec_BOLD_Delta_fast_corr=corr(curr_elec_BOLD,curr_elec_Delta_fast);
 elec_BOLD_Gamma_fast_corr=corr(curr_elec_BOLD,curr_elec_Gamma_fast);
 %elec_BOLD_SCP_corr=corr(curr_elec_BOLD,curr_elec_SCP);
 elec_BOLD_HFB_slow_corr=corr(curr_elec_BOLD,curr_elec_HFB_slow);
 [elec_BOLD_HFB_partialcorr,p_HFB_partial]=partialcorr(curr_elec_BOLD,curr_elec_HFB,curr_elec_distance);
 [elec_BOLD_HFB_slow_partialcorr,p_slow_partial]=partialcorr(curr_elec_BOLD,curr_elec_HFB_slow,curr_elec_distance);
 [elec_BOLD_alpha_partialcorr,p_alpha_partial]=partialcorr(curr_elec_BOLD,curr_elec_alpha,curr_elec_distance);
 [elec_BOLD_beta1_partialcorr,p_beta1_partial]=partialcorr(curr_elec_BOLD,curr_elec_beta1,curr_elec_distance);
 [elec_BOLD_beta2_partialcorr,p_beta2_partial]=partialcorr(curr_elec_BOLD,curr_elec_beta2,curr_elec_distance);
 [elec_BOLD_Theta_partialcorr,p_Theta_partial]=partialcorr(curr_elec_BOLD,curr_elec_Theta,curr_elec_distance);
 [elec_BOLD_Delta_partialcorr,p_Delta_partial]=partialcorr(curr_elec_BOLD,curr_elec_Delta,curr_elec_distance);
 [elec_BOLD_Gamma_partialcorr,p_Gamma_partial]=partialcorr(curr_elec_BOLD,curr_elec_Gamma,curr_elec_distance);
  [elec_BOLD_alpha_medium_partialcorr,p_alpha_medium_partial]=partialcorr(curr_elec_BOLD,curr_elec_alpha_medium,curr_elec_distance);
 [elec_BOLD_beta1_medium_partialcorr,p_beta1_medium_partial]=partialcorr(curr_elec_BOLD,curr_elec_beta1_medium,curr_elec_distance);
 [elec_BOLD_beta2_medium_partialcorr,p_beta2_medium_partial]=partialcorr(curr_elec_BOLD,curr_elec_beta2_medium,curr_elec_distance);
 [elec_BOLD_Theta_medium_partialcorr,p_Theta_medium_partial]=partialcorr(curr_elec_BOLD,curr_elec_Theta_medium,curr_elec_distance);
 [elec_BOLD_Delta_medium_partialcorr,p_Delta_medium_partial]=partialcorr(curr_elec_BOLD,curr_elec_Delta_medium,curr_elec_distance);
 [elec_BOLD_Gamma_medium_partialcorr,p_Gamma_medium_partial]=partialcorr(curr_elec_BOLD,curr_elec_Gamma_medium,curr_elec_distance);
 [elec_BOLD_HFB_medium_partialcorr,p_medium_partial]=partialcorr(curr_elec_BOLD,curr_elec_HFB_medium,curr_elec_distance);
   [elec_BOLD_alpha_fast_partialcorr,p_alpha_fast_partial]=partialcorr(curr_elec_BOLD,curr_elec_alpha_fast,curr_elec_distance);
 [elec_BOLD_beta1_fast_partialcorr,p_beta1_fast_partial]=partialcorr(curr_elec_BOLD,curr_elec_beta1_fast,curr_elec_distance);
 [elec_BOLD_beta2_fast_partialcorr,p_beta2_fast_partial]=partialcorr(curr_elec_BOLD,curr_elec_beta2_fast,curr_elec_distance);
 [elec_BOLD_Theta_fast_partialcorr,p_Theta_fast_partial]=partialcorr(curr_elec_BOLD,curr_elec_Theta_fast,curr_elec_distance);
 [elec_BOLD_Delta_fast_partialcorr,p_Delta_fast_partial]=partialcorr(curr_elec_BOLD,curr_elec_Delta_fast,curr_elec_distance);
 [elec_BOLD_Gamma_fast_partialcorr,p_Gamma_fast_partial]=partialcorr(curr_elec_BOLD,curr_elec_Gamma_fast,curr_elec_distance);
 [elec_BOLD_HFB_fast_partialcorr,p_HFB_fast_partial]=partialcorr(curr_elec_BOLD,curr_elec_HFB_fast,curr_elec_distance);
 %[elec_BOLD_SCP_partialcorr,p_SCP_partial]=partialcorr(curr_elec_BOLD,curr_elec_SCP,curr_elec_distance);
 
 rho_elec_BOLD_HFB_corr=corr(curr_elec_BOLD,curr_elec_HFB,'type','Spearman');
 rho_elec_BOLD_alpha_corr=corr(curr_elec_BOLD,curr_elec_alpha,'type','Spearman');
 rho_elec_BOLD_beta1_corr=corr(curr_elec_BOLD,curr_elec_beta1,'type','Spearman');
 rho_elec_BOLD_beta2_corr=corr(curr_elec_BOLD,curr_elec_beta2,'type','Spearman');
 rho_elec_BOLD_Theta_corr=corr(curr_elec_BOLD,curr_elec_Theta,'type','Spearman');
  rho_elec_BOLD_Delta_corr=corr(curr_elec_BOLD,curr_elec_Delta,'type','Spearman');
   rho_elec_BOLD_Gamma_corr=corr(curr_elec_BOLD,curr_elec_Gamma,'type','Spearman');
    rho_elec_BOLD_HFB_medium_corr=corr(curr_elec_BOLD,curr_elec_HFB_medium,'type','Spearman');
 rho_elec_BOLD_alpha_medium_corr=corr(curr_elec_BOLD,curr_elec_alpha_medium,'type','Spearman');
 rho_elec_BOLD_beta1_medium_corr=corr(curr_elec_BOLD,curr_elec_beta1_medium,'type','Spearman');
 rho_elec_BOLD_beta2_medium_corr=corr(curr_elec_BOLD,curr_elec_beta2_medium,'type','Spearman');
 rho_elec_BOLD_Theta_medium_corr=corr(curr_elec_BOLD,curr_elec_Theta_medium,'type','Spearman');
  rho_elec_BOLD_Delta_medium_corr=corr(curr_elec_BOLD,curr_elec_Delta_medium,'type','Spearman');
   rho_elec_BOLD_Gamma_medium_corr=corr(curr_elec_BOLD,curr_elec_Gamma_medium,'type','Spearman');  
       rho_elec_BOLD_HFB_fast_corr=corr(curr_elec_BOLD,curr_elec_HFB_fast,'type','Spearman');
 rho_elec_BOLD_alpha_fast_corr=corr(curr_elec_BOLD,curr_elec_alpha_fast,'type','Spearman');
 rho_elec_BOLD_beta1_fast_corr=corr(curr_elec_BOLD,curr_elec_beta1_fast,'type','Spearman');
 rho_elec_BOLD_beta2_fast_corr=corr(curr_elec_BOLD,curr_elec_beta2_fast,'type','Spearman');
 rho_elec_BOLD_Theta_fast_corr=corr(curr_elec_BOLD,curr_elec_Theta_fast,'type','Spearman');
  rho_elec_BOLD_Delta_fast_corr=corr(curr_elec_BOLD,curr_elec_Delta_fast,'type','Spearman');
   rho_elec_BOLD_Gamma_fast_corr=corr(curr_elec_BOLD,curr_elec_Gamma_fast,'type','Spearman');  
  % rho_elec_BOLD_SCP_corr=corr(curr_elec_BOLD,curr_elec_SCP,'type','Spearman');
 rho_elec_BOLD_HFB_slow_corr=corr(curr_elec_BOLD,curr_elec_HFB_slow,'type','Spearman');
 
 rho_elec_BOLD_HFB_partialcorr=partialcorr(curr_elec_BOLD,curr_elec_HFB,curr_elec_distance,'type','Spearman');
 rho_elec_BOLD_alpha_partialcorr=partialcorr(curr_elec_BOLD,curr_elec_alpha,curr_elec_distance,'type','Spearman');
 rho_elec_BOLD_beta1_partialcorr=partialcorr(curr_elec_BOLD,curr_elec_beta1,curr_elec_distance,'type','Spearman');
 rho_elec_BOLD_HFB_slow_partialcorr=partialcorr(curr_elec_BOLD,curr_elec_HFB_slow,curr_elec_distance,'type','Spearman');
 rho_elec_BOLD_beta2_partialcorr=partialcorr(curr_elec_BOLD,curr_elec_beta2,curr_elec_distance,'type','Spearman');
 rho_elec_BOLD_Theta_partialcorr=partialcorr(curr_elec_BOLD,curr_elec_Theta,curr_elec_distance,'type','Spearman');
 rho_elec_BOLD_Delta_partialcorr=partialcorr(curr_elec_BOLD,curr_elec_Delta,curr_elec_distance,'type','Spearman');
 rho_elec_BOLD_Gamma_partialcorr=partialcorr(curr_elec_BOLD,curr_elec_Gamma,curr_elec_distance,'type','Spearman');
  rho_elec_BOLD_HFB_medium_partialcorr=partialcorr(curr_elec_BOLD,curr_elec_HFB_medium,curr_elec_distance,'type','Spearman');
 rho_elec_BOLD_alpha_medium_partialcorr=partialcorr(curr_elec_BOLD,curr_elec_alpha_medium,curr_elec_distance,'type','Spearman');
 rho_elec_BOLD_beta1_medium_partialcorr=partialcorr(curr_elec_BOLD,curr_elec_beta1_medium,curr_elec_distance,'type','Spearman');
 rho_elec_BOLD_HFB_slow_medium_partialcorr=partialcorr(curr_elec_BOLD,curr_elec_HFB_slow,curr_elec_distance,'type','Spearman');
 rho_elec_BOLD_beta2_medium_partialcorr=partialcorr(curr_elec_BOLD,curr_elec_beta2_medium,curr_elec_distance,'type','Spearman');
 rho_elec_BOLD_Theta_medium_partialcorr=partialcorr(curr_elec_BOLD,curr_elec_Theta_medium,curr_elec_distance,'type','Spearman');
 rho_elec_BOLD_Delta_medium_partialcorr=partialcorr(curr_elec_BOLD,curr_elec_Delta_medium,curr_elec_distance,'type','Spearman');
 rho_elec_BOLD_Gamma_medium_partialcorr=partialcorr(curr_elec_BOLD,curr_elec_Gamma_medium,curr_elec_distance,'type','Spearman');
   rho_elec_BOLD_HFB_fast_partialcorr=partialcorr(curr_elec_BOLD,curr_elec_HFB_fast,curr_elec_distance,'type','Spearman');
 rho_elec_BOLD_alpha_fast_partialcorr=partialcorr(curr_elec_BOLD,curr_elec_alpha_fast,curr_elec_distance,'type','Spearman');
 rho_elec_BOLD_beta1_fast_partialcorr=partialcorr(curr_elec_BOLD,curr_elec_beta1_fast,curr_elec_distance,'type','Spearman');
 rho_elec_BOLD_HFB_slow_fast_partialcorr=partialcorr(curr_elec_BOLD,curr_elec_HFB_slow,curr_elec_distance,'type','Spearman');
 rho_elec_BOLD_beta2_fast_partialcorr=partialcorr(curr_elec_BOLD,curr_elec_beta2_fast,curr_elec_distance,'type','Spearman');
 rho_elec_BOLD_Theta_fast_partialcorr=partialcorr(curr_elec_BOLD,curr_elec_Theta_fast,curr_elec_distance,'type','Spearman');
 rho_elec_BOLD_Delta_fast_partialcorr=partialcorr(curr_elec_BOLD,curr_elec_Delta_fast,curr_elec_distance,'type','Spearman');
 rho_elec_BOLD_Gamma_fast_partialcorr=partialcorr(curr_elec_BOLD,curr_elec_Gamma_fast,curr_elec_distance,'type','Spearman');
 %rho_elec_BOLD_SCP_partialcorr=partialcorr(curr_elec_BOLD,curr_elec_SCP,curr_elec_distance,'type','Spearman');
 elec_name=char(parcOut(i,1)); 
 
 if plotting=='1' || plotting=='0'
    figure(3)
scatter(curr_elec_BOLD,curr_elec_HFB_medium,'MarkerEdgeColor','k','MarkerFaceColor',[0 0 0]); 
h=lsline; set(h(1),'color',[0 0 0],'LineWidth',3);
set(gca,'Fontsize',18,'FontWeight','bold','LineWidth',2,'TickDir','out');
set(gcf,'color','w');
title({[elec_name ': BOLD FC vs HFB (0.1-1Hz) FC']; ...
    ['r = ' num2str(elec_BOLD_HFB_medium_corr) '; rho = ' num2str(rho_elec_BOLD_HFB_medium_corr)]; ...
    ['distance-corrected r = ' num2str(elec_BOLD_HFB_medium_partialcorr) '; rho = ' num2str(rho_elec_BOLD_HFB_medium_partialcorr)]},'Fontsize',12);
xlabel('BOLD FC (z)');
ylabel('ECoG-HFB FC (z)');
    ylim([-0.2 0.6]);
    xlim([-1 2]);
       set(gca,'Ytick',[-0.2 0 0.2 0.4 0.6])
       set(gca,'Xtick',[-1 -0.5 0 0.5 1 1.5 2])  
set(gcf,'PaperPositionMode','auto');
if BOLD_pipeline==1
print('-opengl','-r300','-dpng',strcat([pwd,filesep,elec_name '_BOLD_HFB_medium_GSR']));
elseif BOLD_pipeline==2
 print('-opengl','-r300','-dpng',strcat([pwd,filesep,elec_name '_BOLD_HFB_medium_AROMA']));
elseif BOLD_pipeline==3
print('-opengl','-r300','-dpng',strcat([pwd,filesep,elec_name '_BOLD_HFB_medium_NoGSR']));
elseif BOLD_pipeline==4
 print('-opengl','-r300','-dpng',strcat([pwd,filesep,elec_name '_BOLD_HFB_medium_aCompCor']));  
end
 close;
 if use_elec==1
     corr_BOLD_HFB_medium_allelecs(i,:)=elec_BOLD_HFB_medium_corr;
 partialcorr_BOLD_HFB_medium_allelecs(i,:)=elec_BOLD_HFB_medium_partialcorr;
 p_BOLD_HFB_medium_allelecs(i,:)=p_medium_partial;
 else
       corr_BOLD_HFB_medium_allelecs(i,:)=NaN;
  partialcorr_BOLD_HFB_medium_allelecs(i,:)=NaN; 
   p_BOLD_HFB_medium_allelecs(i,:)=NaN;
 end
 end
 
 if plotting=='2' || plotting=='0'
    figure(3)
scatter(curr_elec_BOLD,curr_elec_alpha_medium,'MarkerEdgeColor','k','MarkerFaceColor',[0 0 0]); 
h=lsline; set(h(1),'color',[0 0 0],'LineWidth',3);
set(gca,'Fontsize',14,'FontWeight','bold','LineWidth',2,'TickDir','out');
set(gcf,'color','w');
title({[elec_name ': BOLD FC vs alpha (0.1-1Hz) FC']; ...
    ['r = ' num2str(elec_BOLD_alpha_medium_corr) '; rho = ' num2str(rho_elec_BOLD_alpha_medium_corr)]; ...
    ['distance-corrected r = ' num2str(elec_BOLD_alpha_medium_partialcorr) '; rho = ' num2str(rho_elec_BOLD_alpha_medium_partialcorr)]},'Fontsize',12);
xlabel('BOLD FC');
ylabel('alpha (0.1-1Hz) FC');
set(gcf,'PaperPositionMode','auto');
if BOLD_pipeline==1
print('-opengl','-r300','-dpng',strcat([pwd,filesep,elec_name '_BOLD_alpha_medium_GSR']));
elseif BOLD_pipeline==2
    print('-opengl','-r300','-dpng',strcat([pwd,filesep,elec_name '_BOLD_alpha_medium_AROMA']));
elseif BOLD_pipeline==3
print('-opengl','-r300','-dpng',strcat([pwd,filesep,elec_name '_BOLD_alpha_medium_NoGSR']));
elseif BOLD_pipeline==4
    print('-opengl','-r300','-dpng',strcat([pwd,filesep,elec_name '_BOLD_alpha_medium_aCompCor']));   
end
close;
 if use_elec==1
     corr_BOLD_alpha_medium_allelecs(i,:)=elec_BOLD_alpha_medium_corr;
 partialcorr_BOLD_alpha_medium_allelecs(i,:)=elec_BOLD_alpha_medium_partialcorr;
 p_BOLD_alpha_medium_allelecs(i,:)=p_alpha_medium_partial;
 else
       corr_BOLD_alpha_medium_allelecs(i,:)=NaN;
  partialcorr_BOLD_alpha_medium_allelecs(i,:)=NaN; 
   p_BOLD_alpha_medium_allelecs(i,:)=NaN;
 end
 end

if plotting=='3' || plotting=='0'
    figure(3)
scatter(curr_elec_BOLD,curr_elec_HFB_slow,'MarkerEdgeColor','k','MarkerFaceColor',[0 0 0]); 
h=lsline; set(h(1),'color',[0 0 0],'LineWidth',3);
set(gca,'Fontsize',14,'FontWeight','bold','LineWidth',2,'TickDir','out');
set(gcf,'color','w');
title({[elec_name ': BOLD FC vs HFB (<0.1) FC']; ...
    ['r = ' num2str(elec_BOLD_HFB_slow_corr) '; rho = ' num2str(rho_elec_BOLD_HFB_slow_corr)]; ...
    ['distance-corrected r = ' num2str(elec_BOLD_HFB_slow_partialcorr) '; rho = ' num2str(rho_elec_BOLD_HFB_slow_partialcorr)]},'Fontsize',12);
xlabel('BOLD FC');
ylabel('HFB (<0.1) FC');
set(gcf,'PaperPositionMode','auto');
if BOLD_pipeline==1
print('-opengl','-r300','-dpng',strcat([pwd,filesep,elec_name '_BOLD_HFB_slow_GSR']));
elseif BOLD_pipeline==2
 print('-opengl','-r300','-dpng',strcat([pwd,filesep,elec_name '_BOLD_HFB_slow_AROMA']));
elseif BOLD_pipeline==3
print('-opengl','-r300','-dpng',strcat([pwd,filesep,elec_name '_BOLD_HFB_slow_NoGSR']));
elseif BOLD_pipeline==4
 print('-opengl','-r300','-dpng',strcat([pwd,filesep,elec_name '_BOLD_HFB_slow_aCompCor']));  
end
 close;
 if use_elec==1
     corr_BOLD_HFB_slow_allelecs(i,:)=elec_BOLD_HFB_slow_corr;
 partialcorr_BOLD_HFB_slow_allelecs(i,:)=elec_BOLD_HFB_slow_partialcorr;
 p_BOLD_HFB_slow_allelecs(i,:)=p_slow_partial;
 else
       corr_BOLD_HFB_slow_allelecs(i,:)=NaN;
  partialcorr_BOLD_HFB_slow_allelecs(i,:)=NaN; 
   p_BOLD_HFB_slow_allelecs(i,:)=NaN;
 end
end

  if plotting=='4' || plotting=='0'
    figure(3)
scatter(curr_elec_BOLD,curr_elec_beta1_medium,'MarkerEdgeColor','k','MarkerFaceColor',[0 0 0]); 
h=lsline; set(h(1),'color',[0 0 0],'LineWidth',3);
set(gca,'Fontsize',14,'FontWeight','bold','LineWidth',2,'TickDir','out');
set(gcf,'color','w');
title({[elec_name ': BOLD FC vs beta1 (0.1-1Hz) FC']; ...
    ['r = ' num2str(elec_BOLD_beta1_medium_corr) '; rho = ' num2str(rho_elec_BOLD_beta1_medium_corr)]; ...
    ['distance-corrected r = ' num2str(elec_BOLD_beta1_medium_partialcorr) '; rho = ' num2str(rho_elec_BOLD_beta1_medium_partialcorr)]},'Fontsize',12);
xlabel('BOLD FC');
ylabel('beta1 (0.1-1Hz) FC');
set(gcf,'PaperPositionMode','auto');
if BOLD_pipeline==1
print('-opengl','-r300','-dpng',strcat([pwd,filesep,elec_name '_BOLD_beta1_medium_GSR']));
elseif BOLD_pipeline==2
    print('-opengl','-r300','-dpng',strcat([pwd,filesep,elec_name '_BOLD_beta1_medium_AROMA']));
elseif BOLD_pipeline==3
print('-opengl','-r300','-dpng',strcat([pwd,filesep,elec_name '_BOLD_beta1_medium_NoGSR']));
elseif BOLD_pipeline==4
    print('-opengl','-r300','-dpng',strcat([pwd,filesep,elec_name '_BOLD_beta1_medium_aCompCor']));   
end
close;
 if use_elec==1
     corr_BOLD_beta1_medium_allelecs(i,:)=elec_BOLD_beta1_medium_corr;
 partialcorr_BOLD_beta1_medium_allelecs(i,:)=elec_BOLD_beta1_medium_partialcorr;
 p_BOLD_beta1_medium_allelecs(i,:)=p_beta1_medium_partial;
 else
       corr_BOLD_beta1_medium_allelecs(i,:)=NaN;
  partialcorr_BOLD_beta1_medium_allelecs(i,:)=NaN; 
   p_BOLD_beta1_medium_allelecs(i,:)=NaN;
 end
  end
 
  if plotting=='5' || plotting=='0'
    figure(3)
scatter(curr_elec_BOLD,curr_elec_beta2_medium,'MarkerEdgeColor','k','MarkerFaceColor',[0 0 0]); 
h=lsline; set(h(1),'color',[0 0 0],'LineWidth',3);
set(gca,'Fontsize',14,'FontWeight','bold','LineWidth',2,'TickDir','out');
set(gcf,'color','w');
title({[elec_name ': BOLD FC vs beta2 (0.1-1Hz) FC']; ...
    ['r = ' num2str(elec_BOLD_beta2_medium_corr) '; rho = ' num2str(rho_elec_BOLD_beta2_medium_corr)]; ...
    ['distance-corrected r = ' num2str(elec_BOLD_beta2_medium_partialcorr) '; rho = ' num2str(rho_elec_BOLD_beta2_medium_partialcorr)]},'Fontsize',12);
xlabel('BOLD FC');
ylabel('beta2 (0.1-1Hz) FC');
set(gcf,'PaperPositionMode','auto');
if BOLD_pipeline==1
print('-opengl','-r300','-dpng',strcat([pwd,filesep,elec_name '_BOLD_beta2_medium_GSR']));
elseif BOLD_pipeline==2
    print('-opengl','-r300','-dpng',strcat([pwd,filesep,elec_name '_BOLD_beta2_medium_AROMA']));
elseif BOLD_pipeline==3
print('-opengl','-r300','-dpng',strcat([pwd,filesep,elec_name '_BOLD_beta2_medium_NoGSR']));
elseif BOLD_pipeline==4
    print('-opengl','-r300','-dpng',strcat([pwd,filesep,elec_name '_BOLD_beta2_medium_aCompCor']));   
end
close;
 if use_elec==1
     corr_BOLD_beta2_medium_allelecs(i,:)=elec_BOLD_beta2_medium_corr;
 partialcorr_BOLD_beta2_medium_allelecs(i,:)=elec_BOLD_beta2_medium_partialcorr;
 p_BOLD_beta2_medium_allelecs(i,:)=p_beta2_medium_partial;
 else
       corr_BOLD_beta2_medium_allelecs(i,:)=NaN;
  partialcorr_BOLD_beta2_medium_allelecs(i,:)=NaN; 
   p_BOLD_beta2_medium_allelecs(i,:)=NaN;
 end
  end
 
 if plotting=='6' || plotting=='0'
    figure(3)
scatter(curr_elec_BOLD,curr_elec_Theta_medium,'MarkerEdgeColor','k','MarkerFaceColor',[0 0 0]); 
h=lsline; set(h(1),'color',[0 0 0],'LineWidth',3);
set(gca,'Fontsize',14,'FontWeight','bold','LineWidth',2,'TickDir','out');
set(gcf,'color','w');
title({[elec_name ': BOLD FC vs Theta (0.1-1Hz) FC']; ...
    ['r = ' num2str(elec_BOLD_Theta_medium_corr) '; rho = ' num2str(rho_elec_BOLD_Theta_medium_corr)]; ...
    ['distance-corrected r = ' num2str(elec_BOLD_Theta_medium_partialcorr) '; rho = ' num2str(rho_elec_BOLD_Theta_medium_partialcorr)]},'Fontsize',12);
xlabel('BOLD FC');
ylabel('Theta (0.1-1Hz) FC');
set(gcf,'PaperPositionMode','auto');
if BOLD_pipeline==1
print('-opengl','-r300','-dpng',strcat([pwd,filesep,elec_name '_BOLD_Theta_medium_GSR']));
elseif BOLD_pipeline==2
    print('-opengl','-r300','-dpng',strcat([pwd,filesep,elec_name '_BOLD_Theta_medium_AROMA']));
elseif BOLD_pipeline==3
print('-opengl','-r300','-dpng',strcat([pwd,filesep,elec_name '_BOLD_Theta_medium_NoGSR']));
elseif BOLD_pipeline==4
    print('-opengl','-r300','-dpng',strcat([pwd,filesep,elec_name '_BOLD_Theta_medium_aCompCor']));   
end
close;
 if use_elec==1
     corr_BOLD_Theta_medium_allelecs(i,:)=elec_BOLD_Theta_medium_corr;
 partialcorr_BOLD_Theta_medium_allelecs(i,:)=elec_BOLD_Theta_medium_partialcorr;
 p_BOLD_Theta_medium_allelecs(i,:)=p_Theta_medium_partial;
 else
       corr_BOLD_Theta_medium_allelecs(i,:)=NaN;
  partialcorr_BOLD_Theta_medium_allelecs(i,:)=NaN; 
   p_BOLD_Theta_medium_allelecs(i,:)=NaN;
 end
 end
 
  if plotting=='7' || plotting=='0'
    figure(3)
scatter(curr_elec_BOLD,curr_elec_Delta_medium,'MarkerEdgeColor','k','MarkerFaceColor',[0 0 0]); 
h=lsline; set(h(1),'color',[0 0 0],'LineWidth',3);
set(gca,'Fontsize',14,'FontWeight','bold','LineWidth',2,'TickDir','out');
set(gcf,'color','w');
title({[elec_name ': BOLD FC vs Delta (0.1-1Hz) FC']; ...
    ['r = ' num2str(elec_BOLD_Delta_medium_corr) '; rho = ' num2str(rho_elec_BOLD_Delta_medium_corr)]; ...
    ['distance-corrected r = ' num2str(elec_BOLD_Delta_medium_partialcorr) '; rho = ' num2str(rho_elec_BOLD_Delta_medium_partialcorr)]},'Fontsize',12);
xlabel('BOLD FC');
ylabel('Delta (0.1-1Hz) FC');
set(gcf,'PaperPositionMode','auto');
if BOLD_pipeline==1
print('-opengl','-r300','-dpng',strcat([pwd,filesep,elec_name '_BOLD_Delta_medium_GSR']));
elseif BOLD_pipeline==2
    print('-opengl','-r300','-dpng',strcat([pwd,filesep,elec_name '_BOLD_Delta_medium_AROMA']));
elseif BOLD_pipeline==3
print('-opengl','-r300','-dpng',strcat([pwd,filesep,elec_name '_BOLD_Delta_medium_NoGSR']));
elseif BOLD_pipeline==4
    print('-opengl','-r300','-dpng',strcat([pwd,filesep,elec_name '_BOLD_Delta_medium_aCompCor']));   
end
close;
 if use_elec==1
     corr_BOLD_Delta_medium_allelecs(i,:)=elec_BOLD_Delta_medium_corr;
 partialcorr_BOLD_Delta_medium_allelecs(i,:)=elec_BOLD_Delta_medium_partialcorr;
 p_BOLD_Delta_medium_allelecs(i,:)=p_Delta_medium_partial;
 else
       corr_BOLD_Delta_medium_allelecs(i,:)=NaN;
  partialcorr_BOLD_Delta_medium_allelecs(i,:)=NaN; 
   p_BOLD_Delta_medium_allelecs(i,:)=NaN;
 end
  end
 
  if plotting=='8' || plotting=='0'
    figure(3)
scatter(curr_elec_BOLD,curr_elec_Gamma_medium,'MarkerEdgeColor','k','MarkerFaceColor',[0 0 0]); 
h=lsline; set(h(1),'color',[0 0 0],'LineWidth',3);
set(gca,'Fontsize',14,'FontWeight','bold','LineWidth',2,'TickDir','out');
set(gcf,'color','w');
title({[elec_name ': BOLD FC vs Gamma (0.1-1Hz) FC']; ...
    ['r = ' num2str(elec_BOLD_Gamma_medium_corr) '; rho = ' num2str(rho_elec_BOLD_Gamma_medium_corr)]; ...
    ['distance-corrected r = ' num2str(elec_BOLD_Gamma_medium_partialcorr) '; rho = ' num2str(rho_elec_BOLD_Gamma_medium_partialcorr)]},'Fontsize',12);
xlabel('BOLD FC');
ylabel('Gamma (0.1-1Hz) FC');
set(gcf,'PaperPositionMode','auto');
if BOLD_pipeline==1
print('-opengl','-r300','-dpng',strcat([pwd,filesep,elec_name '_BOLD_Gamma_medium_GSR']));
elseif BOLD_pipeline==2
    print('-opengl','-r300','-dpng',strcat([pwd,filesep,elec_name '_BOLD_Gamma_medium_AROMA']));
elseif BOLD_pipeline==3
print('-opengl','-r300','-dpng',strcat([pwd,filesep,elec_name '_BOLD_Gamma_medium_NoGSR']));
elseif BOLD_pipeline==4
    print('-opengl','-r300','-dpng',strcat([pwd,filesep,elec_name '_BOLD_Gamma_medium_aCompCor']));   
end
close;
 if use_elec==1
     corr_BOLD_Gamma_medium_allelecs(i,:)=elec_BOLD_Gamma_medium_corr;
 partialcorr_BOLD_Gamma_medium_allelecs(i,:)=elec_BOLD_Gamma_medium_partialcorr;
 p_BOLD_Gamma_medium_allelecs(i,:)=p_Gamma_medium_partial;
 else
     corr_BOLD_Gamma_medium_allelecs(i,:)=NaN;  
  partialcorr_BOLD_Gamma_medium_allelecs(i,:)=NaN; 
   p_BOLD_Gamma_medium_allelecs(i,:)=NaN;
 end
  end
  
    if plotting=='9' || plotting=='0'
%     figure(3)
% scatter(curr_elec_BOLD,curr_elec_SCP,'MarkerEdgeColor','k','MarkerFaceColor',[0 0 0]); 
% h=lsline; set(h(1),'color',[0 0 0],'LineWidth',3);
% set(gca,'Fontsize',14,'FontWeight','bold','LineWidth',2,'TickDir','out');
% set(gcf,'color','w');
% title({[elec_name ': BOLD FC vs SCP (<1Hz) FC']; ...
%     ['r = ' num2str(elec_BOLD_SCP_corr) '; rho = ' num2str(rho_elec_BOLD_SCP_corr)]; ...
%     ['distance-corrected r = ' num2str(elec_BOLD_SCP_partialcorr) '; rho = ' num2str(rho_elec_BOLD_SCP_partialcorr)]},'Fontsize',12);
% xlabel('BOLD FC');
% ylabel('SCP (0.1-1Hz) FC');
% set(gcf,'PaperPositionMode','auto');
% if BOLD_pipeline==1
% print('-opengl','-r300','-dpng',strcat([pwd,filesep,elec_name '_BOLD_SCP_medium_GSR']));
% elseif BOLD_pipeline==2
%     print('-opengl','-r300','-dpng',strcat([pwd,filesep,elec_name '_BOLD_SCP_medium_AROMA']));
% elseif BOLD_pipeline==3
% print('-opengl','-r300','-dpng',strcat([pwd,filesep,elec_name '_BOLD_SCP_medium_NoGSR']));
% elseif BOLD_pipeline==4
%     print('-opengl','-r300','-dpng',strcat([pwd,filesep,elec_name '_BOLD_SCP_medium_aCompCor']));   
% end
% close;
%  if use_elec==1
%      corr_BOLD_SCP_allelecs(i,:)=elec_BOLD_SCP_corr;
%  partialcorr_BOLD_SCP_allelecs(i,:)=elec_BOLD_SCP_partialcorr;
%  p_BOLD_SCP_allelecs(i,:)=p_SCP_partial;
%  else
%        corr_BOLD_SCP_allelecs(i,:)=NaN;
%   partialcorr_BOLD_SCP_allelecs(i,:)=NaN; 
%    p_BOLD_SCP_allelecs(i,:)=NaN;
%  end
    end
  
   if plotting=='a' || plotting=='0'
    figure(3)
scatter(curr_elec_BOLD,curr_elec_HFB,'MarkerEdgeColor','k','MarkerFaceColor',[0 0 0]); 
h=lsline; set(h(1),'color',[0 0 0],'LineWidth',3);
set(gca,'Fontsize',14,'FontWeight','bold','LineWidth',2,'TickDir','out');
set(gcf,'color','w');
title({[elec_name ': BOLD FC vs HFB (unfiltered) FC']; ...
    ['r = ' num2str(elec_BOLD_HFB_corr) '; rho = ' num2str(rho_elec_BOLD_HFB_corr)]; ...
    ['distance-corrected r = ' num2str(elec_BOLD_HFB_partialcorr) '; rho = ' num2str(rho_elec_BOLD_HFB_partialcorr)]},'Fontsize',12);
xlabel('BOLD FC');
ylabel('HFB (unfiltered) FC');
set(gcf,'PaperPositionMode','auto');
if BOLD_pipeline==1
print('-opengl','-r300','-dpng',strcat([pwd,filesep,elec_name '_BOLD_HFB_GSR']));
elseif BOLD_pipeline==2
    print('-opengl','-r300','-dpng',strcat([pwd,filesep,elec_name '_BOLD_HFB_AROMA']));
elseif BOLD_pipeline==3
print('-opengl','-r300','-dpng',strcat([pwd,filesep,elec_name '_BOLD_HFB_NoGSR']));
elseif BOLD_pipeline==4
    print('-opengl','-r300','-dpng',strcat([pwd,filesep,elec_name '_BOLD_HFB_aCompCor']));   
end
close;
 if use_elec==1
     corr_BOLD_HFB_allelecs(i,:)=elec_BOLD_HFB_corr;
 partialcorr_BOLD_HFB_allelecs(i,:)=elec_BOLD_HFB_partialcorr;
 p_BOLD_HFB_allelecs(i,:)=p_HFB_partial;
 else
       corr_BOLD_HFB_allelecs(i,:)=NaN;
  partialcorr_BOLD_HFB_allelecs(i,:)=NaN; 
   p_BOLD_HFB_allelecs(i,:)=NaN;
 end
   end   
 
   if plotting=='b' || plotting=='0'
    figure(3)
scatter(curr_elec_BOLD,curr_elec_HFB_fast,'MarkerEdgeColor','k','MarkerFaceColor',[0 0 0]); 
h=lsline; set(h(1),'color',[0 0 0],'LineWidth',3);
set(gca,'Fontsize',14,'FontWeight','bold','LineWidth',2,'TickDir','out');
set(gcf,'color','w');
title({[elec_name ': BOLD FC vs HFB (0.1-1Hz) FC']; ...
    ['r = ' num2str(elec_BOLD_HFB_fast_corr) '; rho = ' num2str(rho_elec_BOLD_HFB_fast_corr)]; ...
    ['distance-corrected r = ' num2str(elec_BOLD_HFB_fast_partialcorr) '; rho = ' num2str(rho_elec_BOLD_HFB_fast_partialcorr)]},'Fontsize',12);
xlabel('BOLD FC');
ylabel('HFB (0.1-1Hz) FC');
set(gcf,'PaperPositionMode','auto');
if BOLD_pipeline==1
print('-opengl','-r300','-dpng',strcat([pwd,filesep,elec_name '_BOLD_HFB_fast_GSR']));
elseif BOLD_pipeline==2
    print('-opengl','-r300','-dpng',strcat([pwd,filesep,elec_name '_BOLD_HFB_fast_AROMA']));
elseif BOLD_pipeline==3
print('-opengl','-r300','-dpng',strcat([pwd,filesep,elec_name '_BOLD_HFB_fast_NoGSR']));
elseif BOLD_pipeline==4
    print('-opengl','-r300','-dpng',strcat([pwd,filesep,elec_name '_BOLD_HFB_fast_aCompCor']));   
end
close;
 if use_elec==1
     corr_BOLD_HFB_fast_allelecs(i,:)=elec_BOLD_HFB_fast_corr;
 partialcorr_BOLD_HFB_fast_allelecs(i,:)=elec_BOLD_HFB_fast_partialcorr;
 p_BOLD_HFB_fast_allelecs(i,:)=p_HFB_fast_partial;
 else
     corr_BOLD_HFB_fast_allelecs(i,:)=NaN;  
  partialcorr_BOLD_HFB_fast_allelecs(i,:)=NaN; 
   p_BOLD_HFB_fast_allelecs(i,:)=NaN;
 end
  end
    
    end
end

%% save correlations
if plotting=='1' || plotting=='0'   
  save('corr_BOLD_HFB_medium_allelecs','corr_BOLD_HFB_medium_allelecs');  
save('partialcorr_BOLD_HFB_medium_allelecs','partialcorr_BOLD_HFB_medium_allelecs');
save('p_BOLD_HFB_medium_allelecs','p_BOLD_HFB_medium_allelecs');
end
if plotting=='2' || plotting=='0'
    save('corr_BOLD_alpha_medium_allelecs','corr_BOLD_alpha_medium_allelecs');
   save('partialcorr_BOLD_alpha_medium_allelecs','partialcorr_BOLD_alpha_medium_allelecs');
save('p_BOLD_alpha_medium_allelecs','p_BOLD_alpha_medium_allelecs'); 
end
  if plotting=='3' || plotting=='0'
      save('corr_BOLD_HFB_slow_allelecs','corr_BOLD_HFB_slow_allelecs');
   save('partialcorr_BOLD_HFB_slow_allelecs','partialcorr_BOLD_HFB_slow_allelecs');
save('p_BOLD_HFB_slow_allelecs','p_BOLD_HFB_slow_allelecs'); 
  end
  if plotting=='4' || plotting=='0'
      save('corr_BOLD_beta1_medium_allelecs','corr_BOLD_beta1_medium_allelecs');
   save('partialcorr_BOLD_beta1_medium_allelecs','partialcorr_BOLD_beta1_medium_allelecs');
save('p_BOLD_beta1_medium_allelecs','p_BOLD_beta1_medium_allelecs'); 
  end
  if plotting=='5' || plotting=='0'
      save('corr_BOLD_beta2_medium_allelecs','corr_BOLD_beta2_medium_allelecs');
   save('partialcorr_BOLD_beta2_medium_allelecs','partialcorr_BOLD_beta2_medium_allelecs');
save('p_BOLD_beta2_medium_allelecs','p_BOLD_beta2_medium_allelecs'); 
  end
  if plotting=='6' || plotting=='0'
      save('corr_BOLD_Theta_medium_allelecs','corr_BOLD_Theta_medium_allelecs');
   save('partialcorr_BOLD_Theta_medium_allelecs','partialcorr_BOLD_Theta_medium_allelecs');
save('p_BOLD_Theta_medium_allelecs','p_BOLD_Theta_medium_allelecs');
  end
  if plotting=='7' || plotting=='0'
      save('corr_BOLD_Delta_medium_allelecs','corr_BOLD_Delta_medium_allelecs');
   save('partialcorr_BOLD_Delta_medium_allelecs','partialcorr_BOLD_Delta_medium_allelecs');
save('p_BOLD_Delta_medium_allelecs','p_BOLD_Delta_medium_allelecs'); 
  end
  if plotting=='8' || plotting=='0'
      save('corr_BOLD_Gamma_medium_allelecs','corr_BOLD_Gamma_medium_allelecs');
   save('partialcorr_BOLD_Gamma_medium_allelecs','partialcorr_BOLD_Gamma_medium_allelecs');
save('p_BOLD_Gamma_medium_allelecs','p_BOLD_Gamma_medium_allelecs'); 
  end

    if plotting=='b' || plotting=='0'
      save('corr_BOLD_HFB_fast_allelecs','corr_BOLD_HFB_fast_allelecs');
   save('partialcorr_BOLD_HFB_fast_allelecs','partialcorr_BOLD_HFB_fast_allelecs');
save('p_BOLD_HFB_fast_allelecs','p_BOLD_HFB_fast_allelecs'); 
  end
  
elec_names=parcOut(:,1);
save('elec_names','elec_names');

%% DMN vs other networks
% Normalize time-courses prior to plotting
if depth==2
DMN_BOLD_plot_ts=(DMN_BOLD_mean_ts-mean(DMN_BOLD_mean_ts))/std(DMN_BOLD_mean_ts);
SN_BOLD_plot_ts=(SN_BOLD_mean_ts-mean(SN_BOLD_mean_ts))/std(SN_BOLD_mean_ts);
Yeo_CoreDMN_BOLD_plot_ts=(Yeo_CoreDMN_BOLD_mean_ts-mean(Yeo_CoreDMN_BOLD_mean_ts))/std(Yeo_CoreDMN_BOLD_mean_ts);
Yeo_SN_BOLD_plot_ts=(Yeo_VAN_BOLD_mean_ts-mean(Yeo_VAN_BOLD_mean_ts))/std(Yeo_VAN_BOLD_mean_ts);
global_HFB_plot_ts=(global_HFB-mean(global_HFB))/std(global_HFB);
global_alpha_plot_ts=(global_alpha-mean(global_alpha))/std(global_alpha);


DMN_ECoG_slow_plot_ts=(DMN_ECoG_slow_mean_ts-mean(DMN_ECoG_slow_mean_ts))/std(DMN_ECoG_slow_mean_ts);
SN_ECoG_slow_plot_ts=(SN_ECoG_slow_mean_ts-mean(SN_ECoG_slow_mean_ts))/std(SN_ECoG_slow_mean_ts);
DMN_ECoG_medium_plot_ts=(DMN_ECoG_medium_mean_ts-mean(DMN_ECoG_medium_mean_ts))/std(DMN_ECoG_medium_mean_ts);
DMN_ECoG_alpha_plot_ts=(DMN_ECoG_alpha_mean_ts-mean(DMN_ECoG_alpha_mean_ts))/std(DMN_ECoG_alpha_mean_ts);
SN_ECoG_medium_plot_ts=(SN_ECoG_medium_mean_ts-mean(SN_ECoG_medium_mean_ts))/std(SN_ECoG_medium_mean_ts);
SN_ECoG_alpha_plot_ts=(SN_ECoG_alpha_mean_ts-mean(SN_ECoG_alpha_mean_ts))/std(SN_ECoG_alpha_mean_ts);
DAN_ECoG_medium_plot_ts=(DAN_ECoG_medium_mean_ts-mean(DAN_ECoG_medium_mean_ts))/std(DAN_ECoG_medium_mean_ts);
DAN_ECoG_alpha_plot_ts=(DAN_ECoG_alpha_mean_ts-mean(DAN_ECoG_alpha_mean_ts))/std(DAN_ECoG_alpha_mean_ts);
FPN_ECoG_medium_plot_ts=(FPN_ECoG_medium_mean_ts-mean(FPN_ECoG_medium_mean_ts))/std(FPN_ECoG_medium_mean_ts);
FPN_ECoG_alpha_plot_ts=(FPN_ECoG_alpha_mean_ts-mean(FPN_ECoG_alpha_mean_ts))/std(FPN_ECoG_alpha_mean_ts);

Yeo_CoreDMN_ECoG_slow_plot_ts=(Yeo_CoreDMN_ECoG_slow_mean_ts-mean(Yeo_CoreDMN_ECoG_slow_mean_ts))/std(Yeo_CoreDMN_ECoG_slow_mean_ts);
Yeo_SN_ECoG_slow_plot_ts=(Yeo_VAN_ECoG_slow_mean_ts-mean(Yeo_VAN_ECoG_slow_mean_ts))/std(Yeo_VAN_ECoG_slow_mean_ts);
Yeo_CoreDMN_ECoG_medium_plot_ts=(DMN_ECoG_medium_mean_ts-mean(DMN_ECoG_medium_mean_ts))/std(DMN_ECoG_medium_mean_ts);
Yeo_CoreDMN_ECoG_alpha_plot_ts=(Yeo_CoreDMN_ECoG_alpha_mean_ts-mean(Yeo_CoreDMN_ECoG_alpha_mean_ts))/std(Yeo_CoreDMN_ECoG_alpha_mean_ts);
Yeo_SN_ECoG_medium_plot_ts=(Yeo_VAN_ECoG_medium_mean_ts-mean(Yeo_VAN_ECoG_medium_mean_ts))/std(Yeo_VAN_ECoG_medium_mean_ts);
Yeo_SN_ECoG_alpha_plot_ts=(Yeo_VAN_ECoG_alpha_mean_ts-mean(Yeo_VAN_ECoG_alpha_mean_ts))/std(Yeo_VAN_ECoG_alpha_mean_ts);
Yeo_DAN_ECoG_medium_plot_ts=(Yeo_DAN_ECoG_medium_mean_ts-mean(Yeo_DAN_ECoG_medium_mean_ts))/std(Yeo_DAN_ECoG_medium_mean_ts);
Yeo_DAN_ECoG_alpha_plot_ts=(Yeo_DAN_ECoG_alpha_mean_ts-mean(Yeo_DAN_ECoG_alpha_mean_ts))/std(Yeo_DAN_ECoG_alpha_mean_ts);

figure(3)
plot(1:length(DMN_BOLD_plot_ts),DMN_BOLD_plot_ts,1:length(SN_BOLD_plot_ts),SN_BOLD_plot_ts);
title({['BOLD: mean DMN vs Salience (IndiPar)']; ['r = ' num2str(corr(DMN_BOLD_plot_ts,SN_BOLD_plot_ts))]} ,'Fontsize',12);
pause; close;

figure(3)
plot(1:length(Yeo_CoreDMN_BOLD_plot_ts),Yeo_CoreDMN_BOLD_plot_ts,1:length(Yeo_SN_BOLD_plot_ts),Yeo_SN_BOLD_plot_ts);
title({['BOLD: mean DMN Core vs Salience (Yeo)']; ['r = ' num2str(corr(Yeo_CoreDMN_BOLD_plot_ts,Yeo_SN_BOLD_plot_ts))]} ,'Fontsize',12);
pause; close;

figure(3)
plot(1:length(DMN_ECoG_slow_plot_ts),DMN_ECoG_slow_plot_ts,1:length(SN_ECoG_slow_plot_ts),SN_ECoG_slow_plot_ts);
title({['ECoG HFB <0.1 Hz: mean DMN vs Salience (IndiPar)']; ['r = ' num2str(corr(DMN_ECoG_slow_plot_ts,SN_ECoG_slow_plot_ts))]} ,'Fontsize',12);
pause; close;

figure(3)
plot(1:length(Yeo_CoreDMN_ECoG_slow_plot_ts),Yeo_CoreDMN_ECoG_slow_plot_ts,1:length(Yeo_SN_ECoG_slow_plot_ts),Yeo_SN_ECoG_slow_plot_ts);
title({['ECoG HFB <0.1 Hz: mean DMN vs Salience (Yeo)']; ['r = ' num2str(corr(Yeo_CoreDMN_ECoG_slow_plot_ts,Yeo_SN_ECoG_slow_plot_ts))]} ,'Fontsize',12);
pause; close;

%% iElvis plots of networks and electrode locations
cfg=[]; cfg.view=[hemi(1)]; cfg.overlayParcellation='Y17';
cfg.title=[Patient ': Core DMN electrodes'];
cfg.elecSize=5; cfg.elecShape='marker';cfg.opaqueness=1; cfg.pullOut=2;
cfg.elecCoord=Yeo_CoreDMN_coords; cfg.elecNames=Yeo_CoreDMN_names;
cfgOut=plotPialSurf(Patient,cfg);

cfg=[]; cfg.view=[hemi(1) 'm']; cfg.overlayParcellation='Y17';
cfg.title=[Patient ': Core DMN electrodes'];
cfg.elecSize=5; cfg.elecShape='marker';cfg.opaqueness=1; cfg.pullOut=2;
cfg.elecCoord=Yeo_CoreDMN_coords; cfg.elecNames=Yeo_CoreDMN_names;
cfgOut=plotPialSurf(Patient,cfg);
pause; close;

cfg=[]; cfg.view=hemi(1); cfg.overlayParcellation='Y17';
cfg.title=[Patient ': Salience Network electrodes'];
cfg.elecSize=5; cfg.elecShape='marker'; cfg.opaqueness=1; cfg.pullOut=2;
cfg.elecCoord=Yeo_VAN_coords; cfg.elecNames=Yeo_VAN_names;
cfgOut=plotPialSurf(Patient,cfg);

cfg=[]; cfg.view=[hemi(1) 'm']; cfg.overlayParcellation='Y17';
cfg.title=[Patient ': Salience Network electrodes'];
cfg.elecSize=5; cfg.elecShape='marker'; cfg.opaqueness=1; cfg.pullOut=2;
cfg.elecCoord=Yeo_VAN_coords; cfg.elecNames=Yeo_VAN_names;
cfgOut=plotPialSurf(Patient,cfg);
pause; close;

cfg=[]; cfg.view=[hemi(1)]; cfg.overlayParcellation='Y17';
cfg.title=[Patient ': DAN electrodes'];
cfg.elecSize=5; cfg.elecShape='marker'; cfg.opaqueness=1; cfg.pullOut=2;
cfg.elecCoord=Yeo_DAN_coords; cfg.elecNames=Yeo_DAN_names;
cfgOut=plotPialSurf(Patient,cfg);

cfg=[]; cfg.view=[hemi(1) 'm']; cfg.overlayParcellation='Y17';
cfg.title=[Patient ': DAN electrodes'];
cfg.elecSize=5; cfg.elecShape='marker'; cfg.opaqueness=1; cfg.pullOut=2;
cfg.elecCoord=Yeo_DAN_coords; cfg.elecNames=Yeo_DAN_names;
cfgOut=plotPialSurf(Patient,cfg);
pause; close;

%% Global HFB vs global alpha
figure(5)
plot(1:length(global_HFB_plot_ts),global_HFB_plot_ts,1:length(global_alpha_plot_ts),global_alpha_plot_ts);
title({['Global HFB (0.1-1Hz) vs global alpha (0.1-1Hz)']; ['r = ' num2str(corr(global_alpha,global_HFB))]; ...
    ['mean of local HFB-alpha correlations: r = ' num2str(mean_HFB_alpha_corr)]; ...
    ['mean of local HFB-beta1 correlations: r = ' num2str(mean_HFB_beta1_corr)]},'Fontsize',12);
pause; close;

%% DMN HFB vs DMN alpha (and other networks)
figure(5)
plot(1:length(DMN_ECoG_medium_plot_ts),DMN_ECoG_medium_plot_ts,1:length(DMN_ECoG_alpha_plot_ts),DMN_ECoG_alpha_plot_ts);
title({['DMN HFB (0.1-1Hz) vs DMN alpha (0.1-1Hz)']; ['r = ' num2str(corr(DMN_ECoG_medium_plot_ts,DMN_ECoG_alpha_plot_ts))]} ,'Fontsize',12);
pause; close;
end
% figure(5)
% plot(1:length(SN_ECoG_medium_plot_ts),SN_ECoG_medium_plot_ts,1:length(SN_ECoG_alpha_plot_ts),SN_ECoG_alpha_plot_ts);
% title({['Salience HFB (0.1-1Hz) vs Salience alpha (0.1-1Hz)']; ['r = ' num2str(corr(SN_ECoG_medium_plot_ts,SN_ECoG_alpha_plot_ts))]} ,'Fontsize',12);
% pause; close;

%% stepwise regression with HFB and alpha predicting BOLD
x1=medium_scatter; x2=alpha_scatter;
HFB_alpha=[ones(size(medium_scatter)) x1 x2 x1.*x2];
b=regress(BOLD_scatter,HFB_alpha);

%% stepwise regression with alpha, beta1 and HFB predicting BOLD
% in command window type 'stepwise(HFB_alpha_beta1,BOLD_scatter' for GUI
x3=beta1_scatter;
HFB_alpha_beta1=[ones(size(medium_scatter)) x1 x2 x3 x1.*x2 x2.*x3 x1.*x3];
B=regress(BOLD_scatter,HFB_alpha_beta1);

ECoG_duration_mins=(size(HFB,2)/1000)/60





