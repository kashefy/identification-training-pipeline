function trainAndTestCleanModel_2( classname )

if nargin < 1, classname = 'speech'; end;

%startTwoEars( '../IdentificationTraining.xml' );
addpath( '..' );
startIdentificationTraining();

pipe = TwoEarsIdTrainPipe();
pipe.featureCreator = featureCreators.FeatureSet1Blockmean();
pipe.modelCreator = modelTrainers.GlmNetLambdaSelectTrainer( ...
    'performanceMeasure', @performanceMeasures.BAC2, ...
    'cvFolds', 7, ...
    'alpha', 0.99 );
pipe.modelCreator.verbose( 'on' );

pipe.trainset = 'learned_models/IdentityKS/trainTestSets/IEEE_AASP_80pTrain_TrainSet_1.flist';
pipe.testset = 'learned_models/IdentityKS/trainTestSets/IEEE_AASP_80pTrain_TestSet_1.flist';

sc = dataProcs.SceneConfiguration(); % clean
pipe.setSceneConfig( [sc] ); 

pipe.init();
modelPath = pipe.pipeline.run( {classname}, 0 );

fprintf( ' -- Model is saved at %s -- \n', modelPath );

