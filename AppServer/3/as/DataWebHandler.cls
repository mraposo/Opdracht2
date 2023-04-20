 
 /*------------------------------------------------------------------------
    File        : DataWebHandler
    Purpose     : 
    Syntax      : 
    Description : 
    Author(s)   : mario
    Created     : Wed Apr 19 11:11:05 CEST 2023
    Notes       : 
  ----------------------------------------------------------------------*/

USING Progress.Lang.*.
USING OpenEdge.Web.WebResponseWriter.
USING OpenEdge.Net.HTTP.StatusCodeEnum.
USING OpenEdge.Web.WebHandler.
USING Progress.Json.ObjectModel.JsonObject FROM PROPATH.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS AS.DataWebHandler INHERITS WebHandler: 
{dsDataset.i}
    METHOD OVERRIDE PROTECTED INTEGER HandleNotAllowedMethod( INPUT poRequest AS OpenEdge.Web.IWebRequest ):
        
        UNDO, THROW NEW Progress.Lang.AppError("METHOD NOT IMPLEMENTED").

    END METHOD.

    METHOD OVERRIDE PROTECTED INTEGER HandleNotImplemented( INPUT poRequest AS OpenEdge.Web.IWebRequest ):
        
        UNDO, THROW NEW Progress.Lang.AppError("METHOD NOT IMPLEMENTED").

    END METHOD.

    
    
    /*------------------------------------------------------------------------------
            Purpose: Default handler for the HTTP GET method. The request being 
                     serviced and an optional status code is returned. A zero or 
                     null value means this method will deal with all errors.                                                               
            Notes:                                                                        
    ------------------------------------------------------------------------------*/
     METHOD OVERRIDE PROTECTED INTEGER HandleGet( INPUT poRequest AS OpenEdge.Web.IWebRequest ):
     
    
        DEFINE VARIABLE oResponse AS OpenEdge.Net.HTTP.IHttpResponse NO-UNDO.
        DEFINE VARIABLE oWriter   AS OpenEdge.Web.WebResponseWriter  NO-UNDO.
        DEFINE VARIABLE oBody     AS OpenEdge.Core.String            NO-UNDO.
        
        DEFINE VARIABLE hOutputDataset AS HANDLE NO-UNDO.
            
        /* The WebResponse body is a wrapper around an entire HTTP response message.
           It contains a status code and reason; headers; cookies and a message body.
           
           API-level doc for this and related classes can be found at
           https://documentation.progress.com/output/oehttpclient/      */
        
        IF TYPE-OF(poRequest:Entity,JsonObject) THEN DO:
            DATASET dsDataset:READ-JSON("JsonObject",CAST(poRequest:Entity,JsonObject),"EMPTY").       
         END.
        
        DataLoader:Instance:LoadData(INPUT DATASET dsDataset, OUTPUT DATASET-HANDLE hOutputDataset).
        
        
        
        ASSIGN 
            oResponse              = NEW OpenEdge.Web.WebResponse()
            oResponse:StatusCode   = INTEGER(StatusCodeEnum:OK)
            oResponse:ContentType  = 'application/json':u
            .

        
        /* The WebResponseWriter ensures that the status line and
           all headers are writted out before the message body/entity. */
        ASSIGN 
            oWriter = NEW WebResponseWriter(oResponse).
       
        oWriter:Open().
        oWriter:Flush().
        
        hOutputDataset:WRITE-JSON("STREAM-HANDLE",oWriter:WebStream).
        
        
        /* Finish writing the response message */
        oWriter:Close().
        
        /* A response of 0 means that this handler will build the entire response;
           a non-zero value is mapped to a static handler in the webapp's /static/error folder.
           The mappings are maintained in the webapps's WEB-INF/web.xml 
           A predefined set of HTTP status codes is provided in the OpenEdge.Net.HTTP.StatusCodeEnum 
           enumeration */
        RETURN 0.
        
        FINALLY:
           IF VALID-HANDLE(hOutputDataset) THEN DELETE OBJECT hOutputDataset.    
        END FINALLY.
        
     END METHOD. 
  
END CLASS.