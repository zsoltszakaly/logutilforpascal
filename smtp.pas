unit smtp;

{$mode objfpc}
{$H+}

interface

 uses
   IdSSLOpenSSLHeaders,
   IdSMTP, IdDNSResolver, IdMessage, IdCoderHeader;

const
  DefaultMailAgent:string='';

type
  tvSMTP = class(tIdSMTP)
    constructor Create(const AServerHost:string; const AServerPort:integer; const AUserName, APassword:string);
    constructor Create(const AHeloName:string; const ADirectPort:integer);
    private
      FSendingModeDirect:boolean;
      FServerHost:string;
      FServerPort:integer;
      FDirectPort:integer;
    private
      function SendSimpleMailDirect(const FromName, FromAddress, ToAddress, CcAddress, BccAddress, Subject, Body:string; const FormatHTML:boolean):integer;
      function SendSimpleMailServer(const FromName, FromAddress, ToAddress, CcAddress, BccAddress, Subject, Body:string; const FormatHTML:boolean):integer;
    public
      function SendSimpleMail(const FromName, FromAddress, ToAddress, CcAddress, BccAddress, Subject, Body:string; const FormatHTML:boolean):integer;
    end;
//old
function SendSimpleMail(aFromName, aFromAddress, aToAddress, aCcAddress, aBccAddress : string;
                     aSMTPServer : string; aSMTPPort : UInt16;
                     aAuthenticationName, aAuthenticationPassword :string;
                     aMessageSubject, aMessageBody : string;
                     aSendHTML : boolean) : integer;
// new
function SendSimpleMail(aFromName, aFromAddress, aToAddress : string;
                     aSMTPServer : string; aSMTPPort : UInt16;
                     aAuthenticationName, aAuthenticationPassword :string;
                     aMessageSubject, aMessageBody : string;
                     aSendHTML : boolean) : integer;


implementation

uses
  SysUtils;

const
  CharacterSetDefault:string='utf-8';
  ContentTypeHTML:string='text/html';
  ContentTypePlain:string='text/plain';
  ContentTransferEncodingDefault:string='quoted-printable';

type
    tvMessage=class(tIdMessage)
      constructor Create(const MailFromName, MailFromAddress, MailToAddress, MailCcAddress, MailBccAddress, MailSubject, MailBody:string; const FormatHTML:boolean);
      end;

function ExtractDomainFromAddress(EMailAddress:string):string;
  begin
  // Cut out the domain
  result:=Copy(EMailAddress,Pos('@',EMailAddress)+1,length(EMailAddress)-Pos('@',EMailAddress));
  end;

function GetOneMX(Domain:string):string;
  var
    Count:     Integer;
    I:         Integer;
  begin
  result:='';
  with tIdDNSResolver.Create(nil) do
    begin
    Host:='8.8.8.8';  // TODO it uses google fixed
    QueryType:=[qtMX];
    Resolve(Domain);
    Count:=QueryResult.Count;
    if Count=0 then
      begin
      Destroy;
      Exit;
      end;
  // TODO this part needs some improvement if there are multiple MX records
    for I:=0 to Count-1 do
      begin
      if QueryResult.Items[I] is TARecord then
        with TARecord(QueryResult[I]) do
          if result='' then result:=IPAddress;
      if QueryResult.Items[I] is TMXRecord then
        with TMXRecord(QueryResult[I]) do
          result:=ExchangeServer;
      end;
    Destroy;
    end;
  end;

constructor tvMessage.Create(const MailFromName, MailFromAddress, MailToAddress, MailCcAddress, MailBccAddress, MailSubject, MailBody:string; const FormatHTML:boolean);
  begin
  inherited Create(nil);
  FBody.Clear;
  FBody.Add(UTF8Encode(MailBody));
  if FormatHTML then
    FContentType:=ContentTypeHTML
  else
    FContentType:=ContentTypePlain;
  FCharSet:=CharacterSetDefault;
  FContentTransferEncoding:=ContentTransferEncodingDefault;
  From.Name:=MailFromName;
  From.Address:=MailFromAddress;
  FRecipients.Clear;
  FRecipients.Add.Address:=MailToAddress;
  FCcList.Clear;
  if MailCcAddress <> '' then
    FCcList.Add.Address:=MailCcAddress;
  FBccList.Clear;
  if MailBccAddress <> '' then
    FBccList.Add.Address:=MailBccAddress;
  Subject := ''; // trick to use utf-8 in subject: https://stackoverflow.com/questions/24651339/indy-message-with-unicode-subject
  ExtraHeaders.Values['Subject'] := EncodeHeader(UTF8Encode(MailSubject), '', 'Q', 'UTF-8');
  MsgId := inttostr(random(1000000000)) + '.'+MailFromAddress;
  end;

function tvSMTP.SendSimpleMailDirect(const FromName, FromAddress, ToAddress, CcAddress, BccAddress, Subject, Body:string; const FormatHTML:boolean):integer;
  var MailToPost:tvMessage;
  begin
  MailToPost:=tvMessage.Create(FromName,FromAddress,ToAddress, CcAddress, BccAddress, Subject, Body, FormatHTML);
  FHost:=GetOneMX(ExtractDomainFromAddress(ToAddress));
  FPort:=FDirectPort;
  try
    Connect;
    Send(MailToPost);
    if Connected then Disconnect;
    result:=0;
  except
    result:=-1;
    end;
  MailToPost.Destroy;
  end;

function tvSMTP.SendSimpleMailServer(const FromName, FromAddress, ToAddress, CcAddress, bccAddress, Subject, Body:string; const FormatHTML:boolean):integer;
  var MailToPost:tvMessage;
  begin
  MailToPost:=tvMessage.Create(FromName,FromAddress,ToAddress,CcAddress,BccAddress,Subject,Body,FormatHTML);
  FHost:=FServerHost;
  FPort:=FServerPort;
  try
    Connect;
    Send(MailToPost);
    if Connected then Disconnect;
    result:=0;
  except
    writeln('Failed to load: ',WhichFailedToLoad);
    result:=-1;
    end;
  MailToPost.Destroy;
  end;


constructor tvSMTP.Create(const AServerHost:string; const AServerPort:integer; const AUserName, APassword:string);
  begin
  inherited Create;
  FSendingModeDirect:=false;
  FServerHost:=AServerHost;
  FServerPort:=AServerPort;
  FUserName:=AUserName;
  FPassword:=APassword;
  end;

constructor tvSMTP.Create(const AHeloName:string; const ADirectPort:integer);
  begin
  inherited Create;
  FSendingModeDirect:=true;
  FHeloName:=AHeloName;
  FDirectPort:=ADirectPort;
  end;

function tvSMTP.SendSimpleMail(const FromName, FromAddress, ToAddress, CcAddress, BccAddress, Subject, Body:string; const FormatHTML:boolean):integer;
  begin
  result:=-1;
  if FSendingModeDirect then
    begin
    if FHeloName='' then exit;                                                  // HeloID is needed
    result:=SendSimpleMailDirect(FromName,FromAddress,ToAddress, CcAddress, BccAddress, Subject,Body,FormatHTML);
    end
  else
    begin
    if FServerHost='' then exit;                                                // A valid Server is needed
    result:=SendSimpleMailServer(FromName,FromAddress,ToAddress,CcAddress,BccAddress,Subject,Body,FormatHTML);
    end;
  end;

function SendSimpleMail(aFromName, aFromAddress, aToAddress, aCcAddress, aBccAddress : string;
                     aSMTPServer : string; aSMTPPort : UInt16;
                     aAuthenticationName, aAuthenticationPassword :string;
                     aMessageSubject, aMessageBody : string;
                     aSendHTML : boolean) : integer;
  var
    Server : tvSMTP;
  begin
  Server := tvSMTP.Create(aSMTPServer, aSMTPPort, aAuthenticationName, aAuthenticationPassword);
  result := Server.SendSimpleMailServer(aFromName, aFromAddress, aToAddress, aCcAddress, aBccAddress, aMessageSubject, aMessageBody, aSendHTML);
  Server.Destroy;
  end;
function SendSimpleMail(aFromName, aFromAddress, aToAddress : string;
                     aSMTPServer : string; aSMTPPort : UInt16;
                     aAuthenticationName, aAuthenticationPassword :string;
                     aMessageSubject, aMessageBody : string;
                     aSendHTML : boolean) : integer;
  begin
  result :=SendSimpleMail(aFromName, aFromAddress, AToAddress, '', '', aSMTPServer, aSMTPPort, aAuthenticationName,
      aAuthenticationPassword, aMessageSubject, aMessageBody, aSendHTML);
  end;

end.

