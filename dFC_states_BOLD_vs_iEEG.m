%% Compare high and low states of FC between 2 nodes - BOLD vs iEEG
% must first run plot_dFC_pair.m (with seed to all enabled) for both BOLD and iEEG

Patient=input('Patient: ','s');
hemi=input('Hemisphere (r or l): ','s');
runs=input('iEEG run (e.g. 1): ','s');
rest=input('Rest(1) or Sleep(0)? ','s');
Window_dur=input('Window duration (in sec): ','s'); 
states=input('number of k-states (2 or 3): ','s'); states=str2num(states);
roi1=input('Seed (e.g. AFS9): ','s');
roi2=input('Target to define high and low states (e.g. PIHS4): ','s');

runnum=['run' runs];
fsDir=getFsurfSubDir();
getECoGSubDir; global globalECoGDir;
parcOut=elec2Parc_v2([Patient],'DK',0);
elecNames = parcOut(:,1);

 %% Load distance
 cd([fsDir '/' Patient '/elec_recon']);
vox=dlmread([Patient '.PIAL'],' ',2,0);
distances=zeros(size(vox,1));
for i = 1:size(vox,1)
 coord = vox(i,:);
     for ii = 1:size(vox,1)
         distances(i,ii)=sqrt((vox(ii,1)-coord(1))^2+(vox(ii,2)-coord(2))^2+(vox(ii,3)-coord(3))^2);
     end
end

%% Load sliding window vectors
    
cd([globalECoGDir '/Rest/' Patient '/Run1']);    
    BOLD=load([roi1 '_' Window_dur 'sec_windows_BOLD.mat']);
    cd([globalECoGDir '/Rest/' Patient '/Run' runs]);  
    iEEG=load([roi1 '_' Window_dur 'sec_windows_iEEG.mat']);
     
 %% Get seed and target index numbers
 roi1_num=strmatch(roi1,elecNames,'exact');
roi2_num=strmatch(roi2,elecNames,'exact');

%% Get distances for seed
seed_distance=distances(:,roi1_num);

%% Find window indices for high and low seed-target FC states
target_BOLD_sw_ts=BOLD.seed_allwindows_fisher(roi2_num,:);
BOLD_high=find(target_BOLD_sw_ts>prctile(target_BOLD_sw_ts,66.6));
BOLD_low=find(target_BOLD_sw_ts<prctile(target_BOLD_sw_ts,33.3));
 
target_iEEG_sw_ts=iEEG.seed_allwindows_fisher(roi2_num,:);
iEEG_high=find(target_iEEG_sw_ts>prctile(target_iEEG_sw_ts,66.6));
iEEG_low=find(target_iEEG_sw_ts<prctile(target_iEEG_sw_ts,33.3));

%% Get average FC for all targets within high and within low states
BOLD_high_avg_roi2=mean(target_BOLD_sw_ts(BOLD_high))
BOLD_low_avg_roi2=mean(target_BOLD_sw_ts(BOLD_low))
iEEG_high_avg_roi2=mean(target_iEEG_sw_ts(iEEG_high))
iEEG_low_avg_roi2=mean(target_iEEG_sw_ts(iEEG_low))

BOLD_high_windows=BOLD.seed_allwindows_fisher(:,BOLD_high);
BOLD_low_windows=BOLD.seed_allwindows_fisher(:,BOLD_low);
iEEG_high_windows=iEEG.seed_allwindows_fisher(:,iEEG_high);
iEEG_low_windows=iEEG.seed_allwindows_fisher(:,iEEG_low);

mean_BOLD_high_windows=mean(BOLD_high_windows,2); 
mean_BOLD_low_windows=mean(BOLD_low_windows,2); 
mean_iEEG_high_windows=mean(iEEG_high_windows,2); 
mean_iEEG_low_windows=mean(iEEG_low_windows,2); 

%% Remove bad indices (convert from iEEG to iElvis order)
load('all_bad_indices.mat');

% Load channel name-number mapping
cd([fsDir '/' Patient '/elec_recon']);
[channumbers_iEEG,chanlabels]=xlsread('channelmap.xls');

% Load channel names (in freesurfer/elec recon order)
chan_names=importdata([Patient '.electrodeNames'],' ');
fs_chanlabels={};

for chan=3:length(chan_names)
    chan_name=chan_names(chan); chan_name=char(chan_name);
    [a b]=strtok(chan_name); 
    bsize=size(strfind(b,' '),2);
    if bsize==2
    [c d]=strtok(b); 
    fs_chanlabels{chan,1}=[d(2) a];
    elseif bsize==3
    [c d]=strtok(b); [e f]=strtok(d);
    fs_chanlabels{chan,1}=[f(2) a c];
    end
end
fs_chanlabels=fs_chanlabels(3:end);

% create iEEG to iElvis chanlabel transformation vector
for i=1:length(chanlabels)
    iEEG_to_iElvis_chanlabel(i,:)=strmatch(chanlabels(i),fs_chanlabels(:,1),'exact');    
end
    for i=1:length(chanlabels)
iElvis_to_iEEG_chanlabel(i,:)=channumbers_iEEG(strmatch(fs_chanlabels(i,1),chanlabels,'exact'));
    end

% convert bad indices to iElvis
for i=1:length(all_bad_indices)
    ind_iElvis=find(iElvis_to_iEEG_chanlabel==all_bad_indices(i));
    if isempty(ind_iElvis)~=1
    bad_iElvis(i,:)=ind_iElvis;
    end
end
bad_chans=bad_iElvis(find(bad_iElvis>0));

%% remove bad indices
mean_BOLD_high_windows(bad_chans)=[];
mean_iEEG_high_windows(bad_chans)=[];
mean_BOLD_low_windows(bad_chans)=[];
mean_iEEG_low_windows(bad_chans)=[];
mean_BOLD_high_windows(find(isfinite(mean_BOLD_high_windows)<1))=[];
mean_iEEG_high_windows(find(isfinite(mean_iEEG_high_windows)<1))=[];
mean_BOLD_low_windows(find(isfinite(mean_BOLD_low_windows)<1))=[];
mean_iEEG_low_windows(find(isfinite(mean_iEEG_low_windows)<1))=[];

seed_distance(bad_chans)=[];
seed_distance(find(seed_distance==0))=[];

%% kmeans clustering of seed FC states
to_remove=[bad_chans;roi1_num];
iEEG.seed_allwindows_fisher(to_remove,:)=[];
BOLD.seed_allwindows_fisher(to_remove,:)=[];

[IDX_iEEG,C_iEEG]=kmeans(iEEG.seed_allwindows_fisher',states,'distance','sqEuclidean','display','final','replicate',1000,'maxiter',250);
[IDX_BOLD,C_BOLD]=kmeans(BOLD.seed_allwindows_fisher',states,'distance','sqEuclidean','display','final','replicate',1000,'maxiter',250);

%% Correlate BOLD vs iEEG kmeans states (centroids)
k1_BOLD=C_BOLD(1,:)'; k2_BOLD=C_BOLD(2,:)';
k1_iEEG=C_iEEG(1,:)'; k2_iEEG=C_iEEG(2,:)';

if states==3
    k3_BOLD=C_BOLD(3,:)'; k3_iEEG=C_iEEG(3,:)';
end

[r,p]=corr(k1_BOLD,k1_iEEG); k1B_vs_k1E=r; k1B_vs_k1E_p=p;
[rho,p]=corr(k1_BOLD,k1_iEEG,'type','Spearman'); k1B_vs_k1E_rho=rho;
[r,p]=partialcorr(k1_BOLD,k1_iEEG,seed_distance); k1B_vs_k1E_partial=r;
[r,p]=corr(k1_BOLD,k2_iEEG); k1B_vs_k2E=r; k1B_vs_k2E_p=p;
[rho,p]=corr(k1_BOLD,k2_iEEG,'type','Spearman'); k1B_vs_k2E_rho=rho;
[r,p]=partialcorr(k1_BOLD,k2_iEEG,seed_distance); k1B_vs_k2E_partial=r;
[r,p]=corr(k2_BOLD,k1_iEEG); k2B_vs_k1E=r; k2B_vs_k1E_p=p;
[rho,p]=corr(k2_BOLD,k1_iEEG,'type','Spearman'); k2B_vs_k1E_rho=rho;
[r,p]=partialcorr(k2_BOLD,k1_iEEG,seed_distance); k2B_vs_k1E_partial=r;
[r,p]=corr(k2_BOLD,k2_iEEG); k2B_vs_k2E=r; k2B_vs_k2E_p=p;
[rho,p]=corr(k2_BOLD,k2_iEEG,'type','Spearman'); k2B_vs_k2E_rho=rho;
[r,p]=partialcorr(k2_BOLD,k2_iEEG,seed_distance); k2B_vs_k2E_partial=r;

if states==3
 [r,p]=corr(k1_BOLD,k3_iEEG); k1B_vs_k3E=r; k1B_vs_k3E_p=p;
[rho,p]=corr(k1_BOLD,k3_iEEG,'type','Spearman'); k1B_vs_k3E_rho=rho;
[r,p]=partialcorr(k1_BOLD,k3_iEEG,seed_distance); k1B_vs_k3E_partial=r;  

 [r,p]=corr(k2_BOLD,k3_iEEG); k2B_vs_k3E=r; k2B_vs_k3E_p=p;
[rho,p]=corr(k2_BOLD,k3_iEEG,'type','Spearman'); k2B_vs_k3E_rho=rho;
[r,p]=partialcorr(k2_BOLD,k3_iEEG,seed_distance); k2B_vs_k3E_partial=r; 

 [r,p]=corr(k3_BOLD,k1_iEEG); k3B_vs_k1E=r; k3B_vs_k1E_p=p;
[rho,p]=corr(k3_BOLD,k1_iEEG,'type','Spearman'); k3B_vs_k1E_rho=rho;
[r,p]=partialcorr(k3_BOLD,k1_iEEG,seed_distance); k3B_vs_k1E_partial=r; 

 [r,p]=corr(k3_BOLD,k2_iEEG); k3B_vs_k2E=r; k3B_vs_k2E_p=p;
[rho,p]=corr(k3_BOLD,k2_iEEG,'type','Spearman'); k3B_vs_k2E_rho=rho;
[r,p]=partialcorr(k3_BOLD,k2_iEEG,seed_distance); k3B_vs_k2E_partial=r; 

 [r,p]=corr(k3_BOLD,k3_iEEG); k3B_vs_k3E=r; k3B_vs_k3E_p=p;
[rho,p]=corr(k3_BOLD,k3_iEEG,'type','Spearman'); k3B_vs_k3E_rho=rho;
[r,p]=partialcorr(k3_BOLD,k3_iEEG,seed_distance); k3B_vs_k3E_partial=r; 

end

%% Find electrodes with greatest FC change between high vs low state
BOLD_high_minus_low=mean_BOLD_high_windows-mean_BOLD_low_windows;
iEEG_high_minus_low=mean_iEEG_high_windows-mean_iEEG_low_windows;
BOLD_k1_minus_k2=k1_BOLD-k2_BOLD;
iEEG_k1_minus_k2=k1_iEEG-k2_iEEG;
if states==3
   BOLD_k1_minus_k3=k1_BOLD-k3_BOLD;
   BOLD_k2_minus_k3=k2_BOLD-k3_BOLD;
   iEEG_k1_minus_k3=k1_iEEG-k3_iEEG;
   iEEG_k2_minus_k3=k2_iEEG-k3_iEEG;
end

global_BOLD_high_minus_low=mean(BOLD_high_minus_low);
global_iEEG_high_minus_low=mean(iEEG_high_minus_low);

%% Correlate BOLD vs iEEG (high and low FC states)
[r,p]=corr(mean_BOLD_high_windows,mean_iEEG_high_windows);
high_BOLD_iEEG_corr=r; high_BOLD_iEEG_p=p;
[rho,p]=corr(mean_BOLD_high_windows,mean_iEEG_high_windows,'type','Spearman');
high_BOLD_iEEG_rho=rho;
[r,p]=partialcorr(mean_BOLD_high_windows,mean_iEEG_high_windows,seed_distance);
high_BOLD_iEEG_partial=r;

[r,p]=corr(mean_BOLD_low_windows,mean_iEEG_low_windows);
low_BOLD_iEEG_corr=r; low_BOLD_iEEG_p=p;
[rho,p]=corr(mean_BOLD_low_windows,mean_iEEG_low_windows,'type','Spearman');
low_BOLD_iEEG_rho=rho;
[r,p]=partialcorr(mean_BOLD_low_windows,mean_iEEG_low_windows,seed_distance);
low_BOLD_iEEG_partial=r;

[r,p]=corr(mean_iEEG_low_windows,mean_iEEG_high_windows);
low_high_iEEG_corr=r; low_high_iEEG_p=p;

[r,p]=corr(mean_BOLD_high_windows,mean_BOLD_low_windows);
low_high_BOLD_corr=r; low_high_BOLD_p=p;

[r,p]=corr(mean_BOLD_high_windows,mean_iEEG_low_windows);
BOLD_high_iEEG_low_corr=r;

[r,p]=corr(mean_BOLD_low_windows,mean_iEEG_high_windows);
BOLD_low_iEEG_high_corr=r;

%% Find electrodes with greatest between-state FC change, correlate changes
BOLD_max_increase_elec=find(BOLD_high_minus_low==max(BOLD_high_minus_low));
iEEG_max_increase_elec=find(iEEG_high_minus_low==max(iEEG_high_minus_low));
BOLD_max_decrease_elec=find(BOLD_high_minus_low==min(BOLD_high_minus_low));
iEEG_max_decrease_elec=find(iEEG_high_minus_low==min(iEEG_high_minus_low));

[r,p]=corr(BOLD_high_minus_low,iEEG_high_minus_low);
BOLD_vs_iEEG_change_corr=r;

%% Correlate between k-state changes: BOLD vs iEEG
[r,p]=corr(BOLD_k1_minus_k2,iEEG_k1_minus_k2);
k1k2_BOLD_vs_iEEG_change_corr=r; k1k2_BOLD_vs_iEEG_change_p=p;
if states==3
[r,p]=corr(BOLD_k1_minus_k3,iEEG_k1_minus_k3); 
k1k3_BOLD_vs_iEEG_change_corr=r; k1k3_BOLD_vs_iEEG_change_p=p;
[r,p]=corr(BOLD_k2_minus_k3,iEEG_k2_minus_k3);
k2k3_BOLD_vs_iEEG_change_corr=r; k2k3_BOLD_vs_iEEG_change_p=p;
end

%% Plots
FigHandle = figure('Position', [200, 50, 1049, 895]);

% k=2 BOLD vs iEEG plots
subplot(2,2,1)
scatter(k1_BOLD,k1_iEEG,'MarkerEdgeColor','k','MarkerFaceColor',[0 0 0]); 
h=lsline; set(h(1),'color',[0 0 0],'LineWidth',3);
set(gca,'Fontsize',14,'FontWeight','bold','LineWidth',2,'TickDir','out');
set(gcf,'color','w');
title({['State 1 BOLD vs State 1 iEEG HFB (0.1-1Hz) ' Window_dur ' sec windows']; ...
    ['r = ' num2str(k1B_vs_k1E) '; rho = ' num2str(k1B_vs_k1E_rho)]; ... 
    ['distance-corrected r = ' num2str(k1B_vs_k1E_partial)]},'Fontsize',12);
xlabel('BOLD FC: k-state 1');
ylabel('HFB (0.1-1Hz) FC: k-state 1');
set(gcf,'PaperPositionMode','auto');

subplot(2,2,2)
scatter(k1_BOLD,k2_iEEG,'MarkerEdgeColor','k','MarkerFaceColor',[0 0 0]); 
h=lsline; set(h(1),'color',[0 0 0],'LineWidth',3);
set(gca,'Fontsize',14,'FontWeight','bold','LineWidth',2,'TickDir','out');
set(gcf,'color','w');
title({['State 1 BOLD vs State 2 iEEG HFB (0.1-1Hz) ' Window_dur ' sec windows']; ...
    ['r = ' num2str(k1B_vs_k2E) '; rho = ' num2str(k1B_vs_k2E_rho)]; ... 
    ['distance-corrected r = ' num2str(k1B_vs_k2E_partial)]},'Fontsize',12);
xlabel('BOLD FC: k-state 1');
ylabel('HFB (0.1-1Hz) FC: k-state 2');
set(gcf,'PaperPositionMode','auto');

subplot(2,2,3)
scatter(k2_BOLD,k1_iEEG,'MarkerEdgeColor','k','MarkerFaceColor',[0 0 0]); 
h=lsline; set(h(1),'color',[0 0 0],'LineWidth',3);
set(gca,'Fontsize',14,'FontWeight','bold','LineWidth',2,'TickDir','out');
set(gcf,'color','w');
title({['State 2 BOLD vs State 1 iEEG HFB (0.1-1Hz) ' Window_dur ' sec windows']; ...
    ['r = ' num2str(k2B_vs_k1E) '; rho = ' num2str(k2B_vs_k1E_rho)]; ... 
    ['distance-corrected r = ' num2str(k2B_vs_k1E_partial)]},'Fontsize',12);
xlabel('BOLD FC: k-state 2');
ylabel('HFB (0.1-1Hz) FC: k-state 1');
set(gcf,'PaperPositionMode','auto');

subplot(2,2,4)
scatter(k2_BOLD,k2_iEEG,'MarkerEdgeColor','k','MarkerFaceColor',[0 0 0]); 
h=lsline; set(h(1),'color',[0 0 0],'LineWidth',3);
set(gca,'Fontsize',14,'FontWeight','bold','LineWidth',2,'TickDir','out');
set(gcf,'color','w');
title({['State 2 BOLD vs State 2 iEEG HFB (0.1-1Hz) ' Window_dur ' sec windows']; ...
    ['r = ' num2str(k2B_vs_k2E) '; rho = ' num2str(k2B_vs_k2E_rho)]; ... 
    ['distance-corrected r = ' num2str(k2B_vs_k2E_partial)]},'Fontsize',12);
xlabel('BOLD FC: k-state 2');
ylabel('HFB (0.1-1Hz) FC: k-state 2');
set(gcf,'PaperPositionMode','auto');
pause; close;

% k1 vs k2 change: BOLD vs iEEG
figure(1)
scatter(BOLD_k1_minus_k2,iEEG_k1_minus_k2,'MarkerEdgeColor','k','MarkerFaceColor',[0 0 0]); 
h=lsline; set(h(1),'color',[0 0 0],'LineWidth',3);
set(gca,'Fontsize',14,'FontWeight','bold','LineWidth',2,'TickDir','out');
set(gcf,'color','w');
title({[' BOLD change vs iEEG change (kstate 1 vs 2) ' Window_dur ' sec windows']; ...
    ['r = ' num2str(k1k2_BOLD_vs_iEEG_change_corr) ' p = ' num2str(k1k2_BOLD_vs_iEEG_change_p)]},'Fontsize',12); 
xlabel('BOLD FC change');
ylabel('iEEG FC change');
set(gcf,'PaperPositionMode','auto');
pause; close;

% k1 vs k3 change: BOLD vs iEEG
scatter(BOLD_k1_minus_k3,iEEG_k1_minus_k3,'MarkerEdgeColor','k','MarkerFaceColor',[0 0 0]); 
h=lsline; set(h(1),'color',[0 0 0],'LineWidth',3);
set(gca,'Fontsize',14,'FontWeight','bold','LineWidth',2,'TickDir','out');
set(gcf,'color','w');
title({[' BOLD change vs iEEG change (kstate 1 vs 3) ' Window_dur ' sec windows']; ...
    ['r = ' num2str(k1k3_BOLD_vs_iEEG_change_corr) ' p = ' num2str(k1k3_BOLD_vs_iEEG_change_p)]},'Fontsize',12); 
xlabel('BOLD FC change');
ylabel('iEEG FC change');
set(gcf,'PaperPositionMode','auto');
pause; close;

% k2 vs k3 change: BOLD vs iEEG
scatter(BOLD_k2_minus_k3,iEEG_k2_minus_k3,'MarkerEdgeColor','k','MarkerFaceColor',[0 0 0]); 
h=lsline; set(h(1),'color',[0 0 0],'LineWidth',3);
set(gca,'Fontsize',14,'FontWeight','bold','LineWidth',2,'TickDir','out');
set(gcf,'color','w');
title({[' BOLD change vs iEEG change (kstate 2 vs 3) ' Window_dur ' sec windows']; ...
    ['r = ' num2str(k2k3_BOLD_vs_iEEG_change_corr) ' p = ' num2str(k2k3_BOLD_vs_iEEG_change_p)]},'Fontsize',12); 
xlabel('BOLD FC change');
ylabel('iEEG FC change');
set(gcf,'PaperPositionMode','auto');
pause; close;

% BOLD high/low vs iEEG high/low seed-target plots
FigHandle = figure('Position', [200, 50, 1049, 895]);
subplot(2,2,1)
scatter(mean_BOLD_high_windows,mean_iEEG_high_windows,'MarkerEdgeColor','k','MarkerFaceColor',[0 0 0]); 
h=lsline; set(h(1),'color',[0 0 0],'LineWidth',3);
set(gca,'Fontsize',14,'FontWeight','bold','LineWidth',2,'TickDir','out');
set(gcf,'color','w');
title({[' High FC state: BOLD vs HFB (0.1-1Hz) ' Window_dur ' sec windows']; ...
    ['r = ' num2str(high_BOLD_iEEG_corr) '; rho = ' num2str(high_BOLD_iEEG_rho)]; ... 
    ['distance-corrected r = ' num2str(high_BOLD_iEEG_partial)]},'Fontsize',12);
xlabel('BOLD FC');
ylabel('HFB (0.1-1Hz) FC');
set(gcf,'PaperPositionMode','auto');

subplot(2,2,2)
scatter(mean_BOLD_low_windows,mean_iEEG_low_windows,'MarkerEdgeColor','k','MarkerFaceColor',[0 0 0]); 
h=lsline; set(h(1),'color',[0 0 0],'LineWidth',3);
set(gca,'Fontsize',14,'FontWeight','bold','LineWidth',2,'TickDir','out');
set(gcf,'color','w');
title({[' Low FC state: BOLD vs HFB (0.1-1Hz) ' Window_dur ' sec windows']; ...
    ['r = ' num2str(low_BOLD_iEEG_corr) '; rho = ' num2str(low_BOLD_iEEG_rho)]; ...
    ['distance-corrected r = ' num2str(low_BOLD_iEEG_partial)]},'Fontsize',12);
xlabel('BOLD FC');
ylabel('HFB (0.1-1Hz) FC');
set(gcf,'PaperPositionMode','auto');

subplot(2,2,3)
scatter(mean_BOLD_low_windows,mean_iEEG_high_windows,'MarkerEdgeColor','k','MarkerFaceColor',[0 0 0]); 
h=lsline; set(h(1),'color',[0 0 0],'LineWidth',3);
set(gca,'Fontsize',14,'FontWeight','bold','LineWidth',2,'TickDir','out');
set(gcf,'color','w');
title({[' BOLD low vs iEEG high FC seed-target state ' Window_dur ' sec windows']; ...
    ['r = ' num2str(BOLD_low_iEEG_high_corr)]},'Fontsize',12); 
xlabel('low seed-target BOLD FC state');
ylabel('high seed-target iEEG FC state');
set(gcf,'PaperPositionMode','auto');

subplot(2,2,4)
scatter(mean_BOLD_high_windows,mean_iEEG_low_windows,'MarkerEdgeColor','k','MarkerFaceColor',[0 0 0]); 
h=lsline; set(h(1),'color',[0 0 0],'LineWidth',3);
set(gca,'Fontsize',14,'FontWeight','bold','LineWidth',2,'TickDir','out');
set(gcf,'color','w');
title({[' BOLD high vs iEEG low FC seed-target state ' Window_dur ' sec windows']; ...
    ['r = ' num2str(BOLD_high_iEEG_low_corr)]},'Fontsize',12); 
xlabel('high seed-target BOLD FC state');
ylabel('low seed-target iEEG FC state');
set(gcf,'PaperPositionMode','auto');
pause; close;

figure(2)
scatter(mean_iEEG_low_windows,mean_iEEG_high_windows,'MarkerEdgeColor','k','MarkerFaceColor',[0 0 0]); 
h=lsline; set(h(1),'color',[0 0 0],'LineWidth',3);
set(gca,'Fontsize',14,'FontWeight','bold','LineWidth',2,'TickDir','out');
set(gcf,'color','w');
title({[' iEEG: Low vs High FC state: HFB (0.1-1Hz) ' Window_dur ' sec windows']; ...
    ['r = ' num2str(low_high_iEEG_corr)]},'Fontsize',12); 
xlabel('low seed-target iEEG FC state');
ylabel('high seed-target iEEG FC state');
set(gcf,'PaperPositionMode','auto');

figure(3)
scatter(mean_BOLD_low_windows,mean_BOLD_high_windows,'MarkerEdgeColor','k','MarkerFaceColor',[0 0 0]); 
h=lsline; set(h(1),'color',[0 0 0],'LineWidth',3);
set(gca,'Fontsize',14,'FontWeight','bold','LineWidth',2,'TickDir','out');
set(gcf,'color','w');
title({[' BOLD: Low vs High FC state ' Window_dur ' sec windows']; ...
    ['r = ' num2str(low_high_BOLD_corr)]},'Fontsize',12); 
xlabel('low seed-target BOLD FC state');
ylabel('high seed-target BOLD FC state');
set(gcf,'PaperPositionMode','auto');
pause; close;

scatter(BOLD_high_minus_low,iEEG_high_minus_low,'MarkerEdgeColor','k','MarkerFaceColor',[0 0 0]); 
h=lsline; set(h(1),'color',[0 0 0],'LineWidth',3);
set(gca,'Fontsize',14,'FontWeight','bold','LineWidth',2,'TickDir','out');
set(gcf,'color','w');
title({[' BOLD change vs iEEG change (high minus low) ' Window_dur ' sec windows']; ...
    ['r = ' num2str(BOLD_vs_iEEG_change_corr)]},'Fontsize',12); 
xlabel('BOLD FC change');
ylabel('iEEG FC change');
set(gcf,'PaperPositionMode','auto');
pause; close;


%% view BOLD and iEEG states on brains
ignoreChans=[elecNames(bad_chans)];
elecnames=elecNames;
elecnames([bad_chans; roi1_num])=[];

% BOLD high state
% cfg=[];
% cfg.elecColors=mean_BOLD_high_windows;
% cfg.elecNames=elecnames;
% cfg.ignoreChans=ignoreChans;
% cfg.title=[roi1 ' BOLD FC: high state']; 
% cfg.view=[hemi 'omni'];
% cfg.elecUnits='z';
% cfg.pullOut=3;
% cfg.elecColorScale='minmax';
% cfgOut=plotPialSurf(Patient,cfg);

% iEEG high state
% cfg=[];
% cfg.elecColors=mean_iEEG_high_windows;
% cfg.elecNames=elecnames;
% cfg.ignoreChans=ignoreChans;
% cfg.title=[roi1 ' iEEG FC: high state'];
% cfg.view=[hemi 'omni'];
% cfg.elecUnits='z';
% cfg.pullOut=3;
% cfg.elecColorScale='minmax';
% cfgOut=plotPialSurf(Patient,cfg);

% BOLD low state
% cfg=[];
% cfg.elecColors=mean_BOLD_low_windows;
% cfg.elecNames=elecnames;
% cfg.ignoreChans=ignoreChans;
% cfg.title=[roi1 ' BOLD FC: low state']; 
% cfg.view=[hemi 'omni'];
% cfg.elecUnits='z';
% cfg.pullOut=3;
% cfg.elecColorScale='minmax';
% cfgOut=plotPialSurf(Patient,cfg);

% iEEG low state
% cfg=[];
% cfg.elecColors=mean_iEEG_low_windows;
% cfg.elecNames=elecnames;
% cfg.ignoreChans=ignoreChans;
% cfg.title=[roi1 ' iEEG FC: low state']; 
% cfg.view=[hemi 'omni'];
% cfg.elecUnits='z';
% cfg.pullOut=3;
% cfg.elecColorScale='minmax';
% cfgOut=plotPialSurf(Patient,cfg);

% pause; close('all');

% BOLD k1 state
cfg=[];
cfg.elecColors=k1_BOLD;
cfg.elecNames=elecnames;
cfg.ignoreChans=ignoreChans;
cfg.title=[roi1 ' BOLD: k1 state']; 
cfg.view=[hemi 'omni'];
cfg.elecUnits='z';
cfg.pullOut=3;
cfg.elecColorScale='minmax';
cfgOut=plotPialSurf(Patient,cfg);

% iEEG k1 state
cfg=[];
cfg.elecColors=k1_iEEG;
cfg.elecNames=elecnames;
cfg.ignoreChans=ignoreChans;
cfg.title=[roi1 ' iEEG: k1 state']; 
cfg.view=[hemi 'omni'];
cfg.elecUnits='z';
cfg.pullOut=3;
cfg.elecColorScale='minmax';
cfgOut=plotPialSurf(Patient,cfg);

% BOLD k2 state
cfg=[];
cfg.elecColors=k2_BOLD;
cfg.elecNames=elecnames;
cfg.ignoreChans=ignoreChans;
cfg.title=[roi1 ' BOLD: k2 state']; 
cfg.view=[hemi 'omni'];
cfg.elecUnits='z';
cfg.pullOut=3;
cfg.elecColorScale='minmax';
cfgOut=plotPialSurf(Patient,cfg);

% iEEG k2 state
cfg=[];
cfg.elecColors=k2_iEEG;
cfg.elecNames=elecnames;
cfg.ignoreChans=ignoreChans;
cfg.title=[roi1 ' iEEG: k2 state']; 
cfg.view=[hemi 'omni'];
cfg.elecUnits='z';
cfg.pullOut=3;
cfg.elecColorScale='minmax';
cfgOut=plotPialSurf(Patient,cfg);

% BOLD k3 state
cfg=[];
cfg.elecColors=k3_BOLD;
cfg.elecNames=elecnames;
cfg.ignoreChans=ignoreChans;
cfg.title=[roi1 ' BOLD: k3 state']; 
cfg.view=[hemi 'omni'];
cfg.elecUnits='z';
cfg.pullOut=3;
cfg.elecColorScale='minmax';
cfgOut=plotPialSurf(Patient,cfg);

% iEEG k3 state
cfg=[];
cfg.elecColors=k3_iEEG;
cfg.elecNames=elecnames;
cfg.ignoreChans=ignoreChans;
cfg.title=[roi1 ' iEEG: k3 state']; 
cfg.view=[hemi 'omni'];
cfg.elecUnits='z';
cfg.pullOut=3;
cfg.elecColorScale='minmax';
cfgOut=plotPialSurf(Patient,cfg);

pause; close('all');
