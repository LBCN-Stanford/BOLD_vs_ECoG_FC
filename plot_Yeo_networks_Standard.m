Patient='fsaverage6';
hemi=input('l or r: ','s');
viewpoint=input('medial (m), lateral (l), inferior (i), omni (o): ','s');
FSdir=getFsurfSubDir;
fsdir=[FSdir '/' Patient ];
annot=[FSdir '/' Patient '/label/' hemi 'h.Yeo2011_7Networks_N1000.annot'];
%annot=[fsdir '/label/' hemi 'h.Yeo2011_17Networks_N1000.annot'];
plotElecs=0;

cd([fsdir '/elec_recon'])

title={['DMN (blue); DAN (yellow)']; ['Salience (red); FPN (green)']};
    load('DMN_DAN_FPN_SN_colors.mat')


cfg=[];
if viewpoint=='m';
cfg.view=[hemi 'm'];
elseif viewpoint=='l';
    cfg.view=[hemi];
elseif viewpoint=='i';
    cfg.view=[hemi 'i'];
elseif viewpoint=='o';
    cfg.view=[hemi 'omni'];
end


%cfg.title=title;
cfg.overlayParcellation=annot;
%cfg.parcellationColors=DMN_DAN_FPN_SN_colors;
%cfg.parcellationColors=DMN_DAN_FPN_SN_colors;
cfg.opaqueness=1;

cfgOut=plotPialSurf(Patient,cfg);


