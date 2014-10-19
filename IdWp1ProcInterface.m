classdef (Abstract) IdWp1ProcInterface < Hashable & handle
    %% responsible for transforming wav files into earsignals
    %   this includes transforming onset/offset labels to the earsignals'
    %   time line, as it is the only point where the "truth" is known.
    
    %%---------------------------------------------------------------------
    properties (SetAccess = private)

    end
    
    %%---------------------------------------------------------------------
    methods (Static)
    end
    
    %%---------------------------------------------------------------------
    methods (Access = public)
        
        function obj = IdWp1ProcInterface()
        end
        
        %% function run( obj, idTrainData )
        %       wp1-process all wavs in idTrainData
        %       save the results in mat-files
        %       updates idTrainData
        function run( obj, idTrainData )
            fprintf( 'wp1 processing of sounds' );
            idTrainData.wp1Hash = obj.getHash();
            wp1NameExt = ['.' idTrainData.wp1Hash '.wp1.mat'];
            for trainFile = idTrainData(:)'
                fprintf( '\n.' );
                wp1FileName = [which(trainFile.wavFileName) wp1NameExt];
                if exist( wp1FileName, 'file' ), continue; end
                [earSignals, earsOnOffs] = obj.makeEarsignalsAndLabels( trainFile.wavFileName );
                save( wp1FileName, 'earSignals', 'earsOnOffs' );
            end
            fprintf( ';\n' );
        end
        
        
        %%-----------------------------------------------------------------
        
    end
    
    %%---------------------------------------------------------------------
    methods (Access = private)
    end
    
    %%---------------------------------------------------------------------
    methods (Abstract)
        
        [earSignals, earsOnOffs] = makeEarsignalsAndLabels( obj, trainFile )
        
    end
    
end

