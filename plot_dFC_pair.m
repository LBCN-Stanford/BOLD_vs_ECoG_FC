% plot sliding-window dFC for a pair of regions - BOLD

Patient=input('Patient: ','s');
BOLD=input('BOLD (1) or iEEG (2): ','s');
if BOLD=='2'
    filter=input('filter range: unfiltered (1) 0.1-1 Hz (2) <0.1 Hz (3) ','s');
    if filter=='2'
   frequency=input('all 0.1-1Hz (0), HFB (2), alpha (3), beta1 (4), beta2 (5), Theta (6), Delta(7), Gamma (8)','s'); 
    end
    if filter=='1'
   frequency=input('all unfiltered (p), HFB (9), alpha (b), beta1 (c), beta2 (d), Theta (e), Delta(f), Gamma (g)','s');
    end
    if filter=='3'
       frequency=input('HFB (1)','s'); 
    end
else
    frequency=' ';
end
if BOLD=='1';
    BOLD_window_duration=input('Window duration (in sec) :','s'); BOLD_window_duration=str2num(BOLD_window_duration);
elseif BOLD=='2';
    iEEG_window_duration=input('Window duration (sec); aa for range of 10-100 sec durations :','s'); 
    if isempty(str2num(iEEG_window_duration))==0
    iEEG_window_duration=str2num(iEEG_window_duration);
    end
end
runs=input('run (e.g. 1): ','s');
rest=input('Rest(1) or Sleep(0)? ','s');
roi1=input('ROI 1 (e.g. AFS9): ','s');
roi2=input('ROI 2 (e.g. PIHS4): ','s');
seed=input('seed (ROI1) to all else (1)? ','s');
depth=input('depth (1) or subdural (0)? ','s');

load('cdcol.mat');

runnum=['run' runs];
fsDir=getFsurfSubDir();
getECoGSubDir; global globalECoGDir;
parcOut=elec2Parc_v2([Patient],'DK',0);
elecNames = parcOut(:,1);

if BOLD=='1'
    BOLD=['BOLD'];
else BOLD=['iEEG'];
end

%% BOLD Defaults
TR=2; % fMRI TR in seconds
BOLD_step=1; % step length (number of TRs)
if BOLD=='BOLD'
BOLD_window_size=BOLD_window_duration/TR; % number of TRs per window
end
%BOLD_window_duration=TR*BOLD_window_size;
BOLD_run='run1';

%% iEEG defaults
iEEG_sampling=1000;
iEEG_step=2000;
if BOLD=='iEEG'
    if isnumeric(iEEG_window_duration)==1
iEEG_window_size=iEEG_window_duration*iEEG_sampling;    
    else
        iEEG_window_sizes=[10 20 30 40 50 60 70 80 90 100]*iEEG_sampling;
        iEEG_window_size=30*iEEG_sampling; % example for plots
    end
end
%iEEG_window_duration=iEEG_window_size/iEEG_sampling;
iEEG_window_plot=[57]; % window to plot time series; set to zero to turn off
freq_window_plot=[1 2]; % 1=HFB, 2=Alpha
%depth='0';


%% Get hemisphere and file base name for iEEG
if BOLD=='iEEG'
    if rest=='1'
cd([globalECoGDir '/Rest/' Patient]);
elseif rest=='0'
    cd([globalECoGDir '/Sleep/' Patient]);
end
    
%if depth=='0'
%hemi=importdata(['hemi.txt']); 
%hemi=char(hemi);
%end
    if rest=='1'
cd([globalECoGDir '/Rest/' Patient '/Run' runs]);
elseif rest=='0'
    cd([globalECoGDir '/Sleep/' Patient '/Run' runs]);
    end

Mfile=dir('btf_aMpfff*');
if ~isempty(Mfile)
Mfile=Mfile(2,1).name;
else
    Mfile=dir('btf_aMfff*');
    Mfile=Mfile(2,1).name;
end
%Load channel name-number mapping
cd([fsDir '/' Patient '/elec_recon']);
[channumbers_iEEG,chanlabels]=xlsread('channelmap.xls');
end

%% For iEEG, load channel names (in freesurfer/elec recon order)
if BOLD=='iEEG'
    cd([fsDir '/' Patient '/elec_recon']);
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

end

%% Load iEEG data
if BOLD=='iEEG'
        if rest=='1'
cd([globalECoGDir '/Rest/' Patient '/Run' runs]);
elseif rest=='0'
    cd([globalECoGDir '/Sleep/' Patient '/Run' runs]);
        end

if ~isempty(dir('pHFB*'))   
    if frequency=='1' || frequency=='0'
iEEG_data=spm_eeg_load(['slowpHFB' Mfile]); freq=['HFB (<0.1 Hz)'];
if frequency=='0'
    HFB_slow=iEEG_data; iEEG_data=[];
end
    end
    if frequency=='2' || frequency=='0'
iEEG_data=spm_eeg_load(['bptf_mediumpHFB' Mfile]); freq=['HFB (0.1-1 Hz)'];
if frequency=='0'
    HFB_medium=iEEG_data; iEEG_data=[];
end
    end
    if frequency=='3' || frequency=='0'
iEEG_data=spm_eeg_load(['bptf_mediumpAlpha' Mfile]); freq=['Alpha (0.1-1 Hz)'];
if frequency=='0'
    Alpha_medium=iEEG_data; iEEG_data=[];
end
    end
    if frequency=='4' || frequency=='0'
iEEG_data=spm_eeg_load(['bptf_mediumpBeta1' Mfile]); freq=['Beta1 (0.1-1 Hz)'];
if frequency=='0'
    Beta1_medium=iEEG_data; iEEG_data=[];
end
    end
    if frequency=='5' || frequency=='0'
iEEG_data=spm_eeg_load(['bptf_mediumpBeta2' Mfile]); freq=['Beta2 (0.1-1 Hz)'];
if frequency=='0'
    Beta2_medium=iEEG_data; iEEG_data=[];
end
    end
    if frequency=='6' || frequency=='0'
iEEG_data=spm_eeg_load(['bptf_mediumpTheta' Mfile]); freq=['Theta (0.1-1 Hz)'];
if frequency=='0'
    Theta_medium=iEEG_data; iEEG_data=[];
end
    end
    if frequency=='7' || frequency=='0'
iEEG_data=spm_eeg_load(['bptf_mediumpDelta' Mfile]); freq=['Delta (0.1-1 Hz)'];
if frequency=='0'
    Delta_medium=iEEG_data; iEEG_data=[];
end
    end
    if frequency=='8' || frequency=='0'
iEEG_data=spm_eeg_load(['bptf_mediumpGamma' Mfile]); freq=['Gamma (0.1-1 Hz)'];
if frequency=='0'
    Gamma_medium=iEEG_data; iEEG_data=[];
end
    end
    
    if frequency=='9' || frequency=='p'
iEEG_data=spm_eeg_load(['pHFB' Mfile]); freq=['HFB'];
if frequency=='p'
    HFB=iEEG_data; iEEG_data=[];
end
    end    
    
    if frequency=='b' || frequency=='p'
       iEEG_data=spm_eeg_load(['pAlpha' Mfile]); freq=['Alpha'];
       if frequency=='p'
    Alpha=iEEG_data; iEEG_data=[];
end
    end
    
    if frequency=='c' || frequency=='p'
       iEEG_data=spm_eeg_load(['pBeta1' Mfile]); freq=['Beta1'];
       if frequency=='p'
    Beta1=iEEG_data; iEEG_data=[];
end
    end
        if frequency=='d' || frequency=='p'
       iEEG_data=spm_eeg_load(['pBeta2' Mfile]); freq=['Beta2'];
              if frequency=='p'
    Beta2=iEEG_data; iEEG_data=[];
end
        end
     if frequency=='e' || frequency=='p'
       iEEG_data=spm_eeg_load(['pTheta' Mfile]); freq=['Theta'];
              if frequency=='p'
    Theta=iEEG_data; iEEG_data=[];
end
    end
         if frequency=='f' || frequency=='p'
       iEEG_data=spm_eeg_load(['pDelta' Mfile]); freq=['Delta'];
                     if frequency=='p'
    Delta=iEEG_data; iEEG_data=[];
end
         end
             if frequency=='g' || frequency=='p'
       iEEG_data=spm_eeg_load(['pGamma' Mfile]); freq=['Gamma'];
                            if frequency=='p'
    Gamma=iEEG_data; iEEG_data=[];
end
         end
else
if frequency=='1' || frequency=='0'
iEEG_data=spm_eeg_load(['slowHFB' Mfile]);
if frequency=='0'
    HFB_slow=iEEG_data; iEEG_data=[];
end
end
if frequency=='2' || frequency=='0'
iEEG_data=spm_eeg_load(['bptf_mediumHFB' Mfile]); freq=['HFB (<0.1 Hz)'];
if frequency=='0'
    HFB_medium=iEEG_data; iEEG_data=[];
end
end
if frequency=='3' || frequency=='0'
iEEG_data=spm_eeg_load(['bptf_mediumAlpha' Mfile]); freq=['Alpha (0.1-1 Hz)'];
if frequency=='0'
    Alpha_medium=iEEG_data; iEEG_data=[];
end
end
if frequency=='4' || frequency=='0'
iEEG_data=spm_eeg_load(['bptf_mediumBeta1' Mfile]); freq=['Beta1 (0.1-1 Hz)'];
if frequency=='0'
    Beta1_medium=iEEG_data; iEEG_data=[];
end
end
if frequency=='5' || frequency=='0'
iEEG_data=spm_eeg_load(['bptf_mediumBeta2' Mfile]); freq=['Beta2 (0.1-1 Hz)'];
if frequency=='0'
    Beta2_medium=iEEG_data; iEEG_data=[];
end
end
if frequency=='6' || frequency=='0'
 iEEG_data=spm_eeg_load(['bptf_mediumTheta' Mfile]);   freq=['Theta (0.1-1 Hz)'];
 if frequency=='0'
    Theta_medium=iEEG_data; iEEG_data=[];
end
end
if frequency=='7' || frequency=='0'
 iEEG_data=spm_eeg_load(['bptf_mediumDelta' Mfile]);  freq=['Delta (0.1-1 Hz)']; 
 if frequency=='0'
    Delta_medium=iEEG_data; iEEG_data=[];
end
end
if frequency=='8' || frequency=='0'
   iEEG_data=spm_eeg_load(['bptf_mediumGamma' Mfile]);  freq=['Gamma (0.1-1 Hz)'];
   if frequency=='0'
    Gamma_medium=iEEG_data; iEEG_data=[];
end
end
if frequency=='9' || frequency=='p'
    iEEG_data=spm_eeg_load(['HFB' Mfile]); freq=['HFB'];
    if frequency=='p'
        HFB=iEEG_data; iEEG_data=[];
    end
end

 if frequency=='b' || frequency=='p'
    iEEG_data=spm_eeg_load(['Alpha' Mfile]); freq=['Alpha'];
    if frequency=='p'
        Alpha=iEEG_data; iEEG_data=[];
    end
 end  

if frequency=='c' || frequency=='p'
    iEEG_data=spm_eeg_load(['Beta1' Mfile]); freq=['Beta1'];
    if frequency=='p'
        Beta1=iEEG_data; iEEG_data=[];
    end
end 
 
if frequency=='d' || frequency=='p'
    iEEG_data=spm_eeg_load(['Beta2' Mfile]); freq=['Beta2'];
    if frequency=='p'
        Beta2=iEEG_data; iEEG_data=[];
    end
end 

if frequency=='e' || frequency=='p'
    iEEG_data=spm_eeg_load(['Theta' Mfile]); freq=['Theta'];
    if frequency=='p'
        Theta=iEEG_data; iEEG_data=[];
    end
end 

if frequency=='f' || frequency=='p'
    iEEG_data=spm_eeg_load(['Delta' Mfile]); freq=['Delta'];
    if frequency=='p'
        Delta=iEEG_data; iEEG_data=[];
    end
end 

if frequency=='g' || frequency=='p'
    iEEG_data=spm_eeg_load(['Gamma' Mfile]); freq=['Gamma'];
    if frequency=='p'
        Gamma=iEEG_data; iEEG_data=[];
    end
end 
end


if frequency ~='0' && frequency~='p'
for iEEG_chan=1:size(iEEG_data,1)
    iEEG_ts(:,iEEG_chan)=iEEG_data(iEEG_chan,:)';      
end
end

if frequency=='0'
    for iEEG_chan=1:size(HFB_medium,1)
    HFB_medium_ts(:,iEEG_chan)=HFB_medium(iEEG_chan,:)';      
    end
     for iEEG_chan=1:size(HFB_medium,1)
    Alpha_medium_ts(:,iEEG_chan)=Alpha_medium(iEEG_chan,:)';      
     end   
    for iEEG_chan=1:size(HFB_medium,1)
    Beta1_medium_ts(:,iEEG_chan)=Beta1_medium(iEEG_chan,:)';      
end
      for iEEG_chan=1:size(HFB_medium,1)
    Beta2_medium_ts(:,iEEG_chan)=Beta2_medium(iEEG_chan,:)';      
      end
    for iEEG_chan=1:size(HFB_medium,1)
    Theta_medium_ts(:,iEEG_chan)=Theta_medium(iEEG_chan,:)';      
end
       for iEEG_chan=1:size(HFB_medium,1)
    Delta_medium_ts(:,iEEG_chan)=Delta_medium(iEEG_chan,:)';      
       end
    for iEEG_chan=1:size(HFB_medium,1)
    Gamma_medium_ts(:,iEEG_chan)=Gamma_medium(iEEG_chan,:)';      
end
end

if frequency =='p'
     for iEEG_chan=1:size(HFB,1)
    HFB_ts(:,iEEG_chan)=HFB(iEEG_chan,:)';      
    end
     for iEEG_chan=1:size(HFB,1)
    Alpha_ts(:,iEEG_chan)=Alpha(iEEG_chan,:)';      
     end   
    for iEEG_chan=1:size(HFB,1)
    Beta1_ts(:,iEEG_chan)=Beta1(iEEG_chan,:)';      
end
      for iEEG_chan=1:size(HFB,1)
    Beta2_ts(:,iEEG_chan)=Beta2(iEEG_chan,:)';      
      end
    for iEEG_chan=1:size(HFB,1)
    Theta_ts(:,iEEG_chan)=Theta(iEEG_chan,:)';      
end
       for iEEG_chan=1:size(HFB,1)
    Delta_ts(:,iEEG_chan)=Delta(iEEG_chan,:)';      
       end
    for iEEG_chan=1:size(HFB,1)
    Gamma_ts(:,iEEG_chan)=Gamma(iEEG_chan,:)';      
end       
end
end

%% Convert ROI names to numbers (iElvis space)
roi1_num=strmatch(roi1,parcOut(:,1),'exact');
roi2_num=strmatch(roi2,parcOut(:,1),'exact');

%% Convert iEEG numbers to names
if BOLD=='iEEG'
% create iEEG to iElvis chanlabel transformation vector
for i=1:length(chanlabels)
    iEEG_to_iElvis_chanlabel(i,:)=strmatch(chanlabels(i),fs_chanlabels(:,1),'exact');    
end

    for i=1:length(chanlabels)
iElvis_to_iEEG_chanlabel(i,:)=channumbers_iEEG(strmatch(fs_chanlabels(i,1),chanlabels,'exact'));
    end

end

%% Transform time series from iEEG to iElvis order
if BOLD=='iEEG'
    if frequency~='0' && frequency~='p'
iEEG_ts_iElvis=NaN(size(iEEG_ts,1),length(chanlabels));
for i=1:length(chanlabels);
    curr_iEEG_chan=channumbers_iEEG(i);
    new_ind=iEEG_to_iElvis_chanlabel(i);
    iEEG_ts_iElvis(:,new_ind)=iEEG_ts(:,curr_iEEG_chan);
end

    elseif frequency=='0'
HFB_medium_ts_iElvis=NaN(size(HFB_medium_ts,1),length(chanlabels));  
Alpha_medium_ts_iElvis=NaN(size(Alpha_medium_ts,1),length(chanlabels));
Beta1_medium_ts_iElvis=NaN(size(Beta1_medium_ts,1),length(chanlabels));
Beta2_medium_ts_iElvis=NaN(size(Beta2_medium_ts,1),length(chanlabels));
Theta_medium_ts_iElvis=NaN(size(Theta_medium_ts,1),length(chanlabels));
Delta_medium_ts_iElvis=NaN(size(Delta_medium_ts,1),length(chanlabels));
Gamma_medium_ts_iElvis=NaN(size(Gamma_medium_ts,1),length(chanlabels));

for i=1:length(chanlabels);
    curr_iEEG_chan=channumbers_iEEG(i);
    new_ind=iEEG_to_iElvis_chanlabel(i);
    HFB_medium_ts_iElvis(:,new_ind)=HFB_medium_ts(:,curr_iEEG_chan);
    Alpha_medium_ts_iElvis(:,new_ind)=Alpha_medium_ts(:,curr_iEEG_chan);
    Beta1_medium_ts_iElvis(:,new_ind)=Beta1_medium_ts(:,curr_iEEG_chan);
    Beta2_medium_ts_iElvis(:,new_ind)=Beta2_medium_ts(:,curr_iEEG_chan);
    Theta_medium_ts_iElvis(:,new_ind)=Theta_medium_ts(:,curr_iEEG_chan);
    Delta_medium_ts_iElvis(:,new_ind)=Delta_medium_ts(:,curr_iEEG_chan);
    Gamma_medium_ts_iElvis(:,new_ind)=Gamma_medium_ts(:,curr_iEEG_chan);
end

    elseif frequency=='p'
HFB_ts_iElvis=NaN(size(HFB_ts,1),length(chanlabels));  
Alpha_ts_iElvis=NaN(size(Alpha_ts,1),length(chanlabels));
Beta1_ts_iElvis=NaN(size(Beta1_ts,1),length(chanlabels));
Beta2_ts_iElvis=NaN(size(Beta2_ts,1),length(chanlabels));
Theta_ts_iElvis=NaN(size(Theta_ts,1),length(chanlabels));
Delta_ts_iElvis=NaN(size(Delta_ts,1),length(chanlabels));
Gamma_ts_iElvis=NaN(size(Gamma_ts,1),length(chanlabels));

for i=1:length(chanlabels);
    curr_iEEG_chan=channumbers_iEEG(i);
    new_ind=iEEG_to_iElvis_chanlabel(i);
    HFB_ts_iElvis(:,new_ind)=HFB_ts(:,curr_iEEG_chan);
    Alpha_ts_iElvis(:,new_ind)=Alpha_ts(:,curr_iEEG_chan);
    Beta1_ts_iElvis(:,new_ind)=Beta1_ts(:,curr_iEEG_chan);
    Beta2_ts_iElvis(:,new_ind)=Beta2_ts(:,curr_iEEG_chan);
    Theta_ts_iElvis(:,new_ind)=Theta_ts(:,curr_iEEG_chan);
    Delta_ts_iElvis(:,new_ind)=Delta_ts(:,curr_iEEG_chan);
    Gamma_ts_iElvis(:,new_ind)=Gamma_ts(:,curr_iEEG_chan);
end
    end  
end

%% Load time series for ROI pair
if BOLD=='BOLD'
cd([fsDir '/' Patient '/elec_recon/electrode_spheres']);

if depth=='1'
    roi1_ts=load(['elec' num2str(roi1_num) runnum '_ts_FSL.txt']);
roi2_ts=load(['elec' num2str(roi2_num) runnum '_ts_FSL.txt']);
else
roi1_ts=load(['elec' num2str(roi1_num) runnum '_ts_GSR.txt']);
roi2_ts=load(['elec' num2str(roi2_num) runnum '_ts_GSR.txt']);
end
% load all BOLD ROI time series
if seed=='1'  
       for i=1:length(elecNames)
    elec_num=num2str(i);
    BOLD_ts(:,i)=load(['elec' elec_num BOLD_run '_ts_GSR.txt']);
   end  
end

end

if BOLD=='iEEG'
    roi1_iEEG_num=iElvis_to_iEEG_chanlabel(roi1_num);
    roi2_iEEG_num=iElvis_to_iEEG_chanlabel(roi2_num);

    if frequency ~='0' && frequency ~='p'
    roi1_ts=iEEG_ts_iElvis(:,roi1_num);   
    roi2_ts=iEEG_ts_iElvis(:,roi2_num);   
     elseif frequency=='0'
         roi1_HFB_medium_ts=HFB_medium_ts(:,roi1_iEEG_num);
         roi1_Alpha_medium_ts=Alpha_medium_ts(:,roi1_iEEG_num);
         roi1_Beta1_medium_ts=Beta1_medium_ts(:,roi1_iEEG_num);
         roi1_Beta2_medium_ts=Beta2_medium_ts(:,roi1_iEEG_num);
         roi1_Theta_medium_ts=Theta_medium_ts(:,roi1_iEEG_num);
         roi1_Delta_medium_ts=Delta_medium_ts(:,roi1_iEEG_num);
         roi1_Gamma_medium_ts=Gamma_medium_ts(:,roi1_iEEG_num);
         roi2_HFB_medium_ts=HFB_medium_ts(:,roi2_iEEG_num);
         roi2_Alpha_medium_ts=Alpha_medium_ts(:,roi2_iEEG_num);
         roi2_Beta1_medium_ts=Beta1_medium_ts(:,roi2_iEEG_num);
         roi2_Beta2_medium_ts=Beta2_medium_ts(:,roi2_iEEG_num);
         roi2_Theta_medium_ts=Theta_medium_ts(:,roi2_iEEG_num);
         roi2_Delta_medium_ts=Delta_medium_ts(:,roi2_iEEG_num);
         roi2_Gamma_medium_ts=Gamma_medium_ts(:,roi2_iEEG_num);
        
    elseif frequency=='p'
            roi1_HFB_ts=HFB_ts(:,roi1_iEEG_num);
         roi1_Alpha_ts=Alpha_ts(:,roi1_iEEG_num);
         roi1_Beta1_ts=Beta1_ts(:,roi1_iEEG_num);
         roi1_Beta2_ts=Beta2_ts(:,roi1_iEEG_num);
         roi1_Theta_ts=Theta_ts(:,roi1_iEEG_num);
         roi1_Delta_ts=Delta_ts(:,roi1_iEEG_num);
         roi1_Gamma_ts=Gamma_ts(:,roi1_iEEG_num);
         roi2_HFB_ts=HFB_ts(:,roi2_iEEG_num);
         roi2_Alpha_ts=Alpha_ts(:,roi2_iEEG_num);
         roi2_Beta1_ts=Beta1_ts(:,roi2_iEEG_num);
         roi2_Beta2_ts=Beta2_ts(:,roi2_iEEG_num);
         roi2_Theta_ts=Theta_ts(:,roi2_iEEG_num);
         roi2_Delta_ts=Delta_ts(:,roi2_iEEG_num);
         roi2_Gamma_ts=Gamma_ts(:,roi2_iEEG_num);          
end
end

%% Static FC
if BOLD=='BOLD'
static_fc=corr(roi1_ts,roi2_ts);
end
if BOLD=='iEEG'
    if frequency~='0' && frequency~='p'
   static_fc=corr(roi1_ts,roi2_ts); 
    end
end

%% Sliding windows for seed to all regions
if seed=='1'
    cd([globalECoGDir '/Rest/' Patient '/Run' runs]);
    if BOLD=='iEEG';
seed_allwindows_fisher=[];
  for i=1:iEEG_step:length(roi1_ts)-iEEG_window_size;
    a=i+iEEG_window_size;
    ALL_window_ts=iEEG_ts_iElvis(i:a,:);
    ALL_window_corr=corrcoef(ALL_window_ts);
    ALL_window_fisher=fisherz(ALL_window_corr);
    seed_window_fisher=ALL_window_fisher(:,roi1_num);
    seed_allwindows_fisher=[seed_allwindows_fisher seed_window_fisher];
  end  
  if iEEG_step==2000
   windowsize=num2str(iEEG_window_size/iEEG_sampling);
      save([roi1 '_' windowsize 'sec_windows_iEEG'],'seed_allwindows_fisher');
  end
    end
  if BOLD=='BOLD'
seed_allwindows_fisher=[];
  for i=1:BOLD_step:length(roi1_ts)-BOLD_window_size;
    a=i+BOLD_window_size;
    ALL_window_ts=BOLD_ts(i:a,:);
    ALL_window_corr=corrcoef(ALL_window_ts);
    ALL_window_fisher=fisherz(ALL_window_corr);
    seed_window_fisher=ALL_window_fisher(:,roi1_num);
    seed_allwindows_fisher=[seed_allwindows_fisher seed_window_fisher];
  end  
  if BOLD_step==1
      windowsize=num2str(BOLD_window_duration);
      save([roi1 '_' windowsize 'sec_windows_BOLD'],'seed_allwindows_fisher');
  end    
  end    
end

%% Sliding windows for ROI pair
if BOLD=='BOLD'
for i=1:BOLD_step:length(roi1_ts)-BOLD_window_size;
    a=i+BOLD_window_size;
    roi1_window_ts=roi1_ts(i:a);
    roi2_window_ts=roi2_ts(i:a);
    window_corr=corr(roi1_window_ts,roi2_window_ts);
    window_fisher=fisherz(window_corr);
    all_windows_corr(i,:)=window_corr;
    all_windows_fisher(i,:)=window_fisher;
end
end

if BOLD=='iEEG'
   % loop for multiple window durations: HFB
    if isnumeric(iEEG_window_duration)==0 
   
        all_windows_corr=zeros((ceil((length(roi1_HFB_medium_ts)-iEEG_window_sizes(1))/iEEG_step)),length(iEEG_window_sizes));
        all_windows_fisher=zeros((ceil((length(roi1_HFB_medium_ts)-iEEG_window_sizes(1))/iEEG_step)),length(iEEG_window_sizes));
        
        for j=1:length(iEEG_window_sizes);
        
          for i=1:iEEG_step:length(roi1_HFB_medium_ts)-iEEG_window_sizes(j);
    a=i+iEEG_window_sizes(j);
    roi1_HFB_window_ts=roi1_HFB_medium_ts(i:a);
    roi2_HFB_window_ts=roi2_HFB_medium_ts(i:a);
%             if i==1+iEEG_step*iEEG_window_plot-iEEG_step;
%         roi1_window_ts_plot=roi1_window_ts;
%         roi2_window_ts_plot=roi2_window_ts;
%             end
    window_corr=corr(roi1_HFB_window_ts,roi2_HFB_window_ts);
    window_fisher=fisherz(window_corr);
    all_windows_corr(i,j)=window_corr;   
   all_windows_fisher(i,j)=window_fisher;
   
  end            
        end
    
  
    % for multiple windows, get HFB correlation time courses
    window10_HFB_fisher=all_windows_fisher(:,1);
    window10_HFB_fisher(find(window10_HFB_fisher==0))=[];
    window20_HFB_fisher=all_windows_fisher(:,2);
    window20_HFB_fisher(find(window20_HFB_fisher==0))=[];
    window30_HFB_fisher=all_windows_fisher(:,3);
    window30_HFB_fisher(find(window30_HFB_fisher==0))=[];
    window40_HFB_fisher=all_windows_fisher(:,4);
    window40_HFB_fisher(find(window40_HFB_fisher==0))=[];
    window50_HFB_fisher=all_windows_fisher(:,5);
    window50_HFB_fisher(find(window50_HFB_fisher==0))=[];
    window60_HFB_fisher=all_windows_fisher(:,6);
    window60_HFB_fisher(find(window60_HFB_fisher==0))=[];
    window70_HFB_fisher=all_windows_fisher(:,7);
    window70_HFB_fisher(find(window70_HFB_fisher==0))=[];
    window80_HFB_fisher=all_windows_fisher(:,8);
    window80_HFB_fisher(find(window80_HFB_fisher==0))=[];
    window90_HFB_fisher=all_windows_fisher(:,9);
    window90_HFB_fisher(find(window90_HFB_fisher==0))=[];
    window100_HFB_fisher=all_windows_fisher(:,10);
    window100_HFB_fisher(find(window100_HFB_fisher==0))=[];
    
     % loop for multiple window durations: Alpha
     
     all_windows_corr=zeros((ceil((length(roi1_Alpha_medium_ts)-iEEG_window_sizes(1))/iEEG_step)),length(iEEG_window_sizes));
        all_windows_fisher=zeros((ceil((length(roi1_Alpha_medium_ts)-iEEG_window_sizes(1))/iEEG_step)),length(iEEG_window_sizes));
        
        for j=1:length(iEEG_window_sizes);
        
          for i=1:iEEG_step:length(roi1_Alpha_medium_ts)-iEEG_window_sizes(j);
    a=i+iEEG_window_sizes(j);
    roi1_Alpha_window_ts=roi1_Alpha_medium_ts(i:a);
    roi2_Alpha_window_ts=roi2_Alpha_medium_ts(i:a);
%             if i==1+iEEG_step*iEEG_window_plot-iEEG_step;
%         roi1_window_ts_plot=roi1_window_ts;
%         roi2_window_ts_plot=roi2_window_ts;
%             end
    window_corr=corr(roi1_Alpha_window_ts,roi2_Alpha_window_ts);
    window_fisher=fisherz(window_corr);
    all_windows_corr(i,j)=window_corr;   
   all_windows_fisher(i,j)=window_fisher;
   
  end            
        end
    
  
    % for multiple windows, get Alpha correlation time courses
    window10_Alpha_fisher=all_windows_fisher(:,1);
    window10_Alpha_fisher(find(window10_Alpha_fisher==0))=[];
    window20_Alpha_fisher=all_windows_fisher(:,2);
    window20_Alpha_fisher(find(window20_Alpha_fisher==0))=[];
    window30_Alpha_fisher=all_windows_fisher(:,3);
    window30_Alpha_fisher(find(window30_Alpha_fisher==0))=[];
    window40_Alpha_fisher=all_windows_fisher(:,4);
    window40_Alpha_fisher(find(window40_Alpha_fisher==0))=[];
    window50_Alpha_fisher=all_windows_fisher(:,5);
    window50_Alpha_fisher(find(window50_Alpha_fisher==0))=[];
    window60_Alpha_fisher=all_windows_fisher(:,6);
    window60_Alpha_fisher(find(window60_Alpha_fisher==0))=[];
    window70_Alpha_fisher=all_windows_fisher(:,7);
    window70_Alpha_fisher(find(window70_Alpha_fisher==0))=[];
    window80_Alpha_fisher=all_windows_fisher(:,8);
    window80_Alpha_fisher(find(window80_Alpha_fisher==0))=[];
    window90_Alpha_fisher=all_windows_fisher(:,9);
    window90_Alpha_fisher(find(window90_Alpha_fisher==0))=[];
    window100_Alpha_fisher=all_windows_fisher(:,10);
    window100_Alpha_fisher(find(window100_Alpha_fisher==0))=[];
    
    
    % correlate Alpha vs HFB
    
    SWC_HFB_vs_Alpha_10=corr(window10_HFB_fisher,window10_Alpha_fisher);
    SWC_HFB_vs_Alpha_20=corr(window20_HFB_fisher,window20_Alpha_fisher);
    SWC_HFB_vs_Alpha_30=corr(window30_HFB_fisher,window30_Alpha_fisher);
    SWC_HFB_vs_Alpha_40=corr(window40_HFB_fisher,window40_Alpha_fisher);
    SWC_HFB_vs_Alpha_50=corr(window50_HFB_fisher,window50_Alpha_fisher);
    SWC_HFB_vs_Alpha_60=corr(window60_HFB_fisher,window60_Alpha_fisher);
    SWC_HFB_vs_Alpha_70=corr(window70_HFB_fisher,window70_Alpha_fisher);
    SWC_HFB_vs_Alpha_80=corr(window80_HFB_fisher,window80_Alpha_fisher);
    SWC_HFB_vs_Alpha_90=corr(window90_HFB_fisher,window90_Alpha_fisher);
    SWC_HFB_vs_Alpha_100=corr(window100_HFB_fisher,window100_Alpha_fisher);
    
    SWC_HFB_vs_Alpha_all=[SWC_HFB_vs_Alpha_10; SWC_HFB_vs_Alpha_20; SWC_HFB_vs_Alpha_30; SWC_HFB_vs_Alpha_40; SWC_HFB_vs_Alpha_50; ...
        SWC_HFB_vs_Alpha_60; SWC_HFB_vs_Alpha_70; SWC_HFB_vs_Alpha_80; SWC_HFB_vs_Alpha_90; SWC_HFB_vs_Alpha_100];
     
    end
    
    % single window duration
    if frequency~='0' && frequency ~='p'
    all_windows_corr=[]; all_windows_fisher=[];
  %for i=1:iEEG_step:floor(length(roi1_ts)/iEEG_step);
  for i=1:iEEG_step:length(roi1_ts)-iEEG_window_size;
    a=i+iEEG_window_size;
    roi1_window_ts=roi1_ts(i:a);
    roi2_window_ts=roi2_ts(i:a);
            if i==1+iEEG_step*iEEG_window_plot-iEEG_step;
        roi1_window_ts_plot=roi1_window_ts;
        roi2_window_ts_plot=roi2_window_ts;
            end
    window_corr=corr(roi1_window_ts,roi2_window_ts);
    window_fisher=fisherz(window_corr);
    all_windows_corr=[all_windows_corr window_corr];   
   all_windows_fisher=[all_windows_fisher window_fisher];
  end  
all_windows_corr=all_windows_corr';
all_windows_fisher=all_windows_fisher';
    end
if frequency=='0'
    
    % normalize time courses
            roi1_HFB_medium_ts_norm=(roi1_HFB_medium_ts-mean(roi1_HFB_medium_ts))/std(roi1_HFB_medium_ts);
        roi1_Alpha_medium_ts_norm=(roi1_Alpha_medium_ts-mean(roi1_Alpha_medium_ts))/std(roi1_Alpha_medium_ts);
        roi1_Beta1_medium_ts_norm=(roi1_Beta1_medium_ts-mean(roi1_Beta1_medium_ts))/std(roi1_Beta1_medium_ts);
        roi1_Beta2_medium_ts_norm=(roi1_Beta2_medium_ts-mean(roi1_Beta2_medium_ts))/std(roi1_Beta2_medium_ts);
        roi1_Theta_medium_ts_norm=(roi1_Theta_medium_ts-mean(roi1_Theta_medium_ts))/std(roi1_Theta_medium_ts);
        roi1_Delta_medium_ts_norm=(roi1_Delta_medium_ts-mean(roi1_Delta_medium_ts))/std(roi1_Delta_medium_ts);
        roi1_Gamma_medium_ts_norm=(roi1_Gamma_medium_ts-mean(roi1_Gamma_medium_ts))/std(roi1_Gamma_medium_ts);
        roi2_HFB_medium_ts_norm=(roi2_HFB_medium_ts-mean(roi2_HFB_medium_ts))/std(roi2_HFB_medium_ts);
        roi2_Alpha_medium_ts_norm=(roi2_Alpha_medium_ts-mean(roi2_Alpha_medium_ts))/std(roi2_Alpha_medium_ts);
        roi2_Beta1_medium_ts_norm=(roi2_Beta1_medium_ts-mean(roi2_Beta1_medium_ts))/std(roi2_Beta1_medium_ts);
        roi2_Beta2_medium_ts_norm=(roi2_Beta2_medium_ts-mean(roi2_Beta2_medium_ts))/std(roi2_Beta2_medium_ts);
        roi2_Theta_medium_ts_norm=(roi2_Theta_medium_ts-mean(roi2_Theta_medium_ts))/std(roi2_Theta_medium_ts);
        roi2_Delta_medium_ts_norm=(roi2_Delta_medium_ts-mean(roi2_Delta_medium_ts))/std(roi2_Delta_medium_ts);
        roi2_Gamma_medium_ts_norm=(roi2_Gamma_medium_ts-mean(roi2_Gamma_medium_ts))/std(roi2_Gamma_medium_ts);
    
        % MTD: HFB vs Alpha
        if isnumeric(iEEG_window_duration)==1
    Alpha_mat=[roi1_Alpha_medium_ts_norm roi2_Alpha_medium_ts_norm];
    HFB_mat=[roi1_HFB_medium_ts_norm roi2_HFB_medium_ts_norm];
    
    mtd_alpha=coupling(Alpha_mat,iEEG_window_duration*iEEG_sampling);
    mtd_alpha=squeeze(mtd_alpha(1,2,:));
    
    mtd_HFB=coupling(HFB_mat,iEEG_window_duration*iEEG_sampling);
    mtd_HFB=squeeze(mtd_HFB(1,2,:));
        end
        
    % Sliding window correlations for each frequency
     all_windows_HFB_medium_corr=[]; all_windows_HFB_medium_fisher=[];
     roi1_HFB_alpha_fisher_allwindows=[]; roi2_HFB_alpha_fisher_allwindows=[];
  for i=1:iEEG_step:length(roi1_HFB_medium_ts)-iEEG_window_size;
    a=i+iEEG_window_size;
    roi1_window_HFB_ts=roi1_HFB_medium_ts(i:a); roi1_window_alpha_ts=roi1_Alpha_medium_ts(i:a);
    roi2_window_HFB_ts=roi2_HFB_medium_ts(i:a); roi2_window_alpha_ts=roi2_Alpha_medium_ts(i:a);
    
        if i==1+iEEG_step*iEEG_window_plot-iEEG_step; % for plotting specific window
        HFB_roi1_window_ts_plot=roi1_window_HFB_ts;
        HFB_roi2_window_ts_plot=roi2_window_HFB_ts;
        end
    
        
    window_corr=corr(roi1_window_HFB_ts,roi2_window_HFB_ts);
    window_fisher=fisherz(window_corr);
    all_windows_HFB_medium_corr=[all_windows_HFB_medium_corr window_corr];   
   all_windows_HFB_medium_fisher=[all_windows_HFB_medium_fisher window_fisher];
   
   roi1_HFB_alpha_window_corr=corr(roi1_window_HFB_ts,roi1_window_alpha_ts);
   roi1_HFB_alpha_fisher_allwindows=[roi1_HFB_alpha_fisher_allwindows fisherz(roi1_HFB_alpha_window_corr)];
   
   roi2_HFB_alpha_window_corr=corr(roi2_window_HFB_ts,roi2_window_alpha_ts);
   roi2_HFB_alpha_fisher_allwindows=[roi2_HFB_alpha_fisher_allwindows fisherz(roi2_HFB_alpha_window_corr)];
  end  
all_windows_HFB_medium_corr=all_windows_HFB_medium_corr';
all_windows_HFB_medium_fisher=all_windows_HFB_medium_fisher';

       all_windows_Alpha_medium_corr=[]; all_windows_Alpha_medium_fisher=[];
  for i=1:iEEG_step:length(roi1_Alpha_medium_ts)-iEEG_window_size;
    a=i+iEEG_window_size;
    roi1_window_ts=roi1_Alpha_medium_ts(i:a);
    roi2_window_ts=roi2_Alpha_medium_ts(i:a);
            if i==1+iEEG_step*iEEG_window_plot-iEEG_step;
        Alpha_roi1_window_ts_plot=roi1_window_ts;
        Alpha_roi2_window_ts_plot=roi2_window_ts;
    end
    window_corr=corr(roi1_window_ts,roi2_window_ts);
    window_fisher=fisherz(window_corr);
    all_windows_Alpha_medium_corr=[all_windows_Alpha_medium_corr window_corr];   
   all_windows_Alpha_medium_fisher=[all_windows_Alpha_medium_fisher window_fisher];
  end  
all_windows_Alpha_medium_corr=all_windows_Alpha_medium_corr';
all_windows_Alpha_medium_fisher=all_windows_Alpha_medium_fisher';

       all_windows_Beta1_medium_corr=[]; all_windows_Beta1_medium_fisher=[];
  for i=1:iEEG_step:length(roi1_Beta1_medium_ts)-iEEG_window_size;
    a=i+iEEG_window_size;
    roi1_window_ts=roi1_Beta1_medium_ts(i:a);
    roi2_window_ts=roi2_Beta1_medium_ts(i:a);
            if i==1+iEEG_step*iEEG_window_plot-iEEG_step;
        Beta1_roi1_window_ts_plot=roi1_window_ts;
        Beta1_roi2_window_ts_plot=roi2_window_ts;
    end
    window_corr=corr(roi1_window_ts,roi2_window_ts);
    window_fisher=fisherz(window_corr);
    all_windows_Beta1_medium_corr=[all_windows_Beta1_medium_corr window_corr];   
   all_windows_Beta1_medium_fisher=[all_windows_Beta1_medium_fisher window_fisher];
  end  
all_windows_Beta1_medium_corr=all_windows_Beta1_medium_corr';
all_windows_Beta1_medium_fisher=all_windows_Beta1_medium_fisher';

       all_windows_Beta2_medium_corr=[]; all_windows_Beta2_medium_fisher=[];
  for i=1:iEEG_step:length(roi1_Beta2_medium_ts)-iEEG_window_size;
    a=i+iEEG_window_size;
    roi1_window_ts=roi1_Beta2_medium_ts(i:a);
    roi2_window_ts=roi2_Beta2_medium_ts(i:a);
            if i==1+iEEG_step*iEEG_window_plot-iEEG_step;
        Beta2_roi1_window_ts_plot=roi1_window_ts;
        Beta2_roi2_window_ts_plot=roi2_window_ts;
    end
    window_corr=corr(roi1_window_ts,roi2_window_ts);
    window_fisher=fisherz(window_corr);
    all_windows_Beta2_medium_corr=[all_windows_Beta2_medium_corr window_corr];   
   all_windows_Beta2_medium_fisher=[all_windows_Beta2_medium_fisher window_fisher];
  end  
all_windows_Beta2_medium_corr=all_windows_Beta2_medium_corr';
all_windows_Beta2_medium_fisher=all_windows_Beta2_medium_fisher';

       all_windows_Theta_medium_corr=[]; all_windows_Theta_medium_fisher=[];
  for i=1:iEEG_step:length(roi1_Theta_medium_ts)-iEEG_window_size;
    a=i+iEEG_window_size;
    roi1_window_ts=roi1_Theta_medium_ts(i:a);
    roi2_window_ts=roi2_Theta_medium_ts(i:a);
            if i==1+iEEG_step*iEEG_window_plot-iEEG_step;
        Theta_roi1_window_ts_plot=roi1_window_ts;
        Theta_roi2_window_ts_plot=roi2_window_ts;
    end
    window_corr=corr(roi1_window_ts,roi2_window_ts);
    window_fisher=fisherz(window_corr);
    all_windows_Theta_medium_corr=[all_windows_Theta_medium_corr window_corr];   
   all_windows_Theta_medium_fisher=[all_windows_Theta_medium_fisher window_fisher];
  end  
all_windows_Theta_medium_corr=all_windows_Theta_medium_corr';
all_windows_Theta_medium_fisher=all_windows_Theta_medium_fisher';

       all_windows_Delta_medium_corr=[]; all_windows_Delta_medium_fisher=[];
  for i=1:iEEG_step:length(roi1_Delta_medium_ts)-iEEG_window_size;
    a=i+iEEG_window_size;
    roi1_window_ts=roi1_Delta_medium_ts(i:a);
    roi2_window_ts=roi2_Delta_medium_ts(i:a);
            if i==1+iEEG_step*iEEG_window_plot-iEEG_step;
        Delta_roi1_window_ts_plot=roi1_window_ts;
        Delta_roi2_window_ts_plot=roi2_window_ts;
    end
    window_corr=corr(roi1_window_ts,roi2_window_ts);
    window_fisher=fisherz(window_corr);
    all_windows_Delta_medium_corr=[all_windows_Delta_medium_corr window_corr];   
   all_windows_Delta_medium_fisher=[all_windows_Delta_medium_fisher window_fisher];
  end  
all_windows_Delta_medium_corr=all_windows_Delta_medium_corr';
all_windows_Delta_medium_fisher=all_windows_Delta_medium_fisher';

       all_windows_Gamma_medium_corr=[]; all_windows_Gamma_medium_fisher=[];
  for i=1:iEEG_step:length(roi1_Gamma_medium_ts)-iEEG_window_size;
    a=i+iEEG_window_size;
    roi1_window_ts=roi1_Gamma_medium_ts(i:a);
    roi2_window_ts=roi2_Gamma_medium_ts(i:a);
            if i==1+iEEG_step*iEEG_window_plot-iEEG_step;
        Gamma_roi1_window_ts_plot=roi1_window_ts;
        Gamma_roi2_window_ts_plot=roi2_window_ts;
    end
    window_corr=corr(roi1_window_ts,roi2_window_ts);
    window_fisher=fisherz(window_corr);
    all_windows_Gamma_medium_corr=[all_windows_Gamma_medium_corr window_corr];   
   all_windows_Gamma_medium_fisher=[all_windows_Gamma_medium_fisher window_fisher];
  end  
all_windows_Gamma_medium_corr=all_windows_Gamma_medium_corr';
all_windows_Gamma_medium_fisher=all_windows_Gamma_medium_fisher';

% normalize frequency window correlations
norm_all_windows_HFB_medium_fisher=(all_windows_HFB_medium_fisher-mean(all_windows_HFB_medium_fisher))/std(all_windows_HFB_medium_fisher);
norm_all_windows_Alpha_medium_fisher=(all_windows_Alpha_medium_fisher-mean(all_windows_Alpha_medium_fisher))/std(all_windows_Alpha_medium_fisher);
norm_all_windows_Beta1_medium_fisher=(all_windows_Beta1_medium_fisher-mean(all_windows_Beta1_medium_fisher))/std(all_windows_Beta1_medium_fisher);
norm_all_windows_Beta2_medium_fisher=(all_windows_Beta2_medium_fisher-mean(all_windows_Beta2_medium_fisher))/std(all_windows_Beta2_medium_fisher);
norm_all_windows_Gamma_medium_fisher=(all_windows_Gamma_medium_fisher-mean(all_windows_Gamma_medium_fisher))/std(all_windows_Gamma_medium_fisher);
norm_all_windows_Delta_medium_fisher=(all_windows_Delta_medium_fisher-mean(all_windows_Delta_medium_fisher))/std(all_windows_Delta_medium_fisher);
norm_all_windows_Theta_medium_fisher=(all_windows_Theta_medium_fisher-mean(all_windows_Theta_medium_fisher))/std(all_windows_Theta_medium_fisher);

% lag correlations between coupling in different frequencies
[lag_corr,lag_times]=crosscorr(all_windows_HFB_medium_fisher,all_windows_Alpha_medium_fisher,60); % 60 windows
HFB_alpha_lag_corr=lag_corr; HFB_alpha_lag_times=lag_times;

end

if frequency=='p'

      all_windows_HFB_corr=[]; all_windows_HFB_fisher=[];
  for i=1:iEEG_step:length(roi1_HFB_ts)-iEEG_window_size;
    a=i+iEEG_window_size;
    roi1_window_ts=roi1_HFB_ts(i:a);
    roi2_window_ts=roi2_HFB_ts(i:a);
    window_corr=corr(roi1_window_ts,roi2_window_ts);
    window_fisher=fisherz(window_corr);
    all_windows_HFB_corr=[all_windows_HFB_corr window_corr];   
   all_windows_HFB_fisher=[all_windows_HFB_fisher window_fisher];
  end  
all_windows_HFB_corr=all_windows_HFB_corr';
all_windows_HFB_fisher=all_windows_HFB_fisher';

       all_windows_Alpha_corr=[]; all_windows_Alpha_fisher=[];
  for i=1:iEEG_step:length(roi1_Alpha_ts)-iEEG_window_size;
    a=i+iEEG_window_size;
    roi1_window_ts=roi1_Alpha_ts(i:a);
    roi2_window_ts=roi2_Alpha_ts(i:a);
    window_corr=corr(roi1_window_ts,roi2_window_ts);
    window_fisher=fisherz(window_corr);
    all_windows_Alpha_corr=[all_windows_Alpha_corr window_corr];   
   all_windows_Alpha_fisher=[all_windows_Alpha_fisher window_fisher];
  end  
all_windows_Alpha_corr=all_windows_Alpha_corr';
all_windows_Alpha_fisher=all_windows_Alpha_fisher';

       all_windows_Beta1_corr=[]; all_windows_Beta1_fisher=[];
  for i=1:iEEG_step:length(roi1_Beta1_ts)-iEEG_window_size;
    a=i+iEEG_window_size;
    roi1_window_ts=roi1_Beta1_ts(i:a);
    roi2_window_ts=roi2_Beta1_ts(i:a);
    window_corr=corr(roi1_window_ts,roi2_window_ts);
    window_fisher=fisherz(window_corr);
    all_windows_Beta1_corr=[all_windows_Beta1_corr window_corr];   
   all_windows_Beta1_fisher=[all_windows_Beta1_fisher window_fisher];
  end  
all_windows_Beta1_corr=all_windows_Beta1_corr';
all_windows_Beta1_fisher=all_windows_Beta1_fisher';

       all_windows_Beta2_corr=[]; all_windows_Beta2_fisher=[];
  for i=1:iEEG_step:length(roi1_Beta2_ts)-iEEG_window_size;
    a=i+iEEG_window_size;
    roi1_window_ts=roi1_Beta2_ts(i:a);
    roi2_window_ts=roi2_Beta2_ts(i:a);
    window_corr=corr(roi1_window_ts,roi2_window_ts);
    window_fisher=fisherz(window_corr);
    all_windows_Beta2_corr=[all_windows_Beta2_corr window_corr];   
   all_windows_Beta2_fisher=[all_windows_Beta2_fisher window_fisher];
  end  
all_windows_Beta2_corr=all_windows_Beta2_corr';
all_windows_Beta2_fisher=all_windows_Beta2_fisher';

       all_windows_Theta_corr=[]; all_windows_Theta_fisher=[];
  for i=1:iEEG_step:length(roi1_Theta_ts)-iEEG_window_size;
    a=i+iEEG_window_size;
    roi1_window_ts=roi1_Theta_ts(i:a);
    roi2_window_ts=roi2_Theta_ts(i:a);
    window_corr=corr(roi1_window_ts,roi2_window_ts);
    window_fisher=fisherz(window_corr);
    all_windows_Theta_corr=[all_windows_Theta_corr window_corr];   
   all_windows_Theta_fisher=[all_windows_Theta_fisher window_fisher];
  end  
all_windows_Theta_corr=all_windows_Theta_corr';
all_windows_Theta_fisher=all_windows_Theta_fisher';

       all_windows_Delta_corr=[]; all_windows_Delta_fisher=[];
  for i=1:iEEG_step:length(roi1_Delta_ts)-iEEG_window_size;
    a=i+iEEG_window_size;
    roi1_window_ts=roi1_Delta_ts(i:a);
    roi2_window_ts=roi2_Delta_ts(i:a);
    window_corr=corr(roi1_window_ts,roi2_window_ts);
    window_fisher=fisherz(window_corr);
    all_windows_Delta_corr=[all_windows_Delta_corr window_corr];   
   all_windows_Delta_fisher=[all_windows_Delta_fisher window_fisher];
  end  
all_windows_Delta_corr=all_windows_Delta_corr';
all_windows_Delta_fisher=all_windows_Delta_fisher';

       all_windows_Gamma_corr=[]; all_windows_Gamma_fisher=[];
  for i=1:iEEG_step:length(roi1_Gamma_ts)-iEEG_window_size;
    a=i+iEEG_window_size;
    roi1_window_ts=roi1_Gamma_ts(i:a);
    roi2_window_ts=roi2_Gamma_ts(i:a);
    window_corr=corr(roi1_window_ts,roi2_window_ts);
    window_fisher=fisherz(window_corr);
    all_windows_Gamma_corr=[all_windows_Gamma_corr window_corr];   
   all_windows_Gamma_fisher=[all_windows_Gamma_fisher window_fisher];
  end  
all_windows_Gamma_corr=all_windows_Gamma_corr';
all_windows_Gamma_fisher=all_windows_Gamma_fisher';   
end
end

%% Normalize time series 
if BOLD=='BOLD'
roi1_ts_norm=(roi1_ts-mean(roi1_ts))/std(roi1_ts);
roi2_ts_norm=(roi2_ts-mean(roi2_ts))/std(roi2_ts);

%% calculate lag correlations
[lag_corr,lag_times]=crosscorr(roi1_ts_norm,roi2_ts_norm,(60/TR)); % 60 sec lags
lag_times=lag_times*TR;
lag_peak=lag_times(find(lag_corr==max(lag_corr)));

%% calculate dynamic conditional correlations
[H,R,Theta,X]=DCC_X([roi1_ts_norm roi2_ts_norm],0,0);
dcc=squeeze(R(1,2,:));

end

if BOLD=='iEEG'
    if frequency~='0' && frequency ~='p'
   roi1_ts_norm=(roi1_ts-mean(roi1_ts))/std(roi1_ts);
roi2_ts_norm=(roi2_ts-mean(roi2_ts))/std(roi2_ts);

%% Calculate power spectra
pspec_roi1=pwelch(roi1_ts_norm,iEEG_sampling,0,1:170,iEEG_sampling,'power');
pspec_roi2=pwelch(roi2_ts_norm,iEEG_sampling,0,1:170,iEEG_sampling,'power');

%% calculate lag correlations
[lag_corr,lag_times]=crosscorr(roi1_ts_norm,roi2_ts_norm,60*iEEG_sampling); % 60 sec lags
lag_times=lag_times/iEEG_sampling;
lag_peak=lag_times(find(lag_corr==max(lag_corr)));

%% calculate dynamic conditional correlations
%[H,R,Theta,X]=DCC_X([roi1_ts_norm roi2_ts_norm],0,0);
%dcc=squeeze(R(1,2,:));

    elseif frequency=='0'
        roi1_HFB_medium_ts_norm=(roi1_HFB_medium_ts-mean(roi1_HFB_medium_ts))/std(roi1_HFB_medium_ts);
        roi1_Alpha_medium_ts_norm=(roi1_Alpha_medium_ts-mean(roi1_Alpha_medium_ts))/std(roi1_Alpha_medium_ts);
        roi1_Beta1_medium_ts_norm=(roi1_Beta1_medium_ts-mean(roi1_Beta1_medium_ts))/std(roi1_Beta1_medium_ts);
        roi1_Beta2_medium_ts_norm=(roi1_Beta2_medium_ts-mean(roi1_Beta2_medium_ts))/std(roi1_Beta2_medium_ts);
        roi1_Theta_medium_ts_norm=(roi1_Theta_medium_ts-mean(roi1_Theta_medium_ts))/std(roi1_Theta_medium_ts);
        roi1_Delta_medium_ts_norm=(roi1_Delta_medium_ts-mean(roi1_Delta_medium_ts))/std(roi1_Delta_medium_ts);
        roi1_Gamma_medium_ts_norm=(roi1_Gamma_medium_ts-mean(roi1_Gamma_medium_ts))/std(roi1_Gamma_medium_ts);
        roi2_HFB_medium_ts_norm=(roi2_HFB_medium_ts-mean(roi2_HFB_medium_ts))/std(roi2_HFB_medium_ts);
        roi2_Alpha_medium_ts_norm=(roi2_Alpha_medium_ts-mean(roi2_Alpha_medium_ts))/std(roi2_Alpha_medium_ts);
        roi2_Beta1_medium_ts_norm=(roi2_Beta1_medium_ts-mean(roi2_Beta1_medium_ts))/std(roi2_Beta1_medium_ts);
        roi2_Beta2_medium_ts_norm=(roi2_Beta2_medium_ts-mean(roi2_Beta2_medium_ts))/std(roi2_Beta2_medium_ts);
        roi2_Theta_medium_ts_norm=(roi2_Theta_medium_ts-mean(roi2_Theta_medium_ts))/std(roi2_Theta_medium_ts);
        roi2_Delta_medium_ts_norm=(roi2_Delta_medium_ts-mean(roi2_Delta_medium_ts))/std(roi2_Delta_medium_ts);
        roi2_Gamma_medium_ts_norm=(roi2_Gamma_medium_ts-mean(roi2_Gamma_medium_ts))/std(roi2_Gamma_medium_ts);
        
        roi1_all_freq_medium_ts=[roi1_Delta_medium_ts_norm,roi1_Theta_medium_ts_norm,roi1_Alpha_medium_ts_norm ...
            roi1_Beta1_medium_ts_norm roi1_Beta2_medium_ts_norm roi1_Gamma_medium_ts_norm roi1_HFB_medium_ts_norm];
        
        roi2_all_freq_medium_ts=[roi2_Delta_medium_ts_norm,roi2_Theta_medium_ts_norm,roi2_Alpha_medium_ts_norm ...
            roi2_Beta1_medium_ts_norm roi2_Beta2_medium_ts_norm roi2_Gamma_medium_ts_norm roi2_HFB_medium_ts_norm];

        [lag_corr_HFB_medium,lag_times]=crosscorr(roi1_HFB_medium_ts,roi2_HFB_medium_ts_norm,60*iEEG_sampling);
        [lag_corr_Alpha_medium,lag_times]=crosscorr(roi1_Alpha_medium_ts,roi2_Alpha_medium_ts_norm,60*iEEG_sampling);
        [lag_corr_Beta1_medium,lag_times]=crosscorr(roi1_Beta1_medium_ts,roi2_Beta1_medium_ts_norm,60*iEEG_sampling);
        [lag_corr_Beta2_medium,lag_times]=crosscorr(roi1_Beta2_medium_ts,roi2_Beta2_medium_ts_norm,60*iEEG_sampling);
        [lag_corr_Theta_medium,lag_times]=crosscorr(roi1_Theta_medium_ts,roi2_Theta_medium_ts_norm,60*iEEG_sampling);
        [lag_corr_Delta_medium,lag_times]=crosscorr(roi1_Delta_medium_ts,roi2_Delta_medium_ts_norm,60*iEEG_sampling);
        [lag_corr_Gamma_medium,lag_times]=crosscorr(roi1_Gamma_medium_ts,roi2_Gamma_medium_ts_norm,60*iEEG_sampling);
        lag_times=lag_times/iEEG_sampling;
        
    elseif frequency=='p'
        roi1_HFB_ts_norm=(roi1_HFB_ts-mean(roi1_HFB_ts))/std(roi1_HFB_ts);
        roi1_Alpha_ts_norm=(roi1_Alpha_ts-mean(roi1_Alpha_ts))/std(roi1_Alpha_ts);
        roi1_Beta1_ts_norm=(roi1_Beta1_ts-mean(roi1_Beta1_ts))/std(roi1_Beta1_ts);
        roi1_Beta2_ts_norm=(roi1_Beta2_ts-mean(roi1_Beta2_ts))/std(roi1_Beta2_ts);
        roi1_Theta_ts_norm=(roi1_Theta_ts-mean(roi1_Theta_ts))/std(roi1_Theta_ts);
        roi1_Delta_ts_norm=(roi1_Delta_ts-mean(roi1_Delta_ts))/std(roi1_Delta_ts);
        roi1_Gamma_ts_norm=(roi1_Gamma_ts-mean(roi1_Gamma_ts))/std(roi1_Gamma_ts);
        roi2_HFB_ts_norm=(roi2_HFB_ts-mean(roi2_HFB_ts))/std(roi2_HFB_ts);
        roi2_Alpha_ts_norm=(roi2_Alpha_ts-mean(roi2_Alpha_ts))/std(roi2_Alpha_ts);
        roi2_Beta1_ts_norm=(roi2_Beta1_ts-mean(roi2_Beta1_ts))/std(roi2_Beta1_ts);
        roi2_Beta2_ts_norm=(roi2_Beta2_ts-mean(roi2_Beta2_ts))/std(roi2_Beta2_ts);
        roi2_Theta_ts_norm=(roi2_Theta_ts-mean(roi2_Theta_ts))/std(roi2_Theta_ts);
        roi2_Delta_ts_norm=(roi2_Delta_ts-mean(roi2_Delta_ts))/std(roi2_Delta_ts);
        roi2_Gamma_ts_norm=(roi2_Gamma_ts-mean(roi2_Gamma_ts))/std(roi2_Gamma_ts); 
        
                roi1_all_freq_ts=[roi1_Delta_ts_norm,roi1_Theta_ts_norm,roi1_Alpha_ts_norm ...
            roi1_Beta1_ts_norm roi1_Beta2_ts_norm roi1_Gamma_ts_norm roi1_HFB_ts_norm];
        
        roi2_all_freq_ts=[roi2_Delta_ts_norm,roi2_Theta_ts_norm,roi2_Alpha_ts_norm ...
            roi2_Beta1_ts_norm roi2_Beta2_ts_norm roi2_Gamma_ts_norm roi2_HFB_ts_norm];
        
         [lag_corr_HFB,lag_times]=crosscorr(roi1_HFB_ts,roi2_HFB_ts_norm,60*iEEG_sampling);
        [lag_corr_Alpha,lag_times]=crosscorr(roi1_Alpha_ts,roi2_Alpha_ts_norm,60*iEEG_sampling);
        [lag_corr_Beta1,lag_times]=crosscorr(roi1_Beta1_ts,roi2_Beta1_ts_norm,60*iEEG_sampling);
        [lag_corr_Beta2,lag_times]=crosscorr(roi1_Beta2_ts,roi2_Beta2_ts_norm,60*iEEG_sampling);
        [lag_corr_Theta,lag_times]=crosscorr(roi1_Theta_ts,roi2_Theta_ts_norm,60*iEEG_sampling);
        [lag_corr_Delta,lag_times]=crosscorr(roi1_Delta_ts,roi2_Delta_ts_norm,60*iEEG_sampling);
        [lag_corr_Gamma,lag_times]=crosscorr(roi1_Gamma_ts,roi2_Gamma_ts_norm,60*iEEG_sampling);
        
    end
end

%% Plots
if BOLD=='BOLD'
    freq=[''];
end

if BOLD=='BOLD'
window_duration=BOLD_window_duration;
step_size=BOLD_step*TR;
elseif BOLD=='iEEG'
    window_duration=iEEG_window_duration;
    step_size=iEEG_step/iEEG_sampling;
end

% Static FC
if BOLD=='BOLD'
    time=(1:length(roi1_ts))*TR;
FigHandle = figure('Position', [200, 600, 1200, 800]);
figure(1)
subplot(3,1,1);
title({[BOLD ' ' freq ': ' roi1 ' vs ' roi2]; ['r = ' num2str(static_fc)]} ,'Fontsize',12);
xlabel(['Time (sec)']); ylabel(['Signal']);
set(gca,'Fontsize',14,'Fontweight','bold','LineWidth',2,'TickDir','out','box','off');
hold on;
p=plot(time,roi1_ts_norm,time,roi2_ts_norm);
p(1).LineWidth=2; p(1).Color=[cdcol.portraitplum];
p(2).LineWidth=2; p(2).Color=[cdcol.vermilion];
xlim([0,time(end)]);
legend([roi1],[roi2]);
hold on;

% BOLD dynamic conditional correlations
subplot(3,1,2);
plot(time,dcc,'k','LineWidth',2);
title({['Dynamic Conditional Correlation: ' roi1 ' vs ' roi2]; ['Var = ' num2str(var(dcc))]},'Fontsize',12);
xlabel(['Time (sec)']); ylabel(['DCC']);
xlim([0,time(end)]);
set(gca,'Fontsize',14,'Fontweight','bold','LineWidth',2,'TickDir','out','box','off');
hold on;

% BOLD Sliding-window correlations
subplot(3,1,3);
p=plot(1:length(all_windows_fisher),all_windows_fisher);
p(1).LineWidth=2; p(1).Color=cdcol.scarlet;

title({['Dynamic FC: ' roi1 ' vs ' roi2]; ['FCV = ' num2str(std(all_windows_fisher))]; ...
    ['Step size = ' num2str(step_size) ' sec']} ,'Fontsize',12);
xlabel(['Window number (' num2str(window_duration) ' sec windows)']); ylabel(['Correlation (z)']);
set(gca,'Fontsize',14,'Fontweight','bold','LineWidth',2,'TickDir','out','box','off');
pause;close

% Plot BOLD lag correlation

plot(lag_times,lag_corr,'r','LineWidth',2);
title({['iEEG ' freq ': ' roi1  ' vs'  roi2 ' lag correlations']; ['Peak = ' num2str(lag_peak)]},'Fontsize',10);
xlabel(['Lag (sec)']); ylabel(['Correlation']);
xlim([lag_times(1),lag_times(end)]);
set(gca,'Fontsize',14,'Fontweight','bold','LineWidth',2,'TickDir','out','box','off');
pause; close;
end


if BOLD=='iEEG'
if frequency~='0' && frequency~='p'
FigHandle = figure('Position', [200, 600, 1200, 800]);
figure(1)
time=(1:length(roi1_ts))/iEEG_sampling;
subplot(2,1,1);
title({[BOLD ' ' freq ': ' roi1 ' vs ' roi2]; ['r = ' num2str(static_fc)]} ,'Fontsize',12);
xlabel(['Time (sec)']); ylabel(['Signal']);
set(gca,'Fontsize',14,'Fontweight','bold','LineWidth',2,'TickDir','out','box','off');
hold on;
p=plot(time,roi1_ts_norm,time,roi2_ts_norm);
p(1).LineWidth=2; p(1).Color=cdcol.portraitplum;
p(2).LineWidth=2; p(2).Color=cdcol.vermilion;
xlim([0,time(end)]);
legend([roi1],[roi2]);
hold on;

% iEEG sliding-window correlation
subplot(2,1,2);
plot(1:length(all_windows_fisher),all_windows_fisher,'k','LineWidth',2);
title({['Dynamic FC: ' roi1 ' vs ' roi2]; ['FCV = ' num2str(std(all_windows_fisher))]; ['Mean = ' num2str(mean(all_windows_fisher))]; ...
    ['Step size = ' num2str(step_size) ' sec']} ,'Fontsize',12);
xlabel(['Window number (' num2str(window_duration) ' sec windows)']); ylabel(['Correlation (z)']);
set(gca,'Fontsize',14,'Fontweight','bold','LineWidth',2,'TickDir','out','box','off');
pause; close; 

% Plot iEEG lag correlation
plot(lag_times,lag_corr,'r','LineWidth',2);
title({['iEEG ' freq ': ' roi1  ' vs'  roi2 ' lag correlations']; ['Peak = ' num2str(lag_peak)]},'Fontsize',10);
xlabel(['Lag (sec)']); ylabel(['Correlation']);
xlim([lag_times(1),lag_times(end)]);
set(gca,'Fontsize',14,'Fontweight','bold','LineWidth',2,'TickDir','out','box','off');
pause; close;

% Plot a zoom-in of selected window
time=1:length(roi1_window_ts_plot); time=time/iEEG_sampling;
window_corr=num2str(corr(roi1_window_ts_plot,roi2_window_ts_plot));
FigHandle = figure('Position', [200, 600, 1000, 400]);
plot(time,roi1_window_ts_plot,'r',...
    time,roi2_window_ts_plot,'b',...
    'LineWidth',2);
title({['(0.1-1 Hz): ' roi1 ' vs ' roi2];...
    ['Window ' num2str(iEEG_window_plot) ':  r = ' window_corr]} ,'Fontsize',12);
xlabel(['Time (sec)']); ylabel(['Signal']);
set(gca,'Fontsize',14,'Fontweight','bold','LineWidth',2,'TickDir','out','box','off');
xlim([0,time(end)]);
legend([roi1],[roi2]);
pause; close

%% Plot power spectum for each region
FigHandle = figure('Position', [200, 600, 1200, 800]);
figure(1)
subplot(2,1,1)
plot(10*log10(pspec_roi1),'r','LineWidth',2);
title({['iEEG ' freq ': ' roi1 ' power spectrum']},'Fontsize',10);
set(gca,'Xscale','log');
set(gca,'Fontsize',14,'Fontweight','bold','LineWidth',2,'TickDir','out','box','off');
set(gcf,'color','w');

subplot(2,1,2)
plot(10*log10(pspec_roi2),'r','LineWidth',2);
title({['iEEG ' freq ': ' roi2 ' power spectrum']},'Fontsize',10);
set(gca,'Xscale','log');
set(gca,'Fontsize',14,'Fontweight','bold','LineWidth',2,'TickDir','out','box','off');
set(gcf,'color','w');
pause; close;
end 
end

% dFC for all frequencies (normalized within-frequency) on one plot
if frequency=='0'
plot(1:length(all_windows_HFB_medium_fisher),norm_all_windows_HFB_medium_fisher,...
    1:length(all_windows_Alpha_medium_fisher),norm_all_windows_Alpha_medium_fisher,...
    1:length(all_windows_Beta1_medium_fisher),norm_all_windows_Beta1_medium_fisher,...
    1:length(all_windows_Beta2_medium_fisher),norm_all_windows_Beta2_medium_fisher,...
    1:length(all_windows_Delta_medium_fisher),norm_all_windows_Delta_medium_fisher,...
    1:length(all_windows_Theta_medium_fisher),norm_all_windows_Theta_medium_fisher,...   
    1:length(all_windows_Gamma_medium_fisher),norm_all_windows_Gamma_medium_fisher,...
    'LineWidth',2);
title({['Dynamic FC (0.1-1 Hz): ' roi1 ' vs ' roi2]; ...
    ['Step size = ' num2str(step_size) ' sec']} ,'Fontsize',12);
xlabel(['Window number (' num2str(window_duration) ' sec windows)']); ylabel(['Normalized correlation (z)']);
set(gca,'Fontsize',14,'Fontweight','bold','LineWidth',2,'TickDir','out','box','off');
set(gcf,'color','w');
legend('HFB','α','β1','β2','δ','θ','γ','Location','southeast')
pause; close;

% Sliding window dFC for HFB vs alpha
if iEEG_window_duration=='aa'
    window_duration=30;
end
SWC_HFB_vs_alpha=corr(all_windows_HFB_medium_fisher,all_windows_Alpha_medium_fisher);

    FigHandle = figure('Position', [200, 600, 1000, 400]);
p=plot(1:length(all_windows_HFB_medium_fisher),norm_all_windows_HFB_medium_fisher,...
1:length(all_windows_Alpha_medium_fisher),norm_all_windows_Alpha_medium_fisher);

p(1).LineWidth=2; p(1).Color=[cdcol.scarlet];
p(2).LineWidth=2; p(2).Color=[cdcol.turquoiseblue];

title({['Dynamic FC (0.1-1 Hz): ' roi1 ' vs ' roi2]; ...
    ['Step size = ' num2str(step_size) ' sec; r = ' num2str(SWC_HFB_vs_alpha)]} ,'Fontsize',12);
xlabel(['Window number (' num2str(window_duration) ' sec windows)']); ylabel(['Normalized correlation (z)']);
set(gca,'Fontsize',14,'Fontweight','bold','LineWidth',2,'TickDir','out','box','off');
set(gcf,'color','w');
legend('HFB','α','Location','southeast')
pause; close;

% MTD for HFB vs alpha
if isnumeric(iEEG_window_duration)==1
time=(1:length(roi1_HFB_medium_ts))/iEEG_sampling;
    FigHandle = figure('Position', [200, 600, 1000, 400]);
p= plot(time,mtd_HFB,...
    time,mtd_alpha);
p(1).LineWidth=2; p(1).Color=[cdcol.scarlet];
p(2).LineWidth=2; p(2).Color=[cdcol.turquoiseblue];
title({['MTD: ' roi1 ' vs ' roi2]; ...
    ['Window size = ' num2str(iEEG_window_duration) ' sec; r = ' num2str(corr(mtd_alpha,mtd_HFB))]} ,'Fontsize',12);
xlabel(['Time (sec)']); ylabel(['MTD']);
set(gca,'Fontsize',14,'Fontweight','bold','LineWidth',2,'TickDir','out','box','off');
set(gcf,'color','w');
legend('HFB','α','Location','southeast')
pause; close;
end

% dFC cross-correlation of frequencies
all_windows_allfreqs=[all_windows_Delta_medium_fisher all_windows_Theta_medium_fisher all_windows_Alpha_medium_fisher ...
    all_windows_Beta1_medium_fisher all_windows_Beta2_medium_fisher all_windows_Gamma_medium_fisher all_windows_HFB_medium_fisher];
xcorr_allfreqs=corrcoef(all_windows_allfreqs);
xcorr_allfreqs_column=nonzeros(triu(xcorr_allfreqs)');
xcorr_allfreqs_column(find(xcorr_allfreqs_column==1))=[];

FigHandle = figure(1);
set(FigHandle,'Position',[50, 50, 700, 600]);
set(gcf,'color','w');
imagesc(xcorr_allfreqs,[-1 1]); h=colorbar('vert'); colormap jet
set(h,'fontsize',16);
set(get(h,'title'),'string','r');
set(gca,'XTickLabel',{'δ','θ', 'α','β1','β2','γ','HFB'},'Fontsize',12)
set(gca,'YTickLabel',{'δ','θ', 'α','β1','β2','γ','HFB'},'Fontsize',12)
title(['Dynamic FC (0.1-1 Hz) cross-correlation of frequencies'])
pause; close

% local site cross-frequency correlations
roi1_xcorr_allfreqs=corrcoef(roi1_all_freq_medium_ts);

FigHandle = figure(1);
set(FigHandle,'Position',[50, 50, 700, 600]);
set(gcf,'color','w');
imagesc(xcorr_allfreqs,[-1 1]); h=colorbar('vert'); colormap jet
set(h,'fontsize',16);
set(get(h,'title'),'string','r');
set(gca,'XTickLabel',{'δ','θ', 'α','β1','β2','γ','HFB'},'Fontsize',12)
set(gca,'YTickLabel',{'δ','θ', 'α','β1','β2','γ','HFB'},'Fontsize',12)
title(['Cross-correlation of frequencies at' roi1])
pause; close;

roi2_xcorr_allfreqs=corrcoef(roi2_all_freq_medium_ts);

FigHandle = figure(1);
set(FigHandle,'Position',[50, 50, 700, 600]);
set(gcf,'color','w');
imagesc(xcorr_allfreqs,[-1 1]); h=colorbar('vert'); colormap jet
set(h,'fontsize',16);
set(get(h,'title'),'string','r');
set(gca,'XTickLabel',{'δ','θ', 'α','β1','β2','γ','HFB'},'Fontsize',12)
set(gca,'YTickLabel',{'δ','θ', 'α','β1','β2','γ','HFB'},'Fontsize',12)
title(['Cross-correlation of frequencies at' roi2])
pause; close;

% lag correlations for all frequencies on one plot
FigHandle = figure('Position', [200, 600, 1200, 400]);
plot(lag_times,lag_corr_HFB_medium, ...
    lag_times, lag_corr_Alpha_medium, ...
    lag_times, lag_corr_Beta1_medium,...
    lag_times, lag_corr_Beta2_medium,...
    lag_times, lag_corr_Delta_medium,...
    lag_times, lag_corr_Theta_medium,...
    lag_times, lag_corr_Gamma_medium,...
    'LineWidth',2);
title({['iEEG (0.1-1 Hz) all frequencies'] [roi1 ' vs ' roi2 ' lag correlations']},'Fontsize',10);
xlabel(['Lag (sec)']); ylabel(['Correlation']);
xlim([lag_times(1),lag_times(end)]);
set(gca,'Fontsize',16,'Fontweight','bold','LineWidth',2,'TickDir','out','box','off');
set(gcf,'color','w');
legend('HFB','α','β1','β2','δ','θ','γ','Location','northeastoutside')
print('-opengl','-r300','-dpng',strcat([pwd,filesep,'BOLD_ECoG_figs/lag_corr_allfreq_' runnum roi1 roi2]));
pause; close;

% plot time series for window of interest
for i=1:length(freq_window_plot)
    freq_name=[];
if freq_window_plot(i)==1
    freq_name='HFB';
    roi1_window_ts_plot=HFB_roi1_window_ts_plot; roi2_window_ts_plot=HFB_roi2_window_ts_plot;
elseif freq_window_plot(i)==2
    freq_name='Alpha';
    roi1_window_ts_plot=Alpha_roi1_window_ts_plot; roi2_window_ts_plot=Alpha_roi2_window_ts_plot;
end
time=1:length(roi1_window_ts_plot); time=time/iEEG_sampling;
window_corr=num2str(corr(roi1_window_ts_plot,roi2_window_ts_plot));
FigHandle = figure('Position', [200, 600, 1000, 400]);
p=plot(time,roi1_window_ts_plot,...
    time,roi2_window_ts_plot);
p(1).LineWidth=3; p(1).Color=cdcol.portraitplum;
p(2).LineWidth=3; p(2).Color=cdcol.vermilion;

title({[freq_name ' (0.1-1 Hz): ' roi1 ' vs ' roi2];...
    ['Window ' num2str(iEEG_window_plot) ':  r = ' window_corr]} ,'Fontsize',12);
xlabel(['Time (sec)']); ylabel(['Signal']);
set(gca,'Fontsize',14,'Fontweight','bold','LineWidth',2,'TickDir','out','box','off');
xlim([0,time(end)]);
legend([roi1],[roi2]);
pause; close
end

% dFC for HFB vs alpha as a function of window length
if iEEG_window_duration=='aa'

   % FigHandle = figure('Position', [200, 600, 1000, 400]);
plot(SWC_HFB_vs_Alpha_all,'k.-','Marker','square', 'LineWidth',2);
title([roi1 '-' roi2 ' HFB vs Alpha dynamic FC'],'Fontsize',12);
ylim([-1 1]);
set(gca,'Fontsize',14,'Fontweight','bold','LineWidth',2,'TickDir','out','box','off');
set(gcf,'color','w');
xlabel(['Sliding window duration (sec)']); 
ylabel(['HFB-Alpha FC correlation (r)']);
xticks([1 2 3 4 5 6 7 8 9 10])
xticklabels({'10','20','30','40','50','60','70','80','90','100'})

pause; close;
end
end
% save SWC values for subject
cd([globalECoGDir '/Rest/' Patient '/Run' runs])
save('SWC_HFB_vs_Alpha_all','SWC_HFB_vs_Alpha_all');

if frequency=='p'
plot(1:length(all_windows_HFB_fisher),all_windows_HFB_fisher,...
    1:length(all_windows_Alpha_fisher),all_windows_Alpha_fisher,...
    1:length(all_windows_Beta1_fisher),all_windows_Beta1_fisher,...
    1:length(all_windows_Beta2_fisher),all_windows_Beta2_fisher,...
    1:length(all_windows_Delta_fisher),all_windows_Delta_fisher,...
    1:length(all_windows_Theta_fisher),all_windows_Theta_fisher,...   
    1:length(all_windows_Gamma_fisher),all_windows_Gamma_fisher,...
    'LineWidth',2);
title({['Dynamic FC (unfiltered): ' roi1 ' vs ' roi2]; ...
    ['Step size = ' num2str(step_size) ' sec']} ,'Fontsize',12);
xlabel(['Window number (' num2str(window_duration) ' sec windows)']); ylabel(['Correlation (z)']);
set(gca,'Fontsize',14,'Fontweight','bold','LineWidth',2,'TickDir','out','box','off');
set(gcf,'color','w');
legend('HFB','α','β1','β2','δ','θ','γ','Location','southeast')
pause; close;

% dFC cross-correlation of frequencies
all_windows_allfreqs=[all_windows_Delta_fisher all_windows_Theta_fisher all_windows_Alpha_fisher ...
    all_windows_Beta1_fisher all_windows_Beta2_fisher all_windows_Gamma_fisher all_windows_HFB_fisher];

xcorr_allfreqs=corrcoef(all_windows_allfreqs);

FigHandle = figure(1);
set(FigHandle,'Position',[50, 50, 700, 600]);
set(gcf,'color','w');
imagesc(xcorr_allfreqs,[-1 1]); h=colorbar('vert'); colormap jet
set(h,'fontsize',16);
set(get(h,'title'),'string','r');
set(gca,'XTickLabel',{'δ','θ', 'α','β1','β2','γ','HFB'},'Fontsize',12)
set(gca,'YTickLabel',{'δ','θ', 'α','β1','β2','γ','HFB'},'Fontsize',12)
title(['Dynamic FC (unfiltered) cross-correlation of frequencies'])

% lag correlations for all frequencies on one plot
FigHandle = figure('Position', [200, 600, 1200, 500]);
plot(lag_times,lag_corr_HFB, ...
    lag_times, lag_corr_Alpha, ...
    lag_times, lag_corr_Beta1,...
    lag_times, lag_corr_Beta2,...
    lag_times, lag_corr_Delta,...
    lag_times, lag_corr_Theta,...
    lag_times, lag_corr_Gamma,...
    'LineWidth',1);
title({['iEEG (unfiltered) all frequencies'] [roi1 ' vs ' roi2 ' lag correlations']},'Fontsize',10);
xlabel(['Lag (sec)']); ylabel(['Correlation']);
xlim([lag_times(1),lag_times(end)]);
set(gca,'Fontsize',14,'Fontweight','bold','LineWidth',2,'TickDir','out','box','off');
set(gcf,'color','w');
legend('HFB','α','β1','β2','δ','θ','γ','Location','northeast')
pause; close;

end