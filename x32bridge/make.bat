@echo off
set MORED=..\..\mored
if not exist %MORED% ( echo path to the mored repository "%MORED%" does not exist.  Have you cloned it? && goto EXIT )

dmd -I%MORED% x32bridge.d %MORED%\more\osc.d %MORED%\more\common.d %MORED%\more\net.d -unittest -debug

:EXIT