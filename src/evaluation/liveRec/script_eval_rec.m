function script_eval_rec( modelsDir, fs, recIdxs, segmBb, ppRemoveDc )

if nargin < 1 || isempty( modelsDir )
    modelsDir = 'learned_models/IdentityKS/mc1b_models_dataset_1';
end
if nargin < 2 || isempty( fs )
    fs = 16000;
end
if nargin < 3 || isempty( recIdxs )
    recIdxs = 1:50;
end
if nargin < 4 || isempty( segmBb )
    segmBb = false;
end
if nargin < 5 || isempty( ppRemoveDc )
    ppRemoveDc = false;
end

modelsDir = db.getFile( modelsDir );
modelsDirContents = dir( [modelsDir filesep '*.model.mat'] );
idModels = arrayfun( @(x)(struct('name',{x.name(1:end-10)})), modelsDirContents );
[idModels(1:numel(idModels)).dir] = deal( modelsDir );

%%

flist = ...
    {fullfile(db.path, 'sound_databases/adream_1605/rec/raw/alarm.mat'),...
    fullfile(db.path, 'sound_databases/adream_1605/rec/raw/baby.mat'),...
    fullfile(db.path, 'sound_databases/adream_1605/rec/raw/baby_dog_fire.mat'),...
    fullfile(db.path, 'sound_databases/adream_1605/rec/raw/baby_piano.mat'),...
    fullfile(db.path, 'sound_databases/adream_1605/rec/raw/dog.mat'),...
    fullfile(db.path, 'sound_databases/adream_1605/rec/raw/baby_dog_fire_moving.mat'),...
    fullfile(db.path, 'sound_databases/adream_1605/rec/raw/fire.mat'),...
    fullfile(db.path, 'sound_databases/adream_1605/rec/raw/baby_dog_fire_piano.mat'),...% piano_baby -> baby_dog_fire_piano
    fullfile(db.path, 'sound_databases/adream_1609/rec/bagfiles_20160928_A/mat/alarm.mat'), ...
    fullfile(db.path, 'sound_databases/adream_1609/rec/bagfiles_20160928_A/mat/alarm_general_footsteps_fire.mat'), ...
    fullfile(db.path, 'sound_databases/adream_1609/rec/bagfiles_20160928_A/mat/baby.mat'), ...
    fullfile(db.path, 'sound_databases/adream_1609/rec/bagfiles_20160928_A/mat/baby_maleSpeech_femaleSpeech_femaleScream-maleScream.mat'), ...
    fullfile(db.path, 'sound_databases/adream_1609/rec/bagfiles_20160928_A/mat/femaleScream-maleScream.mat'), ...
    fullfile(db.path, 'sound_databases/adream_1609/rec/bagfiles_20160928_A/mat/femaleScream-maleScream_baby.mat'), ...
    fullfile(db.path, 'sound_databases/adream_1609/rec/bagfiles_20160928_A/mat/femaleSpeech.mat'), ...
    fullfile(db.path, 'sound_databases/adream_1609/rec/bagfiles_20160928_A/mat/femaleSpeech_baby.mat'), ...
    fullfile(db.path, 'sound_databases/adream_1609/rec/bagfiles_20160928_A/mat/fire.mat'), ...
    fullfile(db.path, 'sound_databases/adream_1609/rec/bagfiles_20160928_A/mat/fire_alarm_baby_femaleSpeech.mat'), ...
    fullfile(db.path, 'sound_databases/adream_1609/rec/bagfiles_20160928_A/mat/footsteps.mat'), ...
    fullfile(db.path, 'sound_databases/adream_1609/rec/bagfiles_20160928_A/mat/general1of2.mat'), ...
    fullfile(db.path, 'sound_databases/adream_1609/rec/bagfiles_20160928_A/mat/general2of2.mat'), ...
    fullfile(db.path, 'sound_databases/adream_1609/rec/bagfiles_20160928_A/mat/general_femaleSpeech.mat'), ...
    fullfile(db.path, 'sound_databases/adream_1609/rec/bagfiles_20160928_A/mat/general_maleSpeech_femaleSpeech.mat'), ...
    fullfile(db.path, 'sound_databases/adream_1609/rec/bagfiles_20160928_A/mat/maleSpeech.mat'), ...
    fullfile(db.path, 'sound_databases/adream_1609/rec/bagfiles_20160928_A/mat/maleSpeech_femaleSpeech.mat'), ...
    fullfile(db.path, 'sound_databases/adream_1609/rec/bagfiles_20160929/mat/alarm_general.mat'), ...
    fullfile(db.path, 'sound_databases/adream_1609/rec/bagfiles_20160929/mat/baby_femaleSpeech_general.mat'), ...
    fullfile(db.path, 'sound_databases/adream_1609/rec/bagfiles_20160929/mat/baby_fire.mat'), ...
    fullfile(db.path, 'sound_databases/adream_1609/rec/bagfiles_20160929/mat/baby_fire_alarm_femaleScream-maleScream.mat'), ...
    fullfile(db.path, 'sound_databases/adream_1609/rec/bagfiles_20160929/mat/fire_alarm_femaleScream-maleScream.mat'), ...
    fullfile(db.path, 'sound_databases/adream_1609/rec/bagfiles_20160929/mat/general_maleSpeech_femaleSpeech.mat'), ...
    fullfile(db.path, 'sound_databases/adream_1609/rec/bagfiles_20160929_B/mat/alarm.mat'), ...
    fullfile(db.path, 'sound_databases/adream_1609/rec/bagfiles_20160929_B/mat/baby.mat'), ...
    fullfile(db.path, 'sound_databases/adream_1609/rec/bagfiles_20160929_B/mat/baby_fire_alarm_femaleScream-maleScream.mat'), ...
    fullfile(db.path, 'sound_databases/adream_1609/rec/bagfiles_20160929_B/mat/baby_maleSpeech_femaleSpeech_femaleScream-maleScream.mat'), ...
    fullfile(db.path, 'sound_databases/adream_1609/rec/bagfiles_20160929_B/mat/femaleScream-maleScream_baby.mat'), ...
    fullfile(db.path, 'sound_databases/adream_1609/rec/bagfiles_20160929_B/mat/fire_alarm_baby_femaleSpeech.mat'), ...
    fullfile(db.path, 'sound_databases/adream_1609/rec/bagfiles_20160929_B/mat/footsteps.mat'), ...
    fullfile(db.path, 'sound_databases/adream_1609/rec/bagfiles_20160929_B/mat/general_femaleSpeech.mat'), ...
    fullfile(db.path, 'sound_databases/adream_1609/rec/bagfiles_20160929_C/mat/baby_maleSpeech_femaleSpeech_femaleScream-maleScream.mat'), ...
    fullfile(db.path, 'sound_databases/adream_1609/rec/bagfiles_20160929_C/mat/femaleSpeech.mat'), ...
    fullfile(db.path, 'sound_databases/adream_1609/rec/bagfiles_20160929_C/mat/fire_alarm_baby_femaleSpeech.mat'), ...
    fullfile(db.path, 'sound_databases/adream_1609/rec/bagfiles_20160929_D/mat/femaleSpeech.mat'), ...
    fullfile(db.path, 'sound_databases/adream_1609/rec/bagfiles_20160929_D/mat/fire_alarm_baby_femaleSpeech.mat'), ...
    fullfile(db.path, 'sound_databases/adream_1609/rec/bagfiles_20160929_E/mat/alarm_general_footsteps_fire.mat'), ...
    fullfile(db.path, 'sound_databases/adream_1609/rec/bagfiles_20160929_E/mat/baby_fire_alarm_femaleScream-maleScream.mat'), ...
    fullfile(db.path, 'sound_databases/adream_1609/rec/bagfiles_20160929_E/mat/femaleScream-maleScream_baby.mat'), ...
    fullfile(db.path, 'sound_databases/adream_1609/rec/bagfiles_20160929_E/mat/femaleSpeech.mat'), ...
    fullfile(db.path, 'sound_databases/adream_1609/rec/bagfiles_20160929_E/mat/maleSpeech.mat'), ...
    fullfile(db.path, 'sound_databases/adream_1609/rec/bagfiles_20160929_E/mat/maleSpeech_femaleSpeech.mat'), ...
    };
% onset of first chirp (inclusive) to offset of final chirp
% (inclusive) in samples
session_onOffSet = [1.236e+05, 8582556;...   % alarm
                    8.991e+04, 15096220;...   % baby
                    88944, min([15094288, 4819608, 30081565]);...   % baby_dog_fire
                    7.4822e+04, min([15066044, 8090428]);...   % baby_piano
                    9.2152e+04, 4826024;...   % dog # previously 9.927e+04
                    5.0477e+04, min([15017354, 4742674, 3000463]);...   % baby_dog_fire_moving
                    5.4325e+04, 30012327;...   % fire
                    1.1279e+05, min([15141980, 4867300, 30129257, 8166364]);...   % piano_baby -> baby_dog_fire_piano \
                    % bagfiles_20160928_A
                    71663, inf; ... % alarm
                    120393, inf; ... % 10 alarm_general_footsteps_fire
                    148617, inf; ... % baby
                    134505, inf; ... % baby_maleSpeech_femaleSpeech_femaleScream-maleScream
                    134946, inf; ... % femaleScream-maleScream
                    84893, inf; ... % femaleScream-maleScream_baby
                    54243, inf; ... % 15 femaleSpeech
                    93713, inf; ... % femaleSpeech_baby
                    203433, inf;  ...% fire
                    280035, inf;  ...% fire_alarm_baby_femaleSpeech
                    189365, inf;  ...% footsteps
                    0, inf;  ...% 20 general1of2
                    0, inf;  ...% general2of2
                    54199, inf;  ...% general_femaleSpeech
                    38808, inf;  ...% general_maleSpeech_femaleSpeech
                    75773, inf;  ...% maleSpeech
                    143325, inf;  ...% 25 maleSpeech_femaleSpeech
                    % bagfiles_20160929':
                    64386,   inf; ...% alarm_general
                    75720, inf; ...% baby_femaleSpeech_general
                    138386, inf; ...% baby_fire
                    121716, inf; ...% baby_fire_alarm_femaleScream-maleScream
                    186984, inf; ...% 30 fire_alarm_femaleScream-maleScream
                    45026 inf; ...% general_maleSpeech_femaleSpeech
                    % bagfiles_20160929_B:
                    63284,   inf; ...% alarm
                    70560,   inf; ...% baby
                    132388,   inf; ...% baby_fire_alarm_femaleScream-maleScream
                    93713,   inf; ...% 35 baby_maleSpeech_femaleSpeech_femaleScream-maleScream
                    64739,   inf; ...% femaleScream-maleScream_baby
                    88641,   inf; ...% fire_alarm_baby_femaleSpeech
                    33957,   inf; ...% footsteps
                    51994,   inf; ...% general_femaleSpeech
                    % bagfiles_20160929_C
                    72324, inf; ...% 40 baby_maleSpeech_femaleSpeech_femaleScream-maleScream
                    60858, inf; ...% femaleSpeech
                    62446, inf; ...% fire_alarm_baby_femaleSpeech
                    % bagfiles_20160929_D
                    92831, inf; ...% femaleSpeech
                    76293, inf; ...% fire_alarm_baby_femaleSpeech
                    % bagfiles_20160929_E
                    430416, inf; ...% 45 alarm_general_footsteps_fire
                    380583, inf; ...% baby_fire_alarm_femaleScream-maleScream
                    323694, inf; ...% femaleScream-maleScream_baby
                    304378, inf; ...% femaleSpeech
                    323694, inf; ...% maleSpeech
                    323694, inf; ...% 50 maleSpeech_femaleSpeech
                   ];
session_onOffSet = session_onOffSet / 44100.0; % from samples to seconds
for ii = recIdxs
    fpath_mixture_mat = flist{ii};
    [subdir, fname, ext] = fileparts(fpath_mixture_mat);
    sessiondir = fileparts(subdir); % e.g bagfiles_20160929_B
    if strcmp(ext, '.mat')
        fpath_mixture_wav = fullfile(sessiondir, 'wav', [fname, '.wav']);
    elseif strcmp(ext, '.wav')
        % do nothing
    else
        error('Unrecognized mixture file %s', fpath_mixture_mat);
    end
    [idLabels{ii}, perf{ii}] = identify_rec(idModels, ...
        fpath_mixture_mat, fpath_mixture_wav, ...
        session_onOffSet(ii,:), ...
        ppRemoveDc, fs, segmBb);
    close all
end

p = arrayfun( @(x)(x.performance), vertcat( perf{:} ) );
disp( p );

perfOverview = vertcat( perf{:} );
sceneIdxs{1} = [1,2,5,7]; % 1 src, old files
sceneIdxs{2} = [3,4,6,8]; % 2-4 srcs, old files
sceneIdxs{3} = [9,11,13,15,17,19,20,21,24]; % 1 src, pos A, new files
sceneIdxs{4} = [32,33,38]; % 1 src, pos B, new files
sceneIdxs{5} = [41]; % 1 src, pos C, new files
sceneIdxs{6} = [43]; % 1 src, moving, new files
sceneIdxs{7} = [48,49]; % 1 src, pos e, new files
sceneIdxs{8} = [14,16,22,25,26,28]; % 2 srcs, pos A, new files
sceneIdxs{9} = [36,39]; % 2 srcs, pos B, new files
sceneIdxs{10} = [47,50]; % 2 srcs, pos E, new files
sceneIdxs{11} = [23,27,31]; % 3 srcs, pos A, new files
sceneIdxs{12} = [10,12,18,29]; % 4 srcs, pos A, new files
sceneIdxs{13} = [34,35]; % 4 srcs, pos B, new files
sceneIdxs{14} = [40]; % 4 srcs, pos C, new files
sceneIdxs{15} = [44]; % 4 srcs, moving, new files
sceneIdxs{16} = [45,46]; % 4 srcs, pos E, new files

bac = [];
sens = [];
spec = [];
for ii = 1 : numel( sceneIdxs )
    [bac(ii,:),sens(ii,:),spec(ii,:)] = getLiveEvalPerf( perfOverview, sceneIdxs{ii} );
end

[bac1,sens1,spec1] = getLiveEvalPerf( perfOverview, [sceneIdxs{3:7}] );
[bac2,sens2,spec2] = getLiveEvalPerf( perfOverview, [sceneIdxs{8:10}] );
[bac3,sens3,spec3] = getLiveEvalPerf( perfOverview, [sceneIdxs{11}] );
[bac4,sens4,spec4] = getLiveEvalPerf( perfOverview, [sceneIdxs{[12,13,14,15,16]}] );
