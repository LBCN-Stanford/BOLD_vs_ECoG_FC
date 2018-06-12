% must first run iEEG_FC.m

Patient=input('Patient: ','s');
bold_runname=input('BOLD Run (e.g. 2): ','s');
rest=input('Rest(1) Sleep(0) 7heaven (2)? ','s');
ecog_runname=input('ECoG Run (e.g. 2): ','s');

%freq=input('HFB 0.1-1Hz (1) alpha (2) beta1 (3) beta2 (4) Gamma (5) Delta (6) Theta (7) all (8) ','s');
plot_all=input('Plot all electrodes (1) or one seed (0)? ','s');

if plot_all=='0'
    elec_number=input('electrode number (iElvis order): ','s');
end

bold_run_num=['run' bold_runname];
ecog_run_num=['run' ecog_runname];

if rest=='1'
    Rest='Rest';
elseif rest=='0'
    Rest='Sleep';
elseif rest=='2'
    Rest='7heaven';
end

%% defaults
BOLD_run=['run1'];

%% Load BOLD data and make correlation matrix (iElvis order)
cd([fsDir '/' Patient '/elec_recon/electrode_spheres']);

for i=1:length(chanlabels)
    elec_num=num2str(i);
    BOLD_ts(:,i)=load(['elec' elec_num BOLD_run '_ts_FSL.txt']);
end

%% Make BOLD correlation matrix

%% Load correlation matrix
globalECoGDir=getECoGSubDir;
if rest=='1'
cd([globalECoGDir '/Rest/' Patient '/Run' ecog_runname]);
elseif rest=='0'
    cd([globalECoGDir '/Sleep/' Patient '/Run' ecog_runname]);
elseif rest=='2'
    cd([globalECoGDir '/7heaven/' Patient '/Run' ecog_runname]);
end

load('HFB_corr.mat');
load('HFB_medium_corr.mat');
load('alpha_medium_corr.mat');
load('Beta1_medium_corr.mat');
load('Beta2_medium_corr.mat');
load('Theta_medium_corr.mat');
load('Delta_medium_corr.mat');
load('Gamma_medium_corr.mat');
load('SCP_medium_corr.mat');
load('HFB_slow_corr.mat');

load('all_bad_indices.mat');


fsDir=getFsurfSubDir();
cd([fsDir '/' Patient '/elec_recon']);
coords=dlmread([Patient '.PIALVOX'],' ',2,0);
cd electrode_spheres;
mkdir('SBCA/figs');
mkdir('SBCA/figs/iEEG');
mkdir(['SBCA/figs/iEEG/iEEG_BOLD_HFB']);
mkdir(['SBCA/figs/iEEG_BOLD_HFB_medium']);
mkdir(['SBCA/figs/iEEG_BOLD_Gamma_medium']);
mkdir(['SBCA/figs/iEEG_BOLD_Beta2_medium']);
mkdir(['SBCA/figs/iEEG_BOLD_Beta1_medium']);
mkdir(['SBCA/figs/iEEG_BOLD_Alpha_medium']);
mkdir(['SBCA/figs/iEEG_BOLD_Theta_medium']);
mkdir(['SBCA/figs/iEEG_BOLD_Delta_medium']);
mkdir(['SBCA/figs/iEEG_BOLD_alpha_medium']);
mkdir(['SBCA/figs/iEEG_BOLD_SCP']);
mkdir(['SBCA/figs/iEEG_BOLD_HFB_slow']);
mkdir(['SBCA/figs/iEEG_Yeo_HFB_medium']);
mkdir(['SBCA/figs/iEEG_IndiPar_HFB_medium']);

parcOut=elec2Parc_v2([Patient],'DK',0);
elecNames = parcOut(:,1);


%% Remove bad indices (convert from iEEG to iElvis order)

% Load channel name-number mapping
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

% create iEEG to iElvis chanlabel transformation vector
for i=1:length(chanlabels)
    iEEG_to_iElvis_chanlabel(i,:)=strmatch(chanlabels(i),fs_chanlabels(:,1),'exact');    
end
    for i=1:length(chanlabels)
iElvis_to_iEEG_chanlabel(i,:)=channumbers_iEEG(strmatch(fs_chanlabels(i,1),chanlabels,'exact'));
    end

% convert bad indices to iElvis
for i=1:length(all_bad_indices)
    ind_iElvis=find(iElvis_to_iEEG_chanlabel==all_bad_indices(i));
    if isempty(ind_iElvis)~=1
    bad_iElvis(i,:)=ind_iElvis;
    end
end

bad_chans=bad_iElvis(find(bad_iElvis>0));
ignoreChans=[elecNames(bad_chans)];


cd electrode_spheres;

if plot_all=='0'
   coords=1;
   elec=elec_number;
end

for elec=1:length(coords);

   elec_num=num2str(elec);
   
   
           
elec_name=char(parcOut(elec,1));  
   elecColors_HFBslow=HFB_slow_corr(:,elec);
   
   
curr_elecNames=elecNames;
curr_elecNames([bad_chans; elec])=[];


    
 

      




end