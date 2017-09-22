% must first run iEEG_FC.m

Patient=input('Patient: ','s');
bold_runname=input('BOLD Run (e.g. 2): ','s');
rest=input('Rest(1) Sleep(0) 7heaven (2)? ','s');
ecog_runname=input('ECoG Run (e.g. 2): ','s');
hemi=input('Hemisphere (r or l): ','s');
iEEG=input('iEEG only (1) or iEEG & BOLD (2) or iEEG & Yeo atlas (3) or iEEG & IndiPar (4): ','s');
view_bad=input('show bad channels (1) or hide (0)? ','s');
depth=input('depth(1) or subdural(0)? ','s');
freq=input('HFB 0.1-1Hz (1) alpha (2) beta1 (3) beta2 (4) Gamma (5) Delta (6) Theta (7) ','s');
depth=str2num(depth);
bold_run_num=['run' bold_runname];
ecog_run_num=['run' ecog_runname];

if rest=='1'
    Rest='Rest';
elseif rest=='0'
    Rest='Sleep';
elseif rest=='2'
    Rest='7heaven';
end
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
if hemi=='r'
    Hemi='R';
elseif hemi=='l'
    Hemi='L';
end

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
if view_bad=='0'
for i=1:length(all_bad_indices)
    ind_iElvis=find(iElvis_to_iEEG_chanlabel==all_bad_indices(i));
    if isempty(ind_iElvis)~=1
    bad_iElvis(i,:)=ind_iElvis;
    end
end
bad_chans=bad_iElvis(find(bad_iElvis>0));
ignoreChans=[elecNames(bad_chans)];
else
   bad_chans=[]; ignoreChans=[]; 
end

cd electrode_spheres;

for elec=1:length(coords);
   elec_num=num2str(elec);
   
   if isempty(find(bad_chans==elec))==1 %only plot good chans

       
           
elec_name=char(parcOut(elec,1)); 
    elecColors_HFB=HFB_corr(:,elec);
    elecColors_HFB(bad_chans)=[];
   elecColors_HFB_medium=HFB_medium_corr(:,elec);
   elecColors_HFB_medium(bad_chans)=[];  
   elecColors_alpha_medium=alpha_medium_corr(:,elec);
   elecColors_alpha_medium(bad_chans)=[];
   elecColors_Beta1_medium=Beta1_medium_corr(:,elec);
   elecColors_Beta1_medium(bad_chans)=[];
   elecColors_Beta2_medium=Beta2_medium_corr(:,elec);
   elecColors_Beta2_medium(bad_chans)=[];
   elecColors_Gamma_medium=Gamma_medium_corr(:,elec);
   elecColors_Gamma_medium(bad_chans)=[];
   elecColors_Theta_medium=Theta_medium_corr(:,elec);
   elecColors_Theta_medium(bad_chans)=[];
   elecColors_Delta_medium=Delta_medium_corr(:,elec);
   elecColors_Delta_medium(bad_chans)=[];   
   elecColors_SCP=SCP_medium_corr(:,elec);  
   elecColors_HFBslow=HFB_slow_corr(:,elec);
   
   
curr_elecNames=elecNames;
curr_elecNames([bad_chans; elec])=[];

if iEEG=='1'
    
 
     %if elec_ts(1)~=0
     %cfg=[];
      if view_bad=='0'
 cfg.ignoreChans=ignoreChans;
      end   

cfg.view=[hemi 'omni'];
cfg.elecUnits='r';
cfg.pullOut=3;
cfg.title=[elec_name];  
cfg.showLabels='n';
cfg.elecNames=curr_elecNames;
cfg.elecColors=elecColors_HFB_medium;
%cfg.pialOverlay=[fsDir '/' Patient '/elec_recon/electrode_spheres/SBCA/elec' elec_num 'run1_' Hemi 'H.mgh']
% cfg.elecColorScale='minmax';
cfg.elecColorScale=[-0.1 0.4];
cfg.elecColors(find(cfg.elecColors==1))=[];
% cfg.elecShape='sphere';
% cfg.elecSize=2;
cfgOut=plotPialSurf(Patient,cfg);
if freq=='2'
  print('-opengl','-r300','-dpng',strcat([pwd,filesep,'SBCA',filesep,'figs',filesep,'iEEG',filesep,[rest '_'],'Alpha_iEEG_FC_',elec_name,'_run' ecog_runname]));
elseif freq=='1'
    print('-opengl','-r300','-dpng',strcat([pwd,filesep,'SBCA',filesep,'figs',filesep,'iEEG',filesep,[rest '_'],'HFB_iEEG_FC_',elec_name,'_run' ecog_runname]));
    elseif freq=='3'
    print('-opengl','-r300','-dpng',strcat([pwd,filesep,'SBCA',filesep,'figs',filesep,'iEEG',filesep,[rest '_'],'Beta1_iEEG_FC_',elec_name,'_run' ecog_runname]));
end
    close;
   
  
elseif iEEG=='2' || iEEG=='3' || iEEG=='4'   
        if depth==0
            elec_ts=load([fsDir '/' Patient '/elec_recon/electrode_spheres/elec' elec_num bold_run_num '_ts_GSR.txt']);   
    elseif depth==1
        elec_ts=load([fsDir '/' Patient '/elec_recon/electrode_spheres/elec' elec_num bold_run_num '_ts_FSL.txt']);
        end    
          
    if elec_ts(1)~=0
     cfg=[];
      if view_bad=='0'
 cfg.ignoreChans=ignoreChans;
      end   
cfg.view=[hemi 'omni'];
cfg.elecUnits='r';
cfg.pullOut=3;
cfg.title=[elec_name];  
cfg.showLabels='n';
cfg.elecNames=curr_elecNames;
if freq=='1'
cfg.elecColors=elecColors_HFB_medium;
cfg.elecColorScale=[-0.1 0.4];
elseif freq=='2'
   cfg.elecColors=elecColors_alpha_medium; 
   cfg.elecColorScale=[-0.1 0.4];
elseif freq=='3'
    cfg.elecColors=elecColors_Beta1_medium;
    cfg.elecColorScale=[-0.1 0.4];    
elseif freq=='4'
    cfg.elecColors=elecColors_Beta2_medium;
    cfg.elecColorScale=[-0.1 0.4];
elseif freq=='5'
    cfg.elecColors=elecColors_Gamma_medium;
    cfg.elecColorScale=[-0.1 0.4];
   elseif freq=='6'
    cfg.elecColors=elecColors_Delta_medium;
    cfg.elecColorScale=[0.2 0.8]; 
    elseif freq=='7'
    cfg.elecColors=elecColors_Theta_medium;
    cfg.elecColorScale=[0.2 0.8];
end
cfg.elecColors(find(cfg.elecColors==1))=[];
if iEEG=='2'
cfg.pialOverlay=[fsDir '/' Patient '/elec_recon/electrode_spheres/SBCA/elec' elec_num bold_run_num '_' Hemi 'H.mgh']
elseif iEEG=='3'
    [averts, label, col]=read_annotation(fullfile(getFsurfSubDir(),'fsaverage','label',[ hemi 'h.Yeo2011_7Networks_N1000.annot']));
    cfg.overlayParcellation='Y7';
    %% For potting individual networks
%     cfg.opaqueness=1;
%     id=8; %DAN=4; Salience=5; FPCN=7; DMN=8
%     parc_col = .7.*255.*ones(size(col.table(:,1:3)));
%     parc_col(id,:)=col.table(id,1:3);
%     cfg.parcellationColors = parc_col;
elseif iEEG=='4'
    load('DMN_DAN_FPN_colors.mat')
cfg.parcellationColors=DMN_DAN_FPN_colors;
annot=[fsDir '/' Patient '/label/' hemi 'h_parc_result_' bold_run_num '.annot'];
cfg.overlayParcellation=annot;
end
%cfg.elecColorScale='minmax';

cfg.olayUnits='z';
% cfg.elecShape='sphere';
% cfg.elecSize=2;
cfgOut=plotPialSurf(Patient,cfg);
if iEEG=='2'
if freq=='1'
  print('-opengl','-r300','-dpng',strcat([pwd,filesep,'SBCA',filesep,'figs',filesep,'iEEG_BOLD_HFB_medium',filesep,[Rest '_'],'HFB_medium_iEEG_FC_',elec_name,'_run' ecog_runname]));
elseif freq=='2'
    print('-opengl','-r300','-dpng',strcat([pwd,filesep,'SBCA',filesep,'figs',filesep,'iEEG_BOLD_alpha_medium',filesep,[Rest '_'],'alpha_medium_iEEG_FC_',elec_name,'_run' ecog_runname]));
elseif freq=='3'
    print('-opengl','-r300','-dpng',strcat([pwd,filesep,'SBCA',filesep,'figs',filesep,'iEEG_BOLD_Beta1_medium',filesep,[Rest '_'],'Beta1_medium_iEEG_FC_',elec_name,'_run' ecog_runname]));
    %print('-opengl','-r300','-dpng',strcat([pwd,filesep,'SBCA',filesep,'figs',filesep,'iEEG_BOLD_HFB_slow',filesep,[Rest '_'],'HFB_slow_iEEG_FC_',elec_name,'_run' ecog_runname]));
elseif freq=='4'
    print('-opengl','-r300','-dpng',strcat([pwd,filesep,'SBCA',filesep,'figs',filesep,'iEEG_BOLD_Beta2_medium',filesep,[Rest '_'],'Beta2_medium_iEEG_FC_',elec_name,'_run' ecog_runname]));
    %print('-opengl','-r300','-dpng',strcat([pwd,filesep,'SBCA',filesep,'figs',filesep,'iEEG_BOLD_SCP',filesep,[Rest '_'],'SCP_iEEG_FC_',elec_name,'_run' ecog_runname]));
elseif freq=='5'
    print('-opengl','-r300','-dpng',strcat([pwd,filesep,'SBCA',filesep,'figs',filesep,'iEEG_BOLD_Gamma_medium',filesep,[Rest '_'],'Gamma_medium_iEEG_FC_',elec_name,'_run' ecog_runname]));
    %print('-opengl','-r300','-dpng',strcat([pwd,filesep,'SBCA',filesep,'figs',filesep,'iEEG_BOLD_HFB',filesep,[Rest '_'],'HFB_iEEG_FC_',elec_name,'_run' ecog_runname]));
elseif freq=='6'
    print('-opengl','-r300','-dpng',strcat([pwd,filesep,'SBCA',filesep,'figs',filesep,'iEEG_BOLD_Delta_medium',filesep,[Rest '_'],'Delta_medium_iEEG_FC_',elec_name,'_run' ecog_runname]));
elseif freq=='7'
    print('-opengl','-r300','-dpng',strcat([pwd,filesep,'SBCA',filesep,'figs',filesep,'iEEG_BOLD_Theta_medium',filesep,[Rest '_'],'Theta_medium_iEEG_FC_',elec_name,'_run' ecog_runname]));
end
    close;
if iEEG=='3'
    print('-opengl','-r300','-dpng',strcat([pwd,filesep,'SBCA',filesep,'figs',filesep,'iEEG_Yeo_HFB_medium',filesep,[Rest '_'],'HFB_medium_iEEG_FC_',elec_name,'_run' ecog_runname]));
elseif freq=='2'
    print('-opengl','-r300','-dpng',strcat([pwd,filesep,'SBCA',filesep,'figs',filesep,'iEEG_Yeo_alpha_medium',filesep,[Rest '_'],'alpha_medium_iEEG_FC_',elec_name,'_run' ecog_runname]));
elseif freq=='3'
    print('-opengl','-r300','-dpng',strcat([pwd,filesep,'SBCA',filesep,'figs',filesep,'iEEG_Yeo_Beta1_medium',filesep,[Rest '_'],'Beta1_medium_iEEG_FC_',elec_name,'_run' ecog_runname]));
    %print('-opengl','-r300','-dpng',strcat([pwd,filesep,'SBCA',filesep,'figs',filesep,'iEEG_Yeo_HFB_slow',filesep,[Rest '_'],'HFB_slow_iEEG_FC_',elec_name,'_run' ecog_runname]));
elseif freq=='4'
    print('-opengl','-r300','-dpng',strcat([pwd,filesep,'SBCA',filesep,'figs',filesep,'iEEG_Yeo_Beta2_medium',filesep,[Rest '_'],'Beta2_medium_iEEG_FC_',elec_name,'_run' ecog_runname]));
    %print('-opengl','-r300','-dpng',strcat([pwd,filesep,'SBCA',filesep,'figs',filesep,'iEEG_Yeo_SCP',filesep,[Rest '_'],'SCP_iEEG_FC_',elec_name,'_run' ecog_runname]));
elseif freq=='5'
    print('-opengl','-r300','-dpng',strcat([pwd,filesep,'SBCA',filesep,'figs',filesep,'iEEG_Yeo_Gamma_medium',filesep,[Rest '_'],'Gamma_medium_iEEG_FC_',elec_name,'_run' ecog_runname]));
    %print('-opengl','-r300','-dpng',strcat([pwd,filesep,'SBCA',filesep,'figs',filesep,'iEEG_Yeo_HFB',filesep,[Rest '_'],'HFB_iEEG_FC_',elec_name,'_run' ecog_runname]));
elseif freq=='6'
    print('-opengl','-r300','-dpng',strcat([pwd,filesep,'SBCA',filesep,'figs',filesep,'iEEG_Yeo_Delta_medium',filesep,[Rest '_'],'Delta_medium_iEEG_FC_',elec_name,'_run' ecog_runname]));
elseif freq=='7'
    print('-opengl','-r300','-dpng',strcat([pwd,filesep,'SBCA',filesep,'figs',filesep,'iEEG_Yeo_Theta_medium',filesep,[Rest '_'],'Theta_medium_iEEG_FC_',elec_name,'_run' ecog_runname]));
end
    close;
    end
if iEEG=='4'
      print('-opengl','-r300','-dpng',strcat([pwd,filesep,'SBCA',filesep,'figs',filesep,'iEEG_IndiPar_HFB_medium',filesep,[Rest '_'],'HFB_medium_iEEG_FC_',elec_name,'_run' ecog_runname]));
elseif freq=='2'
    print('-opengl','-r300','-dpng',strcat([pwd,filesep,'SBCA',filesep,'figs',filesep,'iEEG_IndiPar_alpha_medium',filesep,[Rest '_'],'alpha_medium_iEEG_FC_',elec_name,'_run' ecog_runname]));
elseif freq=='3'
    print('-opengl','-r300','-dpng',strcat([pwd,filesep,'SBCA',filesep,'figs',filesep,'iEEG_IndiPar_Beta1_medium',filesep,[Rest '_'],'Beta1_medium_iEEG_FC_',elec_name,'_run' ecog_runname]));
    %print('-opengl','-r300','-dpng',strcat([pwd,filesep,'SBCA',filesep,'figs',filesep,'iEEG_IndiPar_HFB_slow',filesep,[Rest '_'],'HFB_slow_iEEG_FC_',elec_name,'_run' ecog_runname]));
elseif freq=='4'
    print('-opengl','-r300','-dpng',strcat([pwd,filesep,'SBCA',filesep,'figs',filesep,'iEEG_IndiPar_Beta2_medium',filesep,[Rest '_'],'Beta2_medium_iEEG_FC_',elec_name,'_run' ecog_runname]));
    %print('-opengl','-r300','-dpng',strcat([pwd,filesep,'SBCA',filesep,'figs',filesep,'iEEG_IndiPar_SCP',filesep,[Rest '_'],'SCP_iEEG_FC_',elec_name,'_run' ecog_runname]));
elseif freq=='5'
    print('-opengl','-r300','-dpng',strcat([pwd,filesep,'SBCA',filesep,'figs',filesep,'iEEG_IndiPar_Gamma_medium',filesep,[Rest '_'],'Gamma_medium_iEEG_FC_',elec_name,'_run' ecog_runname]));
    %print('-opengl','-r300','-dpng',strcat([pwd,filesep,'SBCA',filesep,'figs',filesep,'iEEG_IndiPar_HFB',filesep,[Rest '_'],'HFB_iEEG_FC_',elec_name,'_run' ecog_runname]));
elseif freq=='6'
    print('-opengl','-r300','-dpng',strcat([pwd,filesep,'SBCA',filesep,'figs',filesep,'iEEG_IndiPar_Delta_medium',filesep,[Rest '_'],'Delta_medium_iEEG_FC_',elec_name,'_run' ecog_runname]));
elseif freq=='7'
    print('-opengl','-r300','-dpng',strcat([pwd,filesep,'SBCA',filesep,'figs',filesep,'iEEG_IndiPar_Theta_medium',filesep,[Rest '_'],'Theta_medium_iEEG_FC_',elec_name,'_run' ecog_runname]));
end
    close;
    end
 
   end
   end
end