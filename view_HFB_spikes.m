Patient=input('Patient: ','s');
run_num=input('run (e.g. 1): ','s');
hemi=input('hemi (R or L): ','s');
tdt=0; % tdt=1, edf=0

runname=['Run' run_num];
globalECoGDir=getECoGSubDir;
fsDir=getFsurfSubDir();

cd([globalECoGDir '/Rest/' Patient '/' runname]);
mkdir(['HFB_plots']);
parcOut=elec2Parc([Patient]);
elecNames = parcOut(:,1);

% Load HFB data (no temporal filter)
display(['1. Select raw ECoG file']);
raw=spm_eeg_load;
display(['2. Select HFB file']);
HFB=spm_eeg_load;

%% Create transformation vector for iElvis labels
cd([fsDir '/' Patient '/elec_recon']);
[channumbers_iEEG,chanlabels]=xlsread('channelmap.xls');
% Load channel names (in freesurfer/elec recon order)
chan_names=importdata([Patient '.electrodeNames'],' ');

for i=1:length(parcOut)
new_elec=strcat(hemi,parcOut(i,1))
chans(i,:)=new_elec;
end

% create iEEG to iElvis chanlabel transformation vector
for i=1:length(chanlabels)
    iEEG_to_iElvis_chanlabel(i,:)=strmatch(chanlabels(i),chans,'exact');    
end

%% Make plots
cd([globalECoGDir '/Rest/' Patient '/' runname]);
for i=1:length(raw.chanlabels)
    HFB_z=[];
    HFB_z=(HFB(i,:)-mean(HFB(i,:)))/std(HFB(i,:));
    chan_sd=num2str(std(raw(i,:)));
    if isempty(find(HFB.badchannels==i))==1
       bad='good';
    else bad='bad';
    end
    elec_name=chans(iEEG_to_iElvis_chanlabel(i))
    
    FigHandle = figure('Position', [200, 600, 1200, 800]);
   figure(1);
   subplot(2,1,1)
   title(['Channel ' elec_name{1} ' (' bad ') |μV| differences; SD=' chan_sd] , 'Fontsize', 12)
   hold on;
   plot(1:length(diff(raw(i,:))),abs(diff(raw(i,:))));
   xlim([0,length(diff(raw(i,:)))]);
   subplot(2,1,2);
   title(['Channel ' elec_name{1} ' HFB (z-scored); max |z|=' num2str(max(abs(HFB_z)))] , 'Fontsize', 12)
   hold on;
   plot(1:length(HFB_z),HFB_z);
   xlim([0,length(HFB_z)])
   print('-opengl','-r300','-dpng',strcat([pwd,filesep,'HFB_plots/HFB_' elec_name{1}])); 
   close('all');
end
%axis([0,stimulus_onsets_PTB(end)+4,0,4])  


