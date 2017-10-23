% Plot lag correlation betweeen predefined electrode pairs in HFB and alpha range
% Must first run plot_dFC_pair.m on all relevant pairs of interest
% HFB_vs_alpha_pairs.txt file should contain subject name (column 1), electrode1 name (column 2),
% electrode2 name (column 3), subject number (4) run number (5), network number
% (6),
% network identity: 1=DMN, 2=DAN, 3=FPCN

%depth=input('depth(1) or subdural(0)? ','s');
%region=input('Seed location (e.g. mPFC) ','s');
%freq=input('HFB 0.1-1Hz (1) or alpha (2) or HFB <0.1Hz (3) or SCP (4) ','s');
% depth=str2num(depth);
%bold_run_num=['run1' bold_runname];
%ecog_run_num=['run' ecog_runname];
load('cdcol.mat');

globalECoGDir=getECoGSubDir;
cd([globalECoGDir '/Rest']);
mkdir('Figs');
cd Figs;
mkdir('dFC_analysis'); cd ..

allsubs_HFB_vs_alpha_SWC=[];
%% Load subject, ECoG run numbers, and electrode list
cd(['dFC_analysis']);
list=importdata('lag_corr_peaks.txt',' ');
subjects=list.textdata(:,1);
subject_nums=list.data(:,1);
roi1=list.textdata(:,2); roi2=list.textdata(:,3);
run_num=list.data(:,2);
networks=list.data(:,3);
%allsubs_seedcorr_allfreqs=NaN(length(subjects),7);

for sub=1:length(subjects)
    Patient=subjects{sub}
    run1=num2str(run_num(sub));
    elec1=roi1(sub);
    elec2=roi2(sub);
    network=networks(sub);
    
%% Load corr values for each run
cd([globalECoGDir '/Rest/' Patient '/Run' run1])
lag_peak_HFB=load(['lag_peak_HFB' char(elec1) char(elec2) '.mat']);
lag_peak_Alpha=load(['lag_peak_Alpha' char(elec1) char(elec2) '.mat']);

lag_peak_HFB_allsubs(sub,:)=lag_peak_HFB.lag_peak_HFB;
lag_peak_Alpha_allsubs(sub,:)=lag_peak_Alpha.lag_peak_Alpha;
end






