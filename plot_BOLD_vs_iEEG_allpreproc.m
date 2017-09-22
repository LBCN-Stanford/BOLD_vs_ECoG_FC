% must first run BOLD_vs_ECoG_FC_corr_iElvis.m with GSR, aCompCor, AROMA
% dFC_preproc_list.txt file should contain subject names (column 1), ECoG run number (column 2), and electrode number (column 3)

%Patient=input('Patient: ','s');
bold_runname=input('BOLD Run (e.g. 2): ','s');
ecog_runname=input('ECoG Run (e.g. 2): ','s');
% hemi=input('Hemisphere (r or l): ','s');
depth=input('depth(1) or subdural(0)? ','s');
region=input('Seed location (e.g. mPFC) ','s');
%freq=input('HFB 0.1-1Hz (1) or alpha (2) or HFB <0.1Hz (3) or SCP (4) ','s');
depth=str2num(depth);
bold_run_num=['run' bold_runname];
ecog_run_num=['run' ecog_runname];

globalECoGDir=getECoGSubDir;
cd([globalECoGDir '/Rest']);
mkdir('Figs');
cd Figs;
mkdir('DMN_Core'); cd ..
