

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

% add values to zero voxels in brainmask.nii.gz
cmd=['fslmaths GSR_run1_FSL -bin func_brainmask'];
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

% else
% cmd = ['echo ' x ' ' y ' ' z ' | img2imgcoord -src brainmask -dest GSR_run1_1vol -xfm brainmask2func_run1.mat -mm'];
% [b,c]=system(cmd);
% c=strrep(c,'Coordinates in Destination volume (in mm)',[]);
% d=str2num(c);
% x1=num2str(d(1));
% y1=num2str(d(2));
% z1=num2str(d(3));
% end

% Convert mm fMRI (FSL) coords to vox
% if depth==0
% cmd = ['echo ' x1 ' ' y1 ' ' z1 ' ' '| std2imgcoord -img GSR_run1_1vol.nii.gz -std GSR_run1_1vol.nii.gz -vox'];
% [b,c] = system(cmd);
% d=str2num(c);
% x2=num2str(d(1));
% y2=num2str(d(2));
% z2=num2str(d(3));
% end
nElectrode=int2str(electrode(:));

% Make 6-mm radius spherical ROI around coordinates
cmd = ['fslmaths GSR_run1_1vol.nii.gz -roi ' x2 ' 1 ' y2 ' 1 ' z2 ' 1 0 1 electrode_spheres/elec' nElectrode '_PIALVOX'];
[b,c]=system(cmd);
cmd = ['fslmaths electrode_spheres/elec' nElectrode '_PIALVOX -kernel sphere 6 -fmean -bin electrode_spheres/elec' nElectrode 'PIALVOX_sphere'];
  [b,c]=system(cmd);  

  display(['Done electrode' nElectrode])
end
% end

cd electrode_spheres;
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





