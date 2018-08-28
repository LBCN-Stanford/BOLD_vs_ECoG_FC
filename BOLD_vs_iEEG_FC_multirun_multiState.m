

Conditions={'gradCPT'; 'Rest'; 'Sleep'};
Seeds={'daINS'; 'PMC'; 'SPL'};
%% Inputs
Patient=input('Patient: ','s');

%% Defaults
bold_runname='1';
plot_all='0'; % 0 = plot one seed
%chop_sec=21; % chop 21 secons from beginning
signal='4'; % HFB unsmoothed (0) smoothed (1) 0.1-1 Hz (2) <0.1 Hz (3) <1 Hz (4); must be string
conditions={'gradCPT'; 'Rest'; 'Sleep'};
load('cdcol.mat');
getECoGSubDir; global globalECoGDir;

%% Loop through conditions and seed regions
for i=1:length(conditions)
   condition=Conditions{i};
    cd([globalECoGDir filesep  Conditions{i} filesep Patient]); 
    
for j=1:length(Seeds)
%% Load seed, target, and neighbour electrode names
% elec1=seed, elec2=target 1 (to highlight), elec3=target 2,
% neighbour1+2=seed's neighbouring electrodes to exclude
cd([globalECoGDir filesep  'gradCPT' filesep Patient]); 
elecs=importdata([Seeds{i} '_FC.txt']);
elecs=elecs.data;
Seed=Seeds{i};
  cd([globalECoGDir filesep  Conditions{i} filesep Patient]); 
  [corr_BOLD_vs_iEEG,cutoff,y_err_neg,...
      y_err_pos]=BOLD_vs_iEEG_FC_multirun_func(Patient,bold_runname,condition,plot_all,Seed,elecs)
end
end
