(***********************************************************************************************************************************

A complex log file unit.

***

    Eight different levels of severity can be chosen in line with the *nix syslog levels. The acceptable values are stored in an
enumerated type called tLogSeverity with values lsEmergency, lsAlert, lsCritical, lsError, lsWarning, lsNotice, lsInformational and
lsDebug.
    For compatibility reasons some aliases are also set:
        lsDetail = lsNotice
        lsLow = lsWarning
        lsMedium = lsError
        lsHigh = lsCritical
        lsInfo = lsInformational
    Theoretically the same rule set can be set for every severity level, however logically different secerity levels require
different actions, e.g. low severity items are only logged locally, while high severity items are reported through e-mail. This is
reflected in the default values shown later.

***

    The system can handle (1) default output, (2) files, (3) memory strings and (4) e-mails.

        (1) Default output (screen for interactive programs)

        The standard writeln function is used with no specified output. In case of interactive programs it writes to the consol,
while for Daemons (services) the standard way is to send this to the daemon.log.

        (2) Files

        A whole set of files can be used. A filename is composed of three parts, the library, the source (a.k.a. the file name) and
the severity (a.k.a. the extention). In order to reduce the total number of log files, there are shared log files as well.
        The library is normally the same library where the application executable is found, but can be overwritten by setting
LogLibrary to another library, e.g. to '/var/log'. Besides the global parameters separate libraries can be specified on individual
severity levels as well in LogLibraries[]. The process must have write access to the given library/libraries.
        The source (file name) is either the source parameter given when the actual Log() is called or a shared source name, what is
normally the same as the executible name, but can be overwritten by setting LogFilename to something like 'system'.
        The severity (extention) is the log severity given (e.g. 'warning') for individual levels or a shared extention, what is
normally set to 'log', but can be overwritten by setting LogFileExtention and LogFileExtentions.

        (3) String Journals

        There are multiple memory strings to store the latest log items. There is a global one what can be accessed through
LogJournal and there are individual ones on all severity levels available through LogJournals[].
        The following parameters can be set both for the global and the individual journals. Here the individual values do not
overwrite the global value, but always the correct one is used, e.g. LogJournalSize for LogJournal and LogJournalSizes[lsError] fo
LogJournals[lsError]:
            LogJournalSize        : integer (default value 50)
            LogJournalLatestFirst : boolean (default true)

        (4) Emails

        For e-mail sending the server, the sender and the recepients (To, Cc, Bcc) can be set, both on a global and on individual
severity levels. The email server related parameters can be set through LogEmail... and LogEmail...[tLogSeverity] variables as
follows.
        If a value is set on an individual level, it overwrites (does not append!) the global setting. If on an individual level a
value is not set (value = ''), then the global value is used. If on an individual level a value is to be overwritten to '' then the
value must be set to ' '. This can be important, e.g. when the email server is different on the global level and on one particular
severity level and the global requires authentication (i.e. it is set) and the latter does not. Setting LogEmailAuthenticationUsers
to '' on the individual level would mean that the global LogEmailAuthenticationUser is used, probably creating an error.
        The follwoing email related variables can be set both on global and individual levels:
            The server related parameters (all string):
                LogEmailSmtpAddress
                LogEmailSmtpPort (default '587')
                LogEmailAuthUser
                LogEmailAuthPassword
            The sender related parameters (all string):
                LogEmailFromName
                LogEmailFromAddress
            The address related parameters (all string, if needed with ; separator):
                LogEmailToAddress
                LogEmailCcAddress
                LogEmailBccAddress
            A parameter to include a timestamp in the subject of the e-mail (string value, where only 'false' means false, all other
are considered true:
                LogEmailUseTimeStampInSubject
            A parameter to specify where the content of the email shall be taken from. The parameter is a pointer
(tLogEmailContentProcedure), so the non-overwriting value is not '' but nil. If both the global and the individual level pointers
are nil (default value) then first the individual LogJournals[] is used, but if that is also empty then the global LogJournal is
used.
                LogEmailContentProcedure

***

    There are two more time related parameter sets (also on global and individual levels).
        LogDateTimeFormat(s) : string; specifies the format used when the timestamp is added
        LogNowProcedure(s) : tLogNowProcedure; to overwrite the system clock (e.g. when a test run is executed)

***

    There is one more global level parameter used to allocate a severity to a Log() item if it is not given explcitely. Originally
it is set to lsWarning, but can be overwritten. The type of it is tLogSeverity:
        LogDefaultSeverity

***

    The operation of the log system can be set through another set of boolean parameters, that can be set only on individual
levels. The list shown next to each parameter shows the default values (T=true, F=false) from lsEmergency to lsDebug.
        LogActive[] (TTTTTTTT)                  - the most important switch to allow or deny the use of actions of a severity level
        LogWriteToDefault[] (FFFFFFFT)          - use it only if really needed, not to "spam" Daemon.log for a service
        LogSaveInSourceSeverity[] (FFFFFTTF)    - like <source>.<severity>
        LogSaveInSourceShared[] (FFFFFFFF)      - like <source>.<LogSharedExtention>
        LogSaveInSharedSeverity[] (TFFFFFFF)    - like <LogSharedFilename>.<severity>
        LogSaveInSharedShared[] (TTTTTFFF)      - like <LogSharedFileName>.<LogSharedExtention>
        LogStoreInShared[] (TTTTFFFF)           - the global stringlist
        LogStoreInSeverity[] (FFFFFFFF)         - the individual stringlists
        LogSendEmail[] (TTTFFFFF)               - assuming the email is parameterised on global or individual level

    The Log() can be called four different ways:
        Log(Severity, Source, Message);  full set, all functionality as per the above parameters
        Log(Severity, Message);          no source, source specific files are not used even if set
        Log(Source, Message);            using the LogDefaultSeverity parameter
        Log(Message);                    as above, no source and using the default severity

***

    There is a mechanism to do a periodic Log entry in any severity level.
        The instructions to create/start and stop/destroy the periodic log mechanism are:
            function LogCreatePeriodic(aSeverity : tLogSeverity; aFrequency : integer; aSource : string = '') : Pointer;
            function LogCreatePeriodic(aFrequency : integer; aSource : string= '') : Pointer;
            function LogCreatePeriodic(aSeverity : tLogSeverity; aSource : string = '') : Pointer;
            function LogCreatePeriodic(aSource : string = '') : Pointer;
            procedure LogDestroyPeriodic(aTimer : Pointer);
        The Severity used if not specified is the same as LogDefaultSeverity
        The Frequency has a default of 3600s (1h)
        The Source has no default (i.e. empty if not specified)
        The Message of the log item is in LogDefaultPeriodicMessage (default: 'Periodic update')

***

   The DEFAULT setting is based on the following logic (but again, all these can be overwritten as written above):

       Normally all severity levels are active, i.e. any of them is given, the underlying action is performed.

       The defaults of the different severity levels is given with the following logic:

           lsDebug : Only writes the message to the screen. Use it only for interactive debugging and switch off its activation in a
production system.
           lsInformational : Only writes to a <source>.informational file. Use it for very detailed information, typically in a
testing phase, when the system is already working in its final form (e.g. daemon), but certain inforamtion is still closely
monitored. Switch it off, later, when the system is stable. If source is not specified, it is omitted.
           lsNotice : Technically set as the same as lsInformational. The practical difference is that it can be kept switched on
when the program is already in a stable phase, but certain detailed data is collected (and probably deleted or analysed separately).
           lsWarning : From lsWarning upwards, all Log items are to be stored in the main, shared log file <executable name>.log as
default. This is the main log file.
           lsError : From lsError upwards, all Log items are stored in the global LogJournal. It can be used as the body of the
e-mails.
           lsCritical : If e-mail parameters are set, in addition an e-mail is also sent. Despite its name, it can be for
information only, e.g. regular operational updates.
           lsAlert : Technically the same as lsCritical, but typically can have more e-mail addresses added for quicker response.
Use it when some action should be done by the main responsible for the system.
           lsEmergency : Still almost the same as lsCritical and lsAlert, and again typically more e-mail addresses can be added for
quicker response. In addition a separate <executable name>.emergancy file is created for quick identification of the error. Typical
usecase means that all possible e-mail addresses are used to get the message to someone capable dealing with the problem asap.

***
    Change log
        2021.01.05 Created
        2021.01.13 Periodic log added

***********************************************************************************************************************************)

unit logutil;

{$mode objfpc}{$H+}

interface

uses
  {$IFDEF UNIX} cthreads, {$ENDIF}
  Classes, SysUtils,
  smtp;

type
  tLogSeverity                     = (lsEmergency, lsAlert, lsCritical, lsError, lsWarning, lsNotice, lsInformational, lsDebug);
  tLogEmailContentProcedure        = procedure(var aContent:string; var aUseHTML:boolean);
  tLogNowProcedure                 = procedure(var aNow : tDateTime);
  tLogIntegers                     = array[tLogSeverity] of integer;
  tLogBooleans                     = array[tLogSeverity] of boolean;
  tLogStrings                      = array[tLogSeverity] of string;
  tLogEmailContentProcedures       = array[tLogSeverity] of tLogEmailContentProcedure;
  tLogNowProcedures                = array[tLogSeverity] of tLogNowProcedure;

const
  lsDetail = lsNotice;
  lsLow = lsWarning;
  lsMedium = lsError;
  lsHigh = lsCritical;
  lsInfo = lsInformational;

const // DO NOT OVERWRITE IT, EVEN IF IT CAN BE OVERWRITTEN
  LOG_DEFAULT_FILE_EXTENTION          = 'log';
  LOG_DEFAULT_FILE_EXTENTIONS         : tLogStrings  = ('emergency', 'alert', 'critical', 'error', 'warning', 'notice',
      'informational', 'debug');
  LOG_DEFAULT_JOURNAL_SIZE            = 50;
  LOG_DEFAULT_JOURNAL_LATEST_FIRST    = true;
  LOG_DEFAULT_SMTP_PORT               = '587';
  LOG_DEFAULT_DATETIME_FORMAT         = 'yyyy/MM/dd hh:mm:ss.zzz ';
  LOG_DEFAULT_SEVERITY                = lsWarning;
  LOG_TRUE_ARRAY                      : tLogBooleans = (true, true, true, true, true, true, true, true);
  LOG_FALSE_ARRAY                     : tLogBooleans = (false, false, false, false, false, false, false, false);
  LOG_DEFAULT_ACTIVE                  : tLogBooleans = (true, true, true, true, true, true, true, true);
  LOG_DEFAULT_WRITE_TO_DEFAULT        : tLogBooleans = (false, false, false, false, false, false, false, true);
  LOG_DEFAULT_SAVE_IN_SOURCE_SEVERITY : tLogBooleans = (false, false, false, false, false, true, true, false);
  LOG_DEFAULT_SAVE_IN_SOURCE_SHARED   : tLogBooleans = (false, false, false, false, false, false, false, false);
  LOG_DEFAULT_SAVE_IN_SHARED_SEVERITY : tLogBooleans = (true, false, false, false, false, false, false, false);
  LOG_DEFAULT_SAVE_IN_SHARED_SHARED   : tLogBooleans = (true, true, true, true, true, false, false, false);
  LOG_DEFAULT_STORE_IN_SHARED         : tLogBooleans = (true, true, true, true, false, false, false, false);
  LOG_DEFAULT_STORE_IN_SEVERITY       : tLogBooleans = (false, false, false, false, false, false, false, false);
  LOG_DEFAULT_SEND_EMAIL              : tLogBooleans = (true, true, true, false, false, false, false, false);
  LOG_DEFAULT_PERIODIC_PERIOD         = 3600;
  LOG_DEFAULT_PERIODIC_MESSAGE        = 'Periodic update';

var // THESE ARE THE VARIABLES TO BE OVERWRITTEN
  // only on global level
  LogSharedFilename              : string = ''; // set in the initialization section
  LogDefaultSeverity             : tLogSeverity = LOG_DEFAULT_SEVERITY;
  LogDefaultPeriodicMessage      : string = LOG_DEFAULT_PERIODIC_MESSAGE;

  // both on global and on individual severity levels
  LogFileLibrary                 : string = '';
  LogFileExtention               : string = LOG_DEFAULT_FILE_EXTENTION;
  LogJournal                     : string = '';
  LogJournalSize                 : integer = LOG_DEFAULT_JOURNAL_SIZE;
  LogJournalLatestFirst          : boolean = LOG_DEFAULT_JOURNAL_LATEST_FIRST;
  LogEmailSmtpAddress            : string = '';
  LogEmailSmtpPort               : string = LOG_DEFAULT_SMTP_PORT;
  LogEmailAuthUser               : string = '';
  LogEmailAuthPassword           : string = '';
  LogEmailFromName               : string = '';
  LogEmailFromAddress            : string = '';
  LogEmailToAddress              : string = '';
  LogEmailCcAddress              : string = '';
  LogEmailBccAddress             : string = '';
  LogEmailUseTimeStampInSubject  : string = ''; // considered true as only 'false' overwrites it
  LogEmailContentProcedure       : tLogEmailContentProcedure = nil;
  LogDateTimeFormat              : string = LOG_DEFAULT_DATETIME_FORMAT;
  LogNowProcedure                : tLogNowProcedure = nil;

  LogFileLibraries               : tLogStrings = ('', '', '', '', '', '', '', '');
  LogFileExtentions              : tLogStrings = ('', '', '', '', '', '', '', '');
  LogJournals                    : tLogStrings = ('', '', '', '', '', '', '', '');
  LogJournalSizes                : tLogIntegers = (LOG_DEFAULT_JOURNAL_SIZE, LOG_DEFAULT_JOURNAL_SIZE, LOG_DEFAULT_JOURNAL_SIZE,
      LOG_DEFAULT_JOURNAL_SIZE, LOG_DEFAULT_JOURNAL_SIZE, LOG_DEFAULT_JOURNAL_SIZE, LOG_DEFAULT_JOURNAL_SIZE,
      LOG_DEFAULT_JOURNAL_SIZE);
  LogJournalLatestFirsts         : tLogBooleans = (LOG_DEFAULT_JOURNAL_LATEST_FIRST, LOG_DEFAULT_JOURNAL_LATEST_FIRST,
      LOG_DEFAULT_JOURNAL_LATEST_FIRST, LOG_DEFAULT_JOURNAL_LATEST_FIRST, LOG_DEFAULT_JOURNAL_LATEST_FIRST,
      LOG_DEFAULT_JOURNAL_LATEST_FIRST, LOG_DEFAULT_JOURNAL_LATEST_FIRST, LOG_DEFAULT_JOURNAL_LATEST_FIRST);
  LogEmailSmtpAddresses          : tLogStrings = ('', '', '', '', '', '', '', '');
  LogEmailSmtpPorts              : tLogStrings = ('', '', '', '', '', '', '', '');
  LogEmailAuthUsers              : tLogStrings = ('', '', '', '', '', '', '', '');
  LogEmailAuthPasswords          : tLogStrings = ('', '', '', '', '', '', '', '');
  LogEmailFromNames              : tLogStrings = ('', '', '', '', '', '', '', '');
  LogEmailFromAddresses          : tLogStrings = ('', '', '', '', '', '', '', '');
  LogEmailToAddresses            : tLogStrings = ('', '', '', '', '', '', '', '');
  LogEmailCcAddresses            : tLogStrings = ('', '', '', '', '', '', '', '');
  LogEmailBccAddresses           : tLogStrings = ('', '', '', '', '', '', '', '');
  LogEmailUseTimeStampInSubjects : tLogStrings = ('', '', '', '', '', '', '', '');
  LogEmailContentProcedures      : tLogEmailContentProcedures = (nil, nil, nil, nil, nil, nil, nil, nil);
  LogDateTimeFormats             : tLogStrings = ('', '', '', '', '', '', '', '');
  LogNowProcedures               : tLogNowProcedures = (nil, nil, nil, nil, nil, nil, nil, nil);

  // only on individual severity levels
  LogActive                      : tLogBooleans;
  LogWriteToDefault              : tLogBooleans;
  LogSaveInSourceSeverity        : tLogBooleans;
  LogSaveInSourceShared          : tLogBooleans;
  LogSaveInSharedSeverity        : tLogBooleans;
  LogSaveInSharedShared          : tLogBooleans;
  LogStoreInShared               : tLogBooleans;
  LogStoreInSeverity             : tLogBooleans;
  LogSendEmail                   : tLogBooleans;

procedure Log(aSeverity : tLogSeverity; aSource : string; aMessage : string);
procedure Log(aSeverity : tLogSeverity; aMessage : string);
procedure Log(aSource : string; aMessage : string);
procedure Log(aMessage : string);
function LogCreatePeriodic(aSeverity : tLogSeverity; aFrequency : integer; aSource : string = '') : Pointer;
function LogCreatePeriodic(aFrequency : integer; aSource : string= '') : Pointer;
function LogCreatePeriodic(aSeverity : tLogSeverity; aSource : string = '') : Pointer;
function LogCreatePeriodic(aSource : string = '') : Pointer;
procedure LogDestroyPeriodic(aTimer : Pointer);

implementation

uses
  fptimer;

type
  tLogFileStreams = array[tLogSeverity] of tFileStream;

const
  CRLF = #13#10;

var
  FileSeverityName    : string = '';
  FileSharedName      : string = '';
  FileSeverityNames   : tLogStrings = ('', '', '', '', '', '', '', '');
  FileSharedNames     : tLogStrings = ('', '', '', '', '', '', '', '');
  FileSeverityHandle  : tFileStream = nil;
  FileSharedHandle    : tFileStream = nil;
  FileSeverityHandles : tLogFileStreams = (nil, nil, nil, nil, nil, nil, nil, nil);
  FileSharedHandles   : tLogFileStreams = (nil, nil, nil, nil, nil, nil, nil, nil);
  CS                  : tRTLCriticalSection;

function GetNow(aSeverity : tLogSeverity) : string;
  var
    NowProcedure : tLogNowProcedure;
    NowFormat : string;
    NowDT : tDateTime;
  begin
  nowDT := Now;
  if assigned(LogNowProcedures[aSeverity]) then
    NowProcedure := LogNowProcedures[aSeverity]
  else
    NowProcedure := LogNowProcedure;
  if assigned(NowProcedure) then
    NowProcedure(NowDT);
  if LogDateTimeFormats[aSeverity] <> '' then
    NowFormat := LogDateTimeFormats[aSeverity]
  else
    NowFormat := LogDateTimeFormat;
  result := AnsiString(FormatDateTime(NowFormat, NowDT))
  end;

procedure WriteToDefault(aSeverity : tLogSeverity; aSource : string; aMessage : string; aNow : string);
  var
    Entry : string;
  begin
  if not LogWriteToDefault[aSeverity] then
    exit;
  if aSource = '' then
    Entry := aNow + aMessage
  else
    Entry := aNow + '[' + aSource + '] ' + aMessage;
  Writeln(Entry);
  end;

procedure CloseFileStream(var aHandle : tFileStream);
  begin
  if assigned(aHandle) then
    FreeAndNil(aHandle);
  end;
procedure CloseFileStreams;
  var
    Severity : tLogSeverity;
  begin
  CloseFileStream(FileSeverityHandle);
  CloseFileStream(FileSharedHandle);
  for Severity in tLogSeverity do
    begin
    CloseFileStream(FileSeverityHandles[Severity]);
    CloseFileStream(FileSharedHandles[Severity]);
    end;
  end;
procedure OpenFileStream(aNewFileName : string; var aOldFileName : string; var aHandle : tFileStream);
  begin
  if (aNewFileName = aOldFileName) and assigned(aHandle) then
    exit;
  try
    begin
    try
      CloseFileStream(aHandle);
      aHandle:=tFileStream.Create(aNewFileName, fmOpenReadWrite or fmShareDenyWrite);
      aHandle.Seek(0,soFromEnd);
    except
      aHandle:=tFileStream.Create(aNewFileName,fmCreate or fmShareDenyWrite);
      end;
    end
  except
    aHandle := nil;
    end;
  if assigned(aHandle) then
    aOldFileName := aNewFileName
  else
    aOldFileName := '';
  end;
function GetFileLibrary(aSeverity : tLogSeverity) : string;
  begin
  result := LogFileLibrary;
  if LogFileLibraries[aSeverity] <> '' then
    result := LogFileLibraries[aSeverity];
  if result = '' then
    result := '.';
  if result[result.Length] <> '/' then
    result := result + '/';
  end;
function GetFileLibrary(aLibrary : string) : string;
  begin
  result := aLibrary;
  if result = '' then
    result := '.';
  if result[result.Length] <> '/' then
    result := result + '/';
  end;
function GetFileName(aFileName : string) : string;
  begin
  result := Trim(aFileName);
  if (result.length>0) and (result[result.length] = '/') then
    SetLength(result, result.length -1);
  while Pos('/', result) > 0 do
    result := Copy(result, Pos('/', result) + 1);
  if result[result.Length] <> '.' then
    result := result + '.';
  end;
procedure WriteToFile(aFileName : string; var aOldFileName : string; var aFileHandle : tFileStream; aEntry : string);
  begin
  try
    OpenFileStream(aFileName, aOldFileName, aFileHandle);
    aFileHandle.Write(aEntry[1],aEntry.Length);
  except
    end;
  end;
procedure WriteToFile(aSeverity : tLogSeverity; aSource : string; aMessage : string; aNow : string);
  var
    Entry : string;
    FileName : string;
  begin
  try
    if ((aSource = '') or (not LogSaveInSourceSeverity[aSeverity])) and
       ((aSource = '') or (not LogSaveInSourceShared[aSeverity])) and
       (not LogSaveInSharedSeverity[aSeverity]) and
       (not LogSaveInSharedShared[aSeverity]) then
      exit;
    Entry := aNow + aMessage + CRLF;
    if (aSource <> '') and LogSaveInSourceSeverity[aSeverity] then
      begin
      FileName := GetFileLibrary(aSeverity) + GetFileName(aSource) + LogFileExtentions[aSeverity];
      WriteToFile(FileName, FileSeverityNames[aSeverity], FileSeverityHandles[aSeverity], Entry);
      end;
    if (aSource <> '') and LogSaveInSourceShared[aSeverity] then
      begin
      FileName := GetFileLibrary(aSeverity) + GetFileName(aSource) + LogFileExtention;
      WriteToFile(FileName, FileSharedNames[aSeverity], FileSharedHandles[aSeverity], Entry);
      end;
    if aSource <> '' then
      Entry := aNow + '[' + aSource + '] ' + aMessage + CRLF;
    if LogSaveInSharedSeverity[aSeverity] then
      begin
      FileName := GetFileLibrary(LogFileLibrary) + GetFileName(LogSharedFileName) + LogFileExtentions[aSeverity];
      WriteToFile(FileName, FileSeverityName, FileSeverityHandle, Entry);
      end;
    if LogSaveInSharedShared[aSeverity] then
      begin
      FileName := GetFileLibrary(LogFileLibrary) + GetFileName(LogSharedFileName) + LogFileExtention;
      WriteToFile(FileName, FileSharedName, FileSharedHandle, Entry);
      end;
  except
    end;
  end;

procedure AddToJournal(var aJournal : string; aMaxSize : integer; aLatestFirst : boolean; aEntry : string);
  var
    Journal : tStringList;
  begin
  Journal := tStringList.Create;
  Journal.Text := aJournal;
  if aLatestFirst then
    Journal.Insert(0, aEntry)
  else
    Journal.Add(aEntry);
  while Journal.Count > aMaxSize do
    begin
    if aLatestFirst then
      Journal.Delete(aMaxSize)
    else
      Journal.Delete(0);
    end;
  aJournal := Journal.Text;
  Journal.Free;
  end;
procedure WriteToJournal(aSeverity : tLogSeverity; aEntry : string);
  begin
  AddToJournal(LogJournals[aSeverity], LogJournalSizes[aSeverity], LogJournalLatestFirsts[aSeverity], aEntry);
  end;
procedure WriteToJournal(aEntry : string);
  begin
  AddToJournal(LogJournal, LogJournalSize, LogJournalLatestFirst, aEntry);
  end;
procedure WriteToJournal(aSeverity : tLogSeverity; aSource : string; aMessage : string; aNow : string);
  var
    Entry : string;
  begin
  if (not LogStoreInSeverity[aSeverity]) and
     (not LogStoreInShared[aSeverity]) then
    exit;
  Entry := aNow + aMessage;
  if LogStoreInSeverity[aSeverity] then
    begin
    WriteToJournal(aSeverity, Entry);
    end;
  if aSource <> '' then
    Entry := aNow + '[' + aSource + '] ' + aMessage;
  if LogStoreInShared[aSeverity] then
    begin
    WriteToJournal(Entry);
    end;
  end;

procedure SendEmail(aSeverity : tLogSeverity; aSource : string; aMessage : string; aNow : string);
  var
    SmtpAddress            : string = '';
    SmtpPort               : string = LOG_DEFAULT_SMTP_PORT;
    AuthUser               : string = '';
    AuthPassword           : string = '';
    FromName               : string = '';
    FromAddress            : string = '';
    ToAddress              : string = '';
    CcAddress              : string = '';
    BccAddress             : string = '';
    UseTimeStampInSubject  : string = '';
    ContentProcedure       : tLogEmailContentProcedure = nil;
    Subject : string = '';
    Body : string = '';
    UseHtml : boolean = false;
  begin
  if not LogSendEmail[aSeverity] then
    exit;
  if LogEmailSmtpAddresses[aSeverity] <> '' then
    SmtpAddress := LogEmailSmtpAddresses[aSeverity]
  else
    SmtpAddress := LogEmailSmtpAddress;
  if SmtpAddress = ' ' then
    SmtpAddress := '';
  if SmtpAddress = '' then
    exit; // no smtp address, no email can be sent
  if LogEmailSmtpPorts[aSeverity] <> '' then
    SmtpPort := LogEmailSmtpPorts[aSeverity]
  else
    SmtpPort := LogEmailSmtpPort;
  if SmtpPort = ' ' then
    SmtpPort := '';
  if SmtpPort = '' then
    exit; // no smtp port, no email can be sent
  if LogEmailAuthUsers[aSeverity] <> '' then
    AuthUser := LogEmailAuthUsers[aSeverity]
  else
    AuthUser := LogEmailAuthUser;
  if AuthUser = ' ' then
    AuthUser := '';
  if LogEmailAuthPasswords[aSeverity] <> '' then
    AuthPassword := LogEmailAuthPasswords[aSeverity]
  else
    AuthPassword := LogEmailAuthPassword;
  if AuthPassword = ' ' then
    AuthPassword := '';
  if LogEmailFromNames[aSeverity] <> '' then
    FromName := LogEmailFromNames[aSeverity]
  else
    FromName := LogEmailFromName;
  if FromName = ' ' then
    FromName := '';
  if LogEmailFromAddresses[aSeverity] <> '' then
    FromAddress := LogEmailFromAddresses[aSeverity]
  else
    FromAddress := LogEmailFromAddress;
  if FromAddress = ' ' then
    FromAddress := '';
  if FromAddress = '' then
    exit;
  if LogEmailToAddresses[aSeverity] <> '' then
    ToAddress := LogEmailToAddresses[aSeverity]
  else
    ToAddress := LogEmailToAddress;
  if ToAddress = ' ' then
    ToAddress := '';
  if LogEmailCcAddresses[aSeverity] <> '' then
    CcAddress := LogEmailCcAddresses[aSeverity]
  else
    CcAddress := LogEmailCcAddress;
  if CcAddress = ' ' then
    CcAddress := '';
  if LogEmailBccAddresses[aSeverity] <> '' then
    BccAddress := LogEmailBccAddresses[aSeverity]
  else
    BccAddress := LogEmailBccAddress;
  if BccAddress = ' ' then
    BccAddress := '';
  if (ToAddress = '') and (CcAddress = '') and (BccAddress = '') then
    exit;
  if LogEmailUseTimeStampInSubjects[aSeverity] <> '' then
    UseTimeStampInSubject := LogEmailUseTimeStampInSubjects[aSeverity]
  else
    UseTimeStampInSubject := LogEmailUseTimeStampInSubject;
  if LogEmailContentProcedures[aSeverity] <> nil then
    ContentProcedure := LogEmailContentProcedures[aSeverity]
  else
    ContentProcedure := LogEmailContentProcedure;
  if aSource = '' then
    Subject := aMessage
  else
    Subject := '[' + aSource + '] ' + aMessage;
  if UseTimeStampInSubject <> 'false' then
    Subject := aNow + Subject;
  if assigned(ContentProcedure) then
    ContentProcedure(Body, UseHtml)
  else
    begin
    Body := LogJournals[aSeverity];
    if Body = '' then // if the ContentProcedure gives empty Body, that is intentionally not overwritten
      Body := LogJournal;
    end;
  try
    SendSimpleMail(FromName, FromAddress, ToAddress, CcAddress, BccAddress, SmtpAddress, SmtpPort.ToInteger, AuthUser, AuthPassword,
        Subject, Body, UseHtml);
  finally
    end;
  end;

procedure Log(aSeverity : tLogSeverity; aSource : string; aMessage : string);
  var
    NowDT : string;
  begin
  EnterCriticalSection(CS);
  try
    if LogActive[aSeverity] then
      begin
      NowDT := GetNow(aSeverity);
      WriteToDefault(aSeverity, aSource, aMessage, NowDT);
      WriteToFile(aSeverity, aSource, aMessage, NowDT);
      WriteToJournal(aSeverity, aSource, aMessage, NowDT);
      SendEmail(aSeverity, aSource, aMessage, NowDT);
      end;
  finally
    LeaveCriticalSection(CS);
    end;
  end;
procedure Log(aSeverity : tLogSeverity; aMessage : string);
  begin
  Log(aSeverity, '', aMessage);
  end;
procedure Log(aSource : string; aMessage : string);
  begin
  Log(LogDefaultSeverity, aSource, aMessage);
  end;
procedure Log(aMessage : string);
  begin
  Log(LogDefaultSeverity, '', aMessage);
  end;

type
  tThreadParams = record
    Severity : tLogSeverity;
    Frequency : Integer;
    Source : string;
    Enabled : boolean;
    end;
  pThreadParams = ^tThreadParams;

function PeriodicUpdate(aThreadParams : Pointer) : Int64;
  begin
  with pThreadParams(aThreadParams)^ do
    begin
    Sleep(Frequency * 1000);
    while Enabled do
      begin
      Log(Severity, Source, LogDefaultPeriodicMessage);
      Sleep(Frequency * 1000);
      end;
    end;
  Dispose(pThreadParams(aThreadParams));
  EndThread;
  result := 0;
  end;
function LogCreatePeriodic(aSeverity : tLogSeverity; aFrequency : integer; aSource : string = '') : Pointer;
  var
    ThreadParams : pThreadParams;
  begin
  New(ThreadParams);
  ThreadParams^.Severity := aSeverity;
  ThreadParams^.Frequency := aFrequency;
  ThreadParams^.Source := aSource;
  ThreadParams^.Enabled := true;
  if BeginThread(@PeriodicUpdate, ThreadParams) > 0 then
    result := ThreadParams
  else
    begin
    Dispose(ThreadParams);
    result := nil;
    end;
  end;
function LogCreatePeriodic(aFrequency : integer; aSource : string= '') : Pointer;
  begin
  result := LogCreatePeriodic(LogDefaultSeverity, aFrequency, aSource);
  end;
function LogCreatePeriodic(aSeverity : tLogSeverity; aSource : string = '') : Pointer;
  begin
  result := LogCreatePeriodic(aSeverity, LOG_DEFAULT_PERIODIC_PERIOD, aSource);
  end;
function LogCreatePeriodic(aSource : string = '') : Pointer;
  begin
  result := LogCreatePeriodic(LogDefaultSeverity, LOG_DEFAULT_PERIODIC_PERIOD, aSource);
  end;
procedure LogDestroyPeriodic(aTimer : Pointer);
  begin
  pThreadParams(aTimer)^.Enabled := false;
  end;

initialization
CS.__m_count := 0; // for the compiler
InitCriticalSection(CS);
LogSharedFilename := ParamStr(0);
LogActive := LOG_DEFAULT_ACTIVE;
LogWriteToDefault := LOG_DEFAULT_WRITE_TO_DEFAULT;
LogFileExtentions := LOG_DEFAULT_FILE_EXTENTIONS;
LogSaveInSourceSeverity := LOG_DEFAULT_SAVE_IN_SOURCE_SEVERITY;
LogSaveInSourceShared := LOG_DEFAULT_SAVE_IN_SOURCE_SHARED;
LogSaveInSharedSeverity := LOG_DEFAULT_SAVE_IN_SHARED_SEVERITY;
LogSaveInSharedShared := LOG_DEFAULT_SAVE_IN_SHARED_SHARED;
LogStoreInShared := LOG_DEFAULT_STORE_IN_SHARED;
LogStoreInSeverity := LOG_DEFAULT_STORE_IN_SEVERITY;
LogSendEmail := LOG_DEFAULT_SEND_EMAIL;

finalization
// Periodic timers are not stopped
CloseFileStreams;
DoneCriticalSection(CS);

end.

// Parts can be copied from here to initialise values - It is not part of the unit

// only global
LogSharedFilename := 'system';
LogDefaultSeverity := lsError;
LogDefaultPeriodicMessage := 'Regular update';

// both global and severity
// global
LogFileLibrary := '/var/log';
LogFileExtention := 'log';
LogJournalSize := 100;
LogJournalLatestFirst := false;
LogEmailSmtpAddress := 'smtp.example.com';
LogEmailSmtpPort := '25';
LogEmailAuthUser := 'UserName';
LogEmailAuthPassword := 'UserPassword';
LogEmailFromName := 'My System';
LogEmailFromAddress := 'my.system@example.com';
LogEmailToAddress := 'administrator1@example.com';
LogEmailCcAddress := 'administrator2@example.com';
LogEmailBccAddress := 'administrator3@example.com';
LogEmailUseTimeStampInSubject := 'false';
LogEmailContentProcedure := @MyContentProcedure;
LogDateTimeFormat := 'hh:mm';
LogNowProcedure := @MynowProcedure;
// severity (8 tLogSeverity can be in the [bracket])
LogFileLibraries[lsDebug] := '/var/log';
LogFileExtentions[lsDebug] := 'debug';
LogJournalSizes[lsDebug] := 100;
LogJournalLatestFirsts[lsDebug] := false;
LogEmailSmtpAddresses[lsDebug] := 'smtp.example.com';
LogEmailSmtpPorts[lsDebug] := '25';
LogEmailAuthUsers[lsDebug] := 'UserName';
LogEmailAuthPasswords[lsDebug] := 'UserPassword';
LogEmailFromNames[lsDebug] := 'My System';
LogEmailFromAddresses[lsDebug] := 'my.system@example.com';
LogEmailToAddresses[lsDebug] := 'administrator1@example.com';
LogEmailCcAddresses[lsDebug] := 'administrator2@example.com';
LogEmailBccAddresses[lsDebug] := 'administrator3@example.com';
LogEmailUseTimeStampInSubjects[lsDebug] := 'false';
LogEmailContentProcedures[lsDebug] := @MyContentProcedure;
LogDateTimeFormats[lsDebug] := 'hh:mm';
LogNowProcedures[lsDebug] := @MynowProcedure;

// only severity (8 tLogSeverity can be in the [bracket])
LogActive[lsDebug] := false;
LogSaveInSourceSeverity[lsDebug] := false;
LogSaveInSourceShared[lsDebug] := false;
LogSaveInSharedSeverity[lsDebug] := false;
LogSaveInSharedShared[lsDebug] := false;
LogStoreInShared[lsDebug] := false;
LogStoreInSeverity[lsDebug] := false;
LogSendEmail[lsDebug] := false;
