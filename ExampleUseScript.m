% Example script

load Examp/ExampleData.mat

% Example structural MRI with gray matter segmentation overlaid
VolView(Structural,Overlay0);

% Example structural MRI with randomly gnerated overlay, masked by
% white matter segmentation
OR = randi([-4 4],256,256,256);
OR = smooth3(OR,'gaussian',7);
VolView(Structural,Overlay1.*OR);

% Example using your real nifti, loaded with fieldtrip
mymri = '~/file/to/mri.nii';
mri   = ft_read_mri(mymri);
D     = ft_volumereslice([],D);
VolView(mri.anatomy,mri.anatomy);