% must first run iEEG_FC.m

Patient=input('Patient: ','s');
runname=input('Run (e.g. 2): ','s');
hemi=input('Hemisphere (r or l): ','s');
iEEG=input('iEEG only (1) or iEEG & BOLD (2): ','s');
depth=input('depth(1) or subdural(0)? ','s');
depth=str2num(depth);
run_num=['run' runname];

%% Load correlation matrix
globalECoGDir=getECoGSubDir;
cd([globalECoGDir '/Rest/' Patient '/Run' runname]);
load('HFB_medium_corr.mat');
load('alpha_medium_corr.mat');

fsDir=getFsurfSubDir();
cd([fsDir '/' Patient '/elec_recon']);
coords=dlmread([Patient '.PIALVOX'],' ',2,0);
cd electrode_spheres;
mkdir('SBCA/figs');
mkdir('SBCA/figs/iEEG');
mkdir('SBCA/figs/iEEG_BOLD_HFB');
mkdir('SBCA/figs/iEEG_BOLD_alpha');

parcOut=elec2Parc([Patient]);
elecNames = parcOut(:,1);
if hemi=='r'
    Hemi='R';
elseif hemi=='l'
    Hemi='L';
end

for elec=1:length(coords);
   elec_num=num2str(elec);
elec_name=char(parcOut(elec,1)); 
   elecColors_HFB=HFB_medium_corr(:,elec);
   elecColors_HFB(elec)=[];
   elecColors_alpha=alpha_medium_corr(:,elec);
   elecColors_alpha(elec)=[];
curr_elecNames=elecNames;
curr_elecNames(elec)=[];

if iEEG=='1';
 cfg=[];
cfg.view=[hemi 'omni'];
cfg.elecUnits='r';
cfg.pullOut=3;
cfg.title=[elec_name];  
cfg.showLabels='n';
cfg.elecNames=curr_elecNames;
cfg.elecColors=elecColors_HFB;
%cfg.pialOverlay=[fsDir '/' Patient '/elec_recon/electrode_spheres/SBCA/elec' elec_num 'run1_' Hemi 'H.mgh']
cfg.elecColorScale='minmax';
% cfg.elecShape='sphere';
% cfg.elecSize=2;
cfgOut=plotPialSurf(Patient,cfg);
  print('-opengl','-r300','-dpng',strcat([pwd,filesep,'SBCA',filesep,'figs',filesep,'iEEG',filesep,'iEEG_FC_',elec_name,'_run' runname]));
  close;
  
elseif iEEG=='2'    
        if depth==0
            elec_ts=load([fsDir '/' Patient '/elec_recon/electrode_spheres/elec' elec_num run_num '_ts_GSR.txt']);   
    elseif depth==1
        elec_ts=load([fsDir '/' Patient '/elec_recon/electrode_spheres/elec' elec_num run_num '_ts_FSL.txt']);
        end    
          
    if elec_ts(1)~=0
     cfg=[];
cfg.view=[hemi 'omni'];
cfg.elecUnits='r';
cfg.pullOut=3;
cfg.title=[elec_name];  
cfg.showLabels='n';
cfg.elecNames=curr_elecNames;
cfg.elecColors=elecColors_HFB;
cfg.pialOverlay=[fsDir '/' Patient '/elec_recon/electrode_spheres/SBCA/elec' elec_num 'run1_' Hemi 'H.mgh']
cfg.elecColorScale='minmax';
cfg.olayUnits='z';
% cfg.elecShape='sphere';
% cfg.elecSize=2;
cfgOut=plotPialSurf(Patient,cfg);
  print('-opengl','-r300','-dpng',strcat([pwd,filesep,'SBCA',filesep,'figs',filesep,'iEEG_BOLD_HFB',filesep,'HFB_iEEG_FC_',elec_name,'_run' runname]));
  close;
  
      cfg=[];
cfg.view=[hemi 'omni'];
cfg.elecUnits='r';
cfg.pullOut=3;
cfg.title=[elec_name];  
cfg.showLabels='n';
cfg.elecNames=curr_elecNames;
cfg.elecColors=elecColors_alpha;
cfg.pialOverlay=[fsDir '/' Patient '/elec_recon/electrode_spheres/SBCA/elec' elec_num 'run1_' Hemi 'H.mgh']
cfg.elecColorScale='minmax';
cfg.olayUnits='z';
% cfg.elecShape='sphere';
% cfg.elecSize=2;
cfgOut=plotPialSurf(Patient,cfg);
  print('-opengl','-r300','-dpng',strcat([pwd,filesep,'SBCA',filesep,'figs',filesep,'iEEG_BOLD_alpha',filesep,'alpha_iEEG_FC_',elec_name,'_run' runname]));
  close; 
  
    end
end 
end