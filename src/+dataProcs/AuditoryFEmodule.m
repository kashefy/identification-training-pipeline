classdef AuditoryFEmodule < core.IdProcInterface
    
    %% --------------------------------------------------------------------
    properties (SetAccess = {?dataProcs.ParallelRequestsAFEmodule})
        managerObject;           % WP2 manager object - holds the signal buffer (data obj)
        afeDataObj;
        afeSignals;
        afeParams;
        output;
    end
    
    %% --------------------------------------------------------------------
    methods (Static)
    end
    
    %% --------------------------------------------------------------------
    methods (Access = public)
        
        function obj = AuditoryFEmodule( fs, afeRequests )
            obj = obj@core.IdProcInterface();
            obj.afeSignals = containers.Map( 'KeyType', 'int32', 'ValueType', 'any' );
            obj.afeDataObj = dataObject( [], fs, 2, 2 );
            obj.managerObject = manager( obj.afeDataObj );
            for ii = 1:length( afeRequests )
                obj.afeSignals(ii) = obj.managerObject.addProcessor( ...
                                           afeRequests{ii}.name, afeRequests{ii}.params );
                sig = obj.afeSignals(ii);
                sigsr = dataProcs.AuditoryFEmodule.signal2struct( sig );
                if isfield( obj.afeParams, 'sr' ) &&...
                        isfield( obj.afeParams.sr, sig{1}.Name )
                    sigsrs = obj.afeParams.sr.(sig{1}.Name);
                    if ~iscell( sigsrs ), sigsrs = {sigsrs}; end
                    sigsrs{end+1} = sigsr;
                    sigsrsHashes = cellfun( @calcDataHash, sigsrs, 'UniformOutput', false );
                    [~,order] = sort( sigsrsHashes );
                    sigsrs = sigsrs(order);
                    obj.afeParams.sr.(sig{1}.Name) = sigsrs;
                else
                    obj.afeParams.sr.(sig{1}.Name) = sigsr;
                end
            end
            obj.afeParams.p = dataProcs.AuditoryFEmodule.parameterSummary2struct( ...
                                obj.afeDataObj.getParameterSummary( obj.managerObject ) );
        end
        %% ----------------------------------------------------------------
        
        function process( obj, wavFilepath )
            in = obj.loadInputData( wavFilepath );
            obj.output.afeData = obj.makeAFEdata( in.earSout );
            obj.output.onOffsOut = in.onOffsOut;
            if isfield( in, 'annotations' )
                obj.output.annotations = in.annotations;
            else
                obj.output.annotations = [];
            end
        end
        %% ----------------------------------------------------------------
        
        function afeDummy = makeDummyData ( obj )
            afeDummy.afeData = obj.makeAFEdata( rand( 4100, 2 ) );
            afeDummy.onOffsOut = zeros(0,2);
            afeDummy.annotations = [];
        end
        %% ----------------------------------------------------------------

        function afeData = makeAFEdata( obj, earSignals )
            obj.managerObject.reset();
            obj.afeDataObj.clearData();
            fs = obj.afeDataObj.time{1,1}.FsHz;
            for outputSig = obj.afeSignals.values
                for kk = 1:numel( outputSig{1} )
                    if isa( outputSig{1}, 'cell' )
                        os = outputSig{1}{kk};
                    else
                        os = outputSig{1}(kk);
                    end
                    os.setBufferSize( ceil( length( earSignals ) / fs ) );
                end
            end
            % process chunks of 1 second
            for chunkBegin = 1:fs:length(earSignals)
                chunkEnd = min( length( earSignals ), chunkBegin + fs - 1 );
                obj.managerObject.processChunk( earSignals(chunkBegin:chunkEnd,:), 1 );
                fprintf( '.' );
            end
            afeData = obj.afeSignals;
        end
        %% ----------------------------------------------------------------

    end
    
    %% --------------------------------------------------------------------
    methods (Access = protected)
        
        function outputDeps = getInternOutputDependencies( obj )
            outputDeps.afeParams = obj.afeParams;
        end
        %% ----------------------------------------------------------------

        function out = getOutput( obj )
            out = obj.output;
        end
        %% ----------------------------------------------------------------
        
    end

    %% --------------------------------------------------------------------
    methods (Static)
       
        function s = signal2struct( sig )
            if isa( sig{1}, 'TimeFrequencySignal' )
                s.cfHz = sig{1}.cfHz;
            end
            if isa( sig{1}, 'CorrelationSignal' )
                s.cfHz = sig{1}.cfHz;
                s.lags = sig{1}.lags;
            end
            if isa( sig{1}, 'FeatureSignal' ) || isa( sig{1}, 'SpectralFeaturesSignal' )
                s.flist = sig{1}.fList;
            end
            if isa( sig{1}, 'ModulationSignal' )
                s.cfHz = sig{1}.cfHz;
                s.modCfHz = sig{1}.modCfHz;
            end
            if isa( sig{1}, 'Signal' )
                s.name = sig{1}.Name;
                s.dim = sig{1}.Dimensions;
                s.fsHz = sig{1}.FsHz;
            end
        end
        %% ----------------------------------------------------------------
        
        function s = parameterSummary2struct( p )
            fnames = fieldnames( p );
            for ii = 1 : length( fnames )
                pfn = p.(fnames{ii});
                if iscell( pfn )
                    for jj = 1 : length( pfn )
                        stmp{jj} = ...
                            dataProcs.AuditoryFEmodule.parameter2struct( pfn{jj} );
                    end
                    s.(fnames{ii}) = stmp;
                    clear stmp;
                elseif isa( pfn, 'Parameters' )
                    s.(fnames{ii}) = ...
                        {dataProcs.AuditoryFEmodule.parameter2struct( pfn )};
                end
            end
        end
        %% ----------------------------------------------------------------
        
        function s = parameter2struct( p )
            k = p.map.keys;
            v = p.map.values;
            for ii = 1 : p.map.Count
                s.(k{ii}) = v{ii};
            end
        end
        %% ----------------------------------------------------------------
        
    end
    
end
