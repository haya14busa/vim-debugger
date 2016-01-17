:bug: vim-debugger
==================

vim-debugger is a Vim script debugger.

*[The APIs might change]*

:debug improved
---------------
![https://gyazo.com/926142136e0429f032efabbc8e5e3c6c](https://i.gyazo.com/926142136e0429f032efabbc8e5e3c6c.png)

### Commands

| command | description |
| ------- | ----------- |
| `:DebugOn` | turn on debugging commands |
| `:Debugger` | add breakpoint |
| `>Current` | show current line and function in debug-mode with syntax highlight |
| `>Break {lnum}` | add break point to {lnum} in a current function |
| `>File` | show current file in debug-mode |
| `>SID` | show `<SID>` in debug-mode |
| `>DebugHelp` | show help for debug-mode |
| `>Sfuncs` | list script-local functions in debug-mode |

:feet: StackTrace
-----------------

```vim
:StackTrace function vitalizer#command[37]..vitalizer#vitalize[69]..<SNR>210_search_dependence[20]..<SNR>211_import[11]..<SNR>211__import[20]..<SNR>211__build_module[18]..<SNR>218__vital_loaded[2]..<SNR>211_import[11]..<SNR>211__import: line    6:
```

![https://gyazo.com/e3f70551a4ce1ab1f614542a4fac0921](https://i.gyazo.com/e3f70551a4ce1ab1f614542a4fac0921.png)

| command | description |
| ------- | ----------- |
| `:StackTrace {throwpoint}` | show stacktrace |
| `:CallStack {id}` | get callstack and save it as {id} |
| `:CallStackReport {id}` | report {id} callstack |
