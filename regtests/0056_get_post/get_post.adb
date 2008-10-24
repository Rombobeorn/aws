------------------------------------------------------------------------------
--                              Ada Web Server                              --
--                                                                          --
--                     Copyright (C) 2003-2008, AdaCore                     --
--                                                                          --
--  This library is free software; you can redistribute it and/or modify    --
--  it under the terms of the GNU General Public License as published by    --
--  the Free Software Foundation; either version 2 of the License, or (at   --
--  your option) any later version.                                         --
--                                                                          --
--  This library is distributed in the hope that it will be useful, but     --
--  WITHOUT ANY WARRANTY; without even the implied warranty of              --
--  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU       --
--  General Public License for more details.                                --
--                                                                          --
--  You should have received a copy of the GNU General Public License       --
--  along with this library; if not, write to the Free Software Foundation, --
--  Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.          --
--                                                                          --
--  As a special exception, if other files instantiate generics from this   --
--  unit, or you link this unit with other files to produce an executable,  --
--  this  unit  does not  by itself cause  the resulting executable to be   --
--  covered by the GNU General Public License. This exception does not      --
--  however invalidate any other reasons why the executable file  might be  --
--  covered by the  GNU Public License.                                     --
------------------------------------------------------------------------------

with Ada.Streams;
with Ada.Text_IO;

with AWS.Client;
with AWS.Messages;
with AWS.MIME;
with AWS.Net.Log;
with AWS.Parameters;
with AWS.Response;
with AWS.Server;
with AWS.Status;
with AWS.Translator;
with AWS.Utils;

with Get_Free_Port;

procedure Get_Post is

   use Ada;
   use Ada.Streams;
   use AWS;

   WS   : Server.HTTP;
   Port : Positive := 8270;

   CRLF : constant String := ASCII.CR & ASCII.LF;

   M_Body : constant String :=
              "BODY_P1=56&BODY_P2=inthebody" & CRLF;

   M2_Body : constant String :=
               "--XXXX" & ASCII.LF
               & "Content-Disposition: form-data; name=""BODY_P1"""
               & ASCII.LF & ASCII.LF
               & "+" & ASCII.LF
               & "--XXXX" & ASCII.LF
               & "Content-Disposition: form-data; name=""BODY_P2"""
               & ASCII.LF & ASCII.LF
               & "%2B" & ASCII.LF
               & "--XXXX--"
               & CRLF;

   M3_Body : constant String :=
               "--XXXX" & CRLF
               & "Content-Disposition: form-data; name=""BODY_P1"""
               & CRLF & CRLF
               & "+" & CRLF
               & "--XXXX" & CRLF
               & "Content-Disposition: form-data; name=""BODY_P2"""
               & CRLF & CRLF
               & "%2B" & CRLF
               & "--XXXX--"
               & CRLF;

   --------
   -- CB --
   --------

   function CB (Request : in Status.Data) return Response.Data is
      Params : constant Parameters.List := Status.Parameters (Request);
   begin
      Text_IO.Put_Line ("P1      >" & Parameters.Get (Params, "P1"));
      Text_IO.Put_Line ("P2      >" & Parameters.Get (Params, "P2"));
      Text_IO.Put_Line ("BODY_P1 >" & Parameters.Get (Params, "BODY_P1"));
      Text_IO.Put_Line ("BODY_P2 >" & Parameters.Get (Params, "BODY_P2"));
      return Response.Build (MIME.Text_HTML, "ok");
   end CB;

   ----------
   -- Dump --
   ----------

   procedure Dump
     (Direction : in Net.Log.Data_Direction;
      Socket    : in Net.Socket_Type'Class;
      Data      : in Stream_Element_Array;
      Last      : in Stream_Element_Offset)
   is
      use type Net.Log.Data_Direction;
   begin
      if Direction = Net.Log.Sent then
         Text_IO.Put_Line
           ("********** " & Net.Log.Data_Direction'Image (Direction));
         Text_IO.Put_Line (Translator.To_String (Data (Data'First .. Last)));
         Text_IO.New_Line;
      end if;
   end Dump;

   R : Response.Data;

begin
   Get_Free_Port (Port);

   Server.Start (WS, "Get Post", CB'Unrestricted_Access, Port => Port);
   Text_IO.Put_Line ("started"); Ada.Text_IO.Flush;

   --  AWS.Net.Log.Start (Dump'Unrestricted_Access);

   R := Client.Post
          ("http://localhost:" & Utils.Image (Port)
           & "/this_uri?P1=12&P2=azerty", M_Body);

   Text_IO.Put_Line (Response.Message_Body (R));

   R := Client.Post
          ("http://localhost:" & Utils.Image (Port)
           & "/this_uri?P1=12&P2=qwerty", M2_Body,
           Content_Type => MIME.Multipart_Form_Data & "; boundary=""XXXX""");

   Text_IO.Put_Line (Response.Message_Body (R));

   R := Client.Post
          ("http://localhost:" & Utils.Image (Port)
           & "/this_uri?P1=29&P2=poiuyt", M3_Body,
           Content_Type => MIME.Multipart_Form_Data & "; boundary=""XXXX""");

   Text_IO.Put_Line (Response.Message_Body (R));

   Server.Shutdown (WS);
   Text_IO.Put_Line ("shutdown");
end Get_Post;
