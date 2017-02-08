%-----------------------------------------------------------------------
% Job saved on 14-Dec-2015 11:03:56 by cfg_util (rev $Rev: 6460 $)
% spm SPM - SPM12 (6470)
% cfg_basicio BasicIO - Unknown
%-----------------------------------------------------------------------

% matlabbatch{3}.spm.meeg.tf.rescale.D(1) = cfg_dep('Time-frequency analysis: M/EEG time-frequency power dataset', substruct('.','val', '{}',{2}, '.','val', '{}',{1}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('.','Dtfname'));
% matlabbatch{3}.spm.meeg.tf.rescale.method.LogR.baseline.timewin = '<UNDEFINED>';
% matlabbatch{3}.spm.meeg.tf.rescale.method.LogR.baseline.Db = [];
% matlabbatch{3}.spm.meeg.tf.rescale.prefix = 'r';
%matlabbatch{4}.spm.meeg.tf.avgfreq.D(1) = cfg_dep('Time-frequency rescale: Rescaled TF Datafile', substruct('.','val', '{}',{3}, '.','val', '{}',{1}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('.','Dfname'));
% matlabbatch{1}.spm.meeg.tf.avgfreq.D = '<UNDEFINED>';
% matlabbatch{1}.spm.meeg.tf.avgfreq.freqwin = [70 170];
% matlabbatch{1}.spm.meeg.tf.avgfreq.prefix = 'HFB';
% disp('Done averaging narrow HFB bands within 70-170 Hz range');

matlabbatch{1}.spm.meeg.preproc.filter.D = '<UNDEFINED>'
matlabbatch{1}.spm.meeg.preproc.filter.type = 'butterworth';
matlabbatch{1}.spm.meeg.preproc.filter.band = 'bandpass';
matlabbatch{1}.spm.meeg.preproc.filter.freq = [0.1 1];
matlabbatch{1}.spm.meeg.preproc.filter.dir = 'twopass';
matlabbatch{1}.spm.meeg.preproc.filter.order = 5;
matlabbatch{1}.spm.meeg.preproc.filter.prefix = 'bptf_medium';
disp('Done bandpass-pass filtering (0.1-1 Hz) averaged HFB time series');



