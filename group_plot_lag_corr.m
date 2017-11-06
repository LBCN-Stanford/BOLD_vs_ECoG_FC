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

%% Make plots
cd([globalECoGDir '/Rest/Figs/DMN_Core']);

% Network color coding
for i=1:length(networks)
    if networks(i)==1
   network_color(i,:)=cdcol.cobaltblue;
    elseif networks(i)==2
        network_color(i,:)=cdcol.grassgreen;
    elseif networks(i)==3
        network_color(i,:)=cdcol.orange 
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
        subjectmarker{i,:}='^'
    end
end


FigHandle = figure('Position', [400, 600, 150, 400]);
figure(1)

% plot SD + SE bars
h=notBoxPlot(lag_peak_HFB_allsubs,1,0.01); axis([0.99,1.01,-.2,0.2]); set(gca, 'XTick', [],'Fontsize',14,'FontWeight','bold','LineWidth',2,'TickDir','out');
set(h.data,'markersize',0.001,'markerfacecolor',[0 0 0]) 
 set(gca,'XTickLabel',{'',''})
ylabel('Peak Lag of Correlation (sec)');
set(gcf,'color','w');
set(gcf,'color','w');
%set(gcf,'Ytick',1:1:11)
%set(gca,'YTickLabel',{'-0.5','-0.4','-0.3','-0.2','-0.1','0','0.1','0.2','0.3','0.4', '0.5'})
%set(gcf,'Position',[500 500 100 450]);
%title({['p= ' num2str(p_val) ]; [' ']},'Fontsize',18);
set(gcf, 'PaperPositionMode', 'auto');
hold on

x=ones(size(lag_peak_HFB_allsubs));
a=0.995; b=1.005; % create custom jitter
x=(b-a).*rand(size(x))+a;
% plot data points with network and subject labelings
for i=1:length(lag_peak_HFB_allsubs)
    plot(x(i),lag_peak_HFB_allsubs(i),[subjectmarker{i,:} '-'], ...
        'LineWidth',1,'Color',network_color(i,:),'MarkerFaceColor',network_color(i,:), ...
        'MarkerSize',6,'MarkerEdgeColor',network_color(i,:));  
end
print('-opengl','-r300','-dpng',strcat([pwd,filesep,'lag_peak_HFB_group']));
pause; close;

% Remove outliers for alpha plot
lag_peak_Alpha_allsubs(find(lag_peak_Alpha_allsubs>1))=NaN;

FigHandle = figure('Position', [400, 600, 150, 400]);
figure(1)

% plot SD + SE bars
h=notBoxPlot(lag_peak_Alpha_allsubs,1,0.01); axis([0.99,1.01,-0.2,0.2]); set(gca, 'XTick', [],'Fontsize',14,'FontWeight','bold','LineWidth',2,'TickDir','out');
set(h.data,'markersize',0.001,'markerfacecolor',[0 0 0]) 
 set(gca,'XTickLabel',{'',''})
ylabel('Peak Lag of Correlation (sec)');
set(gcf,'color','w');
set(gcf,'color','w');
%set(gcf,'Position',[500 500 100 450]);
%title({['p= ' num2str(p_val) ]; [' ']},'Fontsize',18);
set(gcf, 'PaperPositionMode', 'auto');
hold on

x=ones(size(lag_peak_Alpha_allsubs));
a=0.995; b=1.005; % create custom jitter
x=(b-a).*rand(size(x))+a;
% plot data points with network and subject labelings
for i=1:length(lag_peak_Alpha_allsubs)
    plot(x(i),lag_peak_Alpha_allsubs(i),[subjectmarker{i,:} '-'], ...
        'LineWidth',1,'Color',network_color(i,:),'MarkerFaceColor',network_color(i,:), ...
        'MarkerSize',6,'MarkerEdgeColor',network_color(i,:));      
end
print('-opengl','-r300','-dpng',strcat([pwd,filesep,'lag_peak_Alpha_group']));
pause; close;


