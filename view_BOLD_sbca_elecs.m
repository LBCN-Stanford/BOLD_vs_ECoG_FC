Patient=input('Patient: ','s');
runs=input('run (e.g. run1): ','s');
[total_runs y]=size(runs);
Runs=cellstr(runs);

globalECoGDir=getECoGSubDir;
fsDir=getFsurfSubDir();

%cd([fsDir '/' Patient '/elec_recon']);


cfg=[];
cfg.view='lomni';
cfg.olayUnits='z';
cfg.pialOverlay=[fsDir '/' Patient '/elec_recon/electrode_spheres/SBCA/elec1run1_LH.mgh']
cfgOut=plotPialSurf(Patient,cfg);