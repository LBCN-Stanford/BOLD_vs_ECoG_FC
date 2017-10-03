% Run on outputs from plot_dFC_pair.m
% DAN: yellowgreen, emeraldgreen

% time series for 2 electrodes
FigHandle = figure('Position', [200, 600, 800, 300]);
figure(1)
time=(1:length(roi1_ts))/iEEG_sampling;
%title({[BOLD ' ' freq ': ' roi1 ' vs ' roi2]; ['r = ' num2str(static_fc)]} ,'Fontsize',12);
xlabel(['Time (sec)']); ylabel(['Signal']);
set(gca,'Fontsize',18,'Fontweight','bold','LineWidth',2,'TickDir','out','box','off');
set(gcf,'color','w');
hold on;
p=plot(time,roi1_ts_norm,time,roi2_ts_norm);
p(1).LineWidth=2; p(1).Color=cdcol.yellowgeen;
p(2).LineWidth=2; p(2).Color=cdcol.emeraldgreen;
xlim([0,time(end)]);
ylim([-6 6]);
% legend([roi1],[roi2]);

% HFB vs alpha SWCs
    FigHandle = figure('Position', [200, 600, 900, 300]);
    figure(1)
p=plot(1:length(all_windows_HFB_medium_fisher),norm_all_windows_HFB_medium_fisher,...
1:length(all_windows_Alpha_medium_fisher),norm_all_windows_Alpha_medium_fisher);
p(1).LineWidth=3; p(1).Color=[cdcol.turquoiseblue];
p(2).LineWidth=3; p(2).Color=[cdcol.scarlet];
legend('HFB','α','Location','southeast')
%title({['Dynamic FC (0.1-1 Hz): ' roi1 ' vs ' roi2]; ...
    %['Step size = ' num2str(step_size) ' sec; r = ' num2str(SWC_HFB_vs_alpha)]} ,'Fontsize',12);
xlabel(['Window number (' num2str(window_duration) ' sec windows)']); ylabel(['Correlation (z)']);
set(gca,'Fontsize',18,'Fontweight','bold','LineWidth',2,'TickDir','out','box','off');
set(gcf,'color','w');
xticks([0 20 40 60 80 100 120])

xlim auto
%xlim([0,length(all_windows_HFB_medium_fisher);



