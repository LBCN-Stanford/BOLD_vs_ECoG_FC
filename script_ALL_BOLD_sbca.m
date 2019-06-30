%% BOLD seed-based FC from depth electrode locations in a group of subjects

%% Settings
subs={'C18_30'; 'C18_31'; 'C18_33'; 'C18_41'; 'C18_42'};
hemi_plot='l'; % l for left, r for right

%% Loop through patients
for i=1:length(subs)
    curr_sub=subs{i};
get_depth_coords(curr_sub);
mk_electrode_sphere_ROIs(curr_sub,1,0);
extract_elec_BOLD_ts(curr_sub);
seed_based_BOLD_FC(curr_sub,1);
view_BOLD_sbca_elecs(curr_sub,hemi_plot,'1','1','0');
end