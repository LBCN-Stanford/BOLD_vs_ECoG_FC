Patient=input('Patient: ','s');
hemi=input('l or r: ','s');
run_num=input('run (e.g. 1): ','s');
viewpoint=input('medial (m), lateral (l), inferior (i), omni (o): ','s');
networks=input('plot all (0) or just 4 networks (1)? ','s');
FSdir=getFsurfSubDir;
fsdir=[FSdir '/' Patient ];
annot=[FSdir '/' Patient '/label/' hemi 'h_parc_result_run1.annot'];
%annot=[fsdir '/label/' hemi 'h.Yeo2011_17Networks_N1000.annot'];
runname=['run' run_num];
plotElecs=1;


cd([fsdir '/elec_recon'])
if plotElecs==1
coords=importdata([Patient '.LEPTO']);
nElec=size(coords.data,1);
whiteElecs=ones(nElec,3)*1;
end

pullOut=8;
%title={['Depth electrodes on resting state networks'];['DMN = yellow, olive, dark blue']...
    %;['DAN = green, dark green'];['Salience = pink, magenta'];['FPN = orange, maroon, dark red'];['Visual: bright red, purple'] };
%title={['RS-fMRI Networks & Electrode Locations']; ...
    %['DMN (blue), Salience (Red), FPN (green)']};
    if networks=='1'
title={['DMN (blue); DAN (yellow)']; ['Salience (red); FPN (green)']};
    load('DMN_DAN_FPN_SN_colors.mat')
    else
        title=[' '];
    end

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

if plotElecs==1
   cfg.elecColorScale=[0 1];
cfg.edgeBlack='y'; 
cfg.ignoreDepthElec='n';
cfg.elecSize=4;
cfg.pullOut=pullOut;
cfg.clickElec='y';
cfg.showLabels='y';
%cfg.elecShape='sphere';
%cfg.elecColors=whiteElecs;
%cfg.elecColors='r';
end

cfg.title=title;
cfg.overlayParcellation=annot;
if networks=='1'
cfg.parcellationColors=DMN_DAN_FPN_SN_colors;
end
cfg.opaqueness=1;

cfgOut=plotPialSurf(Patient,cfg);

if networks=='0'
print('-opengl','-r300','-dpng',strcat(['IndiPar_all_' runname '_' viewpoint]));
elseif networks=='1'
print('-opengl','-r300','-dpng',strcat(['IndiPar_4networks_' runname '_' viewpoint]));  
end
