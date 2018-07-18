Patient=input('Patient: ','s');
%run_num=input('run (e.g. 1): ','s');
%depth=input('depth (1) or subdural (0) ','s');
rest=input('Rest(1) or Sleep(0) or gradCPT (2)? ','s');

%runname=['Run' run_num];
globalECoGDir=getECoGSubDir;
fsDir=getFsurfSubDir();

if rest=='1'
    maindir=[globalECoGDir '/Rest/' Patient];
cd([maindir]);
elseif rest=='0'
    maindir=[globalECoGDir '/Sleep/' Patient];
    cd([maindir]);
elseif rest=='2'
    maindir=[globalECoGDir '/gradCPT/' Patient];
    cd([maindir]);
end
run_list=load('runs.txt');

for i=1:length(run_list)
    curr_run=num2str(run_list(i));
 cd([maindir filesep 'Run' curr_run]);   
mkdir(['HFB_plots']);

% Load CAR data (no temporal filter)
    filenames=dir('Mfff*');
    filename=filenames(2,1).name;
D_CAR=spm_eeg_load(filename);

    % Load HFB data (bptf)
       filenames=dir('bptf_mediumHFB*');
    if isempty(filenames)==1
   filenames=dir('bptf_mediumpHFB*');
    end
filename=filenames(2,1).name;
D_HFB=spm_eeg_load(filename); 

%% Make and save plots

for i=1:size(D_CAR,1)
        HFB_z=[]; raw_HFB=[];
        raw_HFB=D_HFB(i,:)';
    HFB_z=(raw_HFB-mean(raw_HFB)/(std(raw_HFB)));
    CAR_ts=D_CAR(i,:)';
    chan_sd=num2str(std(CAR_ts));
    if ~isempty(find(i==D_HFB.badchannels))
    bad='bad';
    else bad='good';
        elec_name=D_HFB.chanlabels(i);
        elec_name=char(elec_name);
    end 
    
    FigHandle = figure('Position', [200, 600, 1200, 800]);
   figure(1);
   subplot(2,1,1)
   title(['Channel ' elec_name ' (' bad ') |μV| differences; SD=' chan_sd] , 'Fontsize', 12)
   hold on;
   CAR_diff_ts=abs(diff(CAR_ts));
   time_sec=D_CAR.time;
    plot(time_sec(1:end-1),CAR_diff_ts);
   %plot(1:length(diff(CAR_ts)),abs(diff(CAR_ts)));
   xlim([time_sec(1),time_sec(end-1)]);
   subplot(2,1,2);
   title(['Channel ' elec_name ' HFB (z-scored); max |z|=' num2str(max(abs(HFB_z)))] , 'Fontsize', 12)
   hold on;
   plot(time_sec,HFB_z);
   xlim([time_sec(1),time_sec(end)])
   ylims=ylim;
   % vertical line at 21 seconds
   line([21 21],[ylims(1) ylims(2)],'LineWidth',1,'Color',[.2 .2 .2],'LineStyle','--');
   print('-opengl','-r300','-dpng',strcat([pwd,filesep,'HFB_plots/HFB_' elec_name])); 
   close('all');
end
end
%axis([0,stimulus_onsets_PTB(end)+4,0,4])  


