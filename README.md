# logutilforpascal
A log unit to handle 8 severity levels of errors.

The unit defines the 8 standard levels of severity codes from lsDebug to lsEmergency and also some simple aliases from lsLow to lsHigh. It can also handle a field showing the source of error if specified. For all levels, and if needed for all sources separately individual actions can be assigned, like the very basic screen writeln (for debug typically), writing to files, storing in memory (e.g. for displaying through a monitoring window) and sending e-mails.

The folder also has a unit called smtp, what basically wraps in the Indy smtp object. While the logutil is considered complex enough, the smtp is a quick and not fully bullet proof unit. It can be easily replaced if one has a better e-mail sending unit, or if email sending is not required.

The logutil.pas has extensive amount of comments and after the final end. also some examples. Please read them before using.
