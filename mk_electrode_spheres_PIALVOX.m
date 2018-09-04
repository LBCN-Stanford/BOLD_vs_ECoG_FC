

% Needed: manually created channel name-number mapping file (.xls format)

Patient=input('Patient: ','s');
depth=0; % 1 for depth, 0 for surface (use .PIAL coords)
% runs=['run1'; 'run2'; 'run3'];
% [total_runs y]=size(runs);
% Runs=cellstr(runs);

%Load electrode coordinates
cd(['/media/jplinux/ExtraDrive1/data/freesurfer/subjects/' Patient '/elec_recon']);
mkdir electrode_spheres;
if depth==1
    load('brainmask_coords.mat');
    coords=brainmask_coords;
else
coords=dlmread([Patient '.PIALVOX'],' ',2,0);
end

%% Get electrode names
fsDir=getFsurfSubDir();
parcOut=elec2Parc_v2([Patient],'DK',0);
elecNames = parcOut(:,1);

%% make binarized mask of BOLD data and erode by 2 voxels
cmd=['fslmaths GSR_run1_FSL -bin -kernel 2D -ero func_brainmask'];
[b,c]=system(cmd);
cmd=['fslmaths func_brainmask -kernel 2D -ero func_brainmask'];
[b,c]=system(cmd);
% for run=1:total_runs;
for electrode=1:length(coords)

% get coordinates
x=num2str(coords(electrode,1)); y=num2str(coords(electrode,2)); z=num2str(255-(coords(electrode,3)));

%if depth==1;
x1=num2str(x); y1=num2str(y); z1=num2str(z);   

    
% Convert mm brainmask coords to mm fMRI (FSL) coords
%if depth==1;
  cmd = ['echo ' x ' ' y ' ' z ' | img2imgcoord -src brainmask -dest GSR_run1_1vol -xfm brainmask2func_run1.mat -vox'];
[b,c]=system(cmd);
c=strrep(c,'Coordinates in Destination volume (in voxels)',[]);
d=str2num(c);
x2=num2str(d(1));
y2=num2str(d(2));
z2=num2str(d(3));

nElectrode=int2str(electrode(:));

% if electrode==58
%     pause
% end
%% Make 6-mm radius spherical ROI around coordinates
cmd = ['fslmaths GSR_run1_1vol.nii.gz -roi ' x2 ' 1 ' y2 ' 1 ' z2 ' 1 0 1 electrode_spheres/elec' nElectrode '_PIALVOX'];
[b,c]=system(cmd);
cmd = ['fslmaths electrode_spheres/elec' nElectrode '_PIALVOX -kernel sphere 6 -fmean -bin electrode_spheres/elec' nElectrode 'PIALVOX_sphere'];
  [b,c]=system(cmd);  

  display(['Done electrode' nElectrode])
cmd=['fslmaths electrode_spheres/elec' nElectrode 'PIALVOX_sphere -mul func_brainmask electrode_spheres/elec' nElectrode 'PIALVOX_sphere'];
 [b,c]=system(cmd); 
%% Multiply each ROI by brain mask (exclude edge voxels)

end

cd electrode_spheres;
%% Copy files with electrode names on file name
for elec=1:length(coords);
   elec_num=num2str(elec);
elec_name=char(parcOut(elec,1)); 
copyfile(['elec' elec_num 'PIALVOX_sphere.nii.gz'],[elec_name '.nii.gz']);
end

%% Add all ROIs into single .nii file
for electrode=1:length(coords)
    nElectrode=num2str(electrode);
    cmd=['fslmaths elec' nElectrode 'PIALVOX_sphere -mul ' nElectrode ' elec' nElectrode];
    [b,c]=system(cmd);
    if electrode==1
cmd=['fslmaths elec' nElectrode ' all_electrodes_spheres'];
[b,c]=system(cmd);
    else
        cmd=['fslmaths elec' nElectrode ' -add all_electrodes_spheres all_electrodes_spheres'];
[b,c]=system(cmd);
    end
    delete(['elec' nElectrode '.nii.gz']);
end





