% List of open inputs
% Time-frequency rescale: File Name - cfg_files
% Time-frequency rescale: File Name - cfg_files
nrun = X; % enter the number of runs here
jobfile = {'/home/jplinux/Documents/MATLAB/BOLD_vs_ECoG_FC/normalize_log_batch_job.m'};
jobs = repmat(jobfile, 1, nrun);
inputs = cell(2, nrun);
for crun = 1:nrun
    inputs{1, crun} = MATLAB_CODE_TO_FILL_INPUT; % Time-frequency rescale: File Name - cfg_files
    inputs{2, crun} = MATLAB_CODE_TO_FILL_INPUT; % Time-frequency rescale: File Name - cfg_files
end
spm('defaults', 'EEG');
spm_jobman('run', jobs, inputs{:});
