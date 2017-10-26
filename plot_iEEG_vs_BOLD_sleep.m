% Plot HFB vs alpha local activity within 2 regions within a network per subjects 

% Must first run plot_dFC_pair.m on all relevant pairs of interest
% HFB_vs_alpha_local.txt file should contain subject name (column 1), electrode1 name (column 2),
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
fsDir=getFsurfSubDir();
globalECoGDir=getECoGSubDir;
cd([globalECoGDir '/Rest']);
mkdir('Figs');
cd Figs;
mkdir('dFC_analysis'); cd ..

%% Load subject, ECoG run numbers, and electrode list
list=importdata('dFC_iEEG_multirun.txt',' ');
subjects=list.textdata;
subject_nums=list.data(:,1);
elecs=list.data(:,2);
networks=list.data(:,3);
rest_run1=list.data(:,4); rest_run2=list.data(:,5);
sleep_run=list.data(:,6); heaven_run=list.data(:,7);

allelecs_HFB_sleep_vs_BOLD=[];
%% Loop through subjects and electrodes
for sub=1:length(subjects)
    Patient=subjects{sub}
    curr_rest_run1=rest_run1(sub);
    curr_rest_run2=rest_run2(sub);
    elec=elecs(sub)
    network=networks(sub);
    curr_sleep_run=sleep_run(sub);
    curr_heaven_run=heaven_run(sub);

 %% get elec names
fsDir=getFsurfSubDir();
parcOut=elec2Parc_v2([Patient],'DK',0);
elecNames = parcOut(:,1);

%% Load sleep FC vs BOLD FC for all elecs
cd([globalECoGDir '/Sleep/' Patient '/Run' num2str(curr_sleep_run) '/BOLD_ECoG_figs/GSR']);
HFB_sleep_vs_BOLD=load(['corr_BOLD_HFB_medium_allelecs.mat']);

%% Get sleep FC vs BOLD for elecs of interest
HFB_sleep_vs_BOLD_elec=HFB_sleep_vs_BOLD.corr_BOLD_HFB_medium_allelecs(elec);

%% concatenate across subjects
allelecs_HFB_sleep_vs_BOLD=[allelecs_HFB_sleep_vs_BOLD HFB_sleep_vs_BOLD_elec];
end


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
network_color=[network_color; network_color]; % duplicate list (for 2 electrodes per network)

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

subjectmarker=[subjectmarker; subjectmarker]; % duplicate list (for 2 electrodes per network)

FigHandle = figure('Position', [400, 600, 150, 400]);
figure(1)

% plot SD + SE bars
h=notBoxPlot(allelecs_HFB_sleep_vs_BOLD,1,0.01); axis([0.99,1.01,0,1]); set(gca, 'XTick', [],'Fontsize',14,'FontWeight','bold','LineWidth',2,'TickDir','out');
set(h.data,'markersize',0.001,'markerfacecolor',[0 0 0]) 
 set(gca,'XTickLabel',{'',''})
ylabel('Sleep-BOLD FC Correlation (r)');
set(gcf,'color','w');
set(gcf,'color','w');
%set(gcf,'Position',[500 500 100 450]);
%title({['p= ' num2str(p_val) ]; [' ']},'Fontsize',18);
set(gcf, 'PaperPositionMode', 'auto');
hold on

x=ones(size(allelecs_HFB_sleep_vs_BOLD));
a=0.995; b=1.005; % create custom jitter
x=(b-a).*rand(size(x))+a;
% plot data points with network and subject labelings
for i=1:length(allelecs_HFB_sleep_vs_BOLD)
    plot(x(i),allelecs_HFB_sleep_vs_BOLD(i),[subjectmarker{i,:} '-'], ...
        'LineWidth',1,'Color',network_color(i,:),'MarkerFaceColor',network_color(i,:), ...
        'MarkerSize',6,'MarkerEdgeColor',network_color(i,:));      
end
print('-opengl','-r300','-dpng',strcat([pwd,filesep,'Sleep_vs_BOLD_HFB_group']));
pause; close;







