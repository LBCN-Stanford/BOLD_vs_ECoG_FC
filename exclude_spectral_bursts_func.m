function exclude_spectral_bursts_func(Patient,runname)

getECoGSubDir;
global globalECoGDir;
cd([globalECoGDir '/Rest/' Patient '/Run' runname]);

%% Exclude spectral bursts (after TF averaging and edge cropping)

% Patient=input('Patient: ','s');
% runname=input('Run name: ','s');

%% set deviations from interquartile range
% According to Honey et al (2012 Neuron) - power value more than 6x the interquartile range from the median

%iqr_dev=5;
%% set absolute z threshold
z_dev=8;

getECoGSubDir;
global globalECoGDir;
cd([globalECoGDir '/Rest/' Patient '/Run' runname]);

%% Load HFB
pHFB_fname=dir('bptf_mediumpHFBbtf*');
pHFB_fname=pHFB_fname(2,1).name;
pHFB=spm_eeg_load([pHFB_fname]);

HFB_burst_chans=[];
for HFB_chan=1:size(pHFB,1)
    chan_ts=pHFB(HFB_chan,:)';
    chan_ts_z=(chan_ts-mean(chan_ts))/std(chan_ts);
    HFB_ts(:,HFB_chan)=pHFB(HFB_chan,:)';
    HFB_ts_z(:,HFB_chan)=chan_ts_z;
end

for i=1:size(pHFB,1)
    max_HFB=abs(max(HFB_ts_z(:,i)));
    if max_HFB>8
        HFB_burst_chans=[HFB_burst_chans i];
        display(['chan ' num2str(i) ' has HFB bursts'])
    end
end


% HFB_burst_chans=[];
% for i=1:size(HFB_ts,2)
% chan_iqr=iqr(HFB_ts(:,i));
% chan_median=median(HFB_ts(:,i));
% burst_thr_upper=chan_median+chan_iqr*iqr_dev;
% burst_thr_lower=chan_median-chan_iqr*iqr_dev;
% num_bursts_upper=length(find(HFB_ts(:,i)>burst_thr_upper));
% num_bursts_lower=length(find(HFB_ts(:,i)<burst_thr_lower));
% num_bursts=num_bursts_upper+num_bursts_lower;
% display(['Number of HFB bursts for chan ' num2str(i) ': ' num2str(num_bursts)])
% if num_bursts>0
% HFB_burst_chans=[HFB_burst_chans i];
% end
% end

%% Load Gamma
% pGamma_fname=dir('pGammalog*');
% pGamma_fname=pGamma_fname(2,1).name;
% pGamma=spm_eeg_load([pGamma_fname]);
% 
% for Gamma_chan=1:size(pGamma,1)
%     Gamma_ts(:,Gamma_chan)=pGamma(Gamma_chan,:)';   
% end
% 
% for i=1:size(Gamma_ts,2)
% chan_iqr=iqr(Gamma_ts(:,i));
% chan_median=median(Gamma_ts(:,i));
% burst_thr_upper=chan_median+chan_iqr*iqr_dev;
% burst_thr_lower=chan_median-chan_iqr*iqr_dev;
% num_bursts_upper=length(find(Gamma_ts(:,i)>burst_thr_upper));
% num_bursts_lower=length(find(Gamma_ts(:,i)<burst_thr_lower));
% num_bursts=num_bursts_upper+num_bursts_lower;
% display(['Number of Gamma bursts for chan ' num2str(i) ': ' num2str(num_bursts)])
% end
% 
% %% Load Alpha
% pAlpha_fname=dir('pAlphalog*');
% pAlpha_fname=pAlpha_fname(2,1).name;
% pAlpha=spm_eeg_load([pAlpha_fname]);
% 
% for Alpha_chan=1:size(pAlpha,1)
%     chan_ts=pAlpha(Alpha_chan,:)';
%     chan_ts_z=(chan_ts-mean(chan_ts))/std(chan_ts);
%     Alpha_ts(:,Alpha_chan)=pAlpha(Alpha_chan,:)';
%     Alpha_ts_z(:,Alpha_chan)=chan_ts_z;
% end
% 
% for i=1:size(Alpha_ts,2)
% chan_iqr=iqr(Alpha_ts(:,i));
% chan_median=median(Alpha_ts(:,i));
% burst_thr_upper=chan_median+chan_iqr*iqr_dev;
% burst_thr_lower=chan_median-chan_iqr*iqr_dev;
% num_bursts_upper=length(find(Alpha_ts(:,i)>burst_thr_upper));
% num_bursts_lower=length(find(Alpha_ts(:,i)<burst_thr_lower));
% num_bursts=num_bursts_upper+num_bursts_lower;
% display(['Number of Alpha bursts for chan ' num2str(i) ': ' num2str(num_bursts)])
% end
% 
% %% Load Beta1
% pBeta1_fname=dir('pBeta1log*');
% pBeta1_fname=pBeta1_fname(2,1).name;
% pBeta1=spm_eeg_load([pBeta1_fname]);
% 
% for Beta1_chan=1:size(pBeta1,1)
%     Beta1_ts(:,Beta1_chan)=pBeta1(Beta1_chan,:)';   
% end
% 
% for i=1:size(Beta1_ts,2)
% chan_iqr=iqr(Beta1_ts(:,i));
% chan_median=median(Beta1_ts(:,i));
% burst_thr_upper=chan_median+chan_iqr*iqr_dev;
% burst_thr_lower=chan_median-chan_iqr*iqr_dev;
% num_bursts_upper=length(find(Beta1_ts(:,i)>burst_thr_upper));
% num_bursts_lower=length(find(Beta1_ts(:,i)<burst_thr_lower));
% num_bursts=num_bursts_upper+num_bursts_lower;
% display(['Number of Beta1 bursts for chan ' num2str(i) ': ' num2str(num_bursts)])
% end
% 
% %% Load Beta2
% pBeta2_fname=dir('pBeta2log*');
% pBeta2_fname=pBeta2_fname(2,1).name;
% pBeta2=spm_eeg_load([pBeta2_fname]);
% 
% for Beta2_chan=1:size(pBeta2,1)
%     Beta2_ts(:,Beta2_chan)=pBeta2(Beta2_chan,:)';   
% end
% 
% for i=1:size(Beta2_ts,2)
% chan_iqr=iqr(Beta2_ts(:,i));
% chan_median=median(Beta2_ts(:,i));
% burst_thr_upper=chan_median+chan_iqr*iqr_dev;
% burst_thr_lower=chan_median-chan_iqr*iqr_dev;
% num_bursts_upper=length(find(Beta2_ts(:,i)>burst_thr_upper));
% num_bursts_lower=length(find(Beta2_ts(:,i)<burst_thr_lower));
% num_bursts=num_bursts_upper+num_bursts_lower;
% display(['Number of Beta2 bursts for chan ' num2str(i) ': ' num2str(num_bursts)])
% end
% 
% %% Load Theta
% pTheta_fname=dir('pThetalog*');
% pTheta_fname=pTheta_fname(2,1).name;
% pTheta=spm_eeg_load([pTheta_fname]);
% 
% for Theta_chan=1:size(pTheta,1)
%     Theta_ts(:,Theta_chan)=pTheta(Theta_chan,:)';   
% end
% 
% for i=1:size(Theta_ts,2)
% chan_iqr=iqr(Theta_ts(:,i));
% chan_median=median(Theta_ts(:,i));
% burst_thr_upper=chan_median+chan_iqr*iqr_dev;
% burst_thr_lower=chan_median-chan_iqr*iqr_dev;
% num_bursts_upper=length(find(Theta_ts(:,i)>burst_thr_upper));
% num_bursts_lower=length(find(Theta_ts(:,i)<burst_thr_lower));
% num_bursts=num_bursts_upper+num_bursts_lower;
% display(['Number of Theta bursts for chan ' num2str(i) ': ' num2str(num_bursts)])
% end
% 
% 
% %% Load Delta
% pDelta_fname=dir('pDeltalog*');
% pDelta_fname=pDelta_fname(2,1).name;
% pDelta=spm_eeg_load([pDelta_fname]);
% 
% for Delta_chan=1:size(pDelta,1)
%     Delta_ts(:,Delta_chan)=pDelta(Delta_chan,:)';   
% end
% 
% for i=1:size(Delta_ts,2)
% chan_iqr=iqr(Delta_ts(:,i));
% chan_median=median(Delta_ts(:,i));
% burst_thr_upper=chan_median+chan_iqr*iqr_dev;
% burst_thr_lower=chan_median-chan_iqr*iqr_dev;
% num_bursts_upper=length(find(Delta_ts(:,i)>burst_thr_upper));
% num_bursts_lower=length(find(Delta_ts(:,i)<burst_thr_lower));
% num_bursts=num_bursts_upper+num_bursts_lower;
% display(['Number of Delta bursts for chan ' num2str(i) ': ' num2str(num_bursts)])
% end

% Mark bad channels in file
display([num2str(length(HFB_burst_chans)) ' channels marked as bad in HFB file'])
display([num2str(HFB_burst_chans)])
d{i}=spm_eeg_load([pHFB_fname]);
newbad=[d{i}.badchannels HFB_burst_chans]; % where 33 = new chans
d{i}=badchannels(d{i},newbad,ones(length(newbad),1));
save(d{i});



