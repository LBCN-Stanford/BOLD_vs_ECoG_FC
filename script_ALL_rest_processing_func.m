function script_ALL_rest_processing_batch(Patient,runname,TDT)


%function script_ALL_rest_processing(Patient,runname)
% run set_badchans.m first

%==========================================================================
% Written by Aaron Kucyi, LBCN, Stanford University
%==========================================================================


%% Set patient name and run number
% Patient=input('Patient: ','s'); sub=Patient;
% runname=input('Run (e.g. 2): ','s'); run=runname; 
% TDT=input('TDT (1) or EDF (0): ','s');

if TDT=='1'
    sampling_rate=input('sampling rate (Hz): ','s');
    sampling_rate=str2num(sampling_rate);
end

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

%% Convert EDF to SPM .mat
if TDT=='0';
display(['Choose raw EDF data']);
fname=spm_select;
[D,DC]=LBCN_convert_NKnew(fname);

elseif TDT=='1'
    [D]=Convert_TDTiEEG_to_SPMfa(sampling_rate,[],1); % downsample to 1000 Hz   
end
fname_spm = fullfile(D.path,D.fname);

%% Filter iEEG data and detect bad channels
LBCN_filter_badchans(fname_spm,[],bad_chans,1,[]);
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
crop_edges_postTF_func(Patient,runname,fname_spm_btf);
fname_HFB=['pHFBbtf_aMfff' D.fname];
fname_Alpha=['pAlphabtf_aMfff' D.fname];
fname_Delta=['pDeltabtf_aMfff' D.fname];
fname_Theta=['pThetabtf_aMfff' D.fname];
fname_Beta1=['pBeta1btf_aMfff' D.fname];
fname_Beta2=['pBeta2btf_aMfff' D.fname];
fname_Gamma=['pGammabtf_aMfff' D.fname];

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

