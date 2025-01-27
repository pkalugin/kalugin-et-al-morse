 %% figuring out warping loops
%
% Memory limitations will be important here, especially for warping the
% original (non-meaned) movie - need to chunk things up
%
% - First important consideration is that loaded movie needs to be trimmed by
% the same xy coordinates as the meaned movie - this is mostly already present
% in the Santiago Jupyter notebook (except for 2023 dipping - remake it*done)
%
% - Second important consideration is displacement upsampling - imresize3
% to upsample x,y,t is convenient and reasonably fast - just remember when
% upsampling a chunk that the linear method will be off in the edge
% timepoints (since upsampling interpolates uniformly) - so need to include
% extra overlaps every time and/or trim outputs for correctness
%
% - Finally - presumably it's best to write the warped movie to sbx - how
% time consuming will this be, and are there ways to speed this up? Looks
% like writing to nasquatch is ~25% slower than writing to D:\!
% --edit: writing everything to .npy, fast and easy!
%
% mean movie warp outline:
% 1. Load in reference warp field
% 2. Load in mean movie (whole thing - just a few GB, minimal RAM pressure)
% 3. Upsample warp field to match mean movie (imresize x,y only)
% 4. Apply upsampled warp field to mean movie
% 5. Write warped mean movie to .npy as singles
%
% full-length warp outline:
% 1. Load in reference warp field (not sequential - that's only for
%anchors/trackmate in python
% 2. Loop across chunks (figure out how big - memory limits)
    % 3. Load raw movie chunk (warp both colors for mid-8/23 onward)
    % 4. Upsample warp field to match raw movie chunk (imresize3 x,y,t)
    % 5. Apply upsampled warp field to movie chunk
    % 6. Write warped movie chunk to .npy as singles (not sbx) - here it
    % will be important to keep file open to append all chunks! See
    % writeNPY.m, maybe make a simple version of that function?
% 7. (deprecated) Write warped info mat file

ref = "in_vivo\231108_DG61PL62\DG61PL62_231108_001_noartifact.sbx";
ref1 = "in_vivo\231108_DG61PL62\DG61PL62_231108_001_noartifact_fake.sbx";
meta1 = strsplit(char(ref),'.');
tempa1 = pipe.io.read_sbx(char(ref),1,30,-1,[]);
info1 = pipe.io.read_sbxinfo([meta1{1} '.mat']);
meta1f = strsplit(char(ref1),'.');
tempa1f = pipe.io.read_sbx(char(ref1),1,30,-1,[]);
info1f = pipe.io.read_sbxinfo([meta1f{1} '.mat']);

fakesbx = permute(dispsdemseq,[5,1,2,3,4]);
fakesbx = fakesbx(1:2,:,:,:,:);

%% testing
filext = '.sbx';
%sufficient amount of metadata correction to make sbx code happy!
info1.width = size(fakesbx,2);
info1.height = size(fakesbx,3);
info1.nframes = size(fakesbx,4)*size(fakesbx,5);
%info1.max_idx = info1.nframes-1;
info1.sz = [info1.width,info1.height];
info1.config.lines = info1.width;
info1.recordsPerBuffer = info1.width;

tic
rw = pipe.io.RegWriter([meta1{1} '_fake'],info1,filext,true,'w');
for i = 1:size(fakesbx,5)
    rw.write(squeeze(fakesbx(:,:,:,:,i)));
end
rw.close();
info = info1;
save([meta1{1} '_fake.mat'],'info');
toc

%% warp loop inputs

mov_prefix = "//nasquatch/data/2p/";

%warp_prefix = "D:/2p_data/";
warp_prefix = "//santiago/2p_data/";

 %["peter/in_vivo/231108_DG61PL62/DG61PL62_231108_001_noartifact.sbx"
        %"peter/in_vivo/231108_DG61PL62/DG61PL62_231108_101_full.sbx"
        %"peter/in_vivo/231107_DG44PL58/DG44PL58_231107_001_noartifact.sbx"
        %"peter/in_vivo/231107_DG44PL58/DG44PL58_231107_101_full.sbx"
mov_paths = ["peter/in_vivo/231106_DG52PL68/DG52PL68_231106_001_noartifact.sbx"
        "peter/in_vivo/231106_DG52PL68/DG52PL68_231106_101_full.sbx"
        "peter/in_vivo/231105_DG39PL32/DG39PL32_231105_001_noartifact.sbx"
        "peter/in_vivo/231105_DG39PL32/DG39PL32_231105_201_full.sbx"
        "peter/in_vivo/231105_DG43PL32/DG43PL32_231105_001_noartifact.sbx"
        "peter/in_vivo/231031_DG53PL28/DG53PL28_231031_001_noartifact.sbx"
        "peter/in_vivo/231031_DG53PL28/DG53PL28_231031_101_full.sbx"
        "peter/in_vivo/231030_DG60PL67/DG60PL67_231030_001_noartifact.sbx"
        "peter/in_vivo/231030_DG60PL67/DG60PL67_231030_101_full.sbx"
        "peter/in_vivo/231029_DG58PL64/DG58PL64_231029_001_noartifact.sbx"
        "peter/in_vivo/231027_DG57PL69/DG57PL69_231027_001_noartifact.sbx"
        "peter/in_vivo/231025_DG56PL62/DG56PL62_231025_001_noartifact.sbx"
        "peter/in_vivo/231025_DG56PL62/DG56PL62_231025_101_full.sbx"
        "peter/in_vivo/231024_DG54PL61/DG54PL61_231024_001_noartifact.sbx"
        "peter/in_vivo/231024_DG54PL61/DG54PL61_231024_101_full.sbx"
        "peter/in_vivo/231019_DG53PL68/DG53PL68_231019_001_noartifact.sbx"
        "peter/in_vivo/231018_DG52PL66/DG52PL66_231018_001_noartifact.sbx"
        "peter/in_vivo/231018_DG52PL66/DG52PL66_231018_101_full.sbx"
        "peter/in_vivo/231017_DG49PL70/DG49PL70_231017_001_noartifact.sbx"
        "peter/in_vivo/230909_DG88PL58/DG88PL58_230909_001_noartifact.sbx"
        "peter/in_vivo/230909_DG88PL58/DG88PL58_230909_101_full.sbx"
        "peter/in_vivo/230908_PK109PL52/PK109PL52_230908_001_noartifact.sbx"
        "peter/in_vivo/230908_PK109PL52/PK109PL52_230908_101_full.sbx"
        "peter/in_vivo/230907_PK108PL54/PK108PL54_230907_001_noartifact.sbx"
        "peter/in_vivo/230906_PS57PL56/PS57PL56_230906_001_noartifact.sbx"
        "peter/in_vivo/230906_PS57PL56/PS57PL56_230906_101_full.sbx"
        "peter/in_vivo/230905_PS56PL58/PS56PL58_230905_001_noartifact.sbx"
        "peter/in_vivo/230905_PS56PL58/PS56PL58_230905_101_full.sbx"
        "peter/in_vivo/230904_PS54PL60/PS54PL60_230904_001_noartifact.sbx"
        "peter/in_vivo/230904_PS54PL60/PS54PL60_230904_101_full.sbx"
        "peter/in_vivo/230902_DG90PL61/DG90PL61_230902_001_noartifact.sbx"
        "peter/in_vivo/230902_DG90PL61/DG90PL61_230902_101_full.sbx"
        "peter/in_vivo/230901_DG89PL32/DG89PL32_230901_001_noartifact.sbx"
        "peter/in_vivo/230901_DG89PL32/DG89PL32_230901_101_full.sbx"];

 %["peter/in_vivo/231108_DG61PL62/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
            % "peter/in_vivo/231108_DG61PL62/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
            % "peter/in_vivo/231108_DG61PL62/mouse/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
            % "peter/in_vivo/231108_DG61PL62/mouse/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
            % "peter/in_vivo/231108_DG61PL62/wells/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
            % "peter/in_vivo/231108_DG61PL62/wells/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
            % "peter/in_vivo/231108_DG61PL62/wells/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
            % "peter/in_vivo/231108_DG61PL62/wells/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
            % "peter/in_vivo/231107_DG44PL58/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
            % "peter/in_vivo/231107_DG44PL58/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
            % "peter/in_vivo/231107_DG44PL58/mouse/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
            % "peter/in_vivo/231107_DG44PL58/mouse/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
            % "peter/in_vivo/231107_DG44PL58/wells/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
            % "peter/in_vivo/231107_DG44PL58/wells/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
            % "peter/in_vivo/231107_DG44PL58/wells/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
            % "peter/in_vivo/231107_DG44PL58/wells/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
warp_dirs = ["peter/in_vivo/231106_DG52PL68/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/231106_DG52PL68/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/231106_DG52PL68/mouse/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/231106_DG52PL68/mouse/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/231106_DG52PL68/wells/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/231106_DG52PL68/wells/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/231106_DG52PL68/wells/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/231106_DG52PL68/wells/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/231105_DG43PL32/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/231105_DG43PL32/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/231105_DG43PL32/mouse/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/231105_DG43PL32/mouse/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/231105_DG39PL32/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/231105_DG39PL32/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/231105_DG39PL32/mouse/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/231105_DG39PL32/mouse/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/231105_DG39PL32/wells/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/231105_DG39PL32/wells/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/231105_DG39PL32/wells/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/231105_DG39PL32/wells/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/231031_DG53PL28/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/231031_DG53PL28/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/231031_DG53PL28/mouse/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/231031_DG53PL28/mouse/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/231031_DG53PL28/wells/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/231031_DG53PL28/wells/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/231031_DG53PL28/wells/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/231031_DG53PL28/wells/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/231030_DG60PL67/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/231030_DG60PL67/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/231030_DG60PL67/mouse/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/231030_DG60PL67/mouse/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/231030_DG60PL67/wells/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/231030_DG60PL67/wells/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/231030_DG60PL67/wells/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/231030_DG60PL67/wells/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/231029_DG58PL64/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/231029_DG58PL64/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/231029_DG58PL64/mouse/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/231029_DG58PL64/mouse/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/231027_DG57PL69/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/231027_DG57PL69/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/231027_DG57PL69/mouse/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/231027_DG57PL69/mouse/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/231025_DG56PL62/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/231025_DG56PL62/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/231025_DG56PL62/mouse/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/231025_DG56PL62/mouse/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/231025_DG56PL62/wells/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/231025_DG56PL62/wells/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/231025_DG56PL62/wells/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/231025_DG56PL62/wells/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/231024_DG54PL61/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/231024_DG54PL61/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/231024_DG54PL61/mouse/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/231024_DG54PL61/mouse/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/231024_DG54PL61/wells/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/231024_DG54PL61/wells/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/231024_DG54PL61/wells/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/231024_DG54PL61/wells/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/231019_DG53PL68/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/231019_DG53PL68/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/231019_DG53PL68/mouse/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/231019_DG53PL68/mouse/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/231018_DG52PL66/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/231018_DG52PL66/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/231018_DG52PL66/mouse/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/231018_DG52PL66/mouse/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/231018_DG52PL66/wells/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/231018_DG52PL66/wells/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/231018_DG52PL66/wells/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/231018_DG52PL66/wells/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/231017_DG49PL70/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/231017_DG49PL70/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/231017_DG49PL70/mouse/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/231017_DG49PL70/mouse/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230909_DG88PL58/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230909_DG88PL58/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230909_DG88PL58/mouse/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230909_DG88PL58/mouse/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230909_DG88PL58/wells/segtrack/segs/ch0/31_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230909_DG88PL58/wells/segtrack/segs/ch0/31_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230909_DG88PL58/wells/segtrack/segs/ch1/31_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230909_DG88PL58/wells/segtrack/segs/ch1/31_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230908_PK109PL52/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230908_PK109PL52/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230908_PK109PL52/mouse/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230908_PK109PL52/mouse/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230908_PK109PL52/wells/segtrack/segs/ch0/31_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230908_PK109PL52/wells/segtrack/segs/ch0/31_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230908_PK109PL52/wells/segtrack/segs/ch1/31_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230908_PK109PL52/wells/segtrack/segs/ch1/31_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230907_PK108PL54/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230907_PK108PL54/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230907_PK108PL54/mouse/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230907_PK108PL54/mouse/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230906_PS57PL56/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230906_PS57PL56/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230906_PS57PL56/mouse/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230906_PS57PL56/mouse/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230906_PS57PL56/wells/segtrack/segs/ch0/31_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230906_PS57PL56/wells/segtrack/segs/ch0/31_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230906_PS57PL56/wells/segtrack/segs/ch1/31_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230906_PS57PL56/wells/segtrack/segs/ch1/31_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230905_PS56PL58/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230905_PS56PL58/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230905_PS56PL58/mouse/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230905_PS56PL58/mouse/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230905_PS56PL58/wells/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230905_PS56PL58/wells/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230905_PS56PL58/wells/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230905_PS56PL58/wells/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230904_PS54PL60/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230904_PS54PL60/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230904_PS54PL60/mouse/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230904_PS54PL60/mouse/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230904_PS54PL60/wells/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230904_PS54PL60/wells/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230904_PS54PL60/wells/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230904_PS54PL60/wells/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230902_DG90PL61/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230902_DG90PL61/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230902_DG90PL61/mouse/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230902_DG90PL61/mouse/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230902_DG90PL61/wells/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230902_DG90PL61/wells/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230902_DG90PL61/wells/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230902_DG90PL61/wells/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230901_DG89PL32/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230901_DG89PL32/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230901_DG89PL32/mouse/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230901_DG89PL32/mouse/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230901_DG89PL32/wells/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230901_DG89PL32/wells/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230901_DG89PL32/wells/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230901_DG89PL32/wells/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"];

%[repmat(85,1,4)...
    %repmat(34,1,4)...
    %repmat(85,1,4)...
    %repmat(34,1,4)...
warp_refs = [repmat(85,1,4)...
    repmat(34,1,4)...
    repmat(19,1,4)...
    repmat(85,1,4)...
    repmat(34,1,4)...
    repmat(85,1,4)...
    repmat(34,1,4)...
    repmat(49,1,4)...
    repmat(34,1,4)...
    repmat(10,1,4)...
    repmat(85,1,4)...
    repmat(85,1,4)...
    repmat(34,1,4)...
    repmat(71,1,4)...
    repmat(34,1,4)...
    repmat(85,1,4)...
    repmat(71,1,4)...
    repmat(34,1,4)...
    repmat(71,1,4)...
    repmat(71,1,4)...
    repmat(34,1,4)...
    repmat(65,1,4)...
    repmat(34,1,4)...
    repmat(80,1,4)...
    repmat(60,1,4)...
    repmat(34,1,4)...
    repmat(89,1,4)...
    repmat(34,1,4)...
    repmat(89,1,4)...
    repmat(38,1,4)...
    repmat(75,1,4)...
    repmat(38,1,4)...
    repmat(30,1,4)...
    repmat(38,1,4)]'; 

 %[[145 655 21 471]; %manually added 231025!
        % [145 655 21 471];
        % [143 653 30 480];
        % [169 679 21 471];
warp_bounds = [[138 648 30 480];
         [122 632 29 479];
         [128 638 27 477];
         [120 630 28 478];
         [147 657 26 476];
         [149 659 24 474];
         [159 669 35 485];
         [145 655 35 485];
         [135 645 25 475];
         [148 658 25 475];
         [152 662 21 471];
         [160 670 21 471]; %231023
         [160 670 21 471]; %231023
         [152 662 26 476];
         [160 670 17 467];
         [146 656 27 477];
         [152 662 28 478];
         [199 709 33 483];
         [154 664 27 477];
         [154 664 20 470];
         [160 670 16 466];
         [160 670 23 473];
         [196 706 6 456];
         [146 656 23 473];
         [142 652 31 481];
         [184 694 29 479];
         [151 661 22 472];
         [161 671 31 481];
         [137 647 24 474];
         [153 663 23 473];
         [146 656 17 467];
         [145 655 20 470];
         [141 651 36 486];
         [210 720 25 475]];
     
%% slice movies

mov_prefix = "//nasquatch/data/2p/";

%warp_prefix = "D:/2p_data/";
warp_prefix = "//santiago/2p_data/";

mov_paths = ["peter/slice/20230831_SL1PL55/PL55_230831_001_full.sbx"
        "peter/slice/20230831_SL1PL55/SL1PL55_230831_001_noartifact.sbx"
        "peter/slice/20230830_SL2PL60/SL2PL60_230830_001_noartifact.sbx"
        "peter/slice/20230830_SL1PL28/PL28_230830_001_full.sbx"
        "peter/slice/20230830_SL1PL28/SL1PL28_230830_001_noartifact.sbx"
        "peter/slice/20230829_SL3PL61/SL3PL61_230829_001_noartifact.sbx"
        "peter/slice/20230829_SL2PL39/SL2PL39_230829_001_noartifact.sbx"
        "peter/slice/20230829_SL1PL56/PL56_230829_001_full.sbx"
        "peter/slice/20230829_SL1PL56/SL1PL56_230829_001_noartifact.sbx"
        "peter/slice/20230824_SL2PL54/SL2PL54_230824_001_noartifact.sbx"
        "peter/slice/20230824_SL1PL60/PL60_230824_001_full.sbx"
        "peter/slice/20230824_SL1PL60/PL60_230824_101_full.sbx"
        "peter/slice/20230824_SL1PL60/SL1PL60_230824_001_noartifact.sbx"
        "peter/slice/20230822_SL3PL58/SL3PL58_230822_001_noartifact.sbx"
        "peter/slice/20230822_SL2PL52/PL52_230822_001_full.sbx"
        "peter/slice/20230822_SL2PL52/SL2PL52_230822_001_noartifact.sbx"
        "peter/slice/20230822_SL1PL32/SL1PL32_230822_001_noartifact.sbx"
        "peter/slice/20230817_SL2PL60/SL2PL60_230817_001_noartifact.sbx"
        "peter/slice/20230817_SL1PL55/PL55_230817_001_full.sbx"
        "peter/slice/20230817_SL1PL55/PL55_230817_101_full.sbx"
        "peter/slice/20230817_SL1PL55/SL1PL55_230817_001_noartifact.sbx"
        "peter/slice/20230801_SL2PL34/SL2PL34_230801_001_noartifact.sbx" %from here onward definitely stop ch1 since no tdTomato!
        "peter/slice/20230801_SL1PL35/PL35_230801_101_full.sbx"
        "peter/slice/20230801_SL1PL35/SL1PL35_230801_001_noartifact.sbx"
        "peter/slice/20230727_SL2PL32/PL32_230727_101_full.sbx"
        "peter/slice/20230727_SL2PL32/SL2PL32_230727_001_noartifact.sbx"
        "peter/slice/20230727_SL1PL52/SL1PL52_230727_001_noartifact.sbx"
        "peter/slice/20230616_SL2PL39/SL2PL39_230616_001.sbx"
        "peter/slice/20230616_SL1PL28/PL28_230616_001_full.sbx"
        "peter/slice/20230616_SL1PL28/SL1PL28_230616_001.sbx"
        "peter/slice/20230608_SL2PL45/SL2PL45_230608_001_noartifact.sbx"
        "peter/slice/20230608_SL1PL37/SL1PL37_230608_001_noartifact.sbx"
        "peter/slice/20230607_SL2PL42/SL2PL42_230607_001_noartifact.sbx"
        "peter/slice/20230607_SL1PL47/PL47_230607_001_full.sbx"
        "peter/slice/20230607_SL1PL47/SL1PL47_230607_001.sbx"
        "peter/slice/20230606_SL1PL35/PL35_230606_001.sbx"
        "peter/slice/20230606_SL1PL35/SL1PL35_230606_001.sbx"
        "peter/slice/20230511_DA2PL45/xx0DA2PL45_230511_001.sbx"
        "peter/slice/20230511_DA1PL37/PL37_230511_101_full.sbx"
        "peter/slice/20230511_DA1PL37/xx0DA1PL37_230511_001.sbx"
        "peter/slice/20230509_DA2PL55/DA2PL55_230509_001.sbx"
        "peter/slice/20230509_DA1PL53/DA1PL53_230509_001.sbx"
        "peter/slice/20230509_DA1PL53/PL53_230509_101_full.sbx"];

warp_dirs = ["peter/slice/20230831_SL1PL55/slice/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230831_SL1PL55/slice/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230831_SL1PL55/slice/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230831_SL1PL55/slice/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230831_SL1PL55/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230831_SL1PL55/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230831_SL1PL55/wells001/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230831_SL1PL55/wells001/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230830_SL2PL60/slice/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230830_SL2PL60/slice/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230830_SL2PL60/slice/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230830_SL2PL60/slice/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230830_SL1PL28/slice/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230830_SL1PL28/slice/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230830_SL1PL28/slice/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230830_SL1PL28/slice/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230830_SL1PL28/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230830_SL1PL28/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230830_SL1PL28/wells001/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230830_SL1PL28/wells001/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230829_SL3PL61/slice/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230829_SL3PL61/slice/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230829_SL3PL61/slice/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230829_SL3PL61/slice/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230829_SL2PL39/slice/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230829_SL2PL39/slice/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230829_SL2PL39/slice/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230829_SL2PL39/slice/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230829_SL1PL56/slice/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230829_SL1PL56/slice/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230829_SL1PL56/slice/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230829_SL1PL56/slice/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230829_SL1PL56/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230829_SL1PL56/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230829_SL1PL56/wells001/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230829_SL1PL56/wells001/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230824_SL2PL54/slice/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230824_SL2PL54/slice/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230824_SL2PL54/slice/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230824_SL2PL54/slice/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230824_SL1PL60/slice/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230824_SL1PL60/slice/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230824_SL1PL60/slice/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230824_SL1PL60/slice/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230824_SL1PL60/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230824_SL1PL60/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230824_SL1PL60/wells001/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230824_SL1PL60/wells001/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230824_SL1PL60/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230824_SL1PL60/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230824_SL1PL60/wells101/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230824_SL1PL60/wells101/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230822_SL3PL58/slice/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230822_SL3PL58/slice/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230822_SL3PL58/slice/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230822_SL3PL58/slice/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230822_SL2PL52/slice/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230822_SL2PL52/slice/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230822_SL2PL52/slice/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230822_SL2PL52/slice/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230822_SL2PL52/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230822_SL2PL52/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230822_SL2PL52/wells001/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230822_SL2PL52/wells001/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230822_SL1PL32/slice/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230822_SL1PL32/slice/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230822_SL1PL32/slice/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230822_SL1PL32/slice/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230817_SL2PL60/slice/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230817_SL2PL60/slice/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230817_SL2PL60/slice/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230817_SL2PL60/slice/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230817_SL1PL55/slice/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230817_SL1PL55/slice/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230817_SL1PL55/slice/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230817_SL1PL55/slice/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230817_SL1PL55/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230817_SL1PL55/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230817_SL1PL55/wells001/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230817_SL1PL55/wells001/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230817_SL1PL55/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230817_SL1PL55/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230817_SL1PL55/wells101/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230817_SL1PL55/wells101/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230801_SL2PL34/slice/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230801_SL2PL34/slice/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230801_SL1PL35/slice/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230801_SL1PL35/slice/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230801_SL1PL35/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230801_SL1PL35/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230727_SL2PL32/slice/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230727_SL2PL32/slice/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230727_SL2PL32/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230727_SL2PL32/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230727_SL1PL52/slice/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230727_SL1PL52/slice/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230616_SL2PL39/slice/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230616_SL2PL39/slice/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230616_SL1PL28/slice/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230616_SL1PL28/slice/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230616_SL1PL28/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230616_SL1PL28/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230608_SL2PL45/slice/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230608_SL2PL45/slice/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230608_SL1PL37/slice/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230608_SL1PL37/slice/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230607_SL2PL42/slice/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230607_SL2PL42/slice/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230607_SL1PL47/slice/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230607_SL1PL47/slice/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230607_SL1PL47/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230607_SL1PL47/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230606_SL1PL35/slice/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230606_SL1PL35/slice/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230606_SL1PL35/washes/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230606_SL1PL35/washes/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230511_DA2PL45/slice/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230511_DA2PL45/slice/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230511_DA1PL37/slice/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230511_DA1PL37/slice/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230511_DA1PL37/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230511_DA1PL37/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230509_DA2PL55/slice/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230509_DA2PL55/slice/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230509_DA1PL53/slice/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230509_DA1PL53/slice/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230509_DA1PL53/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230509_DA1PL53/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"];

warp_refs = [repmat(28,1,4)...
    repmat(52,1,4)...
    repmat(28,1,4)...
    repmat(28,1,4)...
    repmat(52,1,4)...
    repmat(28,1,4)...
    repmat(28,1,4)...
    repmat(28,1,4)...
    repmat(52,1,4)...
    repmat(33,1,4)...
    repmat(22,1,4)...
    repmat(18,1,4)...
    repmat(20,1,4)...
    repmat(28,1,4)...
    repmat(28,1,4)...
    repmat(52,1,4)...
    repmat(28,1,4)...
    repmat(27,1,4)...
    repmat(27,1,4)...
    repmat(18,1,4)...
    repmat(39,1,4)...
    repmat(27,1,2)...
    repmat(27,1,2)...
    repmat(76,1,2)...
    repmat(25,1,2)...
    repmat(39,1,2)...
    repmat(18,1,2)...
    repmat(18,1,2)...
    repmat(18,1,2)...
    repmat(11,1,2)...
    repmat(26,1,2)...
    repmat(18,1,2)...
    repmat(25,1,2)...
    repmat(15,1,2)...
    repmat(27,1,2)...
    repmat(18,1,2)...
    repmat(9,1,2)...
    repmat(18,1,2)...
    repmat(15,1,2)...
    repmat(7,1,2)...
    repmat(16,1,2)...
    repmat(10,1,2)...
    repmat(8,1,2)]';

warp_bounds = [[155 665 20 470];
         [150 660 30 480];
         [265 775 31 481];
         [190 700 25 475];
         [56 566 33 483];
         [81 591 35 485];
         [160 670 0 450];
         [200 710 15 465]; 
         [153 663 0 450];
         [145 655 30 480];
         [145 655 16 465]; %mistake! should be 15 not 16!
         [180 690 20 470];
         [135 645 25 475];
         [155 665 0 450];
         [195 705 10 460];
         [128 638 13 463];
         [116 626 53 503];
         [160 670 45 495];
         [220 730 0 450];
         [165 675 20 470];
         [140 650 45 495];
         [139 700 0 495];
         [210 720 13 463];
         [53 614 0 495];
         [135 645 46 496];
         [234 744 62 512];
         [98 608 0 450];
         [102 663 12 507];
         [230 791 0 495];
         [113 674 3 498];
         [78 639 17 512];
         [95 656 0 495];
         [75 636 11 506];
         [147 708 13 508];
         [96 657 14 509];
         [97 658 0 495];
         [173 734 13 508];
         [209 719 54 504];
         [137 647 41 491];
         [152 662 22 472];
         [152 662 23 473];
         [222 732 0 450];
         [177 738 13 508]];
     
%% dipping 2023

mov_prefix = "//nasquatch/data/2p/";

%warp_prefix = "D:/2p_data/";
warp_prefix = "//santiago/2p_data/";

mov_paths = ["peter/dipping/20230927_PL58/PL58_230927_001_full.sbx"
    "peter/dipping/20230927_PL58/PL58_230927_101_full.sbx"
    "peter/dipping/20230927_PL58/PL58_230927_201_full.sbx"
    "peter/dipping/20230927_PL58/PL58_230927_301_full.sbx"
    "peter/dipping/20230927_PL34/PL34_230927_001_full.sbx"
    "peter/dipping/20230927_PL34/PL34_230927_101_full.sbx"
    "peter/dipping/20230927_PL34/PL34_230927_201_full.sbx"
    "peter/dipping/20230927_PL34/PL34_230927_301_full.sbx"
    "peter/dipping/20230926_PL56/PL56_230926_001_full.sbx"
    "peter/dipping/20230926_PL56/PL56_230926_101_full.sbx"
    "peter/dipping/20230926_PL56/PL56_230926_201_full.sbx"
    "peter/dipping/20230926_PL56/PL56_230926_301_full.sbx"
    "peter/dipping/20230926_PL56/PL56_230926_401_full.sbx"
    "peter/dipping/20230926_PL56/PL56_230926_501_full.sbx"
    "peter/dipping/20230925_PL58/PL58_230925_001_full.sbx"
    "peter/dipping/20230925_PL58/PL58_230925_101_full.sbx"
    "peter/dipping/20230925_PL58/PL58_230925_201_full.sbx"
    "peter/dipping/20230925_PL58/PL58_230925_301_full.sbx"
    "peter/dipping/20230925_PL58/PL58_230925_401_full.sbx"
    "peter/dipping/20230923_PL35/PL35_230923_001_full.sbx"
    "peter/dipping/20230923_PL35/PL35_230923_101_full.sbx"
    "peter/dipping/20230923_PL35/PL35_230923_201_full.sbx"
    "peter/dipping/20230923_PL35/PL35_230923_301_full.sbx"
    "peter/dipping/20230923_PL35/PL35_230923_401_full.sbx"
    "peter/dipping/20230923_PL35/PL35_230923_501_full.sbx"
    "peter/dipping/20230922_PL28/PL28_230922_001_full.sbx"
    "peter/dipping/20230922_PL28/PL28_230922_101_full.sbx"
    "peter/dipping/20230922_PL28/PL28_230922_201_full.sbx"
    "peter/dipping/20230922_PL28/PL28_230922_301_full.sbx"
    "peter/dipping/20230922_PL28/PL28_230922_401_full.sbx"
    "peter/dipping/20230922_PL28/PL28_230922_501_full.sbx"
    "peter/dipping/20230922_PL28/PL28_230922_601_full.sbx"
    "peter/dipping/20230922_PL28/PL28_230922_701_full.sbx"
    "peter/dipping/20230920_PL58/PL58_230920_001_full.sbx"
    "peter/dipping/20230920_PL58/PL58_230920_101_full.sbx"
    "peter/dipping/20230920_PL58/PL58_230920_201_full.sbx"
    "peter/dipping/20230920_PL58/PL58_230920_301_full.sbx"
    "peter/dipping/20230920_PL56/PL56_230920_001_full.sbx"
    "peter/dipping/20230920_PL56/PL56_230920_101_full.sbx"
    "peter/dipping/20230920_PL56/PL56_230920_201_full.sbx"
    "peter/dipping/20230916_PL54/PL54_230916_001_full.sbx"
    "peter/dipping/20230916_PL54/PL54_230916_101_full.sbx"
    "peter/dipping/20230916_PL54/PL54_230916_201_full.sbx"
    "peter/dipping/20230916_PL54/PL54_230916_301_full.sbx"
    "peter/dipping/20230916_PL54/PL54_230916_401_full.sbx"
    "peter/dipping/20230916_PL54/PL54_230916_501_full.sbx"
    "peter/dipping/20230916_PL48/PL48_230916_001_full.sbx"
    "peter/dipping/20230916_PL48/PL48_230916_101_full.sbx"
    "peter/dipping/20230915_PL52/PL52_230915_001_full.sbx"
    "peter/dipping/20230915_PL52/PL52_230915_101_full.sbx"
    "peter/dipping/20230915_PL52/PL52_230915_201_full.sbx"
    "peter/dipping/20230915_PL52/PL52_230915_301_full.sbx"
    "peter/dipping/20230915_PL52/PL52_230915_401_full.sbx"
    "peter/dipping/20230825_PL57/PL57_230825_001_full.sbx"
    "peter/dipping/20230825_PL39/PL39_230825_001_full.sbx"
    "peter/dipping/20230823_PL61/PL61_230823_001_full.sbx"
    "peter/dipping/20230823_PL48/PL48_230823_001_full.sbx"
    "peter/dipping/20230823_PL28/PL28_230823_001_full.sbx"
    "peter/dipping/20230823_PL28/PL28_230823_101_full.sbx"
    "peter/dipping/20230823_PL28/PL28_230823_201_full.sbx"
    "peter/dipping/20230821_PL57/PL57_230821_001_full.sbx"
    "peter/dipping/20230819_PL62/PL62_230819_001_full.sbx"
    "peter/dipping/20230819_PL43/PL43_230819_001_full.sbx"
    "peter/dipping/20230819_PL43/PL43_230819_101_full.sbx"
    "peter/dipping/20230819_PL43/PL43_230819_201_full.sbx"];

warp_dirs = ["peter/dipping/20230927_PL58/wells001/segtrack/segs/ch0/31_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230927_PL58/wells001/segtrack/segs/ch0/31_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230927_PL58/wells001/segtrack/segs/ch1/31_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230927_PL58/wells001/segtrack/segs/ch1/31_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230927_PL58/wells101/segtrack/segs/ch0/31_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230927_PL58/wells101/segtrack/segs/ch0/31_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230927_PL58/wells101/segtrack/segs/ch1/31_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230927_PL58/wells101/segtrack/segs/ch1/31_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230927_PL58/wells201/segtrack/segs/ch0/31_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230927_PL58/wells201/segtrack/segs/ch0/31_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230927_PL58/wells201/segtrack/segs/ch1/31_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230927_PL58/wells201/segtrack/segs/ch1/31_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230927_PL58/wells301/segtrack/segs/ch0/31_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230927_PL58/wells301/segtrack/segs/ch0/31_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230927_PL58/wells301/segtrack/segs/ch1/31_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230927_PL58/wells301/segtrack/segs/ch1/31_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230927_PL34/wells001/segtrack/segs/ch0/31_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230927_PL34/wells001/segtrack/segs/ch0/31_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230927_PL34/wells001/segtrack/segs/ch1/31_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230927_PL34/wells001/segtrack/segs/ch1/31_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230927_PL34/wells101/segtrack/segs/ch0/31_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230927_PL34/wells101/segtrack/segs/ch0/31_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230927_PL34/wells101/segtrack/segs/ch1/31_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230927_PL34/wells101/segtrack/segs/ch1/31_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230927_PL34/wells201/segtrack/segs/ch0/31_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230927_PL34/wells201/segtrack/segs/ch0/31_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230927_PL34/wells201/segtrack/segs/ch1/31_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230927_PL34/wells201/segtrack/segs/ch1/31_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230927_PL34/wells301/segtrack/segs/ch0/31_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230927_PL34/wells301/segtrack/segs/ch0/31_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230927_PL34/wells301/segtrack/segs/ch1/31_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230927_PL34/wells301/segtrack/segs/ch1/31_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230926_PL56/wells001/segtrack/segs/ch0/31_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230926_PL56/wells001/segtrack/segs/ch0/31_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230926_PL56/wells001/segtrack/segs/ch1/31_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230926_PL56/wells001/segtrack/segs/ch1/31_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230926_PL56/wells101/segtrack/segs/ch0/31_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230926_PL56/wells101/segtrack/segs/ch0/31_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230926_PL56/wells101/segtrack/segs/ch1/31_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230926_PL56/wells101/segtrack/segs/ch1/31_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230926_PL56/wells201/segtrack/segs/ch0/31_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230926_PL56/wells201/segtrack/segs/ch0/31_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230926_PL56/wells201/segtrack/segs/ch1/31_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230926_PL56/wells201/segtrack/segs/ch1/31_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230926_PL56/wells301/segtrack/segs/ch0/31_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230926_PL56/wells301/segtrack/segs/ch0/31_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230926_PL56/wells301/segtrack/segs/ch1/31_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230926_PL56/wells301/segtrack/segs/ch1/31_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230926_PL56/wells401/segtrack/segs/ch0/31_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230926_PL56/wells401/segtrack/segs/ch0/31_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230926_PL56/wells401/segtrack/segs/ch1/31_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230926_PL56/wells401/segtrack/segs/ch1/31_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230926_PL56/wells501/segtrack/segs/ch0/31_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230926_PL56/wells501/segtrack/segs/ch0/31_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230926_PL56/wells501/segtrack/segs/ch1/31_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230926_PL56/wells501/segtrack/segs/ch1/31_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230925_PL58/wells001/segtrack/segs/ch0/31_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230925_PL58/wells001/segtrack/segs/ch0/31_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230925_PL58/wells001/segtrack/segs/ch1/31_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230925_PL58/wells001/segtrack/segs/ch1/31_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230925_PL58/wells101/segtrack/segs/ch0/31_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230925_PL58/wells101/segtrack/segs/ch0/31_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230925_PL58/wells101/segtrack/segs/ch1/31_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230925_PL58/wells101/segtrack/segs/ch1/31_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230925_PL58/wells201/segtrack/segs/ch0/31_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230925_PL58/wells201/segtrack/segs/ch0/31_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230925_PL58/wells201/segtrack/segs/ch1/31_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230925_PL58/wells201/segtrack/segs/ch1/31_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230925_PL58/wells301/segtrack/segs/ch0/31_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230925_PL58/wells301/segtrack/segs/ch0/31_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230925_PL58/wells301/segtrack/segs/ch1/31_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230925_PL58/wells301/segtrack/segs/ch1/31_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230925_PL58/wells401/segtrack/segs/ch0/31_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230925_PL58/wells401/segtrack/segs/ch0/31_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230925_PL58/wells401/segtrack/segs/ch1/31_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230925_PL58/wells401/segtrack/segs/ch1/31_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230923_PL35/wells001/segtrack/segs/ch0/31_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230923_PL35/wells001/segtrack/segs/ch0/31_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230923_PL35/wells001/segtrack/segs/ch1/31_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230923_PL35/wells001/segtrack/segs/ch1/31_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230923_PL35/wells101/segtrack/segs/ch0/31_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230923_PL35/wells101/segtrack/segs/ch0/31_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230923_PL35/wells101/segtrack/segs/ch1/31_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230923_PL35/wells101/segtrack/segs/ch1/31_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230923_PL35/wells201/segtrack/segs/ch0/31_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230923_PL35/wells201/segtrack/segs/ch0/31_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230923_PL35/wells201/segtrack/segs/ch1/31_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230923_PL35/wells201/segtrack/segs/ch1/31_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230923_PL35/wells301/segtrack/segs/ch0/31_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230923_PL35/wells301/segtrack/segs/ch0/31_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230923_PL35/wells301/segtrack/segs/ch1/31_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230923_PL35/wells301/segtrack/segs/ch1/31_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230923_PL35/wells401/segtrack/segs/ch0/31_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230923_PL35/wells401/segtrack/segs/ch0/31_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230923_PL35/wells401/segtrack/segs/ch1/31_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230923_PL35/wells401/segtrack/segs/ch1/31_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230923_PL35/wells501/segtrack/segs/ch0/31_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230923_PL35/wells501/segtrack/segs/ch0/31_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230923_PL35/wells501/segtrack/segs/ch1/31_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230923_PL35/wells501/segtrack/segs/ch1/31_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230922_PL28/wells001/segtrack/segs/ch0/31_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230922_PL28/wells001/segtrack/segs/ch0/31_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230922_PL28/wells001/segtrack/segs/ch1/31_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230922_PL28/wells001/segtrack/segs/ch1/31_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230922_PL28/wells101/segtrack/segs/ch0/31_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230922_PL28/wells101/segtrack/segs/ch0/31_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230922_PL28/wells101/segtrack/segs/ch1/31_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230922_PL28/wells101/segtrack/segs/ch1/31_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230922_PL28/wells201/segtrack/segs/ch0/31_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230922_PL28/wells201/segtrack/segs/ch0/31_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230922_PL28/wells201/segtrack/segs/ch1/31_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230922_PL28/wells201/segtrack/segs/ch1/31_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230922_PL28/wells301/segtrack/segs/ch0/31_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230922_PL28/wells301/segtrack/segs/ch0/31_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230922_PL28/wells301/segtrack/segs/ch1/31_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230922_PL28/wells301/segtrack/segs/ch1/31_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230922_PL28/wells401/segtrack/segs/ch0/31_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230922_PL28/wells401/segtrack/segs/ch0/31_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230922_PL28/wells401/segtrack/segs/ch1/31_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230922_PL28/wells401/segtrack/segs/ch1/31_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230922_PL28/wells501/segtrack/segs/ch0/31_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230922_PL28/wells501/segtrack/segs/ch0/31_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230922_PL28/wells501/segtrack/segs/ch1/31_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230922_PL28/wells501/segtrack/segs/ch1/31_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230922_PL28/wells601/segtrack/segs/ch0/31_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230922_PL28/wells601/segtrack/segs/ch0/31_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230922_PL28/wells601/segtrack/segs/ch1/31_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230922_PL28/wells601/segtrack/segs/ch1/31_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230922_PL28/wells701/segtrack/segs/ch0/31_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230922_PL28/wells701/segtrack/segs/ch0/31_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230922_PL28/wells701/segtrack/segs/ch1/31_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230922_PL28/wells701/segtrack/segs/ch1/31_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230920_PL58/wells001/segtrack/segs/ch0/31_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230920_PL58/wells001/segtrack/segs/ch0/31_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230920_PL58/wells001/segtrack/segs/ch1/31_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230920_PL58/wells001/segtrack/segs/ch1/31_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230920_PL58/wells101/segtrack/segs/ch0/31_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230920_PL58/wells101/segtrack/segs/ch0/31_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230920_PL58/wells101/segtrack/segs/ch1/31_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230920_PL58/wells101/segtrack/segs/ch1/31_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230920_PL58/wells201/segtrack/segs/ch0/31_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230920_PL58/wells201/segtrack/segs/ch0/31_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230920_PL58/wells201/segtrack/segs/ch1/31_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230920_PL58/wells201/segtrack/segs/ch1/31_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230920_PL58/wells301/segtrack/segs/ch0/31_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230920_PL58/wells301/segtrack/segs/ch0/31_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230920_PL58/wells301/segtrack/segs/ch1/31_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230920_PL58/wells301/segtrack/segs/ch1/31_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230920_PL56/wells001/segtrack/segs/ch0/31_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230920_PL56/wells001/segtrack/segs/ch0/31_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230920_PL56/wells001/segtrack/segs/ch1/31_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230920_PL56/wells001/segtrack/segs/ch1/31_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230920_PL56/wells101/segtrack/segs/ch0/31_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230920_PL56/wells101/segtrack/segs/ch0/31_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230920_PL56/wells101/segtrack/segs/ch1/31_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230920_PL56/wells101/segtrack/segs/ch1/31_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230920_PL56/wells201/segtrack/segs/ch0/31_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230920_PL56/wells201/segtrack/segs/ch0/31_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230920_PL56/wells201/segtrack/segs/ch1/31_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230920_PL56/wells201/segtrack/segs/ch1/31_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230916_PL54/wells001/segtrack/segs/ch0/31_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230916_PL54/wells001/segtrack/segs/ch0/31_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230916_PL54/wells001/segtrack/segs/ch1/31_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230916_PL54/wells001/segtrack/segs/ch1/31_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230916_PL54/wells101/segtrack/segs/ch0/31_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230916_PL54/wells101/segtrack/segs/ch0/31_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230916_PL54/wells101/segtrack/segs/ch1/31_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230916_PL54/wells101/segtrack/segs/ch1/31_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230916_PL54/wells201/segtrack/segs/ch0/31_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230916_PL54/wells201/segtrack/segs/ch0/31_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230916_PL54/wells201/segtrack/segs/ch1/31_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230916_PL54/wells201/segtrack/segs/ch1/31_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230916_PL54/wells301/segtrack/segs/ch0/31_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230916_PL54/wells301/segtrack/segs/ch0/31_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230916_PL54/wells301/segtrack/segs/ch1/31_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230916_PL54/wells301/segtrack/segs/ch1/31_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230916_PL54/wells401/segtrack/segs/ch0/31_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230916_PL54/wells401/segtrack/segs/ch0/31_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230916_PL54/wells401/segtrack/segs/ch1/31_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230916_PL54/wells401/segtrack/segs/ch1/31_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230916_PL54/wells501/segtrack/segs/ch0/31_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230916_PL54/wells501/segtrack/segs/ch0/31_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230916_PL54/wells501/segtrack/segs/ch1/31_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230916_PL54/wells501/segtrack/segs/ch1/31_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230916_PL48/wells001/segtrack/segs/ch0/31_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230916_PL48/wells001/segtrack/segs/ch0/31_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230916_PL48/wells001/segtrack/segs/ch1/31_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230916_PL48/wells001/segtrack/segs/ch1/31_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230916_PL48/wells101/segtrack/segs/ch0/31_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230916_PL48/wells101/segtrack/segs/ch0/31_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230916_PL48/wells101/segtrack/segs/ch1/31_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230916_PL48/wells101/segtrack/segs/ch1/31_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230915_PL52/wells001/segtrack/segs/ch0/31_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230915_PL52/wells001/segtrack/segs/ch0/31_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230915_PL52/wells001/segtrack/segs/ch1/31_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230915_PL52/wells001/segtrack/segs/ch1/31_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230915_PL52/wells101/segtrack/segs/ch0/31_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230915_PL52/wells101/segtrack/segs/ch0/31_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230915_PL52/wells101/segtrack/segs/ch1/31_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230915_PL52/wells101/segtrack/segs/ch1/31_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230915_PL52/wells201/segtrack/segs/ch0/31_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230915_PL52/wells201/segtrack/segs/ch0/31_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230915_PL52/wells201/segtrack/segs/ch1/31_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230915_PL52/wells201/segtrack/segs/ch1/31_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230915_PL52/wells301/segtrack/segs/ch0/31_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230915_PL52/wells301/segtrack/segs/ch0/31_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230915_PL52/wells301/segtrack/segs/ch1/31_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230915_PL52/wells301/segtrack/segs/ch1/31_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230915_PL52/wells401/segtrack/segs/ch0/31_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230915_PL52/wells401/segtrack/segs/ch0/31_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230915_PL52/wells401/segtrack/segs/ch1/31_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230915_PL52/wells401/segtrack/segs/ch1/31_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230825_PL57/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230825_PL57/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230825_PL57/wells001/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230825_PL57/wells001/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230825_PL39/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230825_PL39/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230825_PL39/wells001/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230825_PL39/wells001/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230823_PL61/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230823_PL61/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230823_PL61/wells001/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230823_PL61/wells001/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230823_PL48/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230823_PL48/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230823_PL48/wells001/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230823_PL48/wells001/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230823_PL28/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230823_PL28/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230823_PL28/wells001/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230823_PL28/wells001/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230823_PL28/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230823_PL28/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230823_PL28/wells101/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230823_PL28/wells101/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230823_PL28/wells201/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230823_PL28/wells201/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230823_PL28/wells201/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230823_PL28/wells201/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230821_PL57/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230821_PL57/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230821_PL57/wells001/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230821_PL57/wells001/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230819_PL62/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230819_PL62/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230819_PL62/wells001/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230819_PL62/wells001/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230819_PL43/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230819_PL43/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230819_PL43/wells001/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230819_PL43/wells001/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230819_PL43/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230819_PL43/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230819_PL43/wells101/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230819_PL43/wells101/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230819_PL43/wells201/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230819_PL43/wells201/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230819_PL43/wells201/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230819_PL43/wells201/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"]; 

warp_refs = [repmat(25,1,4)...
    repmat(31,1,4)...
    repmat(30,1,4)...
    repmat(30,1,4)...
    repmat(20,1,4)...
    repmat(35,1,4)...
    repmat(37,1,4)...
    repmat(30,1,4)...
    repmat(25,1,4)...
    repmat(25,1,4)...
    repmat(32,1,4)...
    repmat(35,1,4)...
    repmat(30,1,4)...
    repmat(31,1,4)...
    repmat(30,1,4)...
    repmat(15,1,4)...
    repmat(37,1,4)...
    repmat(31,1,4)...
    repmat(31,1,4)...
    repmat(25,1,4)...
    repmat(37,1,4)...
    repmat(37,1,4)...
    repmat(26,1,4)...
    repmat(36,1,4)...
    repmat(31,1,4)...
    repmat(35,1,4)...
    repmat(15,1,4)...
    repmat(19,1,4)...
    repmat(35,1,4)...
    repmat(18,1,4)...
    repmat(15,1,4)...
    repmat(15,1,4)...
    repmat(40,1,4)...
    repmat(25,1,4)...
    repmat(15,1,4)...
    repmat(20,1,4)...
    repmat(40,1,4)...
    repmat(15,1,4)...
    repmat(4,1,4)...
    repmat(5,1,4)...
    repmat(18,1,4)...
    repmat(13,1,4)...
    repmat(25,1,4)...
    repmat(19,1,4)...
    repmat(15,1,4)...
    repmat(35,1,4)...
    repmat(25,1,4)...
    repmat(40,1,4)...
    repmat(18,1,4)...
    repmat(15,1,4)...
    repmat(31,1,4)...
    repmat(25,1,4)...
    repmat(19,1,4)...
    repmat(18,1,4)...
    repmat(15,1,4)...
    repmat(27,1,4)...
    repmat(25,1,4)...
    repmat(18,1,4)...
    repmat(15,1,4)...
    repmat(46,1,4)...
    repmat(22,1,4)...
    repmat(20,1,4)...
    repmat(34,1,4)...
    repmat(31,1,4)...
    repmat(1,1,4)]'; 

warp_bounds = [[173 683 2 452];
         [180 690 20 470];
         [160 670 0 450];
         [165 675 10 460];
         [124 634 0 450];
         [69 579 6 456];
         [127 637 13 463];
         [222 732 23 473];
         [171 681 13 463];
         [177 687 4 454];
         [110 620 53 503];
         [191 701 13 463];
         [187 697 11 461];
         [172 682 9 459];
         [160 670 7 457];
         [118 628 11 461];
         [117 627 17 467];
         [158 668 16 468];
         [152 662 0 450];
         [191 701 26 476];
         [189 699 19 469];
         [115 625 22 472];
         [129 639 22 472];
         [194 704 11 461];
         [187 697 0 450];
         [175 685 11 461];
         [165 675 16 466];
         [128 638 16 466];
         [143 653 20 470];
         [147 657 19 469];
         [143 653 9 459];
         [164 674 13 463];
         [165 675 19 469];
         [118 628 18 468];
         [117 627 36 486];
         [171 681 37 487];
         [129 639 7 457];
         [159 669 21 471];
         [122 632 48 498];
         [171 681 18 468];
         [202 712 2 452];
         [141 651 5 455];
         [140 650 13 463];
         [110 620 16 466];
         [195 705 8 458];
         [185 695 4 454];
         [109 619 7 457];
         [230 740 13 463];
         [156 663 3 453];
         [132 642 19 469]; 
         [160 670 24 474];
         [164 674 28 478];
         [168 678 24 474];
         [90 600 25 475];
         [145 655 15 465];
         [198 708 0 450];
         [250 760 40 490];
         [170 680 10 460];
         [161 671 2 452];
         [161 671 36 486];
         [115 625 0 450];
         [205 715 20 470];
         [175 685 20 470];
         [176 686 11 461];
         [166 676 0 450]];
     
%% in vivo 2023 8/10 back - warping on colab00

%mov_prefix = "//nasquatch/data/2p/";

%warp_prefix = "D:/2p_data/";
%warp_prefix = "//santiago/2p_data/";

mov_prefix = "/mnt/nasquatch/data/2p/";

warp_prefix = "/mnt/santiago/2p_data/";

mov_paths = ["peter/in_vivo/230810_DG87PL55/DG87PL55_230810_001_noartifact.sbx"
        "peter/in_vivo/230810_DG87PL55/DG87PL55_230810_101_full.sbx"
        "peter/in_vivo/230809_DG86PL57/DG86PL57_230809_001_noartifact.sbx"
        "peter/in_vivo/230809_DG86PL57/DG86PL57_230809_101_full.sbx"
        "peter/in_vivo/230808_DG85PL61/DG85PL61_230808_001_noartifact.sbx"
        "peter/in_vivo/230808_DG85PL61/DG85PL61_230808_101_full.sbx"
        "peter/in_vivo/230807_DG84PL52/DG84PL52_230807_001_noartifact.sbx"
        "peter/in_vivo/230807_DG84PL52/DG84PL52_230807_101_full.sbx"
        "peter/in_vivo/230802_DG48PL58/DG48PL58_230802_001_noartifact.sbx"
        "peter/in_vivo/230802_DG48PL58/DG48PL58_230802_101_full.sbx"
        "peter/in_vivo/230728_DG80PL57/DG80PL57_230728_001_noartifact.sbx"
        "peter/in_vivo/230727_DG79PL59/DG79PL59_230727_001_noartifact.sbx"
        "peter/in_vivo/230726_DG47PL54/DG47PL54_230726_001_noartifact.sbx"
        "peter/in_vivo/230726_DG47PL54/DG47PL54_230726_101_full.sbx"
        "peter/in_vivo/230721_DG46PL32/DG46PL32_230721_001_noartifact.sbx"
        "peter/in_vivo/230721_DG46PL32/DG46PL32_230721_101_full.sbx"
        "peter/in_vivo/230720_PK97PL48/PK97PL48_230720_001_noartifact.sbx"
        "peter/in_vivo/230720_PK97PL48/PK97PL48_230720_101_full.sbx"
        "peter/in_vivo/230714_PK95PL55/PK95PL55_230714_001_noartifact.sbx"
        "peter/in_vivo/230713_PK94PL59/PK94PL59_230713_001_noartifact.sbx"
        "peter/in_vivo/230713_PK94PL59/PK94PL59_230713_101_full.sbx"
        "peter/in_vivo/230712_PK93PL57/PK93PL57_230712_001_noartifact.sbx"
        "peter/in_vivo/230712_PK93PL57/PK93PL57_230712_101_full.sbx"
        "peter/in_vivo/230711_DG44PL47/DG44PL47_230711_001_noartifact.sbx"
        "peter/in_vivo/230711_DG44PL47/DG44PL47_230711_101_full.sbx"
        "peter/in_vivo/230711_DG43PL32/DG43PL32_230711_001_noartifact.sbx"
        "peter/in_vivo/230708_DG70PL56/DG70PL56_230708_001_noartifact.sbx"
        "peter/in_vivo/230708_DG70PL56/DG70PL56_230708_101_full.sbx"
        "peter/in_vivo/230707_DG72PL32/DG72PL32_230707_001_noartifact.sbx"
        "peter/in_vivo/230707_DG72PL32/DG72PL32_230707_101_full.sbx"
        "peter/in_vivo/230706_DG71PL54/DG71PL54_230706_001_noartifact.sbx"
        "peter/in_vivo/230706_DG71PL54/DG71PL54_230706_002.sbx"%mouse2??
        "peter/in_vivo/230706_DG71PL54/DG71PL54_230706_101_full.sbx"
        "peter/in_vivo/230617_DG70PL54/DG70PL54_230617_001_noartifact.sbx"
        "peter/in_vivo/230617_DG70PL54/DG70PL54_230617_101_full.sbx"
        "peter/in_vivo/230615_DG69PL32/DG69PL32_230615_001_noartifact.sbx"
        "peter/in_vivo/230615_DG69PL32/DG69PL32_230615_101_full.sbx"
        "peter/in_vivo/230614_DG63PL54/DG63PL54_230614_001_noartifact.sbx"
        "peter/in_vivo/230614_DG63PL54/DG63PL54_230614_101_full.sbx"
        "peter/in_vivo/230601_PK85PL53/PK85PL53_230601_001_noartifact.sbx"
        "peter/in_vivo/230601_PK85PL53/PL53_230601_101_full.sbx"
        "peter/in_vivo/230531_PK80PL43/PK80PL43_230531_001_noartifact.sbx"
        "peter/in_vivo/230531_PK80PL43/PL43_230531_101_full.sbx"
        "peter/in_vivo/230526_PK84PL50/PK84PL50_230526_001_noartifact.sbx"
        "peter/in_vivo/230526_PK84PL50/PL50_230526_101_full.sbx"
        "peter/in_vivo/230525_DG42PL39/DG42PL39_230525_001_noartifact.sbx"
        "peter/in_vivo/230525_DG42PL39/PL39_230525_101_full.sbx"
        "peter/in_vivo/230519_DG41PL52/DG41PL52_230519_001_noartifact.sbx"
        "peter/in_vivo/230519_DG41PL52/PL52_230519_101_full.sbx"];

warp_dirs = ["peter/in_vivo/230810_DG87PL55/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230810_DG87PL55/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230810_DG87PL55/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230810_DG87PL55/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230809_DG86PL57/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230809_DG86PL57/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230809_DG86PL57/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230809_DG86PL57/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230808_DG85PL61/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230808_DG85PL61/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230808_DG85PL61/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230808_DG85PL61/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230807_DG84PL52/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230807_DG84PL52/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230807_DG84PL52/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230807_DG84PL52/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230802_DG48PL58/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230802_DG48PL58/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230802_DG48PL58/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230802_DG48PL58/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230728_DG80PL57/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230728_DG80PL57/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230727_DG79PL59/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230727_DG79PL59/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230726_DG47PL54/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230726_DG47PL54/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230726_DG47PL54/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230726_DG47PL54/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230721_DG46PL32/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230721_DG46PL32/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230721_DG46PL32/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230721_DG46PL32/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230720_PK97PL48/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230720_PK97PL48/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230720_PK97PL48/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230720_PK97PL48/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230714_PK95PL55/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230714_PK95PL55/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230713_PK94PL59/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230713_PK94PL59/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230713_PK94PL59/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230713_PK94PL59/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230712_PK93PL57/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230712_PK93PL57/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230712_PK93PL57/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230712_PK93PL57/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230711_DG44PL47/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230711_DG44PL47/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230711_DG44PL47/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230711_DG44PL47/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230711_DG43PL32/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230711_DG43PL32/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230708_DG70PL56/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230708_DG70PL56/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230708_DG70PL56/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230708_DG70PL56/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230707_DG72PL32/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230707_DG72PL32/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230707_DG72PL32/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230707_DG72PL32/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230706_DG71PL54/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230706_DG71PL54/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230706_DG71PL54/mouse2/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230706_DG71PL54/mouse2/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230706_DG71PL54/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230706_DG71PL54/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230617_DG70PL54/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230617_DG70PL54/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230617_DG70PL54/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230617_DG70PL54/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230615_DG69PL32/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230615_DG69PL32/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230615_DG69PL32/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230615_DG69PL32/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230614_DG63PL54/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230614_DG63PL54/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230614_DG63PL54/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230614_DG63PL54/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230601_PK85PL53/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230601_PK85PL53/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230601_PK85PL53/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230601_PK85PL53/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230531_PK80PL43/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230531_PK80PL43/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230531_PK80PL43/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230531_PK80PL43/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230526_PK84PL50/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230526_PK84PL50/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230526_PK84PL50/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230526_PK84PL50/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230525_DG42PL39/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230525_DG42PL39/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230525_DG42PL39/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230525_DG42PL39/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230519_DG41PL52/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230519_DG41PL52/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230519_DG41PL52/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230519_DG41PL52/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"];
         
warp_refs = [repmat(94,1,2)...
    repmat(48,1,2)...
    repmat(89,1,2)...
    repmat(48,1,2)...
    repmat(55,1,2)...
    repmat(48,1,2)...
    repmat(73,1,2)...
    repmat(48,1,2)...
    repmat(71,1,2)...
    repmat(57,1,2)...
    repmat(10,1,2)...
    repmat(1,1,2)...
    repmat(71,1,2)...
    repmat(30,1,2)...
    repmat(71,1,2)...
    repmat(57,1,2)...
    repmat(70,1,2)...
    repmat(50,1,2)...
    repmat(15,1,2)...
    repmat(71,1,2)...
    repmat(50,1,2)...
    repmat(35,1,2)...
    repmat(57,1,2)...
    repmat(53,1,2)...
    repmat(1,1,2)...
    repmat(29,1,2)...
    repmat(71,1,2)...
    repmat(57,1,2)...
    repmat(40,1,2)...
    repmat(35,1,2)...
    repmat(25,1,2)...
    repmat(3,1,2)...
    repmat(30,1,2)...
    repmat(71,1,2)...
    repmat(40,1,2)...
    repmat(71,1,2)...
    repmat(54,1,2)...
    repmat(50,1,2)...
    repmat(1,1,2)...
    repmat(1,1,2)...
    repmat(1,1,2)...
    repmat(20,1,2)...
    repmat(1,1,2)...
    repmat(62,1,2)...
    repmat(1,1,2)...
    repmat(70,1,2)...
    repmat(1,1,2)...
    repmat(71,1,2)...
    repmat(1,1,2)]';

warp_bounds = [[140 650 35 485];
         [185 695 0 450];
         [136 646 30 480];
         [139 649 31 481];
         [128 638 32 482];
         [193 703 33 483];
         [123 633 32 482];
         [136 646 60 510];
         [136 646 33 483];
         [147 657 25 475];
         [145 655 18 468];
         [134 644 33 483];
         [136 646 24 474];
         [238 748 21 471];
         [148 658 34 484];
         [195 705 10 460];
         [149 659 31 481];
         [204 714 39 489];
         [135 645 31 481];
         [131 641 26 476];
         [227 737 34 484];
         [148 658 38 488];
         [160 670 10 460];
         [134 644 37 487];
         [220 730 0 450];
         [160 670 30 480];
         [137 647 20 470];
         [190 700 10 460];
         [150 660 31 481];
         [126 636 20 470];
         [159 669 31 481];
         [165 675 40 490];
         [165 675 35 485];
         [146 656 29 479];
         [165 675 40 490];
         [155 665 33 483];
         [109 619 20 470];
         [155 665 47 497];
         [170 680 15 465];
         [134 644 48 498];
         [150 660 10 460];
         [138 648 42 492];
         [200 710 25 475];
         [161 671 42 492];
         [225 735 26 476];
         [142 652 25 475];
         [200 710 10 460];
         [167 677 41 491];
         [167 677 48 498]];

%% in vivo 2022 - to warp on santiago

mov_prefix = "//nasquatch/data/2p/";

%warp_prefix = "D:/2p_data/";
warp_prefix = "//santiago/2p_data/";

%mov_prefix = "/mnt/nasquatch/data/2p/";

%warp_prefix = "/mnt/santiago/2p_data/";

mov_paths = ["peter/in_vivo/221204_PS39PL51/PS39PL51_221204_001_noartifact.sbx"
        "peter/in_vivo/221204_PS39PL51/PS39PL51_221204_101_full.sbx"
        "peter/in_vivo/221203_PS45PL50/PS45PL50_221203_001_noartifact.sbx"
        "peter/in_vivo/221203_PS45PL50/PS45PL50_221203_101_full.sbx"
        "peter/in_vivo/221125_PS39PL50/PS39PL50_221125_001_noartifact.sbx"
        "peter/in_vivo/221125_PS39PL50/PS39PL50_221125_101_full.sbx"
        "peter/in_vivo/221111_PS28PL41/PS28PL41_221111_001_noartifact.sbx"
        "peter/in_vivo/221111_PS28PL41/PS28PL41_221111_101_full.sbx"
        "peter/in_vivo/221109_PS27PL28/PS27PL28_221109_0011_noartifact.sbx"
        "peter/in_vivo/221109_PS27PL28/PS27PL28_221109_001_full.sbx"
        "peter/in_vivo/221107_PS23PL42/PS23PL42_221107_001_noartifact.sbx"
        "peter/in_vivo/221020_PS16PL39/PS16PL39_221020_001_noartifact.sbx"
        "peter/in_vivo/221020_PS16PL39/PS16PL39_221020_101_full.sbx"
        "peter/in_vivo/221018_PS10PL24/PS10PL24_221018_001_noartifact.sbx"
        "peter/in_vivo/221018_PS10PL24/PS10PL24_221018_101_full.sbx"
        "peter/in_vivo/220929_PS11PL37/PS11PL37_220929_001_noartifact.sbx"
        "peter/in_vivo/220928_PK65PL30/PK65PL30_220928_001_noartifact.sbx"
        "peter/in_vivo/220927_PK60PL33/PK60PL33_220927_001_noartifact.sbx"
        "peter/in_vivo/220916_PK66PL28/PK66PL28_220916_001_noartifact.sbx"
        "peter/in_vivo/220916_PK66PL28/PK66PL28_220916_101_full.sbx"
        "peter/in_vivo/220913_PK65PL32/PK65PL32_220913_001_noartifact.sbx"
        "peter/in_vivo/220903_PK63PL34/PK63PL34_220903_001_noartifact.sbx"
        "peter/in_vivo/220903_PK63PL34/PK63PL34_220903_101_full.sbx"
        "peter/in_vivo/220902_PK61PL37/PK61PL37_220902_001_noartifact.sbx"
        "peter/in_vivo/220902_PK61PL37/PPK61PL37_220902_101_full.sbx"
        "peter/in_vivo/220901_PK60PL36/PK60PL36_220901_001_noartifact.sbx"
        "peter/in_vivo/220901_PK60PL36/PK60PL36_220901_101_full.sbx"
        "peter/in_vivo/220701_PK49PL18/PK49PL18_220701_001_noartifact.sbx"
        "peter/in_vivo/220701_PK49PL18/PK49PL18_220701_101_full.sbx"
        "peter/in_vivo/220629_PK46PL25/PK46PL25_220629_001_noartifact.sbx"
        "peter/in_vivo/220629_PK46PL25/PK46PL25_220629_101_full.sbx"
        "peter/in_vivo/220628_PK45PL24/PK45PL24_220628_001_noartifact.sbx"
        "peter/in_vivo/220624_PK45PL13/PK45PL13_220624_001_noartifact.sbx"
        "peter/in_vivo/220624_PK45PL13/PK45PL13_220624_101_full.sbx"
        "peter/in_vivo/220622_PK44PL17/PK44PL17_220622_001_noartifact.sbx"
        "peter/in_vivo/220622_PK44PL17/PK44PL17_220622_101_full.sbx"
        "peter/in_vivo/220621_PK24PL13/PK24PL13_220621_001_noartifact.sbx"
        "peter/in_vivo/220621_PK24PL13/PK25PL13_220621_101_full.sbx"
        "peter/in_vivo/220617_PK26PL18/PK26PL18_220617_001_noartifact.sbx"
        "peter/in_vivo/220617_PK26PL18/PK26PL18_220617_101_full.sbx"
        "peter/in_vivo/220616_PK25PL9/PK25PL9_220616_001_noartifact.sbx"
        "peter/in_vivo/220615_PK24PL18/PK24PL18_220615_001_noartifact.sbx"
        "peter/in_vivo/220530_PK25PL9/PK25PL9_220530_001_noartifact.sbx"
        "peter/in_vivo/220530_PK25PL9/PK25PL9_220530_101_full.sbx"
        "peter/in_vivo/220519_PK43PL17/PK43PL17_220519_001_noartifact.sbx"
        "peter/in_vivo/220519_PK43PL17/PK43PL17_220519_101_full.sbx"
        "peter/in_vivo/220518_PK40PL14/PK40PL14_220518_001_noartifact.sbx"
        "peter/in_vivo/220515_PK27PL13/PK27PL13_220515_001_noartifact.sbx"
        "peter/in_vivo/220514_PK26PL6/PK26PL6_220514_001_noartifact.sbx"
        "peter/in_vivo/220514_PK26PL6/PK26PL6_220514_101_full.sbx"
        "peter/in_vivo/220512_PK24PL19/PK24PL19_220512_001_noartifact.sbx"
        "peter/in_vivo/220506_PK26PL16/PK26PL16_220506_001_noartifact.sbx"
        "peter/in_vivo/220504_PK24PL9/PK24PL9_220504_001_noartifact.sbx"
        "peter/in_vivo/220504_PK24PL9/PK24PL9_220504_101_full.sbx"
        "peter/in_vivo/220427_PK27PL20/PK27PL20_220427_001_noartifact.sbx"
        "peter/in_vivo/220427_PK27PL20/PK27PL20_220427_101_full.sbx"
        "peter/in_vivo/220423_PK24PL17/PK24PL17_220423_001_noartifact.sbx"
        "peter/in_vivo/220408_PK27PL20/PK27PL20_220408_001_noartifact.sbx"
        "peter/in_vivo/220408_PK27PL20/PK27PL20_220408_101_full.sbx"
        "peter/in_vivo/220407_PK26PL15/PK26PL15_220407_001_noartifact.sbx"
        "peter/in_vivo/220407_PK26PL15/PK26PL15_220407_101_full.sbx"
        "peter/in_vivo/220406_PK24PL10/PK24PL10_220406_001_noartifact.sbx"
        "peter/in_vivo/220406_PK24PL10/PK24PL10_220406_101_full.sbx"
        "peter/in_vivo/220318_PK24PL14/PK24PL14_220318_001_noartifact.sbx"
        "peter/in_vivo/220318_PK24PL14/PK24PL14_220318_101_full.sbx"
        "peter/in_vivo/220316_PK32PL13/PK32PL13_220316_001_noartifact.sbx"
        "peter/in_vivo/220316_PK32PL13/PK32PL13_220316_101_full.sbx"
        "peter/in_vivo/220315_PK36PL18/PK36PL18_220315_001_noartifact.sbx"
        "peter/in_vivo/220315_PK36PL18/PK36PL18_220315_101_full.sbx"
        "peter/in_vivo/220314_PL14BCH/PL14BCH_220314_001_full.sbx"
        "peter/in_vivo/220311_PK24PL9/PK24PL9_220311_001_noartifact.sbx"
        "peter/in_vivo/220311_PK24PL9/PK24PL9_220311_101_full.sbx"
        "peter/in_vivo/220303_PK26PL21/PK26PL21_220303_001_noartifact.sbx"
        "peter/in_vivo/220303_PK26PL21/PK26PL21_220303_101_full.sbx"
        "peter/in_vivo/220302_PK27PL13/PK27PL13_220302_001_noartifact.sbx"
        "peter/in_vivo/220223_PK26PL19/PK26PL19_220223_001_noartifact.sbx"
        "peter/in_vivo/220217_PK27PL13/PK27PL13_220217_001_noartifact.sbx"
        "peter/in_vivo/220217_PK26PL15/PK26PL15_220217_001_noartifact.sbx"
        "peter/in_vivo/220216_PK25PL8/PK25PL8_220216_001_noartifact.sbx"
        "peter/in_vivo/220216_PK25PL8/PK25PL8_220216_101_full.sbx"];
    
warp_dirs = ["peter/in_vivo/221204_PS39PL51/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/221204_PS39PL51/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/221204_PS39PL51/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/221204_PS39PL51/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/221203_PS45PL50/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/221203_PS45PL50/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/221203_PS45PL50/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/221203_PS45PL50/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/221125_PS39PL50/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/221125_PS39PL50/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/221125_PS39PL50/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/221125_PS39PL50/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/221111_PS28PL41/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/221111_PS28PL41/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/221111_PS28PL41/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/221111_PS28PL41/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/221109_PS27PL28/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/221109_PS27PL28/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/221109_PS27PL28/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/221109_PS27PL28/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/221107_PS23PL42/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/221107_PS23PL42/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/221020_PS16PL39/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/221020_PS16PL39/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/221020_PS16PL39/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/221020_PS16PL39/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/221018_PS10PL24/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/221018_PS10PL24/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/221018_PS10PL24/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/221018_PS10PL24/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220929_PS11PL37/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220929_PS11PL37/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220928_PK65PL30/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220928_PK65PL30/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220927_PK60PL33/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220927_PK60PL33/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220916_PK66PL28/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220916_PK66PL28/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220916_PK66PL28/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220916_PK66PL28/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220913_PK65PL32/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220913_PK65PL32/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220903_PK63PL34/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220903_PK63PL34/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220903_PK63PL34/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220903_PK63PL34/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220902_PK61PL37/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220902_PK61PL37/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220902_PK61PL37/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220902_PK61PL37/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220901_PK60PL36/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220901_PK60PL36/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220901_PK60PL36/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220901_PK60PL36/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220701_PK49PL18/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220701_PK49PL18/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220701_PK49PL18/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220701_PK49PL18/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220629_PK46PL25/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220629_PK46PL25/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220629_PK46PL25/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220629_PK46PL25/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220628_PK45PL24/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220628_PK45PL24/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220624_PK45PL13/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220624_PK45PL13/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220624_PK45PL13/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220624_PK45PL13/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220622_PK44PL17/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220622_PK44PL17/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220622_PK44PL17/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220622_PK44PL17/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220621_PK24PL13/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220621_PK24PL13/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220621_PK24PL13/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220621_PK24PL13/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220617_PK26PL18/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220617_PK26PL18/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220617_PK26PL18/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220617_PK26PL18/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220616_PK25PL9/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220616_PK25PL9/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220615_PK24PL18/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220615_PK24PL18/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220530_PK25PL9/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220530_PK25PL9/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220530_PK25PL9/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220530_PK25PL9/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220519_PK43PL17/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220519_PK43PL17/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220519_PK43PL17/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220519_PK43PL17/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220518_PK40PL14/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220518_PK40PL14/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220515_PK27PL13/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220515_PK27PL13/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220514_PK26PL6/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220514_PK26PL6/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220514_PK26PL6/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220514_PK26PL6/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220512_PK24PL19/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220512_PK24PL19/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220506_PK26PL16/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220506_PK26PL16/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220504_PK24PL9/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220504_PK24PL9/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220504_PK24PL9/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220504_PK24PL9/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220427_PK27PL20/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220427_PK27PL20/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220427_PK27PL20/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220427_PK27PL20/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220423_PK24PL17/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220423_PK24PL17/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220408_PK27PL20/mouse_noart/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220408_PK27PL20/mouse_noart/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220408_PK27PL20/wells/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220408_PK27PL20/wells/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220407_PK26PL15/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220407_PK26PL15/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220407_PK26PL15/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220407_PK26PL15/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220406_PK24PL10/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220406_PK24PL10/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220406_PK24PL10/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220406_PK24PL10/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220318_PK24PL14/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220318_PK24PL14/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220318_PK24PL14/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220318_PK24PL14/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220316_PK32PL13/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220316_PK32PL13/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220316_PK32PL13/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220316_PK32PL13/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220315_PK36PL18/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220315_PK36PL18/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220315_PK36PL18/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220315_PK36PL18/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220314_PL14BCH/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220314_PL14BCH/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220311_PK24PL9/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220311_PK24PL9/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220311_PK24PL9/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220311_PK24PL9/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220303_PK26PL21/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220303_PK26PL21/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220303_PK26PL21/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220303_PK26PL21/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220302_PK27PL13/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220302_PK27PL13/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220223_PK26PL19/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220223_PK26PL19/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220217_PK27PL13/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220217_PK27PL13/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220217_PK26PL15/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220217_PK26PL15/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220216_PK25PL8/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220216_PK25PL8/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220216_PK25PL8/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220216_PK25PL8/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"];
         
warp_refs = [repmat(58,1,2)...
    repmat(1,1,2)...
    repmat(30,1,2)...
    repmat(115,1,2)...
    repmat(58,1,2)...
    repmat(1,1,2)...
    repmat(40,1,2)...
    repmat(1,1,2)...
    repmat(58,1,2)...
    repmat(1,1,2)...
    repmat(10,1,2)...
    repmat(18,1,2)...
    repmat(115,1,2)...
    repmat(31,1,2)...
    repmat(20,1,2)...
    repmat(53,1,2)...
    repmat(53,1,2)...
    repmat(53,1,2)...
    repmat(1,1,2)...
    repmat(115,1,2)...
    repmat(40,1,2)...
    repmat(55,1,2)...
    repmat(115,1,2)...
    repmat(1,1,2)...
    repmat(1,1,2)...
    repmat(67,1,2)...
    repmat(60,1,2)...
    repmat(76,1,2)...
    repmat(100,1,2)...
    repmat(76,1,2)...
    repmat(20,1,2)...
    repmat(1,1,2)...
    repmat(70,1,2)...
    repmat(1,1,2)...
    repmat(76,1,2)...
    repmat(115,1,2)...
    repmat(67,1,2)...
    repmat(10,1,2)...
    repmat(40,1,2)...
    repmat(120,1,2)...
    repmat(76,1,2)...
    repmat(35,1,2)...
    repmat(20,1,2)...
    repmat(80,1,2)...
    repmat(76,1,2)...
    repmat(115,1,2)...
    repmat(50,1,2)...
    repmat(60,1,2)...
    repmat(25,1,2)...
    repmat(60,1,2)...
    repmat(1,1,2)...
    repmat(76,1,2)...
    repmat(80,1,2)...
    repmat(13,1,2)...
    repmat(77,1,2)...
    repmat(80,1,2)...
    repmat(67,1,2)...
    repmat(71,1,2)...
    repmat(57,1,2)...
    repmat(20,1,2)...
    repmat(57,1,2)...
    repmat(40,1,2)...
    repmat(57,1,2)...
    repmat(80,1,2)...
    repmat(62,1,2)...
    repmat(70,1,2)...
    repmat(5,1,2)...
    repmat(71,1,2)...
    repmat(21,1,2)...
    repmat(57,1,2)...
    repmat(62,1,2)...
    repmat(100,1,2)...
    repmat(50,1,2)...
    repmat(91,1,2)...
    repmat(62,1,2)...
    repmat(67,1,2)...
    repmat(58,1,2)...
    repmat(53,1,2)...
    repmat(62,1,2)...
    repmat(45,1,2)]';

warp_bounds = [[138 648 33 483];
         [145 655 40 490];
         [131 641 45 495];
         [150 660 40 490];
         [140 650 35 485];
         [160 670 30 480];
         [133 643 30 480];
         [170 680 35 485];
         [126 636 33 483];
         [195 705 35 485];
         [165 675 20 470];
         [133 643 34 484];
         [234 744 0 450];
         [135 645 33 483];
         [206 716 55 505];
         [152 662 27 477];
         [149 659 15 465];
         [160 670 29 479];
         [129 639 40 490];
         [175 685 50 500];
         [134 644 43 493];
         [176 686 35 485];
         [91 601 48 498];
         [156 666 14 464];
         [160 670 20 470];
         [146 656 33 483];
         [182 692 39 489];
         [142 652 34 484];
         [200 710 35 485];
         [151 661 42 492];
         [180 690 25 475];
         [143 653 26 476];
         [154 664 31 481];
         [181 691 21 471];
         [153 663 30 480];
         [148 658 30 480];
         [156 666 33 483];
         [145 655 20 470];
         [151 661 22 472];
         [195 705 20 470];
         [147 657 21 471];
         [145 655 26 476];
         [138 648 31 481];
         [205 715 15 465];
         [145 655 32 482];
         [167 677 62 512]; %changed!
         [159 669 23 473];
         [148 658 42 492];
         [145 655 27 477];
         [200 710 20 470];
         [157 667 38 488];
         [149 659 32 482];
         [158 668 43 493];
         [146 656 27 477];
         [152 662 39 489];
         [209 719 53 503];
         [142 652 44 494];
         [160 670 21 471];
         [160 670 21 471];
         [139 649 37 487];
         [144 654 14 464];
         [150 660 30 480];
         [179 689 25 475];
         [153 663 37 487];
         [95 605 33 483];
         [157 667 31 481];
         [173 683 43 493];
         [161 671 38 488];
         [85 595 43 493];
         [90 600 62 512];
         [137 647 44 494];
         [259 769 15 465];
         [150 660 37 487];
         [182 692 27 477];
         [138 648 40 490];
         [149 659 30 480];
         [125 635 41 491];
         [144 654 35 485];
         [144 654 40 490];
         [84 594 37 487]];

%% dipping 2022

mov_prefix = "//nasquatch/data/2p/";

%warp_prefix = "D:/2p_data/";
warp_prefix = "//santiago/2p_data/";

%mov_prefix = "/mnt/nasquatch/data/2p/";

%warp_prefix = "/mnt/santiago/2p_data/";

mov_paths = ["peter/dipping/20221129_PL28/PL28_221129_001_full.sbx"
        "peter/dipping/20221129_PL28/PL28_221129_101_full.sbx"
        "peter/dipping/20221118_PL28/PL28_221118_001_full.sbx"
        "peter/dipping/20221116_PL44/PL44_221116_001_full.sbx"
        "peter/dipping/20221115_PL42/PL42_221115_001_full.sbx"
        "peter/dipping/20221115_PL42/PL42_221115_101_full.sbx"
        "peter/dipping/20221115_PL42/PL42_221115_201_full.sbx"
        "peter/dipping/20221104_PL45/PL45_221104_001_full.sbx"
        "peter/dipping/20221103_PL47/PL47_221103_001_full.sbx"
        "peter/dipping/20221103_PL38/PL38_221103_001_full.sbx"
        "peter/dipping/20221102_PL44/PL44_221102_001_full.sbx"
        "peter/dipping/20221102_PL44/PL44_221102_101_full.sbx"
        "peter/dipping/20221101_PL42/PL42_221101_001_full.sbx"
        "peter/dipping/20221101_PL42/PL42_221101_101_full.sbx"
        "peter/dipping/20221014_PL36/PL36_221014_001_full.sbx"
        "peter/dipping/20221014_PL36/PL36_221014_101_full.sbx"
        "peter/dipping/20221013_PL33/PL33_221013_001_full.sbx"
        "peter/dipping/20221013_PL33/PL33_221013_101_full.sbx"
        "peter/dipping/20220930_PL34/PL34_220930_001_full.sbx"
        "peter/dipping/20220930_PL34/PL34_220930_101_full.sbx"
        "peter/dipping/20220921_PL25/PL25_220921_001_full.sbx"
        "peter/dipping/20220921_PL25/PL25_220921_101_full.sbx"
        "peter/dipping/20220915_PL29/PL29_220915_001_full.sbx"
        "peter/dipping/20220915_PL29/PL29_220915_101_full.sbx"
        "peter/dipping/20220914_PL21/PL21_220914_001_full.sbx"
        "peter/dipping/20220914_PL21/PL21_220914_101_full.sbx"
        "peter/dipping/20220907_PL27/PL27_220907_001_full.sbx"
        "peter/dipping/20220907_PL27/PL27_220907_101_full.sbx"
        "peter/dipping/20220906_PL24/PL24_220906_001_full.sbx"
        "peter/dipping/20220906_PL24/PL24_220906_101_full.sbx"
        "peter/dipping/20220831_PL31/PL31_220831_001_full.sbx"
        "peter/dipping/20220831_PL27/PL27_220831_001_full.sbx"
        "peter/dipping/20220830_PL32/PL32_220830_001_full.sbx"
        "peter/dipping/20220830_PL24/PL24_220830_001_full.sbx"
        "peter/dipping/20220825_PL29/PL29_220825_001_full.sbx"
        "peter/dipping/20220825_PL18/PL18_220825_001_full.sbx"
        "peter/dipping/20220824_PL33/PL33_220824_001_full.sbx"
        "peter/dipping/20220824_PL13/PL13_220824_001_full.sbx"
        "peter/dipping/20220823_PL32/PL32_220823_001_full.sbx"
        "peter/dipping/20220823_PL24/PL24_220823_001_full.sbx"
        "peter/dipping/20220819_PL23/PL23_220819_001_full.sbx"
        "peter/dipping/20220819_PL22/PL22_220819_001_full.sbx"
        "peter/dipping/20220817_PL31/PL31_220817_001_full.sbx"
        "peter/dipping/20220817_PL27/PL27_220817_001_full.sbx"
        "peter/dipping/20220816_PL24/PL24_220816_001_full.sbx"
        "peter/dipping/20220812_PL28/PL28_220812_001_full.sbx"
        "peter/dipping/20220812_PL22/PL22_220812_001_full.sbx"
        "peter/dipping/20220811_PL30/PL30_220811_001_full.sbx"
        "peter/dipping/20220811_PL18/PL18_220811_001_full.sbx"
        "peter/dipping/20220810_PL27/PL27_220810_001_full.sbx"
        "peter/dipping/20220810_PL20/PL20_220810_001_full.sbx"
        "peter/dipping/20220809_PL24/PL24_220809_001_full.sbx"
        "peter/dipping/20220809_PL14/PL14_220809_001_full.sbx"
        "peter/dipping/20220729_PL27/PL27_220729_001_full.sbx"
        "peter/dipping/20220728_PL24/PL24_220728_001_full.sbx"
        "peter/dipping/20220727_PL14/PL14_220727_001_full.sbx"
        "peter/dipping/20220707_PL18/PL18_220707_001_full.sbx"
        "peter/dipping/20220705_PL9/PL9_220705_001_full.sbx"];
    
warp_dirs = ["peter/dipping/20221129_PL28/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20221129_PL28/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20221129_PL28/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20221129_PL28/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20221118_PL28/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20221118_PL28/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20221116_PL44/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20221116_PL44/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20221115_PL42/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20221115_PL42/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20221115_PL42/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20221115_PL42/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20221115_PL42/wells201/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20221115_PL42/wells201/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20221104_PL45/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20221104_PL45/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20221103_PL47/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20221103_PL47/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20221103_PL38/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20221103_PL38/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20221102_PL44/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20221102_PL44/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20221102_PL44/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20221102_PL44/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20221101_PL42/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20221101_PL42/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20221101_PL42/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20221101_PL42/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20221014_PL36/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20221014_PL36/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20221014_PL36/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20221014_PL36/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20221013_PL33/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20221013_PL33/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20221013_PL33/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20221013_PL33/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20220930_PL34/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20220930_PL34/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20220930_PL34/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20220930_PL34/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20220921_PL25/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20220921_PL25/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20220921_PL25/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20220921_PL25/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20220915_PL29/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20220915_PL29/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20220915_PL29/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20220915_PL29/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20220914_PL21/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20220914_PL21/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20220914_PL21/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20220914_PL21/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20220907_PL27/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20220907_PL27/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20220907_PL27/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20220907_PL27/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20220906_PL24/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20220906_PL24/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20220906_PL24/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20220906_PL24/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20220831_PL31/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20220831_PL31/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20220831_PL27/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20220831_PL27/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20220830_PL32/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20220830_PL32/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20220830_PL24/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20220830_PL24/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20220825_PL29/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20220825_PL29/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20220825_PL18/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20220825_PL18/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20220824_PL33/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20220824_PL33/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20220824_PL13/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20220824_PL13/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20220823_PL32/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20220823_PL32/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20220823_PL24/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20220823_PL24/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20220819_PL23/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20220819_PL23/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20220819_PL22/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20220819_PL22/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20220817_PL31/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20220817_PL31/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20220817_PL27/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20220817_PL27/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20220816_PL24/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20220816_PL24/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20220812_PL28/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20220812_PL28/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20220812_PL22/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20220812_PL22/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20220811_PL30/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20220811_PL30/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20220811_PL18/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20220811_PL18/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20220810_PL27/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20220810_PL27/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20220810_PL20/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20220810_PL20/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20220809_PL24/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20220809_PL24/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20220809_PL14/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20220809_PL14/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20220729_PL27/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20220729_PL27/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20220728_PL24/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20220728_PL24/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20220727_PL14/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20220727_PL14/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20220707_PL18/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20220707_PL18/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20220705_PL9/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20220705_PL9/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"];
         
warp_refs = [repmat(40,1,2)...
    repmat(18,1,2)...
    repmat(1,1,2)...
    repmat(76,1,2)...
    repmat(10,1,2)...
    repmat(1,1,2)...
    repmat(16,1,2)...
    repmat(66,1,2)...
    repmat(1,1,2)...
    repmat(76,1,2)...
    repmat(19,1,2)...
    repmat(115,1,2)...
    repmat(19,1,2)...
    repmat(34,1,2)...
    repmat(19,1,2)...
    repmat(16,1,2)...
    repmat(19,1,2)...
    repmat(80,1,2)...
    repmat(13,1,2)...
    repmat(50,1,2)...
    repmat(19,1,2)...
    repmat(46,1,2)...
    repmat(19,1,2)...
    repmat(11,1,2)...
    repmat(18,1,2)...
    repmat(115,1,2)...
    repmat(18,1,2)...
    repmat(115,1,2)...
    repmat(18,1,2)...
    repmat(115,1,2)...
    repmat(57,1,2)...
    repmat(57,1,2)...
    repmat(10,1,2)...
    repmat(10,1,2)...
    repmat(20,1,2)...
    repmat(20,1,2)...
    repmat(12,1,2)...
    repmat(1,1,2)...
    repmat(10,1,2)...
    repmat(13,1,2)...
    repmat(10,1,2)...
    repmat(20,1,2)...
    repmat(20,1,2)...
    repmat(57,1,2)...
    repmat(1,1,2)...
    repmat(15,1,2)...
    repmat(55,1,2)...
    repmat(40,1,2)...
    repmat(48,1,2)...
    repmat(8,1,2)...
    repmat(10,1,2)...
    repmat(25,1,2)...
    repmat(10,1,2)...
    repmat(1,1,2)...
    repmat(13,1,2)...
    repmat(8,1,2)...
    repmat(10,1,2)...
    repmat(40,1,2)]';

warp_bounds = [[147 657 27 477];
         [155 665 25 475];
         [153 663 20 470];
         [146 656 35 485];
         [160 670 20 470];
         [180 690 30 480];
         [202 712 25 475];
         [182 692 32 482];
         [185 695 25 475];
         [183 693 30 480];
         [145 655 43 493];
         [170 680 15 465];
         [150 660 16 466];
         [185 695 10 460];
         [155 665 16 466];
         [130 640 10 460];
         [111 621 4 454];
         [120 630 15 465];
         [209 719 25 475];
         [215 725 15 465];
         [160 670 25 475];
         [185 695 40 490];
         [189 699 32 482];
         [190 700 30 480];
         [165 675 24 474];
         [127 637 6 456];
         [183 693 21 471];
         [170 680 40 490];
         [182 692 18 468];
         [130 640 5 455];
         [136 646 30 480];
         [207 717 10 460];
         [177 687 49 499];
         [138 648 23 473];
         [194 704 21 471];
         [202 712 34 484];
         [167 677 29 479];
         [150 660 8 458];
         [241 751 35 485];
         [139 649 33 483];
         [196 706 11 461];
         [116 626 4 454];
         [121 631 28 478];
         [187 697 0 450];
         [249 759 20 470];
         [166 676 27 477];
         [152 662 49 499];
         [143 653 31 481];
         [147 657 19 469];
         [179 689 35 485];
         [185 695 5 455];
         [173 683 2 452];
         [97 607 21 471];
         [160 670 40 490];
         [153 663 49 499];
         [241 751 23 473];
         [154 664 30 480];
         [196 706 17 467]];

%% dipping anastasia

mov_prefix = "//anastasia/data/2p/";

%warp_prefix = "D:/2p_data/";
warp_prefix = "//santiago/2p_data/";

%mov_prefix = "/mnt/anastasia/data/2p/";

%warp_prefix = "/mnt/santiago/2p_data/";

mov_paths = ["david/dipping_only/6plex/220304_PL7/PL7_220304_001_full.sbx"
        "david/dipping_only/6plex/220211_PK8/PK8_220211_001_full.sbx"
        "david/dipping_only/6plex/220210_PK7/PK7_220210_001_full.sbx"
        "david/dipping_only/6plex/220208_PK8/PK8_220208_001_full.sbx"
        "david/dipping_only/6plex/220207_PK5/PK5_220207_001_full.sbx"
        "david/dipping_only/6plex/220204_PK6/PK6_220204_001_full.sbx"
        "david/dipping_only/6plex/220203_PK9/PK9_220203_001_full.sbx"
        "david/dipping_only/6plex/220127_PK9/PK9_220127_001_full.sbx"
        "david/dipping_only/6plex/220126_PK8/PK8_220126_001_full.sbx"
        "david/dipping_only/6plex/220125_PK9/PK9_220125_001_full.sbx"
        "david/dipping_only/6plex/220121_PK8/PK8_220121_001_full.sbx"
        "david/dipping_only/6plex/220120_DT1/DT1_220120_001_full.sbx"
        "david/dipping_only/6plex/211222_PK8/PK8_211222_001_full.sbx"
        "david/dipping_only/6plex/211222_PK8/PK8_211222_101_full.sbx"
        "david/dipping_only/6plex/211222_PK8/PK8_211222_201_full.sbx"
        "david/dipping_only/6plex/211222_PK8/PK8_211222_301_full.sbx"
        "david/dipping_only/6plex/211221_PK7/PK7_211221_001_full.sbx"
        "david/dipping_only/6plex/211221_PK2/PK2_211221_001_full.sbx"
        %"david/dipping_only/6plex/211221_PK2/PK2_211221_101_full.sbx"
        "david/dipping_only/6plex/211221_PK2/PK2_211221_201_full.sbx"
        "david/dipping_only/6plex/211215_DT2/DT2_211215_001_full.sbx"
        "david/dipping_only/6plex/211215_DT2/DT2_211215_101_full.sbx"
        "david/dipping_only/6plex/211214_PK6/PK6_211214_001_full.sbx"
        "david/dipping_only/6plex/211214_PK6/PK6_211214_101_full.sbx"
        "david/dipping_only/6plex/211213_PK5/PK5_211213_001_full.sbx"
        "david/dipping_only/6plex/211213_PK5/PK5_211213_101_full.sbx"
        "david/dipping_only/6plex/211210_PL4_warped/PL4_211210_001_full.sbx"
        "david/dipping_only/6plex/211210_PL3_bumped/PL3_211210_001_full.sbx"
        "david/dipping_only/6plex/211209_PK6/PK6_211209_001_full.sbx"
        "david/dipping_only/6plex/211209_PK6/PK6_211209_101_full.sbx"
        "david/dipping_only/6plex/211207_PK7/PK7_211207_001_full.sbx"
        "david/dipping_only/6plex/211203_PK7/PK7_211203_001_full.sbx"
        "david/dipping_only/6plex/211202_PK3/PK3_211202_001_full.sbx"
        "david/dipping_only/6plex/211124_PK2/PK2_211124_001_full.sbx"
        "david/dipping_only/6plex/211122_DT1/DT1_211122_001_full.sbx"
        "david/dipping_only/6plex/211027_DT2/DT2_211027_001_full.sbx"
        "david/dipping_only/6plex/211027_DT2/DT2_211027_100_full.sbx"
        "david/dipping_only/6plex/211026_DT2/DT2_211026_001_full.sbx"
        "david/dipping_only/6plex/211026_DT2/DT2_211026_100_full.sbx"
        "david/dipping_only/6plex/211022_PK5/PK5_211022_001_full.sbx"
        "david/dipping_only/6plex/211022_PK5/PK5_211022_100_full.sbx"
        "david/dipping_only/6plex/211021_PK3/PK3_211021_001_full.sbx"
        "david/dipping_only/6plex/211021_PK3/PK3_211021_100_full.sbx"
        "david/dipping_only/6plex/211009_PK4/PK4_211009_001_full.sbx"
        "david/dipping_only/6plex/211009_PK4/PK4_211009_501_full.sbx"
        "david/dipping_only/6plex/211008_PK4/PK4_211008_001_full.sbx"
        "david/dipping_only/6plex/211008_PK4/PK4_211008_501_full.sbx"];
    
warp_dirs = ["david/dipping_only/6plex/220304_PL7/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "david/dipping_only/6plex/220304_PL7/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "david/dipping_only/6plex/220211_PK8/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "david/dipping_only/6plex/220211_PK8/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "david/dipping_only/6plex/220210_PK7/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "david/dipping_only/6plex/220210_PK7/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "david/dipping_only/6plex/220208_PK8/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "david/dipping_only/6plex/220208_PK8/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "david/dipping_only/6plex/220207_PK5/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "david/dipping_only/6plex/220207_PK5/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "david/dipping_only/6plex/220204_PK6/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "david/dipping_only/6plex/220204_PK6/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "david/dipping_only/6plex/220203_PK9/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "david/dipping_only/6plex/220203_PK9/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "david/dipping_only/6plex/220127_PK9/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "david/dipping_only/6plex/220127_PK9/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "david/dipping_only/6plex/220126_PK8/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "david/dipping_only/6plex/220126_PK8/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "david/dipping_only/6plex/220125_PK9/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "david/dipping_only/6plex/220125_PK9/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "david/dipping_only/6plex/220121_PK8/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "david/dipping_only/6plex/220121_PK8/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "david/dipping_only/6plex/220120_DT1/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "david/dipping_only/6plex/220120_DT1/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "david/dipping_only/6plex/211222_PK8/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "david/dipping_only/6plex/211222_PK8/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "david/dipping_only/6plex/211222_PK8/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "david/dipping_only/6plex/211222_PK8/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "david/dipping_only/6plex/211222_PK8/wells201/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "david/dipping_only/6plex/211222_PK8/wells201/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "david/dipping_only/6plex/211222_PK8/wells301/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "david/dipping_only/6plex/211222_PK8/wells301/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "david/dipping_only/6plex/211221_PK7/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "david/dipping_only/6plex/211221_PK7/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "david/dipping_only/6plex/211221_PK2/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "david/dipping_only/6plex/211221_PK2/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             %"david/dipping_only/6plex/211221_PK2/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg" %nothing from cellpose??
             %"david/dipping_only/6plex/211221_PK2/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg" %nothing from cellpose??
             "david/dipping_only/6plex/211221_PK2/wells201/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "david/dipping_only/6plex/211221_PK2/wells201/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "david/dipping_only/6plex/211215_DT2/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "david/dipping_only/6plex/211215_DT2/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "david/dipping_only/6plex/211215_DT2/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "david/dipping_only/6plex/211215_DT2/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "david/dipping_only/6plex/211214_PK6/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "david/dipping_only/6plex/211214_PK6/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "david/dipping_only/6plex/211214_PK6/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "david/dipping_only/6plex/211214_PK6/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "david/dipping_only/6plex/211213_PK5/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "david/dipping_only/6plex/211213_PK5/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "david/dipping_only/6plex/211213_PK5/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "david/dipping_only/6plex/211213_PK5/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "david/dipping_only/6plex/211210_PL4_warped/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "david/dipping_only/6plex/211210_PL4_warped/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "david/dipping_only/6plex/211210_PL3_bumped/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "david/dipping_only/6plex/211210_PL3_bumped/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "david/dipping_only/6plex/211209_PK6/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "david/dipping_only/6plex/211209_PK6/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "david/dipping_only/6plex/211209_PK6/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "david/dipping_only/6plex/211209_PK6/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "david/dipping_only/6plex/211207_PK7/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "david/dipping_only/6plex/211207_PK7/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "david/dipping_only/6plex/211203_PK7/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "david/dipping_only/6plex/211203_PK7/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "david/dipping_only/6plex/211202_PK3/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "david/dipping_only/6plex/211202_PK3/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "david/dipping_only/6plex/211124_PK2/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "david/dipping_only/6plex/211124_PK2/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "david/dipping_only/6plex/211122_DT1/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "david/dipping_only/6plex/211122_DT1/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "david/dipping_only/6plex/211027_DT2/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "david/dipping_only/6plex/211027_DT2/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "david/dipping_only/6plex/211027_DT2/wells100/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "david/dipping_only/6plex/211027_DT2/wells100/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "david/dipping_only/6plex/211026_DT2/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "david/dipping_only/6plex/211026_DT2/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "david/dipping_only/6plex/211026_DT2/wells100/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "david/dipping_only/6plex/211026_DT2/wells100/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "david/dipping_only/6plex/211022_PK5/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "david/dipping_only/6plex/211022_PK5/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "david/dipping_only/6plex/211022_PK5/wells100/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "david/dipping_only/6plex/211022_PK5/wells100/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "david/dipping_only/6plex/211021_PK3/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "david/dipping_only/6plex/211021_PK3/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "david/dipping_only/6plex/211021_PK3/wells100/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "david/dipping_only/6plex/211021_PK3/wells100/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "david/dipping_only/6plex/211009_PK4/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "david/dipping_only/6plex/211009_PK4/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "david/dipping_only/6plex/211009_PK4/wells501/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "david/dipping_only/6plex/211009_PK4/wells501/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "david/dipping_only/6plex/211008_PK4/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "david/dipping_only/6plex/211008_PK4/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "david/dipping_only/6plex/211008_PK4/wells501/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "david/dipping_only/6plex/211008_PK4/wells501/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"];
         
warp_refs = [repmat(30,1,2)...
    repmat(115,1,2)...
    repmat(60,1,2)...
    repmat(1,1,2)...
    repmat(1,1,2)...
    repmat(20,1,2)...
    repmat(18,1,2)...
    repmat(15,1,2)...
    repmat(1,1,2)...
    repmat(10,1,2)...
    repmat(20,1,2)...
    repmat(115,1,2)...
    repmat(22,1,2)...
    repmat(13,1,2)...
    repmat(22,1,2)...
    repmat(115,1,2)...
    repmat(50,1,2)...
    repmat(10,1,2)...
    repmat(13,1,2)...
    repmat(1,1,2)...
    repmat(1,1,2)...
    repmat(61,1,2)...
    repmat(1,1,2)...
    repmat(41,1,2)...
    repmat(100,1,2)...
    repmat(1,1,2)...
    repmat(1,1,2)...
    repmat(37,1,2)...
    repmat(115,1,2)...
    repmat(115,1,2)...
    repmat(115,1,2)...
    repmat(1,1,2)...
    repmat(115,1,2)...
    repmat(1,1,2)...
    repmat(18,1,2)...
    repmat(115,1,2)...
    repmat(18,1,2)...
    repmat(31,1,2)...
    repmat(24,1,2)...
    repmat(55,1,2)...
    repmat(18,1,2)...
    repmat(25,1,2)...
    repmat(60,1,2)...
    repmat(25,1,2)...
    repmat(72,1,2)...
    repmat(55,1,2)]';

warp_bounds = [[226 736 24 474];
         [90 600 31 481];
         [120 630 16 466];
         [169 679 16 466];
         [194 704 26 476];
         [211 721 26 476];
         [200 710 10 460];
         [120 630 15 465];
         [170 680 41 491];
         [75 585 37 487];
         [207 717 51 501];
         [137 647 34 484];
         [275 785 20 470];
         [265 775 20 470];
         [275 785 20 470];
         [285 795 20 470];
         [165 675 49 499];
         [132 642 19 469];
         %[139 649 20 470];
         [125 635 30 480];
         [165 675 35 485];
         [190 700 40 490];
         [258 768 21 471];
         [285 795 22 472];
         [175 685 35 485];
         [160 670 45 495];
         [165 675 20 470];
         [135 645 30 480];
         [225 735 5 455];
         [220 730 5 455];
         [195 705 0 450];
         [140 650 30 480];
         [100 610 45 495];
         [130 640 15 465];
         [120 630 20 470];
         [0 510 10 460];
         [0 510 0 450];
         [50 560 20 470];
         [55 565 30 480];
         [270 780 0 450];
         [275 785 0 450];
         [135 645 15 465];
         [165 675 0 450];
         [195 705 60 510];
         [180 690 60 510];
         [190 700 20 470];
         [190 700 30 480]];
     
%% 5/1/24 example imregdemons on signal vs probmovies
mov_prefix = "//nasquatch/data/2p/";

warp_prefix = "//santiago/2p_data/";

mov_paths = ["peter/in_vivo/231108_DG61PL62/DG61PL62_231108_001_noartifact.sbx"
        "peter/in_vivo/231105_DG39PL32/DG39PL32_231105_001_noartifact.sbx"
        "peter/in_vivo/231025_DG56PL62/DG56PL62_231025_001_noartifact.sbx"];

warp_paths = ["peter/in_vivo/231108_DG61PL62/mouse/segtrack/tiffs/ch0/52_mean__/means_movie_scale4AFS2PL4_dispdemons_toref85.mat"
    "peter/in_vivo/231108_DG61PL62/mouse/segtrack/tiffs/ch0/52_mean__/means_movie_filt_scale4AFS2PL4_dispdemons_toref85.mat"
    "peter/in_vivo/231108_DG61PL62/mouse/segtrack/tiffs/ch0/52_mean__/means_movie_norm_global_scale4AFS2PL4_dispdemons_toref85.mat"
    "peter/in_vivo/231108_DG61PL62/mouse/segtrack/tiffs/ch0/52_mean__/means_movie_filt_norm_global_scale4AFS2PL4_dispdemons_toref85.mat"
    "peter/in_vivo/231108_DG61PL62/mouse/segtrack/tiffs/ch0/52_mean__/means_movie_norm_local_scale_scale4AFS2PL4_dispdemons_toref85.mat"
    "peter/in_vivo/231108_DG61PL62/mouse/segtrack/tiffs/ch0/52_mean__/means_movie_norm_local_df_filt_global_scale4AFS2PL4_dispdemons_toref85.mat"
    "peter/in_vivo/231108_DG61PL62/mouse/segtrack/tiffs/ch0/52_mean__/means_movie_filt_norm_local_scale4AFS2PL4_dispdemons_toref85.mat"
    "peter/in_vivo/231108_DG61PL62/mouse/segtrack/tiffs/ch0/52_mean__/means_movie_filt_norm_local_df_global_scale4AFS2PL4_dispdemons_toref85.mat"
    "peter/in_vivo/231108_DG61PL62/mouse/segtrack/tiffs/ch0/52_mean__/means_movie_norm_local_scale4AFS2PL4_dispdemons_toref85.mat"
    "peter/in_vivo/231108_DG61PL62/mouse/segtrack/tiffs/ch0/52_mean__/means_movie_norm_local_df_global_scale4AFS2PL4_dispdemons_toref85.mat"
    "peter/in_vivo/231108_DG61PL62/mouse/segtrack/tiffs/ch1/52_mean__/means_movie_scale4AFS2PL4_dispdemons_toref85.mat"
    "peter/in_vivo/231108_DG61PL62/mouse/segtrack/tiffs/ch1/52_mean__/means_movie_filt_scale4AFS2PL4_dispdemons_toref85.mat"
    "peter/in_vivo/231108_DG61PL62/mouse/segtrack/tiffs/ch1/52_mean__/means_movie_norm_global_scale4AFS2PL4_dispdemons_toref85.mat"
    "peter/in_vivo/231108_DG61PL62/mouse/segtrack/tiffs/ch1/52_mean__/means_movie_filt_norm_global_scale4AFS2PL4_dispdemons_toref85.mat"
    "peter/in_vivo/231108_DG61PL62/mouse/segtrack/tiffs/ch1/52_mean__/means_movie_norm_local_scale_scale4AFS2PL4_dispdemons_toref85.mat"
    "peter/in_vivo/231108_DG61PL62/mouse/segtrack/tiffs/ch1/52_mean__/means_movie_norm_local_df_filt_global_scale4AFS2PL4_dispdemons_toref85.mat"
    "peter/in_vivo/231108_DG61PL62/mouse/segtrack/tiffs/ch1/52_mean__/means_movie_filt_norm_local_scale4AFS2PL4_dispdemons_toref85.mat"
    "peter/in_vivo/231108_DG61PL62/mouse/segtrack/tiffs/ch1/52_mean__/means_movie_filt_norm_local_df_global_scale4AFS2PL4_dispdemons_toref85.mat"
    "peter/in_vivo/231108_DG61PL62/mouse/segtrack/tiffs/ch1/52_mean__/means_movie_norm_local_scale4AFS2PL4_dispdemons_toref85.mat"
    "peter/in_vivo/231108_DG61PL62/mouse/segtrack/tiffs/ch1/52_mean__/means_movie_norm_local_df_global_scale4AFS2PL4_dispdemons_toref85.mat"
    "peter/in_vivo/231105_DG39PL32/mouse/segtrack/tiffs/ch0/52_mean__/means_movie_scale4AFS2PL4_dispdemons_toref85.mat"
    "peter/in_vivo/231105_DG39PL32/mouse/segtrack/tiffs/ch0/52_mean__/means_movie_filt_scale4AFS2PL4_dispdemons_toref85.mat"
    "peter/in_vivo/231105_DG39PL32/mouse/segtrack/tiffs/ch0/52_mean__/means_movie_norm_global_scale4AFS2PL4_dispdemons_toref85.mat"
    "peter/in_vivo/231105_DG39PL32/mouse/segtrack/tiffs/ch0/52_mean__/means_movie_filt_norm_global_scale4AFS2PL4_dispdemons_toref85.mat"
    "peter/in_vivo/231105_DG39PL32/mouse/segtrack/tiffs/ch0/52_mean__/means_movie_norm_local_scale_scale4AFS2PL4_dispdemons_toref85.mat"
    "peter/in_vivo/231105_DG39PL32/mouse/segtrack/tiffs/ch0/52_mean__/means_movie_norm_local_df_filt_global_scale4AFS2PL4_dispdemons_toref85.mat"
    "peter/in_vivo/231105_DG39PL32/mouse/segtrack/tiffs/ch0/52_mean__/means_movie_filt_norm_local_scale4AFS2PL4_dispdemons_toref85.mat"
    "peter/in_vivo/231105_DG39PL32/mouse/segtrack/tiffs/ch0/52_mean__/means_movie_filt_norm_local_df_global_scale4AFS2PL4_dispdemons_toref85.mat"
    "peter/in_vivo/231105_DG39PL32/mouse/segtrack/tiffs/ch0/52_mean__/means_movie_norm_local_scale4AFS2PL4_dispdemons_toref85.mat"
    "peter/in_vivo/231105_DG39PL32/mouse/segtrack/tiffs/ch0/52_mean__/means_movie_norm_local_df_global_scale4AFS2PL4_dispdemons_toref85.mat"
    "peter/in_vivo/231105_DG39PL32/mouse/segtrack/tiffs/ch1/52_mean__/means_movie_scale4AFS2PL4_dispdemons_toref85.mat"
    "peter/in_vivo/231105_DG39PL32/mouse/segtrack/tiffs/ch1/52_mean__/means_movie_filt_scale4AFS2PL4_dispdemons_toref85.mat"
    "peter/in_vivo/231105_DG39PL32/mouse/segtrack/tiffs/ch1/52_mean__/means_movie_norm_global_scale4AFS2PL4_dispdemons_toref85.mat"
    "peter/in_vivo/231105_DG39PL32/mouse/segtrack/tiffs/ch1/52_mean__/means_movie_filt_norm_global_scale4AFS2PL4_dispdemons_toref85.mat"
    "peter/in_vivo/231105_DG39PL32/mouse/segtrack/tiffs/ch1/52_mean__/means_movie_norm_local_scale_scale4AFS2PL4_dispdemons_toref85.mat"
    "peter/in_vivo/231105_DG39PL32/mouse/segtrack/tiffs/ch1/52_mean__/means_movie_norm_local_df_filt_global_scale4AFS2PL4_dispdemons_toref85.mat"
    "peter/in_vivo/231105_DG39PL32/mouse/segtrack/tiffs/ch1/52_mean__/means_movie_filt_norm_local_scale4AFS2PL4_dispdemons_toref85.mat"
    "peter/in_vivo/231105_DG39PL32/mouse/segtrack/tiffs/ch1/52_mean__/means_movie_filt_norm_local_df_global_scale4AFS2PL4_dispdemons_toref85.mat"
    "peter/in_vivo/231105_DG39PL32/mouse/segtrack/tiffs/ch1/52_mean__/means_movie_norm_local_scale4AFS2PL4_dispdemons_toref85.mat"
    "peter/in_vivo/231105_DG39PL32/mouse/segtrack/tiffs/ch1/52_mean__/means_movie_norm_local_df_global_scale4AFS2PL4_dispdemons_toref85.mat"
    "peter/in_vivo/231025_DG56PL62/mouse/segtrack/tiffs/ch0/52_mean__/means_movie_scale4AFS2PL4_dispdemons_toref85.mat"
    "peter/in_vivo/231025_DG56PL62/mouse/segtrack/tiffs/ch0/52_mean__/means_movie_filt_scale4AFS2PL4_dispdemons_toref85.mat"
    "peter/in_vivo/231025_DG56PL62/mouse/segtrack/tiffs/ch0/52_mean__/means_movie_norm_global_scale4AFS2PL4_dispdemons_toref85.mat"
    "peter/in_vivo/231025_DG56PL62/mouse/segtrack/tiffs/ch0/52_mean__/means_movie_filt_norm_global_scale4AFS2PL4_dispdemons_toref85.mat"
    "peter/in_vivo/231025_DG56PL62/mouse/segtrack/tiffs/ch0/52_mean__/means_movie_norm_local_scale_scale4AFS2PL4_dispdemons_toref85.mat"
    "peter/in_vivo/231025_DG56PL62/mouse/segtrack/tiffs/ch0/52_mean__/means_movie_norm_local_df_filt_global_scale4AFS2PL4_dispdemons_toref85.mat"
    "peter/in_vivo/231025_DG56PL62/mouse/segtrack/tiffs/ch0/52_mean__/means_movie_filt_norm_local_scale4AFS2PL4_dispdemons_toref85.mat"
    "peter/in_vivo/231025_DG56PL62/mouse/segtrack/tiffs/ch0/52_mean__/means_movie_filt_norm_local_df_global_scale4AFS2PL4_dispdemons_toref85.mat"
    "peter/in_vivo/231025_DG56PL62/mouse/segtrack/tiffs/ch0/52_mean__/means_movie_norm_local_scale4AFS2PL4_dispdemons_toref85.mat"
    "peter/in_vivo/231025_DG56PL62/mouse/segtrack/tiffs/ch0/52_mean__/means_movie_norm_local_df_global_scale4AFS2PL4_dispdemons_toref85.mat"
    "peter/in_vivo/231025_DG56PL62/mouse/segtrack/tiffs/ch1/52_mean__/means_movie_scale4AFS2PL4_dispdemons_toref85.mat"
    "peter/in_vivo/231025_DG56PL62/mouse/segtrack/tiffs/ch1/52_mean__/means_movie_filt_scale4AFS2PL4_dispdemons_toref85.mat"
    "peter/in_vivo/231025_DG56PL62/mouse/segtrack/tiffs/ch1/52_mean__/means_movie_norm_global_scale4AFS2PL4_dispdemons_toref85.mat"
    "peter/in_vivo/231025_DG56PL62/mouse/segtrack/tiffs/ch1/52_mean__/means_movie_filt_norm_global_scale4AFS2PL4_dispdemons_toref85.mat"
    "peter/in_vivo/231025_DG56PL62/mouse/segtrack/tiffs/ch1/52_mean__/means_movie_norm_local_scale_scale4AFS2PL4_dispdemons_toref85.mat"
    "peter/in_vivo/231025_DG56PL62/mouse/segtrack/tiffs/ch1/52_mean__/means_movie_norm_local_df_filt_global_scale4AFS2PL4_dispdemons_toref85.mat"
    "peter/in_vivo/231025_DG56PL62/mouse/segtrack/tiffs/ch1/52_mean__/means_movie_filt_norm_local_scale4AFS2PL4_dispdemons_toref85.mat"
    "peter/in_vivo/231025_DG56PL62/mouse/segtrack/tiffs/ch1/52_mean__/means_movie_filt_norm_local_df_global_scale4AFS2PL4_dispdemons_toref85.mat"
    "peter/in_vivo/231025_DG56PL62/mouse/segtrack/tiffs/ch1/52_mean__/means_movie_norm_local_scale4AFS2PL4_dispdemons_toref85.mat"
    "peter/in_vivo/231025_DG56PL62/mouse/segtrack/tiffs/ch1/52_mean__/means_movie_norm_local_df_global_scale4AFS2PL4_dispdemons_toref85.mat"];

warp_refs = [repmat(85,1,20)...
    repmat(85,1,20)...
    repmat(85,1,20)]';

%% 240511 fixing a couple mistakes

mov_prefix = "//nasquatch/data/2p/";

warp_prefix = "//santiago/2p_data/";

mov_paths = ["peter/in_vivo/220408_PK27PL20/PK27PL20_220408_101_full.sbx"
    %"peter/slice/20230824_SL1PL60/PL60_230824_001_full.sbx"
    "peter/slice/20230824_SL1PL60/PL60_230824_001_full.sbx"];

warp_dirs = ["peter/in_vivo/220408_PK27PL20/wells101/segtrack/segs/ch0/52_mean__fix/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
    "peter/slice/20230824_SL1PL60/wells001/segtrack/segs/ch0/52_mean__fix/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
    "peter/slice/20230824_SL1PL60/wells001/segtrack/segs/ch1/52_mean__fix/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"];

warp_refs = [57
    18
    18]';

warp_bounds = [[243 753 48 498];
         %[145 655 15 465]
         [145 655 15 465]];

%% 241206 warp test movies

mov_prefix = "//nasquatch/data/2p/";

warp_prefix = "//santiago/2p_data/";

mov_paths = ["211103_PZ1/chunks/PZ1_211103_well1_merge.sbx"
        "211103_PZ1/chunks/PZ1_211103_well2_merge.sbx"
        "211103_PZ1/chunks/PZ1_211103_well3_merge.sbx"
        "211103_PZ1/chunks/PZ1_211103_well4_merge.sbx"
        "211103_PZ1/chunks/PZ1_211103_well5_merge.sbx"
        "211103_PZ1/chunks/PZ1_211103_well6_merge.sbx"
        "211104_PZ1/chunks/PZ1_211104_well1_merge.sbx"
        "211104_PZ1/chunks/PZ1_211104_well2_merge.sbx"
        "211104_PZ1/chunks/PZ1_211104_well3_merge.sbx"
        "211104_PZ1/chunks/PZ1_211104_well4_merge.sbx"
        "211104_PZ1/chunks/PZ1_211104_well5_merge.sbx"
        "211104_PZ1/chunks/PZ1_211104_well6_merge.sbx"
        "211109_PZ1/chunks/PZ1_211109_well1_merge.sbx"
        "211109_PZ1/chunks/PZ1_211109_well2_merge.sbx"
        "211109_PZ1/chunks/PZ1_211109_well3_merge.sbx"
        "211109_PZ1/chunks/PZ1_211109_well4_merge.sbx"
        "211109_PZ1/chunks/PZ1_211109_well5_merge.sbx"
        "211109_PZ1/chunks/PZ1_211109_well6_merge.sbx"
        "211110_PZ1/chunks/PZ1_211110_well1_merge.sbx"
        "211110_PZ1/chunks/PZ1_211110_well2_merge.sbx"
        "211110_PZ1/chunks/PZ1_211110_well3_merge.sbx"
        "211110_PZ1/chunks/PZ1_211110_well4_merge.sbx"
        "211110_PZ1/chunks/PZ1_211110_well5_merge.sbx"
        "211110_PZ1/chunks/PZ1_211110_well6_merge.sbx"
        "211111_PZ1/chunks/PZ1_211111_well1_merge.sbx"
        "211111_PZ1/chunks/PZ1_211111_well2_merge.sbx"
        "211111_PZ1/chunks/PZ1_211111_well3_merge.sbx"
        "211111_PZ1/chunks/PZ1_211111_well4_merge.sbx"
        "211111_PZ1/chunks/PZ1_211111_well5_merge.sbx"
        "211111_PZ1/chunks/PZ1_211111_well6_merge.sbx"
        "211112_PZ1/chunks/PZ1_211112_well1_merge.sbx"
        "211112_PZ1/chunks/PZ1_211112_well2_merge.sbx"
        "211112_PZ1/chunks/PZ1_211112_well3_merge.sbx"
        "211112_PZ1/chunks/PZ1_211112_well4_merge.sbx"
        "211112_PZ1/chunks/PZ1_211112_well5_merge.sbx"
        "211112_PZ1/chunks/PZ1_211112_well6_merge.sbx"
        "211121_PZ1/chunks/PZ1_211121_well1_merge.sbx"
        "211121_PZ1/chunks/PZ1_211121_well2_merge.sbx"
        "211121_PZ1/chunks/PZ1_211121_well3_merge.sbx"
        "211121_PZ1/chunks/PZ1_211121_well4_merge.sbx"
        "211121_PZ1/chunks/PZ1_211121_well5_merge.sbx"
        "211121_PZ1/chunks/PZ1_211121_well6_merge.sbx"
        "211121_PZ1/chunks/PZ1_211121_well7_merge.sbx"
        "211121_PZ1/chunks/PZ1_211121_well8_merge.sbx"
        "211121_PZ1/chunks/PZ1_211121_well9_merge.sbx"
        %"211123_PZ1/chunks/PZ1_211123_well1_merge.sbx"
        "211123_PZ1/chunks/PZ1_211123_well2_merge.sbx"
        "211123_PZ1/chunks/PZ1_211123_well3_merge.sbx"
        "211123_PZ1/chunks/PZ1_211123_well4_merge.sbx"
        "211123_PZ1/chunks/PZ1_211123_well5_merge.sbx"
        "211123_PZ1/chunks/PZ1_211123_well6_merge.sbx"
        "211123_PZ1/chunks/PZ1_211123_well7_merge.sbx"
        "211123_PZ1/chunks/PZ1_211123_well8_merge.sbx"
        "211123_PZ1/chunks/PZ1_211123_well9_merge.sbx"];

warp_dirs = ["peter/chip_tiling/211103_PZ1/chunks/well1/segtrack/segs/ch0/10_mean__fix/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
        "peter/chip_tiling/211103_PZ1/chunks/well2/segtrack/segs/ch0/10_mean__fix/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
        "peter/chip_tiling/211103_PZ1/chunks/well3/segtrack/segs/ch0/10_mean__fix/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
        "peter/chip_tiling/211103_PZ1/chunks/well4/segtrack/segs/ch0/10_mean__fix/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
        "peter/chip_tiling/211103_PZ1/chunks/well5/segtrack/segs/ch0/10_mean__fix/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
        "peter/chip_tiling/211103_PZ1/chunks/well6/segtrack/segs/ch0/10_mean__fix/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
        "peter/chip_tiling/211104_PZ1/chunks/well1/segtrack/segs/ch0/10_mean__fix/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
        "peter/chip_tiling/211104_PZ1/chunks/well2/segtrack/segs/ch0/10_mean__fix/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
        "peter/chip_tiling/211104_PZ1/chunks/well3/segtrack/segs/ch0/10_mean__fix/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
        "peter/chip_tiling/211104_PZ1/chunks/well4/segtrack/segs/ch0/10_mean__fix/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
        "peter/chip_tiling/211104_PZ1/chunks/well5/segtrack/segs/ch0/10_mean__fix/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
        "peter/chip_tiling/211104_PZ1/chunks/well6/segtrack/segs/ch0/10_mean__fix/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
        "peter/chip_tiling/211109_PZ1/chunks/well1/segtrack/segs/ch0/10_mean__fix/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
        "peter/chip_tiling/211109_PZ1/chunks/well2/segtrack/segs/ch0/10_mean__fix/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
        "peter/chip_tiling/211109_PZ1/chunks/well3/segtrack/segs/ch0/10_mean__fix/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
        "peter/chip_tiling/211109_PZ1/chunks/well4/segtrack/segs/ch0/10_mean__fix/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
        "peter/chip_tiling/211109_PZ1/chunks/well5/segtrack/segs/ch0/10_mean__fix/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
        "peter/chip_tiling/211109_PZ1/chunks/well6/segtrack/segs/ch0/10_mean__fix/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
        "peter/chip_tiling/211110_PZ1/chunks/well1/segtrack/segs/ch0/10_mean__fix/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
        "peter/chip_tiling/211110_PZ1/chunks/well2/segtrack/segs/ch0/10_mean__fix/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
        "peter/chip_tiling/211110_PZ1/chunks/well3/segtrack/segs/ch0/10_mean__fix/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
        "peter/chip_tiling/211110_PZ1/chunks/well4/segtrack/segs/ch0/10_mean__fix/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
        "peter/chip_tiling/211110_PZ1/chunks/well5/segtrack/segs/ch0/10_mean__fix/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
        "peter/chip_tiling/211110_PZ1/chunks/well6/segtrack/segs/ch0/10_mean__fix/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
        "peter/chip_tiling/211111_PZ1/chunks/well1/segtrack/segs/ch0/10_mean__fix/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
        "peter/chip_tiling/211111_PZ1/chunks/well2/segtrack/segs/ch0/10_mean__fix/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
        "peter/chip_tiling/211111_PZ1/chunks/well3/segtrack/segs/ch0/10_mean__fix/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
        "peter/chip_tiling/211111_PZ1/chunks/well4/segtrack/segs/ch0/10_mean__fix/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
        "peter/chip_tiling/211111_PZ1/chunks/well5/segtrack/segs/ch0/10_mean__fix/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
        "peter/chip_tiling/211111_PZ1/chunks/well6/segtrack/segs/ch0/10_mean__fix/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
        "peter/chip_tiling/211112_PZ1/chunks/well1/segtrack/segs/ch0/10_mean__fix/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
        "peter/chip_tiling/211112_PZ1/chunks/well2/segtrack/segs/ch0/10_mean__fix/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
        "peter/chip_tiling/211112_PZ1/chunks/well3/segtrack/segs/ch0/10_mean__fix/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
        "peter/chip_tiling/211112_PZ1/chunks/well4/segtrack/segs/ch0/10_mean__fix/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
        "peter/chip_tiling/211112_PZ1/chunks/well5/segtrack/segs/ch0/10_mean__fix/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
        "peter/chip_tiling/211112_PZ1/chunks/well6/segtrack/segs/ch0/10_mean__fix/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
        "peter/chip_tiling/211121_PZ1/chunks/well1/segtrack/segs/ch0/10_mean__fix/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
        "peter/chip_tiling/211121_PZ1/chunks/well2/segtrack/segs/ch0/10_mean__fix/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
        "peter/chip_tiling/211121_PZ1/chunks/well3/segtrack/segs/ch0/10_mean__fix/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
        "peter/chip_tiling/211121_PZ1/chunks/well4/segtrack/segs/ch0/10_mean__fix/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
        "peter/chip_tiling/211121_PZ1/chunks/well5/segtrack/segs/ch0/10_mean__fix/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
        "peter/chip_tiling/211121_PZ1/chunks/well6/segtrack/segs/ch0/10_mean__fix/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
        "peter/chip_tiling/211121_PZ1/chunks/well7/segtrack/segs/ch0/10_mean__fix/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
        "peter/chip_tiling/211121_PZ1/chunks/well8/segtrack/segs/ch0/10_mean__fix/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
        "peter/chip_tiling/211121_PZ1/chunks/well9/segtrack/segs/ch0/10_mean__fix/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
        %"peter/chip_tiling/211123_PZ1/chunks/well1/segtrack/segs/ch0/10_mean__fix/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
        "peter/chip_tiling/211123_PZ1/chunks/well2/segtrack/segs/ch0/10_mean__fix/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
        "peter/chip_tiling/211123_PZ1/chunks/well3/segtrack/segs/ch0/10_mean__fix/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
        "peter/chip_tiling/211123_PZ1/chunks/well4/segtrack/segs/ch0/10_mean__fix/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
        "peter/chip_tiling/211123_PZ1/chunks/well5/segtrack/segs/ch0/10_mean__fix/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
        "peter/chip_tiling/211123_PZ1/chunks/well6/segtrack/segs/ch0/10_mean__fix/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
        "peter/chip_tiling/211123_PZ1/chunks/well7/segtrack/segs/ch0/10_mean__fix/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
        "peter/chip_tiling/211123_PZ1/chunks/well8/segtrack/segs/ch0/10_mean__fix/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
        "peter/chip_tiling/211123_PZ1/chunks/well9/segtrack/segs/ch0/10_mean__fix/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"];
     
warp_refs = [repmat(1,1,53)]';%54

warp_bounds = [[0 796 0 512];
    [0 796 0 512];
    [0 796 0 512];
    [0 796 0 512];
    [0 796 0 512];
    [0 796 0 512];
    [0 796 0 512];
    [0 796 0 512];
    [0 796 0 512];
    [0 796 0 512];
    [0 796 0 512];
    [0 796 0 512];
    [0 796 0 512];
    [0 796 0 512];
    [0 796 0 512];
    [0 796 0 512];
    [0 796 0 512];
    [0 796 0 512];
    [0 796 0 512];
    [0 796 0 512];
    [0 796 0 512];
    [0 796 0 512];
    [0 796 0 512];
    [0 796 0 512];
    [0 796 0 512];
    [0 796 0 512];
    [0 796 0 512];
    [0 796 0 512];
    [0 796 0 512];
    [0 796 0 512];
    [0 796 0 512];
    [0 796 0 512];
    [0 796 0 512];
    [0 796 0 512];
    [0 796 0 512];
    [0 796 0 512];
    [0 796 0 512];
    [0 796 0 512];
    [0 796 0 512];
    [0 796 0 512];
    [0 796 0 512];
    [0 796 0 512];
    [0 796 0 512];
    [0 796 0 512];
    [0 796 0 512];
    [0 796 0 512];
    [0 796 0 512];
    [0 796 0 512];
    [0 796 0 512];
    [0 796 0 512];
    [0 796 0 512];
    [0 796 0 512];
    [0 796 0 512]];


%% filtering input directories to generate warps of interest
% warp_refs and warp_dirs match in dimension - these come in either groups
% of 2 or 4 per movie depending on whether ch0 only or ch0+1 were used for
% warp calculations
% mov_paths and warp_bounds are one per movie
% could use path stems and folder names to match mov_paths to warp_dirs,
% but keep in mind that conventions slightly changed (e.g. wells vs
% wellsXXX vs washes) - good to double check outputs by eye every batch!

% KEEP IN MIND THAT ANASTASIA HAS EXTRA FOLDERS!

useGPU = false; % set to true to use GPU for warping (if the computer is GPU capable)
if isunix
    useGPU = true; %colab00 only
end
aniso = [4]; % aniso(s) from which to take warps - probably do one at a time/just stick with a single one since this makes little difference
wchs = [0 1]; % channel(s) from which to take warps - probably just use all channels that were calculated (both with tdTomato, just ch0 for not)
wkeep = false(size(warp_dirs,1),1);
for i = 1:size(warp_dirs,1)
    warp_dir = char(strcat(warp_prefix,warp_dirs(i)));
    wkeep(i) = ismember(str2double(extractBetween(warp_dir,strfind(warp_dir,'_aniso')+6,strfind(warp_dir,'_st')-1)),aniso)*ismember(str2double(warp_dir(strfind(warp_dir,'s/ch')+4)),wchs);
end
warp_dirs = warp_dirs(wkeep);
warp_refs = warp_refs(wkeep);
keep_chans = [1 2]; % channel(s) to warp and keep in output - consider keeping just green for movies without tdTomato
if useGPU == true
    D = gpuDevice;
    reset(D);
end

%% mean movie warp loop

J = parfor_progressbar(size(warp_dirs,1),'Mean movie warps progress');
for p = 1:size(warp_dirs,1)
    tic
    
    % get a bunch of metadata from directory
    warp_dir = char(strcat(warp_prefix,warp_dirs(p)));
    warp_ref = warp_refs(p);
    d = ls(warp_dir);
    warp_file = d((contains(string(d),'ref') & ~contains(string(d),'xydft')),:);
    warp_path = [warp_dir '/' warp_file];
    warp_scale = str2double(extractBetween(warp_file,strfind(warp_file,'scale')+5,strfind(warp_file,'AFS')-1));
    warp_chan = str2double(warp_dir(strfind(warp_dir,'/ch')+3));
    warp_aniso = str2double(extractBetween(warp_dir,strfind(warp_dir,'_aniso')+6,strfind(warp_dir,'_st')-1));
    warp_meta = char(extractBetween(warp_file,strfind(warp_file,'_s'),strfind(warp_file,'_d')));
    mov_means = str2double(extractBetween(warp_dir,strfind(warp_dir,'_mean')-2,strfind(warp_dir,'_mean')-1));
    
    % figure out mean movie location(s) from provided warp directory
    mean_dir = [char(fileparts(fileparts(fileparts(fileparts(fileparts(strcat(mov_prefix,warp_dirs(p)))))))) '/tiffs'];
    dl = ls(mean_dir);
    dd = dir(mean_dir);
    chnum = sum(contains(string(dl),'ch').*[dd.isdir]'); % number of mean channels available, either 1 or 2 (ch0 is green, ch1 is red)
    save_path = [mean_dir '/alignedmeans_wch' num2str(warp_chan) '_aniso' num2str(warp_aniso) warp_meta 'toref' num2str(warp_ref) '.npy'];
    save_path2 = [mean_dir '/alignedmeans_wch' num2str(warp_chan) '_aniso' num2str(warp_aniso) warp_meta 'toref' num2str(warp_ref) '_transonly.npy'];
    
    % load in mean movie(s)
    mean_mov = readNPY([mean_dir '/ch0/' num2str(mov_means) '_mean__fix/means_movie.npy']);
    mean_mov = permute(mean_mov,[5,3,4,2,1]);
    %if chnum == 2
    %    mean_mov2 = readNPY([mean_dir '/ch1/' num2str(mov_means) '_mean__fix/means_movie.npy']);
    %    mean_mov(2,:,:,:,:) = permute(mean_mov2,[3,4,2,1]);
    %end
    
    % load in and upsample displacements
    load(warp_path);
    dispsdemup = zeros([size(mean_mov,2) size(mean_mov,3) size(mean_mov,4) min(size(mean_mov,5),size(dispsdemref,4)) 3]);
    if useGPU == true
        dispsdemref = gpuArray(dispsdemref);
    end
    H = parfor_progressbar(size(dispsdemup,4),'Upsampling displacements');
    for t = 1:size(dispsdemup,4)
        for z = 1:size(dispsdemup,3)
            dispsdemup(:,:,z,t,1) = warp_scale*imresize(squeeze(dispsdemref(:,:,z,t,1)),[size(dispsdemup,1),size(dispsdemup,2)],'bilinear');
            dispsdemup(:,:,z,t,2) = warp_scale*imresize(squeeze(dispsdemref(:,:,z,t,2)),[size(dispsdemup,1),size(dispsdemup,2)],'bilinear');
            dispsdemup(:,:,z,t,3) = imresize(squeeze(dispsdemref(:,:,z,t,3)),[size(dispsdemup,1),size(dispsdemup,2)],'bilinear');
        end
        H.iterate(1);
    end
    close(H);
    if useGPU == true
        reset(D);
    end
    
    % apply warp to mean movie
    warped_mov = zeros(size(mean_mov));
    H = parfor_progressbar(size(mean_mov,1)*min(size(mean_mov,5),size(dispsdemref,4)),'Warping movie');
    for ch = intersect(1:size(mean_mov,1),keep_chans)
        mean_mov_ch = squeeze(mean_mov(ch,:,:,:,:));
        if useGPU == true
            mean_mov_ch = gpuArray(mean_mov_ch); % full mean_mov with both colors won't fit on Quadro GPU, only on colabs
        end
        for t = 1:min(size(mean_mov,5),size(dispsdemref,4))
            warped_mov(ch,:,:,:,t) = imwarp(squeeze(mean_mov_ch(:,:,:,t)),squeeze(dispsdemup(:,:,:,t,:)));
            H.iterate(1);
        end
        if useGPU == true
            reset(D);
        end
    end
    close(H);
    
    % save movie as NPY
    warped_mov = cast(warped_mov,'single');
    movout = permute(warped_mov,[1 5 4 2 3]); %permute axes to be TZYX from original YXZT to match upstream .npy movies/satisfy napari; for two color, Fiji tiffs become TZCYX, but for easy color splitting in napari, make it CTZYX!
    writeNPY(movout,save_path);
    
    
    % now redo this but for simple translation version (mean of disps)
    dispsdemref2 = zeros(size(dispsdemref));
    for z = 1:size(dispsdemref,4)
        disptempm = mean(reshape(dispsdemref(:,:,:,z,:),[],3));
        dispsdemref2(:,:,:,z,1) = disptempm(1);
        dispsdemref2(:,:,:,z,2) = disptempm(2);
        dispsdemref2(:,:,:,z,3) = disptempm(3);
    end
    
    dispsdemup2 = zeros([size(mean_mov,2) size(mean_mov,3) size(mean_mov,4) min(size(mean_mov,5),size(dispsdemref2,4)) 3]);
    if useGPU == true
        dispsdemref2 = gpuArray(dispsdemref2);
    end
    H = parfor_progressbar(size(dispsdemup2,4),'Upsampling displacements');
    for t = 1:size(dispsdemup2,4)
        for z = 1:size(dispsdemup2,3)
            dispsdemup2(:,:,z,t,1) = warp_scale*imresize(squeeze(dispsdemref2(:,:,z,t,1)),[size(dispsdemup2,1),size(dispsdemup2,2)],'bilinear');
            dispsdemup2(:,:,z,t,2) = warp_scale*imresize(squeeze(dispsdemref2(:,:,z,t,2)),[size(dispsdemup2,1),size(dispsdemup2,2)],'bilinear');
            dispsdemup2(:,:,z,t,3) = imresize(squeeze(dispsdemref2(:,:,z,t,3)),[size(dispsdemup2,1),size(dispsdemup2,2)],'bilinear');
        end
        H.iterate(1);
    end
    close(H);
    if useGPU == true
        reset(D);
    end
    
    % apply warp to mean movie
    warped_mov2 = zeros(size(mean_mov));
    H = parfor_progressbar(size(mean_mov,1)*min(size(mean_mov,5),size(dispsdemref2,4)),'Warping movie');
    for ch = intersect(1:size(mean_mov,1),keep_chans)
        mean_mov_ch = squeeze(mean_mov(ch,:,:,:,:));
        if useGPU == true
            mean_mov_ch = gpuArray(mean_mov_ch); % full mean_mov with both colors won't fit on Quadro GPU, only on colabs
        end
        for t = 1:min(size(mean_mov,5),size(dispsdemref2,4))
            warped_mov2(ch,:,:,:,t) = imwarp(squeeze(mean_mov_ch(:,:,:,t)),squeeze(dispsdemup2(:,:,:,t,:)));
            H.iterate(1);
        end
        if useGPU == true
            reset(D);
        end
    end
    close(H);
    
    % save movie as NPY
    warped_mov2 = cast(warped_mov2,'single');
    movout2 = permute(warped_mov2,[1 5 4 2 3]); %permute axes to be TZYX from original YXZT to match upstream .npy movies/satisfy napari; for two color, Fiji tiffs become TZCYX, but for easy color splitting in napari, make it CTZYX!
    writeNPY(movout2,save_path2);
    
    
    J.iterate(1);
    toc
end
close(J);

%% full-length warp loop
% figure out warp folder name matching original sbx movie path
warp_mov_refs = zeros(size(warp_dirs));
for i = 1:size(warp_dirs,1)
    filepts = split(warp_dirs(i),'/');
    matched_movs = mov_paths(contains(mov_paths,filepts(end-7)));
    if strcmp(filepts(end-6),"mouse")
        matched_mov = matched_movs(contains(matched_movs,'_noartifact'));
    elseif strcmp(filepts(end-6),"mouse2")
        matched_mov = matched_movs(contains(matched_movs,'_002'));
    elseif strcmp(filepts(end-6),"mouse_noart")
        matched_mov = matched_movs(contains(matched_movs,'_noartifact'));
    elseif strcmp(filepts(end-6),"slice")
        matched_mov = matched_movs(contains(matched_movs,'/SL') | contains(matched_movs,'/xx') | contains(matched_movs,'/DA'));
    elseif strcmp(filepts(end-6),"wells")
        matched_mov = matched_movs(contains(matched_movs,'_full'));
    elseif strcmp(filepts(end-6),"washes")
        matched_mov = matched_movs(~contains(matched_movs,'/SL'));
    elseif strcmp(filepts(end-6),"wells001")
        matched_mov = matched_movs(contains(matched_movs,'001_full'));
    elseif strcmp(filepts(end-6),"wells101")
        matched_mov = matched_movs(contains(matched_movs,'101_full'));
    elseif strcmp(filepts(end-6),"wells201")
        matched_mov = matched_movs(contains(matched_movs,'201_full'));
    elseif strcmp(filepts(end-6),"wells301")
        matched_mov = matched_movs(contains(matched_movs,'301_full'));
    elseif strcmp(filepts(end-6),"wells401")
        matched_mov = matched_movs(contains(matched_movs,'401_full'));
    elseif strcmp(filepts(end-6),"wells501")
        matched_mov = matched_movs(contains(matched_movs,'501_full'));
    elseif strcmp(filepts(end-6),"wells601")
        matched_mov = matched_movs(contains(matched_movs,'601_full'));
    elseif strcmp(filepts(end-6),"wells701")
        matched_mov = matched_movs(contains(matched_movs,'701_full'));
    elseif strcmp(filepts(end-6),"wells100")
        matched_mov = matched_movs(contains(matched_movs,'100_full'));
    else
        disp(['Unknown folder ' char(filepts(end-6))]);
        break;
    end
    if isempty(matched_mov)
        disp(['Couldnt match ' char(warp_dirs(i))]);
        break;
    else
        warp_mov_refs(i) = find(contains(mov_paths,matched_mov));
    end
end

%basic parameters for all movies in batch
otlevels = 30; % should always be 30
chunkMeans = 10; % how many of the mean frames to use per chunk, use 5 on colab00 GPU
if isunix
    chunkMeans = 5;
end
filext = '.sbx';

J = parfor_progressbar(size(warp_dirs,1),'Full-length movie warps progress');
for p = 1:size(warp_dirs,1)
    %figure out relevant paths and metadata for original movie and given reference warp
    mov_path = char(strcat(mov_prefix,mov_paths(warp_mov_refs(p))));
    warp_dir = char(strcat(warp_prefix,warp_dirs(p)));
    warp_bound = warp_bounds(warp_mov_refs(p),:);
    warp_ref = warp_refs(p);
    d = ls(warp_dir);
    if isunix
        d = char(strsplit(d)); %add on linux only!
    end
    warp_file = d(contains(string(d),'ref'),:);
    warp_path = [warp_dir '/' warp_file];
    warp_scale = str2double(extractBetween(warp_file,strfind(warp_file,'scale')+5,strfind(warp_file,'AFS')-1));
    warp_chan = str2double(warp_dir(strfind(warp_dir,'/ch')+3));
    warp_aniso = str2double(extractBetween(warp_dir,strfind(warp_dir,'_aniso')+6,strfind(warp_dir,'_st')-1));
    mov_means = str2double(extractBetween(warp_dir,strfind(warp_dir,'_mean')-2,strfind(warp_dir,'_mean')-1));
    warp_meta = char(extractBetween(warp_file,strfind(warp_file,'_s'),strfind(warp_file,'_d')));
    
    %load in original movie metadata and prepare output file stem
    meta1 = strsplit(mov_path,'.');
    tempa1 = pipe.io.read_sbx(mov_path,1,30,-1,[]); %broke on linux due to read_sbxinfo \ vs / in line 28
    info1 = pipe.io.read_sbxinfo([meta1{1} '.mat']);
    %[~,fnm,~] = fileparts(meta1{1});
    [fdir,fnm,~] = fileparts(mov_path);
    save_path = [fdir '/' fnm '_wch' num2str(warp_chan) '_aniso' num2str(warp_aniso) warp_meta 'toref' num2str(warp_ref) '_wxy.npy'];
    [wdir,wnm,~] = fileparts(warp_path);
    dft_save_path = [wdir '/' wnm '_xydftshifts.mat'];

    %prepare new info file for warped output (deprecated)
    %info = info1;
    
    %sufficient amount of metadata correction to make sbx code happy!
    %but also don't need this at all - just save as NPY!
    width = warp_bound(4)-warp_bound(3);
    height = warp_bound(2)-warp_bound(1);
    %info.sz = [info.width,info.height];
    %info.config.lines = info.width;
    %info.recordsPerBuffer = info.width;
    
    load(warp_path); %30 sec for a big mouse movie (4.5+ hrs), scale 4 (Santiago), 76 sec (old starsky)
    %ADDRESS POTENTIAL BREAKS IN CELLPOSE CUTTING WARP FIELD SHORT - ONLY
    %WARP WHERE CELLPOSE WORKED, CALCULATE INPUT TO LOOP - done

    chunkSize = chunkMeans*mov_means*otlevels; %only tweak chunkMeans here for consistency
    xy_dftshifts = zeros(2,ceil(info1.nframes/otlevels));%CONFIRM DIMENSIONS
    
    %rw = pipe.io.RegWriter(save_stem,info,filext,true,'w'); %open sbx writer for warped movie (deprecated)
    fid = fopen(save_path, 'w');
    %loop across chunks
    H = parfor_progressbar(ceil(min(size(dispsdemref,4),ceil(info1.nframes/(mov_means*otlevels)))/chunkMeans),'Chunks progress');
    for cn = 1:ceil(min(size(dispsdemref,4),ceil(info1.nframes/(mov_means*otlevels)))/chunkMeans)
        tic
        % Load raw movie chunk (warp both colors for mid-Aug/23 onward)
        trangeS = 1 + (cn-1)*chunkSize;
        tempin = pipe.io.read_sbx(mov_path,trangeS,chunkSize,-1,[]); %70-90 sec for 520 volumes on Santiago (~24 GB RAM)
        if ndims(tempin) == 4
            tempin = tempin(:,:,:,1:(size(tempin,4)-mod(size(tempin,4),otlevels)));
            tempin = reshape(tempin,size(tempin,1),size(tempin,2),size(tempin,3),otlevels,[]);
        elseif ndims(tempin) == 3
            tempin = tempin(:,:,1:(size(tempin,3)-mod(size(tempin,3),otlevels)));
            tempin = reshape(tempin,size(tempin,1),size(tempin,2),otlevels,[]);
        else
            disp(['Invalid sbx file ' mov_path]);
        end
        if ndims(tempin) == 5
            temp = zeros(size(tempin,1),width,height,size(tempin,4),size(tempin,5));
            temp = tempin(:,(warp_bound(3)+1):warp_bound(4),(warp_bound(1)+1):warp_bound(2),:,:); %resized movie is ~14 GB RAM
        elseif ndims(tempin) == 4
            temp = zeros(width,height,size(tempin,3),size(tempin,4));
            temp = tempin((warp_bound(3)+1):warp_bound(4),(warp_bound(1)+1):warp_bound(2),:,:); %resized movie is ~14 GB RAM
            temp = permute(temp,[5 1 2 3 4]);
        else
            disp(['Invalid sbx file ' mov_path]);
        end
        %cor = 0;
        %if mod(size(tempin,3),otlevels) ~= 0
        %    cor = 1;
        %end
        clear tempin
        
        % Upsample warp field to match raw movie chunk (imresize3 x,y,t)
        % Here, if the temp movie trange is [1,520]/[521,1040], we will have warp
        % indices [1,10]/[11,20] upsample to [26,494]/[546,1014]ish with
        % erroneous extrapolation outside those ranges - unless overhang
        % indices are included and then trimmed
        if cn == 1
            dtime = (chunkMeans+1)*mov_means;
            dbounds = [1 chunkMeans+1];
            ebounds = [1 dtime-mov_means]; %[1 mov_means/2] extrapolated flat
            sbounds = [1 mov_means*chunkMeans];
        elseif cn == ceil(min(size(dispsdemref,4),ceil(info1.nframes/(mov_means*otlevels)))/chunkMeans)
            dtime = (size(dispsdemref,4)-(cn-1)*chunkMeans+1)*mov_means;
            dbounds = [(cn-1)*chunkMeans size(dispsdemref,4)];
            ebounds = [mov_means+1 min(mov_means+size(temp,5),dtime)]; %[dtime-mov_means/2 end] extrapolated flat
            sbounds = [(cn-1)*mov_means*chunkMeans+1 (cn-1)*mov_means*chunkMeans+size(temp,5)];
        else
            dtime = (chunkMeans+2)*mov_means;
            dbounds = [(cn-1)*chunkMeans cn*chunkMeans+1];
            ebounds = [mov_means+1 dtime-mov_means];
            sbounds = [(cn-1)*mov_means*chunkMeans+1 cn*mov_means*chunkMeans];
        end
       
        dtemp = zeros(width,height,otlevels,(ebounds(2)-ebounds(1)+1),3);
        dtempz = zeros(width,height,dtime,3);
        
        % Here the idea is to take x,y,t displacement fields at each
        % otlevel and interpolate up to raw movie chunk dimensions - one
        % option is to use imresize3 on all three dimensions, and another
        % is to use imresize on x,y (which works on GPU), and separately do
        % the time dimension with more elaborate interpolation control+extrapolation - or
        % find some way to do interpn or related on GPU?
        % interp3 takes 268 sec for 11 means/572 raw timepoints
        K = parfor_progressbar(size(dtemp,3),'Upsampling displacements');
        for z = 1:size(dtemp,3)
            dtempz(:,:,:,1) = warp_scale*imresize3(squeeze(dispsdemref(:,:,z,dbounds(1):dbounds(2),1)),[size(dtempz,1),size(dtempz,2),size(dtempz,3)],'linear');
            dtempz(:,:,:,2) = warp_scale*imresize3(squeeze(dispsdemref(:,:,z,dbounds(1):dbounds(2),2)),[size(dtempz,1),size(dtempz,2),size(dtempz,3)],'linear');
            dtempz(:,:,:,3) = imresize3(squeeze(dispsdemref(:,:,z,dbounds(1):dbounds(2),3)),[size(dtempz,1),size(dtempz,2),size(dtempz,3)],'linear');
            dtemp(:,:,z,:,:) = dtempz(:,:,ebounds(1):ebounds(2),:);
            K.iterate(1);
        end
        close(K);
        
        %dtemp = dtemp(:,:,:,ebounds(1):ebounds(2),:);
        %up to here on Santiago for 520 frame chunk/572 frame disps it
        %takes 410 sec; same on old starsky takes 290 sec! but really
        %hitting tippy top of RAM - upgrade ASAP!
        
        % ndgrid/interpn approach (GPU-able) - seems to take just as long
        % as imresize3, but can be set up to query the exact right values
        % for each timepoint and extrapolate - plus GPU? Quadro barely speeds it up vs CPU!
        % interpn takes 285 sec for 11 means/572 raw timepoints
        % actually looks like it can't extrapolate?? BAD
        %if useGPU == true
        %    dispsdemref = gpuArray(dispsdemref); % GPU can't even do imresize3! so why not stick with normal imresize and separately interpolate in time?! That way the interpolation will be correct vs 0.5 offset!
        %end
        %tic
        %[xi,yi,ti] = ndgrid((size(dtemp,1)/(2*size(dispsdemref,1))):(size(dtemp,1)/size(dispsdemref,1)):(size(dtemp,1)-(size(dtemp,1)/(2*size(dispsdemref,1)))),(size(dtemp,2)/(2*size(dispsdemref,2))):(size(dtemp,2)/size(dispsdemref,2)):(size(dtemp,2)-(size(dtemp,2)/(2*size(dispsdemref,2)))),((dbounds(1)-1)*mov_means+((mov_means+1)/2)):mov_means:((dbounds(2)-1)*mov_means+((mov_means+1)/2)));
        %[xq,yq,tq] = ndgrid(1:size(dtemp,1),1:size(dtemp,2),((cn-1)*chunkMeans*mov_means+1):((cn-1)*chunkMeans*mov_means+size(dtemp,4)));
        %K = parfor_progressbar(size(dtemp,3),'Upsampling displacements');
        %for z = 1:size(dtemp,3)
        %    dtemp(:,:,z,:,1) = warp_scale*interpn(xi,yi,ti,squeeze(dispsdemref(:,:,z,dbounds(1):dbounds(2),1)),xq,yq,tq);
        %    dtemp(:,:,z,:,2) = warp_scale*interpn(xi,yi,ti,squeeze(dispsdemref(:,:,z,dbounds(1):dbounds(2),2)),xq,yq,tq);
        %    dtemp(:,:,z,:,3) = interpn(xi,yi,ti,squeeze(dispsdemref(:,:,z,dbounds(1):dbounds(2),3)),xq,yq,tq);
        %    K.iterate(1);
        %end
        %close(K);
        %toc
        %if useGPU == true
        %    reset(D);
        %end
     
        
        % Apply warp field to movie chunk (across all channels - almost always 2)
        % for 2 channels, 520 frames this takes 408 sec/290-357 sec for uint16! (for)/TOOLONG sec (parfor-topping out RAM, cacheing to SSD - bad)/705 sec (for, no temp_ch) on old starsky CPU,
        % 588 sec/563 for uint16 (for)/650 sec/621 sec for uint16 (parfor)/599 sec (for, no temp_ch) on Santiago CPU
        % parpool takes 55 sec on old starsky (20 workers), 66 sec on
        % Santiago (28 workers)
        warped_temp = zeros(size(temp),'like',temp); % just keep to zeros outside dispsdemref's ability to warp
        I = parfor_progressbar(size(intersect(1:size(temp,1),keep_chans),2)*size(temp,5),'Demons warping chunk');
        for ch = intersect(1:size(temp,1),keep_chans)
            temp_ch = squeeze(temp(ch,:,:,:,1:min(size(temp,5),size(dtemp,4)))); %RAM tradeoffs here - maybe don't need to do this if not using GPU, then could fit a second parallel run
            if useGPU == true
                temp_ch = gpuArray(temp_ch); % 520 frame single-color temp_ch is 7.16GB! But! Max gpuArray is 2^31 or ~450*510*30*310!
            end
            for t = 1:size(temp_ch,4) %for 260 frames, this takes 105 sec on old starsky CPU, OUTOFMEMORY sec on GPU (colab00 should be able to handle 260 - 47 sec on colab00 GPU!), 199 sec on Santiago CPU; 130 frames takes 40.5 sec on old starsky CPU, 32 sec on GPU
                warped_temp(ch,:,:,:,t) = imwarp(squeeze(temp_ch(:,:,:,t)),squeeze(dtemp(:,:,:,t,:)));
                I.iterate(1);
            end
            if useGPU == true
                %warped_temp = gather(warped_temp); %or something like that
                reset(D);
            end
        end
        close(I);
        clear dtemp temp_ch temp dtempz

        % XY DFT registration of warped chunk mean-z projections to chunk
        % mean to remove x-y jitters (just use green channel for
        % consistency!) - adds an extra ~3.5 min per chunk
        warped_temp_meanszch0 = mean(squeeze(warped_temp(1,:,:,:,:)),3);
        warped_temp_meanztch0 = mean(squeeze(warped_temp_meanszch0),3);

        [RSh,CSh] = DetermineXYShiftsFBS(warped_temp_meanszch0,1,0.95,warped_temp_meanztch0);

        xy_dftshifts(:,sbounds(1):sbounds(2)) = [RSh; CSh];

        warped_temp_xy = zeros(size(warped_temp),'like',warped_temp);
        L = parfor_progressbar(size(warped_temp,4)*size(warped_temp,1),'DFT warping chunk');
        for ch = 1:size(warped_temp,1)
            warped_temp_ch = squeeze(warped_temp(ch,:,:,:,:));
            for z = 1:size(warped_temp,4)
                warped_temp_xy(ch,:,:,z,:) = ApplyXYShiftsFBS(warped_temp_ch(:,:,z,:),RSh,CSh);
                L.iterate(1);
            end
        end
        close(L);
        clear warped_temp warped_temp_ch warped_temp_meanszch0 warped_temp_meanztch0 RSh CSh
        
        % Write warped movie chunk to NPY (not sbx) - make sure it doesn't
        % close file until all chunks are done
        % 145 sec to write 520 volumes on old starsky, 27 sec on Santiago
        % (to nasquatch)
        %warped_temp = cast(warped_temp,'single');
        %warped_temp_xy = permute(warped_temp_xy,[1 5 4 2 3]); %permute axes to be TZYX from original YXZT to match upstream .npy movies/satisfy napari; for two color, Fiji tiffs become TZCYX, but for easy color splitting in napari, make it CTZYX!
            %NO - trick is to keep time as the last variable, otherwise
            %appending to file gets messed up!
        if cn == 1
            shape = size(warped_temp_xy);
            shape(5) = min(ceil(info1.nframes/otlevels),size(dispsdemref,4)*mov_means); %correct for total number of volumes to be written!! Otherwise it won't open properly in napari
            dataType = class(warped_temp_xy);
            header = constructNPYheader(dataType, shape);
            fwrite(fid, header, 'uint8');
        end
        fwrite(fid, warped_temp_xy, dataType);
        clear warped_temp_xy

        H.iterate(1);
        toc
    end
    fclose(fid);
    % save xy dft shifts
    save(dft_save_path,'xy_dftshifts',"-v7.3")
    close(H);
    %close sbx file and write info (all this deprecated)
    %rw.close();
    %save([save_stem '.mat'],'info');
    J.iterate(1);
end
close(J);

%% mean movie warp loop for 5/1/24 imregdemons on signal vs probmovies

J = parfor_progressbar(size(warp_paths,1),'Mean movie warps progress');
for p = 1:size(warp_paths,1)
    tic
    
    % get a bunch of metadata from directory
    warp_path = char(strcat(warp_prefix,warp_paths(p)));
    warp_ref = warp_refs(p);
    %d = ls(warp_dir);
    %warp_file = d((contains(string(d),'ref') & ~contains(string(d),'xydft')),:);
    [~,warp_file,~] = fileparts(warp_path);
    %warp_path = [warp_dir '/' warp_file];
    %warp_scale = str2double(extractBetween(warp_file,strfind(warp_file,'scale')+5,strfind(warp_file,'AFS')-1));
    warp_scale = 4;
    warp_chan = str2double(warp_path(strfind(warp_path,'/ch')+3));
    warp_aniso = 0;
    warp_meta = char(extractBetween(warp_file,strfind(warp_file,'_scale4'),strfind(warp_file,'_disp')));
    mov_means = str2double(extractBetween(warp_path,strfind(warp_path,'_mean')-2,strfind(warp_path,'_mean')-1));
    warp_title = char(extractBetween(warp_file,1,strfind(warp_file,'scale4')-1));
    
    % figure out mean movie location(s) from provided warp directory
    mean_dir = [char(fileparts(fileparts(fileparts(fileparts(strcat(mov_prefix,warp_paths(p))))))) '/tiffs'];
    dl = ls(mean_dir);
    dd = dir(mean_dir);
    %chnum = sum(contains(string(dl),'ch').*[dd.isdir]'); % number of mean channels available, either 1 or 2 (ch0 is green, ch1 is red)
    chnum = 2;
    save_path = [mean_dir '/' warp_title 'alignedmeans_wch' num2str(warp_chan) '_aniso' num2str(warp_aniso) warp_meta 'toref' num2str(warp_ref) '.npy'];
    
    % load in mean movie(s)
    mean_mov = readNPY([mean_dir '/ch0/' num2str(mov_means) '_mean__/means_movie.npy']);
    mean_mov = permute(mean_mov,[5,3,4,2,1]);
    if chnum == 2
        mean_mov2 = readNPY([mean_dir '/ch1/' num2str(mov_means) '_mean__/means_movie.npy']);
        mean_mov(2,:,:,:,:) = permute(mean_mov2,[3,4,2,1]);
    end
    
    % load in and upsample displacements
    load(warp_path);
    dispsdemup = zeros([size(mean_mov,2) size(mean_mov,3) size(mean_mov,4) min(size(mean_mov,5),size(dispsdemref,4)) 3]);
    if useGPU == true
        dispsdemref = gpuArray(dispsdemref);
    end
    H = parfor_progressbar(size(dispsdemup,4),'Upsampling displacements');
    for t = 1:size(dispsdemup,4)
        for z = 1:size(dispsdemup,3)
            dispsdemup(:,:,z,t,1) = warp_scale*imresize(squeeze(dispsdemref(:,:,z,t,1)),[size(dispsdemup,1),size(dispsdemup,2)],'bilinear');
            dispsdemup(:,:,z,t,2) = warp_scale*imresize(squeeze(dispsdemref(:,:,z,t,2)),[size(dispsdemup,1),size(dispsdemup,2)],'bilinear');
            dispsdemup(:,:,z,t,3) = imresize(squeeze(dispsdemref(:,:,z,t,3)),[size(dispsdemup,1),size(dispsdemup,2)],'bilinear');
        end
        H.iterate(1);
    end
    close(H);
    if useGPU == true
        reset(D);
    end
    
    % apply warp to mean movie
    warped_mov = zeros(size(mean_mov));
    H = parfor_progressbar(size(mean_mov,1)*min(size(mean_mov,5),size(dispsdemref,4)),'Warping movie');
    for ch = intersect(1:size(mean_mov,1),keep_chans)
        mean_mov_ch = squeeze(mean_mov(ch,:,:,:,:));
        if useGPU == true
            mean_mov_ch = gpuArray(mean_mov_ch); % full mean_mov with both colors won't fit on Quadro GPU, only on colabs
        end
        for t = 1:min(size(mean_mov,5),size(dispsdemref,4))
            warped_mov(ch,:,:,:,t) = imwarp(squeeze(mean_mov_ch(:,:,:,t)),squeeze(dispsdemup(:,:,:,t,:)));
            H.iterate(1);
        end
        if useGPU == true
            reset(D);
        end
    end
    close(H);
    
    % save movie as NPY
    warped_mov = cast(warped_mov,'single');
    movout = permute(warped_mov,[1 5 4 2 3]); %permute axes to be TZYX from original YXZT to match upstream .npy movies/satisfy napari; for two color, Fiji tiffs become TZCYX, but for easy color splitting in napari, make it CTZYX!
    writeNPY(movout,save_path);
    
    J.iterate(1);
    toc
end
close(J);
