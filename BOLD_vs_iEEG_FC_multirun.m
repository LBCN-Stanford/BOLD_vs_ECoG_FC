% must first run iEEG_FC.m

Patient=input('Patient: ','s');
bold_runname=input('BOLD Run (e.g. 2): ','s');
rest=input('Rest(1) Sleep(0) 7heaven (2)? ','s');
%ecog_runname=input('ECoG Run (e.g. 2): ','s');

%freq=input('HFB 0.1-1Hz (1) alpha (2) beta1 (3) beta2 (4) Gamma (5) Delta (6) Theta (7) all (8) ','s');
plot_all=input('Plot all electrodes (1) or one seed (0)? ','s');

if plot_all=='0'
    elec_number=input('electrode number (iElvis order): ');
end

bold_run_num=['run' bold_runname];
%ecog_run_num=['run' ecog_runname];

if rest=='1'
    Rest='Rest';
elseif rest=='0'
    Rest='Sleep';
elseif rest=='2'
    Rest='7heaven';
end

%% defaults
BOLD_run=['run1'];
fsDir=getFsurfSubDir();

%% Load BOLD data and make correlation matrix (iElvis order)
%Load channel name-number mapping
cd([fsDir '/' Patient '/elec_recon']);
[channumbers_iEEG,chanlabels]=xlsread('channelmap.xls');

cd([fsDir '/' Patient '/elec_recon/electrode_spheres']);

for i=1:length(chanlabels)
    elec_num=num2str(i);
    BOLD_ts(:,i)=load(['elec' elec_num BOLD_run '_ts_FSL.txt']);
end

%% Make BOLD correlation matrix
BOLD_bad=find(BOLD_ts(1,:)==0);
BOLD_ts(:,BOLD_bad)=NaN;


%% Load correlation matrix
globalECoGDir=getECoGSubDir;
if rest=='1'
cd([globalECoGDir '/Rest/' Patient]);
elseif rest=='0'
    cd([globalECoGDir '/Sleep/' Patient]);
elseif rest=='2'
    cd([globalECoGDir '/7heaven/' Patient]);
end
run_list=load('runs.txt');

%% Load channel name-number mapping (iEEG vs iElvis)
cd([fsDir '/' Patient '/elec_recon']);
[channumbers_iEEG,chanlabels]=xlsread('channelmap.xls');

% Load channel names (in freesurfer/elec recon order)
chan_names=importdata([Patient '.electrodeNames'],' ');
fs_chanlabels={};


cd([fsDir '/' Patient '/elec_recon']);
coords=dlmread([Patient '.PIALVOX'],' ',2,0);

parcOut=elec2Parc_v2([Patient],'DK',0);
elecNames = parcOut(:,1);

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
    
%% loop through runs
 for i=1:length(run_list)
          HFB_slow_corr=[]; HFB_slow_mat=[]; curr_bad=[]; all_bad_indices=[]; bad_iElvis=[]; bad_chans=[];
         curr_run=num2str(run_list(i));
cd([globalECoGDir filesep Rest '/' Patient '/Run' curr_run]);

% Load iEEG correlation matrix (in iElvis order)
% load('HFB_corr.mat');
% load('HFB_medium_corr.mat');
% load('alpha_medium_corr.mat');
% load('Beta1_medium_corr.mat');
% load('Beta2_medium_corr.mat');
% load('Theta_medium_corr.mat');
% load('Delta_medium_corr.mat');
% load('Gamma_medium_corr.mat');
% load('SCP_medium_corr.mat');
HFB_slow_corr=load('HFB_slow_corr.mat');

% fisher transform
HFB_slow_mat(:,:,i)=fisherz(HFB_slow_corr);
%HFB_medium_mat=fisherz(HFB_medium_corr);
% HFB_mat=fisherz(HFB_corr);

% load bad indices (iEEG order)
curr_bad=load('all_bad_indices.mat');

% Remove bad indices (convert from iEEG to iElvis order)
% convert bad indices to iElvis
for i=1:length(all_bad_indices)
    ind_iElvis=find(iElvis_to_iEEG_chanlabel==all_bad_indices(i));
    if isempty(ind_iElvis)~=1
    bad_iElvis(i,:)=ind_iElvis;
    end
end
bad_chans=bad_iElvis(find(bad_iElvis>0));
%ignoreChans=[elecNames(bad_chans)];
 
 
%% change bad chans to NaN in iEEG FC matrices
HFB_slow_mat(bad_chans,:,i)=NaN; HFB_slow_mat(:,bad_chans,i)=NaN;

 end

%% change bad chans to NaN in BOLD FC matrix
 %BOLD_mat(bad_chans,:)=NaN; BOLD_mat(:,bad_chans)=NaN;
 
if plot_all=='0'
   coords=1;
   elec=elec_number;
end

iEEG_elec_vals=HFB_slow_mat(:,elec);
BOLD_elec_vals=BOLD_mat(:,elec);
curr_elecNames=elecNames;
% remove NaNs + inf
curr_elecNames([bad_chans; elec])=[];
to_remove=find(isnan(iEEG_elec_vals)==1);
iEEG_elec_vals(elec)=[];
BOLD_elec_vals(elec)=[];
% curr_elecNames{elec}={};
% for j=1:length(to_remove)
% curr_elecNames{to_remove(j)}={};
% end
%curr_elecNames=curr_elecNames(~cellfun(@isempty,curr_elecNames));  
iEEG_scatter=iEEG_elec_vals(~isnan(iEEG_elec_vals));
BOLD_scatter=BOLD_elec_vals(~isnan(BOLD_elec_vals));



% for i=1:length(coords);
% 
%    elec_num=num2str(i);
%    
%    
%            
% elec_name=char(parcOut(i,1));  
%    elecColors_HFBslow=HFB_slow_corr(:,i);
%    
%    
% curr_elecNames=elecNames;
% curr_elecNames([bad_chans; i])=[];


    
 

      



