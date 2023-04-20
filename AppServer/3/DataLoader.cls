 
/*------------------------------------------------------------------------
   File        : DataLoader
   Purpose     : 
   Syntax      : 
   Description : 
   Author(s)   : mario
   Created     : Wed Apr 19 11:23:29 CEST 2023
   Notes       : 
 ----------------------------------------------------------------------*/

USING Progress.Lang.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS DataLoader: 
    {dsDataset.i}

    DEFINE PUBLIC STATIC PROPERTY Instance AS DataLoader NO-UNDO 
        GET():
            IF NOT VALID-OBJECT (DataLoader:Instance) THEN 
            DO:
                DataLoader:Instance = NEW DataLoader().           
            END.
            RETURN DataLoader:Instance. 
        END GET.
        PRIVATE SET. 

    /*------------------------------------------------------------------------------
     Purpose:
     Notes:
    ------------------------------------------------------------------------------*/

    CONSTRUCTOR PRIVATE DataLoader (  ):
        SUPER ().
        
    END CONSTRUCTOR.


    /*------------------------------------------------------------------------------
     Purpose:
     Notes:
    ------------------------------------------------------------------------------*/

    METHOD PUBLIC VOID LoadData(INPUT DATASET dsDataset, OUTPUT DATASET-HANDLE hOutputDataset ):
        
        DEFINE VARIABLE hBufferDB      AS HANDLE    NO-UNDO EXTENT.
        DEFINE VARIABLE hTempTable     AS HANDLE    NO-UNDO EXTENT.
        DEFINE VARIABLE hBufferTT      AS HANDLE    NO-UNDO.
        DEFINE VARIABLE hDataSource    AS HANDLE    NO-UNDO EXTENT.
        DEFINE VARIABLE hQuery         AS HANDLE    NO-UNDO.
        DEFINE VARIABLE iNumBuffers    AS INTEGER   NO-UNDO.
        DEFINE VARIABLE iFieldCounter  AS INTEGER   NO-UNDO.

        DEFINE VARIABLE iEntryChild    AS INTEGER   NO-UNDO.
        DEFINE VARIABLE iEntryParent   AS INTEGER   NO-UNDO.
        DEFINE VARIABLE cTableParent   AS CHARACTER NO-UNDO.
        DEFINE VARIABLE cTableChild    AS CHARACTER NO-UNDO.
        DEFINE VARIABLE cFieldParent   AS CHARACTER NO-UNDO.
        DEFINE VARIABLE cFieldChild    AS CHARACTER NO-UNDO.

        CREATE DATASET hOutputDataset.
        hOutputDataset:SERIALIZE-NAME = "Data".

        FOR EACH ttEntity:
    
            iNumBuffers = iNumBuffers + 1. 
            EXTENT(hBufferDB)   = iNumBuffers.
            EXTENT(hTempTable)  = iNumBuffers.
            EXTENT(hDatasource) = iNumBuffers.
           
            CREATE DATA-SOURCE hDatasource[iNumBuffers].
                                         
            CREATE BUFFER hBufferDB[iNumBuffers] FOR TABLE ttEntity.cName.
    
            CREATE TEMP-TABLE hTempTable[iNumBuffers].
    
            hTempTable[iNumBuffers]:CREATE-LIKE (hBufferDB[iNumBuffers]).
    
            hTempTable[iNumBuffers]:TEMP-TABLE-PREPARE (ttEntity.cName).
   
            hBufferTT = hTempTable[iNumBuffers]:DEFAULT-BUFFER-HANDLE.
    
            IF ttEntity.cFields <> "*" AND ttEntity.cFields > "" THEN
            DO:
                DO iFieldCounter = 1 TO hBufferTT:NUM-FIELDS: 
                    hBufferTT:BUFFER-FIELD(iFieldCounter):SERIALIZE-HIDDEN = 
                        NOT (LOOKUP(hBufferTT:BUFFER-FIELD(iFieldCounter):NAME,ttEntity.cFields) > 0).
                END.       
            END.
            hOutputDataset:ADD-BUFFER(hBufferTT).
          
            IF iNumBuffers = 1 THEN 
            DO:                                   
                CREATE QUERY hQuery.
                hQuery:SET-BUFFERS (hBufferDB[iNumBuffers]).
                hQuery:QUERY-PREPARE (SUBSTITUTE("FOR EACH &1 &2 &3",
                                      hBufferDB[iNumBuffers]:NAME,
                                     (IF ttEntity.cFilter > "" THEN "WHERE" ELSE ""),
                                      ttEntity.cFilter)).
                              
                hDatasource[iNumBuffers]:QUERY = hQuery.
        
                hBufferTT:ATTACH-DATA-SOURCE (hDatasource[iNumBuffers]).                
            END.
            ELSE  
            DO:      
                IF TRIM(ENTRY(1,ENTRY(2,ttEntity.cFilter,"="),".")) = ttEntity.cName THEN
                    ASSIGN iEntryChild  = 2
                           iEntryParent = 1.
                ELSE
                    ASSIGN iEntryChild  = 1
                           iEntryParent = 2.
                ASSIGN
                    cTableParent = TRIM(ENTRY(1,ENTRY(iEntryParent,ttEntity.cFilter,"="),"."))
                    cFieldParent = TRIM(ENTRY(2,ENTRY(iEntryParent,ttEntity.cFilter,"="),"."))
                    cTableChild  = TRIM(ENTRY(1,ENTRY(iEntryChild,ttEntity.cFilter,"="),"."))
                    cFieldChild  = TRIM(ENTRY(2,ENTRY(iEntryChild,ttEntity.cFilter,"="),"."))
                    . 
        
                hOutputDataset:ADD-RELATION(hOutputDataset:GET-BUFFER-HANDLE(1),
                                            hOutputDataset:GET-BUFFER-HANDLE(iNumBuffers),
                                            cFieldParent + "," + cFieldChild,?,TRUE).

                hDataSource[iNumBuffers]:ADD-SOURCE-BUFFER(hBufferDB[iNumBuffers],cFieldParent + "," + cFieldParent).     
          
                hBufferTT:ATTACH-DATA-SOURCE (hDatasource[iNumBuffers]).    
            END.                                                                                                 
    END.

    hOutputDataset:FILL(). 
    
    FINALLY:
        hBufferTT:DETACH-DATA-SOURCE ().
        IF VALID-HANDLE(hOutputDataset) THEN DELETE OBJECT hOutputDataset.
        IF VALID-HANDLE(hBufferDB[iNumBuffers]) THEN DELETE OBJECT hBufferDB[iNumBuffers].
        IF VALID-HANDLE(hDataSource[iNumBuffers]) THEN DELETE OBJECT hDataSource[iNumBuffers].   
        IF VALID-HANDLE(hTempTable[iNumBuffers]) THEN DELETE OBJECT hTempTable[iNumBuffers].       
    END FINALLY.

END METHOD.

END CLASS.