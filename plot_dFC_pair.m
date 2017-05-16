% plot sliding-window dFC for a pair of regions - BOLD

Patient=input('Patient: ','s');
BOLD=input('BOLD (1) or iEEG (2): ','s');
if BOLD=='2'
   frequency=input('HFB 0.1-1Hz (1) or HFB <0.1 Hz (2): ','s'); 
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

for HFB_slow_chan=1:size(HFB,1)
    HFB_slow_ts(:,HFB_slow_chan)=HFB_slow(HFB_slow_chan,:)';      
end

for HFB_medium_chan=1:size(HFB,1)
    HFB_medium_ts(:,HFB_medium_chan)=HFB_medium(HFB_medium_chan,:)';      
end

for Alpha_medium_chan=1:size(HFB,1)
    Alpha_medium_ts(:,Alpha_medium_chan)=Alpha_medium(Alpha_medium_chan,:)';      
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
HFB_medium_iElvis=NaN(size(HFB_medium_ts,1),length(chanlabels));
alpha_medium_iElvis=NaN(size(Alpha_medium_ts,1),length(chanlabels));

for i=1:length(chanlabels);
    curr_iEEG_chan=channumbers_iEEG(i);
    new_ind=iEEG_to_iElvis_chanlabel(i);
    HFB_slow_iElvis(:,new_ind)=HFB_slow_ts(:,curr_iEEG_chan);
    HFB_medium_iElvis(:,new_ind)=HFB_medium_ts(:,curr_iEEG_chan);
    alpha_medium_iElvis(:,new_ind)=Alpha_medium_ts(:,curr_iEEG_chan);
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
    
    if frequency=='1'
    roi1_ts=HFB_medium_ts(:,roi1_iEEG_num);   
    roi2_ts=HFB_medium_ts(:,roi2_iEEG_num);   
    
elseif frequency=='2'
     roi1_ts=HFB_slow_ts(:,roi1_iEEG_num);   
    roi2_ts=HFB_slow_ts(:,roi2_iEEG_num);  
    end
end

%% Static FC
static_fc=corr(roi1_ts,roi2_ts);

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



%% Normalize time series
roi1_ts_norm=(roi1_ts-mean(roi1_ts))/std(roi1_ts);
roi2_ts_norm=(roi2_ts-mean(roi2_ts))/std(roi2_ts);

%% Plots
if BOLD=='iEEG'
if frequency=='1'
    freq=['HFB (0.1-1 Hz)'];
elseif frequency=='2'
        freq=['HFB (<0.1 Hz)'];
end
else
    freq=[''];
end

if BOLD=='BOLD'
window_duration=BOLD_window_duration;
elseif BOLD=='iEEG'
    window_duration=iEEG_window_duration;
end

% Static FC
FigHandle = figure('Position', [200, 600, 1200, 800]);
figure(1)
subplot(2,1,1);
title({[BOLD ' ' freq ': ' roi1 ' vs ' roi2]; ['r = ' num2str(static_fc)]} ,'Fontsize',12);
xlabel(['Time']); ylabel(['Signal']);
set(gca,'Fontsize',14,'Fontweight','bold','LineWidth',2,'TickDir','out','box','off');
hold on;
plot(1:length(roi1_ts),roi1_ts_norm,1:length(roi2_ts),roi2_ts_norm,'LineWidth',2);

hold on;

% Dynamic FC
subplot(2,1,2);
%set(gca,'Fontsize',14,'Fontweight','bold','LineWidth',2,'TickDir','out','box','off');
%hold on;
plot(1:length(all_windows_fisher),all_windows_fisher,'LineWidth',2);
title({['Dynamic FC: ' roi1 ' vs ' roi2]; ['FCV = ' num2str(std(all_windows_fisher))]} ,'Fontsize',12);
xlabel(['Window number (' num2str(window_duration) ' sec windows)']); ylabel(['Correlation (z)']);
set(gca,'Fontsize',14,'Fontweight','bold','LineWidth',2,'TickDir','out','box','off');
pause; close;



