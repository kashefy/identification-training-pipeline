function trainAndTestLocKsToNoSrcs()

addPathsIfNotIncluded( cleanPathFromRelativeRefs( [pwd '/..'] ) ); 
startIdentificationTraining();

pipe = TwoEarsIdTrainPipe();
pipe.ksWrapper = DataProcs.DnnLocKsWrapper(); % uses 0.5s blocksize
pipe.blockCreator = BlockCreators.MeanStandardBlockCreator( 0.5, 0.2 );
pipe.featureCreator = FeatureCreators.FeatureSet1BlockmeanPlusModelOutputs();
pipe.labelCreator = LabelCreators.NumberOfSourcesLabeler();
pipe.modelCreator = ModelTrainers.GlmNetLambdaSelectTrainer( ...
    'performanceMeasure', @PerformanceMeasures.MultinomialBAC, ...
    'family', 'multinomial', ... % deal with NumberOfSources as a multiclass label
    'cvFolds', 4, ...
    'alpha', 0.99 );
pipe.modelCreator.verbose( 'on' );

pipe.trainset = 'learned_models/IdentityKS/trainTestSets/NIGENS160807_mini_TrainSet_1.flist';
pipe.setupData();

sc(1) = SceneConfig.SceneConfiguration();
sc(1).addSource( SceneConfig.PointSource( ...
        'data', SceneConfig.FileListValGen( 'pipeInput' ) ) );
sc(1).addSource( SceneConfig.PointSource( ...
        'data', SceneConfig.FileListValGen( ...
               pipe.pipeline.trainSet('fileLabel',{{'type',{'general'}}},'fileName') ),...
        'offset', SceneConfig.ValGen( 'manual', 0 ) ),...
    'snr', SceneConfig.ValGen( 'manual', 10 ),...
    'loop', 'randomSeq' );
sc(1).addSource( SceneConfig.PointSource( ...
        'data', SceneConfig.FileListValGen( ...
               pipe.pipeline.trainSet('fileLabel',{{'type',{'general'}}},'fileName') ),...
        'offset', SceneConfig.ValGen( 'manual', 0 ) ),...
    'snr', SceneConfig.ValGen( 'manual', 10 ),...
    'loop', 'randomSeq' );
pipe.init( sc, 'fs', 16e3 ); % DnnLocKs only works with 16k

modelPath = pipe.pipeline.run( 'modelName', 'dnnlocNoSrcsModel', 'modelPath', 'test_dnnlocNoSrcs' );

fprintf( ' -- Model is saved at %s -- \n\n', modelPath );

%% test

pipe = TwoEarsIdTrainPipe();
pipe.ksWrapper = DataProcs.DnnLocKsWrapper(); % uses 0.5s blocksize
pipe.blockCreator = BlockCreators.MeanStandardBlockCreator( 0.5, 0.2 );
pipe.featureCreator = FeatureCreators.FeatureSet1BlockmeanPlusModelOutputs();
pipe.labelCreator = LabelCreators.NumberOfSourcesLabeler();
pipe.modelCreator = ModelTrainers.LoadModelNoopTrainer( ...
    [pwd filesep 'test_dnnlocNoSrcs/dnnlocNoSrcsModel.model.mat'], ...
    'performanceMeasure', @PerformanceMeasures.MultinomialBAC );
pipe.modelCreator.verbose( 'on' );

pipe.testset = 'learned_models/IdentityKS/trainTestSets/NIGENS160807_mini_TestSet_1.flist';
pipe.setupData();

sc(1) = SceneConfig.SceneConfiguration();
sc(1).addSource( SceneConfig.PointSource( ...
        'data', SceneConfig.FileListValGen( 'pipeInput' ) ) );
sc(1).addSource( SceneConfig.PointSource( ...
        'data', SceneConfig.FileListValGen( ...
               pipe.pipeline.testSet('fileLabel',{{'type',{'general'}}},'fileName') ),...
        'offset', SceneConfig.ValGen( 'manual', 0 ) ),...
    'snr', SceneConfig.ValGen( 'manual', 10 ),...
    'loop', 'randomSeq' );
sc(1).addSource( SceneConfig.PointSource( ...
        'data', SceneConfig.FileListValGen( ...
               pipe.pipeline.testSet('fileLabel',{{'type',{'general'}}},'fileName') ),...
        'offset', SceneConfig.ValGen( 'manual', 0 ) ),...
    'snr', SceneConfig.ValGen( 'manual', 10 ),...
    'loop', 'randomSeq' );
pipe.init( sc, 'fs', 16e3 ); % DnnLocKs only works with 16k

modelPath = pipe.pipeline.run( 'modelName', 'dnnlocNoSrcsModel', 'modelPath', 'test_dnnlocNoSrcs' );

fprintf( ' -- Model is saved at %s -- \n\n', modelPath );
