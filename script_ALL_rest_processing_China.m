%function script_ALL_rest_processing(Patient,runname)
% CONVERT FROM EDF FIRST, THEN MANUALLY CHECK ELECTRODE NAMES
% run set_badchans_rest.m first

%==========================================================================
% Written by Aaron Kucyi, LBCN, Stanford University
%==========================================================================


%% Set patient name and run number
Patient=input('Patient: ','s'); sub=Patient;
runname=input('Run (e.g. 2): ','s'); run=runname; 
sampling=input('Sampling rate (Hz): ','s'); srate=str2num(sampling);
getECoGSubDir; global globalECoGDir;
cd([globalECoGDir '/Rest/' sub]);

%% Load bad channel list (or set none if no list)
if exist('bad_chans.mat','file')>0
load('bad_chans.mat');
else 
    bad_chans=[];
end

cd([globalECoGDir '/Rest/' sub '/Run' run]);
%% Default parameters

%% Load SPM .mat
display(['Choose EDF-converted .mat data']);
fname_spm=spm_select;
load([fname_spm]);

%% Correct the sampling rate to 2000 Hz and downsample to 1000 Hz

% D.Fsample=sampling;
% save(fname_spm,'D');
% D=spm_eeg_load([fname_spm]);
% 
% S.D=D;
% S.fsample_new=1000;
% D=spm_eeg_downsample(S);
% fname_dspm=[D.fname];

%% Filter iEEG data and detect bad channels
LBCN_filter_badchans_China(fname_spm,[],bad_chans,1,[]);
fname_spm_fff=['fff' D.fname];

%% Plot power spectrum for manual removal of outlier channels
LBCN_plot_power_spectrum(fname_spm_fff,[10:1000]);

%% Common average re-referencing
LBCN_montage(fname_spm_fff);
fname_spm_fffM=['Mfff' D.fname];

%% TF decomposition
batch_ArtefactRejection_TF_norescale(fname_spm_fffM);
fname_spm_tf=['tf_aMfff' D.fname];

%% LogR transform (normalize)
LBCN_baseline_Timeseries(fname_spm_tf,'b','logR')
fname_spm_btf=['btf_aMfff' D.fname];

%% Frequency band averaging
batch_AverageFreq(fname_spm_btf);

%% Chop 2 sec from edges (beginning and end)
crop_edges_postTF_func(Patient,runname,fname_spm_tf,);
fname_HFB=['pHFBtf_aMfff' D.fname];
fname_Alpha=['pAlphatf_aMfff' D.fname];
fname_Delta=['pDeltatf_aMfff' D.fname];
fname_Theta=['pThetatf_aMfff' D.fname];
fname_Beta1=['pBeta1tf_aMfff' D.fname];
fname_Beta2=['pBeta2tf_aMfff' D.fname];
fname_Gamma=['pGammatf_aMfff' D.fname];

%% Remove spectral bursts (as in Honey et al 2012, Neuron)
% currently only for HFB
%exclude_spectral_bursts_func(Patient,runname)

%% Temporal filtering: 0.1-1Hz, <0.1Hz
batch_bandpass_medium(fname_HFB);
batch_bandpass_medium(fname_Alpha);
batch_bandpass_medium(fname_Delta);
batch_bandpass_medium(fname_Theta);
batch_bandpass_medium(fname_Beta1);
batch_bandpass_medium(fname_Beta2);
batch_bandpass_medium(fname_Gamma);

batch_lowpass_slow(fname_HFB);
batch_lowpass_slow(fname_Alpha);
batch_lowpass_slow(fname_Delta);
batch_lowpass_slow(fname_Theta);
batch_lowpass_slow(fname_Beta1);
batch_lowpass_slow(fname_Beta2);
batch_lowpass_slow(fname_Gamma);

