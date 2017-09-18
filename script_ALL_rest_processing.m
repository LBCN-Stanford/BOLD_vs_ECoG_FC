%function script_ALL_rest_processing(Patient,runname)
% run set_badchans.m first

%==========================================================================
% Written by Aaron Kucyi, LBCN, Stanford University
%==========================================================================


%% Set patient name and run number
Patient=input('Patient: ','s'); sub=Patient;
rest=input('Rest (1) or Sleep (2)? ','s');
runname=input('Run (e.g. 2): ','s'); run=runname;
TDT=input('TDT (1) or EDF (0): ','s');

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

if rest=='1'
cd([globalECoGDir '/Rest/' sub '/Run' run]);
elseif rest=='2'
   cd([globalECoGDir '/Sleep/' sub '/Run' run]);
end
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
run_length=(D.nsamples/D.fsample)/60;

%% Filter iEEG data and detect bad channels
LBCN_filter_badchans(fname_spm,[],bad_chans,1,[]);
fname_spm_fff=['fff' D.fname];

A=spm_eeg_load(['f' D.fname]);
delete([A.fname]); delete([A.fnamedat]);
A=spm_eeg_load(['ff' D.fname]);
delete([A.fname]); delete([A.fnamedat]); A=[];

%% Chop 2 sec from edges (beginning and end) - to deal with flat line effects
cropping=2000; both=1;
crop_edges_postTF_func(Patient,runname,fname_spm_fff,cropping,both);
fname_spm_pfff=['pfff' D.fname];

%% Plot power spectrum for manual removal of outlier channels
display(['Run length is ' num2str(run_length) ' mins']);
LBCN_plot_power_spectrum(fname_spm_pfff);

%% Common average re-referencing
LBCN_montage(fname_spm_pfff);
fname_spm_fffM=['Mpfff' D.fname];

%% Filter to slow cortical potential range (<1Hz)
batch_lowpass_medium(fname_spm_fffM);

%% TF decomposition
batch_ArtefactRejection_TF_norescale(fname_spm_fffM);
fname_spm_tf=['tf_aMpfff' D.fname];

%% LogR transform (normalize)
LBCN_baseline_Timeseries(fname_spm_tf,'b','logR')
fname_spm_btf=['btf_aMpfff' D.fname];

%% Frequency band averaging
batch_AverageFreq(fname_spm_btf);

%% Chop 20 sec from beginning
cropping=20000; both=0;

fname_HFB=['HFBbtf_aMpfff' D.fname];
fname_Alpha=['Alphabtf_aMpfff' D.fname];
fname_Delta=['Deltabtf_aMpfff' D.fname];
fname_Theta=['Thetabtf_aMpfff' D.fname];
fname_Beta1=['Beta1btf_aMpfff' D.fname];
fname_Beta2=['Beta2btf_aMpfff' D.fname];
fname_Gamma=['Gammabtf_aMpfff' D.fname];

crop_edges_postTF_func(Patient,runname,fname_HFB,cropping,both);
crop_edges_postTF_func(Patient,runname,fname_Alpha,cropping,both);
crop_edges_postTF_func(Patient,runname,fname_Delta,cropping,both);
crop_edges_postTF_func(Patient,runname,fname_Theta,cropping,both);
crop_edges_postTF_func(Patient,runname,fname_Beta1,cropping,both);
crop_edges_postTF_func(Patient,runname,fname_Beta2,cropping,both);
crop_edges_postTF_func(Patient,runname,fname_Gamma,cropping,both);

fname_HFB=['pHFBbtf_aMpfff' D.fname];
fname_Alpha=['pAlphabtf_aMpfff' D.fname];
fname_Delta=['pDeltabtf_aMpfff' D.fname];
fname_Theta=['pThetabtf_aMpfff' D.fname];
fname_Beta1=['pBeta1btf_aMpfff' D.fname];
fname_Beta2=['pBeta2btf_aMpfff' D.fname];
fname_Gamma=['pGammabtf_aMpfff' D.fname];

%% Temporal filtering: 0.1-1Hz, <0.1Hz, >1Hz
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

batch_highpass_fast(fname_HFB);
batch_highpass_fast(fname_Alpha);
batch_highpass_fast(fname_Delta);
batch_highpass_fast(fname_Theta);
batch_highpass_fast(fname_Beta1);
batch_highpass_fast(fname_Beta2);
batch_highpass_fast(fname_Gamma);

%% Label channels with HFB (0.1-1 Hz) spectral bursts as bad
exclude_spectral_bursts_func(Patient,runname);

