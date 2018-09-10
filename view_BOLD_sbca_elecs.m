Patient=input('Patient: ','s');
runs=input('run (e.g. run1): ','s');
hemi=input('Hemisphere (r or l): ','s');
depth=input('depth(1) or subdural(0)? ','s');
inflated=input('Pial (1) or Inflated (2) surface? ','s');
plotOnly=input('Plot all (0) or custom electrodes (1) ','s');
to_plot=[14 20 59];
depth=str2num(depth);
[total_runs y]=size(runs);
Runs=cellstr(runs);

globalECoGDir=getECoGSubDir;
fsDir=getFsurfSubDir();
cd([fsDir '/' Patient '/elec_recon']);
coords=dlmread([Patient '.PIALVOX'],' ',2,0);
cd electrode_spheres;
mkdir('SBCA/figs');
mkdir('SBCA/figs/BOLD');

parcOut=elec2Parc_v2([Patient],'DK',0);
elecNames = cell(length(parcOut),1);
if hemi=='r'
    Hemi='R';
elseif hemi=='l'
    Hemi='L';
end

%% for plotting custom electrodes
if plotOnly=='1'
    for run=1:total_runs;
        run_num=runs;
   for elec=1:length(to_plot);
       elec_num=to_plot(elec);
       elec_name=char(parcOut(elec_num,1));
elec_num=num2str(elec_num);

    elec_ts=load(['elec' elec_num run_num '_ts_GSR.txt']);
    if elec_ts(1)~=0 % ignore WM electrodes
  
      color_matrix = ones(length(parcOut),3)*0.5; % make all electrodes gray
color_matrix(elec,:)=0;

cfg=[];
cfg.view=[hemi 'omni'];
cfg.olayUnits='z';
cfg.pullOut=3;
cfg.title=[elec_name]
cfg.onlyShow={elec_name};
cfg.pialOverlay=[fsDir '/' Patient '/elec_recon/electrode_spheres/SBCA/elec' elec_num run_num '_GSR_' Hemi 'H.mgh']
          if inflated=='2'
   cfg.surfType='inflated';
   cfg.olayThresh=3;
end   
cfgOut=plotPialSurf(Patient,cfg);
print('-opengl','-r300','-dpng',strcat([pwd,filesep,'SBCA',filesep,'figs',filesep,'BOLD',filesep,[Patient '_'],[elec_name '_BOLD_FC_'],[ Hemi 'H']]));
close;  
    end
   end
    end
end

%% for plotting all electrodes
if plotOnly=='0'
for run=1:total_runs;
    run_num=runs;
for elec=1:length(coords);
elec_num=num2str(elec);
elec_name=char(parcOut(elec,1));
    elec_ts=load(['elec' elec_num run_num '_ts_GSR.txt']);
    if elec_ts(1)~=0 % ignore WM electrodes
        
% Make color matrix
color_matrix = ones(length(parcOut),3)*0.5; % make all electrodes gray
color_matrix(elec,:)=0;

cfg=[];
cfg.view=[hemi 'omni'];
cfg.olayUnits='z';
cfg.pullOut=3;
cfg.title=[elec_name]
cfg.onlyShow={elec_name};
cfg.pialOverlay=[fsDir '/' Patient '/elec_recon/electrode_spheres/SBCA/elec' elec_num run_num '_GSR_' Hemi 'H.mgh']
          if inflated=='2'
   cfg.surfType='inflated';
   cfg.olayThresh=3;
end   
cfgOut=plotPialSurf(Patient,cfg);
print('-opengl','-r300','-dpng',strcat([pwd,filesep,'SBCA',filesep,'figs',filesep,'BOLD',filesep,[Patient '_'],[elec_name '_BOLD_FC_'],[ Hemi 'H']]));
close;
    end
end
end
end