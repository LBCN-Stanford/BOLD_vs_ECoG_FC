%% Main function to compare BOLD vs iEEG functional connectivity within subject

%==========================================================================
% Written by Aaron Kucyi, LBCN, Stanford University
%==========================================================================

% Needed: manually created channel name-number mapping file (.xls format)
Patient=input('Patient name (folder name): ','s');
%runname=input('Run (e.g. 2): ','s');
%hemi=input('hemisphere (lh or rh): ','s');
depth=input('depth(1) or subdural(0)? ','s');
rest=input('Rest(1) Sleep(0) 7heaven (2) MMR (3)? ','s');
distance_exclusion=input('exclude short-distance pairs (1)? ','s');
if distance_exclusion=='1'
dist_thr=input('How short (mm)? ','s');
end
depth=str2num(depth);
%BOLD_run=input('BOLD run # (e.g. run1): ','s');
BOLD_run='run1';
tdt=input('TDT data? (1=TDT,0=EDF): ','s');
BOLD_pipeline=input('BOLD pipeline (1=GSR, 2=AROMA, 3=NoGSR, 4=aCompCor): ' ,'s'); % 1=GSR, 2=ICA-AROMA
signal=input('HFB unsmoothed (0) smoothed (1) 0.1-1 Hz (2) <0.1 Hz (3) ','s');
%plotting=input('plot all (0) HFB 0.1-1Hz (1)  alpha (2) HFB <0.1Hz (3) beta1 (4) beta2 (5) Theta (6) Delta (7) Gamma (8) SCP (9) HFB unfiltered (a) HFB >1Hz (b)? ','s');
tdt=str2num(tdt);
BOLD_pipeline=str2num(BOLD_pipeline);

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

    PIALVOX=0;


%% Get hemisphere file base name
getECoGSubDir; global globalECoGDir;

if rest=='1'
    task_type='Rest';
cd([globalECoGDir '/Rest/' Patient]);
elseif rest=='0'
    task_type='Sleep';
    cd([globalECoGDir '/Sleep/' Patient]);
elseif rest=='2'
    cd([globalECoGDir '/7heaven/' Patient]);
elseif rest=='3'
    cd([globalECoGDir '/MMR/' Patient]);
end

if depth=='0'
hemi=importdata(['hemi.txt']); 
hemi=char(hemi);
end
if rest=='1'
cd([globalECoGDir '/Rest/' Patient]);
elseif rest=='0'
    cd([globalECoGDir '/Sleep/' Patient]);
elseif rest=='2'
    cd([globalECoGDir '/7heaven/' Patient]);
elseif rest=='3'
    cd([globalECoGDir '/MMR/' Patient]);
end

%% load list of runs
load('runs.txt');

fsDir=getFsurfSubDir();
% set # of edge data points to delete from iEEG data
edge=10;
%Load channel name-number mapping
cd([fsDir '/' Patient '/elec_recon']);
[channumbers_iEEG,chanlabels]=xlsread('channelmap.xls');

% Load electrode coordinates
if Coords==1;
vox=dlmread([Patient '.PIAL'],' ',2,0);
brainmask_coords=vox;
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
fs_chanlabels=fs_chanlabels(3:end);

%% Get electrode names
parcOut=elec2Parc_v2(Patient,'DK',0);

%% Load fMRI electrode time series (ordered according to iElvis)
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

% create iElvis to iEEG chanlabel transformation vector
if depth==2
for i=1:length(chanlabels)
iElvis_to_iEEG_chanlabel(i,:)=channumbers_iEEG(strmatch(parcOut(i,1),chanlabels,'exact'));
end

% create iEEG to iElvis chanlabel transformation vector
for i=1:length(chanlabels)
    iEEG_to_iElvis_chanlabel(i,:)=strmatch(chanlabels(i),parcOut(:,1),'exact');    
end
end

if depth~=2 
    for i=1:length(chanlabels)
iElvis_to_iEEG_chanlabel(i,:)=channumbers_iEEG(strmatch(fs_chanlabels(i,1),chanlabels,'exact'));
end

% create iEEG to iElvis chanlabel transformation vector
for i=1:length(chanlabels)
    iEEG_to_iElvis_chanlabel(i,:)=strmatch(chanlabels(i),fs_chanlabels(:,1),'exact');    
end
    
end

%% Transform BOLD to iEEG space

for i=1:length(iElvis_to_iEEG_chanlabel)
    new_ind=iElvis_to_iEEG_chanlabel(i);
    elec_BOLD_ts=BOLD_ts(:,i);    
    BOLD_ts_iEEG_space(:,new_ind)=elec_BOLD_ts;
end


%% loop through iEEG runs
% load data file
for i=1:length(runs)
        curr_run=num2str(runs(i));
cd([globalECoGDir filesep task_type '/' Patient '/Run' curr_run]);

    if signal=='0';
filenames=dir('HFB*');
elseif signal=='1'
filenames=dir('SHFB*');    
if isempty(filenames)==1
   filenames=dir('SpHFB*'); 
end
elseif signal=='2'
    filenames=dir('bptf_mediumHFB*');
    if isempty(filenames)==1
        filenames=dir('bptf_mediumpHFB*');
    end
elseif signal=='3'
    filenames=dir('slowHFB*');
    if isempty(filenames)==1
   filenames=dir('slowpHFB*');
    end
end
filename=filenames(2,1).name;
D=spm_eeg_load(filename);    
   
% Load time series of all channels (in iEEG order)
elec_ts=[];
for j=1:total_bold;
    elec_ts(:,j)=D(j,:)';      
end

% Chop iEEG time series (delete beginning time points) 
% change 'Chop' variable at beginning of code to change 
elec_ts=elec_ts(Chop:length(elec_ts),:);

% Transform iEEG & BOLD to iElvis order
if i==1 % only on first loop iteration for BOLD
BOLD_iElvis=NaN(size(BOLD_ts,1),length(chanlabels));
for j=1:length(chanlabels);
    curr_iEEG_chan=channumbers_iEEG(j);
    new_ind=iEEG_to_iElvis_chanlabel(j);
    BOLD_iElvis(:,new_ind)=BOLD_ts_iEEG_space(:,curr_iEEG_chan);
end
end

elec_iElvis=NaN(size(elec_ts,1),length(chanlabels));
for j=1:length(chanlabels);
    curr_iEEG_chan=channumbers_iEEG(j);
    new_ind=iEEG_to_iElvis_chanlabel(j);
    elec_iElvis(:,new_ind)=elec_ts(:,curr_iEEG_chan);
end

% use bad indices from HFB 0.1-1Hz file (where bursts were excluded) 
bad_indices=[];
if use_bad==1
bad_indices=D.badchannels; 
end
overlap_elec=find((BOLD_ts_iEEG_space(1,:))==0); % WM and overlapping electrodes
bad_indices=[bad_indices overlap_elec];
bad_indices_iElvis=iEEG_to_iElvis_chanlabel(bad_indices);
bad_chans=chanlabels(bad_indices_iElvis);

%% TRANSFORM BAD INDICES TO IELVIS


% Change bad channels, WM channels, and channels with overlapping coordinates to NaN

for j=1:length(bad_indices_iElvis)
    elec_iElvis(:,bad_indices_iElvis(j))=NaN;
    BOLD_iElvis(:,bad_indices_iElvis(j))=NaN;
end


% more_bad=[];
% % Change any remaining NaNs in BOLD to NaNs in iEEG
% for j=1:length(BOLD_ts_iEEG_space(1,:))
%     if isnan(BOLD_ts_iEEG_space(1,j))==1
%         more_bad=[more_bad j];
%          elec_ts(:,j)=NaN;      
%     end
% end
% all_bad_indices=more_bad;



% Get vox coordinates (iElvis order) and remove bad indices
vox=brainmask_coords;
vox(find(isnan(BOLD_iElvis(1,:))),:)=NaN;

% calculate FC in BOLD and ECoG
BOLD_column=[]; iEEG_column=[]; BOLD_allcorr=[]; iEEG_allcorr=[];
iEEG_allcorr=corrcoef(elec_iElvis); iEEG_column=iEEG_allcorr(:);
BOLD_allcorr=corrcoef(BOLD_iElvis); BOLD_column=BOLD_allcorr(:);

iEEG_mat=iEEG_allcorr; iEEG_mat(find(iEEG_mat==1))=NaN; iEEG_mat(find(BOLD_allcorr>0.999))=NaN;
BOLD_mat=BOLD_allcorr; BOLD_mat(find(BOLD_mat>0.999))=NaN;

% remove diagonal and lower triangle
BOLD_column_ones=BOLD_column;
iEEG_column(BOLD_column_ones>0.999)=NaN; iEEG_column(isnan(iEEG_column))=[];
BOLD_column(find(BOLD_column_ones>0.999))=NaN; BOLD_column(isnan(BOLD_column))=[];

% Calculate distances
distance_column=[];
distances=zeros(size(vox,1));
for j = 1:size(vox,1)
 coord = vox(j,:);
     for jj = 1:size(vox,1)
         distances(j,jj)=sqrt((vox(jj,1)-coord(1))^2+(vox(jj,2)-coord(2))^2+(vox(jj,3)-coord(3))^2);
     end
end
distances(find(BOLD_allcorr>0.999))=NaN;
distance_column=distances(:);
distance_column(find(BOLD_column_ones>0.999))=NaN; distance_column(isnan(distance_column))=[];

% values for within-run scatter plots
BOLD_scatter=[]; iEEG_scatter=[]; distance_scatter=[];
 BOLD_scatter=BOLD_column;
 iEEG_scatter=iEEG_column;
 distance_scatter=distance_column;
 
% set bad indices: HFB medium corr >0.8; BOLD corr=1;
% remove_ind=[find(BOLD_scatter==1); find(medium_scatter>autocorr_thr & medium_scatter<1)];
% 
%  medium_scatter(remove_ind)=[];
%  slow_scatter(remove_ind)=[];
%  alpha_scatter(remove_ind)=[];
%  beta1_scatter(remove_ind)=[];
%  distance_scatter(remove_ind)=[];
% BOLD_scatter(remove_ind)=[]; 

% exclude electrode pairs below distance threshold
if distance_exclusion=='1'
    display(['Excluding pairs that are <' num2str(distance_thr) 'mm apart']);
distance_scatter(find(distance_scatter<distance_thr))=NaN;
iEEG_scatter(isnan(distance_scatter))=[];
BOLD_scatter(isnan(distance_scatter))=[];
distance_scatter(isnan(distance_scatter))=[];
end
n_elecs=length(iEEG_scatter);

% within-run stats
[r p]=corr(fisherz(iEEG_scatter),fisherz(BOLD_scatter));
iEEG_vs_BOLD_r=num2str(r); iEEG_vs_BOLD_p=num2str(p);
[r p]=corr(fisherz(iEEG_scatter),fisherz(BOLD_scatter),'type','Spearman');
iEEG_vs_BOLD_Spearman=num2str(r); iEEG_vs_BOLD_Spearman_p=num2str(p);

[r,p]=partialcorr(fisherz(iEEG_scatter),fisherz(BOLD_scatter),distance_scatter);
iEEG_partial=num2str(r);

% scatter plot
scatter(BOLD_scatter,iEEG_scatter);
pause; close;
display(['Done run ' curr_run '(' num2str(n_elecs) 'channels)']);
end

pause;





%% Make plots
mkdir BOLD_ECoG_figs
cd BOLD_ECoG_figs


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
 
 curr_elec_SCP=SCP_mat(:,i);
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
 curr_elec_SCP(isnan(curr_elec_SCP))=[];
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
 curr_elec_SCP=fisherz(curr_elec_SCP);
 
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
 elec_BOLD_SCP_corr=corr(curr_elec_BOLD,curr_elec_SCP);
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
 [elec_BOLD_SCP_partialcorr,p_SCP_partial]=partialcorr(curr_elec_BOLD,curr_elec_SCP,curr_elec_distance);
 
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
   rho_elec_BOLD_SCP_corr=corr(curr_elec_BOLD,curr_elec_SCP,'type','Spearman');
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
 rho_elec_BOLD_SCP_partialcorr=partialcorr(curr_elec_BOLD,curr_elec_SCP,curr_elec_distance,'type','Spearman');
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
    figure(3)
scatter(curr_elec_BOLD,curr_elec_SCP,'MarkerEdgeColor','k','MarkerFaceColor',[0 0 0]); 
h=lsline; set(h(1),'color',[0 0 0],'LineWidth',3);
set(gca,'Fontsize',14,'FontWeight','bold','LineWidth',2,'TickDir','out');
set(gcf,'color','w');
title({[elec_name ': BOLD FC vs SCP (<1Hz) FC']; ...
    ['r = ' num2str(elec_BOLD_SCP_corr) '; rho = ' num2str(rho_elec_BOLD_SCP_corr)]; ...
    ['distance-corrected r = ' num2str(elec_BOLD_SCP_partialcorr) '; rho = ' num2str(rho_elec_BOLD_SCP_partialcorr)]},'Fontsize',12);
xlabel('BOLD FC');
ylabel('SCP (0.1-1Hz) FC');
set(gcf,'PaperPositionMode','auto');
if BOLD_pipeline==1
print('-opengl','-r300','-dpng',strcat([pwd,filesep,elec_name '_BOLD_SCP_medium_GSR']));
elseif BOLD_pipeline==2
    print('-opengl','-r300','-dpng',strcat([pwd,filesep,elec_name '_BOLD_SCP_medium_AROMA']));
elseif BOLD_pipeline==3
print('-opengl','-r300','-dpng',strcat([pwd,filesep,elec_name '_BOLD_SCP_medium_NoGSR']));
elseif BOLD_pipeline==4
    print('-opengl','-r300','-dpng',strcat([pwd,filesep,elec_name '_BOLD_SCP_medium_aCompCor']));   
end
close;
 if use_elec==1
     corr_BOLD_SCP_allelecs(i,:)=elec_BOLD_SCP_corr;
 partialcorr_BOLD_SCP_allelecs(i,:)=elec_BOLD_SCP_partialcorr;
 p_BOLD_SCP_allelecs(i,:)=p_SCP_partial;
 else
       corr_BOLD_SCP_allelecs(i,:)=NaN;
  partialcorr_BOLD_SCP_allelecs(i,:)=NaN; 
   p_BOLD_SCP_allelecs(i,:)=NaN;
 end
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





