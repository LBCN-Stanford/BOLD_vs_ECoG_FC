function seed_based_BOLD_FC(Patient,depth)

%% Seed-based FC for each electrode location (after extracting electrode ROI time series)
%==========================================================================
% Written by Aaron Kucyi, LBCN, Stanford University
%==========================================================================
%Patient=input('Patient: ','s');
runs='run1';
%runs=input('run (e.g. run1): ','s');
%depth=input('depth(1) or subdural(0)? ','s');
%depth=str2num(depth);

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
    %if depth==0
    elec_ts=load(['elec' elec_num run_num '_ts_GSR.txt']);
    %elseif depth==1
    %   elec_ts=load(['elec' elec_num run_num '_ts_FSL.txt']);
    %end
    
    
    if elec_ts(1)~=0
        
        %if depth==0
       cmd=['fsl_glm -i ../GSR_run1_FSL.nii.gz -d elec' elec_num run_num '_ts_GSR.txt --out_z=SBCA/elec' elec_num run_num '_z_GSR --demean']; 
[b,c]=system(cmd);

       cmd=['fsl_glm -i ../AROMA_run1_FSL.nii.gz -d elec' elec_num run_num '_ts_AROMA.txt --out_z=SBCA/elec' elec_num run_num '_z_AROMA --demean']; 
[b,c]=system(cmd);
       cmd=['fsl_glm -i ../aCompCor_run1_FSL.nii.gz -d elec' elec_num run_num '_ts_aCompCor.txt --out_z=SBCA/elec' elec_num run_num '_z_aCompCor --demean']; 
[b,c]=system(cmd);
        %elseif depth==1
           %cmd=['fsl_glm -i ../GSR_run1_FSL.nii.gz -d elec' elec_num run_num '_ts_FSL.txt --out_z=SBCA/elec' elec_num run_num '_z --demean'];  
%[b,c]=system(cmd);
        %end
display(['Done seed-based FC for elec' elec_num run_num]);


%% Convert z map from fMRI to brainmask space
% GSR
cmd=['flirt -in SBCA/elec' elec_num run_num '_z_GSR -applyxfm -init ' ...
     '../func2brainmask_' run_num '.mat -out SBCA/elec' elec_num run_num '_z_brainmask_GSR' ...
     ' -paddingsize 0.0 -interp trilinear -ref ../brainmask'];
[b,c]=system(cmd);
display(['Done GSR registration from fMRI to brainmask for elec' elec_num run_num]);

% Map FC to surface
cmd=['mri_vol2surf --src SBCA/elec' elec_num run_num '_z_brainmask_GSR.nii.gz' ...
    ' --reg ../register_' run_num '.dat --out SBCA/elec' elec_num run_num '_GSR_LH.mgh' ...
    ' --out_type mgh --hemi lh']
[b,c]=system(cmd);
cmd=['mri_vol2surf --src SBCA/elec' elec_num run_num '_z_brainmask_GSR.nii.gz' ...
    ' --reg ../register_' run_num '.dat --out SBCA/elec' elec_num run_num 'GSR_RH.mgh' ...
    ' --out_type mgh --hemi rh']
[b,c]=system(cmd);

% AROMA
cmd=['flirt -in SBCA/elec' elec_num run_num '_z_AROMA -applyxfm -init ' ...
     '../func2brainmask_' run_num '.mat -out SBCA/elec' elec_num run_num '_z_brainmask_AROMA' ...
     ' -paddingsize 0.0 -interp trilinear -ref ../brainmask'];
[b,c]=system(cmd);
display(['Done AROMA registration from fMRI to brainmask for elec' elec_num run_num]);

% Map FC to surface
cmd=['mri_vol2surf --src SBCA/elec' elec_num run_num '_z_brainmask_AROMA.nii.gz' ...
    ' --reg ../register_' run_num '.dat --out SBCA/elec' elec_num run_num '_AROMA_LH.mgh' ...
    ' --out_type mgh --hemi lh']
[b,c]=system(cmd);
cmd=['mri_vol2surf --src SBCA/elec' elec_num run_num '_z_brainmask_AROMA.nii.gz' ...
    ' --reg ../register_' run_num '.dat --out SBCA/elec' elec_num run_num 'AROMA_RH.mgh' ...
    ' --out_type mgh --hemi rh']
[b,c]=system(cmd);
display(['Done surface registration for elec' elec_num run_num]);

% aCompCor
cmd=['flirt -in SBCA/elec' elec_num run_num '_z_aCompCor -applyxfm -init ' ...
     '../func2brainmask_' run_num '.mat -out SBCA/elec' elec_num run_num '_z_brainmask_aCompCor' ...
     ' -paddingsize 0.0 -interp trilinear -ref ../brainmask'];
[b,c]=system(cmd);
display(['Done aCompCor registration from fMRI to brainmask for elec' elec_num run_num]);

%% Map FC to surface
cmd=['mri_vol2surf --src SBCA/elec' elec_num run_num '_z_brainmask_aCompCor.nii.gz' ...
    ' --reg ../register_' run_num '.dat --out SBCA/elec' elec_num run_num '_aCompCor_LH.mgh' ...
    ' --out_type mgh --hemi lh']
[b,c]=system(cmd);
cmd=['mri_vol2surf --src SBCA/elec' elec_num run_num '_z_brainmask_aCompCor.nii.gz' ...
    ' --reg ../register_' run_num '.dat --out SBCA/elec' elec_num run_num 'aCompCor_RH.mgh' ...
    ' --out_type mgh --hemi rh']
[b,c]=system(cmd);
end
end
end