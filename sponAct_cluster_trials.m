%% kmeans clustering of trials at target electrode for spontaneous activation events at a seed electrode
condition=input('Rest (1) gradCPT (2): ','s');
if condition=='1'
    condition='Rest'
elseif condition=='2'
    condition='gradCPT'
end

%% Defaults
k=3; % Number of kmeans clusters
k_perm=1000; % Number of kmeans repetitions
srate=1000; % sampling rate (Hz)
getECoGSubDir; global globalECoGDir;
sub=input('Patient: ','s');
elec_name=input('Target electrode name: ','s');
load('cdcol.mat');
color_options=[cdcol.orange; cdcol.cobaltblue; cdcol.grassgreen; cdcol.russet; cdcol.brown; cdcol.periwinkleblue; cdcol.lightolive; ...
    cdcol.metalicdarkgold; cdcol.purple; cdcol.portraitdarkflesh5; cdcol.lightcadmium; cdcol.darkulamarine; cdcol.pink];

%% Load epoched file
%cd([globalECoGDir filesep condition filesep sub filesep 'Run' run_num]);
D=spm_eeg_load;
elec_num=indchannel(D,elec_name);

%% Extract trials and prepare for kmeans clustering
trial_ts=[];
for i=1:size(D,3)
   trial_ts=[trial_ts; D(elec_num,:,i)];     
end

%% clustering based on Louvain algorithm
trial_ts_vert=trial_ts';
trial_mat=corrcoef(trial_ts_vert);
[M,Q]=community_louvain(trial_mat,[],[],'negative_asym');

%% silhouette values for different k solutions
silh=evalclusters(trial_ts,'kmeans','silhouette','klist',[2:20]);

%% kmeans clustering
[IDX,C]=kmeans(trial_ts,k,'distance','sqEuclidean','display','final','replicate',k_perm,'maxiter',250);

%% Get Louvain clusters' average time courses
  for i=1:max(M)
      louvain_cluster_ts=[];
      louvain_cluster_ts=trial_ts_vert(:,find(M==i));
      louvain_cluster_ts_mean(:,i)=mean(louvain_cluster_ts,2);  
      louvain_cluster_ts_SE(:,i)=std(louvain_cluster_ts')/sqrt(size(find(M==i),1));
  end
  
%% Get kmeans clusters' average time courses
  for i=1:k
      cluster_ts=[];
      cluster_ts=trial_ts_vert(:,find(IDX==i));
      cluster_ts_mean(:,i)=mean(cluster_ts,2);  
      cluster_ts_SE(:,i)=std(cluster_ts')/sqrt(size(find(IDX==i),1));
  end

  %% Number of trials classified per cluster
 for i=1:k
   nTrials_clusters(i)=length(find(IDX==i)); 
end 
  
  %% plot cluster time courses
  % Louvain
   figure1=figure('Position', [100, 100, 1024, 500]);
  for i=1:k
   plot(D.time,louvain_cluster_ts_mean(:,i),'LineWidth',2,'Color',color_options(i,:));
 set(gca,'Fontsize',14,'Fontweight','bold','LineWidth',2,'TickDir','out','box','off');
 ylabel('HFB Power');
 xlim([D.time(1) D.time(end)]);
  line([D.time(1) D.time(end)],[0 0],'LineWidth',1,'Color','k');
 hold on;
 
    shadedErrorBar(D.time,louvain_cluster_ts_mean(:,i),louvain_cluster_ts_SE(:,i),{'linewidth',2,'Color',color_options(i,:)},0.8);
    h=vline(0,'k-');
    title(['Louvain clusters']);
 hold on;
  end
  
  % kmeans
 figure1=figure('Position', [100, 100, 1024, 500]);
  for i=1:k
   plot(D.time,cluster_ts_mean(:,i),'LineWidth',2,'Color',color_options(i,:));
 set(gca,'Fontsize',14,'Fontweight','bold','LineWidth',2,'TickDir','out','box','off');
 ylabel('HFB Power');
 xlim([D.time(1) D.time(end)]);
  line([D.time(1) D.time(end)],[0 0],'LineWidth',1,'Color','k');
 hold on;
 
    shadedErrorBar(D.time,cluster_ts_mean(:,i),cluster_ts_SE(:,i),{'linewidth',2,'Color',color_options(i,:)},0.8);
    h=vline(0,'k-');
    title(['kmeans clusters']);
 hold on;
  end
  
  
  
  
  