Patient=input('Patient: ','s');
runs=input('run (e.g. run1): ','s');
hemi=input('Hemisphere (r or l): ','s');
[total_runs y]=size(runs);
Runs=cellstr(runs);

globalECoGDir=getECoGSubDir;
fsDir=getFsurfSubDir();
cd([fsDir '/' Patient '/elec_recon']);
coords=dlmread([Patient '.PIALVOX'],' ',2,0);
cd electrode_spheres;
mkdir('SBCA/figs');
mkdir('SBCA/figs/BOLD');

parcOut=elec2Parc([Patient]);
elecNames = cell(length(parcOut),1);
if hemi=='r'
    Hemi='R';
elseif hemi=='l'
    Hemi='L';
end


for run=1:total_runs;
    run_num=runs;
for elec=1:length(coords);
elec_num=num2str(elec);
elec_name=char(parcOut(elec,1));
    elec_ts=load(['elec' elec_num run_num '_ts_PIALVOX.txt']);    
    if elec_ts(1)~=0 % ignore WM electrodes
        
% Make color matrix
color_matrix = ones(length(parcOut),3)*0.5; % make all electrodes gray
color_matrix(elec,:)=0;

cfg=[];
cfg.view=[hemi 'omni'];
cfg.olayUnits='z';
cfg.pullOut=3;
cfg.title=[elec_name]
%cfg.elecColorScale =[0 1];
cfg.onlyShow={elec_name};
%cfg.elecColors= color_matrix(:,1:3);   
cfg.pialOverlay=[fsDir '/' Patient '/elec_recon/electrode_spheres/SBCA/elec' elec_num run_num '_' Hemi 'H.mgh']
cfgOut=plotPialSurf(Patient,cfg);
print('-opengl','-r300','-dpng',strcat([pwd,filesep,'SBCA',filesep,'figs',filesep,'BOLD',filesep,'BOLD_FC_',elec_name]));
close;
    end
end
end