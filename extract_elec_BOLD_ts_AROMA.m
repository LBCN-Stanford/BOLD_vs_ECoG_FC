%% Extract time series from electrode ROIs (created with mk_electrode_sphere_ROIs.m)
%==========================================================================
% Written by Aaron Kucyi, LBCN, Stanford University
%==========================================================================

%% Must first run mk_electrode_sphere_ROIs.m
% Load FSL functions into MATLAB
setenv('FSLDIR','/usr/share/fsl');
setenv('FSLOUTPUTTYPE','NIFTI_GZ');
Patient=input('Patient: ','s');
runs=input('run (e.g. run1): ','s');
[total_runs y]=size(runs);
Runs=cellstr(runs);

globalECoGDir=getECoGSubDir;
fsDir=getFsurfSubDir();

cd([fsDir '/' Patient '/elec_recon']);
%    load('brainmask_coords.mat');
%     coords=brainmask_coords;
    
coords=dlmread([Patient '.PIALVOX'],' ',2,0);
    
    
%for elec=1:length(coords);
for run=1:total_runs;
% for elec=1:length(coords);
%     elec_num=num2str(elec);
    %run_num=char(runs(run));
    run_num=runs;
% Register electrodes to fs2fsl brain (and binarize)
% cmd=['flirt -in electrode_spheres/elec' elec_num ' -applyxfm -init fs2fsl_' run_num '.mat -out electrode_spheres/elec' elec_num run_num '_fsl -paddingsize 0.0 -interp trilinear -ref fs2fsl_' run_num];
% [b,c]=system(cmd);

%% Remove non brain voxels
% cmd=['fslmaths electrode_spheres/elec' elec_num  'FSL_sphere -mul func_brainmask -bin electrode_spheres/elec' elec_num 'FSL_sphere'];
% [b,c]=system(cmd);
% % cmd=['fslmaths electrode_spheres/elec' elec_num run_num '_fsl -mul fs2fsl_' run_num ' -bin electrode_spheres/elec' elec_num run_num '_fsl'];
% % [b,c]=system(cmd);
% 
% display(['Done removing non-brain voxels for elec' elec_num run_num]);
% 
% end

  %% Remove voxels within ROIs that overlap with other ROIs
% cd electrode_spheres;
% for i=1:length(coords)
%      for j=1:length(coords)
%         
%     elec1=num2str(i); elec2=num2str(j);
%     a=isequal(i,j);
%     if a~=1
%         cmd=['fslmaths elec' elec1 'FSL_sphere -add elec' elec2 'FSL_sphere elec' elec1 'elec' elec2];
%         [b,c]=system(cmd);
%         
%         cmd=['fslmaths elec' elec1 'elec' elec2 ' -mul elec' elec1 'FSL_sphere elec' elec1 'FSL_sphere'];
%         [b,c]=system(cmd);
%         
%         cmd=['fslmaths elec' elec1 'FSL_sphere -uthr 1.5 elec' elec1 'FSL_sphere'];
%         [b,c]=system(cmd);  
%         delete(['elec' elec1 'elec' elec2 '.nii.gz'])
%         
%         display(['Done removing overlap between for electrode ' elec1  ' and ' elec2]);
%     end
%     end   
% end

% extract time series from each electrode, save to file
for elec=1:length(coords);
    elec_num=num2str(elec);

cmd=['fslmeants -i AROMA_' run_num ' -m electrode_spheres/elec' ...
    elec_num 'FSL_sphere -o electrode_spheres/elec' elec_num run_num '_ts_FSL_AROMA.txt'];
[b,c]=system(cmd);

% cmd=['fslmeants -i GSR_' run_num '_nosmooth -m electrode_spheres/elec' ...
%     elec_num 'PIALVOX_sphere -o electrode_spheres/elec' elec_num run_num '_ts_PIALVOX_nosmooth.txt'];
% [b,c]=system(cmd);

display(['Done extracting time series for electrode' elec_num run_num]);
end

% % label WM electrodes with zeros in their time series
% Identify white-matter electrodes (>50% of voxels in WM classified
% by FAST in func space (threshold as in Chai et al)
for elec=1:length(coords);
    elec_num=num2str(elec);

WMvox=[]; elecvox=[]; WM=[];
cmd=['fslmaths electrode_spheres/elec' elec_num 'FSL_sphere -mul WM_thr_Chai_' run_num ' electrode_spheres/test'];
[b,c]=system(cmd);
cmd=['fslstats electrode_spheres/test -V'];
[b,c]=system(cmd); WMvox=str2num(c); WMvox=WMvox(1);
cmd=['fslstats electrode_spheres/elec' elec_num 'FSL_sphere -V'];
[b,c]=system(cmd); elecvox=str2num(c); elecvox=elecvox(1);

if WMvox/elecvox > 0.5
    WM=1; else WM=0;
end

if WM==1
    display(['Electrode ' elec_num ' is WM']);
    ts=load(['electrode_spheres/elec' elec_num run_num '_ts_FSL_AROMA.txt']);
    ts=zeros(length(ts),1);
    cd electrode_spheres;
    dlmwrite(['elec' elec_num run_num '_ts_FSL_AROMA.txt'], ts);
    cd ..
end
% end
end
end

