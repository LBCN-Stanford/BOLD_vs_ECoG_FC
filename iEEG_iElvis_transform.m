function [iEEG_to_iElvis_chanlabel, iElvis_to_iEEG_chanlabel, chanlabels, channumbers_iEEG,elecNames] = iEEG_iElvis_transform(Patient,hemi,depth)


globalECoGDir=getECoGSubDir;
fsDir=getFsurfSubDir();

%% Create transformation vector for iElvis labels
parcOut=elec2Parc_v2([Patient],'DK',0);
elecNames = parcOut(:,1);
cd([fsDir '/' Patient '/elec_recon']);
[channumbers_iEEG,chanlabels]=xlsread('channelmap.xls');
% Load channel names (in freesurfer/elec recon order)
chan_names=importdata([Patient '.electrodeNames'],' ');

if depth=='0'
for i=1:length(parcOut)
new_elec=strcat(hemi,parcOut(i,1));
fs_chanlabels(i,:)=new_elec;
end
elseif depth=='1'
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

% create iEEG to iElvis chanlabel transformation vector
for i=1:length(chanlabels)
    iEEG_to_iElvis_chanlabel(i,:)=strmatch(chanlabels(i),fs_chanlabels,'exact');    
end
    for i=1:length(chanlabels)
iElvis_to_iEEG_chanlabel(i,:)=channumbers_iEEG(strmatch(fs_chanlabels(i,1),chanlabels,'exact'));
    end
    
    