classdef (Abstract) IdProcInterface < handle
    %% data file processor
    %
    
    %%---------------------------------------------------------------------
    properties (SetAccess = protected)
        procName;
        externOutputDeps;
    end
    
    %%---------------------------------------------------------------------
    methods (Static)
    end
    
    %%---------------------------------------------------------------------
    methods (Access = public)
        
        function out = saveOutput( obj, inFilePath )
            inFilePath = which( inFilePath ); % ensure absolute path
            out = obj.getOutput();
            currentFolder = obj.getCurrentFolder( inFilePath );
            if isempty( currentFolder )
                obj.createCurrentConfigFolder( inFilePath );
            end
            outFilename = obj.getOutputFileName( inFilePath );
            save( outFilename, '-struct', 'out' );
        end
        %%-----------------------------------------------------------------
        
        function out = processSaveAndGetOutput( obj, inFileName )
            if ~obj.hasFileAlreadyBeenProcessed( inFileName )
                obj.process( inFileName );
                out = obj.saveOutput( inFileName );
            else
                out = load( obj.getOutputFileName( inFileName ) );
            end
        end
        %%-----------------------------------------------------------------
        
        function outFileName = getOutputFileName( obj, inFilePath )
            inFilePath = which( inFilePath ); % ensure absolute path
            currentFolder = obj.getCurrentFolder( inFilePath );
            [~, fileName, fileExt] = fileparts( inFilePath );
            fileName = [fileName fileExt];
            outFileName = fullfile( currentFolder, [fileName obj.getProcFileExt] );
        end
        %%-----------------------------------------------------------------

        function fileProcessed = hasFileAlreadyBeenProcessed( obj, filePath )
            filePath = which( filePath ); % ensure absolute path
            currentFolder = obj.getCurrentFolder( filePath );
            fileProcessed = ...
                ~isempty( currentFolder )  && ...
                exist( obj.getOutputFileName( filePath ), 'file' );
        end
        %%-----------------------------------------------------------------
    
        function setExternOutputDependencies( obj, externOutputDeps )
            obj.externOutputDeps = externOutputDeps;
        end
        %%-----------------------------------------------------------------

        function outputDeps = getOutputDependencies( obj )
            outputDeps = obj.getInternOutputDependencies();
            if ~isa( outputDeps, 'struct' )
                error( 'getInternOutputDependencies must combine values in a struct.' );
            end
            if isfield( outputDeps, 'extern' )
                error( 'Intern output dependencies must not contain field of name "extern".' );
            end
            if ~isempty( obj.externOutputDeps )
                outputDeps.extern = obj.externOutputDeps;
            end
        end
        %%-----------------------------------------------------------------

    end
    
    %%---------------------------------------------------------------------
    methods (Access = protected)
        
        function obj = IdProcInterface( procName )
            if nargin < 1,
                objMetaClass = metaclass( obj );
                obj.procName = objMetaClass.Name;
            else
                obj.procName = procName;
            end
            obj.externOutputDeps = [];
        end
        %%-----------------------------------------------------------------
    end
    
    %%---------------------------------------------------------------------
    methods (Access = private)
        
        function saveOutputConfig( obj, configFileName )
            outputDeps = obj.getOutputDependencies();
            save( configFileName, '-struct', 'outputDeps' );
        end
        %%-----------------------------------------------------------------
        
        function currentFolder = getCurrentFolder( obj, filePath )
            filePath = which( filePath ); % ensure absolute path
            [procFolders, configs] = obj.getProcFolders( filePath );
            currentConfig = obj.getOutputDependencies();
            currentFolder = [];
            for ii = 1 : length( configs )
                if isequaln( currentConfig, configs{ii} )
                    currentFolder = procFolders{ii};
                    break;
                end
            end
        end
        %%-----------------------------------------------------------------
        
        function [procFolders, configs] = getProcFolders( obj, filePath )
            filePath = which( filePath ); % ensure absolute path
            fileBaseFolder = fileparts( filePath );
            procFoldersDir = dir( [fileBaseFolder filesep obj.procName '.*'] );
            procFolders = strcat( [fileBaseFolder filesep], {procFoldersDir.name} );
            configs = {};
            for ii = 1 : length( procFolders )
                configs{ii} = obj.readConfig( procFolders{ii} );
            end
        end
        %%-----------------------------------------------------------------
        
        function currentFolder = createCurrentConfigFolder( obj, filePath )
            filePath = which( filePath ); % ensure absolute path
            fileBaseFolder = fileparts( filePath );
            timestr = arrayfun( @num2str, clock(), 'UniformOutput', false );
            timestr = strcat( '.', timestr );
            timestr = [timestr{:}];
            currentFolder = [fileBaseFolder filesep obj.procName timestr];
            mkdir( currentFolder );
            obj.saveOutputConfig( fullfile( currentFolder, 'config.mat' ) );
        end
        %%-----------------------------------------------------------------
        
        function config = readConfig( obj, procFolder )
            persistent preloadedConfigs;
            if isempty( preloadedConfigs )
                preloadedConfigs = containers.Map( 'KeyType', 'char', 'ValueType', 'any' );
            end
            if preloadedConfigs.isKey( procFolder )
                config = preloadedConfigs(procFolder);
            else
                config = load( fullfile( procFolder, 'config.mat' ) );
                preloadedConfigs(procFolder) = config;
            end
        end
        %%-----------------------------------------------------------------
        
        function procFileExt = getProcFileExt( obj )
            procFileExt = ['.' obj.procName '.mat'];
        end
        %%-----------------------------------------------------------------

    end
    
    %%---------------------------------------------------------------------
   methods (Abstract)
       process( obj, inputFileName )
   end
   methods (Abstract, Access = protected)
       outputDeps = getInternOutputDependencies( obj )
       out = getOutput( obj )
   end
    
end
