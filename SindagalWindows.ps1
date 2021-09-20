Start-Process powershell -ExecutionPolicy Bypass -Verb runas -ArgumentList "-NoExit -c (cd '$pwd') ; .\modules\win-startup.ps1"
