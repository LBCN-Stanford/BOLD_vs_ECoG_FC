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
China=input('China (1) or Stanford (0)? ','s');
Crop_ts=input('Crop time series (1) or not (0)? ','s');
if Crop_ts=='1'
    crop_start=input('Crop from beginning (e.g. 20 for 20 sec): ','s');
    crop_end=input('Crop from end: ','s');
end

Cropping=input('Crop edges in TF domain by (e.g. 20 for 20 sec): ','s');

    sampling_rate=input('sampling rate (Hz): ','s');
    sampling_rate=str2num(sampling_rate);   

    EDF_convert=input('EDF already converted (1) or not or TDT (0)? ','s');

    crop_start=str2num(crop_start);
    crop_end=str2num(crop_end);
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
    if EDF_convert=='0'
display(['Choose raw EDF data']);
fname=spm_select;
[D,DC]=LBCN_convert_NKnew(fname);
    end
end
if TDT=='1'
    [D]=Convert_TDTiEEG_to_SPMfa(sampling_rate,[],1); % downsample to 1000 Hz  (or keep sampling rate if raw is <1000) 
end
if EDF_convert=='0'
fname_spm = fullfile(D.path,D.fname);
run_length=(D.nsamples/D.fsample)/60;
end

% if pre-converted from EDF: downsample pre-converted EDF to 1000 Hz
if EDF_convert=='1'
    
    display(['Choose raw EDF-converted .mat data']);
fname=spm_select;
if sampling_rate~=1000
S.D=[fname]; S.method='downsample'; S.fsample_new=1000;
D=spm_eeg_downsample(S);
fname_spm=[D.fname];
run_length=(D.nsamples/D.fsample)/60;
else
    
D=spm_eeg_load(fname);
    fname_spm=[fname];
    run_length=(D.nsamples/D.fsample)/60;
end
end

%% Filter iEEG data and detect bad channels
if China=='0'
LBCN_filter_badchans(fname_spm,[],bad_chans,1,[]);
elseif China=='1'
LBCN_filter_badchans_China(fname_spm,[],bad_chans,1,[]); 
end
fname_spm_fff=['fff' D.fname];

A=spm_eeg_load(['f' D.fname]);
delete([A.fname]); delete([A.fnamedat]);
A=spm_eeg_load(['ff' D.fname]);
delete([A.fname]); delete([A.fnamedat]); A=[];

%% Chop 2 sec from edges (beginning and end) - to deal with flat line effects
if Crop_ts=='1'
crop_start=crop_start*D.fsample;
crop_end=D.nsamples-crop_end*D.fsample;
[D]=crop_gradCPT_raw(Patient,runname,fname_spm_fff,crop_start,crop_end);
D=struct(D);
D.timeOnset=0; %% reset onset time to zero after cropping
D=meeg(D);
save(D);
fname_spm_pfff=[D.path filesep D.fname];

else
    fname_spm_pfff=['fff' D.fname];
end
%[D]=crop_gradCPT_raw(sub,runname,fname,cropping_start,cropping_end);
run_length=(D.nsamples/D.fsample)/60;

%% Plot power spectrum for manual removal of outlier channels
display(['Run length is ' num2str(run_length) ' mins']);
LBCN_plot_power_spectrum(fname_spm_pfff);

%% Common average re-referencing
LBCN_montage(fname_spm_pfff);
fname_spm_pfffM=['M' D.fname];

%% Filter to slow cortical potential range (<1Hz)
batch_lowpass_medium(fname_spm_pfffM);

%% TF decomposition
batch_ArtefactRejection_TF_norescale(fname_spm_pfffM);
fname_spm_tf=['tf_aM' D.fname];

%% LogR transform (normalize)
LBCN_baseline_Timeseries(fname_spm_tf,'b','logR')
fname_spm_btf=['btf_aM' D.fname];

%% Frequency band averaging
batch_AverageFreq(fname_spm_btf);

%% Chop 20 sec from beginning
%cropping=20000; 
both=1;
cropping=str2num(Cropping)*sampling_rate;

fname_HFB=['HFBbtf_aM' D.fname];
fname_Alpha=['Alphabtf_aM' D.fname];
fname_Delta=['Deltabtf_aM' D.fname];
fname_Theta=['Thetabtf_aM' D.fname];
fname_Beta1=['Beta1btf_aM' D.fname];
fname_Beta2=['Beta2btf_aM' D.fname];
fname_Gamma=['Gammabtf_aM' D.fname];

if Crop_ts=='1'
crop_edges_postTF_func(Patient,runname,fname_HFB,cropping,both);
crop_edges_postTF_func(Patient,runname,fname_Alpha,cropping,both);
crop_edges_postTF_func(Patient,runname,fname_Delta,cropping,both);
crop_edges_postTF_func(Patient,runname,fname_Theta,cropping,both);
crop_edges_postTF_func(Patient,runname,fname_Beta1,cropping,both);
crop_edges_postTF_func(Patient,runname,fname_Beta2,cropping,both);
crop_edges_postTF_func(Patient,runname,fname_Gamma,cropping,both);
end

if Crop_ts=='1'
fname_HFB=['pHFBbtf_aM' D.fname];
fname_Alpha=['pAlphabtf_aM' D.fname];
fname_Delta=['pDeltabtf_aM' D.fname];
fname_Theta=['pThetabtf_aM' D.fname];
fname_Beta1=['pBeta1btf_aM' D.fname];
fname_Beta2=['pBeta2btf_aM' D.fname];
fname_Gamma=['pGammabtf_aM' D.fname];
else
  fname_HFB=['HFBbtf_aM' D.fname];
fname_Alpha=['Alphabtf_aM' D.fname];
fname_Delta=['Deltabtf_aM' D.fname];
fname_Theta=['Thetabtf_aM' D.fname];
fname_Beta1=['Beta1btf_aM' D.fname];
fname_Beta2=['Beta2btf_aM' D.fname];
fname_Gamma=['Gammabtf_aM' D.fname];  
    
end
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

