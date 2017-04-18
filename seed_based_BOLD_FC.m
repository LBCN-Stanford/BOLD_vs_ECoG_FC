%% Seed-based FC for each electrode location (after extracting electrode ROI time series)
%==========================================================================
% Written by Aaron Kucyi, LBCN, Stanford University
%==========================================================================
Patient=input('Patient: ','s');
runs=input('run (e.g. run1): ','s');
[total_runs y]=size(runs);
Runs=cellstr(runs);

globalECoGDir=getECoGSubDir;
fsDir=getFsurfSubDir();

cd([fsDir '/' Patient '/elec_recon']);
coords=dlmread([Patient '.PIALVOX'],' ',2,0);
cd electrode_spheres;
mkdir('SBCA');

for run=1:total_runs;
    run_num=runs;

%% Regress seed time courses on whole brain (for non-excluded seeds)

for elec=1:length(coords);
    elec_num=num2str(elec);
    elec_ts=load(['elec' elec_num run_num '_ts_PIALVOX.txt']);
    
    if elec_ts(1)~=0
        
       cmd=['fsl_glm -i ../GSR_run1_FSL.nii.gz -d elec' elec_num run_num '_ts_PIALVOX.txt --out_z=SBCA/elec' elec_num run_num '_z --demean']; 
[b,c]=system(cmd);

display(['Done seed-based FC for elec' elec_num run_num]);


%% Convert z map from fMRI to brainmask space
cmd=['flirt -in SBCA/elec' elec_num run_num '_z -applyxfm -init ' ...
     '../func2brainmask_' run_num '.mat -out SBCA/elec' elec_num run_num '_z_brainmask' ...
     ' -paddingsize 0.0 -interp trilinear -ref ../brainmask'];
[b,c]=system(cmd);
display(['Done registration from fMRI to brainmask for elec' elec_num run_num]);

%% Map FC to surface
cmd=['mri_vol2surf --src SBCA/elec' elec_num run_num '_z_brainmask.nii.gz' ...
    ' --reg ../register_' run_num '.dat --out SBCA/elec' elec_num run_num '_LH.mgh' ...
    ' --out_type mgh --hemi lh']
[b,c]=system(cmd);
cmd=['mri_vol2surf --src SBCA/elec' elec_num run_num '_z_brainmask.nii.gz' ...
    ' --reg ../register_' run_num '.dat --out SBCA/elec' elec_num run_num '_RH.mgh' ...
    ' --out_type mgh --hemi rh']
[b,c]=system(cmd);
display(['Done surface registration for elec' elec_num run_num]);

end
end
end