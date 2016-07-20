classdef DistractedBlockCreator < BlockCreators.MeanStandardBlockCreator
    % 
    %% ----------------------------------------------------------------------------------- 
    properties (SetAccess = private)
        distractorIdxs;
        rejectThreshold;
    end
    
    %% -----------------------------------------------------------------------------------
    methods
        
        function obj = DistractedBlockCreator( blockSize_s, shiftSize_s, varargin )
            obj = obj@BlockCreators.MeanStandardBlockCreator( blockSize_s, shiftSize_s );
            ip = inputParser;
            ip.addOptional( 'distractorSources', 2 );
            ip.addOptional( 'rejectEnergyThreshold', -30 );
            ip.parse( varargin{:} );
            obj.distractorIdxs = ip.Results.distractorSources;
            obj.rejectThreshold = ip.Results.rejectEnergyThreshold;
        end
        %% -------------------------------------------------------------------------------
        
    end
    
    %% ----------------------------------------------------------------------------------- 
    methods (Access = protected)
        
        function outputDeps = getBlockCreatorInternOutputDependencies( obj )
            outputDeps.msbc = getBlockCreatorInternOutputDependencies@...
                                                BlockCreators.MeanStandardBlockCreator( obj );
            outputDeps.v = 2;
        end
        %% ------------------------------------------------------------------------------- 

        function [afeBlocks, blockAnnots] = blockify( obj, afeData, annotations )
            [afeBlocks, blockAnnots] = ...
                 blockify@BlockCreators.MeanStandardBlockCreator( obj, afeData, annotations );
            for ii = numel( afeBlocks ) : -1 : 1
                rejectBlock = LabelCreators.EnergyDependentLabeler.isEnergyTooLow( ...
                               blockAnnots(ii), obj.distractorIdxs, obj.rejectThreshold );
                if rejectBlock
                    afeBlocks(ii) = [];
                    blockAnnots(ii) = [];
                end
                fprintf( '*' );
            end
        end
        %% -------------------------------------------------------------------------------
        
    end
    %% ----------------------------------------------------------------------------------- 
    
    methods (Static)
        
        %% ------------------------------------------------------------------------------- 
        %% ------------------------------------------------------------------------------- 
        
    end
    
end

        

