% Plot HFB vs alpha sliding window correlations between pre-defined region
% pairs for multiple window lengths in multiple subjects
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
list=importdata('HFB_vs_alpha_pairs_rest_sleep.txt',' ');
subjects=list.textdata(:,1);
subject_nums=list.data(:,1);
roi1=list.textdata(:,2); roi2=list.textdata(:,3);
run1_num=list.data(:,2);
run2_num=list.data(:,3);
sleep_runs=list.data(:,4);
networks=list.data(:,5);
%allsubs_seedcorr_allfreqs=NaN(length(subjects),7);

run1_allsubs_HFB_vs_alpha_SWC=[];
run2_allsubs_HFB_vs_alpha_SWC=[];
sleep_allsubs_HFB_vs_alpha_SWC=[];
for sub=1:length(subjects)
    Patient=subjects{sub}
    run1=num2str(run1_num(sub));
    run2=num2str(run2_num(sub));
    sleep_run=num2str(sleep_runs(sub));
    elec1=roi1(sub);
    elec2=roi2(sub);
    network=networks(sub);
%% Load corr values for each run
cd([globalECoGDir '/Rest/' Patient '/Run' run1])
run1_HFB_vs_alpha_SWC=load(['SWC_HFB_vs_Alpha_' char(elec1) char(elec2) '.mat']);

cd([globalECoGDir '/Rest/' Patient '/Run' run2])
run2_HFB_vs_alpha_SWC=load(['SWC_HFB_vs_Alpha_' char(elec1) char(elec2) '.mat']);

cd([globalECoGDir '/Sleep/' Patient '/Run' sleep_run])
sleep_HFB_vs_alpha_SWC=load(['SWC_HFB_vs_Alpha_' char(elec1) char(elec2) '.mat']);

%% concatenate across subjects
run1_allsubs_HFB_vs_alpha_SWC=[run1_allsubs_HFB_vs_alpha_SWC run1_HFB_vs_alpha_SWC];
run2_allsubs_HFB_vs_alpha_SWC=[run2_allsubs_HFB_vs_alpha_SWC run2_HFB_vs_alpha_SWC];
sleep_allsubs_HFB_vs_alpha_SWC=[sleep_allsubs_HFB_vs_alpha_SWC sleep_HFB_vs_alpha_SWC];
end

run1_DMN=run1_allsubs_HFB_vs_alpha_SWC(1).SWC_HFB_vs_Alpha_all;

%% Make plots
cd([globalECoGDir '/Rest/Figs/DMN_Core']);

% Network color coding
for i=1:length(networks)
    if networks(i)==1
   network_color(i,:)=cdcol.cobaltblue;
    elseif networks(i)==2
        network_color(i,:)=cdcol.grassgreen;
    elseif networks(i)==3
        network_color(i,:)=cdcol.orange;
    end
end
% Subject marker coding
for i=1:length(subject_nums)
    if subject_nums(i)==1
   subjectmarker{i,:}='<';
    elseif subject_nums(i)==2
        subjectmarker{i,:}='s';
    elseif subject_nums(i)==3
        subjectmarker{i,:}='o';
    elseif subject_nums(i)==4
        subjectmarker{i,:}='>';
    elseif subject_nums(i)==5
        subjectmarker{i,:}='^';
    end
end

% plot
FigHandle = figure('Position', [400, 600, 800, 470]);
figure(1)
for i=1:length(run1_allsubs_HFB_vs_alpha_SWC)
    plot(1:size(run1_allsubs_HFB_vs_alpha_SWC(1).SWC_HFB_vs_Alpha_all(1:6)),run1_allsubs_HFB_vs_alpha_SWC(i).SWC_HFB_vs_Alpha_all(1:6),[subjectmarker{i,:} '-'], ...
        'LineWidth',1,'Color',network_color(i,:),'MarkerFaceColor',network_color(i,:), ...
        'MarkerSize',8,'MarkerEdgeColor',network_color(i,:));      
    ylim([-1 1]);
    xlim([0 10]);
       set(gca,'Xtick',0:1:6)
 set(gca,'XTickLabel',{'','10', '20'})
 set(gca,'Fontsize',18,'FontWeight','bold','LineWidth',2,'TickDir','out');
  %ylabel('BOLD-ECoG FC correlation (r)'); 
  
  hold on
    plot(1:size(run2_allsubs_HFB_vs_alpha_SWC(1).SWC_HFB_vs_Alpha_all(1:6)),run2_allsubs_HFB_vs_alpha_SWC(i).SWC_HFB_vs_Alpha_all(1:6),[subjectmarker{i,:} '-'], ...
        'LineWidth',1,'Color',network_color(i,:),'MarkerFaceColor',network_color(i,:), ...
        'MarkerSize',8,'MarkerEdgeColor',network_color(i,:));  
    
   hold on
    plot(1:size(sleep_allsubs_HFB_vs_alpha_SWC(1).SWC_HFB_vs_Alpha_all(1:6)),sleep_allsubs_HFB_vs_alpha_SWC(i).SWC_HFB_vs_Alpha_all(1:6),[subjectmarker{i,:} '--'], ...
        'LineWidth',1,'Color',network_color(i,:),'MarkerFaceColor',network_color(i,:), ...
        'MarkerSize',8,'MarkerEdgeColor',network_color(i,:));  
    
    hold on
   set(gca,'box','off'); 
set(gca,'Fontsize',18,'FontWeight','bold','LineWidth',2,'TickDir','out');
set(gcf,'color','w');
legend
  ylim([-1 1]);
  xlim([0 6]);
   set(gca,'Xtick',0:1:6)
 set(gca,'XTickLabel',{'', '10','20','30','40','50','60'})
ylabel('HFB-Alpha FC Correlation (r)');
xlabel('Window Duration (sec)');
print('-opengl','-r300','-dpng',strcat([pwd,filesep,'HFB_vs_alpha_SWC_rest_sleep']));
end
