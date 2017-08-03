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
mkdir(['electrode_spheres/SBCA/figs/kstates']);
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

%% Get optimal k using silhouette criterion
silh_iEEG=evalclusters(iEEG.seed_allwindows_fisher','kmeans','silhouette','klist',[2:10]);
silh_BOLD=evalclusters(BOLD.seed_allwindows_fisher','kmeans','silhouette','klist',[2:10]);

plot(silh_iEEG);
pause; close;
plot(silh_BOLD);
pause; close;

%% Get optimal k using elbow criterion
% dim=8;
% % default number of test to get minimun under differnent random centriods
% test_num=10;
% distortion=zeros(dim(1),1);
% for k_temp=1:dim(1)
%     [~,~,sumd]=kmeans(iEEG.seed_allwindows_fisher',k_temp,'emptyaction','drop');
%     destortion_temp=sum(sumd);
%     % try differnet tests to find minimun disortion under k_temp clusters
%     for test_count=2:test_num
%         [~,~,sumd]=kmeans(X,k_temp,'emptyaction','drop');
%         destortion_temp=min(destortion_temp,sum(sumd));
%     end
%     distortion(k_temp,1)=destortion_temp;
% end
% 
% variance=distortion(1:end-1)-distortion(2:end);
% distortion_percent=cumsum(variance)/(distortion(1)-distortion(end));
% plot(distortion_percent,'b*--');



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
k1k2BOLD_vs_k1k2iEEG_change_corr=r; k1k2BOLD_vs_k1k2iEEG_change_p=p;
if states==3
    [r,p]=corr(BOLD_k1_minus_k2,iEEG_k1_minus_k3);
    k1k2BOLD_vs_k1k3iEEG_change_corr=r; k1k2BOLD_vs_k1k3iEEG_change_p=p;
    
    [r,p]=corr(BOLD_k1_minus_k2,iEEG_k2_minus_k3);
    k1k2BOLD_vs_k2k3iEEG_change_corr=r; k1k2BOLD_vs_k2k3iEEG_change_p=p;
    
    [r,p]=corr(BOLD_k1_minus_k3,iEEG_k1_minus_k2);
    k1k3BOLD_vs_k1k2iEEG_change_corr=r; k1k3BOLD_vs_k1k2iEEG_change_p=p;
    
        [r,p]=corr(BOLD_k1_minus_k3,iEEG_k1_minus_k3); 
k1k3BOLD_vs_k1k3iEEG_change_corr=r; k1k3BOLD_vs_k1k3iEEG_change_p=p;

    [r,p]=corr(BOLD_k1_minus_k3,iEEG_k2_minus_k3);
    k1k3BOLD_vs_k2k3iEEG_change_corr=r; k1k3BOLD_vs_k2k3iEEG_change_p=p;
    
    [r,p]=corr(BOLD_k2_minus_k3,iEEG_k1_minus_k2);
k2k3BOLD_vs_k1k2iEEG_change_corr=r; k2k3BOLD_vs_k1k2iEEG_change_p=p;
   
    [r,p]=corr(BOLD_k2_minus_k3,iEEG_k1_minus_k3);
k2k3BOLD_vs_k1k3iEEG_change_corr=r; k2k3BOLD_vs_k1k3iEEG_change_p=p;

    [r,p]=corr(BOLD_k2_minus_k3,iEEG_k2_minus_k3);
k2k3BOLD_vs_k2k3iEEG_change_corr=r; k2k3BOLD_vs_k2k3iEEG_change_p=p;

BOLD_iEEG_kstates_allcorr=[k1k2BOLD_vs_k1k2iEEG_change_corr k1k2BOLD_vs_k1k3iEEG_change_corr k1k2BOLD_vs_k2k3iEEG_change_corr ...
    k1k3BOLD_vs_k1k2iEEG_change_corr k1k3BOLD_vs_k1k3iEEG_change_corr k1k3BOLD_vs_k2k3iEEG_change_corr ...
    k2k3BOLD_vs_k1k2iEEG_change_corr k2k3BOLD_vs_k1k3iEEG_change_corr k2k3BOLD_vs_k2k3iEEG_change_corr];

BOLD_iEEG_kstates_allp=[k1k2BOLD_vs_k1k2iEEG_change_p k1k2BOLD_vs_k1k3iEEG_change_p k1k2BOLD_vs_k2k3iEEG_change_p ...
    k1k3BOLD_vs_k1k2iEEG_change_p k1k3BOLD_vs_k1k3iEEG_change_p k1k3BOLD_vs_k2k3iEEG_change_p ...
    k2k3BOLD_vs_k1k2iEEG_change_p k2k3BOLD_vs_k1k3iEEG_change_p k2k3BOLD_vs_k2k3iEEG_change_p];
end

%% Correlate between k-state changes: iEEG vs iEEG
[r,p]=corr(k1_iEEG,k2_iEEG);
k1k2_iEEG_corr=r;
if states>2
[r,p]=corr(k1_iEEG,k3_iEEG);
k1k3_iEEG_corr=r;
[r,p]=corr(k2_iEEG,k3_iEEG);
k2k3_iEEG_corr=r;
end

%% Correlate between k-state changes: BOLD vs BOLD
[r,p]=corr(k1_BOLD,k2_BOLD);
k1k2_BOLD_corr=r;
if states>2
[r,p]=corr(k1_BOLD,k3_BOLD);
k1k3_BOLD_corr=r;
[r,p]=corr(k2_BOLD,k3_BOLD);
k2k3_BOLD_corr=r;
end

%% Plots

% k=2 BOLD vs BOLD corr
if states==2
scatter(k1_BOLD,k2_BOLD,'MarkerEdgeColor','k','MarkerFaceColor',[0 0 0]); 
h=lsline; set(h(1),'color',[0 0 0],'LineWidth',3);
set(gca,'Fontsize',14,'FontWeight','bold','LineWidth',2,'TickDir','out');
set(gcf,'color','w');
title({[' BOLD: k1 vs k2 ' Window_dur ' sec windows']; ...
    ['r = ' num2str(k1k2_BOLD_corr)]},'Fontsize',12); 
xlabel(['BOLD k1 ' roi1 ' FC']);
ylabel(['BOLD k2 ' roi1 ' FC']);
set(gcf,'PaperPositionMode','auto');
pause; close;
end

% k=2 iEEG vs iEEG corr
if states==2
scatter(k1_iEEG,k2_iEEG,'MarkerEdgeColor','k','MarkerFaceColor',[0 0 0]); 
h=lsline; set(h(1),'color',[0 0 0],'LineWidth',3);
set(gca,'Fontsize',14,'FontWeight','bold','LineWidth',2,'TickDir','out');
set(gcf,'color','w');
title({[' iEEG: k1 vs k2 ' Window_dur ' sec windows']; ...
    ['r = ' num2str(k1k2_iEEG_corr)]},'Fontsize',12); 
xlabel(['iEEG k1 ' roi1 ' FC']);
ylabel(['iEEG k2 ' roi1 ' FC']);
set(gcf,'PaperPositionMode','auto');
pause; close;
end


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

% k=2 BOLD vs iEEG states
if states==2 
kstates_BE_allcorr=[k1B_vs_k1E k1B_vs_k2E k2B_vs_k1E k2B_vs_k2E];

    plot(1:length(kstates_BE_allcorr),kstates_BE_allcorr,'k.--', ...
        'LineWidth',2,'Color',[.6 .6 .6],'MarkerSize',25,'MarkerEdgeColor',[.3 .3 .3]);            
 set(gca,'Fontsize',12,'FontWeight','bold','LineWidth',2,'TickDir','out');
  ylabel('BOLD vs iEEG state correlation (r)'); 
  
    hold on
   set(gca,'box','off'); 
set(gca,'Fontsize',12,'FontWeight','bold','LineWidth',2,'TickDir','out');
set(gcf,'color','w');
  ylim([0 .8]);
   set(gca,'Xtick',0:1:10)
   set(gca,'XTickLabel',{'','BOLD1-iEEG1', 'BOLD1-iEEG2','BOLD2-iEEG1','BOLD2-iEEG2','BOLD2-'})
   xtickangle(90)
ylabel('BOLD vs iEEG state correlation (r)'); 
print('-opengl','-r300','-dpng',strcat([pwd,filesep,'electrode_spheres/SBCA',filesep,'figs',filesep,'kstates',filesep,['k2_' roi1 '_BOLD_vs_iEEG_states_' Window_dur]]));
pause; close; 
end

% k=3 BOLD vs iEEG states
if states==3
 kstates_BE_allcorr=[k1B_vs_k1E k1B_vs_k2E k1B_vs_k3E k2B_vs_k1E k2B_vs_k2E k2B_vs_k3E k3B_vs_k1E k3B_vs_k2E k3B_vs_k3E];

    plot(1:length(kstates_BE_allcorr),kstates_BE_allcorr,'k.--', ...
        'LineWidth',2,'Color',[.6 .6 .6],'MarkerSize',25,'MarkerEdgeColor',[.3 .3 .3]);            
 set(gca,'Fontsize',12,'FontWeight','bold','LineWidth',2,'TickDir','out');
  ylabel('BOLD vs iEEG state correlation (r)'); 
  
    hold on
   set(gca,'box','off'); 
set(gca,'Fontsize',12,'FontWeight','bold','LineWidth',2,'TickDir','out');
set(gcf,'color','w');
  ylim([0 .8]);
   set(gca,'Xtick',0:1:10)
   set(gca,'XTickLabel',{'','BOLD1-iEEG1', 'BOLD1-iEEG2','BOLD1-iEEG3','BOLD2-iEEG1','BOLD2-iEEG2','BOLD2-iEEG3' ...
       'BOLD3-iEEG1','BOLD3-iEEG2','BOLD3-iEEG3'})
   xtickangle(90)
ylabel('BOLD vs iEEG state correlation (r)'); 
print('-opengl','-r300','-dpng',strcat([pwd,filesep,'electrode_spheres/SBCA',filesep,'figs',filesep,'kstates',filesep,['k3_' roi1 '_BOLD_vs_iEEG_states_' Window_dur]]));
pause; close;   
end

% k=3 BOLD vs iEEG between-state changes
if states==3
    plot(1:length(BOLD_iEEG_kstates_allcorr),abs(BOLD_iEEG_kstates_allcorr),'k.--', ...
        'LineWidth',2,'Color',[.6 .6 .6],'MarkerSize',25,'MarkerEdgeColor',[.3 .3 .3]);            
 set(gca,'Fontsize',12,'FontWeight','bold','LineWidth',2,'TickDir','out');  
    hold on
   set(gca,'box','off'); 
set(gca,'Fontsize',12,'FontWeight','bold','LineWidth',2,'TickDir','out');
set(gcf,'color','w');
  %ylim([0 .8]);
   set(gca,'Xtick',0:1:10)
   set(gca,'XTickLabel',{'','k1k2BOLD-k1k2iEEG', 'k1k2BOLD-k1k3iEEG','k1k2BOLD-k2k3iEEG','k1k3BOLD-k1k2iEEG','k1k3BOLD-k1k3iEEG','k1k3BOLD-k2k3iEEG' ...
       'k2k3BOLD-k1k2iEEG','k2k3BOLD-k1k3iEEG','k2k3BOLD-k2k3iEEG'})
   xtickangle(90)
   ylabel('|r| BOLD vs iEEG change'); 
   print('-opengl','-r300','-dpng',strcat([pwd,filesep,'electrode_spheres/SBCA',filesep,'figs',filesep,'kstates',filesep,['k3_' roi1 '_BOLD_vs_iEEG_kchanges_' Window_dur]]));
   pause; close;
end


% k1 vs k2 change: BOLD vs iEEG
FigHandle = figure('Position', [400, 500, 1200, 300]);
if states==3
subplot(1,3,1)
end
scatter(BOLD_k1_minus_k2,iEEG_k1_minus_k2,'MarkerEdgeColor','k','MarkerFaceColor',[0 0 0]); 
h=lsline; set(h(1),'color',[0 0 0],'LineWidth',3);
set(gca,'Fontsize',14,'FontWeight','bold','LineWidth',2,'TickDir','out');
set(gcf,'color','w');
title({['kstate 1 vs 2: ' Window_dur ' sec windows']; ...
    ['r = ' num2str(k1k2BOLD_vs_k1k2iEEG_change_corr) ' p = ' num2str(k1k2BOLD_vs_k1k2iEEG_change_p)]},'Fontsize',12); 
xlabel('BOLD FC change');
ylabel('iEEG FC change');
set(gcf,'PaperPositionMode','auto');
if states==2
    pause; close;
end

% k1 vs k3 change: BOLD vs iEEG
if states==3
subplot(1,3,2)
scatter(BOLD_k1_minus_k3,iEEG_k1_minus_k3,'MarkerEdgeColor','k','MarkerFaceColor',[0 0 0]); 
h=lsline; set(h(1),'color',[0 0 0],'LineWidth',3);
set(gca,'Fontsize',14,'FontWeight','bold','LineWidth',2,'TickDir','out');
set(gcf,'color','w');
title({['kstate 1 vs 3: ' Window_dur ' sec windows']; ...
    ['r = ' num2str(k1k3BOLD_vs_k1k3iEEG_change_corr) ' p = ' num2str(k1k3BOLD_vs_k1k3iEEG_change_p)]},'Fontsize',12); 
xlabel('BOLD FC change');
ylabel('iEEG FC change');
set(gcf,'PaperPositionMode','auto');

% k2 vs k3 change: BOLD vs iEEG
subplot(1,3,3)
scatter(BOLD_k2_minus_k3,iEEG_k2_minus_k3,'MarkerEdgeColor','k','MarkerFaceColor',[0 0 0]); 
h=lsline; set(h(1),'color',[0 0 0],'LineWidth',3);
set(gca,'Fontsize',14,'FontWeight','bold','LineWidth',2,'TickDir','out');
set(gcf,'color','w');
title({['kstate 2 vs 3: ' Window_dur ' sec windows']; ...
    ['r = ' num2str(k2k3BOLD_vs_k2k3iEEG_change_corr) ' p = ' num2str(k2k3BOLD_vs_k2k3iEEG_change_p)]},'Fontsize',12); 
xlabel('BOLD FC change');
ylabel('iEEG FC change');
set(gcf,'PaperPositionMode','auto');
end
pause; close;

% iEEG correlations between k states
if states==3
kstates_iEEG_allcorr=[k1k2_iEEG_corr k1k3_iEEG_corr k2k3_iEEG_corr];

    plot(1:length(kstates_iEEG_allcorr),kstates_iEEG_allcorr,'k.--', ...
        'LineWidth',2,'Color',[.6 .6 .6],'MarkerSize',25,'MarkerEdgeColor',[.3 .3 .3]);      
       set(gca,'Xtick',0:1:4)
 set(gca,'XTickLabel',{'','k1-k2', 'k1-k3','k2-k3'})
 set(gca,'Fontsize',14,'FontWeight','bold','LineWidth',2,'TickDir','out');
  ylabel('iEEG between-state correlation (r)'); 
  
    hold on
   set(gca,'box','off'); 
set(gca,'Fontsize',14,'FontWeight','bold','LineWidth',2,'TickDir','out');
set(gcf,'color','w');
  %ylim([0 1]);
   set(gca,'Xtick',0:1:4)
   set(gca,'XTickLabel',{'','k1-k2', 'k1-k3','k2-k3'})
ylabel('iEEG between-state correlation (r)'); 
 print('-opengl','-r300','-dpng',strcat([pwd,filesep,'electrode_spheres/SBCA',filesep,'figs',filesep,'kstates',filesep,[roi1 '_iEEG_vs_iEEG_kstates_' Window_dur]]));
pause; close;
end

% BOLD correlations between kstates
if states==3
kstates_BOLD_allcorr=[k1k2_BOLD_corr k1k3_BOLD_corr k2k3_BOLD_corr];

    plot(1:length(kstates_BOLD_allcorr),kstates_BOLD_allcorr,'k.--', ...
        'LineWidth',2,'Color',[.6 .6 .6],'MarkerSize',25,'MarkerEdgeColor',[.3 .3 .3]);      
       set(gca,'Xtick',0:1:4)
 set(gca,'XTickLabel',{'','k1-k2', 'k1-k3','k2-k3'})
 set(gca,'Fontsize',14,'FontWeight','bold','LineWidth',2,'TickDir','out');
  ylabel('BOLD between-state correlation (r)'); 
  
    hold on
   set(gca,'box','off'); 
set(gca,'Fontsize',14,'FontWeight','bold','LineWidth',2,'TickDir','out');
set(gcf,'color','w');
  %ylim([0 1]);
   set(gca,'Xtick',0:1:4)
   set(gca,'XTickLabel',{'','k1-k2', 'k1-k3','k2-k3'})
ylabel('BOLD between-state correlation (r)'); 
 print('-opengl','-r300','-dpng',strcat([pwd,filesep,'electrode_spheres/SBCA',filesep,'figs',filesep,'kstates',filesep,[roi1 '_BOLD_vs_BOLD_kstates_' Window_dur]]));
pause; close;
end

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
cfg.elecColorScale=[-1.5 2];
%cfg.elecColorScale='minmax';
cfgOut=plotPialSurf(Patient,cfg);
print('-opengl','-r300','-dpng',strcat([pwd,filesep,'electrode_spheres/SBCA',filesep,'figs',filesep,'kstates',filesep,[roi1 '_BOLD_FC_run1_k1_' Window_dur]]));
 
% iEEG k1 state
cfg=[];
cfg.elecColors=k1_iEEG;
cfg.elecNames=elecnames;
cfg.ignoreChans=ignoreChans;
cfg.title=[roi1 ' iEEG: k1 state']; 
cfg.view=[hemi 'omni'];
cfg.elecUnits='z';
cfg.pullOut=3;
cfg.elecColorScale=[-0.1 0.4];
%cfg.elecColorScale='minmax';
cfgOut=plotPialSurf(Patient,cfg);
print('-opengl','-r300','-dpng',strcat([pwd,filesep,'electrode_spheres/SBCA',filesep,'figs',filesep,'kstates',filesep,[roi1 '_iEEG_FC_run' runs '_k1_' Window_dur]]));

% BOLD k2 state
cfg=[];
cfg.elecColors=k2_BOLD;
cfg.elecNames=elecnames;
cfg.ignoreChans=ignoreChans;
cfg.title=[roi1 ' BOLD: k2 state']; 
cfg.view=[hemi 'omni'];
cfg.elecUnits='z';
cfg.pullOut=3;
cfg.elecColorScale=[-1.5 2];
%cfg.elecColorScale='minmax';
cfgOut=plotPialSurf(Patient,cfg);
print('-opengl','-r300','-dpng',strcat([pwd,filesep,'electrode_spheres/SBCA',filesep,'figs',filesep,'kstates',filesep,[roi1 '_BOLD_FC_run1_k2_' Window_dur]]));

% iEEG k2 state
cfg=[];
cfg.elecColors=k2_iEEG;
cfg.elecNames=elecnames;
cfg.ignoreChans=ignoreChans;
cfg.title=[roi1 ' iEEG: k2 state']; 
cfg.view=[hemi 'omni'];
cfg.elecUnits='z';
cfg.pullOut=3;
cfg.elecColorScale=[-0.1 0.4];
%cfg.elecColorScale='minmax';
cfgOut=plotPialSurf(Patient,cfg);
print('-opengl','-r300','-dpng',strcat([pwd,filesep,'electrode_spheres/SBCA',filesep,'figs',filesep,'kstates',filesep,[roi1 '_iEEG_FC_run' runs '_k2_' Window_dur]]));

if states==3
% BOLD k3 state
cfg=[];
cfg.elecColors=k3_BOLD;
cfg.elecNames=elecnames;
cfg.ignoreChans=ignoreChans;
cfg.title=[roi1 ' BOLD: k3 state']; 
cfg.view=[hemi 'omni'];
cfg.elecUnits='z';
cfg.pullOut=3;
cfg.elecColorScale=[-1.5 2];
%cfg.elecColorScale='minmax';
cfgOut=plotPialSurf(Patient,cfg);
print('-opengl','-r300','-dpng',strcat([pwd,filesep,'electrode_spheres/SBCA',filesep,'figs',filesep,'kstates',filesep,[roi1 '_BOLD_FC_run1_k3_' Window_dur]]));

% iEEG k3 state
cfg=[];
cfg.elecColors=k3_iEEG;
cfg.elecNames=elecnames;
cfg.ignoreChans=ignoreChans;
cfg.title=[roi1 ' iEEG: k3 state']; 
cfg.view=[hemi 'omni'];
cfg.elecUnits='z';
cfg.pullOut=3;
cfg.elecColorScale=[-0.1 0.4];
%cfg.elecColorScale='minmax';
cfgOut=plotPialSurf(Patient,cfg);
print('-opengl','-r300','-dpng',strcat([pwd,filesep,'electrode_spheres/SBCA',filesep,'figs',filesep,'kstates',filesep,[roi1 '_iEEG_FC_run' runs '_k3_' Window_dur]]));
end
pause; close('all');

% plot BOLD change and iEEG change for between-state pair with max
% correspondence
if states==3
    maxcorr=max(abs(BOLD_iEEG_kstates_allcorr));
ind=find(abs(BOLD_iEEG_kstates_allcorr)==maxcorr);
if ind==1
    BOLD_plot=BOLD_k1_minus_k2; BOLD_title=['BOLD k1-k2'];
    iEEG_plot=iEEG_k1_minus_k2; iEEG_title=['iEEG k1-k2'];
elseif ind==2
    BOLD_plot=BOLD_k1_minus_k2; BOLD_title=['BOLD k1-k2'];
    iEEG_plot=iEEG_k1_minus_k3; iEEG_title=['iEEG k1-k3'];
elseif ind==3
     BOLD_plot=BOLD_k1_minus_k2; BOLD_title=['BOLD k1-k2'];
    iEEG_plot=iEEG_k2_minus_k3; iEEG_title=['iEEG k2-k3'];
elseif ind==4
     BOLD_plot=BOLD_k1_minus_k3; BOLD_title=['BOLD k1-k3'];
    iEEG_plot=iEEG_k1_minus_k2; iEEG_title=['iEEG k1-k2'];
elseif ind==5
     BOLD_plot=BOLD_k1_minus_k3; BOLD_title=['BOLD k1-k3'];
    iEEG_plot=iEEG_k1_minus_k3; iEEG_title=['iEEG k1-k3'];
elseif ind==6
     BOLD_plot=BOLD_k1_minus_k3; BOLD_title=['BOLD k1-k3'];
    iEEG_plot=iEEG_k2_minus_k3; iEEG_title=['iEEG k2-k3'];
elseif ind==7
     BOLD_plot=BOLD_k2_minus_k3; BOLD_title=['BOLD k2-k3'];
    iEEG_plot=iEEG_k1_minus_k2; iEEG_title=['iEEG k1-k2'];
elseif ind==8
         BOLD_plot=BOLD_k2_minus_k3; BOLD_title=['BOLD k2-k3'];
    iEEG_plot=iEEG_k1_minus_k3; iEEG_title=['iEEG k1-k3'];
elseif ind==9
         BOLD_plot=BOLD_k2_minus_k3; BOLD_title=['BOLD k2-k3'];
    iEEG_plot=iEEG_k2_minus_k3; iEEG_title=['iEEG k2-k3'];
end

% flip BOLD values if BOLD-iEEG state difference corr is negative
if BOLD_iEEG_kstates_allcorr(ind)<0
    BOLD_plot=-BOLD_plot;
end
% BOLD change plot
cfg=[];
cfg.elecColors=BOLD_plot;
cfg.elecNames=elecnames;
cfg.ignoreChans=ignoreChans;
cfg.title=[roi1 ' ' BOLD_title ': r = ' num2str(maxcorr)]; 
cfg.view=[hemi 'omni'];
cfg.elecUnits='z';
cfg.pullOut=3;
%cfg.elecColorScale=[-1.5 2];
cfg.elecColorScale='minmax';
cfgOut=plotPialSurf(Patient,cfg);
print('-opengl','-r300','-dpng',strcat([pwd,filesep,'electrode_spheres/SBCA',filesep,'figs',filesep,'kstates',filesep,[roi1 '_' BOLD_title '_' Window_dur]]));

% iEEG change plot
cfg=[];
cfg.elecColors=iEEG_plot;
cfg.elecNames=elecnames;
cfg.ignoreChans=ignoreChans;
cfg.title=[roi1 ' ' iEEG_title ': r = ' num2str(maxcorr)]; 
cfg.view=[hemi 'omni'];
cfg.elecUnits='z';
cfg.pullOut=3;
%cfg.elecColorScale=[-1.5 2];
cfg.elecColorScale='minmax';
cfgOut=plotPialSurf(Patient,cfg);
print('-opengl','-r300','-dpng',strcat([pwd,filesep,'electrode_spheres/SBCA',filesep,'figs',filesep,'kstates',filesep,[roi1 '_' iEEG_title '_' Window_dur]]));
end
pause; close;