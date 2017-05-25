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
       frequency=input('HFB (1)'); 
    end
else
    frequency=' ';
end
runs=input('run (e.g. 1): ','s');
roi1=input('ROI 1 (e.g. AFS9): ','s');
roi2=input('ROI 2 (e.g. PIHS4): ','s');

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
BOLD_window_size=15; % number of TRs per window
BOLD_window_duration=TR*BOLD_window_size;

%% iEEG defaults
iEEG_sampling=1000;
iEEG_step=2000;
iEEG_window_size=30000;
iEEG_window_duration=iEEG_window_size/iEEG_sampling;
depth='0';


%% Get hemisphere and file base name for iEEG
if BOLD=='iEEG'
cd ([globalECoGDir '/Rest/' Patient]);
if depth=='0'
hemi=importdata(['hemi.txt']); 
hemi=char(hemi);
end
cd([globalECoGDir '/Rest/' Patient '/Run' runs]);
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
cd([globalECoGDir '/Rest/' Patient '/Run' runs]);

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

if frequency ~='0' || frequency~='p'
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

%% Load ROI time series
if BOLD=='BOLD'
cd([fsDir '/' Patient '/elec_recon/electrode_spheres']);

roi1_ts=load(['elec' num2str(roi1_num) runnum '_ts_GSR.txt']);
roi2_ts=load(['elec' num2str(roi2_num) runnum '_ts_GSR.txt']);
end

if BOLD=='iEEG'
    roi1_iEEG_num=iElvis_to_iEEG_chanlabel(roi1_num);
    roi2_iEEG_num=iElvis_to_iEEG_chanlabel(roi2_num);

    if frequency ~='0' && frequency ~='p'
    roi1_ts=iEEG_ts(:,roi1_iEEG_num);   
    roi2_ts=iEEG_ts(:,roi2_iEEG_num);   
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

%% Sliding windows
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
    if frequency~='0' && frequency ~='p'
    all_windows_corr=[]; all_windows_fisher=[];
  %for i=1:iEEG_step:floor(length(roi1_ts)/iEEG_step);
  for i=1:iEEG_step:length(roi1_ts)-iEEG_window_size;
    a=i+iEEG_window_size;
    roi1_window_ts=roi1_ts(i:a);
    roi2_window_ts=roi2_ts(i:a);
    window_corr=corr(roi1_window_ts,roi2_window_ts);
    window_fisher=fisherz(window_corr);
    all_windows_corr=[all_windows_corr window_corr];   
   all_windows_fisher=[all_windows_fisher window_fisher];
  end  
all_windows_corr=all_windows_corr';
all_windows_fisher=all_windows_fisher';
    end
if frequency=='0'
     all_windows_HFB_medium_corr=[]; all_windows_HFB_medium_fisher=[];
  for i=1:iEEG_step:length(roi1_HFB_medium_ts)-iEEG_window_size;
    a=i+iEEG_window_size;
    roi1_window_ts=roi1_HFB_medium_ts(i:a);
    roi2_window_ts=roi2_HFB_medium_ts(i:a);
    window_corr=corr(roi1_window_ts,roi2_window_ts);
    window_fisher=fisherz(window_corr);
    all_windows_HFB_medium_corr=[all_windows_HFB_medium_corr window_corr];   
   all_windows_HFB_medium_fisher=[all_windows_HFB_medium_fisher window_fisher];
  end  
all_windows_HFB_medium_corr=all_windows_HFB_medium_corr';
all_windows_HFB_medium_fisher=all_windows_HFB_medium_fisher';

       all_windows_Alpha_medium_corr=[]; all_windows_Alpha_medium_fisher=[];
  for i=1:iEEG_step:length(roi1_Alpha_medium_ts)-iEEG_window_size;
    a=i+iEEG_window_size;
    roi1_window_ts=roi1_Alpha_medium_ts(i:a);
    roi2_window_ts=roi2_Alpha_medium_ts(i:a);
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
    window_corr=corr(roi1_window_ts,roi2_window_ts);
    window_fisher=fisherz(window_corr);
    all_windows_Gamma_medium_corr=[all_windows_Gamma_medium_corr window_corr];   
   all_windows_Gamma_medium_fisher=[all_windows_Gamma_medium_fisher window_fisher];
  end  
all_windows_Gamma_medium_corr=all_windows_Gamma_medium_corr';
all_windows_Gamma_medium_fisher=all_windows_Gamma_medium_fisher';




end



end

%% Normalize time series
if BOLD=='BOLD'
roi1_ts_norm=(roi1_ts-mean(roi1_ts))/std(roi1_ts);
roi2_ts_norm=(roi2_ts-mean(roi2_ts))/std(roi2_ts);
end

if BOLD=='iEEG'
    if frequency~='0' && frequency ~='p'
   roi1_ts_norm=(roi1_ts-mean(roi1_ts))/std(roi1_ts);
roi2_ts_norm=(roi2_ts-mean(roi2_ts))/std(roi2_ts);

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
FigHandle = figure('Position', [200, 600, 1200, 800]);
figure(1)
subplot(2,1,1);
title({[BOLD ' ' freq ': ' roi1 ' vs ' roi2]; ['r = ' num2str(static_fc)]} ,'Fontsize',12);
xlabel(['Time']); ylabel(['Signal']);
set(gca,'Fontsize',14,'Fontweight','bold','LineWidth',2,'TickDir','out','box','off');
hold on;
plot(1:length(roi1_ts),roi1_ts_norm,1:length(roi2_ts),roi2_ts_norm,'LineWidth',2);
xlim([0,length(roi1_ts)]);
legend([roi1],[roi2]);
hold on;

% Dynamic FC
subplot(2,1,2);
%set(gca,'Fontsize',14,'Fontweight','bold','LineWidth',2,'TickDir','out','box','off');
%hold on;
plot(1:length(all_windows_fisher),all_windows_fisher,'LineWidth',2);
title({['Dynamic FC: ' roi1 ' vs ' roi2]; ['FCV = ' num2str(std(all_windows_fisher))]; ...
    ['Step size = ' num2str(step_size) ' sec']} ,'Fontsize',12);
xlabel(['Window number (' num2str(window_duration) ' sec windows)']); ylabel(['Correlation (z)']);
set(gca,'Fontsize',14,'Fontweight','bold','LineWidth',2,'TickDir','out','box','off');
pause; close;
end

if BOLD=='iEEG'
if frequency~='0' && frequency~='p'
FigHandle = figure('Position', [200, 600, 1200, 800]);
figure(1)
subplot(2,1,1);
title({[BOLD ' ' freq ': ' roi1 ' vs ' roi2]; ['r = ' num2str(static_fc)]} ,'Fontsize',12);
xlabel(['Time']); ylabel(['Signal']);
set(gca,'Fontsize',14,'Fontweight','bold','LineWidth',2,'TickDir','out','box','off');
hold on;
plot(1:length(roi1_ts),roi1_ts_norm,1:length(roi2_ts),roi2_ts_norm,'LineWidth',2);
xlim([0,length(roi1_ts)]);
legend([roi1],[roi2]);
hold on;

% Dynamic FC
subplot(2,1,2);
%set(gca,'Fontsize',14,'Fontweight','bold','LineWidth',2,'TickDir','out','box','off');
%hold on;
plot(1:length(all_windows_fisher),all_windows_fisher,'LineWidth',2);
title({['Dynamic FC: ' roi1 ' vs ' roi2]; ['FCV = ' num2str(std(all_windows_fisher))]; ...
    ['Step size = ' num2str(step_size) ' sec']} ,'Fontsize',12);
xlabel(['Window number (' num2str(window_duration) ' sec windows)']); ylabel(['Correlation (z)']);
set(gca,'Fontsize',14,'Fontweight','bold','LineWidth',2,'TickDir','out','box','off');
pause; close;    
end 
end

% dFC for all frequencies on one plot
if frequency=='0'
plot(1:length(all_windows_HFB_medium_fisher),all_windows_HFB_medium_fisher,...
    1:length(all_windows_Alpha_medium_fisher),all_windows_Alpha_medium_fisher,...
    1:length(all_windows_Beta1_medium_fisher),all_windows_Beta1_medium_fisher,...
    1:length(all_windows_Beta2_medium_fisher),all_windows_Beta2_medium_fisher,...
    1:length(all_windows_Delta_medium_fisher),all_windows_Delta_medium_fisher,...
    1:length(all_windows_Theta_medium_fisher),all_windows_Theta_medium_fisher,...   
    1:length(all_windows_Gamma_medium_fisher),all_windows_Gamma_medium_fisher,...
    'LineWidth',2);
title({['Dynamic FC: ' roi1 ' vs ' roi2]; ...
    ['Step size = ' num2str(step_size) ' sec']} ,'Fontsize',12);
xlabel(['Window number (' num2str(window_duration) ' sec windows)']); ylabel(['Correlation (z)']);
set(gca,'Fontsize',14,'Fontweight','bold','LineWidth',2,'TickDir','out','box','off');
set(gcf,'color','w');
legend('HFB','α','β1','β2','δ','θ','γ','Location','southeast')
pause; close;

% dFC cross-correlation of frequencies
all_windows_allfreqs=[all_windows_Delta_medium_fisher all_windows_Theta_medium_fisher all_windows_Alpha_medium_fisher ...
    all_windows_Beta1_medium_fisher all_windows_Beta2_medium_fisher all_windows_Gamma_medium_fisher all_windows_HFB_medium_fisher];

xcorr_allfreqs=corrcoef(all_windows_allfreqs);

FigHandle = figure(1);
set(FigHandle,'Position',[50, 50, 700, 600]);
set(gcf,'color','w');
imagesc(xcorr_allfreqs,[-1 1]); h=colorbar('vert'); colormap jet
set(h,'fontsize',16);
set(get(h,'title'),'string','r');
set(gca,'XTickLabel',{'δ','θ', 'α','β1','β2','γ','HFB'},'Fontsize',12)
set(gca,'YTickLabel',{'δ','θ', 'α','β1','β2','γ','HFB'},'Fontsize',12)
title(['Dynamic FC cross-correlation of frequencies'])

end

