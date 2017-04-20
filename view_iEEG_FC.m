Patient=input('Patient: ','s');
runname=input('Run (e.g. 2): ','s');
hemi=input('Hemisphere (r or l): ','s');

%% Load correlation matrix
globalECoGDir=getECoGSubDir;
cd([globalECoGDir '/Rest/' Patient '/Run' runname]);
load('HFB_medium_corr.mat');

fsDir=getFsurfSubDir();
cd([fsDir '/' Patient '/elec_recon']);
coords=dlmread([Patient '.PIALVOX'],' ',2,0);
cd electrode_spheres;
mkdir('SBCA/figs');

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
   elecColors=HFB_medium_corr(:,elec);
   elecColors(elec)=[];
curr_elecNames=elecNames;
curr_elecNames(elec)=[];

 cfg=[];
cfg.view=[hemi 'omni'];
cfg.elecUnits='r';
cfg.pullOut=3;
cfg.title=[elec_name];  
cfg.showLabels='n';
cfg.elecNames=curr_elecNames;
cfg.elecColors=elecColors;
cfg.elecColorScale='minmax';
% cfg.elecShape='sphere';
% cfg.elecSize=2;
cfgOut=plotPialSurf(Patient,cfg);
  print('-opengl','-r300','-dpng',strcat([pwd,filesep,'SBCA',filesep,'figs',filesep,'iEEG_FC_',elec_name,'_run' runname]));
  close;
end