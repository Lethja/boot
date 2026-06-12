; There is nothing to manually configure in this file
; To interface with the config please see the README.md

%ifndef BOOT_MAX
    %ifnum BOOT_MAX
    %else
        %error "BOOT_MAX must be a number"
    %endif
    %define BOOT_MAX 0
%endif

%ifndef BOOT_8086
    %define BOOT_8086 .halt
    %if BOOT_MAX < 1
        %define BOOT_MAX 1
    %endif
%endif

%ifndef BOOT_80286
    %define BOOT_80286 .halt
%endif

%ifndef BOOT_80386
    %define BOOT_80386 .halt
%endif

%ifndef BOOT_80486
    %define BOOT_80486 .halt
%endif

%ifndef BOOT_CPUID
    %define BOOT_CPUID .halt
%endif

%ifndef BOOT_X8664
    %define BOOT_X8664 .halt
%endif