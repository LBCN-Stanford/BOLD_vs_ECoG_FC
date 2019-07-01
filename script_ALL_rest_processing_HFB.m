%function script_ALL_rest_processing(Patient,runname)
% Must first run script_ALL_rest_processing_part1
% run set_badchans.m first

%==========================================================================
% Written by Aaron Kucyi, LBCN, Stanford University
%==========================================================================


%% Set patient name and run number
Patient=input('Patient: ','s'); sub=Patient;
run_list=input('Runs (e.g. [1 2 3 4]: ');
pause_time=input('pause before start (secs): ');
rest=input('Rest (1) or Sleep (2)? ','s');
Crop_ts='2'; % don't crop
%runname=input('Run (e.g. 2): ','s'); run=runname;
%pause_time=input('Pause time (sec) ');
%TDT=input('TDT (1) or EDF (0): ','s');
%China=input('China (1) or Stanford (0)? ','s');
%Crop_ts='2';
%Crop_ts=input('Crop time series (1) or not (0)? ','s');
%crop_secs=60;
% if Crop_ts=='1'
%     crop_start=input('
% end
%Cropping=input('Crop edges in TF domain by (e.g. 20 for 20 sec): ','s');
%sampling_rate=input('sampling rate (Hz): ','s'); sampling_rate=str2num(sampling_rate);   
%EDF_convert='1';
%EDF_convert=input('EDF already converted (1) or not or TDT (0)? ','s');

getECoGSubDir; global globalECoGDir;
cd([globalECoGDir '/Rest/' sub]);

%% Load bad channel list (or set none if no list)
if exist('bad_chans.mat','file')>0
load('bad_chans.mat');
else 
    bad_chans=[];
end

if rest=='1'
subdir=[globalECoGDir '/Rest/' sub];
elseif rest=='2'
subdir=[globalECoGDir '/Sleep/' sub];
end
%% Default parameters

for i=1:length(run_list)
    curr_run=num2str(run_list(i));
cd([subdir '/Run' curr_run]);
fname=dir(['Mfff*']);
if isempty(fname)==1
   fname=dir(['Mpff*']); 
end
fname_spm_fffM=fname(2,1).name;
%% Convert EDF to SPM .mat

% if pre-converted from EDF: downsample pre-converted EDF to 1000 Hz
% if EDF_convert=='1'
%     
%     display(['Choose raw EDF-converted .mat data']);
% fname=spm_select;
% if sampling_rate>1000
% S.D=[fname]; S.method='downsample'; S.fsample_new=1000;
% D=spm_eeg_downsample(S);
% fname_spm=[D.fname];
% run_length=(D.nsamples/D.fsample)/60;
% else
%     
% D=spm_eeg_load(fname);
%     fname_spm=[fname];
%     run_length=(D.nsamples/D.fsample)/60;
% end
% end

%% Filter iEEG data and detect bad channels
% if China=='0'
% LBCN_filter_badchans(fname_spm,[],bad_chans,1,[]);
% elseif China=='1'
% LBCN_filter_badchans_China(fname_spm,[],bad_chans,1,[]); 
% end
% fname_spm_fff=['fff' D.fname];
% 
% A=spm_eeg_load(['f' D.fname]);
% delete([A.fname]); delete([A.fnamedat]);
% A=spm_eeg_load(['ff' D.fname]);
% delete([A.fname]); delete([A.fnamedat]); A=[];

%% Chop 2 sec from edges (beginning and end) - to deal with flat line effects
% if Crop_ts=='1'
%     sampling=D.fsample;
% cropping=crop_secs*sampling; both=1;
% [D]=crop_edges_postTF_func(Patient,runname,fname_spm_fff,cropping,both,sampling);
% D.timeOnset=0; D=meeg(D); save(D);
% fname_spm_pfff=[D.fname];
% else
%     fname_spm_pfff=['fff' D.fname];
% end
% 
% %% Plot power spectrum for manual removal of outlier channels
% display(['Run length is ' num2str(run_length) ' mins']);
% if sampling_rate==1000
% LBCN_plot_power_spectrum_gradCPT_1000(fname_spm_pfff);
% elseif sampling_rate==500
%     LBCN_plot_power_spectrum_gradCPT(fname_spm_pfff);
% end

%% Common average re-referencing
%LBCN_montage(fname_spm_pfff);
%fname_spm_fffM=['M' fname_spm_pfff];

%% TF decomposition
pause(pause_time); % pause before this step for pause_time secs
batch_ArtefactRejection_TF_norescale_HFB(fname_spm_fffM);
fname_spm_tf=['tf_a' fname_spm_fffM];

%% LogR transform (normalize)
LBCN_baseline_Timeseries(fname_spm_tf,'b','logR')
fname_spm_btf=['btf_a' fname_spm_fffM];

%% Frequency band averaging
batch_Avg_HFB(fname_spm_btf);

%% Chop 20 sec from beginning
%cropping=20000; 
D=spm_eeg_load(fname_spm_fffM);
sampling_rate=D.fsample;
both=0;
%cropping=str2num(Cropping)*sampling_rate;

fname_HFB=['HFBbtf_a' fname_spm_fffM];

if Crop_ts=='1'
    D=spm_eeg_load(fname_HFB); D=struct(D); D.timeOnset=0; D=meeg(D); save(D);
[D]=crop_edges_postTF_func(Patient,runname,fname_HFB,cropping,both,sampling);
D.timeOnset=0; D=meeg(D); save(D);
end

if Crop_ts=='1'
fname_HFB=['pHFBbtf_aM' fname_spm_fffM];
% else
%   fname_HFB=['HFBbtf_aM' fname_spm_pfff];
% fname_Alpha=['Alphabtf_aM' fname_spm_pfff];
% fname_Delta=['Deltabtf_aM' fname_spm_pfff];
% fname_Theta=['Thetabtf_aM' fname_spm_pfff];
% fname_Beta1=['Beta1btf_aM' fname_spm_pfff];
% fname_Beta2=['Beta2btf_aM' fname_spm_pfff];
% fname_Gamma=['Gammabtf_aM' fname_spm_pfff];      
end

%% Temporal filtering: 0.1-1Hz, <0.1Hz, >1Hz
batch_bandpass_medium(fname_HFB);

batch_lowpass_slow(fname_HFB);

%LBCN_smooth_data(fname_HFB);

%LBCN_smooth_data_500ms(fname_HFB,500);

%% Label channels with HFB (0.1-1 Hz) spectral bursts as bad
%exclude_spectral_bursts_func(Patient,runname);

%% Delete intermediate files
  delete_file_mat=['btf_a' fname_spm_fffM];
    delete_file_dat=strrep(delete_file_mat,'.mat','.dat');
       delete(char(delete_file_mat));
   delete(char(delete_file_dat));
   
     delete_file_mat=['a' fname_spm_fffM];
    delete_file_dat=strrep(delete_file_mat,'.mat','.dat');
       delete(char(delete_file_mat));
   delete(char(delete_file_dat));
   
        delete_file_mat=['tf_a' fname_spm_fffM];
    delete_file_dat=strrep(delete_file_mat,'.mat','.dat');
       delete(char(delete_file_mat));
   delete(char(delete_file_dat));
end
