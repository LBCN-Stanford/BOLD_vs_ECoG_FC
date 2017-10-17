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
cd(['dFC_analysis']);
list=importdata('HFB_vs_alpha_local.txt',' ');
subjects=list.textdata(:,1);
subject_nums=list.data(:,1);
roi1=list.textdata(:,2); roi2=list.textdata(:,3);
run_num=list.data(:,2);
networks=list.data(:,3);

%% Loop through subjects and electrodes
allsubs_HFB_vs_alpha_local=[];
for sub=1:length(subjects)
    Patient=subjects{sub}
    run1=num2str(run_num(sub));
    elec1=roi1(sub);
    elec2=roi2(sub);
    network=networks(sub);
%% Load HFB vs alpha local correlation
cd([fsDir '/' Patient '/elec_recon/electrode_spheres/SBCA/figs/iEEG/Interfreq']);
HFB_alpha_local=load([char(elec1) '_HFB_alpha_corr.mat']);

%% concatenate across subjects
allsubs_HFB_vs_alpha_local=[allsubs_HFB_vs_alpha_local HFB_alpha_local.roi1_HFB_alpha_corr];
end

%% Stats - sign-rank test on HFB vs alpha values
p_val=signrank(allsubs_HFB_vs_alpha_local);

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


FigHandle = figure('Position', [400, 600, 150, 400]);
figure(1)

h=notBoxPlot(allsubs_HFB_vs_alpha_local,1,0.01); axis([0.99,1.01,-0.5,0.5]); set(gca, 'XTick', [],'Fontsize',14,'FontWeight','bold','LineWidth',2,'TickDir','out');
set(h.data,'markersize',0.001,'markerfacecolor',[0 0 0]) 
 set(gca,'XTickLabel',{'',''})
ylabel('HFB-Alpha Correlation (r)');
set(gcf,'color','w');
set(gcf,'color','w');
%set(gcf,'Position',[500 500 100 450]);
title({['p= ' num2str(p_val) ]; [' ']},'Fontsize',18);
set(gcf, 'PaperPositionMode', 'auto');
hold on

x=ones(size(allsubs_HFB_vs_alpha_local));
a=0.995; b=1.005; % creat custom jitter
x=(b-a).*rand(size(x))+a;
for i=1:length(allsubs_HFB_vs_alpha_local)
    plot(x(i),allsubs_HFB_vs_alpha_local(i),[subjectmarker{i,:} '-'], ...
        'LineWidth',1,'Color',network_color(i,:),'MarkerFaceColor',network_color(i,:), ...
        'MarkerSize',6,'MarkerEdgeColor',network_color(i,:));      

end







