; There is nothing to manually configure in this file
; To interface with the config please see the README.md

%ifndef BOOT_MAX
    %assign BOOT_MAX 0
%endif

%ifndef BOOT_8086
    %define BOOT_8086 .halt
    %if BOOT_MAX < 1
        %assign BOOT_MAX 1
    %endif
%endif

%if BOOT_MAX > 1
    %ifndef BOOT_80286
        %define BOOT_80286 .halt
    %endif
%endif