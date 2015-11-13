function getTimes_GlmNet_azms()
    
addpath( '../..' );
startIdentificationTraining();

classes = {'alarm','baby','femaleSpeech','fire'};
featureCreators = {?featureCreators.FeatureSet1Blockmean2Ch,...
                   ?featureCreators.FeatureSet1Blockmean};
azimuths = {0,45,90,180};

if exist( 'glmnet_azms.mat', 'file' )
    load( 'glmnet_azms.mat' );
else
    return;
end
if exist( 'glmnet_azms_times.mat', 'file' )
    load( 'glmnet_azms_times.mat' );
end

for ii = 1 : 2 % svm only done on 1,2
for cc = 1 : numel( classes )
for fc = 1 : numel( featureCreators )
for aa = 1 : numel( azimuths )
for aatest = aa % 1 : numel( azimuths )
    
fprintf( '.\n' );

if size(modelpathes,1) < ii  ||  size(modelpathes,2) < cc  ||  ...
        size(modelpathes,3) < fc  ||  size(modelpathes,4) < aa
    continue;
end
if size(modelpathes,1) >= ii  &&  size(modelpathes,2) >= cc  &&  ...
        size(modelpathes,3) >= fc  &&  size(modelpathes,4) >= aa  ...
        &&  isempty( modelpathes{ii,cc,fc,aa}
    continue;
end
    
testmodel = load( [modelpathes{ii,cc,fc,aa} filesep classes{cc} '.model.mat'] );
trainTime{ii,cc,fc,aa} = testmodel.trainTime;

% sc = sceneConfig.SceneConfiguration();
% sc.addSource( sceneConfig.PointSource('azimuth',...
%                                       sceneConfig.ValGen('manual',azimuths{aatest})) );
% 
% pipe = TwoEarsIdTrainPipe();
% pipe.featureCreator = feval( featureCreators{fc}.Name );
% pipe.modelCreator = ...
%     modelTrainers.LoadModelNoopTrainer( ...
%         @(cn)(fullfile( modelpathes{ii,cc,fc,aa}, [cn '.model.mat'] )), ...
%         'performanceMeasure', @performanceMeasures.BAC2, ...
%         'modelParams', struct('lambda', []) );
% pipe.modelCreator.verbose( 'on' );
% 
% setsBasePath = 'learned_models/IdentityKS/trainTestSets/';
% pipe.trainset = [];
% pipe.testset = [setsBasePath 'NIGENS_75pTrain_TestSet_' num2str(ii) '.flist'];
% pipe.setupData();
% 
% pipe.setSceneConfig( sc ); 
% 
% pipe.init();
% modelpathes_test{ii,cc,fc,aa,aatest} = pipe.pipeline.run( {classes{cc}}, 0 );
% 
% testmodel = load( [modelpathes_test{ii,cc,fc,aa,aatest} filesep classes{cc} '.model.mat'] );


save( 'glmnet_azms_times.mat', 'classes', 'featureCreators', 'azimuths', ...
      'trainTime'  );

end
end
end
end
end
