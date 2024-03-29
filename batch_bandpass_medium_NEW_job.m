%-----------------------------------------------------------------------
% Job saved on 14-Dec-2015 11:03:56 by cfg_util (rev $Rev: 6460 $)
% spm SPM - SPM12 (6470)
% cfg_basicio BasicIO - Unknown
%-----------------------------------------------------------------------

matlabbatch{1}.spm.meeg.preproc.filter.D = '<UNDEFINED>'
matlabbatch{1}.spm.meeg.preproc.filter.type = 'butterworth';
matlabbatch{1}.spm.meeg.preproc.filter.band = 'bandpass';
matlabbatch{1}.spm.meeg.preproc.filter.freq = [0.1 1];
matlabbatch{1}.spm.meeg.preproc.filter.dir = 'twopass';
matlabbatch{1}.spm.meeg.preproc.filter.order = 5;
matlabbatch{1}.spm.meeg.preproc.filter.prefix = 'bptf_medium';
disp('Done bandpass-pass filtering (0.1-1 Hz) averaged HFB time series');



