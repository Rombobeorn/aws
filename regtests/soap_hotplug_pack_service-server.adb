
--  wsdl2aws SOAP Generator v1.4
--
--  AWS 2.1w - SOAP 1.3
--  This file was generated on Sunday 31 October 2004 at 10:58:27
--
--  $ wsdl2aws -f -cvs -cb -types soap_hotplug_pack.ads soap_hotplug_pack.ads.wsdl

--  $Id$

with Ada.Exceptions;

with SOAP.Message.Response.Error;
with SOAP.Parameters;
with SOAP.Utils;

package body SOAP_Hotplug_Pack_Service.Server is

   use Ada.Exceptions;

   use SOAP.Types;
   use type SOAP.Parameters.List;

   pragma Warnings (Off);
   --  Suppress wrong warnings generated by GNAT (fixed in 3.17)

   pragma Style_Checks (Off);

   -------------
   -- Job1_CB --
   -------------

   function Job1_CB
     (SOAPAction : in String;
      Payload    : in SOAP.Message.Payload.Object;
      Request    : in AWS.Status.Data)
      return AWS.Response.Data
   is
      Proc_Name : constant String
        := SOAP.Message.Payload.Procedure_Name (Payload);
      Params    : constant SOAP.Parameters.List
        := SOAP.Message.Parameters (Payload);
      Response  : SOAP.Message.Response.Object;
      R_Params  : SOAP.Parameters.List;
   begin
      if SOAPAction /= "Job1" then
         return SOAP.Message.Response.Build
           (SOAP.Message.Response.Error.Build
              (SOAP.Message.Response.Error.Client,
               "SOAPAction " & SOAPAction & " in Job1, "
                 & "Job1 expected."));
      end if;

      if Proc_Name /= "Job1" then
         return SOAP.Message.Response.Build
           (SOAP.Message.Response.Error.Build
              (SOAP.Message.Response.Error.Client,
               "Found procedure " & Proc_Name & " in Job1, "
                 & "Job1 expected."));
      end if;

      Response := SOAP.Message.Response.From (Payload);

      declare
         X : constant Integer
           := SOAP.Parameters.Get (Params, "X");
         Y : constant Integer
           := SOAP.Parameters.Get (Params, "Y");
         Result : constant Integer
           := Job1
                (X,
                 Y);
      begin
         R_Params :=
           +SOAP.Types.I (Result, "Result");
      end;

      SOAP.Message.Set_Parameters (Response, R_Params);
      return SOAP.Message.Response.Build (Response);
   exception
      when E : SOAP.Types.Data_Error =>
         --  Here we have a problem with some parameters, return a SOAP error
         return SOAP.Message.Response.Build
           (SOAP.Message.Response.Error.Build
              (SOAP.Message.Response.Error.Client,
               "Parameter error in Job1 ("
                 & Exception_Message (E) & ")"));
      when O : others =>
         --  Here we have a problem with user's callback, return a SOAP error
         return SOAP.Message.Response.Build
           (SOAP.Message.Response.Error.Build
              (SOAP.Message.Response.Error.Client,
               "Error in Job1 ("
                 & Exception_Message (O) & ")"));
   end Job1_CB;

   -------------
   -- Job2_CB --
   -------------

   function Job2_CB
     (SOAPAction : in String;
      Payload    : in SOAP.Message.Payload.Object;
      Request    : in AWS.Status.Data)
      return AWS.Response.Data
   is
      Proc_Name : constant String
        := SOAP.Message.Payload.Procedure_Name (Payload);
      Params    : constant SOAP.Parameters.List
        := SOAP.Message.Parameters (Payload);
      Response  : SOAP.Message.Response.Object;
      R_Params  : SOAP.Parameters.List;
   begin
      if SOAPAction /= "Job2" then
         return SOAP.Message.Response.Build
           (SOAP.Message.Response.Error.Build
              (SOAP.Message.Response.Error.Client,
               "SOAPAction " & SOAPAction & " in Job2, "
                 & "Job2 expected."));
      end if;

      if Proc_Name /= "Job2" then
         return SOAP.Message.Response.Build
           (SOAP.Message.Response.Error.Build
              (SOAP.Message.Response.Error.Client,
               "Found procedure " & Proc_Name & " in Job2, "
                 & "Job2 expected."));
      end if;

      Response := SOAP.Message.Response.From (Payload);

      declare
         X : constant Integer
           := SOAP.Parameters.Get (Params, "X");
         Y : constant Integer
           := SOAP.Parameters.Get (Params, "Y");
         Result : constant Integer
           := Job2
                (X,
                 Y);
      begin
         R_Params :=
           +SOAP.Types.I (Result, "Result");
      end;

      SOAP.Message.Set_Parameters (Response, R_Params);
      return SOAP.Message.Response.Build (Response);
   exception
      when E : SOAP.Types.Data_Error =>
         --  Here we have a problem with some parameters, return a SOAP error
         return SOAP.Message.Response.Build
           (SOAP.Message.Response.Error.Build
              (SOAP.Message.Response.Error.Client,
               "Parameter error in Job2 ("
                 & Exception_Message (E) & ")"));
      when O : others =>
         --  Here we have a problem with user's callback, return a SOAP error
         return SOAP.Message.Response.Build
           (SOAP.Message.Response.Error.Build
              (SOAP.Message.Response.Error.Client,
               "Error in Job2 ("
                 & Exception_Message (O) & ")"));
   end Job2_CB;

end SOAP_Hotplug_Pack_Service.Server;
