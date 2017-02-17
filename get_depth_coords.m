fsSub=input('Patient: ','s');
cfg=[];
%Load channel name-number mapping
cd(['/media/jplinux/ExtraDrive1/data/freesurfer/subjects/' fsSub '/elec_recon']);

%function [elecMatrix, elecLabels, xyz, brainmask_coords] = get_depth_coords(fsSub,cfg)

% function plotMgridOnSlices(fsSub,cfg)
%
% Creates a figure illustrating the location of each electrode in an mgrid
% file in a sagittal, coronal, and axial slice and indicates which part of
% the brain it is in.
%
% Required Inputs:
%  fsSub - Patient's freesurfer directory name
%
% Optional cfg parameters:
%  mgridFname - mgrid filename and path. If empty, name is assumed to be fsSub.mgrid. 
%  fullTitle - If 1, the mgrid and mri voxel coordinates are displayed in
%              the figure title along with the electrode name and anatomical 
%              location. {default: 0}
%  markerSize - The size of the dot in each slice used to represent an
%              electrode's location. {default: 30}
%  cntrst    - 0< number <=1 The lower this number the lower the brighter
%              the image (i.e., the lower the voxel value corresponding to 
%              white). {default: 0.5}
%  anatOverlay- If 1, color is overlayed on the brain to show FreeSurfer's
%              automatic segmentation of brain areas (neocortex uses 
%              Desikan-Killiany parcellation). {default: 0}
%  pauseOn   - If 1, Matlab pauses after each figure is made and waits for
%              a keypress. {default: 0}
%  printFigs - If 1, each figure is output to an eps file. {default: 0}

%
% Examples:
%  %Specify mgrid file and do NOT print
%  cfg=[];
%  cfg.mgridFname='/Applications/freesurfer/subjects/TWH001/elec_recon/TWH001.mgrid';
%  plotMgridOnSlices('PT001',cfg);
%
%  %Use FreeSurfer file structure and print
%  cfg=[];
%  cfg.printFigs=1;
%  plotMgridOnSlices('PT001',cfg);
%
%
% Author: David M. Groppe
% Feb. 2015
% Feinstein Institute for Medical Research/Univ. of Toronto

% Future work:
% Add option for fsurf anatomy colors?
cfg=[]; cfg.printFigs=0;
if ~isfield(cfg,'mgridFname'),    mgridFname=[];    else mgridFname=cfg.mgridFname; end
if ~isfield(cfg,'fullTitle'),     fullTitle=0;      else fullTitle=cfg.fullTitle; end
if ~isfield(cfg,'markerSize'),    markerSize=30;    else markerSize=cfg.markerSize; end
if ~isfield(cfg,'cntrst'),    cntrst=.5;          else cntrst=cfg.cntrst; end
if ~isfield(cfg,'anatOverlay'),    anatOverlay=.5;          else anatOverlay=cfg.anatOverlay; end
if ~isfield(cfg,'pauseOn'),    pauseOn=0;          else pauseOn=cfg.pauseOn; end
if ~isfield(cfg,'printFigs'),    printFigs=0;          else printFigs=cfg.printFigs; end
checkCfg(cfg,'plotMgridOnSlices.m');


% FreeSurfer Subject Directory
fsdir=getFsurfSubDir();

% Load MRI
mriFname=fullfile(fsdir,fsSub,'mri','brainmask.mgz');
if ~exist(mriFname,'file')
   error('File %s not found.',mriFname); 
end
mri=MRIread(mriFname);
%mri.vol is ILA (i.e., S->I, R->L, P->A)
mx=max(max(max(mri.vol)))*cntrst;
mn=min(min(min(mri.vol)));
sVol=size(mri.vol);

% Load segmentation
segFname=fullfile(fsdir,fsSub,'mri','aparc+aseg.mgz');
if ~exist(mriFname,'file')
   error('File %s not found.',mriFname); 
end
seg=MRIread(segFname);

% Load mgrid
% if strcmpi(mgridFname,'l') || strcmpi(mgridFname,'r')
%     [elecMatrix, elecLabels, elecRgb]=mgrid2matlab(fsSub,mgridFname);
% else
%     [elecMatrix, elecLabels, elecRgb]=mgrid2matlab(mgridFname); % mgrid coords are LIP
% end
if isempty(mgridFname)
    [elecMatrix, elecLabels, elecRgb]=mgrid2matlab(fsSub);
end
nElec=length(elecLabels);
elecMatrix=round(elecMatrix);
xyz=zeros(size(elecMatrix));
% xyz(:,1:2)=elecMatrix(:,1:2)
% xyz(:,3)=sVol(3)-elecMatrix(:,3);
xyz(:,1)=elecMatrix(:,2);
xyz(:,2)=elecMatrix(:,1);
xyz(:,3)=sVol(3)-elecMatrix(:,3);

brainmask_coords=[xyz(:,2) xyz(:,1) xyz(:,3)];
save('brainmask_coords','brainmask_coords');
