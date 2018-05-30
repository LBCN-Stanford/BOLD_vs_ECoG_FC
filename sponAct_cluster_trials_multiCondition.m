%% kmeans clustering of trials at target electrode for spontaneous activation events at a seed electrode
conditions={'gradCPT'; 'Rest'};

%% Defaults
run_louvain=0; % set to 1 to run Louvain clustering
run_kmeans=1; % set to 1 to run kmeans clustering
k=3; % Number of kmeans clusters
k_perm=1000; % Number of kmeans repetitions
distance_metric='correlation'; % distance metric for kmeans cluster (e.g. sqeuclidean, correlation)
srate=1000; % sampling rate (Hz)
getECoGSubDir; global globalECoGDir;
sub=input('Patient: ','s');
elec_name=input('Target electrode name: ','s');
load('cdcol.mat');
color_options=[cdcol.orange; cdcol.cobaltblue; cdcol.grassgreen; cdcol.russet; cdcol.brown; cdcol.periwinkleblue; cdcol.lightolive; ...
    cdcol.metalicdarkgold; cdcol.purple; cdcol.portraitdarkflesh5; cdcol.lightcadmium; cdcol.darkulamarine; cdcol.pink];

%% First Condition
    curr_cond=conditions{1};
%% Load epoched file
cd([globalECoGDir filesep curr_cond filesep sub]);
run_list=load('runs.txt'); run_list=run_list';
runs_string=num2str(run_list);
runs_string=strrep(runs_string,' ','_');
runs_string=strrep(runs_string,'__','_');
merge_dir=['mRun' runs_string];

cd([globalECoGDir filesep curr_cond filesep sub filesep merge_dir]);
display(['Select file for ' curr_cond]);
D=spm_eeg_load;
elec_num=indchannel(D,elec_name);

%% Extract trials and prepare for clustering
trial_ts_cond1=[];

for i=1:size(D,3)
   trial_ts_cond1=[trial_ts_cond1; D(elec_num,:,i)];     
end
trial_ts_vert_cond1=trial_ts_cond1';
trial_mat_cond1=corrcoef(trial_ts_vert_cond1);

%% clustering based on Louvain algorithm
if run_louvain==1
[M_cond1,Q_cond1]=community_louvain(trial_mat_cond1,[],[],'negative_asym');

% Get Louvain clusters' average time courses
  for i=1:max(M_cond1)
      louvain_cluster_ts_cond1=[];
      louvain_cluster_ts_cond1=trial_ts_vert_cond1(:,find(M_cond1==i));
      louvain_cluster_ts_mean_cond1(:,i)=mean(louvain_cluster_ts_cond1,2);  
      louvain_cluster_ts_SE_cond1(:,i)=std(louvain_cluster_ts_cond1')/sqrt(size(find(M_cond1==i),1));
  end
   
for i=1:max(M_cond1)
   nTrials_clusters_louvain_cond1(i)=length(find(M_cond1==i)); 
end
end

% silhouette values for different k solutions
if run_kmeans==1
silh_cond1=evalclusters(trial_ts_cond1,'kmeans','silhouette','klist',[2:20]);

%% kmeans clustering
[IDX_cond1,C_cond1]=kmeans(trial_ts_cond1,k,'distance',distance_metric,'display','final','replicate',k_perm,'maxiter',250);

%% Get kmeans clusters' average time courses
  for i=1:k
      cluster_ts_cond1=[];
      cluster_ts_cond1=trial_ts_vert_cond1(:,find(IDX_cond1==i));
      cluster_ts_mean_cond1(:,i)=mean(cluster_ts_cond1,2);  
      cluster_ts_SE_cond1(:,i)=std(cluster_ts_cond1')/sqrt(size(find(IDX_cond1==i),1));
  end

  %% Number of trials classified per cluster
 for i=1:k
   nTrials_clusters_cond1(i)=length(find(IDX_cond1==i)); 
 end 
  end

  %% plot cluster time courses
   % kmeans
  if run_kmeans==1
 figure1=figure('Position', [100, 100, 1024, 500]);
  for i=1:k
   plot(D.time,cluster_ts_mean_cond1(:,i),'LineWidth',2,'Color',color_options(i,:));
 set(gca,'Fontsize',14,'Fontweight','bold','LineWidth',2,'TickDir','out','box','off');
 ylabel('HFB Power');
 xlim([D.time(1) D.time(end)]);
  line([D.time(1) D.time(end)],[0 0],'LineWidth',1,'Color','k');
 hold on;
    shadedErrorBar(D.time,cluster_ts_mean_cond1(:,i),cluster_ts_SE_cond1(:,i),{'linewidth',2,'Color',color_options(i,:)},0.8);
    h=vline(0,'k-');
    title([curr_cond ': kmeans clusters']);
 hold on;
  end
  figure();
  plot(silh_cond1);
  title([curr_cond]);
  end
  
  % Louvain
  if run_louvain==1
  figure1=figure('Position', [100, 100, 1024, 500]);
  for i=1:max(M_cond1)
   plot(D.time,louvain_cluster_ts_mean_cond1(:,i),'LineWidth',2,'Color',color_options(i,:));
 set(gca,'Fontsize',14,'Fontweight','bold','LineWidth',2,'TickDir','out','box','off');
 ylabel('HFB Power');
 xlim([D.time(1) D.time(end)]);
  line([D.time(1) D.time(end)],[0 0],'LineWidth',1,'Color','k');
 hold on;
 
    shadedErrorBar(D.time,louvain_cluster_ts_mean_cond1(:,i),louvain_cluster_ts_SE_cond1(:,i),{'linewidth',2,'Color',color_options(i,:)},0.8);
    h=vline(0,'k-');
    title([curr_cond ': Louvain clusters']);
 hold on;
  end
  end
  
  %% Second condition
    curr_cond=conditions{2};
  cd([globalECoGDir filesep curr_cond filesep sub]);
run_list=load('runs.txt'); run_list=run_list';
runs_string=num2str(run_list);
runs_string=strrep(runs_string,' ','_');
runs_string=strrep(runs_string,'__','_');
merge_dir=['mRun' runs_string];

cd([globalECoGDir filesep curr_cond filesep sub filesep merge_dir]);
display(['Select file for ' curr_cond]);
D=spm_eeg_load;
elec_num=indchannel(D,elec_name);

%% Extract trials and prepare for kmeans clustering
trial_ts_cond2=[];

for i=1:size(D,3)
   trial_ts_cond2=[trial_ts_cond2; D(elec_num,:,i)];     
end

trial_ts_vert_cond2=trial_ts_cond2';
trial_mat_cond2=corrcoef(trial_ts_vert_cond2);

%% clustering based on Louvain algorithm
if run_louvain==1
[M_cond2,Q_cond2]=community_louvain(trial_mat_cond2,[],[],'negative_sym');

%% Get Louvain clusters' average time courses
  for i=1:max(M_cond2)
      louvain_cluster_ts_cond2=[];
      louvain_cluster_ts_cond2=trial_ts_vert_cond2(:,find(M_cond2==i));
      louvain_cluster_ts_mean_cond2(:,i)=mean(louvain_cluster_ts_cond2,2);  
      louvain_cluster_ts_SE_cond2(:,i)=std(louvain_cluster_ts_cond2')/sqrt(size(find(M_cond2==i),1));
  end
   
for i=1:max(M_cond2)
   nTrials_clusters_louvain_cond2(i)=length(find(M_cond2==i)); 
end
end

%% silhouette values for different k solutions
if run_kmeans==1
silh_cond2=evalclusters(trial_ts_cond2,'kmeans','silhouette','klist',[2:20]);

%% kmeans clustering
[IDX_cond2,C_cond2]=kmeans(trial_ts_cond2,k,'distance',distance_metric,'display','final','replicate',k_perm,'maxiter',250);

%% Get kmeans clusters' average time courses
  for i=1:k
      cluster_ts_cond2=[];
      cluster_ts_cond2=trial_ts_vert_cond2(:,find(IDX_cond2==i));
      cluster_ts_mean_cond2(:,i)=mean(cluster_ts_cond2,2);  
      cluster_ts_SE_cond2(:,i)=std(cluster_ts_cond2')/sqrt(size(find(IDX_cond2==i),1));
  end

  %% Number of trials classified per cluster
 for i=1:k
   nTrials_clusters_cond2(i)=length(find(IDX_cond2==i)); 
 end 
end

  %% plot cluster time courses
   % kmeans
  if run_kmeans==1
 figure1=figure('Position', [100, 100, 1024, 500]);
  for i=1:k
   plot(D.time,cluster_ts_mean_cond2(:,i),'LineWidth',2,'Color',color_options(i,:));
 set(gca,'Fontsize',14,'Fontweight','bold','LineWidth',2,'TickDir','out','box','off');
 ylabel('HFB Power');
 xlim([D.time(1) D.time(end)]);
  line([D.time(1) D.time(end)],[0 0],'LineWidth',1,'Color','k');
 hold on;
    shadedErrorBar(D.time,cluster_ts_mean_cond2(:,i),cluster_ts_SE_cond2(:,i),{'linewidth',2,'Color',color_options(i,:)},0.8);
    h=vline(0,'k-');
    title([curr_cond ': kmeans clusters']);
 hold on;
  end
  figure();
      plot(silh_cond2);
  title([curr_cond]);
  end

  % Louvain
  if run_louvain==1
  figure2=figure('Position', [100, 100, 1024, 500]);
  for i=1:max(M_cond2)
   plot(D.time,louvain_cluster_ts_mean_cond2(:,i),'LineWidth',2,'Color',color_options(i,:));
 set(gca,'Fontsize',14,'Fontweight','bold','LineWidth',2,'TickDir','out','box','off');
 ylabel('HFB Power');
 xlim([D.time(1) D.time(end)]);
  line([D.time(1) D.time(end)],[0 0],'LineWidth',1,'Color','k');
 hold on;
 
    shadedErrorBar(D.time,louvain_cluster_ts_mean_cond2(:,i),louvain_cluster_ts_SE_cond2(:,i),{'linewidth',2,'Color',color_options(i,:)},0.8);
    h=vline(0,'k-');
    title([curr_cond ': Louvain clusters']);
 hold on;
  end
  end
  
  %% correlate clusters between conditions
  if run_kmeans==1
  for i=1:k
     for j=1:k
         cluster_corr_conds(i,j)=corr(cluster_ts_mean_cond1(:,i),cluster_ts_mean_cond2(:,j));     
     end
  end
  end
      
      
      
  
  
  