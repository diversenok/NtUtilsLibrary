unit NtUtils.AntiHooking.Trampoline;

{
  The module provides templates for system call trampolines used for
  anti-hooking.
}

interface

// Get an address of a function that issues a direct syscall
// with the specified number.
function SyscallTrampoline(Number: Cardinal): Pointer;

implementation

// Here we include stubs for issuing syscalls from 0 to 4095 on x64 machines.
// That covers all possible syscalls that ntdll can issue. It consumes 64 kB of
// executable memory plus 32 kB for an array of pointers. However, the compiler
// won't include anything unless the program actually uses syscall unhooking.

// Note that we cannot do the same for x86 because the calling convention
// requires us to fix up the stack pointer before returning. This operation
// depends on the amount arguments which we do not know in advance.

{$IFDEF Win64}

procedure Syscall_000; stdcall;
asm
  mov r10, rcx
  mov eax, $000
  syscall
end;

procedure Syscall_001; stdcall;
asm
  mov r10, rcx
  mov eax, $001
  syscall
end;

procedure Syscall_002; stdcall;
asm
  mov r10, rcx
  mov eax, $002
  syscall
end;

procedure Syscall_003; stdcall;
asm
  mov r10, rcx
  mov eax, $003
  syscall
end;

procedure Syscall_004; stdcall;
asm
  mov r10, rcx
  mov eax, $004
  syscall
end;

procedure Syscall_005; stdcall;
asm
  mov r10, rcx
  mov eax, $005
  syscall
end;

procedure Syscall_006; stdcall;
asm
  mov r10, rcx
  mov eax, $006
  syscall
end;

procedure Syscall_007; stdcall;
asm
  mov r10, rcx
  mov eax, $007
  syscall
end;

procedure Syscall_008; stdcall;
asm
  mov r10, rcx
  mov eax, $008
  syscall
end;

procedure Syscall_009; stdcall;
asm
  mov r10, rcx
  mov eax, $009
  syscall
end;

procedure Syscall_00A; stdcall;
asm
  mov r10, rcx
  mov eax, $00A
  syscall
end;

procedure Syscall_00B; stdcall;
asm
  mov r10, rcx
  mov eax, $00B
  syscall
end;

procedure Syscall_00C; stdcall;
asm
  mov r10, rcx
  mov eax, $00C
  syscall
end;

procedure Syscall_00D; stdcall;
asm
  mov r10, rcx
  mov eax, $00D
  syscall
end;

procedure Syscall_00E; stdcall;
asm
  mov r10, rcx
  mov eax, $00E
  syscall
end;

procedure Syscall_00F; stdcall;
asm
  mov r10, rcx
  mov eax, $00F
  syscall
end;

procedure Syscall_010; stdcall;
asm
  mov r10, rcx
  mov eax, $010
  syscall
end;

procedure Syscall_011; stdcall;
asm
  mov r10, rcx
  mov eax, $011
  syscall
end;

procedure Syscall_012; stdcall;
asm
  mov r10, rcx
  mov eax, $012
  syscall
end;

procedure Syscall_013; stdcall;
asm
  mov r10, rcx
  mov eax, $013
  syscall
end;

procedure Syscall_014; stdcall;
asm
  mov r10, rcx
  mov eax, $014
  syscall
end;

procedure Syscall_015; stdcall;
asm
  mov r10, rcx
  mov eax, $015
  syscall
end;

procedure Syscall_016; stdcall;
asm
  mov r10, rcx
  mov eax, $016
  syscall
end;

procedure Syscall_017; stdcall;
asm
  mov r10, rcx
  mov eax, $017
  syscall
end;

procedure Syscall_018; stdcall;
asm
  mov r10, rcx
  mov eax, $018
  syscall
end;

procedure Syscall_019; stdcall;
asm
  mov r10, rcx
  mov eax, $019
  syscall
end;

procedure Syscall_01A; stdcall;
asm
  mov r10, rcx
  mov eax, $01A
  syscall
end;

procedure Syscall_01B; stdcall;
asm
  mov r10, rcx
  mov eax, $01B
  syscall
end;

procedure Syscall_01C; stdcall;
asm
  mov r10, rcx
  mov eax, $01C
  syscall
end;

procedure Syscall_01D; stdcall;
asm
  mov r10, rcx
  mov eax, $01D
  syscall
end;

procedure Syscall_01E; stdcall;
asm
  mov r10, rcx
  mov eax, $01E
  syscall
end;

procedure Syscall_01F; stdcall;
asm
  mov r10, rcx
  mov eax, $01F
  syscall
end;

procedure Syscall_020; stdcall;
asm
  mov r10, rcx
  mov eax, $020
  syscall
end;

procedure Syscall_021; stdcall;
asm
  mov r10, rcx
  mov eax, $021
  syscall
end;

procedure Syscall_022; stdcall;
asm
  mov r10, rcx
  mov eax, $022
  syscall
end;

procedure Syscall_023; stdcall;
asm
  mov r10, rcx
  mov eax, $023
  syscall
end;

procedure Syscall_024; stdcall;
asm
  mov r10, rcx
  mov eax, $024
  syscall
end;

procedure Syscall_025; stdcall;
asm
  mov r10, rcx
  mov eax, $025
  syscall
end;

procedure Syscall_026; stdcall;
asm
  mov r10, rcx
  mov eax, $026
  syscall
end;

procedure Syscall_027; stdcall;
asm
  mov r10, rcx
  mov eax, $027
  syscall
end;

procedure Syscall_028; stdcall;
asm
  mov r10, rcx
  mov eax, $028
  syscall
end;

procedure Syscall_029; stdcall;
asm
  mov r10, rcx
  mov eax, $029
  syscall
end;

procedure Syscall_02A; stdcall;
asm
  mov r10, rcx
  mov eax, $02A
  syscall
end;

procedure Syscall_02B; stdcall;
asm
  mov r10, rcx
  mov eax, $02B
  syscall
end;

procedure Syscall_02C; stdcall;
asm
  mov r10, rcx
  mov eax, $02C
  syscall
end;

procedure Syscall_02D; stdcall;
asm
  mov r10, rcx
  mov eax, $02D
  syscall
end;

procedure Syscall_02E; stdcall;
asm
  mov r10, rcx
  mov eax, $02E
  syscall
end;

procedure Syscall_02F; stdcall;
asm
  mov r10, rcx
  mov eax, $02F
  syscall
end;

procedure Syscall_030; stdcall;
asm
  mov r10, rcx
  mov eax, $030
  syscall
end;

procedure Syscall_031; stdcall;
asm
  mov r10, rcx
  mov eax, $031
  syscall
end;

procedure Syscall_032; stdcall;
asm
  mov r10, rcx
  mov eax, $032
  syscall
end;

procedure Syscall_033; stdcall;
asm
  mov r10, rcx
  mov eax, $033
  syscall
end;

procedure Syscall_034; stdcall;
asm
  mov r10, rcx
  mov eax, $034
  syscall
end;

procedure Syscall_035; stdcall;
asm
  mov r10, rcx
  mov eax, $035
  syscall
end;

procedure Syscall_036; stdcall;
asm
  mov r10, rcx
  mov eax, $036
  syscall
end;

procedure Syscall_037; stdcall;
asm
  mov r10, rcx
  mov eax, $037
  syscall
end;

procedure Syscall_038; stdcall;
asm
  mov r10, rcx
  mov eax, $038
  syscall
end;

procedure Syscall_039; stdcall;
asm
  mov r10, rcx
  mov eax, $039
  syscall
end;

procedure Syscall_03A; stdcall;
asm
  mov r10, rcx
  mov eax, $03A
  syscall
end;

procedure Syscall_03B; stdcall;
asm
  mov r10, rcx
  mov eax, $03B
  syscall
end;

procedure Syscall_03C; stdcall;
asm
  mov r10, rcx
  mov eax, $03C
  syscall
end;

procedure Syscall_03D; stdcall;
asm
  mov r10, rcx
  mov eax, $03D
  syscall
end;

procedure Syscall_03E; stdcall;
asm
  mov r10, rcx
  mov eax, $03E
  syscall
end;

procedure Syscall_03F; stdcall;
asm
  mov r10, rcx
  mov eax, $03F
  syscall
end;

procedure Syscall_040; stdcall;
asm
  mov r10, rcx
  mov eax, $040
  syscall
end;

procedure Syscall_041; stdcall;
asm
  mov r10, rcx
  mov eax, $041
  syscall
end;

procedure Syscall_042; stdcall;
asm
  mov r10, rcx
  mov eax, $042
  syscall
end;

procedure Syscall_043; stdcall;
asm
  mov r10, rcx
  mov eax, $043
  syscall
end;

procedure Syscall_044; stdcall;
asm
  mov r10, rcx
  mov eax, $044
  syscall
end;

procedure Syscall_045; stdcall;
asm
  mov r10, rcx
  mov eax, $045
  syscall
end;

procedure Syscall_046; stdcall;
asm
  mov r10, rcx
  mov eax, $046
  syscall
end;

procedure Syscall_047; stdcall;
asm
  mov r10, rcx
  mov eax, $047
  syscall
end;

procedure Syscall_048; stdcall;
asm
  mov r10, rcx
  mov eax, $048
  syscall
end;

procedure Syscall_049; stdcall;
asm
  mov r10, rcx
  mov eax, $049
  syscall
end;

procedure Syscall_04A; stdcall;
asm
  mov r10, rcx
  mov eax, $04A
  syscall
end;

procedure Syscall_04B; stdcall;
asm
  mov r10, rcx
  mov eax, $04B
  syscall
end;

procedure Syscall_04C; stdcall;
asm
  mov r10, rcx
  mov eax, $04C
  syscall
end;

procedure Syscall_04D; stdcall;
asm
  mov r10, rcx
  mov eax, $04D
  syscall
end;

procedure Syscall_04E; stdcall;
asm
  mov r10, rcx
  mov eax, $04E
  syscall
end;

procedure Syscall_04F; stdcall;
asm
  mov r10, rcx
  mov eax, $04F
  syscall
end;

procedure Syscall_050; stdcall;
asm
  mov r10, rcx
  mov eax, $050
  syscall
end;

procedure Syscall_051; stdcall;
asm
  mov r10, rcx
  mov eax, $051
  syscall
end;

procedure Syscall_052; stdcall;
asm
  mov r10, rcx
  mov eax, $052
  syscall
end;

procedure Syscall_053; stdcall;
asm
  mov r10, rcx
  mov eax, $053
  syscall
end;

procedure Syscall_054; stdcall;
asm
  mov r10, rcx
  mov eax, $054
  syscall
end;

procedure Syscall_055; stdcall;
asm
  mov r10, rcx
  mov eax, $055
  syscall
end;

procedure Syscall_056; stdcall;
asm
  mov r10, rcx
  mov eax, $056
  syscall
end;

procedure Syscall_057; stdcall;
asm
  mov r10, rcx
  mov eax, $057
  syscall
end;

procedure Syscall_058; stdcall;
asm
  mov r10, rcx
  mov eax, $058
  syscall
end;

procedure Syscall_059; stdcall;
asm
  mov r10, rcx
  mov eax, $059
  syscall
end;

procedure Syscall_05A; stdcall;
asm
  mov r10, rcx
  mov eax, $05A
  syscall
end;

procedure Syscall_05B; stdcall;
asm
  mov r10, rcx
  mov eax, $05B
  syscall
end;

procedure Syscall_05C; stdcall;
asm
  mov r10, rcx
  mov eax, $05C
  syscall
end;

procedure Syscall_05D; stdcall;
asm
  mov r10, rcx
  mov eax, $05D
  syscall
end;

procedure Syscall_05E; stdcall;
asm
  mov r10, rcx
  mov eax, $05E
  syscall
end;

procedure Syscall_05F; stdcall;
asm
  mov r10, rcx
  mov eax, $05F
  syscall
end;

procedure Syscall_060; stdcall;
asm
  mov r10, rcx
  mov eax, $060
  syscall
end;

procedure Syscall_061; stdcall;
asm
  mov r10, rcx
  mov eax, $061
  syscall
end;

procedure Syscall_062; stdcall;
asm
  mov r10, rcx
  mov eax, $062
  syscall
end;

procedure Syscall_063; stdcall;
asm
  mov r10, rcx
  mov eax, $063
  syscall
end;

procedure Syscall_064; stdcall;
asm
  mov r10, rcx
  mov eax, $064
  syscall
end;

procedure Syscall_065; stdcall;
asm
  mov r10, rcx
  mov eax, $065
  syscall
end;

procedure Syscall_066; stdcall;
asm
  mov r10, rcx
  mov eax, $066
  syscall
end;

procedure Syscall_067; stdcall;
asm
  mov r10, rcx
  mov eax, $067
  syscall
end;

procedure Syscall_068; stdcall;
asm
  mov r10, rcx
  mov eax, $068
  syscall
end;

procedure Syscall_069; stdcall;
asm
  mov r10, rcx
  mov eax, $069
  syscall
end;

procedure Syscall_06A; stdcall;
asm
  mov r10, rcx
  mov eax, $06A
  syscall
end;

procedure Syscall_06B; stdcall;
asm
  mov r10, rcx
  mov eax, $06B
  syscall
end;

procedure Syscall_06C; stdcall;
asm
  mov r10, rcx
  mov eax, $06C
  syscall
end;

procedure Syscall_06D; stdcall;
asm
  mov r10, rcx
  mov eax, $06D
  syscall
end;

procedure Syscall_06E; stdcall;
asm
  mov r10, rcx
  mov eax, $06E
  syscall
end;

procedure Syscall_06F; stdcall;
asm
  mov r10, rcx
  mov eax, $06F
  syscall
end;

procedure Syscall_070; stdcall;
asm
  mov r10, rcx
  mov eax, $070
  syscall
end;

procedure Syscall_071; stdcall;
asm
  mov r10, rcx
  mov eax, $071
  syscall
end;

procedure Syscall_072; stdcall;
asm
  mov r10, rcx
  mov eax, $072
  syscall
end;

procedure Syscall_073; stdcall;
asm
  mov r10, rcx
  mov eax, $073
  syscall
end;

procedure Syscall_074; stdcall;
asm
  mov r10, rcx
  mov eax, $074
  syscall
end;

procedure Syscall_075; stdcall;
asm
  mov r10, rcx
  mov eax, $075
  syscall
end;

procedure Syscall_076; stdcall;
asm
  mov r10, rcx
  mov eax, $076
  syscall
end;

procedure Syscall_077; stdcall;
asm
  mov r10, rcx
  mov eax, $077
  syscall
end;

procedure Syscall_078; stdcall;
asm
  mov r10, rcx
  mov eax, $078
  syscall
end;

procedure Syscall_079; stdcall;
asm
  mov r10, rcx
  mov eax, $079
  syscall
end;

procedure Syscall_07A; stdcall;
asm
  mov r10, rcx
  mov eax, $07A
  syscall
end;

procedure Syscall_07B; stdcall;
asm
  mov r10, rcx
  mov eax, $07B
  syscall
end;

procedure Syscall_07C; stdcall;
asm
  mov r10, rcx
  mov eax, $07C
  syscall
end;

procedure Syscall_07D; stdcall;
asm
  mov r10, rcx
  mov eax, $07D
  syscall
end;

procedure Syscall_07E; stdcall;
asm
  mov r10, rcx
  mov eax, $07E
  syscall
end;

procedure Syscall_07F; stdcall;
asm
  mov r10, rcx
  mov eax, $07F
  syscall
end;

procedure Syscall_080; stdcall;
asm
  mov r10, rcx
  mov eax, $080
  syscall
end;

procedure Syscall_081; stdcall;
asm
  mov r10, rcx
  mov eax, $081
  syscall
end;

procedure Syscall_082; stdcall;
asm
  mov r10, rcx
  mov eax, $082
  syscall
end;

procedure Syscall_083; stdcall;
asm
  mov r10, rcx
  mov eax, $083
  syscall
end;

procedure Syscall_084; stdcall;
asm
  mov r10, rcx
  mov eax, $084
  syscall
end;

procedure Syscall_085; stdcall;
asm
  mov r10, rcx
  mov eax, $085
  syscall
end;

procedure Syscall_086; stdcall;
asm
  mov r10, rcx
  mov eax, $086
  syscall
end;

procedure Syscall_087; stdcall;
asm
  mov r10, rcx
  mov eax, $087
  syscall
end;

procedure Syscall_088; stdcall;
asm
  mov r10, rcx
  mov eax, $088
  syscall
end;

procedure Syscall_089; stdcall;
asm
  mov r10, rcx
  mov eax, $089
  syscall
end;

procedure Syscall_08A; stdcall;
asm
  mov r10, rcx
  mov eax, $08A
  syscall
end;

procedure Syscall_08B; stdcall;
asm
  mov r10, rcx
  mov eax, $08B
  syscall
end;

procedure Syscall_08C; stdcall;
asm
  mov r10, rcx
  mov eax, $08C
  syscall
end;

procedure Syscall_08D; stdcall;
asm
  mov r10, rcx
  mov eax, $08D
  syscall
end;

procedure Syscall_08E; stdcall;
asm
  mov r10, rcx
  mov eax, $08E
  syscall
end;

procedure Syscall_08F; stdcall;
asm
  mov r10, rcx
  mov eax, $08F
  syscall
end;

procedure Syscall_090; stdcall;
asm
  mov r10, rcx
  mov eax, $090
  syscall
end;

procedure Syscall_091; stdcall;
asm
  mov r10, rcx
  mov eax, $091
  syscall
end;

procedure Syscall_092; stdcall;
asm
  mov r10, rcx
  mov eax, $092
  syscall
end;

procedure Syscall_093; stdcall;
asm
  mov r10, rcx
  mov eax, $093
  syscall
end;

procedure Syscall_094; stdcall;
asm
  mov r10, rcx
  mov eax, $094
  syscall
end;

procedure Syscall_095; stdcall;
asm
  mov r10, rcx
  mov eax, $095
  syscall
end;

procedure Syscall_096; stdcall;
asm
  mov r10, rcx
  mov eax, $096
  syscall
end;

procedure Syscall_097; stdcall;
asm
  mov r10, rcx
  mov eax, $097
  syscall
end;

procedure Syscall_098; stdcall;
asm
  mov r10, rcx
  mov eax, $098
  syscall
end;

procedure Syscall_099; stdcall;
asm
  mov r10, rcx
  mov eax, $099
  syscall
end;

procedure Syscall_09A; stdcall;
asm
  mov r10, rcx
  mov eax, $09A
  syscall
end;

procedure Syscall_09B; stdcall;
asm
  mov r10, rcx
  mov eax, $09B
  syscall
end;

procedure Syscall_09C; stdcall;
asm
  mov r10, rcx
  mov eax, $09C
  syscall
end;

procedure Syscall_09D; stdcall;
asm
  mov r10, rcx
  mov eax, $09D
  syscall
end;

procedure Syscall_09E; stdcall;
asm
  mov r10, rcx
  mov eax, $09E
  syscall
end;

procedure Syscall_09F; stdcall;
asm
  mov r10, rcx
  mov eax, $09F
  syscall
end;

procedure Syscall_0A0; stdcall;
asm
  mov r10, rcx
  mov eax, $0A0
  syscall
end;

procedure Syscall_0A1; stdcall;
asm
  mov r10, rcx
  mov eax, $0A1
  syscall
end;

procedure Syscall_0A2; stdcall;
asm
  mov r10, rcx
  mov eax, $0A2
  syscall
end;

procedure Syscall_0A3; stdcall;
asm
  mov r10, rcx
  mov eax, $0A3
  syscall
end;

procedure Syscall_0A4; stdcall;
asm
  mov r10, rcx
  mov eax, $0A4
  syscall
end;

procedure Syscall_0A5; stdcall;
asm
  mov r10, rcx
  mov eax, $0A5
  syscall
end;

procedure Syscall_0A6; stdcall;
asm
  mov r10, rcx
  mov eax, $0A6
  syscall
end;

procedure Syscall_0A7; stdcall;
asm
  mov r10, rcx
  mov eax, $0A7
  syscall
end;

procedure Syscall_0A8; stdcall;
asm
  mov r10, rcx
  mov eax, $0A8
  syscall
end;

procedure Syscall_0A9; stdcall;
asm
  mov r10, rcx
  mov eax, $0A9
  syscall
end;

procedure Syscall_0AA; stdcall;
asm
  mov r10, rcx
  mov eax, $0AA
  syscall
end;

procedure Syscall_0AB; stdcall;
asm
  mov r10, rcx
  mov eax, $0AB
  syscall
end;

procedure Syscall_0AC; stdcall;
asm
  mov r10, rcx
  mov eax, $0AC
  syscall
end;

procedure Syscall_0AD; stdcall;
asm
  mov r10, rcx
  mov eax, $0AD
  syscall
end;

procedure Syscall_0AE; stdcall;
asm
  mov r10, rcx
  mov eax, $0AE
  syscall
end;

procedure Syscall_0AF; stdcall;
asm
  mov r10, rcx
  mov eax, $0AF
  syscall
end;

procedure Syscall_0B0; stdcall;
asm
  mov r10, rcx
  mov eax, $0B0
  syscall
end;

procedure Syscall_0B1; stdcall;
asm
  mov r10, rcx
  mov eax, $0B1
  syscall
end;

procedure Syscall_0B2; stdcall;
asm
  mov r10, rcx
  mov eax, $0B2
  syscall
end;

procedure Syscall_0B3; stdcall;
asm
  mov r10, rcx
  mov eax, $0B3
  syscall
end;

procedure Syscall_0B4; stdcall;
asm
  mov r10, rcx
  mov eax, $0B4
  syscall
end;

procedure Syscall_0B5; stdcall;
asm
  mov r10, rcx
  mov eax, $0B5
  syscall
end;

procedure Syscall_0B6; stdcall;
asm
  mov r10, rcx
  mov eax, $0B6
  syscall
end;

procedure Syscall_0B7; stdcall;
asm
  mov r10, rcx
  mov eax, $0B7
  syscall
end;

procedure Syscall_0B8; stdcall;
asm
  mov r10, rcx
  mov eax, $0B8
  syscall
end;

procedure Syscall_0B9; stdcall;
asm
  mov r10, rcx
  mov eax, $0B9
  syscall
end;

procedure Syscall_0BA; stdcall;
asm
  mov r10, rcx
  mov eax, $0BA
  syscall
end;

procedure Syscall_0BB; stdcall;
asm
  mov r10, rcx
  mov eax, $0BB
  syscall
end;

procedure Syscall_0BC; stdcall;
asm
  mov r10, rcx
  mov eax, $0BC
  syscall
end;

procedure Syscall_0BD; stdcall;
asm
  mov r10, rcx
  mov eax, $0BD
  syscall
end;

procedure Syscall_0BE; stdcall;
asm
  mov r10, rcx
  mov eax, $0BE
  syscall
end;

procedure Syscall_0BF; stdcall;
asm
  mov r10, rcx
  mov eax, $0BF
  syscall
end;

procedure Syscall_0C0; stdcall;
asm
  mov r10, rcx
  mov eax, $0C0
  syscall
end;

procedure Syscall_0C1; stdcall;
asm
  mov r10, rcx
  mov eax, $0C1
  syscall
end;

procedure Syscall_0C2; stdcall;
asm
  mov r10, rcx
  mov eax, $0C2
  syscall
end;

procedure Syscall_0C3; stdcall;
asm
  mov r10, rcx
  mov eax, $0C3
  syscall
end;

procedure Syscall_0C4; stdcall;
asm
  mov r10, rcx
  mov eax, $0C4
  syscall
end;

procedure Syscall_0C5; stdcall;
asm
  mov r10, rcx
  mov eax, $0C5
  syscall
end;

procedure Syscall_0C6; stdcall;
asm
  mov r10, rcx
  mov eax, $0C6
  syscall
end;

procedure Syscall_0C7; stdcall;
asm
  mov r10, rcx
  mov eax, $0C7
  syscall
end;

procedure Syscall_0C8; stdcall;
asm
  mov r10, rcx
  mov eax, $0C8
  syscall
end;

procedure Syscall_0C9; stdcall;
asm
  mov r10, rcx
  mov eax, $0C9
  syscall
end;

procedure Syscall_0CA; stdcall;
asm
  mov r10, rcx
  mov eax, $0CA
  syscall
end;

procedure Syscall_0CB; stdcall;
asm
  mov r10, rcx
  mov eax, $0CB
  syscall
end;

procedure Syscall_0CC; stdcall;
asm
  mov r10, rcx
  mov eax, $0CC
  syscall
end;

procedure Syscall_0CD; stdcall;
asm
  mov r10, rcx
  mov eax, $0CD
  syscall
end;

procedure Syscall_0CE; stdcall;
asm
  mov r10, rcx
  mov eax, $0CE
  syscall
end;

procedure Syscall_0CF; stdcall;
asm
  mov r10, rcx
  mov eax, $0CF
  syscall
end;

procedure Syscall_0D0; stdcall;
asm
  mov r10, rcx
  mov eax, $0D0
  syscall
end;

procedure Syscall_0D1; stdcall;
asm
  mov r10, rcx
  mov eax, $0D1
  syscall
end;

procedure Syscall_0D2; stdcall;
asm
  mov r10, rcx
  mov eax, $0D2
  syscall
end;

procedure Syscall_0D3; stdcall;
asm
  mov r10, rcx
  mov eax, $0D3
  syscall
end;

procedure Syscall_0D4; stdcall;
asm
  mov r10, rcx
  mov eax, $0D4
  syscall
end;

procedure Syscall_0D5; stdcall;
asm
  mov r10, rcx
  mov eax, $0D5
  syscall
end;

procedure Syscall_0D6; stdcall;
asm
  mov r10, rcx
  mov eax, $0D6
  syscall
end;

procedure Syscall_0D7; stdcall;
asm
  mov r10, rcx
  mov eax, $0D7
  syscall
end;

procedure Syscall_0D8; stdcall;
asm
  mov r10, rcx
  mov eax, $0D8
  syscall
end;

procedure Syscall_0D9; stdcall;
asm
  mov r10, rcx
  mov eax, $0D9
  syscall
end;

procedure Syscall_0DA; stdcall;
asm
  mov r10, rcx
  mov eax, $0DA
  syscall
end;

procedure Syscall_0DB; stdcall;
asm
  mov r10, rcx
  mov eax, $0DB
  syscall
end;

procedure Syscall_0DC; stdcall;
asm
  mov r10, rcx
  mov eax, $0DC
  syscall
end;

procedure Syscall_0DD; stdcall;
asm
  mov r10, rcx
  mov eax, $0DD
  syscall
end;

procedure Syscall_0DE; stdcall;
asm
  mov r10, rcx
  mov eax, $0DE
  syscall
end;

procedure Syscall_0DF; stdcall;
asm
  mov r10, rcx
  mov eax, $0DF
  syscall
end;

procedure Syscall_0E0; stdcall;
asm
  mov r10, rcx
  mov eax, $0E0
  syscall
end;

procedure Syscall_0E1; stdcall;
asm
  mov r10, rcx
  mov eax, $0E1
  syscall
end;

procedure Syscall_0E2; stdcall;
asm
  mov r10, rcx
  mov eax, $0E2
  syscall
end;

procedure Syscall_0E3; stdcall;
asm
  mov r10, rcx
  mov eax, $0E3
  syscall
end;

procedure Syscall_0E4; stdcall;
asm
  mov r10, rcx
  mov eax, $0E4
  syscall
end;

procedure Syscall_0E5; stdcall;
asm
  mov r10, rcx
  mov eax, $0E5
  syscall
end;

procedure Syscall_0E6; stdcall;
asm
  mov r10, rcx
  mov eax, $0E6
  syscall
end;

procedure Syscall_0E7; stdcall;
asm
  mov r10, rcx
  mov eax, $0E7
  syscall
end;

procedure Syscall_0E8; stdcall;
asm
  mov r10, rcx
  mov eax, $0E8
  syscall
end;

procedure Syscall_0E9; stdcall;
asm
  mov r10, rcx
  mov eax, $0E9
  syscall
end;

procedure Syscall_0EA; stdcall;
asm
  mov r10, rcx
  mov eax, $0EA
  syscall
end;

procedure Syscall_0EB; stdcall;
asm
  mov r10, rcx
  mov eax, $0EB
  syscall
end;

procedure Syscall_0EC; stdcall;
asm
  mov r10, rcx
  mov eax, $0EC
  syscall
end;

procedure Syscall_0ED; stdcall;
asm
  mov r10, rcx
  mov eax, $0ED
  syscall
end;

procedure Syscall_0EE; stdcall;
asm
  mov r10, rcx
  mov eax, $0EE
  syscall
end;

procedure Syscall_0EF; stdcall;
asm
  mov r10, rcx
  mov eax, $0EF
  syscall
end;

procedure Syscall_0F0; stdcall;
asm
  mov r10, rcx
  mov eax, $0F0
  syscall
end;

procedure Syscall_0F1; stdcall;
asm
  mov r10, rcx
  mov eax, $0F1
  syscall
end;

procedure Syscall_0F2; stdcall;
asm
  mov r10, rcx
  mov eax, $0F2
  syscall
end;

procedure Syscall_0F3; stdcall;
asm
  mov r10, rcx
  mov eax, $0F3
  syscall
end;

procedure Syscall_0F4; stdcall;
asm
  mov r10, rcx
  mov eax, $0F4
  syscall
end;

procedure Syscall_0F5; stdcall;
asm
  mov r10, rcx
  mov eax, $0F5
  syscall
end;

procedure Syscall_0F6; stdcall;
asm
  mov r10, rcx
  mov eax, $0F6
  syscall
end;

procedure Syscall_0F7; stdcall;
asm
  mov r10, rcx
  mov eax, $0F7
  syscall
end;

procedure Syscall_0F8; stdcall;
asm
  mov r10, rcx
  mov eax, $0F8
  syscall
end;

procedure Syscall_0F9; stdcall;
asm
  mov r10, rcx
  mov eax, $0F9
  syscall
end;

procedure Syscall_0FA; stdcall;
asm
  mov r10, rcx
  mov eax, $0FA
  syscall
end;

procedure Syscall_0FB; stdcall;
asm
  mov r10, rcx
  mov eax, $0FB
  syscall
end;

procedure Syscall_0FC; stdcall;
asm
  mov r10, rcx
  mov eax, $0FC
  syscall
end;

procedure Syscall_0FD; stdcall;
asm
  mov r10, rcx
  mov eax, $0FD
  syscall
end;

procedure Syscall_0FE; stdcall;
asm
  mov r10, rcx
  mov eax, $0FE
  syscall
end;

procedure Syscall_0FF; stdcall;
asm
  mov r10, rcx
  mov eax, $0FF
  syscall
end;

procedure Syscall_100; stdcall;
asm
  mov r10, rcx
  mov eax, $100
  syscall
end;

procedure Syscall_101; stdcall;
asm
  mov r10, rcx
  mov eax, $101
  syscall
end;

procedure Syscall_102; stdcall;
asm
  mov r10, rcx
  mov eax, $102
  syscall
end;

procedure Syscall_103; stdcall;
asm
  mov r10, rcx
  mov eax, $103
  syscall
end;

procedure Syscall_104; stdcall;
asm
  mov r10, rcx
  mov eax, $104
  syscall
end;

procedure Syscall_105; stdcall;
asm
  mov r10, rcx
  mov eax, $105
  syscall
end;

procedure Syscall_106; stdcall;
asm
  mov r10, rcx
  mov eax, $106
  syscall
end;

procedure Syscall_107; stdcall;
asm
  mov r10, rcx
  mov eax, $107
  syscall
end;

procedure Syscall_108; stdcall;
asm
  mov r10, rcx
  mov eax, $108
  syscall
end;

procedure Syscall_109; stdcall;
asm
  mov r10, rcx
  mov eax, $109
  syscall
end;

procedure Syscall_10A; stdcall;
asm
  mov r10, rcx
  mov eax, $10A
  syscall
end;

procedure Syscall_10B; stdcall;
asm
  mov r10, rcx
  mov eax, $10B
  syscall
end;

procedure Syscall_10C; stdcall;
asm
  mov r10, rcx
  mov eax, $10C
  syscall
end;

procedure Syscall_10D; stdcall;
asm
  mov r10, rcx
  mov eax, $10D
  syscall
end;

procedure Syscall_10E; stdcall;
asm
  mov r10, rcx
  mov eax, $10E
  syscall
end;

procedure Syscall_10F; stdcall;
asm
  mov r10, rcx
  mov eax, $10F
  syscall
end;

procedure Syscall_110; stdcall;
asm
  mov r10, rcx
  mov eax, $110
  syscall
end;

procedure Syscall_111; stdcall;
asm
  mov r10, rcx
  mov eax, $111
  syscall
end;

procedure Syscall_112; stdcall;
asm
  mov r10, rcx
  mov eax, $112
  syscall
end;

procedure Syscall_113; stdcall;
asm
  mov r10, rcx
  mov eax, $113
  syscall
end;

procedure Syscall_114; stdcall;
asm
  mov r10, rcx
  mov eax, $114
  syscall
end;

procedure Syscall_115; stdcall;
asm
  mov r10, rcx
  mov eax, $115
  syscall
end;

procedure Syscall_116; stdcall;
asm
  mov r10, rcx
  mov eax, $116
  syscall
end;

procedure Syscall_117; stdcall;
asm
  mov r10, rcx
  mov eax, $117
  syscall
end;

procedure Syscall_118; stdcall;
asm
  mov r10, rcx
  mov eax, $118
  syscall
end;

procedure Syscall_119; stdcall;
asm
  mov r10, rcx
  mov eax, $119
  syscall
end;

procedure Syscall_11A; stdcall;
asm
  mov r10, rcx
  mov eax, $11A
  syscall
end;

procedure Syscall_11B; stdcall;
asm
  mov r10, rcx
  mov eax, $11B
  syscall
end;

procedure Syscall_11C; stdcall;
asm
  mov r10, rcx
  mov eax, $11C
  syscall
end;

procedure Syscall_11D; stdcall;
asm
  mov r10, rcx
  mov eax, $11D
  syscall
end;

procedure Syscall_11E; stdcall;
asm
  mov r10, rcx
  mov eax, $11E
  syscall
end;

procedure Syscall_11F; stdcall;
asm
  mov r10, rcx
  mov eax, $11F
  syscall
end;

procedure Syscall_120; stdcall;
asm
  mov r10, rcx
  mov eax, $120
  syscall
end;

procedure Syscall_121; stdcall;
asm
  mov r10, rcx
  mov eax, $121
  syscall
end;

procedure Syscall_122; stdcall;
asm
  mov r10, rcx
  mov eax, $122
  syscall
end;

procedure Syscall_123; stdcall;
asm
  mov r10, rcx
  mov eax, $123
  syscall
end;

procedure Syscall_124; stdcall;
asm
  mov r10, rcx
  mov eax, $124
  syscall
end;

procedure Syscall_125; stdcall;
asm
  mov r10, rcx
  mov eax, $125
  syscall
end;

procedure Syscall_126; stdcall;
asm
  mov r10, rcx
  mov eax, $126
  syscall
end;

procedure Syscall_127; stdcall;
asm
  mov r10, rcx
  mov eax, $127
  syscall
end;

procedure Syscall_128; stdcall;
asm
  mov r10, rcx
  mov eax, $128
  syscall
end;

procedure Syscall_129; stdcall;
asm
  mov r10, rcx
  mov eax, $129
  syscall
end;

procedure Syscall_12A; stdcall;
asm
  mov r10, rcx
  mov eax, $12A
  syscall
end;

procedure Syscall_12B; stdcall;
asm
  mov r10, rcx
  mov eax, $12B
  syscall
end;

procedure Syscall_12C; stdcall;
asm
  mov r10, rcx
  mov eax, $12C
  syscall
end;

procedure Syscall_12D; stdcall;
asm
  mov r10, rcx
  mov eax, $12D
  syscall
end;

procedure Syscall_12E; stdcall;
asm
  mov r10, rcx
  mov eax, $12E
  syscall
end;

procedure Syscall_12F; stdcall;
asm
  mov r10, rcx
  mov eax, $12F
  syscall
end;

procedure Syscall_130; stdcall;
asm
  mov r10, rcx
  mov eax, $130
  syscall
end;

procedure Syscall_131; stdcall;
asm
  mov r10, rcx
  mov eax, $131
  syscall
end;

procedure Syscall_132; stdcall;
asm
  mov r10, rcx
  mov eax, $132
  syscall
end;

procedure Syscall_133; stdcall;
asm
  mov r10, rcx
  mov eax, $133
  syscall
end;

procedure Syscall_134; stdcall;
asm
  mov r10, rcx
  mov eax, $134
  syscall
end;

procedure Syscall_135; stdcall;
asm
  mov r10, rcx
  mov eax, $135
  syscall
end;

procedure Syscall_136; stdcall;
asm
  mov r10, rcx
  mov eax, $136
  syscall
end;

procedure Syscall_137; stdcall;
asm
  mov r10, rcx
  mov eax, $137
  syscall
end;

procedure Syscall_138; stdcall;
asm
  mov r10, rcx
  mov eax, $138
  syscall
end;

procedure Syscall_139; stdcall;
asm
  mov r10, rcx
  mov eax, $139
  syscall
end;

procedure Syscall_13A; stdcall;
asm
  mov r10, rcx
  mov eax, $13A
  syscall
end;

procedure Syscall_13B; stdcall;
asm
  mov r10, rcx
  mov eax, $13B
  syscall
end;

procedure Syscall_13C; stdcall;
asm
  mov r10, rcx
  mov eax, $13C
  syscall
end;

procedure Syscall_13D; stdcall;
asm
  mov r10, rcx
  mov eax, $13D
  syscall
end;

procedure Syscall_13E; stdcall;
asm
  mov r10, rcx
  mov eax, $13E
  syscall
end;

procedure Syscall_13F; stdcall;
asm
  mov r10, rcx
  mov eax, $13F
  syscall
end;

procedure Syscall_140; stdcall;
asm
  mov r10, rcx
  mov eax, $140
  syscall
end;

procedure Syscall_141; stdcall;
asm
  mov r10, rcx
  mov eax, $141
  syscall
end;

procedure Syscall_142; stdcall;
asm
  mov r10, rcx
  mov eax, $142
  syscall
end;

procedure Syscall_143; stdcall;
asm
  mov r10, rcx
  mov eax, $143
  syscall
end;

procedure Syscall_144; stdcall;
asm
  mov r10, rcx
  mov eax, $144
  syscall
end;

procedure Syscall_145; stdcall;
asm
  mov r10, rcx
  mov eax, $145
  syscall
end;

procedure Syscall_146; stdcall;
asm
  mov r10, rcx
  mov eax, $146
  syscall
end;

procedure Syscall_147; stdcall;
asm
  mov r10, rcx
  mov eax, $147
  syscall
end;

procedure Syscall_148; stdcall;
asm
  mov r10, rcx
  mov eax, $148
  syscall
end;

procedure Syscall_149; stdcall;
asm
  mov r10, rcx
  mov eax, $149
  syscall
end;

procedure Syscall_14A; stdcall;
asm
  mov r10, rcx
  mov eax, $14A
  syscall
end;

procedure Syscall_14B; stdcall;
asm
  mov r10, rcx
  mov eax, $14B
  syscall
end;

procedure Syscall_14C; stdcall;
asm
  mov r10, rcx
  mov eax, $14C
  syscall
end;

procedure Syscall_14D; stdcall;
asm
  mov r10, rcx
  mov eax, $14D
  syscall
end;

procedure Syscall_14E; stdcall;
asm
  mov r10, rcx
  mov eax, $14E
  syscall
end;

procedure Syscall_14F; stdcall;
asm
  mov r10, rcx
  mov eax, $14F
  syscall
end;

procedure Syscall_150; stdcall;
asm
  mov r10, rcx
  mov eax, $150
  syscall
end;

procedure Syscall_151; stdcall;
asm
  mov r10, rcx
  mov eax, $151
  syscall
end;

procedure Syscall_152; stdcall;
asm
  mov r10, rcx
  mov eax, $152
  syscall
end;

procedure Syscall_153; stdcall;
asm
  mov r10, rcx
  mov eax, $153
  syscall
end;

procedure Syscall_154; stdcall;
asm
  mov r10, rcx
  mov eax, $154
  syscall
end;

procedure Syscall_155; stdcall;
asm
  mov r10, rcx
  mov eax, $155
  syscall
end;

procedure Syscall_156; stdcall;
asm
  mov r10, rcx
  mov eax, $156
  syscall
end;

procedure Syscall_157; stdcall;
asm
  mov r10, rcx
  mov eax, $157
  syscall
end;

procedure Syscall_158; stdcall;
asm
  mov r10, rcx
  mov eax, $158
  syscall
end;

procedure Syscall_159; stdcall;
asm
  mov r10, rcx
  mov eax, $159
  syscall
end;

procedure Syscall_15A; stdcall;
asm
  mov r10, rcx
  mov eax, $15A
  syscall
end;

procedure Syscall_15B; stdcall;
asm
  mov r10, rcx
  mov eax, $15B
  syscall
end;

procedure Syscall_15C; stdcall;
asm
  mov r10, rcx
  mov eax, $15C
  syscall
end;

procedure Syscall_15D; stdcall;
asm
  mov r10, rcx
  mov eax, $15D
  syscall
end;

procedure Syscall_15E; stdcall;
asm
  mov r10, rcx
  mov eax, $15E
  syscall
end;

procedure Syscall_15F; stdcall;
asm
  mov r10, rcx
  mov eax, $15F
  syscall
end;

procedure Syscall_160; stdcall;
asm
  mov r10, rcx
  mov eax, $160
  syscall
end;

procedure Syscall_161; stdcall;
asm
  mov r10, rcx
  mov eax, $161
  syscall
end;

procedure Syscall_162; stdcall;
asm
  mov r10, rcx
  mov eax, $162
  syscall
end;

procedure Syscall_163; stdcall;
asm
  mov r10, rcx
  mov eax, $163
  syscall
end;

procedure Syscall_164; stdcall;
asm
  mov r10, rcx
  mov eax, $164
  syscall
end;

procedure Syscall_165; stdcall;
asm
  mov r10, rcx
  mov eax, $165
  syscall
end;

procedure Syscall_166; stdcall;
asm
  mov r10, rcx
  mov eax, $166
  syscall
end;

procedure Syscall_167; stdcall;
asm
  mov r10, rcx
  mov eax, $167
  syscall
end;

procedure Syscall_168; stdcall;
asm
  mov r10, rcx
  mov eax, $168
  syscall
end;

procedure Syscall_169; stdcall;
asm
  mov r10, rcx
  mov eax, $169
  syscall
end;

procedure Syscall_16A; stdcall;
asm
  mov r10, rcx
  mov eax, $16A
  syscall
end;

procedure Syscall_16B; stdcall;
asm
  mov r10, rcx
  mov eax, $16B
  syscall
end;

procedure Syscall_16C; stdcall;
asm
  mov r10, rcx
  mov eax, $16C
  syscall
end;

procedure Syscall_16D; stdcall;
asm
  mov r10, rcx
  mov eax, $16D
  syscall
end;

procedure Syscall_16E; stdcall;
asm
  mov r10, rcx
  mov eax, $16E
  syscall
end;

procedure Syscall_16F; stdcall;
asm
  mov r10, rcx
  mov eax, $16F
  syscall
end;

procedure Syscall_170; stdcall;
asm
  mov r10, rcx
  mov eax, $170
  syscall
end;

procedure Syscall_171; stdcall;
asm
  mov r10, rcx
  mov eax, $171
  syscall
end;

procedure Syscall_172; stdcall;
asm
  mov r10, rcx
  mov eax, $172
  syscall
end;

procedure Syscall_173; stdcall;
asm
  mov r10, rcx
  mov eax, $173
  syscall
end;

procedure Syscall_174; stdcall;
asm
  mov r10, rcx
  mov eax, $174
  syscall
end;

procedure Syscall_175; stdcall;
asm
  mov r10, rcx
  mov eax, $175
  syscall
end;

procedure Syscall_176; stdcall;
asm
  mov r10, rcx
  mov eax, $176
  syscall
end;

procedure Syscall_177; stdcall;
asm
  mov r10, rcx
  mov eax, $177
  syscall
end;

procedure Syscall_178; stdcall;
asm
  mov r10, rcx
  mov eax, $178
  syscall
end;

procedure Syscall_179; stdcall;
asm
  mov r10, rcx
  mov eax, $179
  syscall
end;

procedure Syscall_17A; stdcall;
asm
  mov r10, rcx
  mov eax, $17A
  syscall
end;

procedure Syscall_17B; stdcall;
asm
  mov r10, rcx
  mov eax, $17B
  syscall
end;

procedure Syscall_17C; stdcall;
asm
  mov r10, rcx
  mov eax, $17C
  syscall
end;

procedure Syscall_17D; stdcall;
asm
  mov r10, rcx
  mov eax, $17D
  syscall
end;

procedure Syscall_17E; stdcall;
asm
  mov r10, rcx
  mov eax, $17E
  syscall
end;

procedure Syscall_17F; stdcall;
asm
  mov r10, rcx
  mov eax, $17F
  syscall
end;

procedure Syscall_180; stdcall;
asm
  mov r10, rcx
  mov eax, $180
  syscall
end;

procedure Syscall_181; stdcall;
asm
  mov r10, rcx
  mov eax, $181
  syscall
end;

procedure Syscall_182; stdcall;
asm
  mov r10, rcx
  mov eax, $182
  syscall
end;

procedure Syscall_183; stdcall;
asm
  mov r10, rcx
  mov eax, $183
  syscall
end;

procedure Syscall_184; stdcall;
asm
  mov r10, rcx
  mov eax, $184
  syscall
end;

procedure Syscall_185; stdcall;
asm
  mov r10, rcx
  mov eax, $185
  syscall
end;

procedure Syscall_186; stdcall;
asm
  mov r10, rcx
  mov eax, $186
  syscall
end;

procedure Syscall_187; stdcall;
asm
  mov r10, rcx
  mov eax, $187
  syscall
end;

procedure Syscall_188; stdcall;
asm
  mov r10, rcx
  mov eax, $188
  syscall
end;

procedure Syscall_189; stdcall;
asm
  mov r10, rcx
  mov eax, $189
  syscall
end;

procedure Syscall_18A; stdcall;
asm
  mov r10, rcx
  mov eax, $18A
  syscall
end;

procedure Syscall_18B; stdcall;
asm
  mov r10, rcx
  mov eax, $18B
  syscall
end;

procedure Syscall_18C; stdcall;
asm
  mov r10, rcx
  mov eax, $18C
  syscall
end;

procedure Syscall_18D; stdcall;
asm
  mov r10, rcx
  mov eax, $18D
  syscall
end;

procedure Syscall_18E; stdcall;
asm
  mov r10, rcx
  mov eax, $18E
  syscall
end;

procedure Syscall_18F; stdcall;
asm
  mov r10, rcx
  mov eax, $18F
  syscall
end;

procedure Syscall_190; stdcall;
asm
  mov r10, rcx
  mov eax, $190
  syscall
end;

procedure Syscall_191; stdcall;
asm
  mov r10, rcx
  mov eax, $191
  syscall
end;

procedure Syscall_192; stdcall;
asm
  mov r10, rcx
  mov eax, $192
  syscall
end;

procedure Syscall_193; stdcall;
asm
  mov r10, rcx
  mov eax, $193
  syscall
end;

procedure Syscall_194; stdcall;
asm
  mov r10, rcx
  mov eax, $194
  syscall
end;

procedure Syscall_195; stdcall;
asm
  mov r10, rcx
  mov eax, $195
  syscall
end;

procedure Syscall_196; stdcall;
asm
  mov r10, rcx
  mov eax, $196
  syscall
end;

procedure Syscall_197; stdcall;
asm
  mov r10, rcx
  mov eax, $197
  syscall
end;

procedure Syscall_198; stdcall;
asm
  mov r10, rcx
  mov eax, $198
  syscall
end;

procedure Syscall_199; stdcall;
asm
  mov r10, rcx
  mov eax, $199
  syscall
end;

procedure Syscall_19A; stdcall;
asm
  mov r10, rcx
  mov eax, $19A
  syscall
end;

procedure Syscall_19B; stdcall;
asm
  mov r10, rcx
  mov eax, $19B
  syscall
end;

procedure Syscall_19C; stdcall;
asm
  mov r10, rcx
  mov eax, $19C
  syscall
end;

procedure Syscall_19D; stdcall;
asm
  mov r10, rcx
  mov eax, $19D
  syscall
end;

procedure Syscall_19E; stdcall;
asm
  mov r10, rcx
  mov eax, $19E
  syscall
end;

procedure Syscall_19F; stdcall;
asm
  mov r10, rcx
  mov eax, $19F
  syscall
end;

procedure Syscall_1A0; stdcall;
asm
  mov r10, rcx
  mov eax, $1A0
  syscall
end;

procedure Syscall_1A1; stdcall;
asm
  mov r10, rcx
  mov eax, $1A1
  syscall
end;

procedure Syscall_1A2; stdcall;
asm
  mov r10, rcx
  mov eax, $1A2
  syscall
end;

procedure Syscall_1A3; stdcall;
asm
  mov r10, rcx
  mov eax, $1A3
  syscall
end;

procedure Syscall_1A4; stdcall;
asm
  mov r10, rcx
  mov eax, $1A4
  syscall
end;

procedure Syscall_1A5; stdcall;
asm
  mov r10, rcx
  mov eax, $1A5
  syscall
end;

procedure Syscall_1A6; stdcall;
asm
  mov r10, rcx
  mov eax, $1A6
  syscall
end;

procedure Syscall_1A7; stdcall;
asm
  mov r10, rcx
  mov eax, $1A7
  syscall
end;

procedure Syscall_1A8; stdcall;
asm
  mov r10, rcx
  mov eax, $1A8
  syscall
end;

procedure Syscall_1A9; stdcall;
asm
  mov r10, rcx
  mov eax, $1A9
  syscall
end;

procedure Syscall_1AA; stdcall;
asm
  mov r10, rcx
  mov eax, $1AA
  syscall
end;

procedure Syscall_1AB; stdcall;
asm
  mov r10, rcx
  mov eax, $1AB
  syscall
end;

procedure Syscall_1AC; stdcall;
asm
  mov r10, rcx
  mov eax, $1AC
  syscall
end;

procedure Syscall_1AD; stdcall;
asm
  mov r10, rcx
  mov eax, $1AD
  syscall
end;

procedure Syscall_1AE; stdcall;
asm
  mov r10, rcx
  mov eax, $1AE
  syscall
end;

procedure Syscall_1AF; stdcall;
asm
  mov r10, rcx
  mov eax, $1AF
  syscall
end;

procedure Syscall_1B0; stdcall;
asm
  mov r10, rcx
  mov eax, $1B0
  syscall
end;

procedure Syscall_1B1; stdcall;
asm
  mov r10, rcx
  mov eax, $1B1
  syscall
end;

procedure Syscall_1B2; stdcall;
asm
  mov r10, rcx
  mov eax, $1B2
  syscall
end;

procedure Syscall_1B3; stdcall;
asm
  mov r10, rcx
  mov eax, $1B3
  syscall
end;

procedure Syscall_1B4; stdcall;
asm
  mov r10, rcx
  mov eax, $1B4
  syscall
end;

procedure Syscall_1B5; stdcall;
asm
  mov r10, rcx
  mov eax, $1B5
  syscall
end;

procedure Syscall_1B6; stdcall;
asm
  mov r10, rcx
  mov eax, $1B6
  syscall
end;

procedure Syscall_1B7; stdcall;
asm
  mov r10, rcx
  mov eax, $1B7
  syscall
end;

procedure Syscall_1B8; stdcall;
asm
  mov r10, rcx
  mov eax, $1B8
  syscall
end;

procedure Syscall_1B9; stdcall;
asm
  mov r10, rcx
  mov eax, $1B9
  syscall
end;

procedure Syscall_1BA; stdcall;
asm
  mov r10, rcx
  mov eax, $1BA
  syscall
end;

procedure Syscall_1BB; stdcall;
asm
  mov r10, rcx
  mov eax, $1BB
  syscall
end;

procedure Syscall_1BC; stdcall;
asm
  mov r10, rcx
  mov eax, $1BC
  syscall
end;

procedure Syscall_1BD; stdcall;
asm
  mov r10, rcx
  mov eax, $1BD
  syscall
end;

procedure Syscall_1BE; stdcall;
asm
  mov r10, rcx
  mov eax, $1BE
  syscall
end;

procedure Syscall_1BF; stdcall;
asm
  mov r10, rcx
  mov eax, $1BF
  syscall
end;

procedure Syscall_1C0; stdcall;
asm
  mov r10, rcx
  mov eax, $1C0
  syscall
end;

procedure Syscall_1C1; stdcall;
asm
  mov r10, rcx
  mov eax, $1C1
  syscall
end;

procedure Syscall_1C2; stdcall;
asm
  mov r10, rcx
  mov eax, $1C2
  syscall
end;

procedure Syscall_1C3; stdcall;
asm
  mov r10, rcx
  mov eax, $1C3
  syscall
end;

procedure Syscall_1C4; stdcall;
asm
  mov r10, rcx
  mov eax, $1C4
  syscall
end;

procedure Syscall_1C5; stdcall;
asm
  mov r10, rcx
  mov eax, $1C5
  syscall
end;

procedure Syscall_1C6; stdcall;
asm
  mov r10, rcx
  mov eax, $1C6
  syscall
end;

procedure Syscall_1C7; stdcall;
asm
  mov r10, rcx
  mov eax, $1C7
  syscall
end;

procedure Syscall_1C8; stdcall;
asm
  mov r10, rcx
  mov eax, $1C8
  syscall
end;

procedure Syscall_1C9; stdcall;
asm
  mov r10, rcx
  mov eax, $1C9
  syscall
end;

procedure Syscall_1CA; stdcall;
asm
  mov r10, rcx
  mov eax, $1CA
  syscall
end;

procedure Syscall_1CB; stdcall;
asm
  mov r10, rcx
  mov eax, $1CB
  syscall
end;

procedure Syscall_1CC; stdcall;
asm
  mov r10, rcx
  mov eax, $1CC
  syscall
end;

procedure Syscall_1CD; stdcall;
asm
  mov r10, rcx
  mov eax, $1CD
  syscall
end;

procedure Syscall_1CE; stdcall;
asm
  mov r10, rcx
  mov eax, $1CE
  syscall
end;

procedure Syscall_1CF; stdcall;
asm
  mov r10, rcx
  mov eax, $1CF
  syscall
end;

procedure Syscall_1D0; stdcall;
asm
  mov r10, rcx
  mov eax, $1D0
  syscall
end;

procedure Syscall_1D1; stdcall;
asm
  mov r10, rcx
  mov eax, $1D1
  syscall
end;

procedure Syscall_1D2; stdcall;
asm
  mov r10, rcx
  mov eax, $1D2
  syscall
end;

procedure Syscall_1D3; stdcall;
asm
  mov r10, rcx
  mov eax, $1D3
  syscall
end;

procedure Syscall_1D4; stdcall;
asm
  mov r10, rcx
  mov eax, $1D4
  syscall
end;

procedure Syscall_1D5; stdcall;
asm
  mov r10, rcx
  mov eax, $1D5
  syscall
end;

procedure Syscall_1D6; stdcall;
asm
  mov r10, rcx
  mov eax, $1D6
  syscall
end;

procedure Syscall_1D7; stdcall;
asm
  mov r10, rcx
  mov eax, $1D7
  syscall
end;

procedure Syscall_1D8; stdcall;
asm
  mov r10, rcx
  mov eax, $1D8
  syscall
end;

procedure Syscall_1D9; stdcall;
asm
  mov r10, rcx
  mov eax, $1D9
  syscall
end;

procedure Syscall_1DA; stdcall;
asm
  mov r10, rcx
  mov eax, $1DA
  syscall
end;

procedure Syscall_1DB; stdcall;
asm
  mov r10, rcx
  mov eax, $1DB
  syscall
end;

procedure Syscall_1DC; stdcall;
asm
  mov r10, rcx
  mov eax, $1DC
  syscall
end;

procedure Syscall_1DD; stdcall;
asm
  mov r10, rcx
  mov eax, $1DD
  syscall
end;

procedure Syscall_1DE; stdcall;
asm
  mov r10, rcx
  mov eax, $1DE
  syscall
end;

procedure Syscall_1DF; stdcall;
asm
  mov r10, rcx
  mov eax, $1DF
  syscall
end;

procedure Syscall_1E0; stdcall;
asm
  mov r10, rcx
  mov eax, $1E0
  syscall
end;

procedure Syscall_1E1; stdcall;
asm
  mov r10, rcx
  mov eax, $1E1
  syscall
end;

procedure Syscall_1E2; stdcall;
asm
  mov r10, rcx
  mov eax, $1E2
  syscall
end;

procedure Syscall_1E3; stdcall;
asm
  mov r10, rcx
  mov eax, $1E3
  syscall
end;

procedure Syscall_1E4; stdcall;
asm
  mov r10, rcx
  mov eax, $1E4
  syscall
end;

procedure Syscall_1E5; stdcall;
asm
  mov r10, rcx
  mov eax, $1E5
  syscall
end;

procedure Syscall_1E6; stdcall;
asm
  mov r10, rcx
  mov eax, $1E6
  syscall
end;

procedure Syscall_1E7; stdcall;
asm
  mov r10, rcx
  mov eax, $1E7
  syscall
end;

procedure Syscall_1E8; stdcall;
asm
  mov r10, rcx
  mov eax, $1E8
  syscall
end;

procedure Syscall_1E9; stdcall;
asm
  mov r10, rcx
  mov eax, $1E9
  syscall
end;

procedure Syscall_1EA; stdcall;
asm
  mov r10, rcx
  mov eax, $1EA
  syscall
end;

procedure Syscall_1EB; stdcall;
asm
  mov r10, rcx
  mov eax, $1EB
  syscall
end;

procedure Syscall_1EC; stdcall;
asm
  mov r10, rcx
  mov eax, $1EC
  syscall
end;

procedure Syscall_1ED; stdcall;
asm
  mov r10, rcx
  mov eax, $1ED
  syscall
end;

procedure Syscall_1EE; stdcall;
asm
  mov r10, rcx
  mov eax, $1EE
  syscall
end;

procedure Syscall_1EF; stdcall;
asm
  mov r10, rcx
  mov eax, $1EF
  syscall
end;

procedure Syscall_1F0; stdcall;
asm
  mov r10, rcx
  mov eax, $1F0
  syscall
end;

procedure Syscall_1F1; stdcall;
asm
  mov r10, rcx
  mov eax, $1F1
  syscall
end;

procedure Syscall_1F2; stdcall;
asm
  mov r10, rcx
  mov eax, $1F2
  syscall
end;

procedure Syscall_1F3; stdcall;
asm
  mov r10, rcx
  mov eax, $1F3
  syscall
end;

procedure Syscall_1F4; stdcall;
asm
  mov r10, rcx
  mov eax, $1F4
  syscall
end;

procedure Syscall_1F5; stdcall;
asm
  mov r10, rcx
  mov eax, $1F5
  syscall
end;

procedure Syscall_1F6; stdcall;
asm
  mov r10, rcx
  mov eax, $1F6
  syscall
end;

procedure Syscall_1F7; stdcall;
asm
  mov r10, rcx
  mov eax, $1F7
  syscall
end;

procedure Syscall_1F8; stdcall;
asm
  mov r10, rcx
  mov eax, $1F8
  syscall
end;

procedure Syscall_1F9; stdcall;
asm
  mov r10, rcx
  mov eax, $1F9
  syscall
end;

procedure Syscall_1FA; stdcall;
asm
  mov r10, rcx
  mov eax, $1FA
  syscall
end;

procedure Syscall_1FB; stdcall;
asm
  mov r10, rcx
  mov eax, $1FB
  syscall
end;

procedure Syscall_1FC; stdcall;
asm
  mov r10, rcx
  mov eax, $1FC
  syscall
end;

procedure Syscall_1FD; stdcall;
asm
  mov r10, rcx
  mov eax, $1FD
  syscall
end;

procedure Syscall_1FE; stdcall;
asm
  mov r10, rcx
  mov eax, $1FE
  syscall
end;

procedure Syscall_1FF; stdcall;
asm
  mov r10, rcx
  mov eax, $1FF
  syscall
end;

procedure Syscall_200; stdcall;
asm
  mov r10, rcx
  mov eax, $200
  syscall
end;

procedure Syscall_201; stdcall;
asm
  mov r10, rcx
  mov eax, $201
  syscall
end;

procedure Syscall_202; stdcall;
asm
  mov r10, rcx
  mov eax, $202
  syscall
end;

procedure Syscall_203; stdcall;
asm
  mov r10, rcx
  mov eax, $203
  syscall
end;

procedure Syscall_204; stdcall;
asm
  mov r10, rcx
  mov eax, $204
  syscall
end;

procedure Syscall_205; stdcall;
asm
  mov r10, rcx
  mov eax, $205
  syscall
end;

procedure Syscall_206; stdcall;
asm
  mov r10, rcx
  mov eax, $206
  syscall
end;

procedure Syscall_207; stdcall;
asm
  mov r10, rcx
  mov eax, $207
  syscall
end;

procedure Syscall_208; stdcall;
asm
  mov r10, rcx
  mov eax, $208
  syscall
end;

procedure Syscall_209; stdcall;
asm
  mov r10, rcx
  mov eax, $209
  syscall
end;

procedure Syscall_20A; stdcall;
asm
  mov r10, rcx
  mov eax, $20A
  syscall
end;

procedure Syscall_20B; stdcall;
asm
  mov r10, rcx
  mov eax, $20B
  syscall
end;

procedure Syscall_20C; stdcall;
asm
  mov r10, rcx
  mov eax, $20C
  syscall
end;

procedure Syscall_20D; stdcall;
asm
  mov r10, rcx
  mov eax, $20D
  syscall
end;

procedure Syscall_20E; stdcall;
asm
  mov r10, rcx
  mov eax, $20E
  syscall
end;

procedure Syscall_20F; stdcall;
asm
  mov r10, rcx
  mov eax, $20F
  syscall
end;

procedure Syscall_210; stdcall;
asm
  mov r10, rcx
  mov eax, $210
  syscall
end;

procedure Syscall_211; stdcall;
asm
  mov r10, rcx
  mov eax, $211
  syscall
end;

procedure Syscall_212; stdcall;
asm
  mov r10, rcx
  mov eax, $212
  syscall
end;

procedure Syscall_213; stdcall;
asm
  mov r10, rcx
  mov eax, $213
  syscall
end;

procedure Syscall_214; stdcall;
asm
  mov r10, rcx
  mov eax, $214
  syscall
end;

procedure Syscall_215; stdcall;
asm
  mov r10, rcx
  mov eax, $215
  syscall
end;

procedure Syscall_216; stdcall;
asm
  mov r10, rcx
  mov eax, $216
  syscall
end;

procedure Syscall_217; stdcall;
asm
  mov r10, rcx
  mov eax, $217
  syscall
end;

procedure Syscall_218; stdcall;
asm
  mov r10, rcx
  mov eax, $218
  syscall
end;

procedure Syscall_219; stdcall;
asm
  mov r10, rcx
  mov eax, $219
  syscall
end;

procedure Syscall_21A; stdcall;
asm
  mov r10, rcx
  mov eax, $21A
  syscall
end;

procedure Syscall_21B; stdcall;
asm
  mov r10, rcx
  mov eax, $21B
  syscall
end;

procedure Syscall_21C; stdcall;
asm
  mov r10, rcx
  mov eax, $21C
  syscall
end;

procedure Syscall_21D; stdcall;
asm
  mov r10, rcx
  mov eax, $21D
  syscall
end;

procedure Syscall_21E; stdcall;
asm
  mov r10, rcx
  mov eax, $21E
  syscall
end;

procedure Syscall_21F; stdcall;
asm
  mov r10, rcx
  mov eax, $21F
  syscall
end;

procedure Syscall_220; stdcall;
asm
  mov r10, rcx
  mov eax, $220
  syscall
end;

procedure Syscall_221; stdcall;
asm
  mov r10, rcx
  mov eax, $221
  syscall
end;

procedure Syscall_222; stdcall;
asm
  mov r10, rcx
  mov eax, $222
  syscall
end;

procedure Syscall_223; stdcall;
asm
  mov r10, rcx
  mov eax, $223
  syscall
end;

procedure Syscall_224; stdcall;
asm
  mov r10, rcx
  mov eax, $224
  syscall
end;

procedure Syscall_225; stdcall;
asm
  mov r10, rcx
  mov eax, $225
  syscall
end;

procedure Syscall_226; stdcall;
asm
  mov r10, rcx
  mov eax, $226
  syscall
end;

procedure Syscall_227; stdcall;
asm
  mov r10, rcx
  mov eax, $227
  syscall
end;

procedure Syscall_228; stdcall;
asm
  mov r10, rcx
  mov eax, $228
  syscall
end;

procedure Syscall_229; stdcall;
asm
  mov r10, rcx
  mov eax, $229
  syscall
end;

procedure Syscall_22A; stdcall;
asm
  mov r10, rcx
  mov eax, $22A
  syscall
end;

procedure Syscall_22B; stdcall;
asm
  mov r10, rcx
  mov eax, $22B
  syscall
end;

procedure Syscall_22C; stdcall;
asm
  mov r10, rcx
  mov eax, $22C
  syscall
end;

procedure Syscall_22D; stdcall;
asm
  mov r10, rcx
  mov eax, $22D
  syscall
end;

procedure Syscall_22E; stdcall;
asm
  mov r10, rcx
  mov eax, $22E
  syscall
end;

procedure Syscall_22F; stdcall;
asm
  mov r10, rcx
  mov eax, $22F
  syscall
end;

procedure Syscall_230; stdcall;
asm
  mov r10, rcx
  mov eax, $230
  syscall
end;

procedure Syscall_231; stdcall;
asm
  mov r10, rcx
  mov eax, $231
  syscall
end;

procedure Syscall_232; stdcall;
asm
  mov r10, rcx
  mov eax, $232
  syscall
end;

procedure Syscall_233; stdcall;
asm
  mov r10, rcx
  mov eax, $233
  syscall
end;

procedure Syscall_234; stdcall;
asm
  mov r10, rcx
  mov eax, $234
  syscall
end;

procedure Syscall_235; stdcall;
asm
  mov r10, rcx
  mov eax, $235
  syscall
end;

procedure Syscall_236; stdcall;
asm
  mov r10, rcx
  mov eax, $236
  syscall
end;

procedure Syscall_237; stdcall;
asm
  mov r10, rcx
  mov eax, $237
  syscall
end;

procedure Syscall_238; stdcall;
asm
  mov r10, rcx
  mov eax, $238
  syscall
end;

procedure Syscall_239; stdcall;
asm
  mov r10, rcx
  mov eax, $239
  syscall
end;

procedure Syscall_23A; stdcall;
asm
  mov r10, rcx
  mov eax, $23A
  syscall
end;

procedure Syscall_23B; stdcall;
asm
  mov r10, rcx
  mov eax, $23B
  syscall
end;

procedure Syscall_23C; stdcall;
asm
  mov r10, rcx
  mov eax, $23C
  syscall
end;

procedure Syscall_23D; stdcall;
asm
  mov r10, rcx
  mov eax, $23D
  syscall
end;

procedure Syscall_23E; stdcall;
asm
  mov r10, rcx
  mov eax, $23E
  syscall
end;

procedure Syscall_23F; stdcall;
asm
  mov r10, rcx
  mov eax, $23F
  syscall
end;

procedure Syscall_240; stdcall;
asm
  mov r10, rcx
  mov eax, $240
  syscall
end;

procedure Syscall_241; stdcall;
asm
  mov r10, rcx
  mov eax, $241
  syscall
end;

procedure Syscall_242; stdcall;
asm
  mov r10, rcx
  mov eax, $242
  syscall
end;

procedure Syscall_243; stdcall;
asm
  mov r10, rcx
  mov eax, $243
  syscall
end;

procedure Syscall_244; stdcall;
asm
  mov r10, rcx
  mov eax, $244
  syscall
end;

procedure Syscall_245; stdcall;
asm
  mov r10, rcx
  mov eax, $245
  syscall
end;

procedure Syscall_246; stdcall;
asm
  mov r10, rcx
  mov eax, $246
  syscall
end;

procedure Syscall_247; stdcall;
asm
  mov r10, rcx
  mov eax, $247
  syscall
end;

procedure Syscall_248; stdcall;
asm
  mov r10, rcx
  mov eax, $248
  syscall
end;

procedure Syscall_249; stdcall;
asm
  mov r10, rcx
  mov eax, $249
  syscall
end;

procedure Syscall_24A; stdcall;
asm
  mov r10, rcx
  mov eax, $24A
  syscall
end;

procedure Syscall_24B; stdcall;
asm
  mov r10, rcx
  mov eax, $24B
  syscall
end;

procedure Syscall_24C; stdcall;
asm
  mov r10, rcx
  mov eax, $24C
  syscall
end;

procedure Syscall_24D; stdcall;
asm
  mov r10, rcx
  mov eax, $24D
  syscall
end;

procedure Syscall_24E; stdcall;
asm
  mov r10, rcx
  mov eax, $24E
  syscall
end;

procedure Syscall_24F; stdcall;
asm
  mov r10, rcx
  mov eax, $24F
  syscall
end;

procedure Syscall_250; stdcall;
asm
  mov r10, rcx
  mov eax, $250
  syscall
end;

procedure Syscall_251; stdcall;
asm
  mov r10, rcx
  mov eax, $251
  syscall
end;

procedure Syscall_252; stdcall;
asm
  mov r10, rcx
  mov eax, $252
  syscall
end;

procedure Syscall_253; stdcall;
asm
  mov r10, rcx
  mov eax, $253
  syscall
end;

procedure Syscall_254; stdcall;
asm
  mov r10, rcx
  mov eax, $254
  syscall
end;

procedure Syscall_255; stdcall;
asm
  mov r10, rcx
  mov eax, $255
  syscall
end;

procedure Syscall_256; stdcall;
asm
  mov r10, rcx
  mov eax, $256
  syscall
end;

procedure Syscall_257; stdcall;
asm
  mov r10, rcx
  mov eax, $257
  syscall
end;

procedure Syscall_258; stdcall;
asm
  mov r10, rcx
  mov eax, $258
  syscall
end;

procedure Syscall_259; stdcall;
asm
  mov r10, rcx
  mov eax, $259
  syscall
end;

procedure Syscall_25A; stdcall;
asm
  mov r10, rcx
  mov eax, $25A
  syscall
end;

procedure Syscall_25B; stdcall;
asm
  mov r10, rcx
  mov eax, $25B
  syscall
end;

procedure Syscall_25C; stdcall;
asm
  mov r10, rcx
  mov eax, $25C
  syscall
end;

procedure Syscall_25D; stdcall;
asm
  mov r10, rcx
  mov eax, $25D
  syscall
end;

procedure Syscall_25E; stdcall;
asm
  mov r10, rcx
  mov eax, $25E
  syscall
end;

procedure Syscall_25F; stdcall;
asm
  mov r10, rcx
  mov eax, $25F
  syscall
end;

procedure Syscall_260; stdcall;
asm
  mov r10, rcx
  mov eax, $260
  syscall
end;

procedure Syscall_261; stdcall;
asm
  mov r10, rcx
  mov eax, $261
  syscall
end;

procedure Syscall_262; stdcall;
asm
  mov r10, rcx
  mov eax, $262
  syscall
end;

procedure Syscall_263; stdcall;
asm
  mov r10, rcx
  mov eax, $263
  syscall
end;

procedure Syscall_264; stdcall;
asm
  mov r10, rcx
  mov eax, $264
  syscall
end;

procedure Syscall_265; stdcall;
asm
  mov r10, rcx
  mov eax, $265
  syscall
end;

procedure Syscall_266; stdcall;
asm
  mov r10, rcx
  mov eax, $266
  syscall
end;

procedure Syscall_267; stdcall;
asm
  mov r10, rcx
  mov eax, $267
  syscall
end;

procedure Syscall_268; stdcall;
asm
  mov r10, rcx
  mov eax, $268
  syscall
end;

procedure Syscall_269; stdcall;
asm
  mov r10, rcx
  mov eax, $269
  syscall
end;

procedure Syscall_26A; stdcall;
asm
  mov r10, rcx
  mov eax, $26A
  syscall
end;

procedure Syscall_26B; stdcall;
asm
  mov r10, rcx
  mov eax, $26B
  syscall
end;

procedure Syscall_26C; stdcall;
asm
  mov r10, rcx
  mov eax, $26C
  syscall
end;

procedure Syscall_26D; stdcall;
asm
  mov r10, rcx
  mov eax, $26D
  syscall
end;

procedure Syscall_26E; stdcall;
asm
  mov r10, rcx
  mov eax, $26E
  syscall
end;

procedure Syscall_26F; stdcall;
asm
  mov r10, rcx
  mov eax, $26F
  syscall
end;

procedure Syscall_270; stdcall;
asm
  mov r10, rcx
  mov eax, $270
  syscall
end;

procedure Syscall_271; stdcall;
asm
  mov r10, rcx
  mov eax, $271
  syscall
end;

procedure Syscall_272; stdcall;
asm
  mov r10, rcx
  mov eax, $272
  syscall
end;

procedure Syscall_273; stdcall;
asm
  mov r10, rcx
  mov eax, $273
  syscall
end;

procedure Syscall_274; stdcall;
asm
  mov r10, rcx
  mov eax, $274
  syscall
end;

procedure Syscall_275; stdcall;
asm
  mov r10, rcx
  mov eax, $275
  syscall
end;

procedure Syscall_276; stdcall;
asm
  mov r10, rcx
  mov eax, $276
  syscall
end;

procedure Syscall_277; stdcall;
asm
  mov r10, rcx
  mov eax, $277
  syscall
end;

procedure Syscall_278; stdcall;
asm
  mov r10, rcx
  mov eax, $278
  syscall
end;

procedure Syscall_279; stdcall;
asm
  mov r10, rcx
  mov eax, $279
  syscall
end;

procedure Syscall_27A; stdcall;
asm
  mov r10, rcx
  mov eax, $27A
  syscall
end;

procedure Syscall_27B; stdcall;
asm
  mov r10, rcx
  mov eax, $27B
  syscall
end;

procedure Syscall_27C; stdcall;
asm
  mov r10, rcx
  mov eax, $27C
  syscall
end;

procedure Syscall_27D; stdcall;
asm
  mov r10, rcx
  mov eax, $27D
  syscall
end;

procedure Syscall_27E; stdcall;
asm
  mov r10, rcx
  mov eax, $27E
  syscall
end;

procedure Syscall_27F; stdcall;
asm
  mov r10, rcx
  mov eax, $27F
  syscall
end;

procedure Syscall_280; stdcall;
asm
  mov r10, rcx
  mov eax, $280
  syscall
end;

procedure Syscall_281; stdcall;
asm
  mov r10, rcx
  mov eax, $281
  syscall
end;

procedure Syscall_282; stdcall;
asm
  mov r10, rcx
  mov eax, $282
  syscall
end;

procedure Syscall_283; stdcall;
asm
  mov r10, rcx
  mov eax, $283
  syscall
end;

procedure Syscall_284; stdcall;
asm
  mov r10, rcx
  mov eax, $284
  syscall
end;

procedure Syscall_285; stdcall;
asm
  mov r10, rcx
  mov eax, $285
  syscall
end;

procedure Syscall_286; stdcall;
asm
  mov r10, rcx
  mov eax, $286
  syscall
end;

procedure Syscall_287; stdcall;
asm
  mov r10, rcx
  mov eax, $287
  syscall
end;

procedure Syscall_288; stdcall;
asm
  mov r10, rcx
  mov eax, $288
  syscall
end;

procedure Syscall_289; stdcall;
asm
  mov r10, rcx
  mov eax, $289
  syscall
end;

procedure Syscall_28A; stdcall;
asm
  mov r10, rcx
  mov eax, $28A
  syscall
end;

procedure Syscall_28B; stdcall;
asm
  mov r10, rcx
  mov eax, $28B
  syscall
end;

procedure Syscall_28C; stdcall;
asm
  mov r10, rcx
  mov eax, $28C
  syscall
end;

procedure Syscall_28D; stdcall;
asm
  mov r10, rcx
  mov eax, $28D
  syscall
end;

procedure Syscall_28E; stdcall;
asm
  mov r10, rcx
  mov eax, $28E
  syscall
end;

procedure Syscall_28F; stdcall;
asm
  mov r10, rcx
  mov eax, $28F
  syscall
end;

procedure Syscall_290; stdcall;
asm
  mov r10, rcx
  mov eax, $290
  syscall
end;

procedure Syscall_291; stdcall;
asm
  mov r10, rcx
  mov eax, $291
  syscall
end;

procedure Syscall_292; stdcall;
asm
  mov r10, rcx
  mov eax, $292
  syscall
end;

procedure Syscall_293; stdcall;
asm
  mov r10, rcx
  mov eax, $293
  syscall
end;

procedure Syscall_294; stdcall;
asm
  mov r10, rcx
  mov eax, $294
  syscall
end;

procedure Syscall_295; stdcall;
asm
  mov r10, rcx
  mov eax, $295
  syscall
end;

procedure Syscall_296; stdcall;
asm
  mov r10, rcx
  mov eax, $296
  syscall
end;

procedure Syscall_297; stdcall;
asm
  mov r10, rcx
  mov eax, $297
  syscall
end;

procedure Syscall_298; stdcall;
asm
  mov r10, rcx
  mov eax, $298
  syscall
end;

procedure Syscall_299; stdcall;
asm
  mov r10, rcx
  mov eax, $299
  syscall
end;

procedure Syscall_29A; stdcall;
asm
  mov r10, rcx
  mov eax, $29A
  syscall
end;

procedure Syscall_29B; stdcall;
asm
  mov r10, rcx
  mov eax, $29B
  syscall
end;

procedure Syscall_29C; stdcall;
asm
  mov r10, rcx
  mov eax, $29C
  syscall
end;

procedure Syscall_29D; stdcall;
asm
  mov r10, rcx
  mov eax, $29D
  syscall
end;

procedure Syscall_29E; stdcall;
asm
  mov r10, rcx
  mov eax, $29E
  syscall
end;

procedure Syscall_29F; stdcall;
asm
  mov r10, rcx
  mov eax, $29F
  syscall
end;

procedure Syscall_2A0; stdcall;
asm
  mov r10, rcx
  mov eax, $2A0
  syscall
end;

procedure Syscall_2A1; stdcall;
asm
  mov r10, rcx
  mov eax, $2A1
  syscall
end;

procedure Syscall_2A2; stdcall;
asm
  mov r10, rcx
  mov eax, $2A2
  syscall
end;

procedure Syscall_2A3; stdcall;
asm
  mov r10, rcx
  mov eax, $2A3
  syscall
end;

procedure Syscall_2A4; stdcall;
asm
  mov r10, rcx
  mov eax, $2A4
  syscall
end;

procedure Syscall_2A5; stdcall;
asm
  mov r10, rcx
  mov eax, $2A5
  syscall
end;

procedure Syscall_2A6; stdcall;
asm
  mov r10, rcx
  mov eax, $2A6
  syscall
end;

procedure Syscall_2A7; stdcall;
asm
  mov r10, rcx
  mov eax, $2A7
  syscall
end;

procedure Syscall_2A8; stdcall;
asm
  mov r10, rcx
  mov eax, $2A8
  syscall
end;

procedure Syscall_2A9; stdcall;
asm
  mov r10, rcx
  mov eax, $2A9
  syscall
end;

procedure Syscall_2AA; stdcall;
asm
  mov r10, rcx
  mov eax, $2AA
  syscall
end;

procedure Syscall_2AB; stdcall;
asm
  mov r10, rcx
  mov eax, $2AB
  syscall
end;

procedure Syscall_2AC; stdcall;
asm
  mov r10, rcx
  mov eax, $2AC
  syscall
end;

procedure Syscall_2AD; stdcall;
asm
  mov r10, rcx
  mov eax, $2AD
  syscall
end;

procedure Syscall_2AE; stdcall;
asm
  mov r10, rcx
  mov eax, $2AE
  syscall
end;

procedure Syscall_2AF; stdcall;
asm
  mov r10, rcx
  mov eax, $2AF
  syscall
end;

procedure Syscall_2B0; stdcall;
asm
  mov r10, rcx
  mov eax, $2B0
  syscall
end;

procedure Syscall_2B1; stdcall;
asm
  mov r10, rcx
  mov eax, $2B1
  syscall
end;

procedure Syscall_2B2; stdcall;
asm
  mov r10, rcx
  mov eax, $2B2
  syscall
end;

procedure Syscall_2B3; stdcall;
asm
  mov r10, rcx
  mov eax, $2B3
  syscall
end;

procedure Syscall_2B4; stdcall;
asm
  mov r10, rcx
  mov eax, $2B4
  syscall
end;

procedure Syscall_2B5; stdcall;
asm
  mov r10, rcx
  mov eax, $2B5
  syscall
end;

procedure Syscall_2B6; stdcall;
asm
  mov r10, rcx
  mov eax, $2B6
  syscall
end;

procedure Syscall_2B7; stdcall;
asm
  mov r10, rcx
  mov eax, $2B7
  syscall
end;

procedure Syscall_2B8; stdcall;
asm
  mov r10, rcx
  mov eax, $2B8
  syscall
end;

procedure Syscall_2B9; stdcall;
asm
  mov r10, rcx
  mov eax, $2B9
  syscall
end;

procedure Syscall_2BA; stdcall;
asm
  mov r10, rcx
  mov eax, $2BA
  syscall
end;

procedure Syscall_2BB; stdcall;
asm
  mov r10, rcx
  mov eax, $2BB
  syscall
end;

procedure Syscall_2BC; stdcall;
asm
  mov r10, rcx
  mov eax, $2BC
  syscall
end;

procedure Syscall_2BD; stdcall;
asm
  mov r10, rcx
  mov eax, $2BD
  syscall
end;

procedure Syscall_2BE; stdcall;
asm
  mov r10, rcx
  mov eax, $2BE
  syscall
end;

procedure Syscall_2BF; stdcall;
asm
  mov r10, rcx
  mov eax, $2BF
  syscall
end;

procedure Syscall_2C0; stdcall;
asm
  mov r10, rcx
  mov eax, $2C0
  syscall
end;

procedure Syscall_2C1; stdcall;
asm
  mov r10, rcx
  mov eax, $2C1
  syscall
end;

procedure Syscall_2C2; stdcall;
asm
  mov r10, rcx
  mov eax, $2C2
  syscall
end;

procedure Syscall_2C3; stdcall;
asm
  mov r10, rcx
  mov eax, $2C3
  syscall
end;

procedure Syscall_2C4; stdcall;
asm
  mov r10, rcx
  mov eax, $2C4
  syscall
end;

procedure Syscall_2C5; stdcall;
asm
  mov r10, rcx
  mov eax, $2C5
  syscall
end;

procedure Syscall_2C6; stdcall;
asm
  mov r10, rcx
  mov eax, $2C6
  syscall
end;

procedure Syscall_2C7; stdcall;
asm
  mov r10, rcx
  mov eax, $2C7
  syscall
end;

procedure Syscall_2C8; stdcall;
asm
  mov r10, rcx
  mov eax, $2C8
  syscall
end;

procedure Syscall_2C9; stdcall;
asm
  mov r10, rcx
  mov eax, $2C9
  syscall
end;

procedure Syscall_2CA; stdcall;
asm
  mov r10, rcx
  mov eax, $2CA
  syscall
end;

procedure Syscall_2CB; stdcall;
asm
  mov r10, rcx
  mov eax, $2CB
  syscall
end;

procedure Syscall_2CC; stdcall;
asm
  mov r10, rcx
  mov eax, $2CC
  syscall
end;

procedure Syscall_2CD; stdcall;
asm
  mov r10, rcx
  mov eax, $2CD
  syscall
end;

procedure Syscall_2CE; stdcall;
asm
  mov r10, rcx
  mov eax, $2CE
  syscall
end;

procedure Syscall_2CF; stdcall;
asm
  mov r10, rcx
  mov eax, $2CF
  syscall
end;

procedure Syscall_2D0; stdcall;
asm
  mov r10, rcx
  mov eax, $2D0
  syscall
end;

procedure Syscall_2D1; stdcall;
asm
  mov r10, rcx
  mov eax, $2D1
  syscall
end;

procedure Syscall_2D2; stdcall;
asm
  mov r10, rcx
  mov eax, $2D2
  syscall
end;

procedure Syscall_2D3; stdcall;
asm
  mov r10, rcx
  mov eax, $2D3
  syscall
end;

procedure Syscall_2D4; stdcall;
asm
  mov r10, rcx
  mov eax, $2D4
  syscall
end;

procedure Syscall_2D5; stdcall;
asm
  mov r10, rcx
  mov eax, $2D5
  syscall
end;

procedure Syscall_2D6; stdcall;
asm
  mov r10, rcx
  mov eax, $2D6
  syscall
end;

procedure Syscall_2D7; stdcall;
asm
  mov r10, rcx
  mov eax, $2D7
  syscall
end;

procedure Syscall_2D8; stdcall;
asm
  mov r10, rcx
  mov eax, $2D8
  syscall
end;

procedure Syscall_2D9; stdcall;
asm
  mov r10, rcx
  mov eax, $2D9
  syscall
end;

procedure Syscall_2DA; stdcall;
asm
  mov r10, rcx
  mov eax, $2DA
  syscall
end;

procedure Syscall_2DB; stdcall;
asm
  mov r10, rcx
  mov eax, $2DB
  syscall
end;

procedure Syscall_2DC; stdcall;
asm
  mov r10, rcx
  mov eax, $2DC
  syscall
end;

procedure Syscall_2DD; stdcall;
asm
  mov r10, rcx
  mov eax, $2DD
  syscall
end;

procedure Syscall_2DE; stdcall;
asm
  mov r10, rcx
  mov eax, $2DE
  syscall
end;

procedure Syscall_2DF; stdcall;
asm
  mov r10, rcx
  mov eax, $2DF
  syscall
end;

procedure Syscall_2E0; stdcall;
asm
  mov r10, rcx
  mov eax, $2E0
  syscall
end;

procedure Syscall_2E1; stdcall;
asm
  mov r10, rcx
  mov eax, $2E1
  syscall
end;

procedure Syscall_2E2; stdcall;
asm
  mov r10, rcx
  mov eax, $2E2
  syscall
end;

procedure Syscall_2E3; stdcall;
asm
  mov r10, rcx
  mov eax, $2E3
  syscall
end;

procedure Syscall_2E4; stdcall;
asm
  mov r10, rcx
  mov eax, $2E4
  syscall
end;

procedure Syscall_2E5; stdcall;
asm
  mov r10, rcx
  mov eax, $2E5
  syscall
end;

procedure Syscall_2E6; stdcall;
asm
  mov r10, rcx
  mov eax, $2E6
  syscall
end;

procedure Syscall_2E7; stdcall;
asm
  mov r10, rcx
  mov eax, $2E7
  syscall
end;

procedure Syscall_2E8; stdcall;
asm
  mov r10, rcx
  mov eax, $2E8
  syscall
end;

procedure Syscall_2E9; stdcall;
asm
  mov r10, rcx
  mov eax, $2E9
  syscall
end;

procedure Syscall_2EA; stdcall;
asm
  mov r10, rcx
  mov eax, $2EA
  syscall
end;

procedure Syscall_2EB; stdcall;
asm
  mov r10, rcx
  mov eax, $2EB
  syscall
end;

procedure Syscall_2EC; stdcall;
asm
  mov r10, rcx
  mov eax, $2EC
  syscall
end;

procedure Syscall_2ED; stdcall;
asm
  mov r10, rcx
  mov eax, $2ED
  syscall
end;

procedure Syscall_2EE; stdcall;
asm
  mov r10, rcx
  mov eax, $2EE
  syscall
end;

procedure Syscall_2EF; stdcall;
asm
  mov r10, rcx
  mov eax, $2EF
  syscall
end;

procedure Syscall_2F0; stdcall;
asm
  mov r10, rcx
  mov eax, $2F0
  syscall
end;

procedure Syscall_2F1; stdcall;
asm
  mov r10, rcx
  mov eax, $2F1
  syscall
end;

procedure Syscall_2F2; stdcall;
asm
  mov r10, rcx
  mov eax, $2F2
  syscall
end;

procedure Syscall_2F3; stdcall;
asm
  mov r10, rcx
  mov eax, $2F3
  syscall
end;

procedure Syscall_2F4; stdcall;
asm
  mov r10, rcx
  mov eax, $2F4
  syscall
end;

procedure Syscall_2F5; stdcall;
asm
  mov r10, rcx
  mov eax, $2F5
  syscall
end;

procedure Syscall_2F6; stdcall;
asm
  mov r10, rcx
  mov eax, $2F6
  syscall
end;

procedure Syscall_2F7; stdcall;
asm
  mov r10, rcx
  mov eax, $2F7
  syscall
end;

procedure Syscall_2F8; stdcall;
asm
  mov r10, rcx
  mov eax, $2F8
  syscall
end;

procedure Syscall_2F9; stdcall;
asm
  mov r10, rcx
  mov eax, $2F9
  syscall
end;

procedure Syscall_2FA; stdcall;
asm
  mov r10, rcx
  mov eax, $2FA
  syscall
end;

procedure Syscall_2FB; stdcall;
asm
  mov r10, rcx
  mov eax, $2FB
  syscall
end;

procedure Syscall_2FC; stdcall;
asm
  mov r10, rcx
  mov eax, $2FC
  syscall
end;

procedure Syscall_2FD; stdcall;
asm
  mov r10, rcx
  mov eax, $2FD
  syscall
end;

procedure Syscall_2FE; stdcall;
asm
  mov r10, rcx
  mov eax, $2FE
  syscall
end;

procedure Syscall_2FF; stdcall;
asm
  mov r10, rcx
  mov eax, $2FF
  syscall
end;

procedure Syscall_300; stdcall;
asm
  mov r10, rcx
  mov eax, $300
  syscall
end;

procedure Syscall_301; stdcall;
asm
  mov r10, rcx
  mov eax, $301
  syscall
end;

procedure Syscall_302; stdcall;
asm
  mov r10, rcx
  mov eax, $302
  syscall
end;

procedure Syscall_303; stdcall;
asm
  mov r10, rcx
  mov eax, $303
  syscall
end;

procedure Syscall_304; stdcall;
asm
  mov r10, rcx
  mov eax, $304
  syscall
end;

procedure Syscall_305; stdcall;
asm
  mov r10, rcx
  mov eax, $305
  syscall
end;

procedure Syscall_306; stdcall;
asm
  mov r10, rcx
  mov eax, $306
  syscall
end;

procedure Syscall_307; stdcall;
asm
  mov r10, rcx
  mov eax, $307
  syscall
end;

procedure Syscall_308; stdcall;
asm
  mov r10, rcx
  mov eax, $308
  syscall
end;

procedure Syscall_309; stdcall;
asm
  mov r10, rcx
  mov eax, $309
  syscall
end;

procedure Syscall_30A; stdcall;
asm
  mov r10, rcx
  mov eax, $30A
  syscall
end;

procedure Syscall_30B; stdcall;
asm
  mov r10, rcx
  mov eax, $30B
  syscall
end;

procedure Syscall_30C; stdcall;
asm
  mov r10, rcx
  mov eax, $30C
  syscall
end;

procedure Syscall_30D; stdcall;
asm
  mov r10, rcx
  mov eax, $30D
  syscall
end;

procedure Syscall_30E; stdcall;
asm
  mov r10, rcx
  mov eax, $30E
  syscall
end;

procedure Syscall_30F; stdcall;
asm
  mov r10, rcx
  mov eax, $30F
  syscall
end;

procedure Syscall_310; stdcall;
asm
  mov r10, rcx
  mov eax, $310
  syscall
end;

procedure Syscall_311; stdcall;
asm
  mov r10, rcx
  mov eax, $311
  syscall
end;

procedure Syscall_312; stdcall;
asm
  mov r10, rcx
  mov eax, $312
  syscall
end;

procedure Syscall_313; stdcall;
asm
  mov r10, rcx
  mov eax, $313
  syscall
end;

procedure Syscall_314; stdcall;
asm
  mov r10, rcx
  mov eax, $314
  syscall
end;

procedure Syscall_315; stdcall;
asm
  mov r10, rcx
  mov eax, $315
  syscall
end;

procedure Syscall_316; stdcall;
asm
  mov r10, rcx
  mov eax, $316
  syscall
end;

procedure Syscall_317; stdcall;
asm
  mov r10, rcx
  mov eax, $317
  syscall
end;

procedure Syscall_318; stdcall;
asm
  mov r10, rcx
  mov eax, $318
  syscall
end;

procedure Syscall_319; stdcall;
asm
  mov r10, rcx
  mov eax, $319
  syscall
end;

procedure Syscall_31A; stdcall;
asm
  mov r10, rcx
  mov eax, $31A
  syscall
end;

procedure Syscall_31B; stdcall;
asm
  mov r10, rcx
  mov eax, $31B
  syscall
end;

procedure Syscall_31C; stdcall;
asm
  mov r10, rcx
  mov eax, $31C
  syscall
end;

procedure Syscall_31D; stdcall;
asm
  mov r10, rcx
  mov eax, $31D
  syscall
end;

procedure Syscall_31E; stdcall;
asm
  mov r10, rcx
  mov eax, $31E
  syscall
end;

procedure Syscall_31F; stdcall;
asm
  mov r10, rcx
  mov eax, $31F
  syscall
end;

procedure Syscall_320; stdcall;
asm
  mov r10, rcx
  mov eax, $320
  syscall
end;

procedure Syscall_321; stdcall;
asm
  mov r10, rcx
  mov eax, $321
  syscall
end;

procedure Syscall_322; stdcall;
asm
  mov r10, rcx
  mov eax, $322
  syscall
end;

procedure Syscall_323; stdcall;
asm
  mov r10, rcx
  mov eax, $323
  syscall
end;

procedure Syscall_324; stdcall;
asm
  mov r10, rcx
  mov eax, $324
  syscall
end;

procedure Syscall_325; stdcall;
asm
  mov r10, rcx
  mov eax, $325
  syscall
end;

procedure Syscall_326; stdcall;
asm
  mov r10, rcx
  mov eax, $326
  syscall
end;

procedure Syscall_327; stdcall;
asm
  mov r10, rcx
  mov eax, $327
  syscall
end;

procedure Syscall_328; stdcall;
asm
  mov r10, rcx
  mov eax, $328
  syscall
end;

procedure Syscall_329; stdcall;
asm
  mov r10, rcx
  mov eax, $329
  syscall
end;

procedure Syscall_32A; stdcall;
asm
  mov r10, rcx
  mov eax, $32A
  syscall
end;

procedure Syscall_32B; stdcall;
asm
  mov r10, rcx
  mov eax, $32B
  syscall
end;

procedure Syscall_32C; stdcall;
asm
  mov r10, rcx
  mov eax, $32C
  syscall
end;

procedure Syscall_32D; stdcall;
asm
  mov r10, rcx
  mov eax, $32D
  syscall
end;

procedure Syscall_32E; stdcall;
asm
  mov r10, rcx
  mov eax, $32E
  syscall
end;

procedure Syscall_32F; stdcall;
asm
  mov r10, rcx
  mov eax, $32F
  syscall
end;

procedure Syscall_330; stdcall;
asm
  mov r10, rcx
  mov eax, $330
  syscall
end;

procedure Syscall_331; stdcall;
asm
  mov r10, rcx
  mov eax, $331
  syscall
end;

procedure Syscall_332; stdcall;
asm
  mov r10, rcx
  mov eax, $332
  syscall
end;

procedure Syscall_333; stdcall;
asm
  mov r10, rcx
  mov eax, $333
  syscall
end;

procedure Syscall_334; stdcall;
asm
  mov r10, rcx
  mov eax, $334
  syscall
end;

procedure Syscall_335; stdcall;
asm
  mov r10, rcx
  mov eax, $335
  syscall
end;

procedure Syscall_336; stdcall;
asm
  mov r10, rcx
  mov eax, $336
  syscall
end;

procedure Syscall_337; stdcall;
asm
  mov r10, rcx
  mov eax, $337
  syscall
end;

procedure Syscall_338; stdcall;
asm
  mov r10, rcx
  mov eax, $338
  syscall
end;

procedure Syscall_339; stdcall;
asm
  mov r10, rcx
  mov eax, $339
  syscall
end;

procedure Syscall_33A; stdcall;
asm
  mov r10, rcx
  mov eax, $33A
  syscall
end;

procedure Syscall_33B; stdcall;
asm
  mov r10, rcx
  mov eax, $33B
  syscall
end;

procedure Syscall_33C; stdcall;
asm
  mov r10, rcx
  mov eax, $33C
  syscall
end;

procedure Syscall_33D; stdcall;
asm
  mov r10, rcx
  mov eax, $33D
  syscall
end;

procedure Syscall_33E; stdcall;
asm
  mov r10, rcx
  mov eax, $33E
  syscall
end;

procedure Syscall_33F; stdcall;
asm
  mov r10, rcx
  mov eax, $33F
  syscall
end;

procedure Syscall_340; stdcall;
asm
  mov r10, rcx
  mov eax, $340
  syscall
end;

procedure Syscall_341; stdcall;
asm
  mov r10, rcx
  mov eax, $341
  syscall
end;

procedure Syscall_342; stdcall;
asm
  mov r10, rcx
  mov eax, $342
  syscall
end;

procedure Syscall_343; stdcall;
asm
  mov r10, rcx
  mov eax, $343
  syscall
end;

procedure Syscall_344; stdcall;
asm
  mov r10, rcx
  mov eax, $344
  syscall
end;

procedure Syscall_345; stdcall;
asm
  mov r10, rcx
  mov eax, $345
  syscall
end;

procedure Syscall_346; stdcall;
asm
  mov r10, rcx
  mov eax, $346
  syscall
end;

procedure Syscall_347; stdcall;
asm
  mov r10, rcx
  mov eax, $347
  syscall
end;

procedure Syscall_348; stdcall;
asm
  mov r10, rcx
  mov eax, $348
  syscall
end;

procedure Syscall_349; stdcall;
asm
  mov r10, rcx
  mov eax, $349
  syscall
end;

procedure Syscall_34A; stdcall;
asm
  mov r10, rcx
  mov eax, $34A
  syscall
end;

procedure Syscall_34B; stdcall;
asm
  mov r10, rcx
  mov eax, $34B
  syscall
end;

procedure Syscall_34C; stdcall;
asm
  mov r10, rcx
  mov eax, $34C
  syscall
end;

procedure Syscall_34D; stdcall;
asm
  mov r10, rcx
  mov eax, $34D
  syscall
end;

procedure Syscall_34E; stdcall;
asm
  mov r10, rcx
  mov eax, $34E
  syscall
end;

procedure Syscall_34F; stdcall;
asm
  mov r10, rcx
  mov eax, $34F
  syscall
end;

procedure Syscall_350; stdcall;
asm
  mov r10, rcx
  mov eax, $350
  syscall
end;

procedure Syscall_351; stdcall;
asm
  mov r10, rcx
  mov eax, $351
  syscall
end;

procedure Syscall_352; stdcall;
asm
  mov r10, rcx
  mov eax, $352
  syscall
end;

procedure Syscall_353; stdcall;
asm
  mov r10, rcx
  mov eax, $353
  syscall
end;

procedure Syscall_354; stdcall;
asm
  mov r10, rcx
  mov eax, $354
  syscall
end;

procedure Syscall_355; stdcall;
asm
  mov r10, rcx
  mov eax, $355
  syscall
end;

procedure Syscall_356; stdcall;
asm
  mov r10, rcx
  mov eax, $356
  syscall
end;

procedure Syscall_357; stdcall;
asm
  mov r10, rcx
  mov eax, $357
  syscall
end;

procedure Syscall_358; stdcall;
asm
  mov r10, rcx
  mov eax, $358
  syscall
end;

procedure Syscall_359; stdcall;
asm
  mov r10, rcx
  mov eax, $359
  syscall
end;

procedure Syscall_35A; stdcall;
asm
  mov r10, rcx
  mov eax, $35A
  syscall
end;

procedure Syscall_35B; stdcall;
asm
  mov r10, rcx
  mov eax, $35B
  syscall
end;

procedure Syscall_35C; stdcall;
asm
  mov r10, rcx
  mov eax, $35C
  syscall
end;

procedure Syscall_35D; stdcall;
asm
  mov r10, rcx
  mov eax, $35D
  syscall
end;

procedure Syscall_35E; stdcall;
asm
  mov r10, rcx
  mov eax, $35E
  syscall
end;

procedure Syscall_35F; stdcall;
asm
  mov r10, rcx
  mov eax, $35F
  syscall
end;

procedure Syscall_360; stdcall;
asm
  mov r10, rcx
  mov eax, $360
  syscall
end;

procedure Syscall_361; stdcall;
asm
  mov r10, rcx
  mov eax, $361
  syscall
end;

procedure Syscall_362; stdcall;
asm
  mov r10, rcx
  mov eax, $362
  syscall
end;

procedure Syscall_363; stdcall;
asm
  mov r10, rcx
  mov eax, $363
  syscall
end;

procedure Syscall_364; stdcall;
asm
  mov r10, rcx
  mov eax, $364
  syscall
end;

procedure Syscall_365; stdcall;
asm
  mov r10, rcx
  mov eax, $365
  syscall
end;

procedure Syscall_366; stdcall;
asm
  mov r10, rcx
  mov eax, $366
  syscall
end;

procedure Syscall_367; stdcall;
asm
  mov r10, rcx
  mov eax, $367
  syscall
end;

procedure Syscall_368; stdcall;
asm
  mov r10, rcx
  mov eax, $368
  syscall
end;

procedure Syscall_369; stdcall;
asm
  mov r10, rcx
  mov eax, $369
  syscall
end;

procedure Syscall_36A; stdcall;
asm
  mov r10, rcx
  mov eax, $36A
  syscall
end;

procedure Syscall_36B; stdcall;
asm
  mov r10, rcx
  mov eax, $36B
  syscall
end;

procedure Syscall_36C; stdcall;
asm
  mov r10, rcx
  mov eax, $36C
  syscall
end;

procedure Syscall_36D; stdcall;
asm
  mov r10, rcx
  mov eax, $36D
  syscall
end;

procedure Syscall_36E; stdcall;
asm
  mov r10, rcx
  mov eax, $36E
  syscall
end;

procedure Syscall_36F; stdcall;
asm
  mov r10, rcx
  mov eax, $36F
  syscall
end;

procedure Syscall_370; stdcall;
asm
  mov r10, rcx
  mov eax, $370
  syscall
end;

procedure Syscall_371; stdcall;
asm
  mov r10, rcx
  mov eax, $371
  syscall
end;

procedure Syscall_372; stdcall;
asm
  mov r10, rcx
  mov eax, $372
  syscall
end;

procedure Syscall_373; stdcall;
asm
  mov r10, rcx
  mov eax, $373
  syscall
end;

procedure Syscall_374; stdcall;
asm
  mov r10, rcx
  mov eax, $374
  syscall
end;

procedure Syscall_375; stdcall;
asm
  mov r10, rcx
  mov eax, $375
  syscall
end;

procedure Syscall_376; stdcall;
asm
  mov r10, rcx
  mov eax, $376
  syscall
end;

procedure Syscall_377; stdcall;
asm
  mov r10, rcx
  mov eax, $377
  syscall
end;

procedure Syscall_378; stdcall;
asm
  mov r10, rcx
  mov eax, $378
  syscall
end;

procedure Syscall_379; stdcall;
asm
  mov r10, rcx
  mov eax, $379
  syscall
end;

procedure Syscall_37A; stdcall;
asm
  mov r10, rcx
  mov eax, $37A
  syscall
end;

procedure Syscall_37B; stdcall;
asm
  mov r10, rcx
  mov eax, $37B
  syscall
end;

procedure Syscall_37C; stdcall;
asm
  mov r10, rcx
  mov eax, $37C
  syscall
end;

procedure Syscall_37D; stdcall;
asm
  mov r10, rcx
  mov eax, $37D
  syscall
end;

procedure Syscall_37E; stdcall;
asm
  mov r10, rcx
  mov eax, $37E
  syscall
end;

procedure Syscall_37F; stdcall;
asm
  mov r10, rcx
  mov eax, $37F
  syscall
end;

procedure Syscall_380; stdcall;
asm
  mov r10, rcx
  mov eax, $380
  syscall
end;

procedure Syscall_381; stdcall;
asm
  mov r10, rcx
  mov eax, $381
  syscall
end;

procedure Syscall_382; stdcall;
asm
  mov r10, rcx
  mov eax, $382
  syscall
end;

procedure Syscall_383; stdcall;
asm
  mov r10, rcx
  mov eax, $383
  syscall
end;

procedure Syscall_384; stdcall;
asm
  mov r10, rcx
  mov eax, $384
  syscall
end;

procedure Syscall_385; stdcall;
asm
  mov r10, rcx
  mov eax, $385
  syscall
end;

procedure Syscall_386; stdcall;
asm
  mov r10, rcx
  mov eax, $386
  syscall
end;

procedure Syscall_387; stdcall;
asm
  mov r10, rcx
  mov eax, $387
  syscall
end;

procedure Syscall_388; stdcall;
asm
  mov r10, rcx
  mov eax, $388
  syscall
end;

procedure Syscall_389; stdcall;
asm
  mov r10, rcx
  mov eax, $389
  syscall
end;

procedure Syscall_38A; stdcall;
asm
  mov r10, rcx
  mov eax, $38A
  syscall
end;

procedure Syscall_38B; stdcall;
asm
  mov r10, rcx
  mov eax, $38B
  syscall
end;

procedure Syscall_38C; stdcall;
asm
  mov r10, rcx
  mov eax, $38C
  syscall
end;

procedure Syscall_38D; stdcall;
asm
  mov r10, rcx
  mov eax, $38D
  syscall
end;

procedure Syscall_38E; stdcall;
asm
  mov r10, rcx
  mov eax, $38E
  syscall
end;

procedure Syscall_38F; stdcall;
asm
  mov r10, rcx
  mov eax, $38F
  syscall
end;

procedure Syscall_390; stdcall;
asm
  mov r10, rcx
  mov eax, $390
  syscall
end;

procedure Syscall_391; stdcall;
asm
  mov r10, rcx
  mov eax, $391
  syscall
end;

procedure Syscall_392; stdcall;
asm
  mov r10, rcx
  mov eax, $392
  syscall
end;

procedure Syscall_393; stdcall;
asm
  mov r10, rcx
  mov eax, $393
  syscall
end;

procedure Syscall_394; stdcall;
asm
  mov r10, rcx
  mov eax, $394
  syscall
end;

procedure Syscall_395; stdcall;
asm
  mov r10, rcx
  mov eax, $395
  syscall
end;

procedure Syscall_396; stdcall;
asm
  mov r10, rcx
  mov eax, $396
  syscall
end;

procedure Syscall_397; stdcall;
asm
  mov r10, rcx
  mov eax, $397
  syscall
end;

procedure Syscall_398; stdcall;
asm
  mov r10, rcx
  mov eax, $398
  syscall
end;

procedure Syscall_399; stdcall;
asm
  mov r10, rcx
  mov eax, $399
  syscall
end;

procedure Syscall_39A; stdcall;
asm
  mov r10, rcx
  mov eax, $39A
  syscall
end;

procedure Syscall_39B; stdcall;
asm
  mov r10, rcx
  mov eax, $39B
  syscall
end;

procedure Syscall_39C; stdcall;
asm
  mov r10, rcx
  mov eax, $39C
  syscall
end;

procedure Syscall_39D; stdcall;
asm
  mov r10, rcx
  mov eax, $39D
  syscall
end;

procedure Syscall_39E; stdcall;
asm
  mov r10, rcx
  mov eax, $39E
  syscall
end;

procedure Syscall_39F; stdcall;
asm
  mov r10, rcx
  mov eax, $39F
  syscall
end;

procedure Syscall_3A0; stdcall;
asm
  mov r10, rcx
  mov eax, $3A0
  syscall
end;

procedure Syscall_3A1; stdcall;
asm
  mov r10, rcx
  mov eax, $3A1
  syscall
end;

procedure Syscall_3A2; stdcall;
asm
  mov r10, rcx
  mov eax, $3A2
  syscall
end;

procedure Syscall_3A3; stdcall;
asm
  mov r10, rcx
  mov eax, $3A3
  syscall
end;

procedure Syscall_3A4; stdcall;
asm
  mov r10, rcx
  mov eax, $3A4
  syscall
end;

procedure Syscall_3A5; stdcall;
asm
  mov r10, rcx
  mov eax, $3A5
  syscall
end;

procedure Syscall_3A6; stdcall;
asm
  mov r10, rcx
  mov eax, $3A6
  syscall
end;

procedure Syscall_3A7; stdcall;
asm
  mov r10, rcx
  mov eax, $3A7
  syscall
end;

procedure Syscall_3A8; stdcall;
asm
  mov r10, rcx
  mov eax, $3A8
  syscall
end;

procedure Syscall_3A9; stdcall;
asm
  mov r10, rcx
  mov eax, $3A9
  syscall
end;

procedure Syscall_3AA; stdcall;
asm
  mov r10, rcx
  mov eax, $3AA
  syscall
end;

procedure Syscall_3AB; stdcall;
asm
  mov r10, rcx
  mov eax, $3AB
  syscall
end;

procedure Syscall_3AC; stdcall;
asm
  mov r10, rcx
  mov eax, $3AC
  syscall
end;

procedure Syscall_3AD; stdcall;
asm
  mov r10, rcx
  mov eax, $3AD
  syscall
end;

procedure Syscall_3AE; stdcall;
asm
  mov r10, rcx
  mov eax, $3AE
  syscall
end;

procedure Syscall_3AF; stdcall;
asm
  mov r10, rcx
  mov eax, $3AF
  syscall
end;

procedure Syscall_3B0; stdcall;
asm
  mov r10, rcx
  mov eax, $3B0
  syscall
end;

procedure Syscall_3B1; stdcall;
asm
  mov r10, rcx
  mov eax, $3B1
  syscall
end;

procedure Syscall_3B2; stdcall;
asm
  mov r10, rcx
  mov eax, $3B2
  syscall
end;

procedure Syscall_3B3; stdcall;
asm
  mov r10, rcx
  mov eax, $3B3
  syscall
end;

procedure Syscall_3B4; stdcall;
asm
  mov r10, rcx
  mov eax, $3B4
  syscall
end;

procedure Syscall_3B5; stdcall;
asm
  mov r10, rcx
  mov eax, $3B5
  syscall
end;

procedure Syscall_3B6; stdcall;
asm
  mov r10, rcx
  mov eax, $3B6
  syscall
end;

procedure Syscall_3B7; stdcall;
asm
  mov r10, rcx
  mov eax, $3B7
  syscall
end;

procedure Syscall_3B8; stdcall;
asm
  mov r10, rcx
  mov eax, $3B8
  syscall
end;

procedure Syscall_3B9; stdcall;
asm
  mov r10, rcx
  mov eax, $3B9
  syscall
end;

procedure Syscall_3BA; stdcall;
asm
  mov r10, rcx
  mov eax, $3BA
  syscall
end;

procedure Syscall_3BB; stdcall;
asm
  mov r10, rcx
  mov eax, $3BB
  syscall
end;

procedure Syscall_3BC; stdcall;
asm
  mov r10, rcx
  mov eax, $3BC
  syscall
end;

procedure Syscall_3BD; stdcall;
asm
  mov r10, rcx
  mov eax, $3BD
  syscall
end;

procedure Syscall_3BE; stdcall;
asm
  mov r10, rcx
  mov eax, $3BE
  syscall
end;

procedure Syscall_3BF; stdcall;
asm
  mov r10, rcx
  mov eax, $3BF
  syscall
end;

procedure Syscall_3C0; stdcall;
asm
  mov r10, rcx
  mov eax, $3C0
  syscall
end;

procedure Syscall_3C1; stdcall;
asm
  mov r10, rcx
  mov eax, $3C1
  syscall
end;

procedure Syscall_3C2; stdcall;
asm
  mov r10, rcx
  mov eax, $3C2
  syscall
end;

procedure Syscall_3C3; stdcall;
asm
  mov r10, rcx
  mov eax, $3C3
  syscall
end;

procedure Syscall_3C4; stdcall;
asm
  mov r10, rcx
  mov eax, $3C4
  syscall
end;

procedure Syscall_3C5; stdcall;
asm
  mov r10, rcx
  mov eax, $3C5
  syscall
end;

procedure Syscall_3C6; stdcall;
asm
  mov r10, rcx
  mov eax, $3C6
  syscall
end;

procedure Syscall_3C7; stdcall;
asm
  mov r10, rcx
  mov eax, $3C7
  syscall
end;

procedure Syscall_3C8; stdcall;
asm
  mov r10, rcx
  mov eax, $3C8
  syscall
end;

procedure Syscall_3C9; stdcall;
asm
  mov r10, rcx
  mov eax, $3C9
  syscall
end;

procedure Syscall_3CA; stdcall;
asm
  mov r10, rcx
  mov eax, $3CA
  syscall
end;

procedure Syscall_3CB; stdcall;
asm
  mov r10, rcx
  mov eax, $3CB
  syscall
end;

procedure Syscall_3CC; stdcall;
asm
  mov r10, rcx
  mov eax, $3CC
  syscall
end;

procedure Syscall_3CD; stdcall;
asm
  mov r10, rcx
  mov eax, $3CD
  syscall
end;

procedure Syscall_3CE; stdcall;
asm
  mov r10, rcx
  mov eax, $3CE
  syscall
end;

procedure Syscall_3CF; stdcall;
asm
  mov r10, rcx
  mov eax, $3CF
  syscall
end;

procedure Syscall_3D0; stdcall;
asm
  mov r10, rcx
  mov eax, $3D0
  syscall
end;

procedure Syscall_3D1; stdcall;
asm
  mov r10, rcx
  mov eax, $3D1
  syscall
end;

procedure Syscall_3D2; stdcall;
asm
  mov r10, rcx
  mov eax, $3D2
  syscall
end;

procedure Syscall_3D3; stdcall;
asm
  mov r10, rcx
  mov eax, $3D3
  syscall
end;

procedure Syscall_3D4; stdcall;
asm
  mov r10, rcx
  mov eax, $3D4
  syscall
end;

procedure Syscall_3D5; stdcall;
asm
  mov r10, rcx
  mov eax, $3D5
  syscall
end;

procedure Syscall_3D6; stdcall;
asm
  mov r10, rcx
  mov eax, $3D6
  syscall
end;

procedure Syscall_3D7; stdcall;
asm
  mov r10, rcx
  mov eax, $3D7
  syscall
end;

procedure Syscall_3D8; stdcall;
asm
  mov r10, rcx
  mov eax, $3D8
  syscall
end;

procedure Syscall_3D9; stdcall;
asm
  mov r10, rcx
  mov eax, $3D9
  syscall
end;

procedure Syscall_3DA; stdcall;
asm
  mov r10, rcx
  mov eax, $3DA
  syscall
end;

procedure Syscall_3DB; stdcall;
asm
  mov r10, rcx
  mov eax, $3DB
  syscall
end;

procedure Syscall_3DC; stdcall;
asm
  mov r10, rcx
  mov eax, $3DC
  syscall
end;

procedure Syscall_3DD; stdcall;
asm
  mov r10, rcx
  mov eax, $3DD
  syscall
end;

procedure Syscall_3DE; stdcall;
asm
  mov r10, rcx
  mov eax, $3DE
  syscall
end;

procedure Syscall_3DF; stdcall;
asm
  mov r10, rcx
  mov eax, $3DF
  syscall
end;

procedure Syscall_3E0; stdcall;
asm
  mov r10, rcx
  mov eax, $3E0
  syscall
end;

procedure Syscall_3E1; stdcall;
asm
  mov r10, rcx
  mov eax, $3E1
  syscall
end;

procedure Syscall_3E2; stdcall;
asm
  mov r10, rcx
  mov eax, $3E2
  syscall
end;

procedure Syscall_3E3; stdcall;
asm
  mov r10, rcx
  mov eax, $3E3
  syscall
end;

procedure Syscall_3E4; stdcall;
asm
  mov r10, rcx
  mov eax, $3E4
  syscall
end;

procedure Syscall_3E5; stdcall;
asm
  mov r10, rcx
  mov eax, $3E5
  syscall
end;

procedure Syscall_3E6; stdcall;
asm
  mov r10, rcx
  mov eax, $3E6
  syscall
end;

procedure Syscall_3E7; stdcall;
asm
  mov r10, rcx
  mov eax, $3E7
  syscall
end;

procedure Syscall_3E8; stdcall;
asm
  mov r10, rcx
  mov eax, $3E8
  syscall
end;

procedure Syscall_3E9; stdcall;
asm
  mov r10, rcx
  mov eax, $3E9
  syscall
end;

procedure Syscall_3EA; stdcall;
asm
  mov r10, rcx
  mov eax, $3EA
  syscall
end;

procedure Syscall_3EB; stdcall;
asm
  mov r10, rcx
  mov eax, $3EB
  syscall
end;

procedure Syscall_3EC; stdcall;
asm
  mov r10, rcx
  mov eax, $3EC
  syscall
end;

procedure Syscall_3ED; stdcall;
asm
  mov r10, rcx
  mov eax, $3ED
  syscall
end;

procedure Syscall_3EE; stdcall;
asm
  mov r10, rcx
  mov eax, $3EE
  syscall
end;

procedure Syscall_3EF; stdcall;
asm
  mov r10, rcx
  mov eax, $3EF
  syscall
end;

procedure Syscall_3F0; stdcall;
asm
  mov r10, rcx
  mov eax, $3F0
  syscall
end;

procedure Syscall_3F1; stdcall;
asm
  mov r10, rcx
  mov eax, $3F1
  syscall
end;

procedure Syscall_3F2; stdcall;
asm
  mov r10, rcx
  mov eax, $3F2
  syscall
end;

procedure Syscall_3F3; stdcall;
asm
  mov r10, rcx
  mov eax, $3F3
  syscall
end;

procedure Syscall_3F4; stdcall;
asm
  mov r10, rcx
  mov eax, $3F4
  syscall
end;

procedure Syscall_3F5; stdcall;
asm
  mov r10, rcx
  mov eax, $3F5
  syscall
end;

procedure Syscall_3F6; stdcall;
asm
  mov r10, rcx
  mov eax, $3F6
  syscall
end;

procedure Syscall_3F7; stdcall;
asm
  mov r10, rcx
  mov eax, $3F7
  syscall
end;

procedure Syscall_3F8; stdcall;
asm
  mov r10, rcx
  mov eax, $3F8
  syscall
end;

procedure Syscall_3F9; stdcall;
asm
  mov r10, rcx
  mov eax, $3F9
  syscall
end;

procedure Syscall_3FA; stdcall;
asm
  mov r10, rcx
  mov eax, $3FA
  syscall
end;

procedure Syscall_3FB; stdcall;
asm
  mov r10, rcx
  mov eax, $3FB
  syscall
end;

procedure Syscall_3FC; stdcall;
asm
  mov r10, rcx
  mov eax, $3FC
  syscall
end;

procedure Syscall_3FD; stdcall;
asm
  mov r10, rcx
  mov eax, $3FD
  syscall
end;

procedure Syscall_3FE; stdcall;
asm
  mov r10, rcx
  mov eax, $3FE
  syscall
end;

procedure Syscall_3FF; stdcall;
asm
  mov r10, rcx
  mov eax, $3FF
  syscall
end;

procedure Syscall_400; stdcall;
asm
  mov r10, rcx
  mov eax, $400
  syscall
end;

procedure Syscall_401; stdcall;
asm
  mov r10, rcx
  mov eax, $401
  syscall
end;

procedure Syscall_402; stdcall;
asm
  mov r10, rcx
  mov eax, $402
  syscall
end;

procedure Syscall_403; stdcall;
asm
  mov r10, rcx
  mov eax, $403
  syscall
end;

procedure Syscall_404; stdcall;
asm
  mov r10, rcx
  mov eax, $404
  syscall
end;

procedure Syscall_405; stdcall;
asm
  mov r10, rcx
  mov eax, $405
  syscall
end;

procedure Syscall_406; stdcall;
asm
  mov r10, rcx
  mov eax, $406
  syscall
end;

procedure Syscall_407; stdcall;
asm
  mov r10, rcx
  mov eax, $407
  syscall
end;

procedure Syscall_408; stdcall;
asm
  mov r10, rcx
  mov eax, $408
  syscall
end;

procedure Syscall_409; stdcall;
asm
  mov r10, rcx
  mov eax, $409
  syscall
end;

procedure Syscall_40A; stdcall;
asm
  mov r10, rcx
  mov eax, $40A
  syscall
end;

procedure Syscall_40B; stdcall;
asm
  mov r10, rcx
  mov eax, $40B
  syscall
end;

procedure Syscall_40C; stdcall;
asm
  mov r10, rcx
  mov eax, $40C
  syscall
end;

procedure Syscall_40D; stdcall;
asm
  mov r10, rcx
  mov eax, $40D
  syscall
end;

procedure Syscall_40E; stdcall;
asm
  mov r10, rcx
  mov eax, $40E
  syscall
end;

procedure Syscall_40F; stdcall;
asm
  mov r10, rcx
  mov eax, $40F
  syscall
end;

procedure Syscall_410; stdcall;
asm
  mov r10, rcx
  mov eax, $410
  syscall
end;

procedure Syscall_411; stdcall;
asm
  mov r10, rcx
  mov eax, $411
  syscall
end;

procedure Syscall_412; stdcall;
asm
  mov r10, rcx
  mov eax, $412
  syscall
end;

procedure Syscall_413; stdcall;
asm
  mov r10, rcx
  mov eax, $413
  syscall
end;

procedure Syscall_414; stdcall;
asm
  mov r10, rcx
  mov eax, $414
  syscall
end;

procedure Syscall_415; stdcall;
asm
  mov r10, rcx
  mov eax, $415
  syscall
end;

procedure Syscall_416; stdcall;
asm
  mov r10, rcx
  mov eax, $416
  syscall
end;

procedure Syscall_417; stdcall;
asm
  mov r10, rcx
  mov eax, $417
  syscall
end;

procedure Syscall_418; stdcall;
asm
  mov r10, rcx
  mov eax, $418
  syscall
end;

procedure Syscall_419; stdcall;
asm
  mov r10, rcx
  mov eax, $419
  syscall
end;

procedure Syscall_41A; stdcall;
asm
  mov r10, rcx
  mov eax, $41A
  syscall
end;

procedure Syscall_41B; stdcall;
asm
  mov r10, rcx
  mov eax, $41B
  syscall
end;

procedure Syscall_41C; stdcall;
asm
  mov r10, rcx
  mov eax, $41C
  syscall
end;

procedure Syscall_41D; stdcall;
asm
  mov r10, rcx
  mov eax, $41D
  syscall
end;

procedure Syscall_41E; stdcall;
asm
  mov r10, rcx
  mov eax, $41E
  syscall
end;

procedure Syscall_41F; stdcall;
asm
  mov r10, rcx
  mov eax, $41F
  syscall
end;

procedure Syscall_420; stdcall;
asm
  mov r10, rcx
  mov eax, $420
  syscall
end;

procedure Syscall_421; stdcall;
asm
  mov r10, rcx
  mov eax, $421
  syscall
end;

procedure Syscall_422; stdcall;
asm
  mov r10, rcx
  mov eax, $422
  syscall
end;

procedure Syscall_423; stdcall;
asm
  mov r10, rcx
  mov eax, $423
  syscall
end;

procedure Syscall_424; stdcall;
asm
  mov r10, rcx
  mov eax, $424
  syscall
end;

procedure Syscall_425; stdcall;
asm
  mov r10, rcx
  mov eax, $425
  syscall
end;

procedure Syscall_426; stdcall;
asm
  mov r10, rcx
  mov eax, $426
  syscall
end;

procedure Syscall_427; stdcall;
asm
  mov r10, rcx
  mov eax, $427
  syscall
end;

procedure Syscall_428; stdcall;
asm
  mov r10, rcx
  mov eax, $428
  syscall
end;

procedure Syscall_429; stdcall;
asm
  mov r10, rcx
  mov eax, $429
  syscall
end;

procedure Syscall_42A; stdcall;
asm
  mov r10, rcx
  mov eax, $42A
  syscall
end;

procedure Syscall_42B; stdcall;
asm
  mov r10, rcx
  mov eax, $42B
  syscall
end;

procedure Syscall_42C; stdcall;
asm
  mov r10, rcx
  mov eax, $42C
  syscall
end;

procedure Syscall_42D; stdcall;
asm
  mov r10, rcx
  mov eax, $42D
  syscall
end;

procedure Syscall_42E; stdcall;
asm
  mov r10, rcx
  mov eax, $42E
  syscall
end;

procedure Syscall_42F; stdcall;
asm
  mov r10, rcx
  mov eax, $42F
  syscall
end;

procedure Syscall_430; stdcall;
asm
  mov r10, rcx
  mov eax, $430
  syscall
end;

procedure Syscall_431; stdcall;
asm
  mov r10, rcx
  mov eax, $431
  syscall
end;

procedure Syscall_432; stdcall;
asm
  mov r10, rcx
  mov eax, $432
  syscall
end;

procedure Syscall_433; stdcall;
asm
  mov r10, rcx
  mov eax, $433
  syscall
end;

procedure Syscall_434; stdcall;
asm
  mov r10, rcx
  mov eax, $434
  syscall
end;

procedure Syscall_435; stdcall;
asm
  mov r10, rcx
  mov eax, $435
  syscall
end;

procedure Syscall_436; stdcall;
asm
  mov r10, rcx
  mov eax, $436
  syscall
end;

procedure Syscall_437; stdcall;
asm
  mov r10, rcx
  mov eax, $437
  syscall
end;

procedure Syscall_438; stdcall;
asm
  mov r10, rcx
  mov eax, $438
  syscall
end;

procedure Syscall_439; stdcall;
asm
  mov r10, rcx
  mov eax, $439
  syscall
end;

procedure Syscall_43A; stdcall;
asm
  mov r10, rcx
  mov eax, $43A
  syscall
end;

procedure Syscall_43B; stdcall;
asm
  mov r10, rcx
  mov eax, $43B
  syscall
end;

procedure Syscall_43C; stdcall;
asm
  mov r10, rcx
  mov eax, $43C
  syscall
end;

procedure Syscall_43D; stdcall;
asm
  mov r10, rcx
  mov eax, $43D
  syscall
end;

procedure Syscall_43E; stdcall;
asm
  mov r10, rcx
  mov eax, $43E
  syscall
end;

procedure Syscall_43F; stdcall;
asm
  mov r10, rcx
  mov eax, $43F
  syscall
end;

procedure Syscall_440; stdcall;
asm
  mov r10, rcx
  mov eax, $440
  syscall
end;

procedure Syscall_441; stdcall;
asm
  mov r10, rcx
  mov eax, $441
  syscall
end;

procedure Syscall_442; stdcall;
asm
  mov r10, rcx
  mov eax, $442
  syscall
end;

procedure Syscall_443; stdcall;
asm
  mov r10, rcx
  mov eax, $443
  syscall
end;

procedure Syscall_444; stdcall;
asm
  mov r10, rcx
  mov eax, $444
  syscall
end;

procedure Syscall_445; stdcall;
asm
  mov r10, rcx
  mov eax, $445
  syscall
end;

procedure Syscall_446; stdcall;
asm
  mov r10, rcx
  mov eax, $446
  syscall
end;

procedure Syscall_447; stdcall;
asm
  mov r10, rcx
  mov eax, $447
  syscall
end;

procedure Syscall_448; stdcall;
asm
  mov r10, rcx
  mov eax, $448
  syscall
end;

procedure Syscall_449; stdcall;
asm
  mov r10, rcx
  mov eax, $449
  syscall
end;

procedure Syscall_44A; stdcall;
asm
  mov r10, rcx
  mov eax, $44A
  syscall
end;

procedure Syscall_44B; stdcall;
asm
  mov r10, rcx
  mov eax, $44B
  syscall
end;

procedure Syscall_44C; stdcall;
asm
  mov r10, rcx
  mov eax, $44C
  syscall
end;

procedure Syscall_44D; stdcall;
asm
  mov r10, rcx
  mov eax, $44D
  syscall
end;

procedure Syscall_44E; stdcall;
asm
  mov r10, rcx
  mov eax, $44E
  syscall
end;

procedure Syscall_44F; stdcall;
asm
  mov r10, rcx
  mov eax, $44F
  syscall
end;

procedure Syscall_450; stdcall;
asm
  mov r10, rcx
  mov eax, $450
  syscall
end;

procedure Syscall_451; stdcall;
asm
  mov r10, rcx
  mov eax, $451
  syscall
end;

procedure Syscall_452; stdcall;
asm
  mov r10, rcx
  mov eax, $452
  syscall
end;

procedure Syscall_453; stdcall;
asm
  mov r10, rcx
  mov eax, $453
  syscall
end;

procedure Syscall_454; stdcall;
asm
  mov r10, rcx
  mov eax, $454
  syscall
end;

procedure Syscall_455; stdcall;
asm
  mov r10, rcx
  mov eax, $455
  syscall
end;

procedure Syscall_456; stdcall;
asm
  mov r10, rcx
  mov eax, $456
  syscall
end;

procedure Syscall_457; stdcall;
asm
  mov r10, rcx
  mov eax, $457
  syscall
end;

procedure Syscall_458; stdcall;
asm
  mov r10, rcx
  mov eax, $458
  syscall
end;

procedure Syscall_459; stdcall;
asm
  mov r10, rcx
  mov eax, $459
  syscall
end;

procedure Syscall_45A; stdcall;
asm
  mov r10, rcx
  mov eax, $45A
  syscall
end;

procedure Syscall_45B; stdcall;
asm
  mov r10, rcx
  mov eax, $45B
  syscall
end;

procedure Syscall_45C; stdcall;
asm
  mov r10, rcx
  mov eax, $45C
  syscall
end;

procedure Syscall_45D; stdcall;
asm
  mov r10, rcx
  mov eax, $45D
  syscall
end;

procedure Syscall_45E; stdcall;
asm
  mov r10, rcx
  mov eax, $45E
  syscall
end;

procedure Syscall_45F; stdcall;
asm
  mov r10, rcx
  mov eax, $45F
  syscall
end;

procedure Syscall_460; stdcall;
asm
  mov r10, rcx
  mov eax, $460
  syscall
end;

procedure Syscall_461; stdcall;
asm
  mov r10, rcx
  mov eax, $461
  syscall
end;

procedure Syscall_462; stdcall;
asm
  mov r10, rcx
  mov eax, $462
  syscall
end;

procedure Syscall_463; stdcall;
asm
  mov r10, rcx
  mov eax, $463
  syscall
end;

procedure Syscall_464; stdcall;
asm
  mov r10, rcx
  mov eax, $464
  syscall
end;

procedure Syscall_465; stdcall;
asm
  mov r10, rcx
  mov eax, $465
  syscall
end;

procedure Syscall_466; stdcall;
asm
  mov r10, rcx
  mov eax, $466
  syscall
end;

procedure Syscall_467; stdcall;
asm
  mov r10, rcx
  mov eax, $467
  syscall
end;

procedure Syscall_468; stdcall;
asm
  mov r10, rcx
  mov eax, $468
  syscall
end;

procedure Syscall_469; stdcall;
asm
  mov r10, rcx
  mov eax, $469
  syscall
end;

procedure Syscall_46A; stdcall;
asm
  mov r10, rcx
  mov eax, $46A
  syscall
end;

procedure Syscall_46B; stdcall;
asm
  mov r10, rcx
  mov eax, $46B
  syscall
end;

procedure Syscall_46C; stdcall;
asm
  mov r10, rcx
  mov eax, $46C
  syscall
end;

procedure Syscall_46D; stdcall;
asm
  mov r10, rcx
  mov eax, $46D
  syscall
end;

procedure Syscall_46E; stdcall;
asm
  mov r10, rcx
  mov eax, $46E
  syscall
end;

procedure Syscall_46F; stdcall;
asm
  mov r10, rcx
  mov eax, $46F
  syscall
end;

procedure Syscall_470; stdcall;
asm
  mov r10, rcx
  mov eax, $470
  syscall
end;

procedure Syscall_471; stdcall;
asm
  mov r10, rcx
  mov eax, $471
  syscall
end;

procedure Syscall_472; stdcall;
asm
  mov r10, rcx
  mov eax, $472
  syscall
end;

procedure Syscall_473; stdcall;
asm
  mov r10, rcx
  mov eax, $473
  syscall
end;

procedure Syscall_474; stdcall;
asm
  mov r10, rcx
  mov eax, $474
  syscall
end;

procedure Syscall_475; stdcall;
asm
  mov r10, rcx
  mov eax, $475
  syscall
end;

procedure Syscall_476; stdcall;
asm
  mov r10, rcx
  mov eax, $476
  syscall
end;

procedure Syscall_477; stdcall;
asm
  mov r10, rcx
  mov eax, $477
  syscall
end;

procedure Syscall_478; stdcall;
asm
  mov r10, rcx
  mov eax, $478
  syscall
end;

procedure Syscall_479; stdcall;
asm
  mov r10, rcx
  mov eax, $479
  syscall
end;

procedure Syscall_47A; stdcall;
asm
  mov r10, rcx
  mov eax, $47A
  syscall
end;

procedure Syscall_47B; stdcall;
asm
  mov r10, rcx
  mov eax, $47B
  syscall
end;

procedure Syscall_47C; stdcall;
asm
  mov r10, rcx
  mov eax, $47C
  syscall
end;

procedure Syscall_47D; stdcall;
asm
  mov r10, rcx
  mov eax, $47D
  syscall
end;

procedure Syscall_47E; stdcall;
asm
  mov r10, rcx
  mov eax, $47E
  syscall
end;

procedure Syscall_47F; stdcall;
asm
  mov r10, rcx
  mov eax, $47F
  syscall
end;

procedure Syscall_480; stdcall;
asm
  mov r10, rcx
  mov eax, $480
  syscall
end;

procedure Syscall_481; stdcall;
asm
  mov r10, rcx
  mov eax, $481
  syscall
end;

procedure Syscall_482; stdcall;
asm
  mov r10, rcx
  mov eax, $482
  syscall
end;

procedure Syscall_483; stdcall;
asm
  mov r10, rcx
  mov eax, $483
  syscall
end;

procedure Syscall_484; stdcall;
asm
  mov r10, rcx
  mov eax, $484
  syscall
end;

procedure Syscall_485; stdcall;
asm
  mov r10, rcx
  mov eax, $485
  syscall
end;

procedure Syscall_486; stdcall;
asm
  mov r10, rcx
  mov eax, $486
  syscall
end;

procedure Syscall_487; stdcall;
asm
  mov r10, rcx
  mov eax, $487
  syscall
end;

procedure Syscall_488; stdcall;
asm
  mov r10, rcx
  mov eax, $488
  syscall
end;

procedure Syscall_489; stdcall;
asm
  mov r10, rcx
  mov eax, $489
  syscall
end;

procedure Syscall_48A; stdcall;
asm
  mov r10, rcx
  mov eax, $48A
  syscall
end;

procedure Syscall_48B; stdcall;
asm
  mov r10, rcx
  mov eax, $48B
  syscall
end;

procedure Syscall_48C; stdcall;
asm
  mov r10, rcx
  mov eax, $48C
  syscall
end;

procedure Syscall_48D; stdcall;
asm
  mov r10, rcx
  mov eax, $48D
  syscall
end;

procedure Syscall_48E; stdcall;
asm
  mov r10, rcx
  mov eax, $48E
  syscall
end;

procedure Syscall_48F; stdcall;
asm
  mov r10, rcx
  mov eax, $48F
  syscall
end;

procedure Syscall_490; stdcall;
asm
  mov r10, rcx
  mov eax, $490
  syscall
end;

procedure Syscall_491; stdcall;
asm
  mov r10, rcx
  mov eax, $491
  syscall
end;

procedure Syscall_492; stdcall;
asm
  mov r10, rcx
  mov eax, $492
  syscall
end;

procedure Syscall_493; stdcall;
asm
  mov r10, rcx
  mov eax, $493
  syscall
end;

procedure Syscall_494; stdcall;
asm
  mov r10, rcx
  mov eax, $494
  syscall
end;

procedure Syscall_495; stdcall;
asm
  mov r10, rcx
  mov eax, $495
  syscall
end;

procedure Syscall_496; stdcall;
asm
  mov r10, rcx
  mov eax, $496
  syscall
end;

procedure Syscall_497; stdcall;
asm
  mov r10, rcx
  mov eax, $497
  syscall
end;

procedure Syscall_498; stdcall;
asm
  mov r10, rcx
  mov eax, $498
  syscall
end;

procedure Syscall_499; stdcall;
asm
  mov r10, rcx
  mov eax, $499
  syscall
end;

procedure Syscall_49A; stdcall;
asm
  mov r10, rcx
  mov eax, $49A
  syscall
end;

procedure Syscall_49B; stdcall;
asm
  mov r10, rcx
  mov eax, $49B
  syscall
end;

procedure Syscall_49C; stdcall;
asm
  mov r10, rcx
  mov eax, $49C
  syscall
end;

procedure Syscall_49D; stdcall;
asm
  mov r10, rcx
  mov eax, $49D
  syscall
end;

procedure Syscall_49E; stdcall;
asm
  mov r10, rcx
  mov eax, $49E
  syscall
end;

procedure Syscall_49F; stdcall;
asm
  mov r10, rcx
  mov eax, $49F
  syscall
end;

procedure Syscall_4A0; stdcall;
asm
  mov r10, rcx
  mov eax, $4A0
  syscall
end;

procedure Syscall_4A1; stdcall;
asm
  mov r10, rcx
  mov eax, $4A1
  syscall
end;

procedure Syscall_4A2; stdcall;
asm
  mov r10, rcx
  mov eax, $4A2
  syscall
end;

procedure Syscall_4A3; stdcall;
asm
  mov r10, rcx
  mov eax, $4A3
  syscall
end;

procedure Syscall_4A4; stdcall;
asm
  mov r10, rcx
  mov eax, $4A4
  syscall
end;

procedure Syscall_4A5; stdcall;
asm
  mov r10, rcx
  mov eax, $4A5
  syscall
end;

procedure Syscall_4A6; stdcall;
asm
  mov r10, rcx
  mov eax, $4A6
  syscall
end;

procedure Syscall_4A7; stdcall;
asm
  mov r10, rcx
  mov eax, $4A7
  syscall
end;

procedure Syscall_4A8; stdcall;
asm
  mov r10, rcx
  mov eax, $4A8
  syscall
end;

procedure Syscall_4A9; stdcall;
asm
  mov r10, rcx
  mov eax, $4A9
  syscall
end;

procedure Syscall_4AA; stdcall;
asm
  mov r10, rcx
  mov eax, $4AA
  syscall
end;

procedure Syscall_4AB; stdcall;
asm
  mov r10, rcx
  mov eax, $4AB
  syscall
end;

procedure Syscall_4AC; stdcall;
asm
  mov r10, rcx
  mov eax, $4AC
  syscall
end;

procedure Syscall_4AD; stdcall;
asm
  mov r10, rcx
  mov eax, $4AD
  syscall
end;

procedure Syscall_4AE; stdcall;
asm
  mov r10, rcx
  mov eax, $4AE
  syscall
end;

procedure Syscall_4AF; stdcall;
asm
  mov r10, rcx
  mov eax, $4AF
  syscall
end;

procedure Syscall_4B0; stdcall;
asm
  mov r10, rcx
  mov eax, $4B0
  syscall
end;

procedure Syscall_4B1; stdcall;
asm
  mov r10, rcx
  mov eax, $4B1
  syscall
end;

procedure Syscall_4B2; stdcall;
asm
  mov r10, rcx
  mov eax, $4B2
  syscall
end;

procedure Syscall_4B3; stdcall;
asm
  mov r10, rcx
  mov eax, $4B3
  syscall
end;

procedure Syscall_4B4; stdcall;
asm
  mov r10, rcx
  mov eax, $4B4
  syscall
end;

procedure Syscall_4B5; stdcall;
asm
  mov r10, rcx
  mov eax, $4B5
  syscall
end;

procedure Syscall_4B6; stdcall;
asm
  mov r10, rcx
  mov eax, $4B6
  syscall
end;

procedure Syscall_4B7; stdcall;
asm
  mov r10, rcx
  mov eax, $4B7
  syscall
end;

procedure Syscall_4B8; stdcall;
asm
  mov r10, rcx
  mov eax, $4B8
  syscall
end;

procedure Syscall_4B9; stdcall;
asm
  mov r10, rcx
  mov eax, $4B9
  syscall
end;

procedure Syscall_4BA; stdcall;
asm
  mov r10, rcx
  mov eax, $4BA
  syscall
end;

procedure Syscall_4BB; stdcall;
asm
  mov r10, rcx
  mov eax, $4BB
  syscall
end;

procedure Syscall_4BC; stdcall;
asm
  mov r10, rcx
  mov eax, $4BC
  syscall
end;

procedure Syscall_4BD; stdcall;
asm
  mov r10, rcx
  mov eax, $4BD
  syscall
end;

procedure Syscall_4BE; stdcall;
asm
  mov r10, rcx
  mov eax, $4BE
  syscall
end;

procedure Syscall_4BF; stdcall;
asm
  mov r10, rcx
  mov eax, $4BF
  syscall
end;

procedure Syscall_4C0; stdcall;
asm
  mov r10, rcx
  mov eax, $4C0
  syscall
end;

procedure Syscall_4C1; stdcall;
asm
  mov r10, rcx
  mov eax, $4C1
  syscall
end;

procedure Syscall_4C2; stdcall;
asm
  mov r10, rcx
  mov eax, $4C2
  syscall
end;

procedure Syscall_4C3; stdcall;
asm
  mov r10, rcx
  mov eax, $4C3
  syscall
end;

procedure Syscall_4C4; stdcall;
asm
  mov r10, rcx
  mov eax, $4C4
  syscall
end;

procedure Syscall_4C5; stdcall;
asm
  mov r10, rcx
  mov eax, $4C5
  syscall
end;

procedure Syscall_4C6; stdcall;
asm
  mov r10, rcx
  mov eax, $4C6
  syscall
end;

procedure Syscall_4C7; stdcall;
asm
  mov r10, rcx
  mov eax, $4C7
  syscall
end;

procedure Syscall_4C8; stdcall;
asm
  mov r10, rcx
  mov eax, $4C8
  syscall
end;

procedure Syscall_4C9; stdcall;
asm
  mov r10, rcx
  mov eax, $4C9
  syscall
end;

procedure Syscall_4CA; stdcall;
asm
  mov r10, rcx
  mov eax, $4CA
  syscall
end;

procedure Syscall_4CB; stdcall;
asm
  mov r10, rcx
  mov eax, $4CB
  syscall
end;

procedure Syscall_4CC; stdcall;
asm
  mov r10, rcx
  mov eax, $4CC
  syscall
end;

procedure Syscall_4CD; stdcall;
asm
  mov r10, rcx
  mov eax, $4CD
  syscall
end;

procedure Syscall_4CE; stdcall;
asm
  mov r10, rcx
  mov eax, $4CE
  syscall
end;

procedure Syscall_4CF; stdcall;
asm
  mov r10, rcx
  mov eax, $4CF
  syscall
end;

procedure Syscall_4D0; stdcall;
asm
  mov r10, rcx
  mov eax, $4D0
  syscall
end;

procedure Syscall_4D1; stdcall;
asm
  mov r10, rcx
  mov eax, $4D1
  syscall
end;

procedure Syscall_4D2; stdcall;
asm
  mov r10, rcx
  mov eax, $4D2
  syscall
end;

procedure Syscall_4D3; stdcall;
asm
  mov r10, rcx
  mov eax, $4D3
  syscall
end;

procedure Syscall_4D4; stdcall;
asm
  mov r10, rcx
  mov eax, $4D4
  syscall
end;

procedure Syscall_4D5; stdcall;
asm
  mov r10, rcx
  mov eax, $4D5
  syscall
end;

procedure Syscall_4D6; stdcall;
asm
  mov r10, rcx
  mov eax, $4D6
  syscall
end;

procedure Syscall_4D7; stdcall;
asm
  mov r10, rcx
  mov eax, $4D7
  syscall
end;

procedure Syscall_4D8; stdcall;
asm
  mov r10, rcx
  mov eax, $4D8
  syscall
end;

procedure Syscall_4D9; stdcall;
asm
  mov r10, rcx
  mov eax, $4D9
  syscall
end;

procedure Syscall_4DA; stdcall;
asm
  mov r10, rcx
  mov eax, $4DA
  syscall
end;

procedure Syscall_4DB; stdcall;
asm
  mov r10, rcx
  mov eax, $4DB
  syscall
end;

procedure Syscall_4DC; stdcall;
asm
  mov r10, rcx
  mov eax, $4DC
  syscall
end;

procedure Syscall_4DD; stdcall;
asm
  mov r10, rcx
  mov eax, $4DD
  syscall
end;

procedure Syscall_4DE; stdcall;
asm
  mov r10, rcx
  mov eax, $4DE
  syscall
end;

procedure Syscall_4DF; stdcall;
asm
  mov r10, rcx
  mov eax, $4DF
  syscall
end;

procedure Syscall_4E0; stdcall;
asm
  mov r10, rcx
  mov eax, $4E0
  syscall
end;

procedure Syscall_4E1; stdcall;
asm
  mov r10, rcx
  mov eax, $4E1
  syscall
end;

procedure Syscall_4E2; stdcall;
asm
  mov r10, rcx
  mov eax, $4E2
  syscall
end;

procedure Syscall_4E3; stdcall;
asm
  mov r10, rcx
  mov eax, $4E3
  syscall
end;

procedure Syscall_4E4; stdcall;
asm
  mov r10, rcx
  mov eax, $4E4
  syscall
end;

procedure Syscall_4E5; stdcall;
asm
  mov r10, rcx
  mov eax, $4E5
  syscall
end;

procedure Syscall_4E6; stdcall;
asm
  mov r10, rcx
  mov eax, $4E6
  syscall
end;

procedure Syscall_4E7; stdcall;
asm
  mov r10, rcx
  mov eax, $4E7
  syscall
end;

procedure Syscall_4E8; stdcall;
asm
  mov r10, rcx
  mov eax, $4E8
  syscall
end;

procedure Syscall_4E9; stdcall;
asm
  mov r10, rcx
  mov eax, $4E9
  syscall
end;

procedure Syscall_4EA; stdcall;
asm
  mov r10, rcx
  mov eax, $4EA
  syscall
end;

procedure Syscall_4EB; stdcall;
asm
  mov r10, rcx
  mov eax, $4EB
  syscall
end;

procedure Syscall_4EC; stdcall;
asm
  mov r10, rcx
  mov eax, $4EC
  syscall
end;

procedure Syscall_4ED; stdcall;
asm
  mov r10, rcx
  mov eax, $4ED
  syscall
end;

procedure Syscall_4EE; stdcall;
asm
  mov r10, rcx
  mov eax, $4EE
  syscall
end;

procedure Syscall_4EF; stdcall;
asm
  mov r10, rcx
  mov eax, $4EF
  syscall
end;

procedure Syscall_4F0; stdcall;
asm
  mov r10, rcx
  mov eax, $4F0
  syscall
end;

procedure Syscall_4F1; stdcall;
asm
  mov r10, rcx
  mov eax, $4F1
  syscall
end;

procedure Syscall_4F2; stdcall;
asm
  mov r10, rcx
  mov eax, $4F2
  syscall
end;

procedure Syscall_4F3; stdcall;
asm
  mov r10, rcx
  mov eax, $4F3
  syscall
end;

procedure Syscall_4F4; stdcall;
asm
  mov r10, rcx
  mov eax, $4F4
  syscall
end;

procedure Syscall_4F5; stdcall;
asm
  mov r10, rcx
  mov eax, $4F5
  syscall
end;

procedure Syscall_4F6; stdcall;
asm
  mov r10, rcx
  mov eax, $4F6
  syscall
end;

procedure Syscall_4F7; stdcall;
asm
  mov r10, rcx
  mov eax, $4F7
  syscall
end;

procedure Syscall_4F8; stdcall;
asm
  mov r10, rcx
  mov eax, $4F8
  syscall
end;

procedure Syscall_4F9; stdcall;
asm
  mov r10, rcx
  mov eax, $4F9
  syscall
end;

procedure Syscall_4FA; stdcall;
asm
  mov r10, rcx
  mov eax, $4FA
  syscall
end;

procedure Syscall_4FB; stdcall;
asm
  mov r10, rcx
  mov eax, $4FB
  syscall
end;

procedure Syscall_4FC; stdcall;
asm
  mov r10, rcx
  mov eax, $4FC
  syscall
end;

procedure Syscall_4FD; stdcall;
asm
  mov r10, rcx
  mov eax, $4FD
  syscall
end;

procedure Syscall_4FE; stdcall;
asm
  mov r10, rcx
  mov eax, $4FE
  syscall
end;

procedure Syscall_4FF; stdcall;
asm
  mov r10, rcx
  mov eax, $4FF
  syscall
end;

procedure Syscall_500; stdcall;
asm
  mov r10, rcx
  mov eax, $500
  syscall
end;

procedure Syscall_501; stdcall;
asm
  mov r10, rcx
  mov eax, $501
  syscall
end;

procedure Syscall_502; stdcall;
asm
  mov r10, rcx
  mov eax, $502
  syscall
end;

procedure Syscall_503; stdcall;
asm
  mov r10, rcx
  mov eax, $503
  syscall
end;

procedure Syscall_504; stdcall;
asm
  mov r10, rcx
  mov eax, $504
  syscall
end;

procedure Syscall_505; stdcall;
asm
  mov r10, rcx
  mov eax, $505
  syscall
end;

procedure Syscall_506; stdcall;
asm
  mov r10, rcx
  mov eax, $506
  syscall
end;

procedure Syscall_507; stdcall;
asm
  mov r10, rcx
  mov eax, $507
  syscall
end;

procedure Syscall_508; stdcall;
asm
  mov r10, rcx
  mov eax, $508
  syscall
end;

procedure Syscall_509; stdcall;
asm
  mov r10, rcx
  mov eax, $509
  syscall
end;

procedure Syscall_50A; stdcall;
asm
  mov r10, rcx
  mov eax, $50A
  syscall
end;

procedure Syscall_50B; stdcall;
asm
  mov r10, rcx
  mov eax, $50B
  syscall
end;

procedure Syscall_50C; stdcall;
asm
  mov r10, rcx
  mov eax, $50C
  syscall
end;

procedure Syscall_50D; stdcall;
asm
  mov r10, rcx
  mov eax, $50D
  syscall
end;

procedure Syscall_50E; stdcall;
asm
  mov r10, rcx
  mov eax, $50E
  syscall
end;

procedure Syscall_50F; stdcall;
asm
  mov r10, rcx
  mov eax, $50F
  syscall
end;

procedure Syscall_510; stdcall;
asm
  mov r10, rcx
  mov eax, $510
  syscall
end;

procedure Syscall_511; stdcall;
asm
  mov r10, rcx
  mov eax, $511
  syscall
end;

procedure Syscall_512; stdcall;
asm
  mov r10, rcx
  mov eax, $512
  syscall
end;

procedure Syscall_513; stdcall;
asm
  mov r10, rcx
  mov eax, $513
  syscall
end;

procedure Syscall_514; stdcall;
asm
  mov r10, rcx
  mov eax, $514
  syscall
end;

procedure Syscall_515; stdcall;
asm
  mov r10, rcx
  mov eax, $515
  syscall
end;

procedure Syscall_516; stdcall;
asm
  mov r10, rcx
  mov eax, $516
  syscall
end;

procedure Syscall_517; stdcall;
asm
  mov r10, rcx
  mov eax, $517
  syscall
end;

procedure Syscall_518; stdcall;
asm
  mov r10, rcx
  mov eax, $518
  syscall
end;

procedure Syscall_519; stdcall;
asm
  mov r10, rcx
  mov eax, $519
  syscall
end;

procedure Syscall_51A; stdcall;
asm
  mov r10, rcx
  mov eax, $51A
  syscall
end;

procedure Syscall_51B; stdcall;
asm
  mov r10, rcx
  mov eax, $51B
  syscall
end;

procedure Syscall_51C; stdcall;
asm
  mov r10, rcx
  mov eax, $51C
  syscall
end;

procedure Syscall_51D; stdcall;
asm
  mov r10, rcx
  mov eax, $51D
  syscall
end;

procedure Syscall_51E; stdcall;
asm
  mov r10, rcx
  mov eax, $51E
  syscall
end;

procedure Syscall_51F; stdcall;
asm
  mov r10, rcx
  mov eax, $51F
  syscall
end;

procedure Syscall_520; stdcall;
asm
  mov r10, rcx
  mov eax, $520
  syscall
end;

procedure Syscall_521; stdcall;
asm
  mov r10, rcx
  mov eax, $521
  syscall
end;

procedure Syscall_522; stdcall;
asm
  mov r10, rcx
  mov eax, $522
  syscall
end;

procedure Syscall_523; stdcall;
asm
  mov r10, rcx
  mov eax, $523
  syscall
end;

procedure Syscall_524; stdcall;
asm
  mov r10, rcx
  mov eax, $524
  syscall
end;

procedure Syscall_525; stdcall;
asm
  mov r10, rcx
  mov eax, $525
  syscall
end;

procedure Syscall_526; stdcall;
asm
  mov r10, rcx
  mov eax, $526
  syscall
end;

procedure Syscall_527; stdcall;
asm
  mov r10, rcx
  mov eax, $527
  syscall
end;

procedure Syscall_528; stdcall;
asm
  mov r10, rcx
  mov eax, $528
  syscall
end;

procedure Syscall_529; stdcall;
asm
  mov r10, rcx
  mov eax, $529
  syscall
end;

procedure Syscall_52A; stdcall;
asm
  mov r10, rcx
  mov eax, $52A
  syscall
end;

procedure Syscall_52B; stdcall;
asm
  mov r10, rcx
  mov eax, $52B
  syscall
end;

procedure Syscall_52C; stdcall;
asm
  mov r10, rcx
  mov eax, $52C
  syscall
end;

procedure Syscall_52D; stdcall;
asm
  mov r10, rcx
  mov eax, $52D
  syscall
end;

procedure Syscall_52E; stdcall;
asm
  mov r10, rcx
  mov eax, $52E
  syscall
end;

procedure Syscall_52F; stdcall;
asm
  mov r10, rcx
  mov eax, $52F
  syscall
end;

procedure Syscall_530; stdcall;
asm
  mov r10, rcx
  mov eax, $530
  syscall
end;

procedure Syscall_531; stdcall;
asm
  mov r10, rcx
  mov eax, $531
  syscall
end;

procedure Syscall_532; stdcall;
asm
  mov r10, rcx
  mov eax, $532
  syscall
end;

procedure Syscall_533; stdcall;
asm
  mov r10, rcx
  mov eax, $533
  syscall
end;

procedure Syscall_534; stdcall;
asm
  mov r10, rcx
  mov eax, $534
  syscall
end;

procedure Syscall_535; stdcall;
asm
  mov r10, rcx
  mov eax, $535
  syscall
end;

procedure Syscall_536; stdcall;
asm
  mov r10, rcx
  mov eax, $536
  syscall
end;

procedure Syscall_537; stdcall;
asm
  mov r10, rcx
  mov eax, $537
  syscall
end;

procedure Syscall_538; stdcall;
asm
  mov r10, rcx
  mov eax, $538
  syscall
end;

procedure Syscall_539; stdcall;
asm
  mov r10, rcx
  mov eax, $539
  syscall
end;

procedure Syscall_53A; stdcall;
asm
  mov r10, rcx
  mov eax, $53A
  syscall
end;

procedure Syscall_53B; stdcall;
asm
  mov r10, rcx
  mov eax, $53B
  syscall
end;

procedure Syscall_53C; stdcall;
asm
  mov r10, rcx
  mov eax, $53C
  syscall
end;

procedure Syscall_53D; stdcall;
asm
  mov r10, rcx
  mov eax, $53D
  syscall
end;

procedure Syscall_53E; stdcall;
asm
  mov r10, rcx
  mov eax, $53E
  syscall
end;

procedure Syscall_53F; stdcall;
asm
  mov r10, rcx
  mov eax, $53F
  syscall
end;

procedure Syscall_540; stdcall;
asm
  mov r10, rcx
  mov eax, $540
  syscall
end;

procedure Syscall_541; stdcall;
asm
  mov r10, rcx
  mov eax, $541
  syscall
end;

procedure Syscall_542; stdcall;
asm
  mov r10, rcx
  mov eax, $542
  syscall
end;

procedure Syscall_543; stdcall;
asm
  mov r10, rcx
  mov eax, $543
  syscall
end;

procedure Syscall_544; stdcall;
asm
  mov r10, rcx
  mov eax, $544
  syscall
end;

procedure Syscall_545; stdcall;
asm
  mov r10, rcx
  mov eax, $545
  syscall
end;

procedure Syscall_546; stdcall;
asm
  mov r10, rcx
  mov eax, $546
  syscall
end;

procedure Syscall_547; stdcall;
asm
  mov r10, rcx
  mov eax, $547
  syscall
end;

procedure Syscall_548; stdcall;
asm
  mov r10, rcx
  mov eax, $548
  syscall
end;

procedure Syscall_549; stdcall;
asm
  mov r10, rcx
  mov eax, $549
  syscall
end;

procedure Syscall_54A; stdcall;
asm
  mov r10, rcx
  mov eax, $54A
  syscall
end;

procedure Syscall_54B; stdcall;
asm
  mov r10, rcx
  mov eax, $54B
  syscall
end;

procedure Syscall_54C; stdcall;
asm
  mov r10, rcx
  mov eax, $54C
  syscall
end;

procedure Syscall_54D; stdcall;
asm
  mov r10, rcx
  mov eax, $54D
  syscall
end;

procedure Syscall_54E; stdcall;
asm
  mov r10, rcx
  mov eax, $54E
  syscall
end;

procedure Syscall_54F; stdcall;
asm
  mov r10, rcx
  mov eax, $54F
  syscall
end;

procedure Syscall_550; stdcall;
asm
  mov r10, rcx
  mov eax, $550
  syscall
end;

procedure Syscall_551; stdcall;
asm
  mov r10, rcx
  mov eax, $551
  syscall
end;

procedure Syscall_552; stdcall;
asm
  mov r10, rcx
  mov eax, $552
  syscall
end;

procedure Syscall_553; stdcall;
asm
  mov r10, rcx
  mov eax, $553
  syscall
end;

procedure Syscall_554; stdcall;
asm
  mov r10, rcx
  mov eax, $554
  syscall
end;

procedure Syscall_555; stdcall;
asm
  mov r10, rcx
  mov eax, $555
  syscall
end;

procedure Syscall_556; stdcall;
asm
  mov r10, rcx
  mov eax, $556
  syscall
end;

procedure Syscall_557; stdcall;
asm
  mov r10, rcx
  mov eax, $557
  syscall
end;

procedure Syscall_558; stdcall;
asm
  mov r10, rcx
  mov eax, $558
  syscall
end;

procedure Syscall_559; stdcall;
asm
  mov r10, rcx
  mov eax, $559
  syscall
end;

procedure Syscall_55A; stdcall;
asm
  mov r10, rcx
  mov eax, $55A
  syscall
end;

procedure Syscall_55B; stdcall;
asm
  mov r10, rcx
  mov eax, $55B
  syscall
end;

procedure Syscall_55C; stdcall;
asm
  mov r10, rcx
  mov eax, $55C
  syscall
end;

procedure Syscall_55D; stdcall;
asm
  mov r10, rcx
  mov eax, $55D
  syscall
end;

procedure Syscall_55E; stdcall;
asm
  mov r10, rcx
  mov eax, $55E
  syscall
end;

procedure Syscall_55F; stdcall;
asm
  mov r10, rcx
  mov eax, $55F
  syscall
end;

procedure Syscall_560; stdcall;
asm
  mov r10, rcx
  mov eax, $560
  syscall
end;

procedure Syscall_561; stdcall;
asm
  mov r10, rcx
  mov eax, $561
  syscall
end;

procedure Syscall_562; stdcall;
asm
  mov r10, rcx
  mov eax, $562
  syscall
end;

procedure Syscall_563; stdcall;
asm
  mov r10, rcx
  mov eax, $563
  syscall
end;

procedure Syscall_564; stdcall;
asm
  mov r10, rcx
  mov eax, $564
  syscall
end;

procedure Syscall_565; stdcall;
asm
  mov r10, rcx
  mov eax, $565
  syscall
end;

procedure Syscall_566; stdcall;
asm
  mov r10, rcx
  mov eax, $566
  syscall
end;

procedure Syscall_567; stdcall;
asm
  mov r10, rcx
  mov eax, $567
  syscall
end;

procedure Syscall_568; stdcall;
asm
  mov r10, rcx
  mov eax, $568
  syscall
end;

procedure Syscall_569; stdcall;
asm
  mov r10, rcx
  mov eax, $569
  syscall
end;

procedure Syscall_56A; stdcall;
asm
  mov r10, rcx
  mov eax, $56A
  syscall
end;

procedure Syscall_56B; stdcall;
asm
  mov r10, rcx
  mov eax, $56B
  syscall
end;

procedure Syscall_56C; stdcall;
asm
  mov r10, rcx
  mov eax, $56C
  syscall
end;

procedure Syscall_56D; stdcall;
asm
  mov r10, rcx
  mov eax, $56D
  syscall
end;

procedure Syscall_56E; stdcall;
asm
  mov r10, rcx
  mov eax, $56E
  syscall
end;

procedure Syscall_56F; stdcall;
asm
  mov r10, rcx
  mov eax, $56F
  syscall
end;

procedure Syscall_570; stdcall;
asm
  mov r10, rcx
  mov eax, $570
  syscall
end;

procedure Syscall_571; stdcall;
asm
  mov r10, rcx
  mov eax, $571
  syscall
end;

procedure Syscall_572; stdcall;
asm
  mov r10, rcx
  mov eax, $572
  syscall
end;

procedure Syscall_573; stdcall;
asm
  mov r10, rcx
  mov eax, $573
  syscall
end;

procedure Syscall_574; stdcall;
asm
  mov r10, rcx
  mov eax, $574
  syscall
end;

procedure Syscall_575; stdcall;
asm
  mov r10, rcx
  mov eax, $575
  syscall
end;

procedure Syscall_576; stdcall;
asm
  mov r10, rcx
  mov eax, $576
  syscall
end;

procedure Syscall_577; stdcall;
asm
  mov r10, rcx
  mov eax, $577
  syscall
end;

procedure Syscall_578; stdcall;
asm
  mov r10, rcx
  mov eax, $578
  syscall
end;

procedure Syscall_579; stdcall;
asm
  mov r10, rcx
  mov eax, $579
  syscall
end;

procedure Syscall_57A; stdcall;
asm
  mov r10, rcx
  mov eax, $57A
  syscall
end;

procedure Syscall_57B; stdcall;
asm
  mov r10, rcx
  mov eax, $57B
  syscall
end;

procedure Syscall_57C; stdcall;
asm
  mov r10, rcx
  mov eax, $57C
  syscall
end;

procedure Syscall_57D; stdcall;
asm
  mov r10, rcx
  mov eax, $57D
  syscall
end;

procedure Syscall_57E; stdcall;
asm
  mov r10, rcx
  mov eax, $57E
  syscall
end;

procedure Syscall_57F; stdcall;
asm
  mov r10, rcx
  mov eax, $57F
  syscall
end;

procedure Syscall_580; stdcall;
asm
  mov r10, rcx
  mov eax, $580
  syscall
end;

procedure Syscall_581; stdcall;
asm
  mov r10, rcx
  mov eax, $581
  syscall
end;

procedure Syscall_582; stdcall;
asm
  mov r10, rcx
  mov eax, $582
  syscall
end;

procedure Syscall_583; stdcall;
asm
  mov r10, rcx
  mov eax, $583
  syscall
end;

procedure Syscall_584; stdcall;
asm
  mov r10, rcx
  mov eax, $584
  syscall
end;

procedure Syscall_585; stdcall;
asm
  mov r10, rcx
  mov eax, $585
  syscall
end;

procedure Syscall_586; stdcall;
asm
  mov r10, rcx
  mov eax, $586
  syscall
end;

procedure Syscall_587; stdcall;
asm
  mov r10, rcx
  mov eax, $587
  syscall
end;

procedure Syscall_588; stdcall;
asm
  mov r10, rcx
  mov eax, $588
  syscall
end;

procedure Syscall_589; stdcall;
asm
  mov r10, rcx
  mov eax, $589
  syscall
end;

procedure Syscall_58A; stdcall;
asm
  mov r10, rcx
  mov eax, $58A
  syscall
end;

procedure Syscall_58B; stdcall;
asm
  mov r10, rcx
  mov eax, $58B
  syscall
end;

procedure Syscall_58C; stdcall;
asm
  mov r10, rcx
  mov eax, $58C
  syscall
end;

procedure Syscall_58D; stdcall;
asm
  mov r10, rcx
  mov eax, $58D
  syscall
end;

procedure Syscall_58E; stdcall;
asm
  mov r10, rcx
  mov eax, $58E
  syscall
end;

procedure Syscall_58F; stdcall;
asm
  mov r10, rcx
  mov eax, $58F
  syscall
end;

procedure Syscall_590; stdcall;
asm
  mov r10, rcx
  mov eax, $590
  syscall
end;

procedure Syscall_591; stdcall;
asm
  mov r10, rcx
  mov eax, $591
  syscall
end;

procedure Syscall_592; stdcall;
asm
  mov r10, rcx
  mov eax, $592
  syscall
end;

procedure Syscall_593; stdcall;
asm
  mov r10, rcx
  mov eax, $593
  syscall
end;

procedure Syscall_594; stdcall;
asm
  mov r10, rcx
  mov eax, $594
  syscall
end;

procedure Syscall_595; stdcall;
asm
  mov r10, rcx
  mov eax, $595
  syscall
end;

procedure Syscall_596; stdcall;
asm
  mov r10, rcx
  mov eax, $596
  syscall
end;

procedure Syscall_597; stdcall;
asm
  mov r10, rcx
  mov eax, $597
  syscall
end;

procedure Syscall_598; stdcall;
asm
  mov r10, rcx
  mov eax, $598
  syscall
end;

procedure Syscall_599; stdcall;
asm
  mov r10, rcx
  mov eax, $599
  syscall
end;

procedure Syscall_59A; stdcall;
asm
  mov r10, rcx
  mov eax, $59A
  syscall
end;

procedure Syscall_59B; stdcall;
asm
  mov r10, rcx
  mov eax, $59B
  syscall
end;

procedure Syscall_59C; stdcall;
asm
  mov r10, rcx
  mov eax, $59C
  syscall
end;

procedure Syscall_59D; stdcall;
asm
  mov r10, rcx
  mov eax, $59D
  syscall
end;

procedure Syscall_59E; stdcall;
asm
  mov r10, rcx
  mov eax, $59E
  syscall
end;

procedure Syscall_59F; stdcall;
asm
  mov r10, rcx
  mov eax, $59F
  syscall
end;

procedure Syscall_5A0; stdcall;
asm
  mov r10, rcx
  mov eax, $5A0
  syscall
end;

procedure Syscall_5A1; stdcall;
asm
  mov r10, rcx
  mov eax, $5A1
  syscall
end;

procedure Syscall_5A2; stdcall;
asm
  mov r10, rcx
  mov eax, $5A2
  syscall
end;

procedure Syscall_5A3; stdcall;
asm
  mov r10, rcx
  mov eax, $5A3
  syscall
end;

procedure Syscall_5A4; stdcall;
asm
  mov r10, rcx
  mov eax, $5A4
  syscall
end;

procedure Syscall_5A5; stdcall;
asm
  mov r10, rcx
  mov eax, $5A5
  syscall
end;

procedure Syscall_5A6; stdcall;
asm
  mov r10, rcx
  mov eax, $5A6
  syscall
end;

procedure Syscall_5A7; stdcall;
asm
  mov r10, rcx
  mov eax, $5A7
  syscall
end;

procedure Syscall_5A8; stdcall;
asm
  mov r10, rcx
  mov eax, $5A8
  syscall
end;

procedure Syscall_5A9; stdcall;
asm
  mov r10, rcx
  mov eax, $5A9
  syscall
end;

procedure Syscall_5AA; stdcall;
asm
  mov r10, rcx
  mov eax, $5AA
  syscall
end;

procedure Syscall_5AB; stdcall;
asm
  mov r10, rcx
  mov eax, $5AB
  syscall
end;

procedure Syscall_5AC; stdcall;
asm
  mov r10, rcx
  mov eax, $5AC
  syscall
end;

procedure Syscall_5AD; stdcall;
asm
  mov r10, rcx
  mov eax, $5AD
  syscall
end;

procedure Syscall_5AE; stdcall;
asm
  mov r10, rcx
  mov eax, $5AE
  syscall
end;

procedure Syscall_5AF; stdcall;
asm
  mov r10, rcx
  mov eax, $5AF
  syscall
end;

procedure Syscall_5B0; stdcall;
asm
  mov r10, rcx
  mov eax, $5B0
  syscall
end;

procedure Syscall_5B1; stdcall;
asm
  mov r10, rcx
  mov eax, $5B1
  syscall
end;

procedure Syscall_5B2; stdcall;
asm
  mov r10, rcx
  mov eax, $5B2
  syscall
end;

procedure Syscall_5B3; stdcall;
asm
  mov r10, rcx
  mov eax, $5B3
  syscall
end;

procedure Syscall_5B4; stdcall;
asm
  mov r10, rcx
  mov eax, $5B4
  syscall
end;

procedure Syscall_5B5; stdcall;
asm
  mov r10, rcx
  mov eax, $5B5
  syscall
end;

procedure Syscall_5B6; stdcall;
asm
  mov r10, rcx
  mov eax, $5B6
  syscall
end;

procedure Syscall_5B7; stdcall;
asm
  mov r10, rcx
  mov eax, $5B7
  syscall
end;

procedure Syscall_5B8; stdcall;
asm
  mov r10, rcx
  mov eax, $5B8
  syscall
end;

procedure Syscall_5B9; stdcall;
asm
  mov r10, rcx
  mov eax, $5B9
  syscall
end;

procedure Syscall_5BA; stdcall;
asm
  mov r10, rcx
  mov eax, $5BA
  syscall
end;

procedure Syscall_5BB; stdcall;
asm
  mov r10, rcx
  mov eax, $5BB
  syscall
end;

procedure Syscall_5BC; stdcall;
asm
  mov r10, rcx
  mov eax, $5BC
  syscall
end;

procedure Syscall_5BD; stdcall;
asm
  mov r10, rcx
  mov eax, $5BD
  syscall
end;

procedure Syscall_5BE; stdcall;
asm
  mov r10, rcx
  mov eax, $5BE
  syscall
end;

procedure Syscall_5BF; stdcall;
asm
  mov r10, rcx
  mov eax, $5BF
  syscall
end;

procedure Syscall_5C0; stdcall;
asm
  mov r10, rcx
  mov eax, $5C0
  syscall
end;

procedure Syscall_5C1; stdcall;
asm
  mov r10, rcx
  mov eax, $5C1
  syscall
end;

procedure Syscall_5C2; stdcall;
asm
  mov r10, rcx
  mov eax, $5C2
  syscall
end;

procedure Syscall_5C3; stdcall;
asm
  mov r10, rcx
  mov eax, $5C3
  syscall
end;

procedure Syscall_5C4; stdcall;
asm
  mov r10, rcx
  mov eax, $5C4
  syscall
end;

procedure Syscall_5C5; stdcall;
asm
  mov r10, rcx
  mov eax, $5C5
  syscall
end;

procedure Syscall_5C6; stdcall;
asm
  mov r10, rcx
  mov eax, $5C6
  syscall
end;

procedure Syscall_5C7; stdcall;
asm
  mov r10, rcx
  mov eax, $5C7
  syscall
end;

procedure Syscall_5C8; stdcall;
asm
  mov r10, rcx
  mov eax, $5C8
  syscall
end;

procedure Syscall_5C9; stdcall;
asm
  mov r10, rcx
  mov eax, $5C9
  syscall
end;

procedure Syscall_5CA; stdcall;
asm
  mov r10, rcx
  mov eax, $5CA
  syscall
end;

procedure Syscall_5CB; stdcall;
asm
  mov r10, rcx
  mov eax, $5CB
  syscall
end;

procedure Syscall_5CC; stdcall;
asm
  mov r10, rcx
  mov eax, $5CC
  syscall
end;

procedure Syscall_5CD; stdcall;
asm
  mov r10, rcx
  mov eax, $5CD
  syscall
end;

procedure Syscall_5CE; stdcall;
asm
  mov r10, rcx
  mov eax, $5CE
  syscall
end;

procedure Syscall_5CF; stdcall;
asm
  mov r10, rcx
  mov eax, $5CF
  syscall
end;

procedure Syscall_5D0; stdcall;
asm
  mov r10, rcx
  mov eax, $5D0
  syscall
end;

procedure Syscall_5D1; stdcall;
asm
  mov r10, rcx
  mov eax, $5D1
  syscall
end;

procedure Syscall_5D2; stdcall;
asm
  mov r10, rcx
  mov eax, $5D2
  syscall
end;

procedure Syscall_5D3; stdcall;
asm
  mov r10, rcx
  mov eax, $5D3
  syscall
end;

procedure Syscall_5D4; stdcall;
asm
  mov r10, rcx
  mov eax, $5D4
  syscall
end;

procedure Syscall_5D5; stdcall;
asm
  mov r10, rcx
  mov eax, $5D5
  syscall
end;

procedure Syscall_5D6; stdcall;
asm
  mov r10, rcx
  mov eax, $5D6
  syscall
end;

procedure Syscall_5D7; stdcall;
asm
  mov r10, rcx
  mov eax, $5D7
  syscall
end;

procedure Syscall_5D8; stdcall;
asm
  mov r10, rcx
  mov eax, $5D8
  syscall
end;

procedure Syscall_5D9; stdcall;
asm
  mov r10, rcx
  mov eax, $5D9
  syscall
end;

procedure Syscall_5DA; stdcall;
asm
  mov r10, rcx
  mov eax, $5DA
  syscall
end;

procedure Syscall_5DB; stdcall;
asm
  mov r10, rcx
  mov eax, $5DB
  syscall
end;

procedure Syscall_5DC; stdcall;
asm
  mov r10, rcx
  mov eax, $5DC
  syscall
end;

procedure Syscall_5DD; stdcall;
asm
  mov r10, rcx
  mov eax, $5DD
  syscall
end;

procedure Syscall_5DE; stdcall;
asm
  mov r10, rcx
  mov eax, $5DE
  syscall
end;

procedure Syscall_5DF; stdcall;
asm
  mov r10, rcx
  mov eax, $5DF
  syscall
end;

procedure Syscall_5E0; stdcall;
asm
  mov r10, rcx
  mov eax, $5E0
  syscall
end;

procedure Syscall_5E1; stdcall;
asm
  mov r10, rcx
  mov eax, $5E1
  syscall
end;

procedure Syscall_5E2; stdcall;
asm
  mov r10, rcx
  mov eax, $5E2
  syscall
end;

procedure Syscall_5E3; stdcall;
asm
  mov r10, rcx
  mov eax, $5E3
  syscall
end;

procedure Syscall_5E4; stdcall;
asm
  mov r10, rcx
  mov eax, $5E4
  syscall
end;

procedure Syscall_5E5; stdcall;
asm
  mov r10, rcx
  mov eax, $5E5
  syscall
end;

procedure Syscall_5E6; stdcall;
asm
  mov r10, rcx
  mov eax, $5E6
  syscall
end;

procedure Syscall_5E7; stdcall;
asm
  mov r10, rcx
  mov eax, $5E7
  syscall
end;

procedure Syscall_5E8; stdcall;
asm
  mov r10, rcx
  mov eax, $5E8
  syscall
end;

procedure Syscall_5E9; stdcall;
asm
  mov r10, rcx
  mov eax, $5E9
  syscall
end;

procedure Syscall_5EA; stdcall;
asm
  mov r10, rcx
  mov eax, $5EA
  syscall
end;

procedure Syscall_5EB; stdcall;
asm
  mov r10, rcx
  mov eax, $5EB
  syscall
end;

procedure Syscall_5EC; stdcall;
asm
  mov r10, rcx
  mov eax, $5EC
  syscall
end;

procedure Syscall_5ED; stdcall;
asm
  mov r10, rcx
  mov eax, $5ED
  syscall
end;

procedure Syscall_5EE; stdcall;
asm
  mov r10, rcx
  mov eax, $5EE
  syscall
end;

procedure Syscall_5EF; stdcall;
asm
  mov r10, rcx
  mov eax, $5EF
  syscall
end;

procedure Syscall_5F0; stdcall;
asm
  mov r10, rcx
  mov eax, $5F0
  syscall
end;

procedure Syscall_5F1; stdcall;
asm
  mov r10, rcx
  mov eax, $5F1
  syscall
end;

procedure Syscall_5F2; stdcall;
asm
  mov r10, rcx
  mov eax, $5F2
  syscall
end;

procedure Syscall_5F3; stdcall;
asm
  mov r10, rcx
  mov eax, $5F3
  syscall
end;

procedure Syscall_5F4; stdcall;
asm
  mov r10, rcx
  mov eax, $5F4
  syscall
end;

procedure Syscall_5F5; stdcall;
asm
  mov r10, rcx
  mov eax, $5F5
  syscall
end;

procedure Syscall_5F6; stdcall;
asm
  mov r10, rcx
  mov eax, $5F6
  syscall
end;

procedure Syscall_5F7; stdcall;
asm
  mov r10, rcx
  mov eax, $5F7
  syscall
end;

procedure Syscall_5F8; stdcall;
asm
  mov r10, rcx
  mov eax, $5F8
  syscall
end;

procedure Syscall_5F9; stdcall;
asm
  mov r10, rcx
  mov eax, $5F9
  syscall
end;

procedure Syscall_5FA; stdcall;
asm
  mov r10, rcx
  mov eax, $5FA
  syscall
end;

procedure Syscall_5FB; stdcall;
asm
  mov r10, rcx
  mov eax, $5FB
  syscall
end;

procedure Syscall_5FC; stdcall;
asm
  mov r10, rcx
  mov eax, $5FC
  syscall
end;

procedure Syscall_5FD; stdcall;
asm
  mov r10, rcx
  mov eax, $5FD
  syscall
end;

procedure Syscall_5FE; stdcall;
asm
  mov r10, rcx
  mov eax, $5FE
  syscall
end;

procedure Syscall_5FF; stdcall;
asm
  mov r10, rcx
  mov eax, $5FF
  syscall
end;

procedure Syscall_600; stdcall;
asm
  mov r10, rcx
  mov eax, $600
  syscall
end;

procedure Syscall_601; stdcall;
asm
  mov r10, rcx
  mov eax, $601
  syscall
end;

procedure Syscall_602; stdcall;
asm
  mov r10, rcx
  mov eax, $602
  syscall
end;

procedure Syscall_603; stdcall;
asm
  mov r10, rcx
  mov eax, $603
  syscall
end;

procedure Syscall_604; stdcall;
asm
  mov r10, rcx
  mov eax, $604
  syscall
end;

procedure Syscall_605; stdcall;
asm
  mov r10, rcx
  mov eax, $605
  syscall
end;

procedure Syscall_606; stdcall;
asm
  mov r10, rcx
  mov eax, $606
  syscall
end;

procedure Syscall_607; stdcall;
asm
  mov r10, rcx
  mov eax, $607
  syscall
end;

procedure Syscall_608; stdcall;
asm
  mov r10, rcx
  mov eax, $608
  syscall
end;

procedure Syscall_609; stdcall;
asm
  mov r10, rcx
  mov eax, $609
  syscall
end;

procedure Syscall_60A; stdcall;
asm
  mov r10, rcx
  mov eax, $60A
  syscall
end;

procedure Syscall_60B; stdcall;
asm
  mov r10, rcx
  mov eax, $60B
  syscall
end;

procedure Syscall_60C; stdcall;
asm
  mov r10, rcx
  mov eax, $60C
  syscall
end;

procedure Syscall_60D; stdcall;
asm
  mov r10, rcx
  mov eax, $60D
  syscall
end;

procedure Syscall_60E; stdcall;
asm
  mov r10, rcx
  mov eax, $60E
  syscall
end;

procedure Syscall_60F; stdcall;
asm
  mov r10, rcx
  mov eax, $60F
  syscall
end;

procedure Syscall_610; stdcall;
asm
  mov r10, rcx
  mov eax, $610
  syscall
end;

procedure Syscall_611; stdcall;
asm
  mov r10, rcx
  mov eax, $611
  syscall
end;

procedure Syscall_612; stdcall;
asm
  mov r10, rcx
  mov eax, $612
  syscall
end;

procedure Syscall_613; stdcall;
asm
  mov r10, rcx
  mov eax, $613
  syscall
end;

procedure Syscall_614; stdcall;
asm
  mov r10, rcx
  mov eax, $614
  syscall
end;

procedure Syscall_615; stdcall;
asm
  mov r10, rcx
  mov eax, $615
  syscall
end;

procedure Syscall_616; stdcall;
asm
  mov r10, rcx
  mov eax, $616
  syscall
end;

procedure Syscall_617; stdcall;
asm
  mov r10, rcx
  mov eax, $617
  syscall
end;

procedure Syscall_618; stdcall;
asm
  mov r10, rcx
  mov eax, $618
  syscall
end;

procedure Syscall_619; stdcall;
asm
  mov r10, rcx
  mov eax, $619
  syscall
end;

procedure Syscall_61A; stdcall;
asm
  mov r10, rcx
  mov eax, $61A
  syscall
end;

procedure Syscall_61B; stdcall;
asm
  mov r10, rcx
  mov eax, $61B
  syscall
end;

procedure Syscall_61C; stdcall;
asm
  mov r10, rcx
  mov eax, $61C
  syscall
end;

procedure Syscall_61D; stdcall;
asm
  mov r10, rcx
  mov eax, $61D
  syscall
end;

procedure Syscall_61E; stdcall;
asm
  mov r10, rcx
  mov eax, $61E
  syscall
end;

procedure Syscall_61F; stdcall;
asm
  mov r10, rcx
  mov eax, $61F
  syscall
end;

procedure Syscall_620; stdcall;
asm
  mov r10, rcx
  mov eax, $620
  syscall
end;

procedure Syscall_621; stdcall;
asm
  mov r10, rcx
  mov eax, $621
  syscall
end;

procedure Syscall_622; stdcall;
asm
  mov r10, rcx
  mov eax, $622
  syscall
end;

procedure Syscall_623; stdcall;
asm
  mov r10, rcx
  mov eax, $623
  syscall
end;

procedure Syscall_624; stdcall;
asm
  mov r10, rcx
  mov eax, $624
  syscall
end;

procedure Syscall_625; stdcall;
asm
  mov r10, rcx
  mov eax, $625
  syscall
end;

procedure Syscall_626; stdcall;
asm
  mov r10, rcx
  mov eax, $626
  syscall
end;

procedure Syscall_627; stdcall;
asm
  mov r10, rcx
  mov eax, $627
  syscall
end;

procedure Syscall_628; stdcall;
asm
  mov r10, rcx
  mov eax, $628
  syscall
end;

procedure Syscall_629; stdcall;
asm
  mov r10, rcx
  mov eax, $629
  syscall
end;

procedure Syscall_62A; stdcall;
asm
  mov r10, rcx
  mov eax, $62A
  syscall
end;

procedure Syscall_62B; stdcall;
asm
  mov r10, rcx
  mov eax, $62B
  syscall
end;

procedure Syscall_62C; stdcall;
asm
  mov r10, rcx
  mov eax, $62C
  syscall
end;

procedure Syscall_62D; stdcall;
asm
  mov r10, rcx
  mov eax, $62D
  syscall
end;

procedure Syscall_62E; stdcall;
asm
  mov r10, rcx
  mov eax, $62E
  syscall
end;

procedure Syscall_62F; stdcall;
asm
  mov r10, rcx
  mov eax, $62F
  syscall
end;

procedure Syscall_630; stdcall;
asm
  mov r10, rcx
  mov eax, $630
  syscall
end;

procedure Syscall_631; stdcall;
asm
  mov r10, rcx
  mov eax, $631
  syscall
end;

procedure Syscall_632; stdcall;
asm
  mov r10, rcx
  mov eax, $632
  syscall
end;

procedure Syscall_633; stdcall;
asm
  mov r10, rcx
  mov eax, $633
  syscall
end;

procedure Syscall_634; stdcall;
asm
  mov r10, rcx
  mov eax, $634
  syscall
end;

procedure Syscall_635; stdcall;
asm
  mov r10, rcx
  mov eax, $635
  syscall
end;

procedure Syscall_636; stdcall;
asm
  mov r10, rcx
  mov eax, $636
  syscall
end;

procedure Syscall_637; stdcall;
asm
  mov r10, rcx
  mov eax, $637
  syscall
end;

procedure Syscall_638; stdcall;
asm
  mov r10, rcx
  mov eax, $638
  syscall
end;

procedure Syscall_639; stdcall;
asm
  mov r10, rcx
  mov eax, $639
  syscall
end;

procedure Syscall_63A; stdcall;
asm
  mov r10, rcx
  mov eax, $63A
  syscall
end;

procedure Syscall_63B; stdcall;
asm
  mov r10, rcx
  mov eax, $63B
  syscall
end;

procedure Syscall_63C; stdcall;
asm
  mov r10, rcx
  mov eax, $63C
  syscall
end;

procedure Syscall_63D; stdcall;
asm
  mov r10, rcx
  mov eax, $63D
  syscall
end;

procedure Syscall_63E; stdcall;
asm
  mov r10, rcx
  mov eax, $63E
  syscall
end;

procedure Syscall_63F; stdcall;
asm
  mov r10, rcx
  mov eax, $63F
  syscall
end;

procedure Syscall_640; stdcall;
asm
  mov r10, rcx
  mov eax, $640
  syscall
end;

procedure Syscall_641; stdcall;
asm
  mov r10, rcx
  mov eax, $641
  syscall
end;

procedure Syscall_642; stdcall;
asm
  mov r10, rcx
  mov eax, $642
  syscall
end;

procedure Syscall_643; stdcall;
asm
  mov r10, rcx
  mov eax, $643
  syscall
end;

procedure Syscall_644; stdcall;
asm
  mov r10, rcx
  mov eax, $644
  syscall
end;

procedure Syscall_645; stdcall;
asm
  mov r10, rcx
  mov eax, $645
  syscall
end;

procedure Syscall_646; stdcall;
asm
  mov r10, rcx
  mov eax, $646
  syscall
end;

procedure Syscall_647; stdcall;
asm
  mov r10, rcx
  mov eax, $647
  syscall
end;

procedure Syscall_648; stdcall;
asm
  mov r10, rcx
  mov eax, $648
  syscall
end;

procedure Syscall_649; stdcall;
asm
  mov r10, rcx
  mov eax, $649
  syscall
end;

procedure Syscall_64A; stdcall;
asm
  mov r10, rcx
  mov eax, $64A
  syscall
end;

procedure Syscall_64B; stdcall;
asm
  mov r10, rcx
  mov eax, $64B
  syscall
end;

procedure Syscall_64C; stdcall;
asm
  mov r10, rcx
  mov eax, $64C
  syscall
end;

procedure Syscall_64D; stdcall;
asm
  mov r10, rcx
  mov eax, $64D
  syscall
end;

procedure Syscall_64E; stdcall;
asm
  mov r10, rcx
  mov eax, $64E
  syscall
end;

procedure Syscall_64F; stdcall;
asm
  mov r10, rcx
  mov eax, $64F
  syscall
end;

procedure Syscall_650; stdcall;
asm
  mov r10, rcx
  mov eax, $650
  syscall
end;

procedure Syscall_651; stdcall;
asm
  mov r10, rcx
  mov eax, $651
  syscall
end;

procedure Syscall_652; stdcall;
asm
  mov r10, rcx
  mov eax, $652
  syscall
end;

procedure Syscall_653; stdcall;
asm
  mov r10, rcx
  mov eax, $653
  syscall
end;

procedure Syscall_654; stdcall;
asm
  mov r10, rcx
  mov eax, $654
  syscall
end;

procedure Syscall_655; stdcall;
asm
  mov r10, rcx
  mov eax, $655
  syscall
end;

procedure Syscall_656; stdcall;
asm
  mov r10, rcx
  mov eax, $656
  syscall
end;

procedure Syscall_657; stdcall;
asm
  mov r10, rcx
  mov eax, $657
  syscall
end;

procedure Syscall_658; stdcall;
asm
  mov r10, rcx
  mov eax, $658
  syscall
end;

procedure Syscall_659; stdcall;
asm
  mov r10, rcx
  mov eax, $659
  syscall
end;

procedure Syscall_65A; stdcall;
asm
  mov r10, rcx
  mov eax, $65A
  syscall
end;

procedure Syscall_65B; stdcall;
asm
  mov r10, rcx
  mov eax, $65B
  syscall
end;

procedure Syscall_65C; stdcall;
asm
  mov r10, rcx
  mov eax, $65C
  syscall
end;

procedure Syscall_65D; stdcall;
asm
  mov r10, rcx
  mov eax, $65D
  syscall
end;

procedure Syscall_65E; stdcall;
asm
  mov r10, rcx
  mov eax, $65E
  syscall
end;

procedure Syscall_65F; stdcall;
asm
  mov r10, rcx
  mov eax, $65F
  syscall
end;

procedure Syscall_660; stdcall;
asm
  mov r10, rcx
  mov eax, $660
  syscall
end;

procedure Syscall_661; stdcall;
asm
  mov r10, rcx
  mov eax, $661
  syscall
end;

procedure Syscall_662; stdcall;
asm
  mov r10, rcx
  mov eax, $662
  syscall
end;

procedure Syscall_663; stdcall;
asm
  mov r10, rcx
  mov eax, $663
  syscall
end;

procedure Syscall_664; stdcall;
asm
  mov r10, rcx
  mov eax, $664
  syscall
end;

procedure Syscall_665; stdcall;
asm
  mov r10, rcx
  mov eax, $665
  syscall
end;

procedure Syscall_666; stdcall;
asm
  mov r10, rcx
  mov eax, $666
  syscall
end;

procedure Syscall_667; stdcall;
asm
  mov r10, rcx
  mov eax, $667
  syscall
end;

procedure Syscall_668; stdcall;
asm
  mov r10, rcx
  mov eax, $668
  syscall
end;

procedure Syscall_669; stdcall;
asm
  mov r10, rcx
  mov eax, $669
  syscall
end;

procedure Syscall_66A; stdcall;
asm
  mov r10, rcx
  mov eax, $66A
  syscall
end;

procedure Syscall_66B; stdcall;
asm
  mov r10, rcx
  mov eax, $66B
  syscall
end;

procedure Syscall_66C; stdcall;
asm
  mov r10, rcx
  mov eax, $66C
  syscall
end;

procedure Syscall_66D; stdcall;
asm
  mov r10, rcx
  mov eax, $66D
  syscall
end;

procedure Syscall_66E; stdcall;
asm
  mov r10, rcx
  mov eax, $66E
  syscall
end;

procedure Syscall_66F; stdcall;
asm
  mov r10, rcx
  mov eax, $66F
  syscall
end;

procedure Syscall_670; stdcall;
asm
  mov r10, rcx
  mov eax, $670
  syscall
end;

procedure Syscall_671; stdcall;
asm
  mov r10, rcx
  mov eax, $671
  syscall
end;

procedure Syscall_672; stdcall;
asm
  mov r10, rcx
  mov eax, $672
  syscall
end;

procedure Syscall_673; stdcall;
asm
  mov r10, rcx
  mov eax, $673
  syscall
end;

procedure Syscall_674; stdcall;
asm
  mov r10, rcx
  mov eax, $674
  syscall
end;

procedure Syscall_675; stdcall;
asm
  mov r10, rcx
  mov eax, $675
  syscall
end;

procedure Syscall_676; stdcall;
asm
  mov r10, rcx
  mov eax, $676
  syscall
end;

procedure Syscall_677; stdcall;
asm
  mov r10, rcx
  mov eax, $677
  syscall
end;

procedure Syscall_678; stdcall;
asm
  mov r10, rcx
  mov eax, $678
  syscall
end;

procedure Syscall_679; stdcall;
asm
  mov r10, rcx
  mov eax, $679
  syscall
end;

procedure Syscall_67A; stdcall;
asm
  mov r10, rcx
  mov eax, $67A
  syscall
end;

procedure Syscall_67B; stdcall;
asm
  mov r10, rcx
  mov eax, $67B
  syscall
end;

procedure Syscall_67C; stdcall;
asm
  mov r10, rcx
  mov eax, $67C
  syscall
end;

procedure Syscall_67D; stdcall;
asm
  mov r10, rcx
  mov eax, $67D
  syscall
end;

procedure Syscall_67E; stdcall;
asm
  mov r10, rcx
  mov eax, $67E
  syscall
end;

procedure Syscall_67F; stdcall;
asm
  mov r10, rcx
  mov eax, $67F
  syscall
end;

procedure Syscall_680; stdcall;
asm
  mov r10, rcx
  mov eax, $680
  syscall
end;

procedure Syscall_681; stdcall;
asm
  mov r10, rcx
  mov eax, $681
  syscall
end;

procedure Syscall_682; stdcall;
asm
  mov r10, rcx
  mov eax, $682
  syscall
end;

procedure Syscall_683; stdcall;
asm
  mov r10, rcx
  mov eax, $683
  syscall
end;

procedure Syscall_684; stdcall;
asm
  mov r10, rcx
  mov eax, $684
  syscall
end;

procedure Syscall_685; stdcall;
asm
  mov r10, rcx
  mov eax, $685
  syscall
end;

procedure Syscall_686; stdcall;
asm
  mov r10, rcx
  mov eax, $686
  syscall
end;

procedure Syscall_687; stdcall;
asm
  mov r10, rcx
  mov eax, $687
  syscall
end;

procedure Syscall_688; stdcall;
asm
  mov r10, rcx
  mov eax, $688
  syscall
end;

procedure Syscall_689; stdcall;
asm
  mov r10, rcx
  mov eax, $689
  syscall
end;

procedure Syscall_68A; stdcall;
asm
  mov r10, rcx
  mov eax, $68A
  syscall
end;

procedure Syscall_68B; stdcall;
asm
  mov r10, rcx
  mov eax, $68B
  syscall
end;

procedure Syscall_68C; stdcall;
asm
  mov r10, rcx
  mov eax, $68C
  syscall
end;

procedure Syscall_68D; stdcall;
asm
  mov r10, rcx
  mov eax, $68D
  syscall
end;

procedure Syscall_68E; stdcall;
asm
  mov r10, rcx
  mov eax, $68E
  syscall
end;

procedure Syscall_68F; stdcall;
asm
  mov r10, rcx
  mov eax, $68F
  syscall
end;

procedure Syscall_690; stdcall;
asm
  mov r10, rcx
  mov eax, $690
  syscall
end;

procedure Syscall_691; stdcall;
asm
  mov r10, rcx
  mov eax, $691
  syscall
end;

procedure Syscall_692; stdcall;
asm
  mov r10, rcx
  mov eax, $692
  syscall
end;

procedure Syscall_693; stdcall;
asm
  mov r10, rcx
  mov eax, $693
  syscall
end;

procedure Syscall_694; stdcall;
asm
  mov r10, rcx
  mov eax, $694
  syscall
end;

procedure Syscall_695; stdcall;
asm
  mov r10, rcx
  mov eax, $695
  syscall
end;

procedure Syscall_696; stdcall;
asm
  mov r10, rcx
  mov eax, $696
  syscall
end;

procedure Syscall_697; stdcall;
asm
  mov r10, rcx
  mov eax, $697
  syscall
end;

procedure Syscall_698; stdcall;
asm
  mov r10, rcx
  mov eax, $698
  syscall
end;

procedure Syscall_699; stdcall;
asm
  mov r10, rcx
  mov eax, $699
  syscall
end;

procedure Syscall_69A; stdcall;
asm
  mov r10, rcx
  mov eax, $69A
  syscall
end;

procedure Syscall_69B; stdcall;
asm
  mov r10, rcx
  mov eax, $69B
  syscall
end;

procedure Syscall_69C; stdcall;
asm
  mov r10, rcx
  mov eax, $69C
  syscall
end;

procedure Syscall_69D; stdcall;
asm
  mov r10, rcx
  mov eax, $69D
  syscall
end;

procedure Syscall_69E; stdcall;
asm
  mov r10, rcx
  mov eax, $69E
  syscall
end;

procedure Syscall_69F; stdcall;
asm
  mov r10, rcx
  mov eax, $69F
  syscall
end;

procedure Syscall_6A0; stdcall;
asm
  mov r10, rcx
  mov eax, $6A0
  syscall
end;

procedure Syscall_6A1; stdcall;
asm
  mov r10, rcx
  mov eax, $6A1
  syscall
end;

procedure Syscall_6A2; stdcall;
asm
  mov r10, rcx
  mov eax, $6A2
  syscall
end;

procedure Syscall_6A3; stdcall;
asm
  mov r10, rcx
  mov eax, $6A3
  syscall
end;

procedure Syscall_6A4; stdcall;
asm
  mov r10, rcx
  mov eax, $6A4
  syscall
end;

procedure Syscall_6A5; stdcall;
asm
  mov r10, rcx
  mov eax, $6A5
  syscall
end;

procedure Syscall_6A6; stdcall;
asm
  mov r10, rcx
  mov eax, $6A6
  syscall
end;

procedure Syscall_6A7; stdcall;
asm
  mov r10, rcx
  mov eax, $6A7
  syscall
end;

procedure Syscall_6A8; stdcall;
asm
  mov r10, rcx
  mov eax, $6A8
  syscall
end;

procedure Syscall_6A9; stdcall;
asm
  mov r10, rcx
  mov eax, $6A9
  syscall
end;

procedure Syscall_6AA; stdcall;
asm
  mov r10, rcx
  mov eax, $6AA
  syscall
end;

procedure Syscall_6AB; stdcall;
asm
  mov r10, rcx
  mov eax, $6AB
  syscall
end;

procedure Syscall_6AC; stdcall;
asm
  mov r10, rcx
  mov eax, $6AC
  syscall
end;

procedure Syscall_6AD; stdcall;
asm
  mov r10, rcx
  mov eax, $6AD
  syscall
end;

procedure Syscall_6AE; stdcall;
asm
  mov r10, rcx
  mov eax, $6AE
  syscall
end;

procedure Syscall_6AF; stdcall;
asm
  mov r10, rcx
  mov eax, $6AF
  syscall
end;

procedure Syscall_6B0; stdcall;
asm
  mov r10, rcx
  mov eax, $6B0
  syscall
end;

procedure Syscall_6B1; stdcall;
asm
  mov r10, rcx
  mov eax, $6B1
  syscall
end;

procedure Syscall_6B2; stdcall;
asm
  mov r10, rcx
  mov eax, $6B2
  syscall
end;

procedure Syscall_6B3; stdcall;
asm
  mov r10, rcx
  mov eax, $6B3
  syscall
end;

procedure Syscall_6B4; stdcall;
asm
  mov r10, rcx
  mov eax, $6B4
  syscall
end;

procedure Syscall_6B5; stdcall;
asm
  mov r10, rcx
  mov eax, $6B5
  syscall
end;

procedure Syscall_6B6; stdcall;
asm
  mov r10, rcx
  mov eax, $6B6
  syscall
end;

procedure Syscall_6B7; stdcall;
asm
  mov r10, rcx
  mov eax, $6B7
  syscall
end;

procedure Syscall_6B8; stdcall;
asm
  mov r10, rcx
  mov eax, $6B8
  syscall
end;

procedure Syscall_6B9; stdcall;
asm
  mov r10, rcx
  mov eax, $6B9
  syscall
end;

procedure Syscall_6BA; stdcall;
asm
  mov r10, rcx
  mov eax, $6BA
  syscall
end;

procedure Syscall_6BB; stdcall;
asm
  mov r10, rcx
  mov eax, $6BB
  syscall
end;

procedure Syscall_6BC; stdcall;
asm
  mov r10, rcx
  mov eax, $6BC
  syscall
end;

procedure Syscall_6BD; stdcall;
asm
  mov r10, rcx
  mov eax, $6BD
  syscall
end;

procedure Syscall_6BE; stdcall;
asm
  mov r10, rcx
  mov eax, $6BE
  syscall
end;

procedure Syscall_6BF; stdcall;
asm
  mov r10, rcx
  mov eax, $6BF
  syscall
end;

procedure Syscall_6C0; stdcall;
asm
  mov r10, rcx
  mov eax, $6C0
  syscall
end;

procedure Syscall_6C1; stdcall;
asm
  mov r10, rcx
  mov eax, $6C1
  syscall
end;

procedure Syscall_6C2; stdcall;
asm
  mov r10, rcx
  mov eax, $6C2
  syscall
end;

procedure Syscall_6C3; stdcall;
asm
  mov r10, rcx
  mov eax, $6C3
  syscall
end;

procedure Syscall_6C4; stdcall;
asm
  mov r10, rcx
  mov eax, $6C4
  syscall
end;

procedure Syscall_6C5; stdcall;
asm
  mov r10, rcx
  mov eax, $6C5
  syscall
end;

procedure Syscall_6C6; stdcall;
asm
  mov r10, rcx
  mov eax, $6C6
  syscall
end;

procedure Syscall_6C7; stdcall;
asm
  mov r10, rcx
  mov eax, $6C7
  syscall
end;

procedure Syscall_6C8; stdcall;
asm
  mov r10, rcx
  mov eax, $6C8
  syscall
end;

procedure Syscall_6C9; stdcall;
asm
  mov r10, rcx
  mov eax, $6C9
  syscall
end;

procedure Syscall_6CA; stdcall;
asm
  mov r10, rcx
  mov eax, $6CA
  syscall
end;

procedure Syscall_6CB; stdcall;
asm
  mov r10, rcx
  mov eax, $6CB
  syscall
end;

procedure Syscall_6CC; stdcall;
asm
  mov r10, rcx
  mov eax, $6CC
  syscall
end;

procedure Syscall_6CD; stdcall;
asm
  mov r10, rcx
  mov eax, $6CD
  syscall
end;

procedure Syscall_6CE; stdcall;
asm
  mov r10, rcx
  mov eax, $6CE
  syscall
end;

procedure Syscall_6CF; stdcall;
asm
  mov r10, rcx
  mov eax, $6CF
  syscall
end;

procedure Syscall_6D0; stdcall;
asm
  mov r10, rcx
  mov eax, $6D0
  syscall
end;

procedure Syscall_6D1; stdcall;
asm
  mov r10, rcx
  mov eax, $6D1
  syscall
end;

procedure Syscall_6D2; stdcall;
asm
  mov r10, rcx
  mov eax, $6D2
  syscall
end;

procedure Syscall_6D3; stdcall;
asm
  mov r10, rcx
  mov eax, $6D3
  syscall
end;

procedure Syscall_6D4; stdcall;
asm
  mov r10, rcx
  mov eax, $6D4
  syscall
end;

procedure Syscall_6D5; stdcall;
asm
  mov r10, rcx
  mov eax, $6D5
  syscall
end;

procedure Syscall_6D6; stdcall;
asm
  mov r10, rcx
  mov eax, $6D6
  syscall
end;

procedure Syscall_6D7; stdcall;
asm
  mov r10, rcx
  mov eax, $6D7
  syscall
end;

procedure Syscall_6D8; stdcall;
asm
  mov r10, rcx
  mov eax, $6D8
  syscall
end;

procedure Syscall_6D9; stdcall;
asm
  mov r10, rcx
  mov eax, $6D9
  syscall
end;

procedure Syscall_6DA; stdcall;
asm
  mov r10, rcx
  mov eax, $6DA
  syscall
end;

procedure Syscall_6DB; stdcall;
asm
  mov r10, rcx
  mov eax, $6DB
  syscall
end;

procedure Syscall_6DC; stdcall;
asm
  mov r10, rcx
  mov eax, $6DC
  syscall
end;

procedure Syscall_6DD; stdcall;
asm
  mov r10, rcx
  mov eax, $6DD
  syscall
end;

procedure Syscall_6DE; stdcall;
asm
  mov r10, rcx
  mov eax, $6DE
  syscall
end;

procedure Syscall_6DF; stdcall;
asm
  mov r10, rcx
  mov eax, $6DF
  syscall
end;

procedure Syscall_6E0; stdcall;
asm
  mov r10, rcx
  mov eax, $6E0
  syscall
end;

procedure Syscall_6E1; stdcall;
asm
  mov r10, rcx
  mov eax, $6E1
  syscall
end;

procedure Syscall_6E2; stdcall;
asm
  mov r10, rcx
  mov eax, $6E2
  syscall
end;

procedure Syscall_6E3; stdcall;
asm
  mov r10, rcx
  mov eax, $6E3
  syscall
end;

procedure Syscall_6E4; stdcall;
asm
  mov r10, rcx
  mov eax, $6E4
  syscall
end;

procedure Syscall_6E5; stdcall;
asm
  mov r10, rcx
  mov eax, $6E5
  syscall
end;

procedure Syscall_6E6; stdcall;
asm
  mov r10, rcx
  mov eax, $6E6
  syscall
end;

procedure Syscall_6E7; stdcall;
asm
  mov r10, rcx
  mov eax, $6E7
  syscall
end;

procedure Syscall_6E8; stdcall;
asm
  mov r10, rcx
  mov eax, $6E8
  syscall
end;

procedure Syscall_6E9; stdcall;
asm
  mov r10, rcx
  mov eax, $6E9
  syscall
end;

procedure Syscall_6EA; stdcall;
asm
  mov r10, rcx
  mov eax, $6EA
  syscall
end;

procedure Syscall_6EB; stdcall;
asm
  mov r10, rcx
  mov eax, $6EB
  syscall
end;

procedure Syscall_6EC; stdcall;
asm
  mov r10, rcx
  mov eax, $6EC
  syscall
end;

procedure Syscall_6ED; stdcall;
asm
  mov r10, rcx
  mov eax, $6ED
  syscall
end;

procedure Syscall_6EE; stdcall;
asm
  mov r10, rcx
  mov eax, $6EE
  syscall
end;

procedure Syscall_6EF; stdcall;
asm
  mov r10, rcx
  mov eax, $6EF
  syscall
end;

procedure Syscall_6F0; stdcall;
asm
  mov r10, rcx
  mov eax, $6F0
  syscall
end;

procedure Syscall_6F1; stdcall;
asm
  mov r10, rcx
  mov eax, $6F1
  syscall
end;

procedure Syscall_6F2; stdcall;
asm
  mov r10, rcx
  mov eax, $6F2
  syscall
end;

procedure Syscall_6F3; stdcall;
asm
  mov r10, rcx
  mov eax, $6F3
  syscall
end;

procedure Syscall_6F4; stdcall;
asm
  mov r10, rcx
  mov eax, $6F4
  syscall
end;

procedure Syscall_6F5; stdcall;
asm
  mov r10, rcx
  mov eax, $6F5
  syscall
end;

procedure Syscall_6F6; stdcall;
asm
  mov r10, rcx
  mov eax, $6F6
  syscall
end;

procedure Syscall_6F7; stdcall;
asm
  mov r10, rcx
  mov eax, $6F7
  syscall
end;

procedure Syscall_6F8; stdcall;
asm
  mov r10, rcx
  mov eax, $6F8
  syscall
end;

procedure Syscall_6F9; stdcall;
asm
  mov r10, rcx
  mov eax, $6F9
  syscall
end;

procedure Syscall_6FA; stdcall;
asm
  mov r10, rcx
  mov eax, $6FA
  syscall
end;

procedure Syscall_6FB; stdcall;
asm
  mov r10, rcx
  mov eax, $6FB
  syscall
end;

procedure Syscall_6FC; stdcall;
asm
  mov r10, rcx
  mov eax, $6FC
  syscall
end;

procedure Syscall_6FD; stdcall;
asm
  mov r10, rcx
  mov eax, $6FD
  syscall
end;

procedure Syscall_6FE; stdcall;
asm
  mov r10, rcx
  mov eax, $6FE
  syscall
end;

procedure Syscall_6FF; stdcall;
asm
  mov r10, rcx
  mov eax, $6FF
  syscall
end;

procedure Syscall_700; stdcall;
asm
  mov r10, rcx
  mov eax, $700
  syscall
end;

procedure Syscall_701; stdcall;
asm
  mov r10, rcx
  mov eax, $701
  syscall
end;

procedure Syscall_702; stdcall;
asm
  mov r10, rcx
  mov eax, $702
  syscall
end;

procedure Syscall_703; stdcall;
asm
  mov r10, rcx
  mov eax, $703
  syscall
end;

procedure Syscall_704; stdcall;
asm
  mov r10, rcx
  mov eax, $704
  syscall
end;

procedure Syscall_705; stdcall;
asm
  mov r10, rcx
  mov eax, $705
  syscall
end;

procedure Syscall_706; stdcall;
asm
  mov r10, rcx
  mov eax, $706
  syscall
end;

procedure Syscall_707; stdcall;
asm
  mov r10, rcx
  mov eax, $707
  syscall
end;

procedure Syscall_708; stdcall;
asm
  mov r10, rcx
  mov eax, $708
  syscall
end;

procedure Syscall_709; stdcall;
asm
  mov r10, rcx
  mov eax, $709
  syscall
end;

procedure Syscall_70A; stdcall;
asm
  mov r10, rcx
  mov eax, $70A
  syscall
end;

procedure Syscall_70B; stdcall;
asm
  mov r10, rcx
  mov eax, $70B
  syscall
end;

procedure Syscall_70C; stdcall;
asm
  mov r10, rcx
  mov eax, $70C
  syscall
end;

procedure Syscall_70D; stdcall;
asm
  mov r10, rcx
  mov eax, $70D
  syscall
end;

procedure Syscall_70E; stdcall;
asm
  mov r10, rcx
  mov eax, $70E
  syscall
end;

procedure Syscall_70F; stdcall;
asm
  mov r10, rcx
  mov eax, $70F
  syscall
end;

procedure Syscall_710; stdcall;
asm
  mov r10, rcx
  mov eax, $710
  syscall
end;

procedure Syscall_711; stdcall;
asm
  mov r10, rcx
  mov eax, $711
  syscall
end;

procedure Syscall_712; stdcall;
asm
  mov r10, rcx
  mov eax, $712
  syscall
end;

procedure Syscall_713; stdcall;
asm
  mov r10, rcx
  mov eax, $713
  syscall
end;

procedure Syscall_714; stdcall;
asm
  mov r10, rcx
  mov eax, $714
  syscall
end;

procedure Syscall_715; stdcall;
asm
  mov r10, rcx
  mov eax, $715
  syscall
end;

procedure Syscall_716; stdcall;
asm
  mov r10, rcx
  mov eax, $716
  syscall
end;

procedure Syscall_717; stdcall;
asm
  mov r10, rcx
  mov eax, $717
  syscall
end;

procedure Syscall_718; stdcall;
asm
  mov r10, rcx
  mov eax, $718
  syscall
end;

procedure Syscall_719; stdcall;
asm
  mov r10, rcx
  mov eax, $719
  syscall
end;

procedure Syscall_71A; stdcall;
asm
  mov r10, rcx
  mov eax, $71A
  syscall
end;

procedure Syscall_71B; stdcall;
asm
  mov r10, rcx
  mov eax, $71B
  syscall
end;

procedure Syscall_71C; stdcall;
asm
  mov r10, rcx
  mov eax, $71C
  syscall
end;

procedure Syscall_71D; stdcall;
asm
  mov r10, rcx
  mov eax, $71D
  syscall
end;

procedure Syscall_71E; stdcall;
asm
  mov r10, rcx
  mov eax, $71E
  syscall
end;

procedure Syscall_71F; stdcall;
asm
  mov r10, rcx
  mov eax, $71F
  syscall
end;

procedure Syscall_720; stdcall;
asm
  mov r10, rcx
  mov eax, $720
  syscall
end;

procedure Syscall_721; stdcall;
asm
  mov r10, rcx
  mov eax, $721
  syscall
end;

procedure Syscall_722; stdcall;
asm
  mov r10, rcx
  mov eax, $722
  syscall
end;

procedure Syscall_723; stdcall;
asm
  mov r10, rcx
  mov eax, $723
  syscall
end;

procedure Syscall_724; stdcall;
asm
  mov r10, rcx
  mov eax, $724
  syscall
end;

procedure Syscall_725; stdcall;
asm
  mov r10, rcx
  mov eax, $725
  syscall
end;

procedure Syscall_726; stdcall;
asm
  mov r10, rcx
  mov eax, $726
  syscall
end;

procedure Syscall_727; stdcall;
asm
  mov r10, rcx
  mov eax, $727
  syscall
end;

procedure Syscall_728; stdcall;
asm
  mov r10, rcx
  mov eax, $728
  syscall
end;

procedure Syscall_729; stdcall;
asm
  mov r10, rcx
  mov eax, $729
  syscall
end;

procedure Syscall_72A; stdcall;
asm
  mov r10, rcx
  mov eax, $72A
  syscall
end;

procedure Syscall_72B; stdcall;
asm
  mov r10, rcx
  mov eax, $72B
  syscall
end;

procedure Syscall_72C; stdcall;
asm
  mov r10, rcx
  mov eax, $72C
  syscall
end;

procedure Syscall_72D; stdcall;
asm
  mov r10, rcx
  mov eax, $72D
  syscall
end;

procedure Syscall_72E; stdcall;
asm
  mov r10, rcx
  mov eax, $72E
  syscall
end;

procedure Syscall_72F; stdcall;
asm
  mov r10, rcx
  mov eax, $72F
  syscall
end;

procedure Syscall_730; stdcall;
asm
  mov r10, rcx
  mov eax, $730
  syscall
end;

procedure Syscall_731; stdcall;
asm
  mov r10, rcx
  mov eax, $731
  syscall
end;

procedure Syscall_732; stdcall;
asm
  mov r10, rcx
  mov eax, $732
  syscall
end;

procedure Syscall_733; stdcall;
asm
  mov r10, rcx
  mov eax, $733
  syscall
end;

procedure Syscall_734; stdcall;
asm
  mov r10, rcx
  mov eax, $734
  syscall
end;

procedure Syscall_735; stdcall;
asm
  mov r10, rcx
  mov eax, $735
  syscall
end;

procedure Syscall_736; stdcall;
asm
  mov r10, rcx
  mov eax, $736
  syscall
end;

procedure Syscall_737; stdcall;
asm
  mov r10, rcx
  mov eax, $737
  syscall
end;

procedure Syscall_738; stdcall;
asm
  mov r10, rcx
  mov eax, $738
  syscall
end;

procedure Syscall_739; stdcall;
asm
  mov r10, rcx
  mov eax, $739
  syscall
end;

procedure Syscall_73A; stdcall;
asm
  mov r10, rcx
  mov eax, $73A
  syscall
end;

procedure Syscall_73B; stdcall;
asm
  mov r10, rcx
  mov eax, $73B
  syscall
end;

procedure Syscall_73C; stdcall;
asm
  mov r10, rcx
  mov eax, $73C
  syscall
end;

procedure Syscall_73D; stdcall;
asm
  mov r10, rcx
  mov eax, $73D
  syscall
end;

procedure Syscall_73E; stdcall;
asm
  mov r10, rcx
  mov eax, $73E
  syscall
end;

procedure Syscall_73F; stdcall;
asm
  mov r10, rcx
  mov eax, $73F
  syscall
end;

procedure Syscall_740; stdcall;
asm
  mov r10, rcx
  mov eax, $740
  syscall
end;

procedure Syscall_741; stdcall;
asm
  mov r10, rcx
  mov eax, $741
  syscall
end;

procedure Syscall_742; stdcall;
asm
  mov r10, rcx
  mov eax, $742
  syscall
end;

procedure Syscall_743; stdcall;
asm
  mov r10, rcx
  mov eax, $743
  syscall
end;

procedure Syscall_744; stdcall;
asm
  mov r10, rcx
  mov eax, $744
  syscall
end;

procedure Syscall_745; stdcall;
asm
  mov r10, rcx
  mov eax, $745
  syscall
end;

procedure Syscall_746; stdcall;
asm
  mov r10, rcx
  mov eax, $746
  syscall
end;

procedure Syscall_747; stdcall;
asm
  mov r10, rcx
  mov eax, $747
  syscall
end;

procedure Syscall_748; stdcall;
asm
  mov r10, rcx
  mov eax, $748
  syscall
end;

procedure Syscall_749; stdcall;
asm
  mov r10, rcx
  mov eax, $749
  syscall
end;

procedure Syscall_74A; stdcall;
asm
  mov r10, rcx
  mov eax, $74A
  syscall
end;

procedure Syscall_74B; stdcall;
asm
  mov r10, rcx
  mov eax, $74B
  syscall
end;

procedure Syscall_74C; stdcall;
asm
  mov r10, rcx
  mov eax, $74C
  syscall
end;

procedure Syscall_74D; stdcall;
asm
  mov r10, rcx
  mov eax, $74D
  syscall
end;

procedure Syscall_74E; stdcall;
asm
  mov r10, rcx
  mov eax, $74E
  syscall
end;

procedure Syscall_74F; stdcall;
asm
  mov r10, rcx
  mov eax, $74F
  syscall
end;

procedure Syscall_750; stdcall;
asm
  mov r10, rcx
  mov eax, $750
  syscall
end;

procedure Syscall_751; stdcall;
asm
  mov r10, rcx
  mov eax, $751
  syscall
end;

procedure Syscall_752; stdcall;
asm
  mov r10, rcx
  mov eax, $752
  syscall
end;

procedure Syscall_753; stdcall;
asm
  mov r10, rcx
  mov eax, $753
  syscall
end;

procedure Syscall_754; stdcall;
asm
  mov r10, rcx
  mov eax, $754
  syscall
end;

procedure Syscall_755; stdcall;
asm
  mov r10, rcx
  mov eax, $755
  syscall
end;

procedure Syscall_756; stdcall;
asm
  mov r10, rcx
  mov eax, $756
  syscall
end;

procedure Syscall_757; stdcall;
asm
  mov r10, rcx
  mov eax, $757
  syscall
end;

procedure Syscall_758; stdcall;
asm
  mov r10, rcx
  mov eax, $758
  syscall
end;

procedure Syscall_759; stdcall;
asm
  mov r10, rcx
  mov eax, $759
  syscall
end;

procedure Syscall_75A; stdcall;
asm
  mov r10, rcx
  mov eax, $75A
  syscall
end;

procedure Syscall_75B; stdcall;
asm
  mov r10, rcx
  mov eax, $75B
  syscall
end;

procedure Syscall_75C; stdcall;
asm
  mov r10, rcx
  mov eax, $75C
  syscall
end;

procedure Syscall_75D; stdcall;
asm
  mov r10, rcx
  mov eax, $75D
  syscall
end;

procedure Syscall_75E; stdcall;
asm
  mov r10, rcx
  mov eax, $75E
  syscall
end;

procedure Syscall_75F; stdcall;
asm
  mov r10, rcx
  mov eax, $75F
  syscall
end;

procedure Syscall_760; stdcall;
asm
  mov r10, rcx
  mov eax, $760
  syscall
end;

procedure Syscall_761; stdcall;
asm
  mov r10, rcx
  mov eax, $761
  syscall
end;

procedure Syscall_762; stdcall;
asm
  mov r10, rcx
  mov eax, $762
  syscall
end;

procedure Syscall_763; stdcall;
asm
  mov r10, rcx
  mov eax, $763
  syscall
end;

procedure Syscall_764; stdcall;
asm
  mov r10, rcx
  mov eax, $764
  syscall
end;

procedure Syscall_765; stdcall;
asm
  mov r10, rcx
  mov eax, $765
  syscall
end;

procedure Syscall_766; stdcall;
asm
  mov r10, rcx
  mov eax, $766
  syscall
end;

procedure Syscall_767; stdcall;
asm
  mov r10, rcx
  mov eax, $767
  syscall
end;

procedure Syscall_768; stdcall;
asm
  mov r10, rcx
  mov eax, $768
  syscall
end;

procedure Syscall_769; stdcall;
asm
  mov r10, rcx
  mov eax, $769
  syscall
end;

procedure Syscall_76A; stdcall;
asm
  mov r10, rcx
  mov eax, $76A
  syscall
end;

procedure Syscall_76B; stdcall;
asm
  mov r10, rcx
  mov eax, $76B
  syscall
end;

procedure Syscall_76C; stdcall;
asm
  mov r10, rcx
  mov eax, $76C
  syscall
end;

procedure Syscall_76D; stdcall;
asm
  mov r10, rcx
  mov eax, $76D
  syscall
end;

procedure Syscall_76E; stdcall;
asm
  mov r10, rcx
  mov eax, $76E
  syscall
end;

procedure Syscall_76F; stdcall;
asm
  mov r10, rcx
  mov eax, $76F
  syscall
end;

procedure Syscall_770; stdcall;
asm
  mov r10, rcx
  mov eax, $770
  syscall
end;

procedure Syscall_771; stdcall;
asm
  mov r10, rcx
  mov eax, $771
  syscall
end;

procedure Syscall_772; stdcall;
asm
  mov r10, rcx
  mov eax, $772
  syscall
end;

procedure Syscall_773; stdcall;
asm
  mov r10, rcx
  mov eax, $773
  syscall
end;

procedure Syscall_774; stdcall;
asm
  mov r10, rcx
  mov eax, $774
  syscall
end;

procedure Syscall_775; stdcall;
asm
  mov r10, rcx
  mov eax, $775
  syscall
end;

procedure Syscall_776; stdcall;
asm
  mov r10, rcx
  mov eax, $776
  syscall
end;

procedure Syscall_777; stdcall;
asm
  mov r10, rcx
  mov eax, $777
  syscall
end;

procedure Syscall_778; stdcall;
asm
  mov r10, rcx
  mov eax, $778
  syscall
end;

procedure Syscall_779; stdcall;
asm
  mov r10, rcx
  mov eax, $779
  syscall
end;

procedure Syscall_77A; stdcall;
asm
  mov r10, rcx
  mov eax, $77A
  syscall
end;

procedure Syscall_77B; stdcall;
asm
  mov r10, rcx
  mov eax, $77B
  syscall
end;

procedure Syscall_77C; stdcall;
asm
  mov r10, rcx
  mov eax, $77C
  syscall
end;

procedure Syscall_77D; stdcall;
asm
  mov r10, rcx
  mov eax, $77D
  syscall
end;

procedure Syscall_77E; stdcall;
asm
  mov r10, rcx
  mov eax, $77E
  syscall
end;

procedure Syscall_77F; stdcall;
asm
  mov r10, rcx
  mov eax, $77F
  syscall
end;

procedure Syscall_780; stdcall;
asm
  mov r10, rcx
  mov eax, $780
  syscall
end;

procedure Syscall_781; stdcall;
asm
  mov r10, rcx
  mov eax, $781
  syscall
end;

procedure Syscall_782; stdcall;
asm
  mov r10, rcx
  mov eax, $782
  syscall
end;

procedure Syscall_783; stdcall;
asm
  mov r10, rcx
  mov eax, $783
  syscall
end;

procedure Syscall_784; stdcall;
asm
  mov r10, rcx
  mov eax, $784
  syscall
end;

procedure Syscall_785; stdcall;
asm
  mov r10, rcx
  mov eax, $785
  syscall
end;

procedure Syscall_786; stdcall;
asm
  mov r10, rcx
  mov eax, $786
  syscall
end;

procedure Syscall_787; stdcall;
asm
  mov r10, rcx
  mov eax, $787
  syscall
end;

procedure Syscall_788; stdcall;
asm
  mov r10, rcx
  mov eax, $788
  syscall
end;

procedure Syscall_789; stdcall;
asm
  mov r10, rcx
  mov eax, $789
  syscall
end;

procedure Syscall_78A; stdcall;
asm
  mov r10, rcx
  mov eax, $78A
  syscall
end;

procedure Syscall_78B; stdcall;
asm
  mov r10, rcx
  mov eax, $78B
  syscall
end;

procedure Syscall_78C; stdcall;
asm
  mov r10, rcx
  mov eax, $78C
  syscall
end;

procedure Syscall_78D; stdcall;
asm
  mov r10, rcx
  mov eax, $78D
  syscall
end;

procedure Syscall_78E; stdcall;
asm
  mov r10, rcx
  mov eax, $78E
  syscall
end;

procedure Syscall_78F; stdcall;
asm
  mov r10, rcx
  mov eax, $78F
  syscall
end;

procedure Syscall_790; stdcall;
asm
  mov r10, rcx
  mov eax, $790
  syscall
end;

procedure Syscall_791; stdcall;
asm
  mov r10, rcx
  mov eax, $791
  syscall
end;

procedure Syscall_792; stdcall;
asm
  mov r10, rcx
  mov eax, $792
  syscall
end;

procedure Syscall_793; stdcall;
asm
  mov r10, rcx
  mov eax, $793
  syscall
end;

procedure Syscall_794; stdcall;
asm
  mov r10, rcx
  mov eax, $794
  syscall
end;

procedure Syscall_795; stdcall;
asm
  mov r10, rcx
  mov eax, $795
  syscall
end;

procedure Syscall_796; stdcall;
asm
  mov r10, rcx
  mov eax, $796
  syscall
end;

procedure Syscall_797; stdcall;
asm
  mov r10, rcx
  mov eax, $797
  syscall
end;

procedure Syscall_798; stdcall;
asm
  mov r10, rcx
  mov eax, $798
  syscall
end;

procedure Syscall_799; stdcall;
asm
  mov r10, rcx
  mov eax, $799
  syscall
end;

procedure Syscall_79A; stdcall;
asm
  mov r10, rcx
  mov eax, $79A
  syscall
end;

procedure Syscall_79B; stdcall;
asm
  mov r10, rcx
  mov eax, $79B
  syscall
end;

procedure Syscall_79C; stdcall;
asm
  mov r10, rcx
  mov eax, $79C
  syscall
end;

procedure Syscall_79D; stdcall;
asm
  mov r10, rcx
  mov eax, $79D
  syscall
end;

procedure Syscall_79E; stdcall;
asm
  mov r10, rcx
  mov eax, $79E
  syscall
end;

procedure Syscall_79F; stdcall;
asm
  mov r10, rcx
  mov eax, $79F
  syscall
end;

procedure Syscall_7A0; stdcall;
asm
  mov r10, rcx
  mov eax, $7A0
  syscall
end;

procedure Syscall_7A1; stdcall;
asm
  mov r10, rcx
  mov eax, $7A1
  syscall
end;

procedure Syscall_7A2; stdcall;
asm
  mov r10, rcx
  mov eax, $7A2
  syscall
end;

procedure Syscall_7A3; stdcall;
asm
  mov r10, rcx
  mov eax, $7A3
  syscall
end;

procedure Syscall_7A4; stdcall;
asm
  mov r10, rcx
  mov eax, $7A4
  syscall
end;

procedure Syscall_7A5; stdcall;
asm
  mov r10, rcx
  mov eax, $7A5
  syscall
end;

procedure Syscall_7A6; stdcall;
asm
  mov r10, rcx
  mov eax, $7A6
  syscall
end;

procedure Syscall_7A7; stdcall;
asm
  mov r10, rcx
  mov eax, $7A7
  syscall
end;

procedure Syscall_7A8; stdcall;
asm
  mov r10, rcx
  mov eax, $7A8
  syscall
end;

procedure Syscall_7A9; stdcall;
asm
  mov r10, rcx
  mov eax, $7A9
  syscall
end;

procedure Syscall_7AA; stdcall;
asm
  mov r10, rcx
  mov eax, $7AA
  syscall
end;

procedure Syscall_7AB; stdcall;
asm
  mov r10, rcx
  mov eax, $7AB
  syscall
end;

procedure Syscall_7AC; stdcall;
asm
  mov r10, rcx
  mov eax, $7AC
  syscall
end;

procedure Syscall_7AD; stdcall;
asm
  mov r10, rcx
  mov eax, $7AD
  syscall
end;

procedure Syscall_7AE; stdcall;
asm
  mov r10, rcx
  mov eax, $7AE
  syscall
end;

procedure Syscall_7AF; stdcall;
asm
  mov r10, rcx
  mov eax, $7AF
  syscall
end;

procedure Syscall_7B0; stdcall;
asm
  mov r10, rcx
  mov eax, $7B0
  syscall
end;

procedure Syscall_7B1; stdcall;
asm
  mov r10, rcx
  mov eax, $7B1
  syscall
end;

procedure Syscall_7B2; stdcall;
asm
  mov r10, rcx
  mov eax, $7B2
  syscall
end;

procedure Syscall_7B3; stdcall;
asm
  mov r10, rcx
  mov eax, $7B3
  syscall
end;

procedure Syscall_7B4; stdcall;
asm
  mov r10, rcx
  mov eax, $7B4
  syscall
end;

procedure Syscall_7B5; stdcall;
asm
  mov r10, rcx
  mov eax, $7B5
  syscall
end;

procedure Syscall_7B6; stdcall;
asm
  mov r10, rcx
  mov eax, $7B6
  syscall
end;

procedure Syscall_7B7; stdcall;
asm
  mov r10, rcx
  mov eax, $7B7
  syscall
end;

procedure Syscall_7B8; stdcall;
asm
  mov r10, rcx
  mov eax, $7B8
  syscall
end;

procedure Syscall_7B9; stdcall;
asm
  mov r10, rcx
  mov eax, $7B9
  syscall
end;

procedure Syscall_7BA; stdcall;
asm
  mov r10, rcx
  mov eax, $7BA
  syscall
end;

procedure Syscall_7BB; stdcall;
asm
  mov r10, rcx
  mov eax, $7BB
  syscall
end;

procedure Syscall_7BC; stdcall;
asm
  mov r10, rcx
  mov eax, $7BC
  syscall
end;

procedure Syscall_7BD; stdcall;
asm
  mov r10, rcx
  mov eax, $7BD
  syscall
end;

procedure Syscall_7BE; stdcall;
asm
  mov r10, rcx
  mov eax, $7BE
  syscall
end;

procedure Syscall_7BF; stdcall;
asm
  mov r10, rcx
  mov eax, $7BF
  syscall
end;

procedure Syscall_7C0; stdcall;
asm
  mov r10, rcx
  mov eax, $7C0
  syscall
end;

procedure Syscall_7C1; stdcall;
asm
  mov r10, rcx
  mov eax, $7C1
  syscall
end;

procedure Syscall_7C2; stdcall;
asm
  mov r10, rcx
  mov eax, $7C2
  syscall
end;

procedure Syscall_7C3; stdcall;
asm
  mov r10, rcx
  mov eax, $7C3
  syscall
end;

procedure Syscall_7C4; stdcall;
asm
  mov r10, rcx
  mov eax, $7C4
  syscall
end;

procedure Syscall_7C5; stdcall;
asm
  mov r10, rcx
  mov eax, $7C5
  syscall
end;

procedure Syscall_7C6; stdcall;
asm
  mov r10, rcx
  mov eax, $7C6
  syscall
end;

procedure Syscall_7C7; stdcall;
asm
  mov r10, rcx
  mov eax, $7C7
  syscall
end;

procedure Syscall_7C8; stdcall;
asm
  mov r10, rcx
  mov eax, $7C8
  syscall
end;

procedure Syscall_7C9; stdcall;
asm
  mov r10, rcx
  mov eax, $7C9
  syscall
end;

procedure Syscall_7CA; stdcall;
asm
  mov r10, rcx
  mov eax, $7CA
  syscall
end;

procedure Syscall_7CB; stdcall;
asm
  mov r10, rcx
  mov eax, $7CB
  syscall
end;

procedure Syscall_7CC; stdcall;
asm
  mov r10, rcx
  mov eax, $7CC
  syscall
end;

procedure Syscall_7CD; stdcall;
asm
  mov r10, rcx
  mov eax, $7CD
  syscall
end;

procedure Syscall_7CE; stdcall;
asm
  mov r10, rcx
  mov eax, $7CE
  syscall
end;

procedure Syscall_7CF; stdcall;
asm
  mov r10, rcx
  mov eax, $7CF
  syscall
end;

procedure Syscall_7D0; stdcall;
asm
  mov r10, rcx
  mov eax, $7D0
  syscall
end;

procedure Syscall_7D1; stdcall;
asm
  mov r10, rcx
  mov eax, $7D1
  syscall
end;

procedure Syscall_7D2; stdcall;
asm
  mov r10, rcx
  mov eax, $7D2
  syscall
end;

procedure Syscall_7D3; stdcall;
asm
  mov r10, rcx
  mov eax, $7D3
  syscall
end;

procedure Syscall_7D4; stdcall;
asm
  mov r10, rcx
  mov eax, $7D4
  syscall
end;

procedure Syscall_7D5; stdcall;
asm
  mov r10, rcx
  mov eax, $7D5
  syscall
end;

procedure Syscall_7D6; stdcall;
asm
  mov r10, rcx
  mov eax, $7D6
  syscall
end;

procedure Syscall_7D7; stdcall;
asm
  mov r10, rcx
  mov eax, $7D7
  syscall
end;

procedure Syscall_7D8; stdcall;
asm
  mov r10, rcx
  mov eax, $7D8
  syscall
end;

procedure Syscall_7D9; stdcall;
asm
  mov r10, rcx
  mov eax, $7D9
  syscall
end;

procedure Syscall_7DA; stdcall;
asm
  mov r10, rcx
  mov eax, $7DA
  syscall
end;

procedure Syscall_7DB; stdcall;
asm
  mov r10, rcx
  mov eax, $7DB
  syscall
end;

procedure Syscall_7DC; stdcall;
asm
  mov r10, rcx
  mov eax, $7DC
  syscall
end;

procedure Syscall_7DD; stdcall;
asm
  mov r10, rcx
  mov eax, $7DD
  syscall
end;

procedure Syscall_7DE; stdcall;
asm
  mov r10, rcx
  mov eax, $7DE
  syscall
end;

procedure Syscall_7DF; stdcall;
asm
  mov r10, rcx
  mov eax, $7DF
  syscall
end;

procedure Syscall_7E0; stdcall;
asm
  mov r10, rcx
  mov eax, $7E0
  syscall
end;

procedure Syscall_7E1; stdcall;
asm
  mov r10, rcx
  mov eax, $7E1
  syscall
end;

procedure Syscall_7E2; stdcall;
asm
  mov r10, rcx
  mov eax, $7E2
  syscall
end;

procedure Syscall_7E3; stdcall;
asm
  mov r10, rcx
  mov eax, $7E3
  syscall
end;

procedure Syscall_7E4; stdcall;
asm
  mov r10, rcx
  mov eax, $7E4
  syscall
end;

procedure Syscall_7E5; stdcall;
asm
  mov r10, rcx
  mov eax, $7E5
  syscall
end;

procedure Syscall_7E6; stdcall;
asm
  mov r10, rcx
  mov eax, $7E6
  syscall
end;

procedure Syscall_7E7; stdcall;
asm
  mov r10, rcx
  mov eax, $7E7
  syscall
end;

procedure Syscall_7E8; stdcall;
asm
  mov r10, rcx
  mov eax, $7E8
  syscall
end;

procedure Syscall_7E9; stdcall;
asm
  mov r10, rcx
  mov eax, $7E9
  syscall
end;

procedure Syscall_7EA; stdcall;
asm
  mov r10, rcx
  mov eax, $7EA
  syscall
end;

procedure Syscall_7EB; stdcall;
asm
  mov r10, rcx
  mov eax, $7EB
  syscall
end;

procedure Syscall_7EC; stdcall;
asm
  mov r10, rcx
  mov eax, $7EC
  syscall
end;

procedure Syscall_7ED; stdcall;
asm
  mov r10, rcx
  mov eax, $7ED
  syscall
end;

procedure Syscall_7EE; stdcall;
asm
  mov r10, rcx
  mov eax, $7EE
  syscall
end;

procedure Syscall_7EF; stdcall;
asm
  mov r10, rcx
  mov eax, $7EF
  syscall
end;

procedure Syscall_7F0; stdcall;
asm
  mov r10, rcx
  mov eax, $7F0
  syscall
end;

procedure Syscall_7F1; stdcall;
asm
  mov r10, rcx
  mov eax, $7F1
  syscall
end;

procedure Syscall_7F2; stdcall;
asm
  mov r10, rcx
  mov eax, $7F2
  syscall
end;

procedure Syscall_7F3; stdcall;
asm
  mov r10, rcx
  mov eax, $7F3
  syscall
end;

procedure Syscall_7F4; stdcall;
asm
  mov r10, rcx
  mov eax, $7F4
  syscall
end;

procedure Syscall_7F5; stdcall;
asm
  mov r10, rcx
  mov eax, $7F5
  syscall
end;

procedure Syscall_7F6; stdcall;
asm
  mov r10, rcx
  mov eax, $7F6
  syscall
end;

procedure Syscall_7F7; stdcall;
asm
  mov r10, rcx
  mov eax, $7F7
  syscall
end;

procedure Syscall_7F8; stdcall;
asm
  mov r10, rcx
  mov eax, $7F8
  syscall
end;

procedure Syscall_7F9; stdcall;
asm
  mov r10, rcx
  mov eax, $7F9
  syscall
end;

procedure Syscall_7FA; stdcall;
asm
  mov r10, rcx
  mov eax, $7FA
  syscall
end;

procedure Syscall_7FB; stdcall;
asm
  mov r10, rcx
  mov eax, $7FB
  syscall
end;

procedure Syscall_7FC; stdcall;
asm
  mov r10, rcx
  mov eax, $7FC
  syscall
end;

procedure Syscall_7FD; stdcall;
asm
  mov r10, rcx
  mov eax, $7FD
  syscall
end;

procedure Syscall_7FE; stdcall;
asm
  mov r10, rcx
  mov eax, $7FE
  syscall
end;

procedure Syscall_7FF; stdcall;
asm
  mov r10, rcx
  mov eax, $7FF
  syscall
end;

procedure Syscall_800; stdcall;
asm
  mov r10, rcx
  mov eax, $800
  syscall
end;

procedure Syscall_801; stdcall;
asm
  mov r10, rcx
  mov eax, $801
  syscall
end;

procedure Syscall_802; stdcall;
asm
  mov r10, rcx
  mov eax, $802
  syscall
end;

procedure Syscall_803; stdcall;
asm
  mov r10, rcx
  mov eax, $803
  syscall
end;

procedure Syscall_804; stdcall;
asm
  mov r10, rcx
  mov eax, $804
  syscall
end;

procedure Syscall_805; stdcall;
asm
  mov r10, rcx
  mov eax, $805
  syscall
end;

procedure Syscall_806; stdcall;
asm
  mov r10, rcx
  mov eax, $806
  syscall
end;

procedure Syscall_807; stdcall;
asm
  mov r10, rcx
  mov eax, $807
  syscall
end;

procedure Syscall_808; stdcall;
asm
  mov r10, rcx
  mov eax, $808
  syscall
end;

procedure Syscall_809; stdcall;
asm
  mov r10, rcx
  mov eax, $809
  syscall
end;

procedure Syscall_80A; stdcall;
asm
  mov r10, rcx
  mov eax, $80A
  syscall
end;

procedure Syscall_80B; stdcall;
asm
  mov r10, rcx
  mov eax, $80B
  syscall
end;

procedure Syscall_80C; stdcall;
asm
  mov r10, rcx
  mov eax, $80C
  syscall
end;

procedure Syscall_80D; stdcall;
asm
  mov r10, rcx
  mov eax, $80D
  syscall
end;

procedure Syscall_80E; stdcall;
asm
  mov r10, rcx
  mov eax, $80E
  syscall
end;

procedure Syscall_80F; stdcall;
asm
  mov r10, rcx
  mov eax, $80F
  syscall
end;

procedure Syscall_810; stdcall;
asm
  mov r10, rcx
  mov eax, $810
  syscall
end;

procedure Syscall_811; stdcall;
asm
  mov r10, rcx
  mov eax, $811
  syscall
end;

procedure Syscall_812; stdcall;
asm
  mov r10, rcx
  mov eax, $812
  syscall
end;

procedure Syscall_813; stdcall;
asm
  mov r10, rcx
  mov eax, $813
  syscall
end;

procedure Syscall_814; stdcall;
asm
  mov r10, rcx
  mov eax, $814
  syscall
end;

procedure Syscall_815; stdcall;
asm
  mov r10, rcx
  mov eax, $815
  syscall
end;

procedure Syscall_816; stdcall;
asm
  mov r10, rcx
  mov eax, $816
  syscall
end;

procedure Syscall_817; stdcall;
asm
  mov r10, rcx
  mov eax, $817
  syscall
end;

procedure Syscall_818; stdcall;
asm
  mov r10, rcx
  mov eax, $818
  syscall
end;

procedure Syscall_819; stdcall;
asm
  mov r10, rcx
  mov eax, $819
  syscall
end;

procedure Syscall_81A; stdcall;
asm
  mov r10, rcx
  mov eax, $81A
  syscall
end;

procedure Syscall_81B; stdcall;
asm
  mov r10, rcx
  mov eax, $81B
  syscall
end;

procedure Syscall_81C; stdcall;
asm
  mov r10, rcx
  mov eax, $81C
  syscall
end;

procedure Syscall_81D; stdcall;
asm
  mov r10, rcx
  mov eax, $81D
  syscall
end;

procedure Syscall_81E; stdcall;
asm
  mov r10, rcx
  mov eax, $81E
  syscall
end;

procedure Syscall_81F; stdcall;
asm
  mov r10, rcx
  mov eax, $81F
  syscall
end;

procedure Syscall_820; stdcall;
asm
  mov r10, rcx
  mov eax, $820
  syscall
end;

procedure Syscall_821; stdcall;
asm
  mov r10, rcx
  mov eax, $821
  syscall
end;

procedure Syscall_822; stdcall;
asm
  mov r10, rcx
  mov eax, $822
  syscall
end;

procedure Syscall_823; stdcall;
asm
  mov r10, rcx
  mov eax, $823
  syscall
end;

procedure Syscall_824; stdcall;
asm
  mov r10, rcx
  mov eax, $824
  syscall
end;

procedure Syscall_825; stdcall;
asm
  mov r10, rcx
  mov eax, $825
  syscall
end;

procedure Syscall_826; stdcall;
asm
  mov r10, rcx
  mov eax, $826
  syscall
end;

procedure Syscall_827; stdcall;
asm
  mov r10, rcx
  mov eax, $827
  syscall
end;

procedure Syscall_828; stdcall;
asm
  mov r10, rcx
  mov eax, $828
  syscall
end;

procedure Syscall_829; stdcall;
asm
  mov r10, rcx
  mov eax, $829
  syscall
end;

procedure Syscall_82A; stdcall;
asm
  mov r10, rcx
  mov eax, $82A
  syscall
end;

procedure Syscall_82B; stdcall;
asm
  mov r10, rcx
  mov eax, $82B
  syscall
end;

procedure Syscall_82C; stdcall;
asm
  mov r10, rcx
  mov eax, $82C
  syscall
end;

procedure Syscall_82D; stdcall;
asm
  mov r10, rcx
  mov eax, $82D
  syscall
end;

procedure Syscall_82E; stdcall;
asm
  mov r10, rcx
  mov eax, $82E
  syscall
end;

procedure Syscall_82F; stdcall;
asm
  mov r10, rcx
  mov eax, $82F
  syscall
end;

procedure Syscall_830; stdcall;
asm
  mov r10, rcx
  mov eax, $830
  syscall
end;

procedure Syscall_831; stdcall;
asm
  mov r10, rcx
  mov eax, $831
  syscall
end;

procedure Syscall_832; stdcall;
asm
  mov r10, rcx
  mov eax, $832
  syscall
end;

procedure Syscall_833; stdcall;
asm
  mov r10, rcx
  mov eax, $833
  syscall
end;

procedure Syscall_834; stdcall;
asm
  mov r10, rcx
  mov eax, $834
  syscall
end;

procedure Syscall_835; stdcall;
asm
  mov r10, rcx
  mov eax, $835
  syscall
end;

procedure Syscall_836; stdcall;
asm
  mov r10, rcx
  mov eax, $836
  syscall
end;

procedure Syscall_837; stdcall;
asm
  mov r10, rcx
  mov eax, $837
  syscall
end;

procedure Syscall_838; stdcall;
asm
  mov r10, rcx
  mov eax, $838
  syscall
end;

procedure Syscall_839; stdcall;
asm
  mov r10, rcx
  mov eax, $839
  syscall
end;

procedure Syscall_83A; stdcall;
asm
  mov r10, rcx
  mov eax, $83A
  syscall
end;

procedure Syscall_83B; stdcall;
asm
  mov r10, rcx
  mov eax, $83B
  syscall
end;

procedure Syscall_83C; stdcall;
asm
  mov r10, rcx
  mov eax, $83C
  syscall
end;

procedure Syscall_83D; stdcall;
asm
  mov r10, rcx
  mov eax, $83D
  syscall
end;

procedure Syscall_83E; stdcall;
asm
  mov r10, rcx
  mov eax, $83E
  syscall
end;

procedure Syscall_83F; stdcall;
asm
  mov r10, rcx
  mov eax, $83F
  syscall
end;

procedure Syscall_840; stdcall;
asm
  mov r10, rcx
  mov eax, $840
  syscall
end;

procedure Syscall_841; stdcall;
asm
  mov r10, rcx
  mov eax, $841
  syscall
end;

procedure Syscall_842; stdcall;
asm
  mov r10, rcx
  mov eax, $842
  syscall
end;

procedure Syscall_843; stdcall;
asm
  mov r10, rcx
  mov eax, $843
  syscall
end;

procedure Syscall_844; stdcall;
asm
  mov r10, rcx
  mov eax, $844
  syscall
end;

procedure Syscall_845; stdcall;
asm
  mov r10, rcx
  mov eax, $845
  syscall
end;

procedure Syscall_846; stdcall;
asm
  mov r10, rcx
  mov eax, $846
  syscall
end;

procedure Syscall_847; stdcall;
asm
  mov r10, rcx
  mov eax, $847
  syscall
end;

procedure Syscall_848; stdcall;
asm
  mov r10, rcx
  mov eax, $848
  syscall
end;

procedure Syscall_849; stdcall;
asm
  mov r10, rcx
  mov eax, $849
  syscall
end;

procedure Syscall_84A; stdcall;
asm
  mov r10, rcx
  mov eax, $84A
  syscall
end;

procedure Syscall_84B; stdcall;
asm
  mov r10, rcx
  mov eax, $84B
  syscall
end;

procedure Syscall_84C; stdcall;
asm
  mov r10, rcx
  mov eax, $84C
  syscall
end;

procedure Syscall_84D; stdcall;
asm
  mov r10, rcx
  mov eax, $84D
  syscall
end;

procedure Syscall_84E; stdcall;
asm
  mov r10, rcx
  mov eax, $84E
  syscall
end;

procedure Syscall_84F; stdcall;
asm
  mov r10, rcx
  mov eax, $84F
  syscall
end;

procedure Syscall_850; stdcall;
asm
  mov r10, rcx
  mov eax, $850
  syscall
end;

procedure Syscall_851; stdcall;
asm
  mov r10, rcx
  mov eax, $851
  syscall
end;

procedure Syscall_852; stdcall;
asm
  mov r10, rcx
  mov eax, $852
  syscall
end;

procedure Syscall_853; stdcall;
asm
  mov r10, rcx
  mov eax, $853
  syscall
end;

procedure Syscall_854; stdcall;
asm
  mov r10, rcx
  mov eax, $854
  syscall
end;

procedure Syscall_855; stdcall;
asm
  mov r10, rcx
  mov eax, $855
  syscall
end;

procedure Syscall_856; stdcall;
asm
  mov r10, rcx
  mov eax, $856
  syscall
end;

procedure Syscall_857; stdcall;
asm
  mov r10, rcx
  mov eax, $857
  syscall
end;

procedure Syscall_858; stdcall;
asm
  mov r10, rcx
  mov eax, $858
  syscall
end;

procedure Syscall_859; stdcall;
asm
  mov r10, rcx
  mov eax, $859
  syscall
end;

procedure Syscall_85A; stdcall;
asm
  mov r10, rcx
  mov eax, $85A
  syscall
end;

procedure Syscall_85B; stdcall;
asm
  mov r10, rcx
  mov eax, $85B
  syscall
end;

procedure Syscall_85C; stdcall;
asm
  mov r10, rcx
  mov eax, $85C
  syscall
end;

procedure Syscall_85D; stdcall;
asm
  mov r10, rcx
  mov eax, $85D
  syscall
end;

procedure Syscall_85E; stdcall;
asm
  mov r10, rcx
  mov eax, $85E
  syscall
end;

procedure Syscall_85F; stdcall;
asm
  mov r10, rcx
  mov eax, $85F
  syscall
end;

procedure Syscall_860; stdcall;
asm
  mov r10, rcx
  mov eax, $860
  syscall
end;

procedure Syscall_861; stdcall;
asm
  mov r10, rcx
  mov eax, $861
  syscall
end;

procedure Syscall_862; stdcall;
asm
  mov r10, rcx
  mov eax, $862
  syscall
end;

procedure Syscall_863; stdcall;
asm
  mov r10, rcx
  mov eax, $863
  syscall
end;

procedure Syscall_864; stdcall;
asm
  mov r10, rcx
  mov eax, $864
  syscall
end;

procedure Syscall_865; stdcall;
asm
  mov r10, rcx
  mov eax, $865
  syscall
end;

procedure Syscall_866; stdcall;
asm
  mov r10, rcx
  mov eax, $866
  syscall
end;

procedure Syscall_867; stdcall;
asm
  mov r10, rcx
  mov eax, $867
  syscall
end;

procedure Syscall_868; stdcall;
asm
  mov r10, rcx
  mov eax, $868
  syscall
end;

procedure Syscall_869; stdcall;
asm
  mov r10, rcx
  mov eax, $869
  syscall
end;

procedure Syscall_86A; stdcall;
asm
  mov r10, rcx
  mov eax, $86A
  syscall
end;

procedure Syscall_86B; stdcall;
asm
  mov r10, rcx
  mov eax, $86B
  syscall
end;

procedure Syscall_86C; stdcall;
asm
  mov r10, rcx
  mov eax, $86C
  syscall
end;

procedure Syscall_86D; stdcall;
asm
  mov r10, rcx
  mov eax, $86D
  syscall
end;

procedure Syscall_86E; stdcall;
asm
  mov r10, rcx
  mov eax, $86E
  syscall
end;

procedure Syscall_86F; stdcall;
asm
  mov r10, rcx
  mov eax, $86F
  syscall
end;

procedure Syscall_870; stdcall;
asm
  mov r10, rcx
  mov eax, $870
  syscall
end;

procedure Syscall_871; stdcall;
asm
  mov r10, rcx
  mov eax, $871
  syscall
end;

procedure Syscall_872; stdcall;
asm
  mov r10, rcx
  mov eax, $872
  syscall
end;

procedure Syscall_873; stdcall;
asm
  mov r10, rcx
  mov eax, $873
  syscall
end;

procedure Syscall_874; stdcall;
asm
  mov r10, rcx
  mov eax, $874
  syscall
end;

procedure Syscall_875; stdcall;
asm
  mov r10, rcx
  mov eax, $875
  syscall
end;

procedure Syscall_876; stdcall;
asm
  mov r10, rcx
  mov eax, $876
  syscall
end;

procedure Syscall_877; stdcall;
asm
  mov r10, rcx
  mov eax, $877
  syscall
end;

procedure Syscall_878; stdcall;
asm
  mov r10, rcx
  mov eax, $878
  syscall
end;

procedure Syscall_879; stdcall;
asm
  mov r10, rcx
  mov eax, $879
  syscall
end;

procedure Syscall_87A; stdcall;
asm
  mov r10, rcx
  mov eax, $87A
  syscall
end;

procedure Syscall_87B; stdcall;
asm
  mov r10, rcx
  mov eax, $87B
  syscall
end;

procedure Syscall_87C; stdcall;
asm
  mov r10, rcx
  mov eax, $87C
  syscall
end;

procedure Syscall_87D; stdcall;
asm
  mov r10, rcx
  mov eax, $87D
  syscall
end;

procedure Syscall_87E; stdcall;
asm
  mov r10, rcx
  mov eax, $87E
  syscall
end;

procedure Syscall_87F; stdcall;
asm
  mov r10, rcx
  mov eax, $87F
  syscall
end;

procedure Syscall_880; stdcall;
asm
  mov r10, rcx
  mov eax, $880
  syscall
end;

procedure Syscall_881; stdcall;
asm
  mov r10, rcx
  mov eax, $881
  syscall
end;

procedure Syscall_882; stdcall;
asm
  mov r10, rcx
  mov eax, $882
  syscall
end;

procedure Syscall_883; stdcall;
asm
  mov r10, rcx
  mov eax, $883
  syscall
end;

procedure Syscall_884; stdcall;
asm
  mov r10, rcx
  mov eax, $884
  syscall
end;

procedure Syscall_885; stdcall;
asm
  mov r10, rcx
  mov eax, $885
  syscall
end;

procedure Syscall_886; stdcall;
asm
  mov r10, rcx
  mov eax, $886
  syscall
end;

procedure Syscall_887; stdcall;
asm
  mov r10, rcx
  mov eax, $887
  syscall
end;

procedure Syscall_888; stdcall;
asm
  mov r10, rcx
  mov eax, $888
  syscall
end;

procedure Syscall_889; stdcall;
asm
  mov r10, rcx
  mov eax, $889
  syscall
end;

procedure Syscall_88A; stdcall;
asm
  mov r10, rcx
  mov eax, $88A
  syscall
end;

procedure Syscall_88B; stdcall;
asm
  mov r10, rcx
  mov eax, $88B
  syscall
end;

procedure Syscall_88C; stdcall;
asm
  mov r10, rcx
  mov eax, $88C
  syscall
end;

procedure Syscall_88D; stdcall;
asm
  mov r10, rcx
  mov eax, $88D
  syscall
end;

procedure Syscall_88E; stdcall;
asm
  mov r10, rcx
  mov eax, $88E
  syscall
end;

procedure Syscall_88F; stdcall;
asm
  mov r10, rcx
  mov eax, $88F
  syscall
end;

procedure Syscall_890; stdcall;
asm
  mov r10, rcx
  mov eax, $890
  syscall
end;

procedure Syscall_891; stdcall;
asm
  mov r10, rcx
  mov eax, $891
  syscall
end;

procedure Syscall_892; stdcall;
asm
  mov r10, rcx
  mov eax, $892
  syscall
end;

procedure Syscall_893; stdcall;
asm
  mov r10, rcx
  mov eax, $893
  syscall
end;

procedure Syscall_894; stdcall;
asm
  mov r10, rcx
  mov eax, $894
  syscall
end;

procedure Syscall_895; stdcall;
asm
  mov r10, rcx
  mov eax, $895
  syscall
end;

procedure Syscall_896; stdcall;
asm
  mov r10, rcx
  mov eax, $896
  syscall
end;

procedure Syscall_897; stdcall;
asm
  mov r10, rcx
  mov eax, $897
  syscall
end;

procedure Syscall_898; stdcall;
asm
  mov r10, rcx
  mov eax, $898
  syscall
end;

procedure Syscall_899; stdcall;
asm
  mov r10, rcx
  mov eax, $899
  syscall
end;

procedure Syscall_89A; stdcall;
asm
  mov r10, rcx
  mov eax, $89A
  syscall
end;

procedure Syscall_89B; stdcall;
asm
  mov r10, rcx
  mov eax, $89B
  syscall
end;

procedure Syscall_89C; stdcall;
asm
  mov r10, rcx
  mov eax, $89C
  syscall
end;

procedure Syscall_89D; stdcall;
asm
  mov r10, rcx
  mov eax, $89D
  syscall
end;

procedure Syscall_89E; stdcall;
asm
  mov r10, rcx
  mov eax, $89E
  syscall
end;

procedure Syscall_89F; stdcall;
asm
  mov r10, rcx
  mov eax, $89F
  syscall
end;

procedure Syscall_8A0; stdcall;
asm
  mov r10, rcx
  mov eax, $8A0
  syscall
end;

procedure Syscall_8A1; stdcall;
asm
  mov r10, rcx
  mov eax, $8A1
  syscall
end;

procedure Syscall_8A2; stdcall;
asm
  mov r10, rcx
  mov eax, $8A2
  syscall
end;

procedure Syscall_8A3; stdcall;
asm
  mov r10, rcx
  mov eax, $8A3
  syscall
end;

procedure Syscall_8A4; stdcall;
asm
  mov r10, rcx
  mov eax, $8A4
  syscall
end;

procedure Syscall_8A5; stdcall;
asm
  mov r10, rcx
  mov eax, $8A5
  syscall
end;

procedure Syscall_8A6; stdcall;
asm
  mov r10, rcx
  mov eax, $8A6
  syscall
end;

procedure Syscall_8A7; stdcall;
asm
  mov r10, rcx
  mov eax, $8A7
  syscall
end;

procedure Syscall_8A8; stdcall;
asm
  mov r10, rcx
  mov eax, $8A8
  syscall
end;

procedure Syscall_8A9; stdcall;
asm
  mov r10, rcx
  mov eax, $8A9
  syscall
end;

procedure Syscall_8AA; stdcall;
asm
  mov r10, rcx
  mov eax, $8AA
  syscall
end;

procedure Syscall_8AB; stdcall;
asm
  mov r10, rcx
  mov eax, $8AB
  syscall
end;

procedure Syscall_8AC; stdcall;
asm
  mov r10, rcx
  mov eax, $8AC
  syscall
end;

procedure Syscall_8AD; stdcall;
asm
  mov r10, rcx
  mov eax, $8AD
  syscall
end;

procedure Syscall_8AE; stdcall;
asm
  mov r10, rcx
  mov eax, $8AE
  syscall
end;

procedure Syscall_8AF; stdcall;
asm
  mov r10, rcx
  mov eax, $8AF
  syscall
end;

procedure Syscall_8B0; stdcall;
asm
  mov r10, rcx
  mov eax, $8B0
  syscall
end;

procedure Syscall_8B1; stdcall;
asm
  mov r10, rcx
  mov eax, $8B1
  syscall
end;

procedure Syscall_8B2; stdcall;
asm
  mov r10, rcx
  mov eax, $8B2
  syscall
end;

procedure Syscall_8B3; stdcall;
asm
  mov r10, rcx
  mov eax, $8B3
  syscall
end;

procedure Syscall_8B4; stdcall;
asm
  mov r10, rcx
  mov eax, $8B4
  syscall
end;

procedure Syscall_8B5; stdcall;
asm
  mov r10, rcx
  mov eax, $8B5
  syscall
end;

procedure Syscall_8B6; stdcall;
asm
  mov r10, rcx
  mov eax, $8B6
  syscall
end;

procedure Syscall_8B7; stdcall;
asm
  mov r10, rcx
  mov eax, $8B7
  syscall
end;

procedure Syscall_8B8; stdcall;
asm
  mov r10, rcx
  mov eax, $8B8
  syscall
end;

procedure Syscall_8B9; stdcall;
asm
  mov r10, rcx
  mov eax, $8B9
  syscall
end;

procedure Syscall_8BA; stdcall;
asm
  mov r10, rcx
  mov eax, $8BA
  syscall
end;

procedure Syscall_8BB; stdcall;
asm
  mov r10, rcx
  mov eax, $8BB
  syscall
end;

procedure Syscall_8BC; stdcall;
asm
  mov r10, rcx
  mov eax, $8BC
  syscall
end;

procedure Syscall_8BD; stdcall;
asm
  mov r10, rcx
  mov eax, $8BD
  syscall
end;

procedure Syscall_8BE; stdcall;
asm
  mov r10, rcx
  mov eax, $8BE
  syscall
end;

procedure Syscall_8BF; stdcall;
asm
  mov r10, rcx
  mov eax, $8BF
  syscall
end;

procedure Syscall_8C0; stdcall;
asm
  mov r10, rcx
  mov eax, $8C0
  syscall
end;

procedure Syscall_8C1; stdcall;
asm
  mov r10, rcx
  mov eax, $8C1
  syscall
end;

procedure Syscall_8C2; stdcall;
asm
  mov r10, rcx
  mov eax, $8C2
  syscall
end;

procedure Syscall_8C3; stdcall;
asm
  mov r10, rcx
  mov eax, $8C3
  syscall
end;

procedure Syscall_8C4; stdcall;
asm
  mov r10, rcx
  mov eax, $8C4
  syscall
end;

procedure Syscall_8C5; stdcall;
asm
  mov r10, rcx
  mov eax, $8C5
  syscall
end;

procedure Syscall_8C6; stdcall;
asm
  mov r10, rcx
  mov eax, $8C6
  syscall
end;

procedure Syscall_8C7; stdcall;
asm
  mov r10, rcx
  mov eax, $8C7
  syscall
end;

procedure Syscall_8C8; stdcall;
asm
  mov r10, rcx
  mov eax, $8C8
  syscall
end;

procedure Syscall_8C9; stdcall;
asm
  mov r10, rcx
  mov eax, $8C9
  syscall
end;

procedure Syscall_8CA; stdcall;
asm
  mov r10, rcx
  mov eax, $8CA
  syscall
end;

procedure Syscall_8CB; stdcall;
asm
  mov r10, rcx
  mov eax, $8CB
  syscall
end;

procedure Syscall_8CC; stdcall;
asm
  mov r10, rcx
  mov eax, $8CC
  syscall
end;

procedure Syscall_8CD; stdcall;
asm
  mov r10, rcx
  mov eax, $8CD
  syscall
end;

procedure Syscall_8CE; stdcall;
asm
  mov r10, rcx
  mov eax, $8CE
  syscall
end;

procedure Syscall_8CF; stdcall;
asm
  mov r10, rcx
  mov eax, $8CF
  syscall
end;

procedure Syscall_8D0; stdcall;
asm
  mov r10, rcx
  mov eax, $8D0
  syscall
end;

procedure Syscall_8D1; stdcall;
asm
  mov r10, rcx
  mov eax, $8D1
  syscall
end;

procedure Syscall_8D2; stdcall;
asm
  mov r10, rcx
  mov eax, $8D2
  syscall
end;

procedure Syscall_8D3; stdcall;
asm
  mov r10, rcx
  mov eax, $8D3
  syscall
end;

procedure Syscall_8D4; stdcall;
asm
  mov r10, rcx
  mov eax, $8D4
  syscall
end;

procedure Syscall_8D5; stdcall;
asm
  mov r10, rcx
  mov eax, $8D5
  syscall
end;

procedure Syscall_8D6; stdcall;
asm
  mov r10, rcx
  mov eax, $8D6
  syscall
end;

procedure Syscall_8D7; stdcall;
asm
  mov r10, rcx
  mov eax, $8D7
  syscall
end;

procedure Syscall_8D8; stdcall;
asm
  mov r10, rcx
  mov eax, $8D8
  syscall
end;

procedure Syscall_8D9; stdcall;
asm
  mov r10, rcx
  mov eax, $8D9
  syscall
end;

procedure Syscall_8DA; stdcall;
asm
  mov r10, rcx
  mov eax, $8DA
  syscall
end;

procedure Syscall_8DB; stdcall;
asm
  mov r10, rcx
  mov eax, $8DB
  syscall
end;

procedure Syscall_8DC; stdcall;
asm
  mov r10, rcx
  mov eax, $8DC
  syscall
end;

procedure Syscall_8DD; stdcall;
asm
  mov r10, rcx
  mov eax, $8DD
  syscall
end;

procedure Syscall_8DE; stdcall;
asm
  mov r10, rcx
  mov eax, $8DE
  syscall
end;

procedure Syscall_8DF; stdcall;
asm
  mov r10, rcx
  mov eax, $8DF
  syscall
end;

procedure Syscall_8E0; stdcall;
asm
  mov r10, rcx
  mov eax, $8E0
  syscall
end;

procedure Syscall_8E1; stdcall;
asm
  mov r10, rcx
  mov eax, $8E1
  syscall
end;

procedure Syscall_8E2; stdcall;
asm
  mov r10, rcx
  mov eax, $8E2
  syscall
end;

procedure Syscall_8E3; stdcall;
asm
  mov r10, rcx
  mov eax, $8E3
  syscall
end;

procedure Syscall_8E4; stdcall;
asm
  mov r10, rcx
  mov eax, $8E4
  syscall
end;

procedure Syscall_8E5; stdcall;
asm
  mov r10, rcx
  mov eax, $8E5
  syscall
end;

procedure Syscall_8E6; stdcall;
asm
  mov r10, rcx
  mov eax, $8E6
  syscall
end;

procedure Syscall_8E7; stdcall;
asm
  mov r10, rcx
  mov eax, $8E7
  syscall
end;

procedure Syscall_8E8; stdcall;
asm
  mov r10, rcx
  mov eax, $8E8
  syscall
end;

procedure Syscall_8E9; stdcall;
asm
  mov r10, rcx
  mov eax, $8E9
  syscall
end;

procedure Syscall_8EA; stdcall;
asm
  mov r10, rcx
  mov eax, $8EA
  syscall
end;

procedure Syscall_8EB; stdcall;
asm
  mov r10, rcx
  mov eax, $8EB
  syscall
end;

procedure Syscall_8EC; stdcall;
asm
  mov r10, rcx
  mov eax, $8EC
  syscall
end;

procedure Syscall_8ED; stdcall;
asm
  mov r10, rcx
  mov eax, $8ED
  syscall
end;

procedure Syscall_8EE; stdcall;
asm
  mov r10, rcx
  mov eax, $8EE
  syscall
end;

procedure Syscall_8EF; stdcall;
asm
  mov r10, rcx
  mov eax, $8EF
  syscall
end;

procedure Syscall_8F0; stdcall;
asm
  mov r10, rcx
  mov eax, $8F0
  syscall
end;

procedure Syscall_8F1; stdcall;
asm
  mov r10, rcx
  mov eax, $8F1
  syscall
end;

procedure Syscall_8F2; stdcall;
asm
  mov r10, rcx
  mov eax, $8F2
  syscall
end;

procedure Syscall_8F3; stdcall;
asm
  mov r10, rcx
  mov eax, $8F3
  syscall
end;

procedure Syscall_8F4; stdcall;
asm
  mov r10, rcx
  mov eax, $8F4
  syscall
end;

procedure Syscall_8F5; stdcall;
asm
  mov r10, rcx
  mov eax, $8F5
  syscall
end;

procedure Syscall_8F6; stdcall;
asm
  mov r10, rcx
  mov eax, $8F6
  syscall
end;

procedure Syscall_8F7; stdcall;
asm
  mov r10, rcx
  mov eax, $8F7
  syscall
end;

procedure Syscall_8F8; stdcall;
asm
  mov r10, rcx
  mov eax, $8F8
  syscall
end;

procedure Syscall_8F9; stdcall;
asm
  mov r10, rcx
  mov eax, $8F9
  syscall
end;

procedure Syscall_8FA; stdcall;
asm
  mov r10, rcx
  mov eax, $8FA
  syscall
end;

procedure Syscall_8FB; stdcall;
asm
  mov r10, rcx
  mov eax, $8FB
  syscall
end;

procedure Syscall_8FC; stdcall;
asm
  mov r10, rcx
  mov eax, $8FC
  syscall
end;

procedure Syscall_8FD; stdcall;
asm
  mov r10, rcx
  mov eax, $8FD
  syscall
end;

procedure Syscall_8FE; stdcall;
asm
  mov r10, rcx
  mov eax, $8FE
  syscall
end;

procedure Syscall_8FF; stdcall;
asm
  mov r10, rcx
  mov eax, $8FF
  syscall
end;

procedure Syscall_900; stdcall;
asm
  mov r10, rcx
  mov eax, $900
  syscall
end;

procedure Syscall_901; stdcall;
asm
  mov r10, rcx
  mov eax, $901
  syscall
end;

procedure Syscall_902; stdcall;
asm
  mov r10, rcx
  mov eax, $902
  syscall
end;

procedure Syscall_903; stdcall;
asm
  mov r10, rcx
  mov eax, $903
  syscall
end;

procedure Syscall_904; stdcall;
asm
  mov r10, rcx
  mov eax, $904
  syscall
end;

procedure Syscall_905; stdcall;
asm
  mov r10, rcx
  mov eax, $905
  syscall
end;

procedure Syscall_906; stdcall;
asm
  mov r10, rcx
  mov eax, $906
  syscall
end;

procedure Syscall_907; stdcall;
asm
  mov r10, rcx
  mov eax, $907
  syscall
end;

procedure Syscall_908; stdcall;
asm
  mov r10, rcx
  mov eax, $908
  syscall
end;

procedure Syscall_909; stdcall;
asm
  mov r10, rcx
  mov eax, $909
  syscall
end;

procedure Syscall_90A; stdcall;
asm
  mov r10, rcx
  mov eax, $90A
  syscall
end;

procedure Syscall_90B; stdcall;
asm
  mov r10, rcx
  mov eax, $90B
  syscall
end;

procedure Syscall_90C; stdcall;
asm
  mov r10, rcx
  mov eax, $90C
  syscall
end;

procedure Syscall_90D; stdcall;
asm
  mov r10, rcx
  mov eax, $90D
  syscall
end;

procedure Syscall_90E; stdcall;
asm
  mov r10, rcx
  mov eax, $90E
  syscall
end;

procedure Syscall_90F; stdcall;
asm
  mov r10, rcx
  mov eax, $90F
  syscall
end;

procedure Syscall_910; stdcall;
asm
  mov r10, rcx
  mov eax, $910
  syscall
end;

procedure Syscall_911; stdcall;
asm
  mov r10, rcx
  mov eax, $911
  syscall
end;

procedure Syscall_912; stdcall;
asm
  mov r10, rcx
  mov eax, $912
  syscall
end;

procedure Syscall_913; stdcall;
asm
  mov r10, rcx
  mov eax, $913
  syscall
end;

procedure Syscall_914; stdcall;
asm
  mov r10, rcx
  mov eax, $914
  syscall
end;

procedure Syscall_915; stdcall;
asm
  mov r10, rcx
  mov eax, $915
  syscall
end;

procedure Syscall_916; stdcall;
asm
  mov r10, rcx
  mov eax, $916
  syscall
end;

procedure Syscall_917; stdcall;
asm
  mov r10, rcx
  mov eax, $917
  syscall
end;

procedure Syscall_918; stdcall;
asm
  mov r10, rcx
  mov eax, $918
  syscall
end;

procedure Syscall_919; stdcall;
asm
  mov r10, rcx
  mov eax, $919
  syscall
end;

procedure Syscall_91A; stdcall;
asm
  mov r10, rcx
  mov eax, $91A
  syscall
end;

procedure Syscall_91B; stdcall;
asm
  mov r10, rcx
  mov eax, $91B
  syscall
end;

procedure Syscall_91C; stdcall;
asm
  mov r10, rcx
  mov eax, $91C
  syscall
end;

procedure Syscall_91D; stdcall;
asm
  mov r10, rcx
  mov eax, $91D
  syscall
end;

procedure Syscall_91E; stdcall;
asm
  mov r10, rcx
  mov eax, $91E
  syscall
end;

procedure Syscall_91F; stdcall;
asm
  mov r10, rcx
  mov eax, $91F
  syscall
end;

procedure Syscall_920; stdcall;
asm
  mov r10, rcx
  mov eax, $920
  syscall
end;

procedure Syscall_921; stdcall;
asm
  mov r10, rcx
  mov eax, $921
  syscall
end;

procedure Syscall_922; stdcall;
asm
  mov r10, rcx
  mov eax, $922
  syscall
end;

procedure Syscall_923; stdcall;
asm
  mov r10, rcx
  mov eax, $923
  syscall
end;

procedure Syscall_924; stdcall;
asm
  mov r10, rcx
  mov eax, $924
  syscall
end;

procedure Syscall_925; stdcall;
asm
  mov r10, rcx
  mov eax, $925
  syscall
end;

procedure Syscall_926; stdcall;
asm
  mov r10, rcx
  mov eax, $926
  syscall
end;

procedure Syscall_927; stdcall;
asm
  mov r10, rcx
  mov eax, $927
  syscall
end;

procedure Syscall_928; stdcall;
asm
  mov r10, rcx
  mov eax, $928
  syscall
end;

procedure Syscall_929; stdcall;
asm
  mov r10, rcx
  mov eax, $929
  syscall
end;

procedure Syscall_92A; stdcall;
asm
  mov r10, rcx
  mov eax, $92A
  syscall
end;

procedure Syscall_92B; stdcall;
asm
  mov r10, rcx
  mov eax, $92B
  syscall
end;

procedure Syscall_92C; stdcall;
asm
  mov r10, rcx
  mov eax, $92C
  syscall
end;

procedure Syscall_92D; stdcall;
asm
  mov r10, rcx
  mov eax, $92D
  syscall
end;

procedure Syscall_92E; stdcall;
asm
  mov r10, rcx
  mov eax, $92E
  syscall
end;

procedure Syscall_92F; stdcall;
asm
  mov r10, rcx
  mov eax, $92F
  syscall
end;

procedure Syscall_930; stdcall;
asm
  mov r10, rcx
  mov eax, $930
  syscall
end;

procedure Syscall_931; stdcall;
asm
  mov r10, rcx
  mov eax, $931
  syscall
end;

procedure Syscall_932; stdcall;
asm
  mov r10, rcx
  mov eax, $932
  syscall
end;

procedure Syscall_933; stdcall;
asm
  mov r10, rcx
  mov eax, $933
  syscall
end;

procedure Syscall_934; stdcall;
asm
  mov r10, rcx
  mov eax, $934
  syscall
end;

procedure Syscall_935; stdcall;
asm
  mov r10, rcx
  mov eax, $935
  syscall
end;

procedure Syscall_936; stdcall;
asm
  mov r10, rcx
  mov eax, $936
  syscall
end;

procedure Syscall_937; stdcall;
asm
  mov r10, rcx
  mov eax, $937
  syscall
end;

procedure Syscall_938; stdcall;
asm
  mov r10, rcx
  mov eax, $938
  syscall
end;

procedure Syscall_939; stdcall;
asm
  mov r10, rcx
  mov eax, $939
  syscall
end;

procedure Syscall_93A; stdcall;
asm
  mov r10, rcx
  mov eax, $93A
  syscall
end;

procedure Syscall_93B; stdcall;
asm
  mov r10, rcx
  mov eax, $93B
  syscall
end;

procedure Syscall_93C; stdcall;
asm
  mov r10, rcx
  mov eax, $93C
  syscall
end;

procedure Syscall_93D; stdcall;
asm
  mov r10, rcx
  mov eax, $93D
  syscall
end;

procedure Syscall_93E; stdcall;
asm
  mov r10, rcx
  mov eax, $93E
  syscall
end;

procedure Syscall_93F; stdcall;
asm
  mov r10, rcx
  mov eax, $93F
  syscall
end;

procedure Syscall_940; stdcall;
asm
  mov r10, rcx
  mov eax, $940
  syscall
end;

procedure Syscall_941; stdcall;
asm
  mov r10, rcx
  mov eax, $941
  syscall
end;

procedure Syscall_942; stdcall;
asm
  mov r10, rcx
  mov eax, $942
  syscall
end;

procedure Syscall_943; stdcall;
asm
  mov r10, rcx
  mov eax, $943
  syscall
end;

procedure Syscall_944; stdcall;
asm
  mov r10, rcx
  mov eax, $944
  syscall
end;

procedure Syscall_945; stdcall;
asm
  mov r10, rcx
  mov eax, $945
  syscall
end;

procedure Syscall_946; stdcall;
asm
  mov r10, rcx
  mov eax, $946
  syscall
end;

procedure Syscall_947; stdcall;
asm
  mov r10, rcx
  mov eax, $947
  syscall
end;

procedure Syscall_948; stdcall;
asm
  mov r10, rcx
  mov eax, $948
  syscall
end;

procedure Syscall_949; stdcall;
asm
  mov r10, rcx
  mov eax, $949
  syscall
end;

procedure Syscall_94A; stdcall;
asm
  mov r10, rcx
  mov eax, $94A
  syscall
end;

procedure Syscall_94B; stdcall;
asm
  mov r10, rcx
  mov eax, $94B
  syscall
end;

procedure Syscall_94C; stdcall;
asm
  mov r10, rcx
  mov eax, $94C
  syscall
end;

procedure Syscall_94D; stdcall;
asm
  mov r10, rcx
  mov eax, $94D
  syscall
end;

procedure Syscall_94E; stdcall;
asm
  mov r10, rcx
  mov eax, $94E
  syscall
end;

procedure Syscall_94F; stdcall;
asm
  mov r10, rcx
  mov eax, $94F
  syscall
end;

procedure Syscall_950; stdcall;
asm
  mov r10, rcx
  mov eax, $950
  syscall
end;

procedure Syscall_951; stdcall;
asm
  mov r10, rcx
  mov eax, $951
  syscall
end;

procedure Syscall_952; stdcall;
asm
  mov r10, rcx
  mov eax, $952
  syscall
end;

procedure Syscall_953; stdcall;
asm
  mov r10, rcx
  mov eax, $953
  syscall
end;

procedure Syscall_954; stdcall;
asm
  mov r10, rcx
  mov eax, $954
  syscall
end;

procedure Syscall_955; stdcall;
asm
  mov r10, rcx
  mov eax, $955
  syscall
end;

procedure Syscall_956; stdcall;
asm
  mov r10, rcx
  mov eax, $956
  syscall
end;

procedure Syscall_957; stdcall;
asm
  mov r10, rcx
  mov eax, $957
  syscall
end;

procedure Syscall_958; stdcall;
asm
  mov r10, rcx
  mov eax, $958
  syscall
end;

procedure Syscall_959; stdcall;
asm
  mov r10, rcx
  mov eax, $959
  syscall
end;

procedure Syscall_95A; stdcall;
asm
  mov r10, rcx
  mov eax, $95A
  syscall
end;

procedure Syscall_95B; stdcall;
asm
  mov r10, rcx
  mov eax, $95B
  syscall
end;

procedure Syscall_95C; stdcall;
asm
  mov r10, rcx
  mov eax, $95C
  syscall
end;

procedure Syscall_95D; stdcall;
asm
  mov r10, rcx
  mov eax, $95D
  syscall
end;

procedure Syscall_95E; stdcall;
asm
  mov r10, rcx
  mov eax, $95E
  syscall
end;

procedure Syscall_95F; stdcall;
asm
  mov r10, rcx
  mov eax, $95F
  syscall
end;

procedure Syscall_960; stdcall;
asm
  mov r10, rcx
  mov eax, $960
  syscall
end;

procedure Syscall_961; stdcall;
asm
  mov r10, rcx
  mov eax, $961
  syscall
end;

procedure Syscall_962; stdcall;
asm
  mov r10, rcx
  mov eax, $962
  syscall
end;

procedure Syscall_963; stdcall;
asm
  mov r10, rcx
  mov eax, $963
  syscall
end;

procedure Syscall_964; stdcall;
asm
  mov r10, rcx
  mov eax, $964
  syscall
end;

procedure Syscall_965; stdcall;
asm
  mov r10, rcx
  mov eax, $965
  syscall
end;

procedure Syscall_966; stdcall;
asm
  mov r10, rcx
  mov eax, $966
  syscall
end;

procedure Syscall_967; stdcall;
asm
  mov r10, rcx
  mov eax, $967
  syscall
end;

procedure Syscall_968; stdcall;
asm
  mov r10, rcx
  mov eax, $968
  syscall
end;

procedure Syscall_969; stdcall;
asm
  mov r10, rcx
  mov eax, $969
  syscall
end;

procedure Syscall_96A; stdcall;
asm
  mov r10, rcx
  mov eax, $96A
  syscall
end;

procedure Syscall_96B; stdcall;
asm
  mov r10, rcx
  mov eax, $96B
  syscall
end;

procedure Syscall_96C; stdcall;
asm
  mov r10, rcx
  mov eax, $96C
  syscall
end;

procedure Syscall_96D; stdcall;
asm
  mov r10, rcx
  mov eax, $96D
  syscall
end;

procedure Syscall_96E; stdcall;
asm
  mov r10, rcx
  mov eax, $96E
  syscall
end;

procedure Syscall_96F; stdcall;
asm
  mov r10, rcx
  mov eax, $96F
  syscall
end;

procedure Syscall_970; stdcall;
asm
  mov r10, rcx
  mov eax, $970
  syscall
end;

procedure Syscall_971; stdcall;
asm
  mov r10, rcx
  mov eax, $971
  syscall
end;

procedure Syscall_972; stdcall;
asm
  mov r10, rcx
  mov eax, $972
  syscall
end;

procedure Syscall_973; stdcall;
asm
  mov r10, rcx
  mov eax, $973
  syscall
end;

procedure Syscall_974; stdcall;
asm
  mov r10, rcx
  mov eax, $974
  syscall
end;

procedure Syscall_975; stdcall;
asm
  mov r10, rcx
  mov eax, $975
  syscall
end;

procedure Syscall_976; stdcall;
asm
  mov r10, rcx
  mov eax, $976
  syscall
end;

procedure Syscall_977; stdcall;
asm
  mov r10, rcx
  mov eax, $977
  syscall
end;

procedure Syscall_978; stdcall;
asm
  mov r10, rcx
  mov eax, $978
  syscall
end;

procedure Syscall_979; stdcall;
asm
  mov r10, rcx
  mov eax, $979
  syscall
end;

procedure Syscall_97A; stdcall;
asm
  mov r10, rcx
  mov eax, $97A
  syscall
end;

procedure Syscall_97B; stdcall;
asm
  mov r10, rcx
  mov eax, $97B
  syscall
end;

procedure Syscall_97C; stdcall;
asm
  mov r10, rcx
  mov eax, $97C
  syscall
end;

procedure Syscall_97D; stdcall;
asm
  mov r10, rcx
  mov eax, $97D
  syscall
end;

procedure Syscall_97E; stdcall;
asm
  mov r10, rcx
  mov eax, $97E
  syscall
end;

procedure Syscall_97F; stdcall;
asm
  mov r10, rcx
  mov eax, $97F
  syscall
end;

procedure Syscall_980; stdcall;
asm
  mov r10, rcx
  mov eax, $980
  syscall
end;

procedure Syscall_981; stdcall;
asm
  mov r10, rcx
  mov eax, $981
  syscall
end;

procedure Syscall_982; stdcall;
asm
  mov r10, rcx
  mov eax, $982
  syscall
end;

procedure Syscall_983; stdcall;
asm
  mov r10, rcx
  mov eax, $983
  syscall
end;

procedure Syscall_984; stdcall;
asm
  mov r10, rcx
  mov eax, $984
  syscall
end;

procedure Syscall_985; stdcall;
asm
  mov r10, rcx
  mov eax, $985
  syscall
end;

procedure Syscall_986; stdcall;
asm
  mov r10, rcx
  mov eax, $986
  syscall
end;

procedure Syscall_987; stdcall;
asm
  mov r10, rcx
  mov eax, $987
  syscall
end;

procedure Syscall_988; stdcall;
asm
  mov r10, rcx
  mov eax, $988
  syscall
end;

procedure Syscall_989; stdcall;
asm
  mov r10, rcx
  mov eax, $989
  syscall
end;

procedure Syscall_98A; stdcall;
asm
  mov r10, rcx
  mov eax, $98A
  syscall
end;

procedure Syscall_98B; stdcall;
asm
  mov r10, rcx
  mov eax, $98B
  syscall
end;

procedure Syscall_98C; stdcall;
asm
  mov r10, rcx
  mov eax, $98C
  syscall
end;

procedure Syscall_98D; stdcall;
asm
  mov r10, rcx
  mov eax, $98D
  syscall
end;

procedure Syscall_98E; stdcall;
asm
  mov r10, rcx
  mov eax, $98E
  syscall
end;

procedure Syscall_98F; stdcall;
asm
  mov r10, rcx
  mov eax, $98F
  syscall
end;

procedure Syscall_990; stdcall;
asm
  mov r10, rcx
  mov eax, $990
  syscall
end;

procedure Syscall_991; stdcall;
asm
  mov r10, rcx
  mov eax, $991
  syscall
end;

procedure Syscall_992; stdcall;
asm
  mov r10, rcx
  mov eax, $992
  syscall
end;

procedure Syscall_993; stdcall;
asm
  mov r10, rcx
  mov eax, $993
  syscall
end;

procedure Syscall_994; stdcall;
asm
  mov r10, rcx
  mov eax, $994
  syscall
end;

procedure Syscall_995; stdcall;
asm
  mov r10, rcx
  mov eax, $995
  syscall
end;

procedure Syscall_996; stdcall;
asm
  mov r10, rcx
  mov eax, $996
  syscall
end;

procedure Syscall_997; stdcall;
asm
  mov r10, rcx
  mov eax, $997
  syscall
end;

procedure Syscall_998; stdcall;
asm
  mov r10, rcx
  mov eax, $998
  syscall
end;

procedure Syscall_999; stdcall;
asm
  mov r10, rcx
  mov eax, $999
  syscall
end;

procedure Syscall_99A; stdcall;
asm
  mov r10, rcx
  mov eax, $99A
  syscall
end;

procedure Syscall_99B; stdcall;
asm
  mov r10, rcx
  mov eax, $99B
  syscall
end;

procedure Syscall_99C; stdcall;
asm
  mov r10, rcx
  mov eax, $99C
  syscall
end;

procedure Syscall_99D; stdcall;
asm
  mov r10, rcx
  mov eax, $99D
  syscall
end;

procedure Syscall_99E; stdcall;
asm
  mov r10, rcx
  mov eax, $99E
  syscall
end;

procedure Syscall_99F; stdcall;
asm
  mov r10, rcx
  mov eax, $99F
  syscall
end;

procedure Syscall_9A0; stdcall;
asm
  mov r10, rcx
  mov eax, $9A0
  syscall
end;

procedure Syscall_9A1; stdcall;
asm
  mov r10, rcx
  mov eax, $9A1
  syscall
end;

procedure Syscall_9A2; stdcall;
asm
  mov r10, rcx
  mov eax, $9A2
  syscall
end;

procedure Syscall_9A3; stdcall;
asm
  mov r10, rcx
  mov eax, $9A3
  syscall
end;

procedure Syscall_9A4; stdcall;
asm
  mov r10, rcx
  mov eax, $9A4
  syscall
end;

procedure Syscall_9A5; stdcall;
asm
  mov r10, rcx
  mov eax, $9A5
  syscall
end;

procedure Syscall_9A6; stdcall;
asm
  mov r10, rcx
  mov eax, $9A6
  syscall
end;

procedure Syscall_9A7; stdcall;
asm
  mov r10, rcx
  mov eax, $9A7
  syscall
end;

procedure Syscall_9A8; stdcall;
asm
  mov r10, rcx
  mov eax, $9A8
  syscall
end;

procedure Syscall_9A9; stdcall;
asm
  mov r10, rcx
  mov eax, $9A9
  syscall
end;

procedure Syscall_9AA; stdcall;
asm
  mov r10, rcx
  mov eax, $9AA
  syscall
end;

procedure Syscall_9AB; stdcall;
asm
  mov r10, rcx
  mov eax, $9AB
  syscall
end;

procedure Syscall_9AC; stdcall;
asm
  mov r10, rcx
  mov eax, $9AC
  syscall
end;

procedure Syscall_9AD; stdcall;
asm
  mov r10, rcx
  mov eax, $9AD
  syscall
end;

procedure Syscall_9AE; stdcall;
asm
  mov r10, rcx
  mov eax, $9AE
  syscall
end;

procedure Syscall_9AF; stdcall;
asm
  mov r10, rcx
  mov eax, $9AF
  syscall
end;

procedure Syscall_9B0; stdcall;
asm
  mov r10, rcx
  mov eax, $9B0
  syscall
end;

procedure Syscall_9B1; stdcall;
asm
  mov r10, rcx
  mov eax, $9B1
  syscall
end;

procedure Syscall_9B2; stdcall;
asm
  mov r10, rcx
  mov eax, $9B2
  syscall
end;

procedure Syscall_9B3; stdcall;
asm
  mov r10, rcx
  mov eax, $9B3
  syscall
end;

procedure Syscall_9B4; stdcall;
asm
  mov r10, rcx
  mov eax, $9B4
  syscall
end;

procedure Syscall_9B5; stdcall;
asm
  mov r10, rcx
  mov eax, $9B5
  syscall
end;

procedure Syscall_9B6; stdcall;
asm
  mov r10, rcx
  mov eax, $9B6
  syscall
end;

procedure Syscall_9B7; stdcall;
asm
  mov r10, rcx
  mov eax, $9B7
  syscall
end;

procedure Syscall_9B8; stdcall;
asm
  mov r10, rcx
  mov eax, $9B8
  syscall
end;

procedure Syscall_9B9; stdcall;
asm
  mov r10, rcx
  mov eax, $9B9
  syscall
end;

procedure Syscall_9BA; stdcall;
asm
  mov r10, rcx
  mov eax, $9BA
  syscall
end;

procedure Syscall_9BB; stdcall;
asm
  mov r10, rcx
  mov eax, $9BB
  syscall
end;

procedure Syscall_9BC; stdcall;
asm
  mov r10, rcx
  mov eax, $9BC
  syscall
end;

procedure Syscall_9BD; stdcall;
asm
  mov r10, rcx
  mov eax, $9BD
  syscall
end;

procedure Syscall_9BE; stdcall;
asm
  mov r10, rcx
  mov eax, $9BE
  syscall
end;

procedure Syscall_9BF; stdcall;
asm
  mov r10, rcx
  mov eax, $9BF
  syscall
end;

procedure Syscall_9C0; stdcall;
asm
  mov r10, rcx
  mov eax, $9C0
  syscall
end;

procedure Syscall_9C1; stdcall;
asm
  mov r10, rcx
  mov eax, $9C1
  syscall
end;

procedure Syscall_9C2; stdcall;
asm
  mov r10, rcx
  mov eax, $9C2
  syscall
end;

procedure Syscall_9C3; stdcall;
asm
  mov r10, rcx
  mov eax, $9C3
  syscall
end;

procedure Syscall_9C4; stdcall;
asm
  mov r10, rcx
  mov eax, $9C4
  syscall
end;

procedure Syscall_9C5; stdcall;
asm
  mov r10, rcx
  mov eax, $9C5
  syscall
end;

procedure Syscall_9C6; stdcall;
asm
  mov r10, rcx
  mov eax, $9C6
  syscall
end;

procedure Syscall_9C7; stdcall;
asm
  mov r10, rcx
  mov eax, $9C7
  syscall
end;

procedure Syscall_9C8; stdcall;
asm
  mov r10, rcx
  mov eax, $9C8
  syscall
end;

procedure Syscall_9C9; stdcall;
asm
  mov r10, rcx
  mov eax, $9C9
  syscall
end;

procedure Syscall_9CA; stdcall;
asm
  mov r10, rcx
  mov eax, $9CA
  syscall
end;

procedure Syscall_9CB; stdcall;
asm
  mov r10, rcx
  mov eax, $9CB
  syscall
end;

procedure Syscall_9CC; stdcall;
asm
  mov r10, rcx
  mov eax, $9CC
  syscall
end;

procedure Syscall_9CD; stdcall;
asm
  mov r10, rcx
  mov eax, $9CD
  syscall
end;

procedure Syscall_9CE; stdcall;
asm
  mov r10, rcx
  mov eax, $9CE
  syscall
end;

procedure Syscall_9CF; stdcall;
asm
  mov r10, rcx
  mov eax, $9CF
  syscall
end;

procedure Syscall_9D0; stdcall;
asm
  mov r10, rcx
  mov eax, $9D0
  syscall
end;

procedure Syscall_9D1; stdcall;
asm
  mov r10, rcx
  mov eax, $9D1
  syscall
end;

procedure Syscall_9D2; stdcall;
asm
  mov r10, rcx
  mov eax, $9D2
  syscall
end;

procedure Syscall_9D3; stdcall;
asm
  mov r10, rcx
  mov eax, $9D3
  syscall
end;

procedure Syscall_9D4; stdcall;
asm
  mov r10, rcx
  mov eax, $9D4
  syscall
end;

procedure Syscall_9D5; stdcall;
asm
  mov r10, rcx
  mov eax, $9D5
  syscall
end;

procedure Syscall_9D6; stdcall;
asm
  mov r10, rcx
  mov eax, $9D6
  syscall
end;

procedure Syscall_9D7; stdcall;
asm
  mov r10, rcx
  mov eax, $9D7
  syscall
end;

procedure Syscall_9D8; stdcall;
asm
  mov r10, rcx
  mov eax, $9D8
  syscall
end;

procedure Syscall_9D9; stdcall;
asm
  mov r10, rcx
  mov eax, $9D9
  syscall
end;

procedure Syscall_9DA; stdcall;
asm
  mov r10, rcx
  mov eax, $9DA
  syscall
end;

procedure Syscall_9DB; stdcall;
asm
  mov r10, rcx
  mov eax, $9DB
  syscall
end;

procedure Syscall_9DC; stdcall;
asm
  mov r10, rcx
  mov eax, $9DC
  syscall
end;

procedure Syscall_9DD; stdcall;
asm
  mov r10, rcx
  mov eax, $9DD
  syscall
end;

procedure Syscall_9DE; stdcall;
asm
  mov r10, rcx
  mov eax, $9DE
  syscall
end;

procedure Syscall_9DF; stdcall;
asm
  mov r10, rcx
  mov eax, $9DF
  syscall
end;

procedure Syscall_9E0; stdcall;
asm
  mov r10, rcx
  mov eax, $9E0
  syscall
end;

procedure Syscall_9E1; stdcall;
asm
  mov r10, rcx
  mov eax, $9E1
  syscall
end;

procedure Syscall_9E2; stdcall;
asm
  mov r10, rcx
  mov eax, $9E2
  syscall
end;

procedure Syscall_9E3; stdcall;
asm
  mov r10, rcx
  mov eax, $9E3
  syscall
end;

procedure Syscall_9E4; stdcall;
asm
  mov r10, rcx
  mov eax, $9E4
  syscall
end;

procedure Syscall_9E5; stdcall;
asm
  mov r10, rcx
  mov eax, $9E5
  syscall
end;

procedure Syscall_9E6; stdcall;
asm
  mov r10, rcx
  mov eax, $9E6
  syscall
end;

procedure Syscall_9E7; stdcall;
asm
  mov r10, rcx
  mov eax, $9E7
  syscall
end;

procedure Syscall_9E8; stdcall;
asm
  mov r10, rcx
  mov eax, $9E8
  syscall
end;

procedure Syscall_9E9; stdcall;
asm
  mov r10, rcx
  mov eax, $9E9
  syscall
end;

procedure Syscall_9EA; stdcall;
asm
  mov r10, rcx
  mov eax, $9EA
  syscall
end;

procedure Syscall_9EB; stdcall;
asm
  mov r10, rcx
  mov eax, $9EB
  syscall
end;

procedure Syscall_9EC; stdcall;
asm
  mov r10, rcx
  mov eax, $9EC
  syscall
end;

procedure Syscall_9ED; stdcall;
asm
  mov r10, rcx
  mov eax, $9ED
  syscall
end;

procedure Syscall_9EE; stdcall;
asm
  mov r10, rcx
  mov eax, $9EE
  syscall
end;

procedure Syscall_9EF; stdcall;
asm
  mov r10, rcx
  mov eax, $9EF
  syscall
end;

procedure Syscall_9F0; stdcall;
asm
  mov r10, rcx
  mov eax, $9F0
  syscall
end;

procedure Syscall_9F1; stdcall;
asm
  mov r10, rcx
  mov eax, $9F1
  syscall
end;

procedure Syscall_9F2; stdcall;
asm
  mov r10, rcx
  mov eax, $9F2
  syscall
end;

procedure Syscall_9F3; stdcall;
asm
  mov r10, rcx
  mov eax, $9F3
  syscall
end;

procedure Syscall_9F4; stdcall;
asm
  mov r10, rcx
  mov eax, $9F4
  syscall
end;

procedure Syscall_9F5; stdcall;
asm
  mov r10, rcx
  mov eax, $9F5
  syscall
end;

procedure Syscall_9F6; stdcall;
asm
  mov r10, rcx
  mov eax, $9F6
  syscall
end;

procedure Syscall_9F7; stdcall;
asm
  mov r10, rcx
  mov eax, $9F7
  syscall
end;

procedure Syscall_9F8; stdcall;
asm
  mov r10, rcx
  mov eax, $9F8
  syscall
end;

procedure Syscall_9F9; stdcall;
asm
  mov r10, rcx
  mov eax, $9F9
  syscall
end;

procedure Syscall_9FA; stdcall;
asm
  mov r10, rcx
  mov eax, $9FA
  syscall
end;

procedure Syscall_9FB; stdcall;
asm
  mov r10, rcx
  mov eax, $9FB
  syscall
end;

procedure Syscall_9FC; stdcall;
asm
  mov r10, rcx
  mov eax, $9FC
  syscall
end;

procedure Syscall_9FD; stdcall;
asm
  mov r10, rcx
  mov eax, $9FD
  syscall
end;

procedure Syscall_9FE; stdcall;
asm
  mov r10, rcx
  mov eax, $9FE
  syscall
end;

procedure Syscall_9FF; stdcall;
asm
  mov r10, rcx
  mov eax, $9FF
  syscall
end;

procedure Syscall_A00; stdcall;
asm
  mov r10, rcx
  mov eax, $A00
  syscall
end;

procedure Syscall_A01; stdcall;
asm
  mov r10, rcx
  mov eax, $A01
  syscall
end;

procedure Syscall_A02; stdcall;
asm
  mov r10, rcx
  mov eax, $A02
  syscall
end;

procedure Syscall_A03; stdcall;
asm
  mov r10, rcx
  mov eax, $A03
  syscall
end;

procedure Syscall_A04; stdcall;
asm
  mov r10, rcx
  mov eax, $A04
  syscall
end;

procedure Syscall_A05; stdcall;
asm
  mov r10, rcx
  mov eax, $A05
  syscall
end;

procedure Syscall_A06; stdcall;
asm
  mov r10, rcx
  mov eax, $A06
  syscall
end;

procedure Syscall_A07; stdcall;
asm
  mov r10, rcx
  mov eax, $A07
  syscall
end;

procedure Syscall_A08; stdcall;
asm
  mov r10, rcx
  mov eax, $A08
  syscall
end;

procedure Syscall_A09; stdcall;
asm
  mov r10, rcx
  mov eax, $A09
  syscall
end;

procedure Syscall_A0A; stdcall;
asm
  mov r10, rcx
  mov eax, $A0A
  syscall
end;

procedure Syscall_A0B; stdcall;
asm
  mov r10, rcx
  mov eax, $A0B
  syscall
end;

procedure Syscall_A0C; stdcall;
asm
  mov r10, rcx
  mov eax, $A0C
  syscall
end;

procedure Syscall_A0D; stdcall;
asm
  mov r10, rcx
  mov eax, $A0D
  syscall
end;

procedure Syscall_A0E; stdcall;
asm
  mov r10, rcx
  mov eax, $A0E
  syscall
end;

procedure Syscall_A0F; stdcall;
asm
  mov r10, rcx
  mov eax, $A0F
  syscall
end;

procedure Syscall_A10; stdcall;
asm
  mov r10, rcx
  mov eax, $A10
  syscall
end;

procedure Syscall_A11; stdcall;
asm
  mov r10, rcx
  mov eax, $A11
  syscall
end;

procedure Syscall_A12; stdcall;
asm
  mov r10, rcx
  mov eax, $A12
  syscall
end;

procedure Syscall_A13; stdcall;
asm
  mov r10, rcx
  mov eax, $A13
  syscall
end;

procedure Syscall_A14; stdcall;
asm
  mov r10, rcx
  mov eax, $A14
  syscall
end;

procedure Syscall_A15; stdcall;
asm
  mov r10, rcx
  mov eax, $A15
  syscall
end;

procedure Syscall_A16; stdcall;
asm
  mov r10, rcx
  mov eax, $A16
  syscall
end;

procedure Syscall_A17; stdcall;
asm
  mov r10, rcx
  mov eax, $A17
  syscall
end;

procedure Syscall_A18; stdcall;
asm
  mov r10, rcx
  mov eax, $A18
  syscall
end;

procedure Syscall_A19; stdcall;
asm
  mov r10, rcx
  mov eax, $A19
  syscall
end;

procedure Syscall_A1A; stdcall;
asm
  mov r10, rcx
  mov eax, $A1A
  syscall
end;

procedure Syscall_A1B; stdcall;
asm
  mov r10, rcx
  mov eax, $A1B
  syscall
end;

procedure Syscall_A1C; stdcall;
asm
  mov r10, rcx
  mov eax, $A1C
  syscall
end;

procedure Syscall_A1D; stdcall;
asm
  mov r10, rcx
  mov eax, $A1D
  syscall
end;

procedure Syscall_A1E; stdcall;
asm
  mov r10, rcx
  mov eax, $A1E
  syscall
end;

procedure Syscall_A1F; stdcall;
asm
  mov r10, rcx
  mov eax, $A1F
  syscall
end;

procedure Syscall_A20; stdcall;
asm
  mov r10, rcx
  mov eax, $A20
  syscall
end;

procedure Syscall_A21; stdcall;
asm
  mov r10, rcx
  mov eax, $A21
  syscall
end;

procedure Syscall_A22; stdcall;
asm
  mov r10, rcx
  mov eax, $A22
  syscall
end;

procedure Syscall_A23; stdcall;
asm
  mov r10, rcx
  mov eax, $A23
  syscall
end;

procedure Syscall_A24; stdcall;
asm
  mov r10, rcx
  mov eax, $A24
  syscall
end;

procedure Syscall_A25; stdcall;
asm
  mov r10, rcx
  mov eax, $A25
  syscall
end;

procedure Syscall_A26; stdcall;
asm
  mov r10, rcx
  mov eax, $A26
  syscall
end;

procedure Syscall_A27; stdcall;
asm
  mov r10, rcx
  mov eax, $A27
  syscall
end;

procedure Syscall_A28; stdcall;
asm
  mov r10, rcx
  mov eax, $A28
  syscall
end;

procedure Syscall_A29; stdcall;
asm
  mov r10, rcx
  mov eax, $A29
  syscall
end;

procedure Syscall_A2A; stdcall;
asm
  mov r10, rcx
  mov eax, $A2A
  syscall
end;

procedure Syscall_A2B; stdcall;
asm
  mov r10, rcx
  mov eax, $A2B
  syscall
end;

procedure Syscall_A2C; stdcall;
asm
  mov r10, rcx
  mov eax, $A2C
  syscall
end;

procedure Syscall_A2D; stdcall;
asm
  mov r10, rcx
  mov eax, $A2D
  syscall
end;

procedure Syscall_A2E; stdcall;
asm
  mov r10, rcx
  mov eax, $A2E
  syscall
end;

procedure Syscall_A2F; stdcall;
asm
  mov r10, rcx
  mov eax, $A2F
  syscall
end;

procedure Syscall_A30; stdcall;
asm
  mov r10, rcx
  mov eax, $A30
  syscall
end;

procedure Syscall_A31; stdcall;
asm
  mov r10, rcx
  mov eax, $A31
  syscall
end;

procedure Syscall_A32; stdcall;
asm
  mov r10, rcx
  mov eax, $A32
  syscall
end;

procedure Syscall_A33; stdcall;
asm
  mov r10, rcx
  mov eax, $A33
  syscall
end;

procedure Syscall_A34; stdcall;
asm
  mov r10, rcx
  mov eax, $A34
  syscall
end;

procedure Syscall_A35; stdcall;
asm
  mov r10, rcx
  mov eax, $A35
  syscall
end;

procedure Syscall_A36; stdcall;
asm
  mov r10, rcx
  mov eax, $A36
  syscall
end;

procedure Syscall_A37; stdcall;
asm
  mov r10, rcx
  mov eax, $A37
  syscall
end;

procedure Syscall_A38; stdcall;
asm
  mov r10, rcx
  mov eax, $A38
  syscall
end;

procedure Syscall_A39; stdcall;
asm
  mov r10, rcx
  mov eax, $A39
  syscall
end;

procedure Syscall_A3A; stdcall;
asm
  mov r10, rcx
  mov eax, $A3A
  syscall
end;

procedure Syscall_A3B; stdcall;
asm
  mov r10, rcx
  mov eax, $A3B
  syscall
end;

procedure Syscall_A3C; stdcall;
asm
  mov r10, rcx
  mov eax, $A3C
  syscall
end;

procedure Syscall_A3D; stdcall;
asm
  mov r10, rcx
  mov eax, $A3D
  syscall
end;

procedure Syscall_A3E; stdcall;
asm
  mov r10, rcx
  mov eax, $A3E
  syscall
end;

procedure Syscall_A3F; stdcall;
asm
  mov r10, rcx
  mov eax, $A3F
  syscall
end;

procedure Syscall_A40; stdcall;
asm
  mov r10, rcx
  mov eax, $A40
  syscall
end;

procedure Syscall_A41; stdcall;
asm
  mov r10, rcx
  mov eax, $A41
  syscall
end;

procedure Syscall_A42; stdcall;
asm
  mov r10, rcx
  mov eax, $A42
  syscall
end;

procedure Syscall_A43; stdcall;
asm
  mov r10, rcx
  mov eax, $A43
  syscall
end;

procedure Syscall_A44; stdcall;
asm
  mov r10, rcx
  mov eax, $A44
  syscall
end;

procedure Syscall_A45; stdcall;
asm
  mov r10, rcx
  mov eax, $A45
  syscall
end;

procedure Syscall_A46; stdcall;
asm
  mov r10, rcx
  mov eax, $A46
  syscall
end;

procedure Syscall_A47; stdcall;
asm
  mov r10, rcx
  mov eax, $A47
  syscall
end;

procedure Syscall_A48; stdcall;
asm
  mov r10, rcx
  mov eax, $A48
  syscall
end;

procedure Syscall_A49; stdcall;
asm
  mov r10, rcx
  mov eax, $A49
  syscall
end;

procedure Syscall_A4A; stdcall;
asm
  mov r10, rcx
  mov eax, $A4A
  syscall
end;

procedure Syscall_A4B; stdcall;
asm
  mov r10, rcx
  mov eax, $A4B
  syscall
end;

procedure Syscall_A4C; stdcall;
asm
  mov r10, rcx
  mov eax, $A4C
  syscall
end;

procedure Syscall_A4D; stdcall;
asm
  mov r10, rcx
  mov eax, $A4D
  syscall
end;

procedure Syscall_A4E; stdcall;
asm
  mov r10, rcx
  mov eax, $A4E
  syscall
end;

procedure Syscall_A4F; stdcall;
asm
  mov r10, rcx
  mov eax, $A4F
  syscall
end;

procedure Syscall_A50; stdcall;
asm
  mov r10, rcx
  mov eax, $A50
  syscall
end;

procedure Syscall_A51; stdcall;
asm
  mov r10, rcx
  mov eax, $A51
  syscall
end;

procedure Syscall_A52; stdcall;
asm
  mov r10, rcx
  mov eax, $A52
  syscall
end;

procedure Syscall_A53; stdcall;
asm
  mov r10, rcx
  mov eax, $A53
  syscall
end;

procedure Syscall_A54; stdcall;
asm
  mov r10, rcx
  mov eax, $A54
  syscall
end;

procedure Syscall_A55; stdcall;
asm
  mov r10, rcx
  mov eax, $A55
  syscall
end;

procedure Syscall_A56; stdcall;
asm
  mov r10, rcx
  mov eax, $A56
  syscall
end;

procedure Syscall_A57; stdcall;
asm
  mov r10, rcx
  mov eax, $A57
  syscall
end;

procedure Syscall_A58; stdcall;
asm
  mov r10, rcx
  mov eax, $A58
  syscall
end;

procedure Syscall_A59; stdcall;
asm
  mov r10, rcx
  mov eax, $A59
  syscall
end;

procedure Syscall_A5A; stdcall;
asm
  mov r10, rcx
  mov eax, $A5A
  syscall
end;

procedure Syscall_A5B; stdcall;
asm
  mov r10, rcx
  mov eax, $A5B
  syscall
end;

procedure Syscall_A5C; stdcall;
asm
  mov r10, rcx
  mov eax, $A5C
  syscall
end;

procedure Syscall_A5D; stdcall;
asm
  mov r10, rcx
  mov eax, $A5D
  syscall
end;

procedure Syscall_A5E; stdcall;
asm
  mov r10, rcx
  mov eax, $A5E
  syscall
end;

procedure Syscall_A5F; stdcall;
asm
  mov r10, rcx
  mov eax, $A5F
  syscall
end;

procedure Syscall_A60; stdcall;
asm
  mov r10, rcx
  mov eax, $A60
  syscall
end;

procedure Syscall_A61; stdcall;
asm
  mov r10, rcx
  mov eax, $A61
  syscall
end;

procedure Syscall_A62; stdcall;
asm
  mov r10, rcx
  mov eax, $A62
  syscall
end;

procedure Syscall_A63; stdcall;
asm
  mov r10, rcx
  mov eax, $A63
  syscall
end;

procedure Syscall_A64; stdcall;
asm
  mov r10, rcx
  mov eax, $A64
  syscall
end;

procedure Syscall_A65; stdcall;
asm
  mov r10, rcx
  mov eax, $A65
  syscall
end;

procedure Syscall_A66; stdcall;
asm
  mov r10, rcx
  mov eax, $A66
  syscall
end;

procedure Syscall_A67; stdcall;
asm
  mov r10, rcx
  mov eax, $A67
  syscall
end;

procedure Syscall_A68; stdcall;
asm
  mov r10, rcx
  mov eax, $A68
  syscall
end;

procedure Syscall_A69; stdcall;
asm
  mov r10, rcx
  mov eax, $A69
  syscall
end;

procedure Syscall_A6A; stdcall;
asm
  mov r10, rcx
  mov eax, $A6A
  syscall
end;

procedure Syscall_A6B; stdcall;
asm
  mov r10, rcx
  mov eax, $A6B
  syscall
end;

procedure Syscall_A6C; stdcall;
asm
  mov r10, rcx
  mov eax, $A6C
  syscall
end;

procedure Syscall_A6D; stdcall;
asm
  mov r10, rcx
  mov eax, $A6D
  syscall
end;

procedure Syscall_A6E; stdcall;
asm
  mov r10, rcx
  mov eax, $A6E
  syscall
end;

procedure Syscall_A6F; stdcall;
asm
  mov r10, rcx
  mov eax, $A6F
  syscall
end;

procedure Syscall_A70; stdcall;
asm
  mov r10, rcx
  mov eax, $A70
  syscall
end;

procedure Syscall_A71; stdcall;
asm
  mov r10, rcx
  mov eax, $A71
  syscall
end;

procedure Syscall_A72; stdcall;
asm
  mov r10, rcx
  mov eax, $A72
  syscall
end;

procedure Syscall_A73; stdcall;
asm
  mov r10, rcx
  mov eax, $A73
  syscall
end;

procedure Syscall_A74; stdcall;
asm
  mov r10, rcx
  mov eax, $A74
  syscall
end;

procedure Syscall_A75; stdcall;
asm
  mov r10, rcx
  mov eax, $A75
  syscall
end;

procedure Syscall_A76; stdcall;
asm
  mov r10, rcx
  mov eax, $A76
  syscall
end;

procedure Syscall_A77; stdcall;
asm
  mov r10, rcx
  mov eax, $A77
  syscall
end;

procedure Syscall_A78; stdcall;
asm
  mov r10, rcx
  mov eax, $A78
  syscall
end;

procedure Syscall_A79; stdcall;
asm
  mov r10, rcx
  mov eax, $A79
  syscall
end;

procedure Syscall_A7A; stdcall;
asm
  mov r10, rcx
  mov eax, $A7A
  syscall
end;

procedure Syscall_A7B; stdcall;
asm
  mov r10, rcx
  mov eax, $A7B
  syscall
end;

procedure Syscall_A7C; stdcall;
asm
  mov r10, rcx
  mov eax, $A7C
  syscall
end;

procedure Syscall_A7D; stdcall;
asm
  mov r10, rcx
  mov eax, $A7D
  syscall
end;

procedure Syscall_A7E; stdcall;
asm
  mov r10, rcx
  mov eax, $A7E
  syscall
end;

procedure Syscall_A7F; stdcall;
asm
  mov r10, rcx
  mov eax, $A7F
  syscall
end;

procedure Syscall_A80; stdcall;
asm
  mov r10, rcx
  mov eax, $A80
  syscall
end;

procedure Syscall_A81; stdcall;
asm
  mov r10, rcx
  mov eax, $A81
  syscall
end;

procedure Syscall_A82; stdcall;
asm
  mov r10, rcx
  mov eax, $A82
  syscall
end;

procedure Syscall_A83; stdcall;
asm
  mov r10, rcx
  mov eax, $A83
  syscall
end;

procedure Syscall_A84; stdcall;
asm
  mov r10, rcx
  mov eax, $A84
  syscall
end;

procedure Syscall_A85; stdcall;
asm
  mov r10, rcx
  mov eax, $A85
  syscall
end;

procedure Syscall_A86; stdcall;
asm
  mov r10, rcx
  mov eax, $A86
  syscall
end;

procedure Syscall_A87; stdcall;
asm
  mov r10, rcx
  mov eax, $A87
  syscall
end;

procedure Syscall_A88; stdcall;
asm
  mov r10, rcx
  mov eax, $A88
  syscall
end;

procedure Syscall_A89; stdcall;
asm
  mov r10, rcx
  mov eax, $A89
  syscall
end;

procedure Syscall_A8A; stdcall;
asm
  mov r10, rcx
  mov eax, $A8A
  syscall
end;

procedure Syscall_A8B; stdcall;
asm
  mov r10, rcx
  mov eax, $A8B
  syscall
end;

procedure Syscall_A8C; stdcall;
asm
  mov r10, rcx
  mov eax, $A8C
  syscall
end;

procedure Syscall_A8D; stdcall;
asm
  mov r10, rcx
  mov eax, $A8D
  syscall
end;

procedure Syscall_A8E; stdcall;
asm
  mov r10, rcx
  mov eax, $A8E
  syscall
end;

procedure Syscall_A8F; stdcall;
asm
  mov r10, rcx
  mov eax, $A8F
  syscall
end;

procedure Syscall_A90; stdcall;
asm
  mov r10, rcx
  mov eax, $A90
  syscall
end;

procedure Syscall_A91; stdcall;
asm
  mov r10, rcx
  mov eax, $A91
  syscall
end;

procedure Syscall_A92; stdcall;
asm
  mov r10, rcx
  mov eax, $A92
  syscall
end;

procedure Syscall_A93; stdcall;
asm
  mov r10, rcx
  mov eax, $A93
  syscall
end;

procedure Syscall_A94; stdcall;
asm
  mov r10, rcx
  mov eax, $A94
  syscall
end;

procedure Syscall_A95; stdcall;
asm
  mov r10, rcx
  mov eax, $A95
  syscall
end;

procedure Syscall_A96; stdcall;
asm
  mov r10, rcx
  mov eax, $A96
  syscall
end;

procedure Syscall_A97; stdcall;
asm
  mov r10, rcx
  mov eax, $A97
  syscall
end;

procedure Syscall_A98; stdcall;
asm
  mov r10, rcx
  mov eax, $A98
  syscall
end;

procedure Syscall_A99; stdcall;
asm
  mov r10, rcx
  mov eax, $A99
  syscall
end;

procedure Syscall_A9A; stdcall;
asm
  mov r10, rcx
  mov eax, $A9A
  syscall
end;

procedure Syscall_A9B; stdcall;
asm
  mov r10, rcx
  mov eax, $A9B
  syscall
end;

procedure Syscall_A9C; stdcall;
asm
  mov r10, rcx
  mov eax, $A9C
  syscall
end;

procedure Syscall_A9D; stdcall;
asm
  mov r10, rcx
  mov eax, $A9D
  syscall
end;

procedure Syscall_A9E; stdcall;
asm
  mov r10, rcx
  mov eax, $A9E
  syscall
end;

procedure Syscall_A9F; stdcall;
asm
  mov r10, rcx
  mov eax, $A9F
  syscall
end;

procedure Syscall_AA0; stdcall;
asm
  mov r10, rcx
  mov eax, $AA0
  syscall
end;

procedure Syscall_AA1; stdcall;
asm
  mov r10, rcx
  mov eax, $AA1
  syscall
end;

procedure Syscall_AA2; stdcall;
asm
  mov r10, rcx
  mov eax, $AA2
  syscall
end;

procedure Syscall_AA3; stdcall;
asm
  mov r10, rcx
  mov eax, $AA3
  syscall
end;

procedure Syscall_AA4; stdcall;
asm
  mov r10, rcx
  mov eax, $AA4
  syscall
end;

procedure Syscall_AA5; stdcall;
asm
  mov r10, rcx
  mov eax, $AA5
  syscall
end;

procedure Syscall_AA6; stdcall;
asm
  mov r10, rcx
  mov eax, $AA6
  syscall
end;

procedure Syscall_AA7; stdcall;
asm
  mov r10, rcx
  mov eax, $AA7
  syscall
end;

procedure Syscall_AA8; stdcall;
asm
  mov r10, rcx
  mov eax, $AA8
  syscall
end;

procedure Syscall_AA9; stdcall;
asm
  mov r10, rcx
  mov eax, $AA9
  syscall
end;

procedure Syscall_AAA; stdcall;
asm
  mov r10, rcx
  mov eax, $AAA
  syscall
end;

procedure Syscall_AAB; stdcall;
asm
  mov r10, rcx
  mov eax, $AAB
  syscall
end;

procedure Syscall_AAC; stdcall;
asm
  mov r10, rcx
  mov eax, $AAC
  syscall
end;

procedure Syscall_AAD; stdcall;
asm
  mov r10, rcx
  mov eax, $AAD
  syscall
end;

procedure Syscall_AAE; stdcall;
asm
  mov r10, rcx
  mov eax, $AAE
  syscall
end;

procedure Syscall_AAF; stdcall;
asm
  mov r10, rcx
  mov eax, $AAF
  syscall
end;

procedure Syscall_AB0; stdcall;
asm
  mov r10, rcx
  mov eax, $AB0
  syscall
end;

procedure Syscall_AB1; stdcall;
asm
  mov r10, rcx
  mov eax, $AB1
  syscall
end;

procedure Syscall_AB2; stdcall;
asm
  mov r10, rcx
  mov eax, $AB2
  syscall
end;

procedure Syscall_AB3; stdcall;
asm
  mov r10, rcx
  mov eax, $AB3
  syscall
end;

procedure Syscall_AB4; stdcall;
asm
  mov r10, rcx
  mov eax, $AB4
  syscall
end;

procedure Syscall_AB5; stdcall;
asm
  mov r10, rcx
  mov eax, $AB5
  syscall
end;

procedure Syscall_AB6; stdcall;
asm
  mov r10, rcx
  mov eax, $AB6
  syscall
end;

procedure Syscall_AB7; stdcall;
asm
  mov r10, rcx
  mov eax, $AB7
  syscall
end;

procedure Syscall_AB8; stdcall;
asm
  mov r10, rcx
  mov eax, $AB8
  syscall
end;

procedure Syscall_AB9; stdcall;
asm
  mov r10, rcx
  mov eax, $AB9
  syscall
end;

procedure Syscall_ABA; stdcall;
asm
  mov r10, rcx
  mov eax, $ABA
  syscall
end;

procedure Syscall_ABB; stdcall;
asm
  mov r10, rcx
  mov eax, $ABB
  syscall
end;

procedure Syscall_ABC; stdcall;
asm
  mov r10, rcx
  mov eax, $ABC
  syscall
end;

procedure Syscall_ABD; stdcall;
asm
  mov r10, rcx
  mov eax, $ABD
  syscall
end;

procedure Syscall_ABE; stdcall;
asm
  mov r10, rcx
  mov eax, $ABE
  syscall
end;

procedure Syscall_ABF; stdcall;
asm
  mov r10, rcx
  mov eax, $ABF
  syscall
end;

procedure Syscall_AC0; stdcall;
asm
  mov r10, rcx
  mov eax, $AC0
  syscall
end;

procedure Syscall_AC1; stdcall;
asm
  mov r10, rcx
  mov eax, $AC1
  syscall
end;

procedure Syscall_AC2; stdcall;
asm
  mov r10, rcx
  mov eax, $AC2
  syscall
end;

procedure Syscall_AC3; stdcall;
asm
  mov r10, rcx
  mov eax, $AC3
  syscall
end;

procedure Syscall_AC4; stdcall;
asm
  mov r10, rcx
  mov eax, $AC4
  syscall
end;

procedure Syscall_AC5; stdcall;
asm
  mov r10, rcx
  mov eax, $AC5
  syscall
end;

procedure Syscall_AC6; stdcall;
asm
  mov r10, rcx
  mov eax, $AC6
  syscall
end;

procedure Syscall_AC7; stdcall;
asm
  mov r10, rcx
  mov eax, $AC7
  syscall
end;

procedure Syscall_AC8; stdcall;
asm
  mov r10, rcx
  mov eax, $AC8
  syscall
end;

procedure Syscall_AC9; stdcall;
asm
  mov r10, rcx
  mov eax, $AC9
  syscall
end;

procedure Syscall_ACA; stdcall;
asm
  mov r10, rcx
  mov eax, $ACA
  syscall
end;

procedure Syscall_ACB; stdcall;
asm
  mov r10, rcx
  mov eax, $ACB
  syscall
end;

procedure Syscall_ACC; stdcall;
asm
  mov r10, rcx
  mov eax, $ACC
  syscall
end;

procedure Syscall_ACD; stdcall;
asm
  mov r10, rcx
  mov eax, $ACD
  syscall
end;

procedure Syscall_ACE; stdcall;
asm
  mov r10, rcx
  mov eax, $ACE
  syscall
end;

procedure Syscall_ACF; stdcall;
asm
  mov r10, rcx
  mov eax, $ACF
  syscall
end;

procedure Syscall_AD0; stdcall;
asm
  mov r10, rcx
  mov eax, $AD0
  syscall
end;

procedure Syscall_AD1; stdcall;
asm
  mov r10, rcx
  mov eax, $AD1
  syscall
end;

procedure Syscall_AD2; stdcall;
asm
  mov r10, rcx
  mov eax, $AD2
  syscall
end;

procedure Syscall_AD3; stdcall;
asm
  mov r10, rcx
  mov eax, $AD3
  syscall
end;

procedure Syscall_AD4; stdcall;
asm
  mov r10, rcx
  mov eax, $AD4
  syscall
end;

procedure Syscall_AD5; stdcall;
asm
  mov r10, rcx
  mov eax, $AD5
  syscall
end;

procedure Syscall_AD6; stdcall;
asm
  mov r10, rcx
  mov eax, $AD6
  syscall
end;

procedure Syscall_AD7; stdcall;
asm
  mov r10, rcx
  mov eax, $AD7
  syscall
end;

procedure Syscall_AD8; stdcall;
asm
  mov r10, rcx
  mov eax, $AD8
  syscall
end;

procedure Syscall_AD9; stdcall;
asm
  mov r10, rcx
  mov eax, $AD9
  syscall
end;

procedure Syscall_ADA; stdcall;
asm
  mov r10, rcx
  mov eax, $ADA
  syscall
end;

procedure Syscall_ADB; stdcall;
asm
  mov r10, rcx
  mov eax, $ADB
  syscall
end;

procedure Syscall_ADC; stdcall;
asm
  mov r10, rcx
  mov eax, $ADC
  syscall
end;

procedure Syscall_ADD; stdcall;
asm
  mov r10, rcx
  mov eax, $ADD
  syscall
end;

procedure Syscall_ADE; stdcall;
asm
  mov r10, rcx
  mov eax, $ADE
  syscall
end;

procedure Syscall_ADF; stdcall;
asm
  mov r10, rcx
  mov eax, $ADF
  syscall
end;

procedure Syscall_AE0; stdcall;
asm
  mov r10, rcx
  mov eax, $AE0
  syscall
end;

procedure Syscall_AE1; stdcall;
asm
  mov r10, rcx
  mov eax, $AE1
  syscall
end;

procedure Syscall_AE2; stdcall;
asm
  mov r10, rcx
  mov eax, $AE2
  syscall
end;

procedure Syscall_AE3; stdcall;
asm
  mov r10, rcx
  mov eax, $AE3
  syscall
end;

procedure Syscall_AE4; stdcall;
asm
  mov r10, rcx
  mov eax, $AE4
  syscall
end;

procedure Syscall_AE5; stdcall;
asm
  mov r10, rcx
  mov eax, $AE5
  syscall
end;

procedure Syscall_AE6; stdcall;
asm
  mov r10, rcx
  mov eax, $AE6
  syscall
end;

procedure Syscall_AE7; stdcall;
asm
  mov r10, rcx
  mov eax, $AE7
  syscall
end;

procedure Syscall_AE8; stdcall;
asm
  mov r10, rcx
  mov eax, $AE8
  syscall
end;

procedure Syscall_AE9; stdcall;
asm
  mov r10, rcx
  mov eax, $AE9
  syscall
end;

procedure Syscall_AEA; stdcall;
asm
  mov r10, rcx
  mov eax, $AEA
  syscall
end;

procedure Syscall_AEB; stdcall;
asm
  mov r10, rcx
  mov eax, $AEB
  syscall
end;

procedure Syscall_AEC; stdcall;
asm
  mov r10, rcx
  mov eax, $AEC
  syscall
end;

procedure Syscall_AED; stdcall;
asm
  mov r10, rcx
  mov eax, $AED
  syscall
end;

procedure Syscall_AEE; stdcall;
asm
  mov r10, rcx
  mov eax, $AEE
  syscall
end;

procedure Syscall_AEF; stdcall;
asm
  mov r10, rcx
  mov eax, $AEF
  syscall
end;

procedure Syscall_AF0; stdcall;
asm
  mov r10, rcx
  mov eax, $AF0
  syscall
end;

procedure Syscall_AF1; stdcall;
asm
  mov r10, rcx
  mov eax, $AF1
  syscall
end;

procedure Syscall_AF2; stdcall;
asm
  mov r10, rcx
  mov eax, $AF2
  syscall
end;

procedure Syscall_AF3; stdcall;
asm
  mov r10, rcx
  mov eax, $AF3
  syscall
end;

procedure Syscall_AF4; stdcall;
asm
  mov r10, rcx
  mov eax, $AF4
  syscall
end;

procedure Syscall_AF5; stdcall;
asm
  mov r10, rcx
  mov eax, $AF5
  syscall
end;

procedure Syscall_AF6; stdcall;
asm
  mov r10, rcx
  mov eax, $AF6
  syscall
end;

procedure Syscall_AF7; stdcall;
asm
  mov r10, rcx
  mov eax, $AF7
  syscall
end;

procedure Syscall_AF8; stdcall;
asm
  mov r10, rcx
  mov eax, $AF8
  syscall
end;

procedure Syscall_AF9; stdcall;
asm
  mov r10, rcx
  mov eax, $AF9
  syscall
end;

procedure Syscall_AFA; stdcall;
asm
  mov r10, rcx
  mov eax, $AFA
  syscall
end;

procedure Syscall_AFB; stdcall;
asm
  mov r10, rcx
  mov eax, $AFB
  syscall
end;

procedure Syscall_AFC; stdcall;
asm
  mov r10, rcx
  mov eax, $AFC
  syscall
end;

procedure Syscall_AFD; stdcall;
asm
  mov r10, rcx
  mov eax, $AFD
  syscall
end;

procedure Syscall_AFE; stdcall;
asm
  mov r10, rcx
  mov eax, $AFE
  syscall
end;

procedure Syscall_AFF; stdcall;
asm
  mov r10, rcx
  mov eax, $AFF
  syscall
end;

procedure Syscall_B00; stdcall;
asm
  mov r10, rcx
  mov eax, $B00
  syscall
end;

procedure Syscall_B01; stdcall;
asm
  mov r10, rcx
  mov eax, $B01
  syscall
end;

procedure Syscall_B02; stdcall;
asm
  mov r10, rcx
  mov eax, $B02
  syscall
end;

procedure Syscall_B03; stdcall;
asm
  mov r10, rcx
  mov eax, $B03
  syscall
end;

procedure Syscall_B04; stdcall;
asm
  mov r10, rcx
  mov eax, $B04
  syscall
end;

procedure Syscall_B05; stdcall;
asm
  mov r10, rcx
  mov eax, $B05
  syscall
end;

procedure Syscall_B06; stdcall;
asm
  mov r10, rcx
  mov eax, $B06
  syscall
end;

procedure Syscall_B07; stdcall;
asm
  mov r10, rcx
  mov eax, $B07
  syscall
end;

procedure Syscall_B08; stdcall;
asm
  mov r10, rcx
  mov eax, $B08
  syscall
end;

procedure Syscall_B09; stdcall;
asm
  mov r10, rcx
  mov eax, $B09
  syscall
end;

procedure Syscall_B0A; stdcall;
asm
  mov r10, rcx
  mov eax, $B0A
  syscall
end;

procedure Syscall_B0B; stdcall;
asm
  mov r10, rcx
  mov eax, $B0B
  syscall
end;

procedure Syscall_B0C; stdcall;
asm
  mov r10, rcx
  mov eax, $B0C
  syscall
end;

procedure Syscall_B0D; stdcall;
asm
  mov r10, rcx
  mov eax, $B0D
  syscall
end;

procedure Syscall_B0E; stdcall;
asm
  mov r10, rcx
  mov eax, $B0E
  syscall
end;

procedure Syscall_B0F; stdcall;
asm
  mov r10, rcx
  mov eax, $B0F
  syscall
end;

procedure Syscall_B10; stdcall;
asm
  mov r10, rcx
  mov eax, $B10
  syscall
end;

procedure Syscall_B11; stdcall;
asm
  mov r10, rcx
  mov eax, $B11
  syscall
end;

procedure Syscall_B12; stdcall;
asm
  mov r10, rcx
  mov eax, $B12
  syscall
end;

procedure Syscall_B13; stdcall;
asm
  mov r10, rcx
  mov eax, $B13
  syscall
end;

procedure Syscall_B14; stdcall;
asm
  mov r10, rcx
  mov eax, $B14
  syscall
end;

procedure Syscall_B15; stdcall;
asm
  mov r10, rcx
  mov eax, $B15
  syscall
end;

procedure Syscall_B16; stdcall;
asm
  mov r10, rcx
  mov eax, $B16
  syscall
end;

procedure Syscall_B17; stdcall;
asm
  mov r10, rcx
  mov eax, $B17
  syscall
end;

procedure Syscall_B18; stdcall;
asm
  mov r10, rcx
  mov eax, $B18
  syscall
end;

procedure Syscall_B19; stdcall;
asm
  mov r10, rcx
  mov eax, $B19
  syscall
end;

procedure Syscall_B1A; stdcall;
asm
  mov r10, rcx
  mov eax, $B1A
  syscall
end;

procedure Syscall_B1B; stdcall;
asm
  mov r10, rcx
  mov eax, $B1B
  syscall
end;

procedure Syscall_B1C; stdcall;
asm
  mov r10, rcx
  mov eax, $B1C
  syscall
end;

procedure Syscall_B1D; stdcall;
asm
  mov r10, rcx
  mov eax, $B1D
  syscall
end;

procedure Syscall_B1E; stdcall;
asm
  mov r10, rcx
  mov eax, $B1E
  syscall
end;

procedure Syscall_B1F; stdcall;
asm
  mov r10, rcx
  mov eax, $B1F
  syscall
end;

procedure Syscall_B20; stdcall;
asm
  mov r10, rcx
  mov eax, $B20
  syscall
end;

procedure Syscall_B21; stdcall;
asm
  mov r10, rcx
  mov eax, $B21
  syscall
end;

procedure Syscall_B22; stdcall;
asm
  mov r10, rcx
  mov eax, $B22
  syscall
end;

procedure Syscall_B23; stdcall;
asm
  mov r10, rcx
  mov eax, $B23
  syscall
end;

procedure Syscall_B24; stdcall;
asm
  mov r10, rcx
  mov eax, $B24
  syscall
end;

procedure Syscall_B25; stdcall;
asm
  mov r10, rcx
  mov eax, $B25
  syscall
end;

procedure Syscall_B26; stdcall;
asm
  mov r10, rcx
  mov eax, $B26
  syscall
end;

procedure Syscall_B27; stdcall;
asm
  mov r10, rcx
  mov eax, $B27
  syscall
end;

procedure Syscall_B28; stdcall;
asm
  mov r10, rcx
  mov eax, $B28
  syscall
end;

procedure Syscall_B29; stdcall;
asm
  mov r10, rcx
  mov eax, $B29
  syscall
end;

procedure Syscall_B2A; stdcall;
asm
  mov r10, rcx
  mov eax, $B2A
  syscall
end;

procedure Syscall_B2B; stdcall;
asm
  mov r10, rcx
  mov eax, $B2B
  syscall
end;

procedure Syscall_B2C; stdcall;
asm
  mov r10, rcx
  mov eax, $B2C
  syscall
end;

procedure Syscall_B2D; stdcall;
asm
  mov r10, rcx
  mov eax, $B2D
  syscall
end;

procedure Syscall_B2E; stdcall;
asm
  mov r10, rcx
  mov eax, $B2E
  syscall
end;

procedure Syscall_B2F; stdcall;
asm
  mov r10, rcx
  mov eax, $B2F
  syscall
end;

procedure Syscall_B30; stdcall;
asm
  mov r10, rcx
  mov eax, $B30
  syscall
end;

procedure Syscall_B31; stdcall;
asm
  mov r10, rcx
  mov eax, $B31
  syscall
end;

procedure Syscall_B32; stdcall;
asm
  mov r10, rcx
  mov eax, $B32
  syscall
end;

procedure Syscall_B33; stdcall;
asm
  mov r10, rcx
  mov eax, $B33
  syscall
end;

procedure Syscall_B34; stdcall;
asm
  mov r10, rcx
  mov eax, $B34
  syscall
end;

procedure Syscall_B35; stdcall;
asm
  mov r10, rcx
  mov eax, $B35
  syscall
end;

procedure Syscall_B36; stdcall;
asm
  mov r10, rcx
  mov eax, $B36
  syscall
end;

procedure Syscall_B37; stdcall;
asm
  mov r10, rcx
  mov eax, $B37
  syscall
end;

procedure Syscall_B38; stdcall;
asm
  mov r10, rcx
  mov eax, $B38
  syscall
end;

procedure Syscall_B39; stdcall;
asm
  mov r10, rcx
  mov eax, $B39
  syscall
end;

procedure Syscall_B3A; stdcall;
asm
  mov r10, rcx
  mov eax, $B3A
  syscall
end;

procedure Syscall_B3B; stdcall;
asm
  mov r10, rcx
  mov eax, $B3B
  syscall
end;

procedure Syscall_B3C; stdcall;
asm
  mov r10, rcx
  mov eax, $B3C
  syscall
end;

procedure Syscall_B3D; stdcall;
asm
  mov r10, rcx
  mov eax, $B3D
  syscall
end;

procedure Syscall_B3E; stdcall;
asm
  mov r10, rcx
  mov eax, $B3E
  syscall
end;

procedure Syscall_B3F; stdcall;
asm
  mov r10, rcx
  mov eax, $B3F
  syscall
end;

procedure Syscall_B40; stdcall;
asm
  mov r10, rcx
  mov eax, $B40
  syscall
end;

procedure Syscall_B41; stdcall;
asm
  mov r10, rcx
  mov eax, $B41
  syscall
end;

procedure Syscall_B42; stdcall;
asm
  mov r10, rcx
  mov eax, $B42
  syscall
end;

procedure Syscall_B43; stdcall;
asm
  mov r10, rcx
  mov eax, $B43
  syscall
end;

procedure Syscall_B44; stdcall;
asm
  mov r10, rcx
  mov eax, $B44
  syscall
end;

procedure Syscall_B45; stdcall;
asm
  mov r10, rcx
  mov eax, $B45
  syscall
end;

procedure Syscall_B46; stdcall;
asm
  mov r10, rcx
  mov eax, $B46
  syscall
end;

procedure Syscall_B47; stdcall;
asm
  mov r10, rcx
  mov eax, $B47
  syscall
end;

procedure Syscall_B48; stdcall;
asm
  mov r10, rcx
  mov eax, $B48
  syscall
end;

procedure Syscall_B49; stdcall;
asm
  mov r10, rcx
  mov eax, $B49
  syscall
end;

procedure Syscall_B4A; stdcall;
asm
  mov r10, rcx
  mov eax, $B4A
  syscall
end;

procedure Syscall_B4B; stdcall;
asm
  mov r10, rcx
  mov eax, $B4B
  syscall
end;

procedure Syscall_B4C; stdcall;
asm
  mov r10, rcx
  mov eax, $B4C
  syscall
end;

procedure Syscall_B4D; stdcall;
asm
  mov r10, rcx
  mov eax, $B4D
  syscall
end;

procedure Syscall_B4E; stdcall;
asm
  mov r10, rcx
  mov eax, $B4E
  syscall
end;

procedure Syscall_B4F; stdcall;
asm
  mov r10, rcx
  mov eax, $B4F
  syscall
end;

procedure Syscall_B50; stdcall;
asm
  mov r10, rcx
  mov eax, $B50
  syscall
end;

procedure Syscall_B51; stdcall;
asm
  mov r10, rcx
  mov eax, $B51
  syscall
end;

procedure Syscall_B52; stdcall;
asm
  mov r10, rcx
  mov eax, $B52
  syscall
end;

procedure Syscall_B53; stdcall;
asm
  mov r10, rcx
  mov eax, $B53
  syscall
end;

procedure Syscall_B54; stdcall;
asm
  mov r10, rcx
  mov eax, $B54
  syscall
end;

procedure Syscall_B55; stdcall;
asm
  mov r10, rcx
  mov eax, $B55
  syscall
end;

procedure Syscall_B56; stdcall;
asm
  mov r10, rcx
  mov eax, $B56
  syscall
end;

procedure Syscall_B57; stdcall;
asm
  mov r10, rcx
  mov eax, $B57
  syscall
end;

procedure Syscall_B58; stdcall;
asm
  mov r10, rcx
  mov eax, $B58
  syscall
end;

procedure Syscall_B59; stdcall;
asm
  mov r10, rcx
  mov eax, $B59
  syscall
end;

procedure Syscall_B5A; stdcall;
asm
  mov r10, rcx
  mov eax, $B5A
  syscall
end;

procedure Syscall_B5B; stdcall;
asm
  mov r10, rcx
  mov eax, $B5B
  syscall
end;

procedure Syscall_B5C; stdcall;
asm
  mov r10, rcx
  mov eax, $B5C
  syscall
end;

procedure Syscall_B5D; stdcall;
asm
  mov r10, rcx
  mov eax, $B5D
  syscall
end;

procedure Syscall_B5E; stdcall;
asm
  mov r10, rcx
  mov eax, $B5E
  syscall
end;

procedure Syscall_B5F; stdcall;
asm
  mov r10, rcx
  mov eax, $B5F
  syscall
end;

procedure Syscall_B60; stdcall;
asm
  mov r10, rcx
  mov eax, $B60
  syscall
end;

procedure Syscall_B61; stdcall;
asm
  mov r10, rcx
  mov eax, $B61
  syscall
end;

procedure Syscall_B62; stdcall;
asm
  mov r10, rcx
  mov eax, $B62
  syscall
end;

procedure Syscall_B63; stdcall;
asm
  mov r10, rcx
  mov eax, $B63
  syscall
end;

procedure Syscall_B64; stdcall;
asm
  mov r10, rcx
  mov eax, $B64
  syscall
end;

procedure Syscall_B65; stdcall;
asm
  mov r10, rcx
  mov eax, $B65
  syscall
end;

procedure Syscall_B66; stdcall;
asm
  mov r10, rcx
  mov eax, $B66
  syscall
end;

procedure Syscall_B67; stdcall;
asm
  mov r10, rcx
  mov eax, $B67
  syscall
end;

procedure Syscall_B68; stdcall;
asm
  mov r10, rcx
  mov eax, $B68
  syscall
end;

procedure Syscall_B69; stdcall;
asm
  mov r10, rcx
  mov eax, $B69
  syscall
end;

procedure Syscall_B6A; stdcall;
asm
  mov r10, rcx
  mov eax, $B6A
  syscall
end;

procedure Syscall_B6B; stdcall;
asm
  mov r10, rcx
  mov eax, $B6B
  syscall
end;

procedure Syscall_B6C; stdcall;
asm
  mov r10, rcx
  mov eax, $B6C
  syscall
end;

procedure Syscall_B6D; stdcall;
asm
  mov r10, rcx
  mov eax, $B6D
  syscall
end;

procedure Syscall_B6E; stdcall;
asm
  mov r10, rcx
  mov eax, $B6E
  syscall
end;

procedure Syscall_B6F; stdcall;
asm
  mov r10, rcx
  mov eax, $B6F
  syscall
end;

procedure Syscall_B70; stdcall;
asm
  mov r10, rcx
  mov eax, $B70
  syscall
end;

procedure Syscall_B71; stdcall;
asm
  mov r10, rcx
  mov eax, $B71
  syscall
end;

procedure Syscall_B72; stdcall;
asm
  mov r10, rcx
  mov eax, $B72
  syscall
end;

procedure Syscall_B73; stdcall;
asm
  mov r10, rcx
  mov eax, $B73
  syscall
end;

procedure Syscall_B74; stdcall;
asm
  mov r10, rcx
  mov eax, $B74
  syscall
end;

procedure Syscall_B75; stdcall;
asm
  mov r10, rcx
  mov eax, $B75
  syscall
end;

procedure Syscall_B76; stdcall;
asm
  mov r10, rcx
  mov eax, $B76
  syscall
end;

procedure Syscall_B77; stdcall;
asm
  mov r10, rcx
  mov eax, $B77
  syscall
end;

procedure Syscall_B78; stdcall;
asm
  mov r10, rcx
  mov eax, $B78
  syscall
end;

procedure Syscall_B79; stdcall;
asm
  mov r10, rcx
  mov eax, $B79
  syscall
end;

procedure Syscall_B7A; stdcall;
asm
  mov r10, rcx
  mov eax, $B7A
  syscall
end;

procedure Syscall_B7B; stdcall;
asm
  mov r10, rcx
  mov eax, $B7B
  syscall
end;

procedure Syscall_B7C; stdcall;
asm
  mov r10, rcx
  mov eax, $B7C
  syscall
end;

procedure Syscall_B7D; stdcall;
asm
  mov r10, rcx
  mov eax, $B7D
  syscall
end;

procedure Syscall_B7E; stdcall;
asm
  mov r10, rcx
  mov eax, $B7E
  syscall
end;

procedure Syscall_B7F; stdcall;
asm
  mov r10, rcx
  mov eax, $B7F
  syscall
end;

procedure Syscall_B80; stdcall;
asm
  mov r10, rcx
  mov eax, $B80
  syscall
end;

procedure Syscall_B81; stdcall;
asm
  mov r10, rcx
  mov eax, $B81
  syscall
end;

procedure Syscall_B82; stdcall;
asm
  mov r10, rcx
  mov eax, $B82
  syscall
end;

procedure Syscall_B83; stdcall;
asm
  mov r10, rcx
  mov eax, $B83
  syscall
end;

procedure Syscall_B84; stdcall;
asm
  mov r10, rcx
  mov eax, $B84
  syscall
end;

procedure Syscall_B85; stdcall;
asm
  mov r10, rcx
  mov eax, $B85
  syscall
end;

procedure Syscall_B86; stdcall;
asm
  mov r10, rcx
  mov eax, $B86
  syscall
end;

procedure Syscall_B87; stdcall;
asm
  mov r10, rcx
  mov eax, $B87
  syscall
end;

procedure Syscall_B88; stdcall;
asm
  mov r10, rcx
  mov eax, $B88
  syscall
end;

procedure Syscall_B89; stdcall;
asm
  mov r10, rcx
  mov eax, $B89
  syscall
end;

procedure Syscall_B8A; stdcall;
asm
  mov r10, rcx
  mov eax, $B8A
  syscall
end;

procedure Syscall_B8B; stdcall;
asm
  mov r10, rcx
  mov eax, $B8B
  syscall
end;

procedure Syscall_B8C; stdcall;
asm
  mov r10, rcx
  mov eax, $B8C
  syscall
end;

procedure Syscall_B8D; stdcall;
asm
  mov r10, rcx
  mov eax, $B8D
  syscall
end;

procedure Syscall_B8E; stdcall;
asm
  mov r10, rcx
  mov eax, $B8E
  syscall
end;

procedure Syscall_B8F; stdcall;
asm
  mov r10, rcx
  mov eax, $B8F
  syscall
end;

procedure Syscall_B90; stdcall;
asm
  mov r10, rcx
  mov eax, $B90
  syscall
end;

procedure Syscall_B91; stdcall;
asm
  mov r10, rcx
  mov eax, $B91
  syscall
end;

procedure Syscall_B92; stdcall;
asm
  mov r10, rcx
  mov eax, $B92
  syscall
end;

procedure Syscall_B93; stdcall;
asm
  mov r10, rcx
  mov eax, $B93
  syscall
end;

procedure Syscall_B94; stdcall;
asm
  mov r10, rcx
  mov eax, $B94
  syscall
end;

procedure Syscall_B95; stdcall;
asm
  mov r10, rcx
  mov eax, $B95
  syscall
end;

procedure Syscall_B96; stdcall;
asm
  mov r10, rcx
  mov eax, $B96
  syscall
end;

procedure Syscall_B97; stdcall;
asm
  mov r10, rcx
  mov eax, $B97
  syscall
end;

procedure Syscall_B98; stdcall;
asm
  mov r10, rcx
  mov eax, $B98
  syscall
end;

procedure Syscall_B99; stdcall;
asm
  mov r10, rcx
  mov eax, $B99
  syscall
end;

procedure Syscall_B9A; stdcall;
asm
  mov r10, rcx
  mov eax, $B9A
  syscall
end;

procedure Syscall_B9B; stdcall;
asm
  mov r10, rcx
  mov eax, $B9B
  syscall
end;

procedure Syscall_B9C; stdcall;
asm
  mov r10, rcx
  mov eax, $B9C
  syscall
end;

procedure Syscall_B9D; stdcall;
asm
  mov r10, rcx
  mov eax, $B9D
  syscall
end;

procedure Syscall_B9E; stdcall;
asm
  mov r10, rcx
  mov eax, $B9E
  syscall
end;

procedure Syscall_B9F; stdcall;
asm
  mov r10, rcx
  mov eax, $B9F
  syscall
end;

procedure Syscall_BA0; stdcall;
asm
  mov r10, rcx
  mov eax, $BA0
  syscall
end;

procedure Syscall_BA1; stdcall;
asm
  mov r10, rcx
  mov eax, $BA1
  syscall
end;

procedure Syscall_BA2; stdcall;
asm
  mov r10, rcx
  mov eax, $BA2
  syscall
end;

procedure Syscall_BA3; stdcall;
asm
  mov r10, rcx
  mov eax, $BA3
  syscall
end;

procedure Syscall_BA4; stdcall;
asm
  mov r10, rcx
  mov eax, $BA4
  syscall
end;

procedure Syscall_BA5; stdcall;
asm
  mov r10, rcx
  mov eax, $BA5
  syscall
end;

procedure Syscall_BA6; stdcall;
asm
  mov r10, rcx
  mov eax, $BA6
  syscall
end;

procedure Syscall_BA7; stdcall;
asm
  mov r10, rcx
  mov eax, $BA7
  syscall
end;

procedure Syscall_BA8; stdcall;
asm
  mov r10, rcx
  mov eax, $BA8
  syscall
end;

procedure Syscall_BA9; stdcall;
asm
  mov r10, rcx
  mov eax, $BA9
  syscall
end;

procedure Syscall_BAA; stdcall;
asm
  mov r10, rcx
  mov eax, $BAA
  syscall
end;

procedure Syscall_BAB; stdcall;
asm
  mov r10, rcx
  mov eax, $BAB
  syscall
end;

procedure Syscall_BAC; stdcall;
asm
  mov r10, rcx
  mov eax, $BAC
  syscall
end;

procedure Syscall_BAD; stdcall;
asm
  mov r10, rcx
  mov eax, $BAD
  syscall
end;

procedure Syscall_BAE; stdcall;
asm
  mov r10, rcx
  mov eax, $BAE
  syscall
end;

procedure Syscall_BAF; stdcall;
asm
  mov r10, rcx
  mov eax, $BAF
  syscall
end;

procedure Syscall_BB0; stdcall;
asm
  mov r10, rcx
  mov eax, $BB0
  syscall
end;

procedure Syscall_BB1; stdcall;
asm
  mov r10, rcx
  mov eax, $BB1
  syscall
end;

procedure Syscall_BB2; stdcall;
asm
  mov r10, rcx
  mov eax, $BB2
  syscall
end;

procedure Syscall_BB3; stdcall;
asm
  mov r10, rcx
  mov eax, $BB3
  syscall
end;

procedure Syscall_BB4; stdcall;
asm
  mov r10, rcx
  mov eax, $BB4
  syscall
end;

procedure Syscall_BB5; stdcall;
asm
  mov r10, rcx
  mov eax, $BB5
  syscall
end;

procedure Syscall_BB6; stdcall;
asm
  mov r10, rcx
  mov eax, $BB6
  syscall
end;

procedure Syscall_BB7; stdcall;
asm
  mov r10, rcx
  mov eax, $BB7
  syscall
end;

procedure Syscall_BB8; stdcall;
asm
  mov r10, rcx
  mov eax, $BB8
  syscall
end;

procedure Syscall_BB9; stdcall;
asm
  mov r10, rcx
  mov eax, $BB9
  syscall
end;

procedure Syscall_BBA; stdcall;
asm
  mov r10, rcx
  mov eax, $BBA
  syscall
end;

procedure Syscall_BBB; stdcall;
asm
  mov r10, rcx
  mov eax, $BBB
  syscall
end;

procedure Syscall_BBC; stdcall;
asm
  mov r10, rcx
  mov eax, $BBC
  syscall
end;

procedure Syscall_BBD; stdcall;
asm
  mov r10, rcx
  mov eax, $BBD
  syscall
end;

procedure Syscall_BBE; stdcall;
asm
  mov r10, rcx
  mov eax, $BBE
  syscall
end;

procedure Syscall_BBF; stdcall;
asm
  mov r10, rcx
  mov eax, $BBF
  syscall
end;

procedure Syscall_BC0; stdcall;
asm
  mov r10, rcx
  mov eax, $BC0
  syscall
end;

procedure Syscall_BC1; stdcall;
asm
  mov r10, rcx
  mov eax, $BC1
  syscall
end;

procedure Syscall_BC2; stdcall;
asm
  mov r10, rcx
  mov eax, $BC2
  syscall
end;

procedure Syscall_BC3; stdcall;
asm
  mov r10, rcx
  mov eax, $BC3
  syscall
end;

procedure Syscall_BC4; stdcall;
asm
  mov r10, rcx
  mov eax, $BC4
  syscall
end;

procedure Syscall_BC5; stdcall;
asm
  mov r10, rcx
  mov eax, $BC5
  syscall
end;

procedure Syscall_BC6; stdcall;
asm
  mov r10, rcx
  mov eax, $BC6
  syscall
end;

procedure Syscall_BC7; stdcall;
asm
  mov r10, rcx
  mov eax, $BC7
  syscall
end;

procedure Syscall_BC8; stdcall;
asm
  mov r10, rcx
  mov eax, $BC8
  syscall
end;

procedure Syscall_BC9; stdcall;
asm
  mov r10, rcx
  mov eax, $BC9
  syscall
end;

procedure Syscall_BCA; stdcall;
asm
  mov r10, rcx
  mov eax, $BCA
  syscall
end;

procedure Syscall_BCB; stdcall;
asm
  mov r10, rcx
  mov eax, $BCB
  syscall
end;

procedure Syscall_BCC; stdcall;
asm
  mov r10, rcx
  mov eax, $BCC
  syscall
end;

procedure Syscall_BCD; stdcall;
asm
  mov r10, rcx
  mov eax, $BCD
  syscall
end;

procedure Syscall_BCE; stdcall;
asm
  mov r10, rcx
  mov eax, $BCE
  syscall
end;

procedure Syscall_BCF; stdcall;
asm
  mov r10, rcx
  mov eax, $BCF
  syscall
end;

procedure Syscall_BD0; stdcall;
asm
  mov r10, rcx
  mov eax, $BD0
  syscall
end;

procedure Syscall_BD1; stdcall;
asm
  mov r10, rcx
  mov eax, $BD1
  syscall
end;

procedure Syscall_BD2; stdcall;
asm
  mov r10, rcx
  mov eax, $BD2
  syscall
end;

procedure Syscall_BD3; stdcall;
asm
  mov r10, rcx
  mov eax, $BD3
  syscall
end;

procedure Syscall_BD4; stdcall;
asm
  mov r10, rcx
  mov eax, $BD4
  syscall
end;

procedure Syscall_BD5; stdcall;
asm
  mov r10, rcx
  mov eax, $BD5
  syscall
end;

procedure Syscall_BD6; stdcall;
asm
  mov r10, rcx
  mov eax, $BD6
  syscall
end;

procedure Syscall_BD7; stdcall;
asm
  mov r10, rcx
  mov eax, $BD7
  syscall
end;

procedure Syscall_BD8; stdcall;
asm
  mov r10, rcx
  mov eax, $BD8
  syscall
end;

procedure Syscall_BD9; stdcall;
asm
  mov r10, rcx
  mov eax, $BD9
  syscall
end;

procedure Syscall_BDA; stdcall;
asm
  mov r10, rcx
  mov eax, $BDA
  syscall
end;

procedure Syscall_BDB; stdcall;
asm
  mov r10, rcx
  mov eax, $BDB
  syscall
end;

procedure Syscall_BDC; stdcall;
asm
  mov r10, rcx
  mov eax, $BDC
  syscall
end;

procedure Syscall_BDD; stdcall;
asm
  mov r10, rcx
  mov eax, $BDD
  syscall
end;

procedure Syscall_BDE; stdcall;
asm
  mov r10, rcx
  mov eax, $BDE
  syscall
end;

procedure Syscall_BDF; stdcall;
asm
  mov r10, rcx
  mov eax, $BDF
  syscall
end;

procedure Syscall_BE0; stdcall;
asm
  mov r10, rcx
  mov eax, $BE0
  syscall
end;

procedure Syscall_BE1; stdcall;
asm
  mov r10, rcx
  mov eax, $BE1
  syscall
end;

procedure Syscall_BE2; stdcall;
asm
  mov r10, rcx
  mov eax, $BE2
  syscall
end;

procedure Syscall_BE3; stdcall;
asm
  mov r10, rcx
  mov eax, $BE3
  syscall
end;

procedure Syscall_BE4; stdcall;
asm
  mov r10, rcx
  mov eax, $BE4
  syscall
end;

procedure Syscall_BE5; stdcall;
asm
  mov r10, rcx
  mov eax, $BE5
  syscall
end;

procedure Syscall_BE6; stdcall;
asm
  mov r10, rcx
  mov eax, $BE6
  syscall
end;

procedure Syscall_BE7; stdcall;
asm
  mov r10, rcx
  mov eax, $BE7
  syscall
end;

procedure Syscall_BE8; stdcall;
asm
  mov r10, rcx
  mov eax, $BE8
  syscall
end;

procedure Syscall_BE9; stdcall;
asm
  mov r10, rcx
  mov eax, $BE9
  syscall
end;

procedure Syscall_BEA; stdcall;
asm
  mov r10, rcx
  mov eax, $BEA
  syscall
end;

procedure Syscall_BEB; stdcall;
asm
  mov r10, rcx
  mov eax, $BEB
  syscall
end;

procedure Syscall_BEC; stdcall;
asm
  mov r10, rcx
  mov eax, $BEC
  syscall
end;

procedure Syscall_BED; stdcall;
asm
  mov r10, rcx
  mov eax, $BED
  syscall
end;

procedure Syscall_BEE; stdcall;
asm
  mov r10, rcx
  mov eax, $BEE
  syscall
end;

procedure Syscall_BEF; stdcall;
asm
  mov r10, rcx
  mov eax, $BEF
  syscall
end;

procedure Syscall_BF0; stdcall;
asm
  mov r10, rcx
  mov eax, $BF0
  syscall
end;

procedure Syscall_BF1; stdcall;
asm
  mov r10, rcx
  mov eax, $BF1
  syscall
end;

procedure Syscall_BF2; stdcall;
asm
  mov r10, rcx
  mov eax, $BF2
  syscall
end;

procedure Syscall_BF3; stdcall;
asm
  mov r10, rcx
  mov eax, $BF3
  syscall
end;

procedure Syscall_BF4; stdcall;
asm
  mov r10, rcx
  mov eax, $BF4
  syscall
end;

procedure Syscall_BF5; stdcall;
asm
  mov r10, rcx
  mov eax, $BF5
  syscall
end;

procedure Syscall_BF6; stdcall;
asm
  mov r10, rcx
  mov eax, $BF6
  syscall
end;

procedure Syscall_BF7; stdcall;
asm
  mov r10, rcx
  mov eax, $BF7
  syscall
end;

procedure Syscall_BF8; stdcall;
asm
  mov r10, rcx
  mov eax, $BF8
  syscall
end;

procedure Syscall_BF9; stdcall;
asm
  mov r10, rcx
  mov eax, $BF9
  syscall
end;

procedure Syscall_BFA; stdcall;
asm
  mov r10, rcx
  mov eax, $BFA
  syscall
end;

procedure Syscall_BFB; stdcall;
asm
  mov r10, rcx
  mov eax, $BFB
  syscall
end;

procedure Syscall_BFC; stdcall;
asm
  mov r10, rcx
  mov eax, $BFC
  syscall
end;

procedure Syscall_BFD; stdcall;
asm
  mov r10, rcx
  mov eax, $BFD
  syscall
end;

procedure Syscall_BFE; stdcall;
asm
  mov r10, rcx
  mov eax, $BFE
  syscall
end;

procedure Syscall_BFF; stdcall;
asm
  mov r10, rcx
  mov eax, $BFF
  syscall
end;

procedure Syscall_C00; stdcall;
asm
  mov r10, rcx
  mov eax, $C00
  syscall
end;

procedure Syscall_C01; stdcall;
asm
  mov r10, rcx
  mov eax, $C01
  syscall
end;

procedure Syscall_C02; stdcall;
asm
  mov r10, rcx
  mov eax, $C02
  syscall
end;

procedure Syscall_C03; stdcall;
asm
  mov r10, rcx
  mov eax, $C03
  syscall
end;

procedure Syscall_C04; stdcall;
asm
  mov r10, rcx
  mov eax, $C04
  syscall
end;

procedure Syscall_C05; stdcall;
asm
  mov r10, rcx
  mov eax, $C05
  syscall
end;

procedure Syscall_C06; stdcall;
asm
  mov r10, rcx
  mov eax, $C06
  syscall
end;

procedure Syscall_C07; stdcall;
asm
  mov r10, rcx
  mov eax, $C07
  syscall
end;

procedure Syscall_C08; stdcall;
asm
  mov r10, rcx
  mov eax, $C08
  syscall
end;

procedure Syscall_C09; stdcall;
asm
  mov r10, rcx
  mov eax, $C09
  syscall
end;

procedure Syscall_C0A; stdcall;
asm
  mov r10, rcx
  mov eax, $C0A
  syscall
end;

procedure Syscall_C0B; stdcall;
asm
  mov r10, rcx
  mov eax, $C0B
  syscall
end;

procedure Syscall_C0C; stdcall;
asm
  mov r10, rcx
  mov eax, $C0C
  syscall
end;

procedure Syscall_C0D; stdcall;
asm
  mov r10, rcx
  mov eax, $C0D
  syscall
end;

procedure Syscall_C0E; stdcall;
asm
  mov r10, rcx
  mov eax, $C0E
  syscall
end;

procedure Syscall_C0F; stdcall;
asm
  mov r10, rcx
  mov eax, $C0F
  syscall
end;

procedure Syscall_C10; stdcall;
asm
  mov r10, rcx
  mov eax, $C10
  syscall
end;

procedure Syscall_C11; stdcall;
asm
  mov r10, rcx
  mov eax, $C11
  syscall
end;

procedure Syscall_C12; stdcall;
asm
  mov r10, rcx
  mov eax, $C12
  syscall
end;

procedure Syscall_C13; stdcall;
asm
  mov r10, rcx
  mov eax, $C13
  syscall
end;

procedure Syscall_C14; stdcall;
asm
  mov r10, rcx
  mov eax, $C14
  syscall
end;

procedure Syscall_C15; stdcall;
asm
  mov r10, rcx
  mov eax, $C15
  syscall
end;

procedure Syscall_C16; stdcall;
asm
  mov r10, rcx
  mov eax, $C16
  syscall
end;

procedure Syscall_C17; stdcall;
asm
  mov r10, rcx
  mov eax, $C17
  syscall
end;

procedure Syscall_C18; stdcall;
asm
  mov r10, rcx
  mov eax, $C18
  syscall
end;

procedure Syscall_C19; stdcall;
asm
  mov r10, rcx
  mov eax, $C19
  syscall
end;

procedure Syscall_C1A; stdcall;
asm
  mov r10, rcx
  mov eax, $C1A
  syscall
end;

procedure Syscall_C1B; stdcall;
asm
  mov r10, rcx
  mov eax, $C1B
  syscall
end;

procedure Syscall_C1C; stdcall;
asm
  mov r10, rcx
  mov eax, $C1C
  syscall
end;

procedure Syscall_C1D; stdcall;
asm
  mov r10, rcx
  mov eax, $C1D
  syscall
end;

procedure Syscall_C1E; stdcall;
asm
  mov r10, rcx
  mov eax, $C1E
  syscall
end;

procedure Syscall_C1F; stdcall;
asm
  mov r10, rcx
  mov eax, $C1F
  syscall
end;

procedure Syscall_C20; stdcall;
asm
  mov r10, rcx
  mov eax, $C20
  syscall
end;

procedure Syscall_C21; stdcall;
asm
  mov r10, rcx
  mov eax, $C21
  syscall
end;

procedure Syscall_C22; stdcall;
asm
  mov r10, rcx
  mov eax, $C22
  syscall
end;

procedure Syscall_C23; stdcall;
asm
  mov r10, rcx
  mov eax, $C23
  syscall
end;

procedure Syscall_C24; stdcall;
asm
  mov r10, rcx
  mov eax, $C24
  syscall
end;

procedure Syscall_C25; stdcall;
asm
  mov r10, rcx
  mov eax, $C25
  syscall
end;

procedure Syscall_C26; stdcall;
asm
  mov r10, rcx
  mov eax, $C26
  syscall
end;

procedure Syscall_C27; stdcall;
asm
  mov r10, rcx
  mov eax, $C27
  syscall
end;

procedure Syscall_C28; stdcall;
asm
  mov r10, rcx
  mov eax, $C28
  syscall
end;

procedure Syscall_C29; stdcall;
asm
  mov r10, rcx
  mov eax, $C29
  syscall
end;

procedure Syscall_C2A; stdcall;
asm
  mov r10, rcx
  mov eax, $C2A
  syscall
end;

procedure Syscall_C2B; stdcall;
asm
  mov r10, rcx
  mov eax, $C2B
  syscall
end;

procedure Syscall_C2C; stdcall;
asm
  mov r10, rcx
  mov eax, $C2C
  syscall
end;

procedure Syscall_C2D; stdcall;
asm
  mov r10, rcx
  mov eax, $C2D
  syscall
end;

procedure Syscall_C2E; stdcall;
asm
  mov r10, rcx
  mov eax, $C2E
  syscall
end;

procedure Syscall_C2F; stdcall;
asm
  mov r10, rcx
  mov eax, $C2F
  syscall
end;

procedure Syscall_C30; stdcall;
asm
  mov r10, rcx
  mov eax, $C30
  syscall
end;

procedure Syscall_C31; stdcall;
asm
  mov r10, rcx
  mov eax, $C31
  syscall
end;

procedure Syscall_C32; stdcall;
asm
  mov r10, rcx
  mov eax, $C32
  syscall
end;

procedure Syscall_C33; stdcall;
asm
  mov r10, rcx
  mov eax, $C33
  syscall
end;

procedure Syscall_C34; stdcall;
asm
  mov r10, rcx
  mov eax, $C34
  syscall
end;

procedure Syscall_C35; stdcall;
asm
  mov r10, rcx
  mov eax, $C35
  syscall
end;

procedure Syscall_C36; stdcall;
asm
  mov r10, rcx
  mov eax, $C36
  syscall
end;

procedure Syscall_C37; stdcall;
asm
  mov r10, rcx
  mov eax, $C37
  syscall
end;

procedure Syscall_C38; stdcall;
asm
  mov r10, rcx
  mov eax, $C38
  syscall
end;

procedure Syscall_C39; stdcall;
asm
  mov r10, rcx
  mov eax, $C39
  syscall
end;

procedure Syscall_C3A; stdcall;
asm
  mov r10, rcx
  mov eax, $C3A
  syscall
end;

procedure Syscall_C3B; stdcall;
asm
  mov r10, rcx
  mov eax, $C3B
  syscall
end;

procedure Syscall_C3C; stdcall;
asm
  mov r10, rcx
  mov eax, $C3C
  syscall
end;

procedure Syscall_C3D; stdcall;
asm
  mov r10, rcx
  mov eax, $C3D
  syscall
end;

procedure Syscall_C3E; stdcall;
asm
  mov r10, rcx
  mov eax, $C3E
  syscall
end;

procedure Syscall_C3F; stdcall;
asm
  mov r10, rcx
  mov eax, $C3F
  syscall
end;

procedure Syscall_C40; stdcall;
asm
  mov r10, rcx
  mov eax, $C40
  syscall
end;

procedure Syscall_C41; stdcall;
asm
  mov r10, rcx
  mov eax, $C41
  syscall
end;

procedure Syscall_C42; stdcall;
asm
  mov r10, rcx
  mov eax, $C42
  syscall
end;

procedure Syscall_C43; stdcall;
asm
  mov r10, rcx
  mov eax, $C43
  syscall
end;

procedure Syscall_C44; stdcall;
asm
  mov r10, rcx
  mov eax, $C44
  syscall
end;

procedure Syscall_C45; stdcall;
asm
  mov r10, rcx
  mov eax, $C45
  syscall
end;

procedure Syscall_C46; stdcall;
asm
  mov r10, rcx
  mov eax, $C46
  syscall
end;

procedure Syscall_C47; stdcall;
asm
  mov r10, rcx
  mov eax, $C47
  syscall
end;

procedure Syscall_C48; stdcall;
asm
  mov r10, rcx
  mov eax, $C48
  syscall
end;

procedure Syscall_C49; stdcall;
asm
  mov r10, rcx
  mov eax, $C49
  syscall
end;

procedure Syscall_C4A; stdcall;
asm
  mov r10, rcx
  mov eax, $C4A
  syscall
end;

procedure Syscall_C4B; stdcall;
asm
  mov r10, rcx
  mov eax, $C4B
  syscall
end;

procedure Syscall_C4C; stdcall;
asm
  mov r10, rcx
  mov eax, $C4C
  syscall
end;

procedure Syscall_C4D; stdcall;
asm
  mov r10, rcx
  mov eax, $C4D
  syscall
end;

procedure Syscall_C4E; stdcall;
asm
  mov r10, rcx
  mov eax, $C4E
  syscall
end;

procedure Syscall_C4F; stdcall;
asm
  mov r10, rcx
  mov eax, $C4F
  syscall
end;

procedure Syscall_C50; stdcall;
asm
  mov r10, rcx
  mov eax, $C50
  syscall
end;

procedure Syscall_C51; stdcall;
asm
  mov r10, rcx
  mov eax, $C51
  syscall
end;

procedure Syscall_C52; stdcall;
asm
  mov r10, rcx
  mov eax, $C52
  syscall
end;

procedure Syscall_C53; stdcall;
asm
  mov r10, rcx
  mov eax, $C53
  syscall
end;

procedure Syscall_C54; stdcall;
asm
  mov r10, rcx
  mov eax, $C54
  syscall
end;

procedure Syscall_C55; stdcall;
asm
  mov r10, rcx
  mov eax, $C55
  syscall
end;

procedure Syscall_C56; stdcall;
asm
  mov r10, rcx
  mov eax, $C56
  syscall
end;

procedure Syscall_C57; stdcall;
asm
  mov r10, rcx
  mov eax, $C57
  syscall
end;

procedure Syscall_C58; stdcall;
asm
  mov r10, rcx
  mov eax, $C58
  syscall
end;

procedure Syscall_C59; stdcall;
asm
  mov r10, rcx
  mov eax, $C59
  syscall
end;

procedure Syscall_C5A; stdcall;
asm
  mov r10, rcx
  mov eax, $C5A
  syscall
end;

procedure Syscall_C5B; stdcall;
asm
  mov r10, rcx
  mov eax, $C5B
  syscall
end;

procedure Syscall_C5C; stdcall;
asm
  mov r10, rcx
  mov eax, $C5C
  syscall
end;

procedure Syscall_C5D; stdcall;
asm
  mov r10, rcx
  mov eax, $C5D
  syscall
end;

procedure Syscall_C5E; stdcall;
asm
  mov r10, rcx
  mov eax, $C5E
  syscall
end;

procedure Syscall_C5F; stdcall;
asm
  mov r10, rcx
  mov eax, $C5F
  syscall
end;

procedure Syscall_C60; stdcall;
asm
  mov r10, rcx
  mov eax, $C60
  syscall
end;

procedure Syscall_C61; stdcall;
asm
  mov r10, rcx
  mov eax, $C61
  syscall
end;

procedure Syscall_C62; stdcall;
asm
  mov r10, rcx
  mov eax, $C62
  syscall
end;

procedure Syscall_C63; stdcall;
asm
  mov r10, rcx
  mov eax, $C63
  syscall
end;

procedure Syscall_C64; stdcall;
asm
  mov r10, rcx
  mov eax, $C64
  syscall
end;

procedure Syscall_C65; stdcall;
asm
  mov r10, rcx
  mov eax, $C65
  syscall
end;

procedure Syscall_C66; stdcall;
asm
  mov r10, rcx
  mov eax, $C66
  syscall
end;

procedure Syscall_C67; stdcall;
asm
  mov r10, rcx
  mov eax, $C67
  syscall
end;

procedure Syscall_C68; stdcall;
asm
  mov r10, rcx
  mov eax, $C68
  syscall
end;

procedure Syscall_C69; stdcall;
asm
  mov r10, rcx
  mov eax, $C69
  syscall
end;

procedure Syscall_C6A; stdcall;
asm
  mov r10, rcx
  mov eax, $C6A
  syscall
end;

procedure Syscall_C6B; stdcall;
asm
  mov r10, rcx
  mov eax, $C6B
  syscall
end;

procedure Syscall_C6C; stdcall;
asm
  mov r10, rcx
  mov eax, $C6C
  syscall
end;

procedure Syscall_C6D; stdcall;
asm
  mov r10, rcx
  mov eax, $C6D
  syscall
end;

procedure Syscall_C6E; stdcall;
asm
  mov r10, rcx
  mov eax, $C6E
  syscall
end;

procedure Syscall_C6F; stdcall;
asm
  mov r10, rcx
  mov eax, $C6F
  syscall
end;

procedure Syscall_C70; stdcall;
asm
  mov r10, rcx
  mov eax, $C70
  syscall
end;

procedure Syscall_C71; stdcall;
asm
  mov r10, rcx
  mov eax, $C71
  syscall
end;

procedure Syscall_C72; stdcall;
asm
  mov r10, rcx
  mov eax, $C72
  syscall
end;

procedure Syscall_C73; stdcall;
asm
  mov r10, rcx
  mov eax, $C73
  syscall
end;

procedure Syscall_C74; stdcall;
asm
  mov r10, rcx
  mov eax, $C74
  syscall
end;

procedure Syscall_C75; stdcall;
asm
  mov r10, rcx
  mov eax, $C75
  syscall
end;

procedure Syscall_C76; stdcall;
asm
  mov r10, rcx
  mov eax, $C76
  syscall
end;

procedure Syscall_C77; stdcall;
asm
  mov r10, rcx
  mov eax, $C77
  syscall
end;

procedure Syscall_C78; stdcall;
asm
  mov r10, rcx
  mov eax, $C78
  syscall
end;

procedure Syscall_C79; stdcall;
asm
  mov r10, rcx
  mov eax, $C79
  syscall
end;

procedure Syscall_C7A; stdcall;
asm
  mov r10, rcx
  mov eax, $C7A
  syscall
end;

procedure Syscall_C7B; stdcall;
asm
  mov r10, rcx
  mov eax, $C7B
  syscall
end;

procedure Syscall_C7C; stdcall;
asm
  mov r10, rcx
  mov eax, $C7C
  syscall
end;

procedure Syscall_C7D; stdcall;
asm
  mov r10, rcx
  mov eax, $C7D
  syscall
end;

procedure Syscall_C7E; stdcall;
asm
  mov r10, rcx
  mov eax, $C7E
  syscall
end;

procedure Syscall_C7F; stdcall;
asm
  mov r10, rcx
  mov eax, $C7F
  syscall
end;

procedure Syscall_C80; stdcall;
asm
  mov r10, rcx
  mov eax, $C80
  syscall
end;

procedure Syscall_C81; stdcall;
asm
  mov r10, rcx
  mov eax, $C81
  syscall
end;

procedure Syscall_C82; stdcall;
asm
  mov r10, rcx
  mov eax, $C82
  syscall
end;

procedure Syscall_C83; stdcall;
asm
  mov r10, rcx
  mov eax, $C83
  syscall
end;

procedure Syscall_C84; stdcall;
asm
  mov r10, rcx
  mov eax, $C84
  syscall
end;

procedure Syscall_C85; stdcall;
asm
  mov r10, rcx
  mov eax, $C85
  syscall
end;

procedure Syscall_C86; stdcall;
asm
  mov r10, rcx
  mov eax, $C86
  syscall
end;

procedure Syscall_C87; stdcall;
asm
  mov r10, rcx
  mov eax, $C87
  syscall
end;

procedure Syscall_C88; stdcall;
asm
  mov r10, rcx
  mov eax, $C88
  syscall
end;

procedure Syscall_C89; stdcall;
asm
  mov r10, rcx
  mov eax, $C89
  syscall
end;

procedure Syscall_C8A; stdcall;
asm
  mov r10, rcx
  mov eax, $C8A
  syscall
end;

procedure Syscall_C8B; stdcall;
asm
  mov r10, rcx
  mov eax, $C8B
  syscall
end;

procedure Syscall_C8C; stdcall;
asm
  mov r10, rcx
  mov eax, $C8C
  syscall
end;

procedure Syscall_C8D; stdcall;
asm
  mov r10, rcx
  mov eax, $C8D
  syscall
end;

procedure Syscall_C8E; stdcall;
asm
  mov r10, rcx
  mov eax, $C8E
  syscall
end;

procedure Syscall_C8F; stdcall;
asm
  mov r10, rcx
  mov eax, $C8F
  syscall
end;

procedure Syscall_C90; stdcall;
asm
  mov r10, rcx
  mov eax, $C90
  syscall
end;

procedure Syscall_C91; stdcall;
asm
  mov r10, rcx
  mov eax, $C91
  syscall
end;

procedure Syscall_C92; stdcall;
asm
  mov r10, rcx
  mov eax, $C92
  syscall
end;

procedure Syscall_C93; stdcall;
asm
  mov r10, rcx
  mov eax, $C93
  syscall
end;

procedure Syscall_C94; stdcall;
asm
  mov r10, rcx
  mov eax, $C94
  syscall
end;

procedure Syscall_C95; stdcall;
asm
  mov r10, rcx
  mov eax, $C95
  syscall
end;

procedure Syscall_C96; stdcall;
asm
  mov r10, rcx
  mov eax, $C96
  syscall
end;

procedure Syscall_C97; stdcall;
asm
  mov r10, rcx
  mov eax, $C97
  syscall
end;

procedure Syscall_C98; stdcall;
asm
  mov r10, rcx
  mov eax, $C98
  syscall
end;

procedure Syscall_C99; stdcall;
asm
  mov r10, rcx
  mov eax, $C99
  syscall
end;

procedure Syscall_C9A; stdcall;
asm
  mov r10, rcx
  mov eax, $C9A
  syscall
end;

procedure Syscall_C9B; stdcall;
asm
  mov r10, rcx
  mov eax, $C9B
  syscall
end;

procedure Syscall_C9C; stdcall;
asm
  mov r10, rcx
  mov eax, $C9C
  syscall
end;

procedure Syscall_C9D; stdcall;
asm
  mov r10, rcx
  mov eax, $C9D
  syscall
end;

procedure Syscall_C9E; stdcall;
asm
  mov r10, rcx
  mov eax, $C9E
  syscall
end;

procedure Syscall_C9F; stdcall;
asm
  mov r10, rcx
  mov eax, $C9F
  syscall
end;

procedure Syscall_CA0; stdcall;
asm
  mov r10, rcx
  mov eax, $CA0
  syscall
end;

procedure Syscall_CA1; stdcall;
asm
  mov r10, rcx
  mov eax, $CA1
  syscall
end;

procedure Syscall_CA2; stdcall;
asm
  mov r10, rcx
  mov eax, $CA2
  syscall
end;

procedure Syscall_CA3; stdcall;
asm
  mov r10, rcx
  mov eax, $CA3
  syscall
end;

procedure Syscall_CA4; stdcall;
asm
  mov r10, rcx
  mov eax, $CA4
  syscall
end;

procedure Syscall_CA5; stdcall;
asm
  mov r10, rcx
  mov eax, $CA5
  syscall
end;

procedure Syscall_CA6; stdcall;
asm
  mov r10, rcx
  mov eax, $CA6
  syscall
end;

procedure Syscall_CA7; stdcall;
asm
  mov r10, rcx
  mov eax, $CA7
  syscall
end;

procedure Syscall_CA8; stdcall;
asm
  mov r10, rcx
  mov eax, $CA8
  syscall
end;

procedure Syscall_CA9; stdcall;
asm
  mov r10, rcx
  mov eax, $CA9
  syscall
end;

procedure Syscall_CAA; stdcall;
asm
  mov r10, rcx
  mov eax, $CAA
  syscall
end;

procedure Syscall_CAB; stdcall;
asm
  mov r10, rcx
  mov eax, $CAB
  syscall
end;

procedure Syscall_CAC; stdcall;
asm
  mov r10, rcx
  mov eax, $CAC
  syscall
end;

procedure Syscall_CAD; stdcall;
asm
  mov r10, rcx
  mov eax, $CAD
  syscall
end;

procedure Syscall_CAE; stdcall;
asm
  mov r10, rcx
  mov eax, $CAE
  syscall
end;

procedure Syscall_CAF; stdcall;
asm
  mov r10, rcx
  mov eax, $CAF
  syscall
end;

procedure Syscall_CB0; stdcall;
asm
  mov r10, rcx
  mov eax, $CB0
  syscall
end;

procedure Syscall_CB1; stdcall;
asm
  mov r10, rcx
  mov eax, $CB1
  syscall
end;

procedure Syscall_CB2; stdcall;
asm
  mov r10, rcx
  mov eax, $CB2
  syscall
end;

procedure Syscall_CB3; stdcall;
asm
  mov r10, rcx
  mov eax, $CB3
  syscall
end;

procedure Syscall_CB4; stdcall;
asm
  mov r10, rcx
  mov eax, $CB4
  syscall
end;

procedure Syscall_CB5; stdcall;
asm
  mov r10, rcx
  mov eax, $CB5
  syscall
end;

procedure Syscall_CB6; stdcall;
asm
  mov r10, rcx
  mov eax, $CB6
  syscall
end;

procedure Syscall_CB7; stdcall;
asm
  mov r10, rcx
  mov eax, $CB7
  syscall
end;

procedure Syscall_CB8; stdcall;
asm
  mov r10, rcx
  mov eax, $CB8
  syscall
end;

procedure Syscall_CB9; stdcall;
asm
  mov r10, rcx
  mov eax, $CB9
  syscall
end;

procedure Syscall_CBA; stdcall;
asm
  mov r10, rcx
  mov eax, $CBA
  syscall
end;

procedure Syscall_CBB; stdcall;
asm
  mov r10, rcx
  mov eax, $CBB
  syscall
end;

procedure Syscall_CBC; stdcall;
asm
  mov r10, rcx
  mov eax, $CBC
  syscall
end;

procedure Syscall_CBD; stdcall;
asm
  mov r10, rcx
  mov eax, $CBD
  syscall
end;

procedure Syscall_CBE; stdcall;
asm
  mov r10, rcx
  mov eax, $CBE
  syscall
end;

procedure Syscall_CBF; stdcall;
asm
  mov r10, rcx
  mov eax, $CBF
  syscall
end;

procedure Syscall_CC0; stdcall;
asm
  mov r10, rcx
  mov eax, $CC0
  syscall
end;

procedure Syscall_CC1; stdcall;
asm
  mov r10, rcx
  mov eax, $CC1
  syscall
end;

procedure Syscall_CC2; stdcall;
asm
  mov r10, rcx
  mov eax, $CC2
  syscall
end;

procedure Syscall_CC3; stdcall;
asm
  mov r10, rcx
  mov eax, $CC3
  syscall
end;

procedure Syscall_CC4; stdcall;
asm
  mov r10, rcx
  mov eax, $CC4
  syscall
end;

procedure Syscall_CC5; stdcall;
asm
  mov r10, rcx
  mov eax, $CC5
  syscall
end;

procedure Syscall_CC6; stdcall;
asm
  mov r10, rcx
  mov eax, $CC6
  syscall
end;

procedure Syscall_CC7; stdcall;
asm
  mov r10, rcx
  mov eax, $CC7
  syscall
end;

procedure Syscall_CC8; stdcall;
asm
  mov r10, rcx
  mov eax, $CC8
  syscall
end;

procedure Syscall_CC9; stdcall;
asm
  mov r10, rcx
  mov eax, $CC9
  syscall
end;

procedure Syscall_CCA; stdcall;
asm
  mov r10, rcx
  mov eax, $CCA
  syscall
end;

procedure Syscall_CCB; stdcall;
asm
  mov r10, rcx
  mov eax, $CCB
  syscall
end;

procedure Syscall_CCC; stdcall;
asm
  mov r10, rcx
  mov eax, $CCC
  syscall
end;

procedure Syscall_CCD; stdcall;
asm
  mov r10, rcx
  mov eax, $CCD
  syscall
end;

procedure Syscall_CCE; stdcall;
asm
  mov r10, rcx
  mov eax, $CCE
  syscall
end;

procedure Syscall_CCF; stdcall;
asm
  mov r10, rcx
  mov eax, $CCF
  syscall
end;

procedure Syscall_CD0; stdcall;
asm
  mov r10, rcx
  mov eax, $CD0
  syscall
end;

procedure Syscall_CD1; stdcall;
asm
  mov r10, rcx
  mov eax, $CD1
  syscall
end;

procedure Syscall_CD2; stdcall;
asm
  mov r10, rcx
  mov eax, $CD2
  syscall
end;

procedure Syscall_CD3; stdcall;
asm
  mov r10, rcx
  mov eax, $CD3
  syscall
end;

procedure Syscall_CD4; stdcall;
asm
  mov r10, rcx
  mov eax, $CD4
  syscall
end;

procedure Syscall_CD5; stdcall;
asm
  mov r10, rcx
  mov eax, $CD5
  syscall
end;

procedure Syscall_CD6; stdcall;
asm
  mov r10, rcx
  mov eax, $CD6
  syscall
end;

procedure Syscall_CD7; stdcall;
asm
  mov r10, rcx
  mov eax, $CD7
  syscall
end;

procedure Syscall_CD8; stdcall;
asm
  mov r10, rcx
  mov eax, $CD8
  syscall
end;

procedure Syscall_CD9; stdcall;
asm
  mov r10, rcx
  mov eax, $CD9
  syscall
end;

procedure Syscall_CDA; stdcall;
asm
  mov r10, rcx
  mov eax, $CDA
  syscall
end;

procedure Syscall_CDB; stdcall;
asm
  mov r10, rcx
  mov eax, $CDB
  syscall
end;

procedure Syscall_CDC; stdcall;
asm
  mov r10, rcx
  mov eax, $CDC
  syscall
end;

procedure Syscall_CDD; stdcall;
asm
  mov r10, rcx
  mov eax, $CDD
  syscall
end;

procedure Syscall_CDE; stdcall;
asm
  mov r10, rcx
  mov eax, $CDE
  syscall
end;

procedure Syscall_CDF; stdcall;
asm
  mov r10, rcx
  mov eax, $CDF
  syscall
end;

procedure Syscall_CE0; stdcall;
asm
  mov r10, rcx
  mov eax, $CE0
  syscall
end;

procedure Syscall_CE1; stdcall;
asm
  mov r10, rcx
  mov eax, $CE1
  syscall
end;

procedure Syscall_CE2; stdcall;
asm
  mov r10, rcx
  mov eax, $CE2
  syscall
end;

procedure Syscall_CE3; stdcall;
asm
  mov r10, rcx
  mov eax, $CE3
  syscall
end;

procedure Syscall_CE4; stdcall;
asm
  mov r10, rcx
  mov eax, $CE4
  syscall
end;

procedure Syscall_CE5; stdcall;
asm
  mov r10, rcx
  mov eax, $CE5
  syscall
end;

procedure Syscall_CE6; stdcall;
asm
  mov r10, rcx
  mov eax, $CE6
  syscall
end;

procedure Syscall_CE7; stdcall;
asm
  mov r10, rcx
  mov eax, $CE7
  syscall
end;

procedure Syscall_CE8; stdcall;
asm
  mov r10, rcx
  mov eax, $CE8
  syscall
end;

procedure Syscall_CE9; stdcall;
asm
  mov r10, rcx
  mov eax, $CE9
  syscall
end;

procedure Syscall_CEA; stdcall;
asm
  mov r10, rcx
  mov eax, $CEA
  syscall
end;

procedure Syscall_CEB; stdcall;
asm
  mov r10, rcx
  mov eax, $CEB
  syscall
end;

procedure Syscall_CEC; stdcall;
asm
  mov r10, rcx
  mov eax, $CEC
  syscall
end;

procedure Syscall_CED; stdcall;
asm
  mov r10, rcx
  mov eax, $CED
  syscall
end;

procedure Syscall_CEE; stdcall;
asm
  mov r10, rcx
  mov eax, $CEE
  syscall
end;

procedure Syscall_CEF; stdcall;
asm
  mov r10, rcx
  mov eax, $CEF
  syscall
end;

procedure Syscall_CF0; stdcall;
asm
  mov r10, rcx
  mov eax, $CF0
  syscall
end;

procedure Syscall_CF1; stdcall;
asm
  mov r10, rcx
  mov eax, $CF1
  syscall
end;

procedure Syscall_CF2; stdcall;
asm
  mov r10, rcx
  mov eax, $CF2
  syscall
end;

procedure Syscall_CF3; stdcall;
asm
  mov r10, rcx
  mov eax, $CF3
  syscall
end;

procedure Syscall_CF4; stdcall;
asm
  mov r10, rcx
  mov eax, $CF4
  syscall
end;

procedure Syscall_CF5; stdcall;
asm
  mov r10, rcx
  mov eax, $CF5
  syscall
end;

procedure Syscall_CF6; stdcall;
asm
  mov r10, rcx
  mov eax, $CF6
  syscall
end;

procedure Syscall_CF7; stdcall;
asm
  mov r10, rcx
  mov eax, $CF7
  syscall
end;

procedure Syscall_CF8; stdcall;
asm
  mov r10, rcx
  mov eax, $CF8
  syscall
end;

procedure Syscall_CF9; stdcall;
asm
  mov r10, rcx
  mov eax, $CF9
  syscall
end;

procedure Syscall_CFA; stdcall;
asm
  mov r10, rcx
  mov eax, $CFA
  syscall
end;

procedure Syscall_CFB; stdcall;
asm
  mov r10, rcx
  mov eax, $CFB
  syscall
end;

procedure Syscall_CFC; stdcall;
asm
  mov r10, rcx
  mov eax, $CFC
  syscall
end;

procedure Syscall_CFD; stdcall;
asm
  mov r10, rcx
  mov eax, $CFD
  syscall
end;

procedure Syscall_CFE; stdcall;
asm
  mov r10, rcx
  mov eax, $CFE
  syscall
end;

procedure Syscall_CFF; stdcall;
asm
  mov r10, rcx
  mov eax, $CFF
  syscall
end;

procedure Syscall_D00; stdcall;
asm
  mov r10, rcx
  mov eax, $D00
  syscall
end;

procedure Syscall_D01; stdcall;
asm
  mov r10, rcx
  mov eax, $D01
  syscall
end;

procedure Syscall_D02; stdcall;
asm
  mov r10, rcx
  mov eax, $D02
  syscall
end;

procedure Syscall_D03; stdcall;
asm
  mov r10, rcx
  mov eax, $D03
  syscall
end;

procedure Syscall_D04; stdcall;
asm
  mov r10, rcx
  mov eax, $D04
  syscall
end;

procedure Syscall_D05; stdcall;
asm
  mov r10, rcx
  mov eax, $D05
  syscall
end;

procedure Syscall_D06; stdcall;
asm
  mov r10, rcx
  mov eax, $D06
  syscall
end;

procedure Syscall_D07; stdcall;
asm
  mov r10, rcx
  mov eax, $D07
  syscall
end;

procedure Syscall_D08; stdcall;
asm
  mov r10, rcx
  mov eax, $D08
  syscall
end;

procedure Syscall_D09; stdcall;
asm
  mov r10, rcx
  mov eax, $D09
  syscall
end;

procedure Syscall_D0A; stdcall;
asm
  mov r10, rcx
  mov eax, $D0A
  syscall
end;

procedure Syscall_D0B; stdcall;
asm
  mov r10, rcx
  mov eax, $D0B
  syscall
end;

procedure Syscall_D0C; stdcall;
asm
  mov r10, rcx
  mov eax, $D0C
  syscall
end;

procedure Syscall_D0D; stdcall;
asm
  mov r10, rcx
  mov eax, $D0D
  syscall
end;

procedure Syscall_D0E; stdcall;
asm
  mov r10, rcx
  mov eax, $D0E
  syscall
end;

procedure Syscall_D0F; stdcall;
asm
  mov r10, rcx
  mov eax, $D0F
  syscall
end;

procedure Syscall_D10; stdcall;
asm
  mov r10, rcx
  mov eax, $D10
  syscall
end;

procedure Syscall_D11; stdcall;
asm
  mov r10, rcx
  mov eax, $D11
  syscall
end;

procedure Syscall_D12; stdcall;
asm
  mov r10, rcx
  mov eax, $D12
  syscall
end;

procedure Syscall_D13; stdcall;
asm
  mov r10, rcx
  mov eax, $D13
  syscall
end;

procedure Syscall_D14; stdcall;
asm
  mov r10, rcx
  mov eax, $D14
  syscall
end;

procedure Syscall_D15; stdcall;
asm
  mov r10, rcx
  mov eax, $D15
  syscall
end;

procedure Syscall_D16; stdcall;
asm
  mov r10, rcx
  mov eax, $D16
  syscall
end;

procedure Syscall_D17; stdcall;
asm
  mov r10, rcx
  mov eax, $D17
  syscall
end;

procedure Syscall_D18; stdcall;
asm
  mov r10, rcx
  mov eax, $D18
  syscall
end;

procedure Syscall_D19; stdcall;
asm
  mov r10, rcx
  mov eax, $D19
  syscall
end;

procedure Syscall_D1A; stdcall;
asm
  mov r10, rcx
  mov eax, $D1A
  syscall
end;

procedure Syscall_D1B; stdcall;
asm
  mov r10, rcx
  mov eax, $D1B
  syscall
end;

procedure Syscall_D1C; stdcall;
asm
  mov r10, rcx
  mov eax, $D1C
  syscall
end;

procedure Syscall_D1D; stdcall;
asm
  mov r10, rcx
  mov eax, $D1D
  syscall
end;

procedure Syscall_D1E; stdcall;
asm
  mov r10, rcx
  mov eax, $D1E
  syscall
end;

procedure Syscall_D1F; stdcall;
asm
  mov r10, rcx
  mov eax, $D1F
  syscall
end;

procedure Syscall_D20; stdcall;
asm
  mov r10, rcx
  mov eax, $D20
  syscall
end;

procedure Syscall_D21; stdcall;
asm
  mov r10, rcx
  mov eax, $D21
  syscall
end;

procedure Syscall_D22; stdcall;
asm
  mov r10, rcx
  mov eax, $D22
  syscall
end;

procedure Syscall_D23; stdcall;
asm
  mov r10, rcx
  mov eax, $D23
  syscall
end;

procedure Syscall_D24; stdcall;
asm
  mov r10, rcx
  mov eax, $D24
  syscall
end;

procedure Syscall_D25; stdcall;
asm
  mov r10, rcx
  mov eax, $D25
  syscall
end;

procedure Syscall_D26; stdcall;
asm
  mov r10, rcx
  mov eax, $D26
  syscall
end;

procedure Syscall_D27; stdcall;
asm
  mov r10, rcx
  mov eax, $D27
  syscall
end;

procedure Syscall_D28; stdcall;
asm
  mov r10, rcx
  mov eax, $D28
  syscall
end;

procedure Syscall_D29; stdcall;
asm
  mov r10, rcx
  mov eax, $D29
  syscall
end;

procedure Syscall_D2A; stdcall;
asm
  mov r10, rcx
  mov eax, $D2A
  syscall
end;

procedure Syscall_D2B; stdcall;
asm
  mov r10, rcx
  mov eax, $D2B
  syscall
end;

procedure Syscall_D2C; stdcall;
asm
  mov r10, rcx
  mov eax, $D2C
  syscall
end;

procedure Syscall_D2D; stdcall;
asm
  mov r10, rcx
  mov eax, $D2D
  syscall
end;

procedure Syscall_D2E; stdcall;
asm
  mov r10, rcx
  mov eax, $D2E
  syscall
end;

procedure Syscall_D2F; stdcall;
asm
  mov r10, rcx
  mov eax, $D2F
  syscall
end;

procedure Syscall_D30; stdcall;
asm
  mov r10, rcx
  mov eax, $D30
  syscall
end;

procedure Syscall_D31; stdcall;
asm
  mov r10, rcx
  mov eax, $D31
  syscall
end;

procedure Syscall_D32; stdcall;
asm
  mov r10, rcx
  mov eax, $D32
  syscall
end;

procedure Syscall_D33; stdcall;
asm
  mov r10, rcx
  mov eax, $D33
  syscall
end;

procedure Syscall_D34; stdcall;
asm
  mov r10, rcx
  mov eax, $D34
  syscall
end;

procedure Syscall_D35; stdcall;
asm
  mov r10, rcx
  mov eax, $D35
  syscall
end;

procedure Syscall_D36; stdcall;
asm
  mov r10, rcx
  mov eax, $D36
  syscall
end;

procedure Syscall_D37; stdcall;
asm
  mov r10, rcx
  mov eax, $D37
  syscall
end;

procedure Syscall_D38; stdcall;
asm
  mov r10, rcx
  mov eax, $D38
  syscall
end;

procedure Syscall_D39; stdcall;
asm
  mov r10, rcx
  mov eax, $D39
  syscall
end;

procedure Syscall_D3A; stdcall;
asm
  mov r10, rcx
  mov eax, $D3A
  syscall
end;

procedure Syscall_D3B; stdcall;
asm
  mov r10, rcx
  mov eax, $D3B
  syscall
end;

procedure Syscall_D3C; stdcall;
asm
  mov r10, rcx
  mov eax, $D3C
  syscall
end;

procedure Syscall_D3D; stdcall;
asm
  mov r10, rcx
  mov eax, $D3D
  syscall
end;

procedure Syscall_D3E; stdcall;
asm
  mov r10, rcx
  mov eax, $D3E
  syscall
end;

procedure Syscall_D3F; stdcall;
asm
  mov r10, rcx
  mov eax, $D3F
  syscall
end;

procedure Syscall_D40; stdcall;
asm
  mov r10, rcx
  mov eax, $D40
  syscall
end;

procedure Syscall_D41; stdcall;
asm
  mov r10, rcx
  mov eax, $D41
  syscall
end;

procedure Syscall_D42; stdcall;
asm
  mov r10, rcx
  mov eax, $D42
  syscall
end;

procedure Syscall_D43; stdcall;
asm
  mov r10, rcx
  mov eax, $D43
  syscall
end;

procedure Syscall_D44; stdcall;
asm
  mov r10, rcx
  mov eax, $D44
  syscall
end;

procedure Syscall_D45; stdcall;
asm
  mov r10, rcx
  mov eax, $D45
  syscall
end;

procedure Syscall_D46; stdcall;
asm
  mov r10, rcx
  mov eax, $D46
  syscall
end;

procedure Syscall_D47; stdcall;
asm
  mov r10, rcx
  mov eax, $D47
  syscall
end;

procedure Syscall_D48; stdcall;
asm
  mov r10, rcx
  mov eax, $D48
  syscall
end;

procedure Syscall_D49; stdcall;
asm
  mov r10, rcx
  mov eax, $D49
  syscall
end;

procedure Syscall_D4A; stdcall;
asm
  mov r10, rcx
  mov eax, $D4A
  syscall
end;

procedure Syscall_D4B; stdcall;
asm
  mov r10, rcx
  mov eax, $D4B
  syscall
end;

procedure Syscall_D4C; stdcall;
asm
  mov r10, rcx
  mov eax, $D4C
  syscall
end;

procedure Syscall_D4D; stdcall;
asm
  mov r10, rcx
  mov eax, $D4D
  syscall
end;

procedure Syscall_D4E; stdcall;
asm
  mov r10, rcx
  mov eax, $D4E
  syscall
end;

procedure Syscall_D4F; stdcall;
asm
  mov r10, rcx
  mov eax, $D4F
  syscall
end;

procedure Syscall_D50; stdcall;
asm
  mov r10, rcx
  mov eax, $D50
  syscall
end;

procedure Syscall_D51; stdcall;
asm
  mov r10, rcx
  mov eax, $D51
  syscall
end;

procedure Syscall_D52; stdcall;
asm
  mov r10, rcx
  mov eax, $D52
  syscall
end;

procedure Syscall_D53; stdcall;
asm
  mov r10, rcx
  mov eax, $D53
  syscall
end;

procedure Syscall_D54; stdcall;
asm
  mov r10, rcx
  mov eax, $D54
  syscall
end;

procedure Syscall_D55; stdcall;
asm
  mov r10, rcx
  mov eax, $D55
  syscall
end;

procedure Syscall_D56; stdcall;
asm
  mov r10, rcx
  mov eax, $D56
  syscall
end;

procedure Syscall_D57; stdcall;
asm
  mov r10, rcx
  mov eax, $D57
  syscall
end;

procedure Syscall_D58; stdcall;
asm
  mov r10, rcx
  mov eax, $D58
  syscall
end;

procedure Syscall_D59; stdcall;
asm
  mov r10, rcx
  mov eax, $D59
  syscall
end;

procedure Syscall_D5A; stdcall;
asm
  mov r10, rcx
  mov eax, $D5A
  syscall
end;

procedure Syscall_D5B; stdcall;
asm
  mov r10, rcx
  mov eax, $D5B
  syscall
end;

procedure Syscall_D5C; stdcall;
asm
  mov r10, rcx
  mov eax, $D5C
  syscall
end;

procedure Syscall_D5D; stdcall;
asm
  mov r10, rcx
  mov eax, $D5D
  syscall
end;

procedure Syscall_D5E; stdcall;
asm
  mov r10, rcx
  mov eax, $D5E
  syscall
end;

procedure Syscall_D5F; stdcall;
asm
  mov r10, rcx
  mov eax, $D5F
  syscall
end;

procedure Syscall_D60; stdcall;
asm
  mov r10, rcx
  mov eax, $D60
  syscall
end;

procedure Syscall_D61; stdcall;
asm
  mov r10, rcx
  mov eax, $D61
  syscall
end;

procedure Syscall_D62; stdcall;
asm
  mov r10, rcx
  mov eax, $D62
  syscall
end;

procedure Syscall_D63; stdcall;
asm
  mov r10, rcx
  mov eax, $D63
  syscall
end;

procedure Syscall_D64; stdcall;
asm
  mov r10, rcx
  mov eax, $D64
  syscall
end;

procedure Syscall_D65; stdcall;
asm
  mov r10, rcx
  mov eax, $D65
  syscall
end;

procedure Syscall_D66; stdcall;
asm
  mov r10, rcx
  mov eax, $D66
  syscall
end;

procedure Syscall_D67; stdcall;
asm
  mov r10, rcx
  mov eax, $D67
  syscall
end;

procedure Syscall_D68; stdcall;
asm
  mov r10, rcx
  mov eax, $D68
  syscall
end;

procedure Syscall_D69; stdcall;
asm
  mov r10, rcx
  mov eax, $D69
  syscall
end;

procedure Syscall_D6A; stdcall;
asm
  mov r10, rcx
  mov eax, $D6A
  syscall
end;

procedure Syscall_D6B; stdcall;
asm
  mov r10, rcx
  mov eax, $D6B
  syscall
end;

procedure Syscall_D6C; stdcall;
asm
  mov r10, rcx
  mov eax, $D6C
  syscall
end;

procedure Syscall_D6D; stdcall;
asm
  mov r10, rcx
  mov eax, $D6D
  syscall
end;

procedure Syscall_D6E; stdcall;
asm
  mov r10, rcx
  mov eax, $D6E
  syscall
end;

procedure Syscall_D6F; stdcall;
asm
  mov r10, rcx
  mov eax, $D6F
  syscall
end;

procedure Syscall_D70; stdcall;
asm
  mov r10, rcx
  mov eax, $D70
  syscall
end;

procedure Syscall_D71; stdcall;
asm
  mov r10, rcx
  mov eax, $D71
  syscall
end;

procedure Syscall_D72; stdcall;
asm
  mov r10, rcx
  mov eax, $D72
  syscall
end;

procedure Syscall_D73; stdcall;
asm
  mov r10, rcx
  mov eax, $D73
  syscall
end;

procedure Syscall_D74; stdcall;
asm
  mov r10, rcx
  mov eax, $D74
  syscall
end;

procedure Syscall_D75; stdcall;
asm
  mov r10, rcx
  mov eax, $D75
  syscall
end;

procedure Syscall_D76; stdcall;
asm
  mov r10, rcx
  mov eax, $D76
  syscall
end;

procedure Syscall_D77; stdcall;
asm
  mov r10, rcx
  mov eax, $D77
  syscall
end;

procedure Syscall_D78; stdcall;
asm
  mov r10, rcx
  mov eax, $D78
  syscall
end;

procedure Syscall_D79; stdcall;
asm
  mov r10, rcx
  mov eax, $D79
  syscall
end;

procedure Syscall_D7A; stdcall;
asm
  mov r10, rcx
  mov eax, $D7A
  syscall
end;

procedure Syscall_D7B; stdcall;
asm
  mov r10, rcx
  mov eax, $D7B
  syscall
end;

procedure Syscall_D7C; stdcall;
asm
  mov r10, rcx
  mov eax, $D7C
  syscall
end;

procedure Syscall_D7D; stdcall;
asm
  mov r10, rcx
  mov eax, $D7D
  syscall
end;

procedure Syscall_D7E; stdcall;
asm
  mov r10, rcx
  mov eax, $D7E
  syscall
end;

procedure Syscall_D7F; stdcall;
asm
  mov r10, rcx
  mov eax, $D7F
  syscall
end;

procedure Syscall_D80; stdcall;
asm
  mov r10, rcx
  mov eax, $D80
  syscall
end;

procedure Syscall_D81; stdcall;
asm
  mov r10, rcx
  mov eax, $D81
  syscall
end;

procedure Syscall_D82; stdcall;
asm
  mov r10, rcx
  mov eax, $D82
  syscall
end;

procedure Syscall_D83; stdcall;
asm
  mov r10, rcx
  mov eax, $D83
  syscall
end;

procedure Syscall_D84; stdcall;
asm
  mov r10, rcx
  mov eax, $D84
  syscall
end;

procedure Syscall_D85; stdcall;
asm
  mov r10, rcx
  mov eax, $D85
  syscall
end;

procedure Syscall_D86; stdcall;
asm
  mov r10, rcx
  mov eax, $D86
  syscall
end;

procedure Syscall_D87; stdcall;
asm
  mov r10, rcx
  mov eax, $D87
  syscall
end;

procedure Syscall_D88; stdcall;
asm
  mov r10, rcx
  mov eax, $D88
  syscall
end;

procedure Syscall_D89; stdcall;
asm
  mov r10, rcx
  mov eax, $D89
  syscall
end;

procedure Syscall_D8A; stdcall;
asm
  mov r10, rcx
  mov eax, $D8A
  syscall
end;

procedure Syscall_D8B; stdcall;
asm
  mov r10, rcx
  mov eax, $D8B
  syscall
end;

procedure Syscall_D8C; stdcall;
asm
  mov r10, rcx
  mov eax, $D8C
  syscall
end;

procedure Syscall_D8D; stdcall;
asm
  mov r10, rcx
  mov eax, $D8D
  syscall
end;

procedure Syscall_D8E; stdcall;
asm
  mov r10, rcx
  mov eax, $D8E
  syscall
end;

procedure Syscall_D8F; stdcall;
asm
  mov r10, rcx
  mov eax, $D8F
  syscall
end;

procedure Syscall_D90; stdcall;
asm
  mov r10, rcx
  mov eax, $D90
  syscall
end;

procedure Syscall_D91; stdcall;
asm
  mov r10, rcx
  mov eax, $D91
  syscall
end;

procedure Syscall_D92; stdcall;
asm
  mov r10, rcx
  mov eax, $D92
  syscall
end;

procedure Syscall_D93; stdcall;
asm
  mov r10, rcx
  mov eax, $D93
  syscall
end;

procedure Syscall_D94; stdcall;
asm
  mov r10, rcx
  mov eax, $D94
  syscall
end;

procedure Syscall_D95; stdcall;
asm
  mov r10, rcx
  mov eax, $D95
  syscall
end;

procedure Syscall_D96; stdcall;
asm
  mov r10, rcx
  mov eax, $D96
  syscall
end;

procedure Syscall_D97; stdcall;
asm
  mov r10, rcx
  mov eax, $D97
  syscall
end;

procedure Syscall_D98; stdcall;
asm
  mov r10, rcx
  mov eax, $D98
  syscall
end;

procedure Syscall_D99; stdcall;
asm
  mov r10, rcx
  mov eax, $D99
  syscall
end;

procedure Syscall_D9A; stdcall;
asm
  mov r10, rcx
  mov eax, $D9A
  syscall
end;

procedure Syscall_D9B; stdcall;
asm
  mov r10, rcx
  mov eax, $D9B
  syscall
end;

procedure Syscall_D9C; stdcall;
asm
  mov r10, rcx
  mov eax, $D9C
  syscall
end;

procedure Syscall_D9D; stdcall;
asm
  mov r10, rcx
  mov eax, $D9D
  syscall
end;

procedure Syscall_D9E; stdcall;
asm
  mov r10, rcx
  mov eax, $D9E
  syscall
end;

procedure Syscall_D9F; stdcall;
asm
  mov r10, rcx
  mov eax, $D9F
  syscall
end;

procedure Syscall_DA0; stdcall;
asm
  mov r10, rcx
  mov eax, $DA0
  syscall
end;

procedure Syscall_DA1; stdcall;
asm
  mov r10, rcx
  mov eax, $DA1
  syscall
end;

procedure Syscall_DA2; stdcall;
asm
  mov r10, rcx
  mov eax, $DA2
  syscall
end;

procedure Syscall_DA3; stdcall;
asm
  mov r10, rcx
  mov eax, $DA3
  syscall
end;

procedure Syscall_DA4; stdcall;
asm
  mov r10, rcx
  mov eax, $DA4
  syscall
end;

procedure Syscall_DA5; stdcall;
asm
  mov r10, rcx
  mov eax, $DA5
  syscall
end;

procedure Syscall_DA6; stdcall;
asm
  mov r10, rcx
  mov eax, $DA6
  syscall
end;

procedure Syscall_DA7; stdcall;
asm
  mov r10, rcx
  mov eax, $DA7
  syscall
end;

procedure Syscall_DA8; stdcall;
asm
  mov r10, rcx
  mov eax, $DA8
  syscall
end;

procedure Syscall_DA9; stdcall;
asm
  mov r10, rcx
  mov eax, $DA9
  syscall
end;

procedure Syscall_DAA; stdcall;
asm
  mov r10, rcx
  mov eax, $DAA
  syscall
end;

procedure Syscall_DAB; stdcall;
asm
  mov r10, rcx
  mov eax, $DAB
  syscall
end;

procedure Syscall_DAC; stdcall;
asm
  mov r10, rcx
  mov eax, $DAC
  syscall
end;

procedure Syscall_DAD; stdcall;
asm
  mov r10, rcx
  mov eax, $DAD
  syscall
end;

procedure Syscall_DAE; stdcall;
asm
  mov r10, rcx
  mov eax, $DAE
  syscall
end;

procedure Syscall_DAF; stdcall;
asm
  mov r10, rcx
  mov eax, $DAF
  syscall
end;

procedure Syscall_DB0; stdcall;
asm
  mov r10, rcx
  mov eax, $DB0
  syscall
end;

procedure Syscall_DB1; stdcall;
asm
  mov r10, rcx
  mov eax, $DB1
  syscall
end;

procedure Syscall_DB2; stdcall;
asm
  mov r10, rcx
  mov eax, $DB2
  syscall
end;

procedure Syscall_DB3; stdcall;
asm
  mov r10, rcx
  mov eax, $DB3
  syscall
end;

procedure Syscall_DB4; stdcall;
asm
  mov r10, rcx
  mov eax, $DB4
  syscall
end;

procedure Syscall_DB5; stdcall;
asm
  mov r10, rcx
  mov eax, $DB5
  syscall
end;

procedure Syscall_DB6; stdcall;
asm
  mov r10, rcx
  mov eax, $DB6
  syscall
end;

procedure Syscall_DB7; stdcall;
asm
  mov r10, rcx
  mov eax, $DB7
  syscall
end;

procedure Syscall_DB8; stdcall;
asm
  mov r10, rcx
  mov eax, $DB8
  syscall
end;

procedure Syscall_DB9; stdcall;
asm
  mov r10, rcx
  mov eax, $DB9
  syscall
end;

procedure Syscall_DBA; stdcall;
asm
  mov r10, rcx
  mov eax, $DBA
  syscall
end;

procedure Syscall_DBB; stdcall;
asm
  mov r10, rcx
  mov eax, $DBB
  syscall
end;

procedure Syscall_DBC; stdcall;
asm
  mov r10, rcx
  mov eax, $DBC
  syscall
end;

procedure Syscall_DBD; stdcall;
asm
  mov r10, rcx
  mov eax, $DBD
  syscall
end;

procedure Syscall_DBE; stdcall;
asm
  mov r10, rcx
  mov eax, $DBE
  syscall
end;

procedure Syscall_DBF; stdcall;
asm
  mov r10, rcx
  mov eax, $DBF
  syscall
end;

procedure Syscall_DC0; stdcall;
asm
  mov r10, rcx
  mov eax, $DC0
  syscall
end;

procedure Syscall_DC1; stdcall;
asm
  mov r10, rcx
  mov eax, $DC1
  syscall
end;

procedure Syscall_DC2; stdcall;
asm
  mov r10, rcx
  mov eax, $DC2
  syscall
end;

procedure Syscall_DC3; stdcall;
asm
  mov r10, rcx
  mov eax, $DC3
  syscall
end;

procedure Syscall_DC4; stdcall;
asm
  mov r10, rcx
  mov eax, $DC4
  syscall
end;

procedure Syscall_DC5; stdcall;
asm
  mov r10, rcx
  mov eax, $DC5
  syscall
end;

procedure Syscall_DC6; stdcall;
asm
  mov r10, rcx
  mov eax, $DC6
  syscall
end;

procedure Syscall_DC7; stdcall;
asm
  mov r10, rcx
  mov eax, $DC7
  syscall
end;

procedure Syscall_DC8; stdcall;
asm
  mov r10, rcx
  mov eax, $DC8
  syscall
end;

procedure Syscall_DC9; stdcall;
asm
  mov r10, rcx
  mov eax, $DC9
  syscall
end;

procedure Syscall_DCA; stdcall;
asm
  mov r10, rcx
  mov eax, $DCA
  syscall
end;

procedure Syscall_DCB; stdcall;
asm
  mov r10, rcx
  mov eax, $DCB
  syscall
end;

procedure Syscall_DCC; stdcall;
asm
  mov r10, rcx
  mov eax, $DCC
  syscall
end;

procedure Syscall_DCD; stdcall;
asm
  mov r10, rcx
  mov eax, $DCD
  syscall
end;

procedure Syscall_DCE; stdcall;
asm
  mov r10, rcx
  mov eax, $DCE
  syscall
end;

procedure Syscall_DCF; stdcall;
asm
  mov r10, rcx
  mov eax, $DCF
  syscall
end;

procedure Syscall_DD0; stdcall;
asm
  mov r10, rcx
  mov eax, $DD0
  syscall
end;

procedure Syscall_DD1; stdcall;
asm
  mov r10, rcx
  mov eax, $DD1
  syscall
end;

procedure Syscall_DD2; stdcall;
asm
  mov r10, rcx
  mov eax, $DD2
  syscall
end;

procedure Syscall_DD3; stdcall;
asm
  mov r10, rcx
  mov eax, $DD3
  syscall
end;

procedure Syscall_DD4; stdcall;
asm
  mov r10, rcx
  mov eax, $DD4
  syscall
end;

procedure Syscall_DD5; stdcall;
asm
  mov r10, rcx
  mov eax, $DD5
  syscall
end;

procedure Syscall_DD6; stdcall;
asm
  mov r10, rcx
  mov eax, $DD6
  syscall
end;

procedure Syscall_DD7; stdcall;
asm
  mov r10, rcx
  mov eax, $DD7
  syscall
end;

procedure Syscall_DD8; stdcall;
asm
  mov r10, rcx
  mov eax, $DD8
  syscall
end;

procedure Syscall_DD9; stdcall;
asm
  mov r10, rcx
  mov eax, $DD9
  syscall
end;

procedure Syscall_DDA; stdcall;
asm
  mov r10, rcx
  mov eax, $DDA
  syscall
end;

procedure Syscall_DDB; stdcall;
asm
  mov r10, rcx
  mov eax, $DDB
  syscall
end;

procedure Syscall_DDC; stdcall;
asm
  mov r10, rcx
  mov eax, $DDC
  syscall
end;

procedure Syscall_DDD; stdcall;
asm
  mov r10, rcx
  mov eax, $DDD
  syscall
end;

procedure Syscall_DDE; stdcall;
asm
  mov r10, rcx
  mov eax, $DDE
  syscall
end;

procedure Syscall_DDF; stdcall;
asm
  mov r10, rcx
  mov eax, $DDF
  syscall
end;

procedure Syscall_DE0; stdcall;
asm
  mov r10, rcx
  mov eax, $DE0
  syscall
end;

procedure Syscall_DE1; stdcall;
asm
  mov r10, rcx
  mov eax, $DE1
  syscall
end;

procedure Syscall_DE2; stdcall;
asm
  mov r10, rcx
  mov eax, $DE2
  syscall
end;

procedure Syscall_DE3; stdcall;
asm
  mov r10, rcx
  mov eax, $DE3
  syscall
end;

procedure Syscall_DE4; stdcall;
asm
  mov r10, rcx
  mov eax, $DE4
  syscall
end;

procedure Syscall_DE5; stdcall;
asm
  mov r10, rcx
  mov eax, $DE5
  syscall
end;

procedure Syscall_DE6; stdcall;
asm
  mov r10, rcx
  mov eax, $DE6
  syscall
end;

procedure Syscall_DE7; stdcall;
asm
  mov r10, rcx
  mov eax, $DE7
  syscall
end;

procedure Syscall_DE8; stdcall;
asm
  mov r10, rcx
  mov eax, $DE8
  syscall
end;

procedure Syscall_DE9; stdcall;
asm
  mov r10, rcx
  mov eax, $DE9
  syscall
end;

procedure Syscall_DEA; stdcall;
asm
  mov r10, rcx
  mov eax, $DEA
  syscall
end;

procedure Syscall_DEB; stdcall;
asm
  mov r10, rcx
  mov eax, $DEB
  syscall
end;

procedure Syscall_DEC; stdcall;
asm
  mov r10, rcx
  mov eax, $DEC
  syscall
end;

procedure Syscall_DED; stdcall;
asm
  mov r10, rcx
  mov eax, $DED
  syscall
end;

procedure Syscall_DEE; stdcall;
asm
  mov r10, rcx
  mov eax, $DEE
  syscall
end;

procedure Syscall_DEF; stdcall;
asm
  mov r10, rcx
  mov eax, $DEF
  syscall
end;

procedure Syscall_DF0; stdcall;
asm
  mov r10, rcx
  mov eax, $DF0
  syscall
end;

procedure Syscall_DF1; stdcall;
asm
  mov r10, rcx
  mov eax, $DF1
  syscall
end;

procedure Syscall_DF2; stdcall;
asm
  mov r10, rcx
  mov eax, $DF2
  syscall
end;

procedure Syscall_DF3; stdcall;
asm
  mov r10, rcx
  mov eax, $DF3
  syscall
end;

procedure Syscall_DF4; stdcall;
asm
  mov r10, rcx
  mov eax, $DF4
  syscall
end;

procedure Syscall_DF5; stdcall;
asm
  mov r10, rcx
  mov eax, $DF5
  syscall
end;

procedure Syscall_DF6; stdcall;
asm
  mov r10, rcx
  mov eax, $DF6
  syscall
end;

procedure Syscall_DF7; stdcall;
asm
  mov r10, rcx
  mov eax, $DF7
  syscall
end;

procedure Syscall_DF8; stdcall;
asm
  mov r10, rcx
  mov eax, $DF8
  syscall
end;

procedure Syscall_DF9; stdcall;
asm
  mov r10, rcx
  mov eax, $DF9
  syscall
end;

procedure Syscall_DFA; stdcall;
asm
  mov r10, rcx
  mov eax, $DFA
  syscall
end;

procedure Syscall_DFB; stdcall;
asm
  mov r10, rcx
  mov eax, $DFB
  syscall
end;

procedure Syscall_DFC; stdcall;
asm
  mov r10, rcx
  mov eax, $DFC
  syscall
end;

procedure Syscall_DFD; stdcall;
asm
  mov r10, rcx
  mov eax, $DFD
  syscall
end;

procedure Syscall_DFE; stdcall;
asm
  mov r10, rcx
  mov eax, $DFE
  syscall
end;

procedure Syscall_DFF; stdcall;
asm
  mov r10, rcx
  mov eax, $DFF
  syscall
end;

procedure Syscall_E00; stdcall;
asm
  mov r10, rcx
  mov eax, $E00
  syscall
end;

procedure Syscall_E01; stdcall;
asm
  mov r10, rcx
  mov eax, $E01
  syscall
end;

procedure Syscall_E02; stdcall;
asm
  mov r10, rcx
  mov eax, $E02
  syscall
end;

procedure Syscall_E03; stdcall;
asm
  mov r10, rcx
  mov eax, $E03
  syscall
end;

procedure Syscall_E04; stdcall;
asm
  mov r10, rcx
  mov eax, $E04
  syscall
end;

procedure Syscall_E05; stdcall;
asm
  mov r10, rcx
  mov eax, $E05
  syscall
end;

procedure Syscall_E06; stdcall;
asm
  mov r10, rcx
  mov eax, $E06
  syscall
end;

procedure Syscall_E07; stdcall;
asm
  mov r10, rcx
  mov eax, $E07
  syscall
end;

procedure Syscall_E08; stdcall;
asm
  mov r10, rcx
  mov eax, $E08
  syscall
end;

procedure Syscall_E09; stdcall;
asm
  mov r10, rcx
  mov eax, $E09
  syscall
end;

procedure Syscall_E0A; stdcall;
asm
  mov r10, rcx
  mov eax, $E0A
  syscall
end;

procedure Syscall_E0B; stdcall;
asm
  mov r10, rcx
  mov eax, $E0B
  syscall
end;

procedure Syscall_E0C; stdcall;
asm
  mov r10, rcx
  mov eax, $E0C
  syscall
end;

procedure Syscall_E0D; stdcall;
asm
  mov r10, rcx
  mov eax, $E0D
  syscall
end;

procedure Syscall_E0E; stdcall;
asm
  mov r10, rcx
  mov eax, $E0E
  syscall
end;

procedure Syscall_E0F; stdcall;
asm
  mov r10, rcx
  mov eax, $E0F
  syscall
end;

procedure Syscall_E10; stdcall;
asm
  mov r10, rcx
  mov eax, $E10
  syscall
end;

procedure Syscall_E11; stdcall;
asm
  mov r10, rcx
  mov eax, $E11
  syscall
end;

procedure Syscall_E12; stdcall;
asm
  mov r10, rcx
  mov eax, $E12
  syscall
end;

procedure Syscall_E13; stdcall;
asm
  mov r10, rcx
  mov eax, $E13
  syscall
end;

procedure Syscall_E14; stdcall;
asm
  mov r10, rcx
  mov eax, $E14
  syscall
end;

procedure Syscall_E15; stdcall;
asm
  mov r10, rcx
  mov eax, $E15
  syscall
end;

procedure Syscall_E16; stdcall;
asm
  mov r10, rcx
  mov eax, $E16
  syscall
end;

procedure Syscall_E17; stdcall;
asm
  mov r10, rcx
  mov eax, $E17
  syscall
end;

procedure Syscall_E18; stdcall;
asm
  mov r10, rcx
  mov eax, $E18
  syscall
end;

procedure Syscall_E19; stdcall;
asm
  mov r10, rcx
  mov eax, $E19
  syscall
end;

procedure Syscall_E1A; stdcall;
asm
  mov r10, rcx
  mov eax, $E1A
  syscall
end;

procedure Syscall_E1B; stdcall;
asm
  mov r10, rcx
  mov eax, $E1B
  syscall
end;

procedure Syscall_E1C; stdcall;
asm
  mov r10, rcx
  mov eax, $E1C
  syscall
end;

procedure Syscall_E1D; stdcall;
asm
  mov r10, rcx
  mov eax, $E1D
  syscall
end;

procedure Syscall_E1E; stdcall;
asm
  mov r10, rcx
  mov eax, $E1E
  syscall
end;

procedure Syscall_E1F; stdcall;
asm
  mov r10, rcx
  mov eax, $E1F
  syscall
end;

procedure Syscall_E20; stdcall;
asm
  mov r10, rcx
  mov eax, $E20
  syscall
end;

procedure Syscall_E21; stdcall;
asm
  mov r10, rcx
  mov eax, $E21
  syscall
end;

procedure Syscall_E22; stdcall;
asm
  mov r10, rcx
  mov eax, $E22
  syscall
end;

procedure Syscall_E23; stdcall;
asm
  mov r10, rcx
  mov eax, $E23
  syscall
end;

procedure Syscall_E24; stdcall;
asm
  mov r10, rcx
  mov eax, $E24
  syscall
end;

procedure Syscall_E25; stdcall;
asm
  mov r10, rcx
  mov eax, $E25
  syscall
end;

procedure Syscall_E26; stdcall;
asm
  mov r10, rcx
  mov eax, $E26
  syscall
end;

procedure Syscall_E27; stdcall;
asm
  mov r10, rcx
  mov eax, $E27
  syscall
end;

procedure Syscall_E28; stdcall;
asm
  mov r10, rcx
  mov eax, $E28
  syscall
end;

procedure Syscall_E29; stdcall;
asm
  mov r10, rcx
  mov eax, $E29
  syscall
end;

procedure Syscall_E2A; stdcall;
asm
  mov r10, rcx
  mov eax, $E2A
  syscall
end;

procedure Syscall_E2B; stdcall;
asm
  mov r10, rcx
  mov eax, $E2B
  syscall
end;

procedure Syscall_E2C; stdcall;
asm
  mov r10, rcx
  mov eax, $E2C
  syscall
end;

procedure Syscall_E2D; stdcall;
asm
  mov r10, rcx
  mov eax, $E2D
  syscall
end;

procedure Syscall_E2E; stdcall;
asm
  mov r10, rcx
  mov eax, $E2E
  syscall
end;

procedure Syscall_E2F; stdcall;
asm
  mov r10, rcx
  mov eax, $E2F
  syscall
end;

procedure Syscall_E30; stdcall;
asm
  mov r10, rcx
  mov eax, $E30
  syscall
end;

procedure Syscall_E31; stdcall;
asm
  mov r10, rcx
  mov eax, $E31
  syscall
end;

procedure Syscall_E32; stdcall;
asm
  mov r10, rcx
  mov eax, $E32
  syscall
end;

procedure Syscall_E33; stdcall;
asm
  mov r10, rcx
  mov eax, $E33
  syscall
end;

procedure Syscall_E34; stdcall;
asm
  mov r10, rcx
  mov eax, $E34
  syscall
end;

procedure Syscall_E35; stdcall;
asm
  mov r10, rcx
  mov eax, $E35
  syscall
end;

procedure Syscall_E36; stdcall;
asm
  mov r10, rcx
  mov eax, $E36
  syscall
end;

procedure Syscall_E37; stdcall;
asm
  mov r10, rcx
  mov eax, $E37
  syscall
end;

procedure Syscall_E38; stdcall;
asm
  mov r10, rcx
  mov eax, $E38
  syscall
end;

procedure Syscall_E39; stdcall;
asm
  mov r10, rcx
  mov eax, $E39
  syscall
end;

procedure Syscall_E3A; stdcall;
asm
  mov r10, rcx
  mov eax, $E3A
  syscall
end;

procedure Syscall_E3B; stdcall;
asm
  mov r10, rcx
  mov eax, $E3B
  syscall
end;

procedure Syscall_E3C; stdcall;
asm
  mov r10, rcx
  mov eax, $E3C
  syscall
end;

procedure Syscall_E3D; stdcall;
asm
  mov r10, rcx
  mov eax, $E3D
  syscall
end;

procedure Syscall_E3E; stdcall;
asm
  mov r10, rcx
  mov eax, $E3E
  syscall
end;

procedure Syscall_E3F; stdcall;
asm
  mov r10, rcx
  mov eax, $E3F
  syscall
end;

procedure Syscall_E40; stdcall;
asm
  mov r10, rcx
  mov eax, $E40
  syscall
end;

procedure Syscall_E41; stdcall;
asm
  mov r10, rcx
  mov eax, $E41
  syscall
end;

procedure Syscall_E42; stdcall;
asm
  mov r10, rcx
  mov eax, $E42
  syscall
end;

procedure Syscall_E43; stdcall;
asm
  mov r10, rcx
  mov eax, $E43
  syscall
end;

procedure Syscall_E44; stdcall;
asm
  mov r10, rcx
  mov eax, $E44
  syscall
end;

procedure Syscall_E45; stdcall;
asm
  mov r10, rcx
  mov eax, $E45
  syscall
end;

procedure Syscall_E46; stdcall;
asm
  mov r10, rcx
  mov eax, $E46
  syscall
end;

procedure Syscall_E47; stdcall;
asm
  mov r10, rcx
  mov eax, $E47
  syscall
end;

procedure Syscall_E48; stdcall;
asm
  mov r10, rcx
  mov eax, $E48
  syscall
end;

procedure Syscall_E49; stdcall;
asm
  mov r10, rcx
  mov eax, $E49
  syscall
end;

procedure Syscall_E4A; stdcall;
asm
  mov r10, rcx
  mov eax, $E4A
  syscall
end;

procedure Syscall_E4B; stdcall;
asm
  mov r10, rcx
  mov eax, $E4B
  syscall
end;

procedure Syscall_E4C; stdcall;
asm
  mov r10, rcx
  mov eax, $E4C
  syscall
end;

procedure Syscall_E4D; stdcall;
asm
  mov r10, rcx
  mov eax, $E4D
  syscall
end;

procedure Syscall_E4E; stdcall;
asm
  mov r10, rcx
  mov eax, $E4E
  syscall
end;

procedure Syscall_E4F; stdcall;
asm
  mov r10, rcx
  mov eax, $E4F
  syscall
end;

procedure Syscall_E50; stdcall;
asm
  mov r10, rcx
  mov eax, $E50
  syscall
end;

procedure Syscall_E51; stdcall;
asm
  mov r10, rcx
  mov eax, $E51
  syscall
end;

procedure Syscall_E52; stdcall;
asm
  mov r10, rcx
  mov eax, $E52
  syscall
end;

procedure Syscall_E53; stdcall;
asm
  mov r10, rcx
  mov eax, $E53
  syscall
end;

procedure Syscall_E54; stdcall;
asm
  mov r10, rcx
  mov eax, $E54
  syscall
end;

procedure Syscall_E55; stdcall;
asm
  mov r10, rcx
  mov eax, $E55
  syscall
end;

procedure Syscall_E56; stdcall;
asm
  mov r10, rcx
  mov eax, $E56
  syscall
end;

procedure Syscall_E57; stdcall;
asm
  mov r10, rcx
  mov eax, $E57
  syscall
end;

procedure Syscall_E58; stdcall;
asm
  mov r10, rcx
  mov eax, $E58
  syscall
end;

procedure Syscall_E59; stdcall;
asm
  mov r10, rcx
  mov eax, $E59
  syscall
end;

procedure Syscall_E5A; stdcall;
asm
  mov r10, rcx
  mov eax, $E5A
  syscall
end;

procedure Syscall_E5B; stdcall;
asm
  mov r10, rcx
  mov eax, $E5B
  syscall
end;

procedure Syscall_E5C; stdcall;
asm
  mov r10, rcx
  mov eax, $E5C
  syscall
end;

procedure Syscall_E5D; stdcall;
asm
  mov r10, rcx
  mov eax, $E5D
  syscall
end;

procedure Syscall_E5E; stdcall;
asm
  mov r10, rcx
  mov eax, $E5E
  syscall
end;

procedure Syscall_E5F; stdcall;
asm
  mov r10, rcx
  mov eax, $E5F
  syscall
end;

procedure Syscall_E60; stdcall;
asm
  mov r10, rcx
  mov eax, $E60
  syscall
end;

procedure Syscall_E61; stdcall;
asm
  mov r10, rcx
  mov eax, $E61
  syscall
end;

procedure Syscall_E62; stdcall;
asm
  mov r10, rcx
  mov eax, $E62
  syscall
end;

procedure Syscall_E63; stdcall;
asm
  mov r10, rcx
  mov eax, $E63
  syscall
end;

procedure Syscall_E64; stdcall;
asm
  mov r10, rcx
  mov eax, $E64
  syscall
end;

procedure Syscall_E65; stdcall;
asm
  mov r10, rcx
  mov eax, $E65
  syscall
end;

procedure Syscall_E66; stdcall;
asm
  mov r10, rcx
  mov eax, $E66
  syscall
end;

procedure Syscall_E67; stdcall;
asm
  mov r10, rcx
  mov eax, $E67
  syscall
end;

procedure Syscall_E68; stdcall;
asm
  mov r10, rcx
  mov eax, $E68
  syscall
end;

procedure Syscall_E69; stdcall;
asm
  mov r10, rcx
  mov eax, $E69
  syscall
end;

procedure Syscall_E6A; stdcall;
asm
  mov r10, rcx
  mov eax, $E6A
  syscall
end;

procedure Syscall_E6B; stdcall;
asm
  mov r10, rcx
  mov eax, $E6B
  syscall
end;

procedure Syscall_E6C; stdcall;
asm
  mov r10, rcx
  mov eax, $E6C
  syscall
end;

procedure Syscall_E6D; stdcall;
asm
  mov r10, rcx
  mov eax, $E6D
  syscall
end;

procedure Syscall_E6E; stdcall;
asm
  mov r10, rcx
  mov eax, $E6E
  syscall
end;

procedure Syscall_E6F; stdcall;
asm
  mov r10, rcx
  mov eax, $E6F
  syscall
end;

procedure Syscall_E70; stdcall;
asm
  mov r10, rcx
  mov eax, $E70
  syscall
end;

procedure Syscall_E71; stdcall;
asm
  mov r10, rcx
  mov eax, $E71
  syscall
end;

procedure Syscall_E72; stdcall;
asm
  mov r10, rcx
  mov eax, $E72
  syscall
end;

procedure Syscall_E73; stdcall;
asm
  mov r10, rcx
  mov eax, $E73
  syscall
end;

procedure Syscall_E74; stdcall;
asm
  mov r10, rcx
  mov eax, $E74
  syscall
end;

procedure Syscall_E75; stdcall;
asm
  mov r10, rcx
  mov eax, $E75
  syscall
end;

procedure Syscall_E76; stdcall;
asm
  mov r10, rcx
  mov eax, $E76
  syscall
end;

procedure Syscall_E77; stdcall;
asm
  mov r10, rcx
  mov eax, $E77
  syscall
end;

procedure Syscall_E78; stdcall;
asm
  mov r10, rcx
  mov eax, $E78
  syscall
end;

procedure Syscall_E79; stdcall;
asm
  mov r10, rcx
  mov eax, $E79
  syscall
end;

procedure Syscall_E7A; stdcall;
asm
  mov r10, rcx
  mov eax, $E7A
  syscall
end;

procedure Syscall_E7B; stdcall;
asm
  mov r10, rcx
  mov eax, $E7B
  syscall
end;

procedure Syscall_E7C; stdcall;
asm
  mov r10, rcx
  mov eax, $E7C
  syscall
end;

procedure Syscall_E7D; stdcall;
asm
  mov r10, rcx
  mov eax, $E7D
  syscall
end;

procedure Syscall_E7E; stdcall;
asm
  mov r10, rcx
  mov eax, $E7E
  syscall
end;

procedure Syscall_E7F; stdcall;
asm
  mov r10, rcx
  mov eax, $E7F
  syscall
end;

procedure Syscall_E80; stdcall;
asm
  mov r10, rcx
  mov eax, $E80
  syscall
end;

procedure Syscall_E81; stdcall;
asm
  mov r10, rcx
  mov eax, $E81
  syscall
end;

procedure Syscall_E82; stdcall;
asm
  mov r10, rcx
  mov eax, $E82
  syscall
end;

procedure Syscall_E83; stdcall;
asm
  mov r10, rcx
  mov eax, $E83
  syscall
end;

procedure Syscall_E84; stdcall;
asm
  mov r10, rcx
  mov eax, $E84
  syscall
end;

procedure Syscall_E85; stdcall;
asm
  mov r10, rcx
  mov eax, $E85
  syscall
end;

procedure Syscall_E86; stdcall;
asm
  mov r10, rcx
  mov eax, $E86
  syscall
end;

procedure Syscall_E87; stdcall;
asm
  mov r10, rcx
  mov eax, $E87
  syscall
end;

procedure Syscall_E88; stdcall;
asm
  mov r10, rcx
  mov eax, $E88
  syscall
end;

procedure Syscall_E89; stdcall;
asm
  mov r10, rcx
  mov eax, $E89
  syscall
end;

procedure Syscall_E8A; stdcall;
asm
  mov r10, rcx
  mov eax, $E8A
  syscall
end;

procedure Syscall_E8B; stdcall;
asm
  mov r10, rcx
  mov eax, $E8B
  syscall
end;

procedure Syscall_E8C; stdcall;
asm
  mov r10, rcx
  mov eax, $E8C
  syscall
end;

procedure Syscall_E8D; stdcall;
asm
  mov r10, rcx
  mov eax, $E8D
  syscall
end;

procedure Syscall_E8E; stdcall;
asm
  mov r10, rcx
  mov eax, $E8E
  syscall
end;

procedure Syscall_E8F; stdcall;
asm
  mov r10, rcx
  mov eax, $E8F
  syscall
end;

procedure Syscall_E90; stdcall;
asm
  mov r10, rcx
  mov eax, $E90
  syscall
end;

procedure Syscall_E91; stdcall;
asm
  mov r10, rcx
  mov eax, $E91
  syscall
end;

procedure Syscall_E92; stdcall;
asm
  mov r10, rcx
  mov eax, $E92
  syscall
end;

procedure Syscall_E93; stdcall;
asm
  mov r10, rcx
  mov eax, $E93
  syscall
end;

procedure Syscall_E94; stdcall;
asm
  mov r10, rcx
  mov eax, $E94
  syscall
end;

procedure Syscall_E95; stdcall;
asm
  mov r10, rcx
  mov eax, $E95
  syscall
end;

procedure Syscall_E96; stdcall;
asm
  mov r10, rcx
  mov eax, $E96
  syscall
end;

procedure Syscall_E97; stdcall;
asm
  mov r10, rcx
  mov eax, $E97
  syscall
end;

procedure Syscall_E98; stdcall;
asm
  mov r10, rcx
  mov eax, $E98
  syscall
end;

procedure Syscall_E99; stdcall;
asm
  mov r10, rcx
  mov eax, $E99
  syscall
end;

procedure Syscall_E9A; stdcall;
asm
  mov r10, rcx
  mov eax, $E9A
  syscall
end;

procedure Syscall_E9B; stdcall;
asm
  mov r10, rcx
  mov eax, $E9B
  syscall
end;

procedure Syscall_E9C; stdcall;
asm
  mov r10, rcx
  mov eax, $E9C
  syscall
end;

procedure Syscall_E9D; stdcall;
asm
  mov r10, rcx
  mov eax, $E9D
  syscall
end;

procedure Syscall_E9E; stdcall;
asm
  mov r10, rcx
  mov eax, $E9E
  syscall
end;

procedure Syscall_E9F; stdcall;
asm
  mov r10, rcx
  mov eax, $E9F
  syscall
end;

procedure Syscall_EA0; stdcall;
asm
  mov r10, rcx
  mov eax, $EA0
  syscall
end;

procedure Syscall_EA1; stdcall;
asm
  mov r10, rcx
  mov eax, $EA1
  syscall
end;

procedure Syscall_EA2; stdcall;
asm
  mov r10, rcx
  mov eax, $EA2
  syscall
end;

procedure Syscall_EA3; stdcall;
asm
  mov r10, rcx
  mov eax, $EA3
  syscall
end;

procedure Syscall_EA4; stdcall;
asm
  mov r10, rcx
  mov eax, $EA4
  syscall
end;

procedure Syscall_EA5; stdcall;
asm
  mov r10, rcx
  mov eax, $EA5
  syscall
end;

procedure Syscall_EA6; stdcall;
asm
  mov r10, rcx
  mov eax, $EA6
  syscall
end;

procedure Syscall_EA7; stdcall;
asm
  mov r10, rcx
  mov eax, $EA7
  syscall
end;

procedure Syscall_EA8; stdcall;
asm
  mov r10, rcx
  mov eax, $EA8
  syscall
end;

procedure Syscall_EA9; stdcall;
asm
  mov r10, rcx
  mov eax, $EA9
  syscall
end;

procedure Syscall_EAA; stdcall;
asm
  mov r10, rcx
  mov eax, $EAA
  syscall
end;

procedure Syscall_EAB; stdcall;
asm
  mov r10, rcx
  mov eax, $EAB
  syscall
end;

procedure Syscall_EAC; stdcall;
asm
  mov r10, rcx
  mov eax, $EAC
  syscall
end;

procedure Syscall_EAD; stdcall;
asm
  mov r10, rcx
  mov eax, $EAD
  syscall
end;

procedure Syscall_EAE; stdcall;
asm
  mov r10, rcx
  mov eax, $EAE
  syscall
end;

procedure Syscall_EAF; stdcall;
asm
  mov r10, rcx
  mov eax, $EAF
  syscall
end;

procedure Syscall_EB0; stdcall;
asm
  mov r10, rcx
  mov eax, $EB0
  syscall
end;

procedure Syscall_EB1; stdcall;
asm
  mov r10, rcx
  mov eax, $EB1
  syscall
end;

procedure Syscall_EB2; stdcall;
asm
  mov r10, rcx
  mov eax, $EB2
  syscall
end;

procedure Syscall_EB3; stdcall;
asm
  mov r10, rcx
  mov eax, $EB3
  syscall
end;

procedure Syscall_EB4; stdcall;
asm
  mov r10, rcx
  mov eax, $EB4
  syscall
end;

procedure Syscall_EB5; stdcall;
asm
  mov r10, rcx
  mov eax, $EB5
  syscall
end;

procedure Syscall_EB6; stdcall;
asm
  mov r10, rcx
  mov eax, $EB6
  syscall
end;

procedure Syscall_EB7; stdcall;
asm
  mov r10, rcx
  mov eax, $EB7
  syscall
end;

procedure Syscall_EB8; stdcall;
asm
  mov r10, rcx
  mov eax, $EB8
  syscall
end;

procedure Syscall_EB9; stdcall;
asm
  mov r10, rcx
  mov eax, $EB9
  syscall
end;

procedure Syscall_EBA; stdcall;
asm
  mov r10, rcx
  mov eax, $EBA
  syscall
end;

procedure Syscall_EBB; stdcall;
asm
  mov r10, rcx
  mov eax, $EBB
  syscall
end;

procedure Syscall_EBC; stdcall;
asm
  mov r10, rcx
  mov eax, $EBC
  syscall
end;

procedure Syscall_EBD; stdcall;
asm
  mov r10, rcx
  mov eax, $EBD
  syscall
end;

procedure Syscall_EBE; stdcall;
asm
  mov r10, rcx
  mov eax, $EBE
  syscall
end;

procedure Syscall_EBF; stdcall;
asm
  mov r10, rcx
  mov eax, $EBF
  syscall
end;

procedure Syscall_EC0; stdcall;
asm
  mov r10, rcx
  mov eax, $EC0
  syscall
end;

procedure Syscall_EC1; stdcall;
asm
  mov r10, rcx
  mov eax, $EC1
  syscall
end;

procedure Syscall_EC2; stdcall;
asm
  mov r10, rcx
  mov eax, $EC2
  syscall
end;

procedure Syscall_EC3; stdcall;
asm
  mov r10, rcx
  mov eax, $EC3
  syscall
end;

procedure Syscall_EC4; stdcall;
asm
  mov r10, rcx
  mov eax, $EC4
  syscall
end;

procedure Syscall_EC5; stdcall;
asm
  mov r10, rcx
  mov eax, $EC5
  syscall
end;

procedure Syscall_EC6; stdcall;
asm
  mov r10, rcx
  mov eax, $EC6
  syscall
end;

procedure Syscall_EC7; stdcall;
asm
  mov r10, rcx
  mov eax, $EC7
  syscall
end;

procedure Syscall_EC8; stdcall;
asm
  mov r10, rcx
  mov eax, $EC8
  syscall
end;

procedure Syscall_EC9; stdcall;
asm
  mov r10, rcx
  mov eax, $EC9
  syscall
end;

procedure Syscall_ECA; stdcall;
asm
  mov r10, rcx
  mov eax, $ECA
  syscall
end;

procedure Syscall_ECB; stdcall;
asm
  mov r10, rcx
  mov eax, $ECB
  syscall
end;

procedure Syscall_ECC; stdcall;
asm
  mov r10, rcx
  mov eax, $ECC
  syscall
end;

procedure Syscall_ECD; stdcall;
asm
  mov r10, rcx
  mov eax, $ECD
  syscall
end;

procedure Syscall_ECE; stdcall;
asm
  mov r10, rcx
  mov eax, $ECE
  syscall
end;

procedure Syscall_ECF; stdcall;
asm
  mov r10, rcx
  mov eax, $ECF
  syscall
end;

procedure Syscall_ED0; stdcall;
asm
  mov r10, rcx
  mov eax, $ED0
  syscall
end;

procedure Syscall_ED1; stdcall;
asm
  mov r10, rcx
  mov eax, $ED1
  syscall
end;

procedure Syscall_ED2; stdcall;
asm
  mov r10, rcx
  mov eax, $ED2
  syscall
end;

procedure Syscall_ED3; stdcall;
asm
  mov r10, rcx
  mov eax, $ED3
  syscall
end;

procedure Syscall_ED4; stdcall;
asm
  mov r10, rcx
  mov eax, $ED4
  syscall
end;

procedure Syscall_ED5; stdcall;
asm
  mov r10, rcx
  mov eax, $ED5
  syscall
end;

procedure Syscall_ED6; stdcall;
asm
  mov r10, rcx
  mov eax, $ED6
  syscall
end;

procedure Syscall_ED7; stdcall;
asm
  mov r10, rcx
  mov eax, $ED7
  syscall
end;

procedure Syscall_ED8; stdcall;
asm
  mov r10, rcx
  mov eax, $ED8
  syscall
end;

procedure Syscall_ED9; stdcall;
asm
  mov r10, rcx
  mov eax, $ED9
  syscall
end;

procedure Syscall_EDA; stdcall;
asm
  mov r10, rcx
  mov eax, $EDA
  syscall
end;

procedure Syscall_EDB; stdcall;
asm
  mov r10, rcx
  mov eax, $EDB
  syscall
end;

procedure Syscall_EDC; stdcall;
asm
  mov r10, rcx
  mov eax, $EDC
  syscall
end;

procedure Syscall_EDD; stdcall;
asm
  mov r10, rcx
  mov eax, $EDD
  syscall
end;

procedure Syscall_EDE; stdcall;
asm
  mov r10, rcx
  mov eax, $EDE
  syscall
end;

procedure Syscall_EDF; stdcall;
asm
  mov r10, rcx
  mov eax, $EDF
  syscall
end;

procedure Syscall_EE0; stdcall;
asm
  mov r10, rcx
  mov eax, $EE0
  syscall
end;

procedure Syscall_EE1; stdcall;
asm
  mov r10, rcx
  mov eax, $EE1
  syscall
end;

procedure Syscall_EE2; stdcall;
asm
  mov r10, rcx
  mov eax, $EE2
  syscall
end;

procedure Syscall_EE3; stdcall;
asm
  mov r10, rcx
  mov eax, $EE3
  syscall
end;

procedure Syscall_EE4; stdcall;
asm
  mov r10, rcx
  mov eax, $EE4
  syscall
end;

procedure Syscall_EE5; stdcall;
asm
  mov r10, rcx
  mov eax, $EE5
  syscall
end;

procedure Syscall_EE6; stdcall;
asm
  mov r10, rcx
  mov eax, $EE6
  syscall
end;

procedure Syscall_EE7; stdcall;
asm
  mov r10, rcx
  mov eax, $EE7
  syscall
end;

procedure Syscall_EE8; stdcall;
asm
  mov r10, rcx
  mov eax, $EE8
  syscall
end;

procedure Syscall_EE9; stdcall;
asm
  mov r10, rcx
  mov eax, $EE9
  syscall
end;

procedure Syscall_EEA; stdcall;
asm
  mov r10, rcx
  mov eax, $EEA
  syscall
end;

procedure Syscall_EEB; stdcall;
asm
  mov r10, rcx
  mov eax, $EEB
  syscall
end;

procedure Syscall_EEC; stdcall;
asm
  mov r10, rcx
  mov eax, $EEC
  syscall
end;

procedure Syscall_EED; stdcall;
asm
  mov r10, rcx
  mov eax, $EED
  syscall
end;

procedure Syscall_EEE; stdcall;
asm
  mov r10, rcx
  mov eax, $EEE
  syscall
end;

procedure Syscall_EEF; stdcall;
asm
  mov r10, rcx
  mov eax, $EEF
  syscall
end;

procedure Syscall_EF0; stdcall;
asm
  mov r10, rcx
  mov eax, $EF0
  syscall
end;

procedure Syscall_EF1; stdcall;
asm
  mov r10, rcx
  mov eax, $EF1
  syscall
end;

procedure Syscall_EF2; stdcall;
asm
  mov r10, rcx
  mov eax, $EF2
  syscall
end;

procedure Syscall_EF3; stdcall;
asm
  mov r10, rcx
  mov eax, $EF3
  syscall
end;

procedure Syscall_EF4; stdcall;
asm
  mov r10, rcx
  mov eax, $EF4
  syscall
end;

procedure Syscall_EF5; stdcall;
asm
  mov r10, rcx
  mov eax, $EF5
  syscall
end;

procedure Syscall_EF6; stdcall;
asm
  mov r10, rcx
  mov eax, $EF6
  syscall
end;

procedure Syscall_EF7; stdcall;
asm
  mov r10, rcx
  mov eax, $EF7
  syscall
end;

procedure Syscall_EF8; stdcall;
asm
  mov r10, rcx
  mov eax, $EF8
  syscall
end;

procedure Syscall_EF9; stdcall;
asm
  mov r10, rcx
  mov eax, $EF9
  syscall
end;

procedure Syscall_EFA; stdcall;
asm
  mov r10, rcx
  mov eax, $EFA
  syscall
end;

procedure Syscall_EFB; stdcall;
asm
  mov r10, rcx
  mov eax, $EFB
  syscall
end;

procedure Syscall_EFC; stdcall;
asm
  mov r10, rcx
  mov eax, $EFC
  syscall
end;

procedure Syscall_EFD; stdcall;
asm
  mov r10, rcx
  mov eax, $EFD
  syscall
end;

procedure Syscall_EFE; stdcall;
asm
  mov r10, rcx
  mov eax, $EFE
  syscall
end;

procedure Syscall_EFF; stdcall;
asm
  mov r10, rcx
  mov eax, $EFF
  syscall
end;

procedure Syscall_F00; stdcall;
asm
  mov r10, rcx
  mov eax, $F00
  syscall
end;

procedure Syscall_F01; stdcall;
asm
  mov r10, rcx
  mov eax, $F01
  syscall
end;

procedure Syscall_F02; stdcall;
asm
  mov r10, rcx
  mov eax, $F02
  syscall
end;

procedure Syscall_F03; stdcall;
asm
  mov r10, rcx
  mov eax, $F03
  syscall
end;

procedure Syscall_F04; stdcall;
asm
  mov r10, rcx
  mov eax, $F04
  syscall
end;

procedure Syscall_F05; stdcall;
asm
  mov r10, rcx
  mov eax, $F05
  syscall
end;

procedure Syscall_F06; stdcall;
asm
  mov r10, rcx
  mov eax, $F06
  syscall
end;

procedure Syscall_F07; stdcall;
asm
  mov r10, rcx
  mov eax, $F07
  syscall
end;

procedure Syscall_F08; stdcall;
asm
  mov r10, rcx
  mov eax, $F08
  syscall
end;

procedure Syscall_F09; stdcall;
asm
  mov r10, rcx
  mov eax, $F09
  syscall
end;

procedure Syscall_F0A; stdcall;
asm
  mov r10, rcx
  mov eax, $F0A
  syscall
end;

procedure Syscall_F0B; stdcall;
asm
  mov r10, rcx
  mov eax, $F0B
  syscall
end;

procedure Syscall_F0C; stdcall;
asm
  mov r10, rcx
  mov eax, $F0C
  syscall
end;

procedure Syscall_F0D; stdcall;
asm
  mov r10, rcx
  mov eax, $F0D
  syscall
end;

procedure Syscall_F0E; stdcall;
asm
  mov r10, rcx
  mov eax, $F0E
  syscall
end;

procedure Syscall_F0F; stdcall;
asm
  mov r10, rcx
  mov eax, $F0F
  syscall
end;

procedure Syscall_F10; stdcall;
asm
  mov r10, rcx
  mov eax, $F10
  syscall
end;

procedure Syscall_F11; stdcall;
asm
  mov r10, rcx
  mov eax, $F11
  syscall
end;

procedure Syscall_F12; stdcall;
asm
  mov r10, rcx
  mov eax, $F12
  syscall
end;

procedure Syscall_F13; stdcall;
asm
  mov r10, rcx
  mov eax, $F13
  syscall
end;

procedure Syscall_F14; stdcall;
asm
  mov r10, rcx
  mov eax, $F14
  syscall
end;

procedure Syscall_F15; stdcall;
asm
  mov r10, rcx
  mov eax, $F15
  syscall
end;

procedure Syscall_F16; stdcall;
asm
  mov r10, rcx
  mov eax, $F16
  syscall
end;

procedure Syscall_F17; stdcall;
asm
  mov r10, rcx
  mov eax, $F17
  syscall
end;

procedure Syscall_F18; stdcall;
asm
  mov r10, rcx
  mov eax, $F18
  syscall
end;

procedure Syscall_F19; stdcall;
asm
  mov r10, rcx
  mov eax, $F19
  syscall
end;

procedure Syscall_F1A; stdcall;
asm
  mov r10, rcx
  mov eax, $F1A
  syscall
end;

procedure Syscall_F1B; stdcall;
asm
  mov r10, rcx
  mov eax, $F1B
  syscall
end;

procedure Syscall_F1C; stdcall;
asm
  mov r10, rcx
  mov eax, $F1C
  syscall
end;

procedure Syscall_F1D; stdcall;
asm
  mov r10, rcx
  mov eax, $F1D
  syscall
end;

procedure Syscall_F1E; stdcall;
asm
  mov r10, rcx
  mov eax, $F1E
  syscall
end;

procedure Syscall_F1F; stdcall;
asm
  mov r10, rcx
  mov eax, $F1F
  syscall
end;

procedure Syscall_F20; stdcall;
asm
  mov r10, rcx
  mov eax, $F20
  syscall
end;

procedure Syscall_F21; stdcall;
asm
  mov r10, rcx
  mov eax, $F21
  syscall
end;

procedure Syscall_F22; stdcall;
asm
  mov r10, rcx
  mov eax, $F22
  syscall
end;

procedure Syscall_F23; stdcall;
asm
  mov r10, rcx
  mov eax, $F23
  syscall
end;

procedure Syscall_F24; stdcall;
asm
  mov r10, rcx
  mov eax, $F24
  syscall
end;

procedure Syscall_F25; stdcall;
asm
  mov r10, rcx
  mov eax, $F25
  syscall
end;

procedure Syscall_F26; stdcall;
asm
  mov r10, rcx
  mov eax, $F26
  syscall
end;

procedure Syscall_F27; stdcall;
asm
  mov r10, rcx
  mov eax, $F27
  syscall
end;

procedure Syscall_F28; stdcall;
asm
  mov r10, rcx
  mov eax, $F28
  syscall
end;

procedure Syscall_F29; stdcall;
asm
  mov r10, rcx
  mov eax, $F29
  syscall
end;

procedure Syscall_F2A; stdcall;
asm
  mov r10, rcx
  mov eax, $F2A
  syscall
end;

procedure Syscall_F2B; stdcall;
asm
  mov r10, rcx
  mov eax, $F2B
  syscall
end;

procedure Syscall_F2C; stdcall;
asm
  mov r10, rcx
  mov eax, $F2C
  syscall
end;

procedure Syscall_F2D; stdcall;
asm
  mov r10, rcx
  mov eax, $F2D
  syscall
end;

procedure Syscall_F2E; stdcall;
asm
  mov r10, rcx
  mov eax, $F2E
  syscall
end;

procedure Syscall_F2F; stdcall;
asm
  mov r10, rcx
  mov eax, $F2F
  syscall
end;

procedure Syscall_F30; stdcall;
asm
  mov r10, rcx
  mov eax, $F30
  syscall
end;

procedure Syscall_F31; stdcall;
asm
  mov r10, rcx
  mov eax, $F31
  syscall
end;

procedure Syscall_F32; stdcall;
asm
  mov r10, rcx
  mov eax, $F32
  syscall
end;

procedure Syscall_F33; stdcall;
asm
  mov r10, rcx
  mov eax, $F33
  syscall
end;

procedure Syscall_F34; stdcall;
asm
  mov r10, rcx
  mov eax, $F34
  syscall
end;

procedure Syscall_F35; stdcall;
asm
  mov r10, rcx
  mov eax, $F35
  syscall
end;

procedure Syscall_F36; stdcall;
asm
  mov r10, rcx
  mov eax, $F36
  syscall
end;

procedure Syscall_F37; stdcall;
asm
  mov r10, rcx
  mov eax, $F37
  syscall
end;

procedure Syscall_F38; stdcall;
asm
  mov r10, rcx
  mov eax, $F38
  syscall
end;

procedure Syscall_F39; stdcall;
asm
  mov r10, rcx
  mov eax, $F39
  syscall
end;

procedure Syscall_F3A; stdcall;
asm
  mov r10, rcx
  mov eax, $F3A
  syscall
end;

procedure Syscall_F3B; stdcall;
asm
  mov r10, rcx
  mov eax, $F3B
  syscall
end;

procedure Syscall_F3C; stdcall;
asm
  mov r10, rcx
  mov eax, $F3C
  syscall
end;

procedure Syscall_F3D; stdcall;
asm
  mov r10, rcx
  mov eax, $F3D
  syscall
end;

procedure Syscall_F3E; stdcall;
asm
  mov r10, rcx
  mov eax, $F3E
  syscall
end;

procedure Syscall_F3F; stdcall;
asm
  mov r10, rcx
  mov eax, $F3F
  syscall
end;

procedure Syscall_F40; stdcall;
asm
  mov r10, rcx
  mov eax, $F40
  syscall
end;

procedure Syscall_F41; stdcall;
asm
  mov r10, rcx
  mov eax, $F41
  syscall
end;

procedure Syscall_F42; stdcall;
asm
  mov r10, rcx
  mov eax, $F42
  syscall
end;

procedure Syscall_F43; stdcall;
asm
  mov r10, rcx
  mov eax, $F43
  syscall
end;

procedure Syscall_F44; stdcall;
asm
  mov r10, rcx
  mov eax, $F44
  syscall
end;

procedure Syscall_F45; stdcall;
asm
  mov r10, rcx
  mov eax, $F45
  syscall
end;

procedure Syscall_F46; stdcall;
asm
  mov r10, rcx
  mov eax, $F46
  syscall
end;

procedure Syscall_F47; stdcall;
asm
  mov r10, rcx
  mov eax, $F47
  syscall
end;

procedure Syscall_F48; stdcall;
asm
  mov r10, rcx
  mov eax, $F48
  syscall
end;

procedure Syscall_F49; stdcall;
asm
  mov r10, rcx
  mov eax, $F49
  syscall
end;

procedure Syscall_F4A; stdcall;
asm
  mov r10, rcx
  mov eax, $F4A
  syscall
end;

procedure Syscall_F4B; stdcall;
asm
  mov r10, rcx
  mov eax, $F4B
  syscall
end;

procedure Syscall_F4C; stdcall;
asm
  mov r10, rcx
  mov eax, $F4C
  syscall
end;

procedure Syscall_F4D; stdcall;
asm
  mov r10, rcx
  mov eax, $F4D
  syscall
end;

procedure Syscall_F4E; stdcall;
asm
  mov r10, rcx
  mov eax, $F4E
  syscall
end;

procedure Syscall_F4F; stdcall;
asm
  mov r10, rcx
  mov eax, $F4F
  syscall
end;

procedure Syscall_F50; stdcall;
asm
  mov r10, rcx
  mov eax, $F50
  syscall
end;

procedure Syscall_F51; stdcall;
asm
  mov r10, rcx
  mov eax, $F51
  syscall
end;

procedure Syscall_F52; stdcall;
asm
  mov r10, rcx
  mov eax, $F52
  syscall
end;

procedure Syscall_F53; stdcall;
asm
  mov r10, rcx
  mov eax, $F53
  syscall
end;

procedure Syscall_F54; stdcall;
asm
  mov r10, rcx
  mov eax, $F54
  syscall
end;

procedure Syscall_F55; stdcall;
asm
  mov r10, rcx
  mov eax, $F55
  syscall
end;

procedure Syscall_F56; stdcall;
asm
  mov r10, rcx
  mov eax, $F56
  syscall
end;

procedure Syscall_F57; stdcall;
asm
  mov r10, rcx
  mov eax, $F57
  syscall
end;

procedure Syscall_F58; stdcall;
asm
  mov r10, rcx
  mov eax, $F58
  syscall
end;

procedure Syscall_F59; stdcall;
asm
  mov r10, rcx
  mov eax, $F59
  syscall
end;

procedure Syscall_F5A; stdcall;
asm
  mov r10, rcx
  mov eax, $F5A
  syscall
end;

procedure Syscall_F5B; stdcall;
asm
  mov r10, rcx
  mov eax, $F5B
  syscall
end;

procedure Syscall_F5C; stdcall;
asm
  mov r10, rcx
  mov eax, $F5C
  syscall
end;

procedure Syscall_F5D; stdcall;
asm
  mov r10, rcx
  mov eax, $F5D
  syscall
end;

procedure Syscall_F5E; stdcall;
asm
  mov r10, rcx
  mov eax, $F5E
  syscall
end;

procedure Syscall_F5F; stdcall;
asm
  mov r10, rcx
  mov eax, $F5F
  syscall
end;

procedure Syscall_F60; stdcall;
asm
  mov r10, rcx
  mov eax, $F60
  syscall
end;

procedure Syscall_F61; stdcall;
asm
  mov r10, rcx
  mov eax, $F61
  syscall
end;

procedure Syscall_F62; stdcall;
asm
  mov r10, rcx
  mov eax, $F62
  syscall
end;

procedure Syscall_F63; stdcall;
asm
  mov r10, rcx
  mov eax, $F63
  syscall
end;

procedure Syscall_F64; stdcall;
asm
  mov r10, rcx
  mov eax, $F64
  syscall
end;

procedure Syscall_F65; stdcall;
asm
  mov r10, rcx
  mov eax, $F65
  syscall
end;

procedure Syscall_F66; stdcall;
asm
  mov r10, rcx
  mov eax, $F66
  syscall
end;

procedure Syscall_F67; stdcall;
asm
  mov r10, rcx
  mov eax, $F67
  syscall
end;

procedure Syscall_F68; stdcall;
asm
  mov r10, rcx
  mov eax, $F68
  syscall
end;

procedure Syscall_F69; stdcall;
asm
  mov r10, rcx
  mov eax, $F69
  syscall
end;

procedure Syscall_F6A; stdcall;
asm
  mov r10, rcx
  mov eax, $F6A
  syscall
end;

procedure Syscall_F6B; stdcall;
asm
  mov r10, rcx
  mov eax, $F6B
  syscall
end;

procedure Syscall_F6C; stdcall;
asm
  mov r10, rcx
  mov eax, $F6C
  syscall
end;

procedure Syscall_F6D; stdcall;
asm
  mov r10, rcx
  mov eax, $F6D
  syscall
end;

procedure Syscall_F6E; stdcall;
asm
  mov r10, rcx
  mov eax, $F6E
  syscall
end;

procedure Syscall_F6F; stdcall;
asm
  mov r10, rcx
  mov eax, $F6F
  syscall
end;

procedure Syscall_F70; stdcall;
asm
  mov r10, rcx
  mov eax, $F70
  syscall
end;

procedure Syscall_F71; stdcall;
asm
  mov r10, rcx
  mov eax, $F71
  syscall
end;

procedure Syscall_F72; stdcall;
asm
  mov r10, rcx
  mov eax, $F72
  syscall
end;

procedure Syscall_F73; stdcall;
asm
  mov r10, rcx
  mov eax, $F73
  syscall
end;

procedure Syscall_F74; stdcall;
asm
  mov r10, rcx
  mov eax, $F74
  syscall
end;

procedure Syscall_F75; stdcall;
asm
  mov r10, rcx
  mov eax, $F75
  syscall
end;

procedure Syscall_F76; stdcall;
asm
  mov r10, rcx
  mov eax, $F76
  syscall
end;

procedure Syscall_F77; stdcall;
asm
  mov r10, rcx
  mov eax, $F77
  syscall
end;

procedure Syscall_F78; stdcall;
asm
  mov r10, rcx
  mov eax, $F78
  syscall
end;

procedure Syscall_F79; stdcall;
asm
  mov r10, rcx
  mov eax, $F79
  syscall
end;

procedure Syscall_F7A; stdcall;
asm
  mov r10, rcx
  mov eax, $F7A
  syscall
end;

procedure Syscall_F7B; stdcall;
asm
  mov r10, rcx
  mov eax, $F7B
  syscall
end;

procedure Syscall_F7C; stdcall;
asm
  mov r10, rcx
  mov eax, $F7C
  syscall
end;

procedure Syscall_F7D; stdcall;
asm
  mov r10, rcx
  mov eax, $F7D
  syscall
end;

procedure Syscall_F7E; stdcall;
asm
  mov r10, rcx
  mov eax, $F7E
  syscall
end;

procedure Syscall_F7F; stdcall;
asm
  mov r10, rcx
  mov eax, $F7F
  syscall
end;

procedure Syscall_F80; stdcall;
asm
  mov r10, rcx
  mov eax, $F80
  syscall
end;

procedure Syscall_F81; stdcall;
asm
  mov r10, rcx
  mov eax, $F81
  syscall
end;

procedure Syscall_F82; stdcall;
asm
  mov r10, rcx
  mov eax, $F82
  syscall
end;

procedure Syscall_F83; stdcall;
asm
  mov r10, rcx
  mov eax, $F83
  syscall
end;

procedure Syscall_F84; stdcall;
asm
  mov r10, rcx
  mov eax, $F84
  syscall
end;

procedure Syscall_F85; stdcall;
asm
  mov r10, rcx
  mov eax, $F85
  syscall
end;

procedure Syscall_F86; stdcall;
asm
  mov r10, rcx
  mov eax, $F86
  syscall
end;

procedure Syscall_F87; stdcall;
asm
  mov r10, rcx
  mov eax, $F87
  syscall
end;

procedure Syscall_F88; stdcall;
asm
  mov r10, rcx
  mov eax, $F88
  syscall
end;

procedure Syscall_F89; stdcall;
asm
  mov r10, rcx
  mov eax, $F89
  syscall
end;

procedure Syscall_F8A; stdcall;
asm
  mov r10, rcx
  mov eax, $F8A
  syscall
end;

procedure Syscall_F8B; stdcall;
asm
  mov r10, rcx
  mov eax, $F8B
  syscall
end;

procedure Syscall_F8C; stdcall;
asm
  mov r10, rcx
  mov eax, $F8C
  syscall
end;

procedure Syscall_F8D; stdcall;
asm
  mov r10, rcx
  mov eax, $F8D
  syscall
end;

procedure Syscall_F8E; stdcall;
asm
  mov r10, rcx
  mov eax, $F8E
  syscall
end;

procedure Syscall_F8F; stdcall;
asm
  mov r10, rcx
  mov eax, $F8F
  syscall
end;

procedure Syscall_F90; stdcall;
asm
  mov r10, rcx
  mov eax, $F90
  syscall
end;

procedure Syscall_F91; stdcall;
asm
  mov r10, rcx
  mov eax, $F91
  syscall
end;

procedure Syscall_F92; stdcall;
asm
  mov r10, rcx
  mov eax, $F92
  syscall
end;

procedure Syscall_F93; stdcall;
asm
  mov r10, rcx
  mov eax, $F93
  syscall
end;

procedure Syscall_F94; stdcall;
asm
  mov r10, rcx
  mov eax, $F94
  syscall
end;

procedure Syscall_F95; stdcall;
asm
  mov r10, rcx
  mov eax, $F95
  syscall
end;

procedure Syscall_F96; stdcall;
asm
  mov r10, rcx
  mov eax, $F96
  syscall
end;

procedure Syscall_F97; stdcall;
asm
  mov r10, rcx
  mov eax, $F97
  syscall
end;

procedure Syscall_F98; stdcall;
asm
  mov r10, rcx
  mov eax, $F98
  syscall
end;

procedure Syscall_F99; stdcall;
asm
  mov r10, rcx
  mov eax, $F99
  syscall
end;

procedure Syscall_F9A; stdcall;
asm
  mov r10, rcx
  mov eax, $F9A
  syscall
end;

procedure Syscall_F9B; stdcall;
asm
  mov r10, rcx
  mov eax, $F9B
  syscall
end;

procedure Syscall_F9C; stdcall;
asm
  mov r10, rcx
  mov eax, $F9C
  syscall
end;

procedure Syscall_F9D; stdcall;
asm
  mov r10, rcx
  mov eax, $F9D
  syscall
end;

procedure Syscall_F9E; stdcall;
asm
  mov r10, rcx
  mov eax, $F9E
  syscall
end;

procedure Syscall_F9F; stdcall;
asm
  mov r10, rcx
  mov eax, $F9F
  syscall
end;

procedure Syscall_FA0; stdcall;
asm
  mov r10, rcx
  mov eax, $FA0
  syscall
end;

procedure Syscall_FA1; stdcall;
asm
  mov r10, rcx
  mov eax, $FA1
  syscall
end;

procedure Syscall_FA2; stdcall;
asm
  mov r10, rcx
  mov eax, $FA2
  syscall
end;

procedure Syscall_FA3; stdcall;
asm
  mov r10, rcx
  mov eax, $FA3
  syscall
end;

procedure Syscall_FA4; stdcall;
asm
  mov r10, rcx
  mov eax, $FA4
  syscall
end;

procedure Syscall_FA5; stdcall;
asm
  mov r10, rcx
  mov eax, $FA5
  syscall
end;

procedure Syscall_FA6; stdcall;
asm
  mov r10, rcx
  mov eax, $FA6
  syscall
end;

procedure Syscall_FA7; stdcall;
asm
  mov r10, rcx
  mov eax, $FA7
  syscall
end;

procedure Syscall_FA8; stdcall;
asm
  mov r10, rcx
  mov eax, $FA8
  syscall
end;

procedure Syscall_FA9; stdcall;
asm
  mov r10, rcx
  mov eax, $FA9
  syscall
end;

procedure Syscall_FAA; stdcall;
asm
  mov r10, rcx
  mov eax, $FAA
  syscall
end;

procedure Syscall_FAB; stdcall;
asm
  mov r10, rcx
  mov eax, $FAB
  syscall
end;

procedure Syscall_FAC; stdcall;
asm
  mov r10, rcx
  mov eax, $FAC
  syscall
end;

procedure Syscall_FAD; stdcall;
asm
  mov r10, rcx
  mov eax, $FAD
  syscall
end;

procedure Syscall_FAE; stdcall;
asm
  mov r10, rcx
  mov eax, $FAE
  syscall
end;

procedure Syscall_FAF; stdcall;
asm
  mov r10, rcx
  mov eax, $FAF
  syscall
end;

procedure Syscall_FB0; stdcall;
asm
  mov r10, rcx
  mov eax, $FB0
  syscall
end;

procedure Syscall_FB1; stdcall;
asm
  mov r10, rcx
  mov eax, $FB1
  syscall
end;

procedure Syscall_FB2; stdcall;
asm
  mov r10, rcx
  mov eax, $FB2
  syscall
end;

procedure Syscall_FB3; stdcall;
asm
  mov r10, rcx
  mov eax, $FB3
  syscall
end;

procedure Syscall_FB4; stdcall;
asm
  mov r10, rcx
  mov eax, $FB4
  syscall
end;

procedure Syscall_FB5; stdcall;
asm
  mov r10, rcx
  mov eax, $FB5
  syscall
end;

procedure Syscall_FB6; stdcall;
asm
  mov r10, rcx
  mov eax, $FB6
  syscall
end;

procedure Syscall_FB7; stdcall;
asm
  mov r10, rcx
  mov eax, $FB7
  syscall
end;

procedure Syscall_FB8; stdcall;
asm
  mov r10, rcx
  mov eax, $FB8
  syscall
end;

procedure Syscall_FB9; stdcall;
asm
  mov r10, rcx
  mov eax, $FB9
  syscall
end;

procedure Syscall_FBA; stdcall;
asm
  mov r10, rcx
  mov eax, $FBA
  syscall
end;

procedure Syscall_FBB; stdcall;
asm
  mov r10, rcx
  mov eax, $FBB
  syscall
end;

procedure Syscall_FBC; stdcall;
asm
  mov r10, rcx
  mov eax, $FBC
  syscall
end;

procedure Syscall_FBD; stdcall;
asm
  mov r10, rcx
  mov eax, $FBD
  syscall
end;

procedure Syscall_FBE; stdcall;
asm
  mov r10, rcx
  mov eax, $FBE
  syscall
end;

procedure Syscall_FBF; stdcall;
asm
  mov r10, rcx
  mov eax, $FBF
  syscall
end;

procedure Syscall_FC0; stdcall;
asm
  mov r10, rcx
  mov eax, $FC0
  syscall
end;

procedure Syscall_FC1; stdcall;
asm
  mov r10, rcx
  mov eax, $FC1
  syscall
end;

procedure Syscall_FC2; stdcall;
asm
  mov r10, rcx
  mov eax, $FC2
  syscall
end;

procedure Syscall_FC3; stdcall;
asm
  mov r10, rcx
  mov eax, $FC3
  syscall
end;

procedure Syscall_FC4; stdcall;
asm
  mov r10, rcx
  mov eax, $FC4
  syscall
end;

procedure Syscall_FC5; stdcall;
asm
  mov r10, rcx
  mov eax, $FC5
  syscall
end;

procedure Syscall_FC6; stdcall;
asm
  mov r10, rcx
  mov eax, $FC6
  syscall
end;

procedure Syscall_FC7; stdcall;
asm
  mov r10, rcx
  mov eax, $FC7
  syscall
end;

procedure Syscall_FC8; stdcall;
asm
  mov r10, rcx
  mov eax, $FC8
  syscall
end;

procedure Syscall_FC9; stdcall;
asm
  mov r10, rcx
  mov eax, $FC9
  syscall
end;

procedure Syscall_FCA; stdcall;
asm
  mov r10, rcx
  mov eax, $FCA
  syscall
end;

procedure Syscall_FCB; stdcall;
asm
  mov r10, rcx
  mov eax, $FCB
  syscall
end;

procedure Syscall_FCC; stdcall;
asm
  mov r10, rcx
  mov eax, $FCC
  syscall
end;

procedure Syscall_FCD; stdcall;
asm
  mov r10, rcx
  mov eax, $FCD
  syscall
end;

procedure Syscall_FCE; stdcall;
asm
  mov r10, rcx
  mov eax, $FCE
  syscall
end;

procedure Syscall_FCF; stdcall;
asm
  mov r10, rcx
  mov eax, $FCF
  syscall
end;

procedure Syscall_FD0; stdcall;
asm
  mov r10, rcx
  mov eax, $FD0
  syscall
end;

procedure Syscall_FD1; stdcall;
asm
  mov r10, rcx
  mov eax, $FD1
  syscall
end;

procedure Syscall_FD2; stdcall;
asm
  mov r10, rcx
  mov eax, $FD2
  syscall
end;

procedure Syscall_FD3; stdcall;
asm
  mov r10, rcx
  mov eax, $FD3
  syscall
end;

procedure Syscall_FD4; stdcall;
asm
  mov r10, rcx
  mov eax, $FD4
  syscall
end;

procedure Syscall_FD5; stdcall;
asm
  mov r10, rcx
  mov eax, $FD5
  syscall
end;

procedure Syscall_FD6; stdcall;
asm
  mov r10, rcx
  mov eax, $FD6
  syscall
end;

procedure Syscall_FD7; stdcall;
asm
  mov r10, rcx
  mov eax, $FD7
  syscall
end;

procedure Syscall_FD8; stdcall;
asm
  mov r10, rcx
  mov eax, $FD8
  syscall
end;

procedure Syscall_FD9; stdcall;
asm
  mov r10, rcx
  mov eax, $FD9
  syscall
end;

procedure Syscall_FDA; stdcall;
asm
  mov r10, rcx
  mov eax, $FDA
  syscall
end;

procedure Syscall_FDB; stdcall;
asm
  mov r10, rcx
  mov eax, $FDB
  syscall
end;

procedure Syscall_FDC; stdcall;
asm
  mov r10, rcx
  mov eax, $FDC
  syscall
end;

procedure Syscall_FDD; stdcall;
asm
  mov r10, rcx
  mov eax, $FDD
  syscall
end;

procedure Syscall_FDE; stdcall;
asm
  mov r10, rcx
  mov eax, $FDE
  syscall
end;

procedure Syscall_FDF; stdcall;
asm
  mov r10, rcx
  mov eax, $FDF
  syscall
end;

procedure Syscall_FE0; stdcall;
asm
  mov r10, rcx
  mov eax, $FE0
  syscall
end;

procedure Syscall_FE1; stdcall;
asm
  mov r10, rcx
  mov eax, $FE1
  syscall
end;

procedure Syscall_FE2; stdcall;
asm
  mov r10, rcx
  mov eax, $FE2
  syscall
end;

procedure Syscall_FE3; stdcall;
asm
  mov r10, rcx
  mov eax, $FE3
  syscall
end;

procedure Syscall_FE4; stdcall;
asm
  mov r10, rcx
  mov eax, $FE4
  syscall
end;

procedure Syscall_FE5; stdcall;
asm
  mov r10, rcx
  mov eax, $FE5
  syscall
end;

procedure Syscall_FE6; stdcall;
asm
  mov r10, rcx
  mov eax, $FE6
  syscall
end;

procedure Syscall_FE7; stdcall;
asm
  mov r10, rcx
  mov eax, $FE7
  syscall
end;

procedure Syscall_FE8; stdcall;
asm
  mov r10, rcx
  mov eax, $FE8
  syscall
end;

procedure Syscall_FE9; stdcall;
asm
  mov r10, rcx
  mov eax, $FE9
  syscall
end;

procedure Syscall_FEA; stdcall;
asm
  mov r10, rcx
  mov eax, $FEA
  syscall
end;

procedure Syscall_FEB; stdcall;
asm
  mov r10, rcx
  mov eax, $FEB
  syscall
end;

procedure Syscall_FEC; stdcall;
asm
  mov r10, rcx
  mov eax, $FEC
  syscall
end;

procedure Syscall_FED; stdcall;
asm
  mov r10, rcx
  mov eax, $FED
  syscall
end;

procedure Syscall_FEE; stdcall;
asm
  mov r10, rcx
  mov eax, $FEE
  syscall
end;

procedure Syscall_FEF; stdcall;
asm
  mov r10, rcx
  mov eax, $FEF
  syscall
end;

procedure Syscall_FF0; stdcall;
asm
  mov r10, rcx
  mov eax, $FF0
  syscall
end;

procedure Syscall_FF1; stdcall;
asm
  mov r10, rcx
  mov eax, $FF1
  syscall
end;

procedure Syscall_FF2; stdcall;
asm
  mov r10, rcx
  mov eax, $FF2
  syscall
end;

procedure Syscall_FF3; stdcall;
asm
  mov r10, rcx
  mov eax, $FF3
  syscall
end;

procedure Syscall_FF4; stdcall;
asm
  mov r10, rcx
  mov eax, $FF4
  syscall
end;

procedure Syscall_FF5; stdcall;
asm
  mov r10, rcx
  mov eax, $FF5
  syscall
end;

procedure Syscall_FF6; stdcall;
asm
  mov r10, rcx
  mov eax, $FF6
  syscall
end;

procedure Syscall_FF7; stdcall;
asm
  mov r10, rcx
  mov eax, $FF7
  syscall
end;

procedure Syscall_FF8; stdcall;
asm
  mov r10, rcx
  mov eax, $FF8
  syscall
end;

procedure Syscall_FF9; stdcall;
asm
  mov r10, rcx
  mov eax, $FF9
  syscall
end;

procedure Syscall_FFA; stdcall;
asm
  mov r10, rcx
  mov eax, $FFA
  syscall
end;

procedure Syscall_FFB; stdcall;
asm
  mov r10, rcx
  mov eax, $FFB
  syscall
end;

procedure Syscall_FFC; stdcall;
asm
  mov r10, rcx
  mov eax, $FFC
  syscall
end;

procedure Syscall_FFD; stdcall;
asm
  mov r10, rcx
  mov eax, $FFD
  syscall
end;

procedure Syscall_FFE; stdcall;
asm
  mov r10, rcx
  mov eax, $FFE
  syscall
end;

procedure Syscall_FFF; stdcall;
asm
  mov r10, rcx
  mov eax, $FFF
  syscall
end;

var
  SyscallMap: array [$000..$FFF] of Pointer = (
    @Syscall_000, @Syscall_001, @Syscall_002, @Syscall_003, @Syscall_004,
    @Syscall_005, @Syscall_006, @Syscall_007, @Syscall_008, @Syscall_009,
    @Syscall_00A, @Syscall_00B, @Syscall_00C, @Syscall_00D, @Syscall_00E,
    @Syscall_00F, @Syscall_010, @Syscall_011, @Syscall_012, @Syscall_013,
    @Syscall_014, @Syscall_015, @Syscall_016, @Syscall_017, @Syscall_018,
    @Syscall_019, @Syscall_01A, @Syscall_01B, @Syscall_01C, @Syscall_01D,
    @Syscall_01E, @Syscall_01F, @Syscall_020, @Syscall_021, @Syscall_022,
    @Syscall_023, @Syscall_024, @Syscall_025, @Syscall_026, @Syscall_027,
    @Syscall_028, @Syscall_029, @Syscall_02A, @Syscall_02B, @Syscall_02C,
    @Syscall_02D, @Syscall_02E, @Syscall_02F, @Syscall_030, @Syscall_031,
    @Syscall_032, @Syscall_033, @Syscall_034, @Syscall_035, @Syscall_036,
    @Syscall_037, @Syscall_038, @Syscall_039, @Syscall_03A, @Syscall_03B,
    @Syscall_03C, @Syscall_03D, @Syscall_03E, @Syscall_03F, @Syscall_040,
    @Syscall_041, @Syscall_042, @Syscall_043, @Syscall_044, @Syscall_045,
    @Syscall_046, @Syscall_047, @Syscall_048, @Syscall_049, @Syscall_04A,
    @Syscall_04B, @Syscall_04C, @Syscall_04D, @Syscall_04E, @Syscall_04F,
    @Syscall_050, @Syscall_051, @Syscall_052, @Syscall_053, @Syscall_054,
    @Syscall_055, @Syscall_056, @Syscall_057, @Syscall_058, @Syscall_059,
    @Syscall_05A, @Syscall_05B, @Syscall_05C, @Syscall_05D, @Syscall_05E,
    @Syscall_05F, @Syscall_060, @Syscall_061, @Syscall_062, @Syscall_063,
    @Syscall_064, @Syscall_065, @Syscall_066, @Syscall_067, @Syscall_068,
    @Syscall_069, @Syscall_06A, @Syscall_06B, @Syscall_06C, @Syscall_06D,
    @Syscall_06E, @Syscall_06F, @Syscall_070, @Syscall_071, @Syscall_072,
    @Syscall_073, @Syscall_074, @Syscall_075, @Syscall_076, @Syscall_077,
    @Syscall_078, @Syscall_079, @Syscall_07A, @Syscall_07B, @Syscall_07C,
    @Syscall_07D, @Syscall_07E, @Syscall_07F, @Syscall_080, @Syscall_081,
    @Syscall_082, @Syscall_083, @Syscall_084, @Syscall_085, @Syscall_086,
    @Syscall_087, @Syscall_088, @Syscall_089, @Syscall_08A, @Syscall_08B,
    @Syscall_08C, @Syscall_08D, @Syscall_08E, @Syscall_08F, @Syscall_090,
    @Syscall_091, @Syscall_092, @Syscall_093, @Syscall_094, @Syscall_095,
    @Syscall_096, @Syscall_097, @Syscall_098, @Syscall_099, @Syscall_09A,
    @Syscall_09B, @Syscall_09C, @Syscall_09D, @Syscall_09E, @Syscall_09F,
    @Syscall_0A0, @Syscall_0A1, @Syscall_0A2, @Syscall_0A3, @Syscall_0A4,
    @Syscall_0A5, @Syscall_0A6, @Syscall_0A7, @Syscall_0A8, @Syscall_0A9,
    @Syscall_0AA, @Syscall_0AB, @Syscall_0AC, @Syscall_0AD, @Syscall_0AE,
    @Syscall_0AF, @Syscall_0B0, @Syscall_0B1, @Syscall_0B2, @Syscall_0B3,
    @Syscall_0B4, @Syscall_0B5, @Syscall_0B6, @Syscall_0B7, @Syscall_0B8,
    @Syscall_0B9, @Syscall_0BA, @Syscall_0BB, @Syscall_0BC, @Syscall_0BD,
    @Syscall_0BE, @Syscall_0BF, @Syscall_0C0, @Syscall_0C1, @Syscall_0C2,
    @Syscall_0C3, @Syscall_0C4, @Syscall_0C5, @Syscall_0C6, @Syscall_0C7,
    @Syscall_0C8, @Syscall_0C9, @Syscall_0CA, @Syscall_0CB, @Syscall_0CC,
    @Syscall_0CD, @Syscall_0CE, @Syscall_0CF, @Syscall_0D0, @Syscall_0D1,
    @Syscall_0D2, @Syscall_0D3, @Syscall_0D4, @Syscall_0D5, @Syscall_0D6,
    @Syscall_0D7, @Syscall_0D8, @Syscall_0D9, @Syscall_0DA, @Syscall_0DB,
    @Syscall_0DC, @Syscall_0DD, @Syscall_0DE, @Syscall_0DF, @Syscall_0E0,
    @Syscall_0E1, @Syscall_0E2, @Syscall_0E3, @Syscall_0E4, @Syscall_0E5,
    @Syscall_0E6, @Syscall_0E7, @Syscall_0E8, @Syscall_0E9, @Syscall_0EA,
    @Syscall_0EB, @Syscall_0EC, @Syscall_0ED, @Syscall_0EE, @Syscall_0EF,
    @Syscall_0F0, @Syscall_0F1, @Syscall_0F2, @Syscall_0F3, @Syscall_0F4,
    @Syscall_0F5, @Syscall_0F6, @Syscall_0F7, @Syscall_0F8, @Syscall_0F9,
    @Syscall_0FA, @Syscall_0FB, @Syscall_0FC, @Syscall_0FD, @Syscall_0FE,
    @Syscall_0FF, @Syscall_100, @Syscall_101, @Syscall_102, @Syscall_103,
    @Syscall_104, @Syscall_105, @Syscall_106, @Syscall_107, @Syscall_108,
    @Syscall_109, @Syscall_10A, @Syscall_10B, @Syscall_10C, @Syscall_10D,
    @Syscall_10E, @Syscall_10F, @Syscall_110, @Syscall_111, @Syscall_112,
    @Syscall_113, @Syscall_114, @Syscall_115, @Syscall_116, @Syscall_117,
    @Syscall_118, @Syscall_119, @Syscall_11A, @Syscall_11B, @Syscall_11C,
    @Syscall_11D, @Syscall_11E, @Syscall_11F, @Syscall_120, @Syscall_121,
    @Syscall_122, @Syscall_123, @Syscall_124, @Syscall_125, @Syscall_126,
    @Syscall_127, @Syscall_128, @Syscall_129, @Syscall_12A, @Syscall_12B,
    @Syscall_12C, @Syscall_12D, @Syscall_12E, @Syscall_12F, @Syscall_130,
    @Syscall_131, @Syscall_132, @Syscall_133, @Syscall_134, @Syscall_135,
    @Syscall_136, @Syscall_137, @Syscall_138, @Syscall_139, @Syscall_13A,
    @Syscall_13B, @Syscall_13C, @Syscall_13D, @Syscall_13E, @Syscall_13F,
    @Syscall_140, @Syscall_141, @Syscall_142, @Syscall_143, @Syscall_144,
    @Syscall_145, @Syscall_146, @Syscall_147, @Syscall_148, @Syscall_149,
    @Syscall_14A, @Syscall_14B, @Syscall_14C, @Syscall_14D, @Syscall_14E,
    @Syscall_14F, @Syscall_150, @Syscall_151, @Syscall_152, @Syscall_153,
    @Syscall_154, @Syscall_155, @Syscall_156, @Syscall_157, @Syscall_158,
    @Syscall_159, @Syscall_15A, @Syscall_15B, @Syscall_15C, @Syscall_15D,
    @Syscall_15E, @Syscall_15F, @Syscall_160, @Syscall_161, @Syscall_162,
    @Syscall_163, @Syscall_164, @Syscall_165, @Syscall_166, @Syscall_167,
    @Syscall_168, @Syscall_169, @Syscall_16A, @Syscall_16B, @Syscall_16C,
    @Syscall_16D, @Syscall_16E, @Syscall_16F, @Syscall_170, @Syscall_171,
    @Syscall_172, @Syscall_173, @Syscall_174, @Syscall_175, @Syscall_176,
    @Syscall_177, @Syscall_178, @Syscall_179, @Syscall_17A, @Syscall_17B,
    @Syscall_17C, @Syscall_17D, @Syscall_17E, @Syscall_17F, @Syscall_180,
    @Syscall_181, @Syscall_182, @Syscall_183, @Syscall_184, @Syscall_185,
    @Syscall_186, @Syscall_187, @Syscall_188, @Syscall_189, @Syscall_18A,
    @Syscall_18B, @Syscall_18C, @Syscall_18D, @Syscall_18E, @Syscall_18F,
    @Syscall_190, @Syscall_191, @Syscall_192, @Syscall_193, @Syscall_194,
    @Syscall_195, @Syscall_196, @Syscall_197, @Syscall_198, @Syscall_199,
    @Syscall_19A, @Syscall_19B, @Syscall_19C, @Syscall_19D, @Syscall_19E,
    @Syscall_19F, @Syscall_1A0, @Syscall_1A1, @Syscall_1A2, @Syscall_1A3,
    @Syscall_1A4, @Syscall_1A5, @Syscall_1A6, @Syscall_1A7, @Syscall_1A8,
    @Syscall_1A9, @Syscall_1AA, @Syscall_1AB, @Syscall_1AC, @Syscall_1AD,
    @Syscall_1AE, @Syscall_1AF, @Syscall_1B0, @Syscall_1B1, @Syscall_1B2,
    @Syscall_1B3, @Syscall_1B4, @Syscall_1B5, @Syscall_1B6, @Syscall_1B7,
    @Syscall_1B8, @Syscall_1B9, @Syscall_1BA, @Syscall_1BB, @Syscall_1BC,
    @Syscall_1BD, @Syscall_1BE, @Syscall_1BF, @Syscall_1C0, @Syscall_1C1,
    @Syscall_1C2, @Syscall_1C3, @Syscall_1C4, @Syscall_1C5, @Syscall_1C6,
    @Syscall_1C7, @Syscall_1C8, @Syscall_1C9, @Syscall_1CA, @Syscall_1CB,
    @Syscall_1CC, @Syscall_1CD, @Syscall_1CE, @Syscall_1CF, @Syscall_1D0,
    @Syscall_1D1, @Syscall_1D2, @Syscall_1D3, @Syscall_1D4, @Syscall_1D5,
    @Syscall_1D6, @Syscall_1D7, @Syscall_1D8, @Syscall_1D9, @Syscall_1DA,
    @Syscall_1DB, @Syscall_1DC, @Syscall_1DD, @Syscall_1DE, @Syscall_1DF,
    @Syscall_1E0, @Syscall_1E1, @Syscall_1E2, @Syscall_1E3, @Syscall_1E4,
    @Syscall_1E5, @Syscall_1E6, @Syscall_1E7, @Syscall_1E8, @Syscall_1E9,
    @Syscall_1EA, @Syscall_1EB, @Syscall_1EC, @Syscall_1ED, @Syscall_1EE,
    @Syscall_1EF, @Syscall_1F0, @Syscall_1F1, @Syscall_1F2, @Syscall_1F3,
    @Syscall_1F4, @Syscall_1F5, @Syscall_1F6, @Syscall_1F7, @Syscall_1F8,
    @Syscall_1F9, @Syscall_1FA, @Syscall_1FB, @Syscall_1FC, @Syscall_1FD,
    @Syscall_1FE, @Syscall_1FF, @Syscall_200, @Syscall_201, @Syscall_202,
    @Syscall_203, @Syscall_204, @Syscall_205, @Syscall_206, @Syscall_207,
    @Syscall_208, @Syscall_209, @Syscall_20A, @Syscall_20B, @Syscall_20C,
    @Syscall_20D, @Syscall_20E, @Syscall_20F, @Syscall_210, @Syscall_211,
    @Syscall_212, @Syscall_213, @Syscall_214, @Syscall_215, @Syscall_216,
    @Syscall_217, @Syscall_218, @Syscall_219, @Syscall_21A, @Syscall_21B,
    @Syscall_21C, @Syscall_21D, @Syscall_21E, @Syscall_21F, @Syscall_220,
    @Syscall_221, @Syscall_222, @Syscall_223, @Syscall_224, @Syscall_225,
    @Syscall_226, @Syscall_227, @Syscall_228, @Syscall_229, @Syscall_22A,
    @Syscall_22B, @Syscall_22C, @Syscall_22D, @Syscall_22E, @Syscall_22F,
    @Syscall_230, @Syscall_231, @Syscall_232, @Syscall_233, @Syscall_234,
    @Syscall_235, @Syscall_236, @Syscall_237, @Syscall_238, @Syscall_239,
    @Syscall_23A, @Syscall_23B, @Syscall_23C, @Syscall_23D, @Syscall_23E,
    @Syscall_23F, @Syscall_240, @Syscall_241, @Syscall_242, @Syscall_243,
    @Syscall_244, @Syscall_245, @Syscall_246, @Syscall_247, @Syscall_248,
    @Syscall_249, @Syscall_24A, @Syscall_24B, @Syscall_24C, @Syscall_24D,
    @Syscall_24E, @Syscall_24F, @Syscall_250, @Syscall_251, @Syscall_252,
    @Syscall_253, @Syscall_254, @Syscall_255, @Syscall_256, @Syscall_257,
    @Syscall_258, @Syscall_259, @Syscall_25A, @Syscall_25B, @Syscall_25C,
    @Syscall_25D, @Syscall_25E, @Syscall_25F, @Syscall_260, @Syscall_261,
    @Syscall_262, @Syscall_263, @Syscall_264, @Syscall_265, @Syscall_266,
    @Syscall_267, @Syscall_268, @Syscall_269, @Syscall_26A, @Syscall_26B,
    @Syscall_26C, @Syscall_26D, @Syscall_26E, @Syscall_26F, @Syscall_270,
    @Syscall_271, @Syscall_272, @Syscall_273, @Syscall_274, @Syscall_275,
    @Syscall_276, @Syscall_277, @Syscall_278, @Syscall_279, @Syscall_27A,
    @Syscall_27B, @Syscall_27C, @Syscall_27D, @Syscall_27E, @Syscall_27F,
    @Syscall_280, @Syscall_281, @Syscall_282, @Syscall_283, @Syscall_284,
    @Syscall_285, @Syscall_286, @Syscall_287, @Syscall_288, @Syscall_289,
    @Syscall_28A, @Syscall_28B, @Syscall_28C, @Syscall_28D, @Syscall_28E,
    @Syscall_28F, @Syscall_290, @Syscall_291, @Syscall_292, @Syscall_293,
    @Syscall_294, @Syscall_295, @Syscall_296, @Syscall_297, @Syscall_298,
    @Syscall_299, @Syscall_29A, @Syscall_29B, @Syscall_29C, @Syscall_29D,
    @Syscall_29E, @Syscall_29F, @Syscall_2A0, @Syscall_2A1, @Syscall_2A2,
    @Syscall_2A3, @Syscall_2A4, @Syscall_2A5, @Syscall_2A6, @Syscall_2A7,
    @Syscall_2A8, @Syscall_2A9, @Syscall_2AA, @Syscall_2AB, @Syscall_2AC,
    @Syscall_2AD, @Syscall_2AE, @Syscall_2AF, @Syscall_2B0, @Syscall_2B1,
    @Syscall_2B2, @Syscall_2B3, @Syscall_2B4, @Syscall_2B5, @Syscall_2B6,
    @Syscall_2B7, @Syscall_2B8, @Syscall_2B9, @Syscall_2BA, @Syscall_2BB,
    @Syscall_2BC, @Syscall_2BD, @Syscall_2BE, @Syscall_2BF, @Syscall_2C0,
    @Syscall_2C1, @Syscall_2C2, @Syscall_2C3, @Syscall_2C4, @Syscall_2C5,
    @Syscall_2C6, @Syscall_2C7, @Syscall_2C8, @Syscall_2C9, @Syscall_2CA,
    @Syscall_2CB, @Syscall_2CC, @Syscall_2CD, @Syscall_2CE, @Syscall_2CF,
    @Syscall_2D0, @Syscall_2D1, @Syscall_2D2, @Syscall_2D3, @Syscall_2D4,
    @Syscall_2D5, @Syscall_2D6, @Syscall_2D7, @Syscall_2D8, @Syscall_2D9,
    @Syscall_2DA, @Syscall_2DB, @Syscall_2DC, @Syscall_2DD, @Syscall_2DE,
    @Syscall_2DF, @Syscall_2E0, @Syscall_2E1, @Syscall_2E2, @Syscall_2E3,
    @Syscall_2E4, @Syscall_2E5, @Syscall_2E6, @Syscall_2E7, @Syscall_2E8,
    @Syscall_2E9, @Syscall_2EA, @Syscall_2EB, @Syscall_2EC, @Syscall_2ED,
    @Syscall_2EE, @Syscall_2EF, @Syscall_2F0, @Syscall_2F1, @Syscall_2F2,
    @Syscall_2F3, @Syscall_2F4, @Syscall_2F5, @Syscall_2F6, @Syscall_2F7,
    @Syscall_2F8, @Syscall_2F9, @Syscall_2FA, @Syscall_2FB, @Syscall_2FC,
    @Syscall_2FD, @Syscall_2FE, @Syscall_2FF, @Syscall_300, @Syscall_301,
    @Syscall_302, @Syscall_303, @Syscall_304, @Syscall_305, @Syscall_306,
    @Syscall_307, @Syscall_308, @Syscall_309, @Syscall_30A, @Syscall_30B,
    @Syscall_30C, @Syscall_30D, @Syscall_30E, @Syscall_30F, @Syscall_310,
    @Syscall_311, @Syscall_312, @Syscall_313, @Syscall_314, @Syscall_315,
    @Syscall_316, @Syscall_317, @Syscall_318, @Syscall_319, @Syscall_31A,
    @Syscall_31B, @Syscall_31C, @Syscall_31D, @Syscall_31E, @Syscall_31F,
    @Syscall_320, @Syscall_321, @Syscall_322, @Syscall_323, @Syscall_324,
    @Syscall_325, @Syscall_326, @Syscall_327, @Syscall_328, @Syscall_329,
    @Syscall_32A, @Syscall_32B, @Syscall_32C, @Syscall_32D, @Syscall_32E,
    @Syscall_32F, @Syscall_330, @Syscall_331, @Syscall_332, @Syscall_333,
    @Syscall_334, @Syscall_335, @Syscall_336, @Syscall_337, @Syscall_338,
    @Syscall_339, @Syscall_33A, @Syscall_33B, @Syscall_33C, @Syscall_33D,
    @Syscall_33E, @Syscall_33F, @Syscall_340, @Syscall_341, @Syscall_342,
    @Syscall_343, @Syscall_344, @Syscall_345, @Syscall_346, @Syscall_347,
    @Syscall_348, @Syscall_349, @Syscall_34A, @Syscall_34B, @Syscall_34C,
    @Syscall_34D, @Syscall_34E, @Syscall_34F, @Syscall_350, @Syscall_351,
    @Syscall_352, @Syscall_353, @Syscall_354, @Syscall_355, @Syscall_356,
    @Syscall_357, @Syscall_358, @Syscall_359, @Syscall_35A, @Syscall_35B,
    @Syscall_35C, @Syscall_35D, @Syscall_35E, @Syscall_35F, @Syscall_360,
    @Syscall_361, @Syscall_362, @Syscall_363, @Syscall_364, @Syscall_365,
    @Syscall_366, @Syscall_367, @Syscall_368, @Syscall_369, @Syscall_36A,
    @Syscall_36B, @Syscall_36C, @Syscall_36D, @Syscall_36E, @Syscall_36F,
    @Syscall_370, @Syscall_371, @Syscall_372, @Syscall_373, @Syscall_374,
    @Syscall_375, @Syscall_376, @Syscall_377, @Syscall_378, @Syscall_379,
    @Syscall_37A, @Syscall_37B, @Syscall_37C, @Syscall_37D, @Syscall_37E,
    @Syscall_37F, @Syscall_380, @Syscall_381, @Syscall_382, @Syscall_383,
    @Syscall_384, @Syscall_385, @Syscall_386, @Syscall_387, @Syscall_388,
    @Syscall_389, @Syscall_38A, @Syscall_38B, @Syscall_38C, @Syscall_38D,
    @Syscall_38E, @Syscall_38F, @Syscall_390, @Syscall_391, @Syscall_392,
    @Syscall_393, @Syscall_394, @Syscall_395, @Syscall_396, @Syscall_397,
    @Syscall_398, @Syscall_399, @Syscall_39A, @Syscall_39B, @Syscall_39C,
    @Syscall_39D, @Syscall_39E, @Syscall_39F, @Syscall_3A0, @Syscall_3A1,
    @Syscall_3A2, @Syscall_3A3, @Syscall_3A4, @Syscall_3A5, @Syscall_3A6,
    @Syscall_3A7, @Syscall_3A8, @Syscall_3A9, @Syscall_3AA, @Syscall_3AB,
    @Syscall_3AC, @Syscall_3AD, @Syscall_3AE, @Syscall_3AF, @Syscall_3B0,
    @Syscall_3B1, @Syscall_3B2, @Syscall_3B3, @Syscall_3B4, @Syscall_3B5,
    @Syscall_3B6, @Syscall_3B7, @Syscall_3B8, @Syscall_3B9, @Syscall_3BA,
    @Syscall_3BB, @Syscall_3BC, @Syscall_3BD, @Syscall_3BE, @Syscall_3BF,
    @Syscall_3C0, @Syscall_3C1, @Syscall_3C2, @Syscall_3C3, @Syscall_3C4,
    @Syscall_3C5, @Syscall_3C6, @Syscall_3C7, @Syscall_3C8, @Syscall_3C9,
    @Syscall_3CA, @Syscall_3CB, @Syscall_3CC, @Syscall_3CD, @Syscall_3CE,
    @Syscall_3CF, @Syscall_3D0, @Syscall_3D1, @Syscall_3D2, @Syscall_3D3,
    @Syscall_3D4, @Syscall_3D5, @Syscall_3D6, @Syscall_3D7, @Syscall_3D8,
    @Syscall_3D9, @Syscall_3DA, @Syscall_3DB, @Syscall_3DC, @Syscall_3DD,
    @Syscall_3DE, @Syscall_3DF, @Syscall_3E0, @Syscall_3E1, @Syscall_3E2,
    @Syscall_3E3, @Syscall_3E4, @Syscall_3E5, @Syscall_3E6, @Syscall_3E7,
    @Syscall_3E8, @Syscall_3E9, @Syscall_3EA, @Syscall_3EB, @Syscall_3EC,
    @Syscall_3ED, @Syscall_3EE, @Syscall_3EF, @Syscall_3F0, @Syscall_3F1,
    @Syscall_3F2, @Syscall_3F3, @Syscall_3F4, @Syscall_3F5, @Syscall_3F6,
    @Syscall_3F7, @Syscall_3F8, @Syscall_3F9, @Syscall_3FA, @Syscall_3FB,
    @Syscall_3FC, @Syscall_3FD, @Syscall_3FE, @Syscall_3FF, @Syscall_400,
    @Syscall_401, @Syscall_402, @Syscall_403, @Syscall_404, @Syscall_405,
    @Syscall_406, @Syscall_407, @Syscall_408, @Syscall_409, @Syscall_40A,
    @Syscall_40B, @Syscall_40C, @Syscall_40D, @Syscall_40E, @Syscall_40F,
    @Syscall_410, @Syscall_411, @Syscall_412, @Syscall_413, @Syscall_414,
    @Syscall_415, @Syscall_416, @Syscall_417, @Syscall_418, @Syscall_419,
    @Syscall_41A, @Syscall_41B, @Syscall_41C, @Syscall_41D, @Syscall_41E,
    @Syscall_41F, @Syscall_420, @Syscall_421, @Syscall_422, @Syscall_423,
    @Syscall_424, @Syscall_425, @Syscall_426, @Syscall_427, @Syscall_428,
    @Syscall_429, @Syscall_42A, @Syscall_42B, @Syscall_42C, @Syscall_42D,
    @Syscall_42E, @Syscall_42F, @Syscall_430, @Syscall_431, @Syscall_432,
    @Syscall_433, @Syscall_434, @Syscall_435, @Syscall_436, @Syscall_437,
    @Syscall_438, @Syscall_439, @Syscall_43A, @Syscall_43B, @Syscall_43C,
    @Syscall_43D, @Syscall_43E, @Syscall_43F, @Syscall_440, @Syscall_441,
    @Syscall_442, @Syscall_443, @Syscall_444, @Syscall_445, @Syscall_446,
    @Syscall_447, @Syscall_448, @Syscall_449, @Syscall_44A, @Syscall_44B,
    @Syscall_44C, @Syscall_44D, @Syscall_44E, @Syscall_44F, @Syscall_450,
    @Syscall_451, @Syscall_452, @Syscall_453, @Syscall_454, @Syscall_455,
    @Syscall_456, @Syscall_457, @Syscall_458, @Syscall_459, @Syscall_45A,
    @Syscall_45B, @Syscall_45C, @Syscall_45D, @Syscall_45E, @Syscall_45F,
    @Syscall_460, @Syscall_461, @Syscall_462, @Syscall_463, @Syscall_464,
    @Syscall_465, @Syscall_466, @Syscall_467, @Syscall_468, @Syscall_469,
    @Syscall_46A, @Syscall_46B, @Syscall_46C, @Syscall_46D, @Syscall_46E,
    @Syscall_46F, @Syscall_470, @Syscall_471, @Syscall_472, @Syscall_473,
    @Syscall_474, @Syscall_475, @Syscall_476, @Syscall_477, @Syscall_478,
    @Syscall_479, @Syscall_47A, @Syscall_47B, @Syscall_47C, @Syscall_47D,
    @Syscall_47E, @Syscall_47F, @Syscall_480, @Syscall_481, @Syscall_482,
    @Syscall_483, @Syscall_484, @Syscall_485, @Syscall_486, @Syscall_487,
    @Syscall_488, @Syscall_489, @Syscall_48A, @Syscall_48B, @Syscall_48C,
    @Syscall_48D, @Syscall_48E, @Syscall_48F, @Syscall_490, @Syscall_491,
    @Syscall_492, @Syscall_493, @Syscall_494, @Syscall_495, @Syscall_496,
    @Syscall_497, @Syscall_498, @Syscall_499, @Syscall_49A, @Syscall_49B,
    @Syscall_49C, @Syscall_49D, @Syscall_49E, @Syscall_49F, @Syscall_4A0,
    @Syscall_4A1, @Syscall_4A2, @Syscall_4A3, @Syscall_4A4, @Syscall_4A5,
    @Syscall_4A6, @Syscall_4A7, @Syscall_4A8, @Syscall_4A9, @Syscall_4AA,
    @Syscall_4AB, @Syscall_4AC, @Syscall_4AD, @Syscall_4AE, @Syscall_4AF,
    @Syscall_4B0, @Syscall_4B1, @Syscall_4B2, @Syscall_4B3, @Syscall_4B4,
    @Syscall_4B5, @Syscall_4B6, @Syscall_4B7, @Syscall_4B8, @Syscall_4B9,
    @Syscall_4BA, @Syscall_4BB, @Syscall_4BC, @Syscall_4BD, @Syscall_4BE,
    @Syscall_4BF, @Syscall_4C0, @Syscall_4C1, @Syscall_4C2, @Syscall_4C3,
    @Syscall_4C4, @Syscall_4C5, @Syscall_4C6, @Syscall_4C7, @Syscall_4C8,
    @Syscall_4C9, @Syscall_4CA, @Syscall_4CB, @Syscall_4CC, @Syscall_4CD,
    @Syscall_4CE, @Syscall_4CF, @Syscall_4D0, @Syscall_4D1, @Syscall_4D2,
    @Syscall_4D3, @Syscall_4D4, @Syscall_4D5, @Syscall_4D6, @Syscall_4D7,
    @Syscall_4D8, @Syscall_4D9, @Syscall_4DA, @Syscall_4DB, @Syscall_4DC,
    @Syscall_4DD, @Syscall_4DE, @Syscall_4DF, @Syscall_4E0, @Syscall_4E1,
    @Syscall_4E2, @Syscall_4E3, @Syscall_4E4, @Syscall_4E5, @Syscall_4E6,
    @Syscall_4E7, @Syscall_4E8, @Syscall_4E9, @Syscall_4EA, @Syscall_4EB,
    @Syscall_4EC, @Syscall_4ED, @Syscall_4EE, @Syscall_4EF, @Syscall_4F0,
    @Syscall_4F1, @Syscall_4F2, @Syscall_4F3, @Syscall_4F4, @Syscall_4F5,
    @Syscall_4F6, @Syscall_4F7, @Syscall_4F8, @Syscall_4F9, @Syscall_4FA,
    @Syscall_4FB, @Syscall_4FC, @Syscall_4FD, @Syscall_4FE, @Syscall_4FF,
    @Syscall_500, @Syscall_501, @Syscall_502, @Syscall_503, @Syscall_504,
    @Syscall_505, @Syscall_506, @Syscall_507, @Syscall_508, @Syscall_509,
    @Syscall_50A, @Syscall_50B, @Syscall_50C, @Syscall_50D, @Syscall_50E,
    @Syscall_50F, @Syscall_510, @Syscall_511, @Syscall_512, @Syscall_513,
    @Syscall_514, @Syscall_515, @Syscall_516, @Syscall_517, @Syscall_518,
    @Syscall_519, @Syscall_51A, @Syscall_51B, @Syscall_51C, @Syscall_51D,
    @Syscall_51E, @Syscall_51F, @Syscall_520, @Syscall_521, @Syscall_522,
    @Syscall_523, @Syscall_524, @Syscall_525, @Syscall_526, @Syscall_527,
    @Syscall_528, @Syscall_529, @Syscall_52A, @Syscall_52B, @Syscall_52C,
    @Syscall_52D, @Syscall_52E, @Syscall_52F, @Syscall_530, @Syscall_531,
    @Syscall_532, @Syscall_533, @Syscall_534, @Syscall_535, @Syscall_536,
    @Syscall_537, @Syscall_538, @Syscall_539, @Syscall_53A, @Syscall_53B,
    @Syscall_53C, @Syscall_53D, @Syscall_53E, @Syscall_53F, @Syscall_540,
    @Syscall_541, @Syscall_542, @Syscall_543, @Syscall_544, @Syscall_545,
    @Syscall_546, @Syscall_547, @Syscall_548, @Syscall_549, @Syscall_54A,
    @Syscall_54B, @Syscall_54C, @Syscall_54D, @Syscall_54E, @Syscall_54F,
    @Syscall_550, @Syscall_551, @Syscall_552, @Syscall_553, @Syscall_554,
    @Syscall_555, @Syscall_556, @Syscall_557, @Syscall_558, @Syscall_559,
    @Syscall_55A, @Syscall_55B, @Syscall_55C, @Syscall_55D, @Syscall_55E,
    @Syscall_55F, @Syscall_560, @Syscall_561, @Syscall_562, @Syscall_563,
    @Syscall_564, @Syscall_565, @Syscall_566, @Syscall_567, @Syscall_568,
    @Syscall_569, @Syscall_56A, @Syscall_56B, @Syscall_56C, @Syscall_56D,
    @Syscall_56E, @Syscall_56F, @Syscall_570, @Syscall_571, @Syscall_572,
    @Syscall_573, @Syscall_574, @Syscall_575, @Syscall_576, @Syscall_577,
    @Syscall_578, @Syscall_579, @Syscall_57A, @Syscall_57B, @Syscall_57C,
    @Syscall_57D, @Syscall_57E, @Syscall_57F, @Syscall_580, @Syscall_581,
    @Syscall_582, @Syscall_583, @Syscall_584, @Syscall_585, @Syscall_586,
    @Syscall_587, @Syscall_588, @Syscall_589, @Syscall_58A, @Syscall_58B,
    @Syscall_58C, @Syscall_58D, @Syscall_58E, @Syscall_58F, @Syscall_590,
    @Syscall_591, @Syscall_592, @Syscall_593, @Syscall_594, @Syscall_595,
    @Syscall_596, @Syscall_597, @Syscall_598, @Syscall_599, @Syscall_59A,
    @Syscall_59B, @Syscall_59C, @Syscall_59D, @Syscall_59E, @Syscall_59F,
    @Syscall_5A0, @Syscall_5A1, @Syscall_5A2, @Syscall_5A3, @Syscall_5A4,
    @Syscall_5A5, @Syscall_5A6, @Syscall_5A7, @Syscall_5A8, @Syscall_5A9,
    @Syscall_5AA, @Syscall_5AB, @Syscall_5AC, @Syscall_5AD, @Syscall_5AE,
    @Syscall_5AF, @Syscall_5B0, @Syscall_5B1, @Syscall_5B2, @Syscall_5B3,
    @Syscall_5B4, @Syscall_5B5, @Syscall_5B6, @Syscall_5B7, @Syscall_5B8,
    @Syscall_5B9, @Syscall_5BA, @Syscall_5BB, @Syscall_5BC, @Syscall_5BD,
    @Syscall_5BE, @Syscall_5BF, @Syscall_5C0, @Syscall_5C1, @Syscall_5C2,
    @Syscall_5C3, @Syscall_5C4, @Syscall_5C5, @Syscall_5C6, @Syscall_5C7,
    @Syscall_5C8, @Syscall_5C9, @Syscall_5CA, @Syscall_5CB, @Syscall_5CC,
    @Syscall_5CD, @Syscall_5CE, @Syscall_5CF, @Syscall_5D0, @Syscall_5D1,
    @Syscall_5D2, @Syscall_5D3, @Syscall_5D4, @Syscall_5D5, @Syscall_5D6,
    @Syscall_5D7, @Syscall_5D8, @Syscall_5D9, @Syscall_5DA, @Syscall_5DB,
    @Syscall_5DC, @Syscall_5DD, @Syscall_5DE, @Syscall_5DF, @Syscall_5E0,
    @Syscall_5E1, @Syscall_5E2, @Syscall_5E3, @Syscall_5E4, @Syscall_5E5,
    @Syscall_5E6, @Syscall_5E7, @Syscall_5E8, @Syscall_5E9, @Syscall_5EA,
    @Syscall_5EB, @Syscall_5EC, @Syscall_5ED, @Syscall_5EE, @Syscall_5EF,
    @Syscall_5F0, @Syscall_5F1, @Syscall_5F2, @Syscall_5F3, @Syscall_5F4,
    @Syscall_5F5, @Syscall_5F6, @Syscall_5F7, @Syscall_5F8, @Syscall_5F9,
    @Syscall_5FA, @Syscall_5FB, @Syscall_5FC, @Syscall_5FD, @Syscall_5FE,
    @Syscall_5FF, @Syscall_600, @Syscall_601, @Syscall_602, @Syscall_603,
    @Syscall_604, @Syscall_605, @Syscall_606, @Syscall_607, @Syscall_608,
    @Syscall_609, @Syscall_60A, @Syscall_60B, @Syscall_60C, @Syscall_60D,
    @Syscall_60E, @Syscall_60F, @Syscall_610, @Syscall_611, @Syscall_612,
    @Syscall_613, @Syscall_614, @Syscall_615, @Syscall_616, @Syscall_617,
    @Syscall_618, @Syscall_619, @Syscall_61A, @Syscall_61B, @Syscall_61C,
    @Syscall_61D, @Syscall_61E, @Syscall_61F, @Syscall_620, @Syscall_621,
    @Syscall_622, @Syscall_623, @Syscall_624, @Syscall_625, @Syscall_626,
    @Syscall_627, @Syscall_628, @Syscall_629, @Syscall_62A, @Syscall_62B,
    @Syscall_62C, @Syscall_62D, @Syscall_62E, @Syscall_62F, @Syscall_630,
    @Syscall_631, @Syscall_632, @Syscall_633, @Syscall_634, @Syscall_635,
    @Syscall_636, @Syscall_637, @Syscall_638, @Syscall_639, @Syscall_63A,
    @Syscall_63B, @Syscall_63C, @Syscall_63D, @Syscall_63E, @Syscall_63F,
    @Syscall_640, @Syscall_641, @Syscall_642, @Syscall_643, @Syscall_644,
    @Syscall_645, @Syscall_646, @Syscall_647, @Syscall_648, @Syscall_649,
    @Syscall_64A, @Syscall_64B, @Syscall_64C, @Syscall_64D, @Syscall_64E,
    @Syscall_64F, @Syscall_650, @Syscall_651, @Syscall_652, @Syscall_653,
    @Syscall_654, @Syscall_655, @Syscall_656, @Syscall_657, @Syscall_658,
    @Syscall_659, @Syscall_65A, @Syscall_65B, @Syscall_65C, @Syscall_65D,
    @Syscall_65E, @Syscall_65F, @Syscall_660, @Syscall_661, @Syscall_662,
    @Syscall_663, @Syscall_664, @Syscall_665, @Syscall_666, @Syscall_667,
    @Syscall_668, @Syscall_669, @Syscall_66A, @Syscall_66B, @Syscall_66C,
    @Syscall_66D, @Syscall_66E, @Syscall_66F, @Syscall_670, @Syscall_671,
    @Syscall_672, @Syscall_673, @Syscall_674, @Syscall_675, @Syscall_676,
    @Syscall_677, @Syscall_678, @Syscall_679, @Syscall_67A, @Syscall_67B,
    @Syscall_67C, @Syscall_67D, @Syscall_67E, @Syscall_67F, @Syscall_680,
    @Syscall_681, @Syscall_682, @Syscall_683, @Syscall_684, @Syscall_685,
    @Syscall_686, @Syscall_687, @Syscall_688, @Syscall_689, @Syscall_68A,
    @Syscall_68B, @Syscall_68C, @Syscall_68D, @Syscall_68E, @Syscall_68F,
    @Syscall_690, @Syscall_691, @Syscall_692, @Syscall_693, @Syscall_694,
    @Syscall_695, @Syscall_696, @Syscall_697, @Syscall_698, @Syscall_699,
    @Syscall_69A, @Syscall_69B, @Syscall_69C, @Syscall_69D, @Syscall_69E,
    @Syscall_69F, @Syscall_6A0, @Syscall_6A1, @Syscall_6A2, @Syscall_6A3,
    @Syscall_6A4, @Syscall_6A5, @Syscall_6A6, @Syscall_6A7, @Syscall_6A8,
    @Syscall_6A9, @Syscall_6AA, @Syscall_6AB, @Syscall_6AC, @Syscall_6AD,
    @Syscall_6AE, @Syscall_6AF, @Syscall_6B0, @Syscall_6B1, @Syscall_6B2,
    @Syscall_6B3, @Syscall_6B4, @Syscall_6B5, @Syscall_6B6, @Syscall_6B7,
    @Syscall_6B8, @Syscall_6B9, @Syscall_6BA, @Syscall_6BB, @Syscall_6BC,
    @Syscall_6BD, @Syscall_6BE, @Syscall_6BF, @Syscall_6C0, @Syscall_6C1,
    @Syscall_6C2, @Syscall_6C3, @Syscall_6C4, @Syscall_6C5, @Syscall_6C6,
    @Syscall_6C7, @Syscall_6C8, @Syscall_6C9, @Syscall_6CA, @Syscall_6CB,
    @Syscall_6CC, @Syscall_6CD, @Syscall_6CE, @Syscall_6CF, @Syscall_6D0,
    @Syscall_6D1, @Syscall_6D2, @Syscall_6D3, @Syscall_6D4, @Syscall_6D5,
    @Syscall_6D6, @Syscall_6D7, @Syscall_6D8, @Syscall_6D9, @Syscall_6DA,
    @Syscall_6DB, @Syscall_6DC, @Syscall_6DD, @Syscall_6DE, @Syscall_6DF,
    @Syscall_6E0, @Syscall_6E1, @Syscall_6E2, @Syscall_6E3, @Syscall_6E4,
    @Syscall_6E5, @Syscall_6E6, @Syscall_6E7, @Syscall_6E8, @Syscall_6E9,
    @Syscall_6EA, @Syscall_6EB, @Syscall_6EC, @Syscall_6ED, @Syscall_6EE,
    @Syscall_6EF, @Syscall_6F0, @Syscall_6F1, @Syscall_6F2, @Syscall_6F3,
    @Syscall_6F4, @Syscall_6F5, @Syscall_6F6, @Syscall_6F7, @Syscall_6F8,
    @Syscall_6F9, @Syscall_6FA, @Syscall_6FB, @Syscall_6FC, @Syscall_6FD,
    @Syscall_6FE, @Syscall_6FF, @Syscall_700, @Syscall_701, @Syscall_702,
    @Syscall_703, @Syscall_704, @Syscall_705, @Syscall_706, @Syscall_707,
    @Syscall_708, @Syscall_709, @Syscall_70A, @Syscall_70B, @Syscall_70C,
    @Syscall_70D, @Syscall_70E, @Syscall_70F, @Syscall_710, @Syscall_711,
    @Syscall_712, @Syscall_713, @Syscall_714, @Syscall_715, @Syscall_716,
    @Syscall_717, @Syscall_718, @Syscall_719, @Syscall_71A, @Syscall_71B,
    @Syscall_71C, @Syscall_71D, @Syscall_71E, @Syscall_71F, @Syscall_720,
    @Syscall_721, @Syscall_722, @Syscall_723, @Syscall_724, @Syscall_725,
    @Syscall_726, @Syscall_727, @Syscall_728, @Syscall_729, @Syscall_72A,
    @Syscall_72B, @Syscall_72C, @Syscall_72D, @Syscall_72E, @Syscall_72F,
    @Syscall_730, @Syscall_731, @Syscall_732, @Syscall_733, @Syscall_734,
    @Syscall_735, @Syscall_736, @Syscall_737, @Syscall_738, @Syscall_739,
    @Syscall_73A, @Syscall_73B, @Syscall_73C, @Syscall_73D, @Syscall_73E,
    @Syscall_73F, @Syscall_740, @Syscall_741, @Syscall_742, @Syscall_743,
    @Syscall_744, @Syscall_745, @Syscall_746, @Syscall_747, @Syscall_748,
    @Syscall_749, @Syscall_74A, @Syscall_74B, @Syscall_74C, @Syscall_74D,
    @Syscall_74E, @Syscall_74F, @Syscall_750, @Syscall_751, @Syscall_752,
    @Syscall_753, @Syscall_754, @Syscall_755, @Syscall_756, @Syscall_757,
    @Syscall_758, @Syscall_759, @Syscall_75A, @Syscall_75B, @Syscall_75C,
    @Syscall_75D, @Syscall_75E, @Syscall_75F, @Syscall_760, @Syscall_761,
    @Syscall_762, @Syscall_763, @Syscall_764, @Syscall_765, @Syscall_766,
    @Syscall_767, @Syscall_768, @Syscall_769, @Syscall_76A, @Syscall_76B,
    @Syscall_76C, @Syscall_76D, @Syscall_76E, @Syscall_76F, @Syscall_770,
    @Syscall_771, @Syscall_772, @Syscall_773, @Syscall_774, @Syscall_775,
    @Syscall_776, @Syscall_777, @Syscall_778, @Syscall_779, @Syscall_77A,
    @Syscall_77B, @Syscall_77C, @Syscall_77D, @Syscall_77E, @Syscall_77F,
    @Syscall_780, @Syscall_781, @Syscall_782, @Syscall_783, @Syscall_784,
    @Syscall_785, @Syscall_786, @Syscall_787, @Syscall_788, @Syscall_789,
    @Syscall_78A, @Syscall_78B, @Syscall_78C, @Syscall_78D, @Syscall_78E,
    @Syscall_78F, @Syscall_790, @Syscall_791, @Syscall_792, @Syscall_793,
    @Syscall_794, @Syscall_795, @Syscall_796, @Syscall_797, @Syscall_798,
    @Syscall_799, @Syscall_79A, @Syscall_79B, @Syscall_79C, @Syscall_79D,
    @Syscall_79E, @Syscall_79F, @Syscall_7A0, @Syscall_7A1, @Syscall_7A2,
    @Syscall_7A3, @Syscall_7A4, @Syscall_7A5, @Syscall_7A6, @Syscall_7A7,
    @Syscall_7A8, @Syscall_7A9, @Syscall_7AA, @Syscall_7AB, @Syscall_7AC,
    @Syscall_7AD, @Syscall_7AE, @Syscall_7AF, @Syscall_7B0, @Syscall_7B1,
    @Syscall_7B2, @Syscall_7B3, @Syscall_7B4, @Syscall_7B5, @Syscall_7B6,
    @Syscall_7B7, @Syscall_7B8, @Syscall_7B9, @Syscall_7BA, @Syscall_7BB,
    @Syscall_7BC, @Syscall_7BD, @Syscall_7BE, @Syscall_7BF, @Syscall_7C0,
    @Syscall_7C1, @Syscall_7C2, @Syscall_7C3, @Syscall_7C4, @Syscall_7C5,
    @Syscall_7C6, @Syscall_7C7, @Syscall_7C8, @Syscall_7C9, @Syscall_7CA,
    @Syscall_7CB, @Syscall_7CC, @Syscall_7CD, @Syscall_7CE, @Syscall_7CF,
    @Syscall_7D0, @Syscall_7D1, @Syscall_7D2, @Syscall_7D3, @Syscall_7D4,
    @Syscall_7D5, @Syscall_7D6, @Syscall_7D7, @Syscall_7D8, @Syscall_7D9,
    @Syscall_7DA, @Syscall_7DB, @Syscall_7DC, @Syscall_7DD, @Syscall_7DE,
    @Syscall_7DF, @Syscall_7E0, @Syscall_7E1, @Syscall_7E2, @Syscall_7E3,
    @Syscall_7E4, @Syscall_7E5, @Syscall_7E6, @Syscall_7E7, @Syscall_7E8,
    @Syscall_7E9, @Syscall_7EA, @Syscall_7EB, @Syscall_7EC, @Syscall_7ED,
    @Syscall_7EE, @Syscall_7EF, @Syscall_7F0, @Syscall_7F1, @Syscall_7F2,
    @Syscall_7F3, @Syscall_7F4, @Syscall_7F5, @Syscall_7F6, @Syscall_7F7,
    @Syscall_7F8, @Syscall_7F9, @Syscall_7FA, @Syscall_7FB, @Syscall_7FC,
    @Syscall_7FD, @Syscall_7FE, @Syscall_7FF, @Syscall_800, @Syscall_801,
    @Syscall_802, @Syscall_803, @Syscall_804, @Syscall_805, @Syscall_806,
    @Syscall_807, @Syscall_808, @Syscall_809, @Syscall_80A, @Syscall_80B,
    @Syscall_80C, @Syscall_80D, @Syscall_80E, @Syscall_80F, @Syscall_810,
    @Syscall_811, @Syscall_812, @Syscall_813, @Syscall_814, @Syscall_815,
    @Syscall_816, @Syscall_817, @Syscall_818, @Syscall_819, @Syscall_81A,
    @Syscall_81B, @Syscall_81C, @Syscall_81D, @Syscall_81E, @Syscall_81F,
    @Syscall_820, @Syscall_821, @Syscall_822, @Syscall_823, @Syscall_824,
    @Syscall_825, @Syscall_826, @Syscall_827, @Syscall_828, @Syscall_829,
    @Syscall_82A, @Syscall_82B, @Syscall_82C, @Syscall_82D, @Syscall_82E,
    @Syscall_82F, @Syscall_830, @Syscall_831, @Syscall_832, @Syscall_833,
    @Syscall_834, @Syscall_835, @Syscall_836, @Syscall_837, @Syscall_838,
    @Syscall_839, @Syscall_83A, @Syscall_83B, @Syscall_83C, @Syscall_83D,
    @Syscall_83E, @Syscall_83F, @Syscall_840, @Syscall_841, @Syscall_842,
    @Syscall_843, @Syscall_844, @Syscall_845, @Syscall_846, @Syscall_847,
    @Syscall_848, @Syscall_849, @Syscall_84A, @Syscall_84B, @Syscall_84C,
    @Syscall_84D, @Syscall_84E, @Syscall_84F, @Syscall_850, @Syscall_851,
    @Syscall_852, @Syscall_853, @Syscall_854, @Syscall_855, @Syscall_856,
    @Syscall_857, @Syscall_858, @Syscall_859, @Syscall_85A, @Syscall_85B,
    @Syscall_85C, @Syscall_85D, @Syscall_85E, @Syscall_85F, @Syscall_860,
    @Syscall_861, @Syscall_862, @Syscall_863, @Syscall_864, @Syscall_865,
    @Syscall_866, @Syscall_867, @Syscall_868, @Syscall_869, @Syscall_86A,
    @Syscall_86B, @Syscall_86C, @Syscall_86D, @Syscall_86E, @Syscall_86F,
    @Syscall_870, @Syscall_871, @Syscall_872, @Syscall_873, @Syscall_874,
    @Syscall_875, @Syscall_876, @Syscall_877, @Syscall_878, @Syscall_879,
    @Syscall_87A, @Syscall_87B, @Syscall_87C, @Syscall_87D, @Syscall_87E,
    @Syscall_87F, @Syscall_880, @Syscall_881, @Syscall_882, @Syscall_883,
    @Syscall_884, @Syscall_885, @Syscall_886, @Syscall_887, @Syscall_888,
    @Syscall_889, @Syscall_88A, @Syscall_88B, @Syscall_88C, @Syscall_88D,
    @Syscall_88E, @Syscall_88F, @Syscall_890, @Syscall_891, @Syscall_892,
    @Syscall_893, @Syscall_894, @Syscall_895, @Syscall_896, @Syscall_897,
    @Syscall_898, @Syscall_899, @Syscall_89A, @Syscall_89B, @Syscall_89C,
    @Syscall_89D, @Syscall_89E, @Syscall_89F, @Syscall_8A0, @Syscall_8A1,
    @Syscall_8A2, @Syscall_8A3, @Syscall_8A4, @Syscall_8A5, @Syscall_8A6,
    @Syscall_8A7, @Syscall_8A8, @Syscall_8A9, @Syscall_8AA, @Syscall_8AB,
    @Syscall_8AC, @Syscall_8AD, @Syscall_8AE, @Syscall_8AF, @Syscall_8B0,
    @Syscall_8B1, @Syscall_8B2, @Syscall_8B3, @Syscall_8B4, @Syscall_8B5,
    @Syscall_8B6, @Syscall_8B7, @Syscall_8B8, @Syscall_8B9, @Syscall_8BA,
    @Syscall_8BB, @Syscall_8BC, @Syscall_8BD, @Syscall_8BE, @Syscall_8BF,
    @Syscall_8C0, @Syscall_8C1, @Syscall_8C2, @Syscall_8C3, @Syscall_8C4,
    @Syscall_8C5, @Syscall_8C6, @Syscall_8C7, @Syscall_8C8, @Syscall_8C9,
    @Syscall_8CA, @Syscall_8CB, @Syscall_8CC, @Syscall_8CD, @Syscall_8CE,
    @Syscall_8CF, @Syscall_8D0, @Syscall_8D1, @Syscall_8D2, @Syscall_8D3,
    @Syscall_8D4, @Syscall_8D5, @Syscall_8D6, @Syscall_8D7, @Syscall_8D8,
    @Syscall_8D9, @Syscall_8DA, @Syscall_8DB, @Syscall_8DC, @Syscall_8DD,
    @Syscall_8DE, @Syscall_8DF, @Syscall_8E0, @Syscall_8E1, @Syscall_8E2,
    @Syscall_8E3, @Syscall_8E4, @Syscall_8E5, @Syscall_8E6, @Syscall_8E7,
    @Syscall_8E8, @Syscall_8E9, @Syscall_8EA, @Syscall_8EB, @Syscall_8EC,
    @Syscall_8ED, @Syscall_8EE, @Syscall_8EF, @Syscall_8F0, @Syscall_8F1,
    @Syscall_8F2, @Syscall_8F3, @Syscall_8F4, @Syscall_8F5, @Syscall_8F6,
    @Syscall_8F7, @Syscall_8F8, @Syscall_8F9, @Syscall_8FA, @Syscall_8FB,
    @Syscall_8FC, @Syscall_8FD, @Syscall_8FE, @Syscall_8FF, @Syscall_900,
    @Syscall_901, @Syscall_902, @Syscall_903, @Syscall_904, @Syscall_905,
    @Syscall_906, @Syscall_907, @Syscall_908, @Syscall_909, @Syscall_90A,
    @Syscall_90B, @Syscall_90C, @Syscall_90D, @Syscall_90E, @Syscall_90F,
    @Syscall_910, @Syscall_911, @Syscall_912, @Syscall_913, @Syscall_914,
    @Syscall_915, @Syscall_916, @Syscall_917, @Syscall_918, @Syscall_919,
    @Syscall_91A, @Syscall_91B, @Syscall_91C, @Syscall_91D, @Syscall_91E,
    @Syscall_91F, @Syscall_920, @Syscall_921, @Syscall_922, @Syscall_923,
    @Syscall_924, @Syscall_925, @Syscall_926, @Syscall_927, @Syscall_928,
    @Syscall_929, @Syscall_92A, @Syscall_92B, @Syscall_92C, @Syscall_92D,
    @Syscall_92E, @Syscall_92F, @Syscall_930, @Syscall_931, @Syscall_932,
    @Syscall_933, @Syscall_934, @Syscall_935, @Syscall_936, @Syscall_937,
    @Syscall_938, @Syscall_939, @Syscall_93A, @Syscall_93B, @Syscall_93C,
    @Syscall_93D, @Syscall_93E, @Syscall_93F, @Syscall_940, @Syscall_941,
    @Syscall_942, @Syscall_943, @Syscall_944, @Syscall_945, @Syscall_946,
    @Syscall_947, @Syscall_948, @Syscall_949, @Syscall_94A, @Syscall_94B,
    @Syscall_94C, @Syscall_94D, @Syscall_94E, @Syscall_94F, @Syscall_950,
    @Syscall_951, @Syscall_952, @Syscall_953, @Syscall_954, @Syscall_955,
    @Syscall_956, @Syscall_957, @Syscall_958, @Syscall_959, @Syscall_95A,
    @Syscall_95B, @Syscall_95C, @Syscall_95D, @Syscall_95E, @Syscall_95F,
    @Syscall_960, @Syscall_961, @Syscall_962, @Syscall_963, @Syscall_964,
    @Syscall_965, @Syscall_966, @Syscall_967, @Syscall_968, @Syscall_969,
    @Syscall_96A, @Syscall_96B, @Syscall_96C, @Syscall_96D, @Syscall_96E,
    @Syscall_96F, @Syscall_970, @Syscall_971, @Syscall_972, @Syscall_973,
    @Syscall_974, @Syscall_975, @Syscall_976, @Syscall_977, @Syscall_978,
    @Syscall_979, @Syscall_97A, @Syscall_97B, @Syscall_97C, @Syscall_97D,
    @Syscall_97E, @Syscall_97F, @Syscall_980, @Syscall_981, @Syscall_982,
    @Syscall_983, @Syscall_984, @Syscall_985, @Syscall_986, @Syscall_987,
    @Syscall_988, @Syscall_989, @Syscall_98A, @Syscall_98B, @Syscall_98C,
    @Syscall_98D, @Syscall_98E, @Syscall_98F, @Syscall_990, @Syscall_991,
    @Syscall_992, @Syscall_993, @Syscall_994, @Syscall_995, @Syscall_996,
    @Syscall_997, @Syscall_998, @Syscall_999, @Syscall_99A, @Syscall_99B,
    @Syscall_99C, @Syscall_99D, @Syscall_99E, @Syscall_99F, @Syscall_9A0,
    @Syscall_9A1, @Syscall_9A2, @Syscall_9A3, @Syscall_9A4, @Syscall_9A5,
    @Syscall_9A6, @Syscall_9A7, @Syscall_9A8, @Syscall_9A9, @Syscall_9AA,
    @Syscall_9AB, @Syscall_9AC, @Syscall_9AD, @Syscall_9AE, @Syscall_9AF,
    @Syscall_9B0, @Syscall_9B1, @Syscall_9B2, @Syscall_9B3, @Syscall_9B4,
    @Syscall_9B5, @Syscall_9B6, @Syscall_9B7, @Syscall_9B8, @Syscall_9B9,
    @Syscall_9BA, @Syscall_9BB, @Syscall_9BC, @Syscall_9BD, @Syscall_9BE,
    @Syscall_9BF, @Syscall_9C0, @Syscall_9C1, @Syscall_9C2, @Syscall_9C3,
    @Syscall_9C4, @Syscall_9C5, @Syscall_9C6, @Syscall_9C7, @Syscall_9C8,
    @Syscall_9C9, @Syscall_9CA, @Syscall_9CB, @Syscall_9CC, @Syscall_9CD,
    @Syscall_9CE, @Syscall_9CF, @Syscall_9D0, @Syscall_9D1, @Syscall_9D2,
    @Syscall_9D3, @Syscall_9D4, @Syscall_9D5, @Syscall_9D6, @Syscall_9D7,
    @Syscall_9D8, @Syscall_9D9, @Syscall_9DA, @Syscall_9DB, @Syscall_9DC,
    @Syscall_9DD, @Syscall_9DE, @Syscall_9DF, @Syscall_9E0, @Syscall_9E1,
    @Syscall_9E2, @Syscall_9E3, @Syscall_9E4, @Syscall_9E5, @Syscall_9E6,
    @Syscall_9E7, @Syscall_9E8, @Syscall_9E9, @Syscall_9EA, @Syscall_9EB,
    @Syscall_9EC, @Syscall_9ED, @Syscall_9EE, @Syscall_9EF, @Syscall_9F0,
    @Syscall_9F1, @Syscall_9F2, @Syscall_9F3, @Syscall_9F4, @Syscall_9F5,
    @Syscall_9F6, @Syscall_9F7, @Syscall_9F8, @Syscall_9F9, @Syscall_9FA,
    @Syscall_9FB, @Syscall_9FC, @Syscall_9FD, @Syscall_9FE, @Syscall_9FF,
    @Syscall_A00, @Syscall_A01, @Syscall_A02, @Syscall_A03, @Syscall_A04,
    @Syscall_A05, @Syscall_A06, @Syscall_A07, @Syscall_A08, @Syscall_A09,
    @Syscall_A0A, @Syscall_A0B, @Syscall_A0C, @Syscall_A0D, @Syscall_A0E,
    @Syscall_A0F, @Syscall_A10, @Syscall_A11, @Syscall_A12, @Syscall_A13,
    @Syscall_A14, @Syscall_A15, @Syscall_A16, @Syscall_A17, @Syscall_A18,
    @Syscall_A19, @Syscall_A1A, @Syscall_A1B, @Syscall_A1C, @Syscall_A1D,
    @Syscall_A1E, @Syscall_A1F, @Syscall_A20, @Syscall_A21, @Syscall_A22,
    @Syscall_A23, @Syscall_A24, @Syscall_A25, @Syscall_A26, @Syscall_A27,
    @Syscall_A28, @Syscall_A29, @Syscall_A2A, @Syscall_A2B, @Syscall_A2C,
    @Syscall_A2D, @Syscall_A2E, @Syscall_A2F, @Syscall_A30, @Syscall_A31,
    @Syscall_A32, @Syscall_A33, @Syscall_A34, @Syscall_A35, @Syscall_A36,
    @Syscall_A37, @Syscall_A38, @Syscall_A39, @Syscall_A3A, @Syscall_A3B,
    @Syscall_A3C, @Syscall_A3D, @Syscall_A3E, @Syscall_A3F, @Syscall_A40,
    @Syscall_A41, @Syscall_A42, @Syscall_A43, @Syscall_A44, @Syscall_A45,
    @Syscall_A46, @Syscall_A47, @Syscall_A48, @Syscall_A49, @Syscall_A4A,
    @Syscall_A4B, @Syscall_A4C, @Syscall_A4D, @Syscall_A4E, @Syscall_A4F,
    @Syscall_A50, @Syscall_A51, @Syscall_A52, @Syscall_A53, @Syscall_A54,
    @Syscall_A55, @Syscall_A56, @Syscall_A57, @Syscall_A58, @Syscall_A59,
    @Syscall_A5A, @Syscall_A5B, @Syscall_A5C, @Syscall_A5D, @Syscall_A5E,
    @Syscall_A5F, @Syscall_A60, @Syscall_A61, @Syscall_A62, @Syscall_A63,
    @Syscall_A64, @Syscall_A65, @Syscall_A66, @Syscall_A67, @Syscall_A68,
    @Syscall_A69, @Syscall_A6A, @Syscall_A6B, @Syscall_A6C, @Syscall_A6D,
    @Syscall_A6E, @Syscall_A6F, @Syscall_A70, @Syscall_A71, @Syscall_A72,
    @Syscall_A73, @Syscall_A74, @Syscall_A75, @Syscall_A76, @Syscall_A77,
    @Syscall_A78, @Syscall_A79, @Syscall_A7A, @Syscall_A7B, @Syscall_A7C,
    @Syscall_A7D, @Syscall_A7E, @Syscall_A7F, @Syscall_A80, @Syscall_A81,
    @Syscall_A82, @Syscall_A83, @Syscall_A84, @Syscall_A85, @Syscall_A86,
    @Syscall_A87, @Syscall_A88, @Syscall_A89, @Syscall_A8A, @Syscall_A8B,
    @Syscall_A8C, @Syscall_A8D, @Syscall_A8E, @Syscall_A8F, @Syscall_A90,
    @Syscall_A91, @Syscall_A92, @Syscall_A93, @Syscall_A94, @Syscall_A95,
    @Syscall_A96, @Syscall_A97, @Syscall_A98, @Syscall_A99, @Syscall_A9A,
    @Syscall_A9B, @Syscall_A9C, @Syscall_A9D, @Syscall_A9E, @Syscall_A9F,
    @Syscall_AA0, @Syscall_AA1, @Syscall_AA2, @Syscall_AA3, @Syscall_AA4,
    @Syscall_AA5, @Syscall_AA6, @Syscall_AA7, @Syscall_AA8, @Syscall_AA9,
    @Syscall_AAA, @Syscall_AAB, @Syscall_AAC, @Syscall_AAD, @Syscall_AAE,
    @Syscall_AAF, @Syscall_AB0, @Syscall_AB1, @Syscall_AB2, @Syscall_AB3,
    @Syscall_AB4, @Syscall_AB5, @Syscall_AB6, @Syscall_AB7, @Syscall_AB8,
    @Syscall_AB9, @Syscall_ABA, @Syscall_ABB, @Syscall_ABC, @Syscall_ABD,
    @Syscall_ABE, @Syscall_ABF, @Syscall_AC0, @Syscall_AC1, @Syscall_AC2,
    @Syscall_AC3, @Syscall_AC4, @Syscall_AC5, @Syscall_AC6, @Syscall_AC7,
    @Syscall_AC8, @Syscall_AC9, @Syscall_ACA, @Syscall_ACB, @Syscall_ACC,
    @Syscall_ACD, @Syscall_ACE, @Syscall_ACF, @Syscall_AD0, @Syscall_AD1,
    @Syscall_AD2, @Syscall_AD3, @Syscall_AD4, @Syscall_AD5, @Syscall_AD6,
    @Syscall_AD7, @Syscall_AD8, @Syscall_AD9, @Syscall_ADA, @Syscall_ADB,
    @Syscall_ADC, @Syscall_ADD, @Syscall_ADE, @Syscall_ADF, @Syscall_AE0,
    @Syscall_AE1, @Syscall_AE2, @Syscall_AE3, @Syscall_AE4, @Syscall_AE5,
    @Syscall_AE6, @Syscall_AE7, @Syscall_AE8, @Syscall_AE9, @Syscall_AEA,
    @Syscall_AEB, @Syscall_AEC, @Syscall_AED, @Syscall_AEE, @Syscall_AEF,
    @Syscall_AF0, @Syscall_AF1, @Syscall_AF2, @Syscall_AF3, @Syscall_AF4,
    @Syscall_AF5, @Syscall_AF6, @Syscall_AF7, @Syscall_AF8, @Syscall_AF9,
    @Syscall_AFA, @Syscall_AFB, @Syscall_AFC, @Syscall_AFD, @Syscall_AFE,
    @Syscall_AFF, @Syscall_B00, @Syscall_B01, @Syscall_B02, @Syscall_B03,
    @Syscall_B04, @Syscall_B05, @Syscall_B06, @Syscall_B07, @Syscall_B08,
    @Syscall_B09, @Syscall_B0A, @Syscall_B0B, @Syscall_B0C, @Syscall_B0D,
    @Syscall_B0E, @Syscall_B0F, @Syscall_B10, @Syscall_B11, @Syscall_B12,
    @Syscall_B13, @Syscall_B14, @Syscall_B15, @Syscall_B16, @Syscall_B17,
    @Syscall_B18, @Syscall_B19, @Syscall_B1A, @Syscall_B1B, @Syscall_B1C,
    @Syscall_B1D, @Syscall_B1E, @Syscall_B1F, @Syscall_B20, @Syscall_B21,
    @Syscall_B22, @Syscall_B23, @Syscall_B24, @Syscall_B25, @Syscall_B26,
    @Syscall_B27, @Syscall_B28, @Syscall_B29, @Syscall_B2A, @Syscall_B2B,
    @Syscall_B2C, @Syscall_B2D, @Syscall_B2E, @Syscall_B2F, @Syscall_B30,
    @Syscall_B31, @Syscall_B32, @Syscall_B33, @Syscall_B34, @Syscall_B35,
    @Syscall_B36, @Syscall_B37, @Syscall_B38, @Syscall_B39, @Syscall_B3A,
    @Syscall_B3B, @Syscall_B3C, @Syscall_B3D, @Syscall_B3E, @Syscall_B3F,
    @Syscall_B40, @Syscall_B41, @Syscall_B42, @Syscall_B43, @Syscall_B44,
    @Syscall_B45, @Syscall_B46, @Syscall_B47, @Syscall_B48, @Syscall_B49,
    @Syscall_B4A, @Syscall_B4B, @Syscall_B4C, @Syscall_B4D, @Syscall_B4E,
    @Syscall_B4F, @Syscall_B50, @Syscall_B51, @Syscall_B52, @Syscall_B53,
    @Syscall_B54, @Syscall_B55, @Syscall_B56, @Syscall_B57, @Syscall_B58,
    @Syscall_B59, @Syscall_B5A, @Syscall_B5B, @Syscall_B5C, @Syscall_B5D,
    @Syscall_B5E, @Syscall_B5F, @Syscall_B60, @Syscall_B61, @Syscall_B62,
    @Syscall_B63, @Syscall_B64, @Syscall_B65, @Syscall_B66, @Syscall_B67,
    @Syscall_B68, @Syscall_B69, @Syscall_B6A, @Syscall_B6B, @Syscall_B6C,
    @Syscall_B6D, @Syscall_B6E, @Syscall_B6F, @Syscall_B70, @Syscall_B71,
    @Syscall_B72, @Syscall_B73, @Syscall_B74, @Syscall_B75, @Syscall_B76,
    @Syscall_B77, @Syscall_B78, @Syscall_B79, @Syscall_B7A, @Syscall_B7B,
    @Syscall_B7C, @Syscall_B7D, @Syscall_B7E, @Syscall_B7F, @Syscall_B80,
    @Syscall_B81, @Syscall_B82, @Syscall_B83, @Syscall_B84, @Syscall_B85,
    @Syscall_B86, @Syscall_B87, @Syscall_B88, @Syscall_B89, @Syscall_B8A,
    @Syscall_B8B, @Syscall_B8C, @Syscall_B8D, @Syscall_B8E, @Syscall_B8F,
    @Syscall_B90, @Syscall_B91, @Syscall_B92, @Syscall_B93, @Syscall_B94,
    @Syscall_B95, @Syscall_B96, @Syscall_B97, @Syscall_B98, @Syscall_B99,
    @Syscall_B9A, @Syscall_B9B, @Syscall_B9C, @Syscall_B9D, @Syscall_B9E,
    @Syscall_B9F, @Syscall_BA0, @Syscall_BA1, @Syscall_BA2, @Syscall_BA3,
    @Syscall_BA4, @Syscall_BA5, @Syscall_BA6, @Syscall_BA7, @Syscall_BA8,
    @Syscall_BA9, @Syscall_BAA, @Syscall_BAB, @Syscall_BAC, @Syscall_BAD,
    @Syscall_BAE, @Syscall_BAF, @Syscall_BB0, @Syscall_BB1, @Syscall_BB2,
    @Syscall_BB3, @Syscall_BB4, @Syscall_BB5, @Syscall_BB6, @Syscall_BB7,
    @Syscall_BB8, @Syscall_BB9, @Syscall_BBA, @Syscall_BBB, @Syscall_BBC,
    @Syscall_BBD, @Syscall_BBE, @Syscall_BBF, @Syscall_BC0, @Syscall_BC1,
    @Syscall_BC2, @Syscall_BC3, @Syscall_BC4, @Syscall_BC5, @Syscall_BC6,
    @Syscall_BC7, @Syscall_BC8, @Syscall_BC9, @Syscall_BCA, @Syscall_BCB,
    @Syscall_BCC, @Syscall_BCD, @Syscall_BCE, @Syscall_BCF, @Syscall_BD0,
    @Syscall_BD1, @Syscall_BD2, @Syscall_BD3, @Syscall_BD4, @Syscall_BD5,
    @Syscall_BD6, @Syscall_BD7, @Syscall_BD8, @Syscall_BD9, @Syscall_BDA,
    @Syscall_BDB, @Syscall_BDC, @Syscall_BDD, @Syscall_BDE, @Syscall_BDF,
    @Syscall_BE0, @Syscall_BE1, @Syscall_BE2, @Syscall_BE3, @Syscall_BE4,
    @Syscall_BE5, @Syscall_BE6, @Syscall_BE7, @Syscall_BE8, @Syscall_BE9,
    @Syscall_BEA, @Syscall_BEB, @Syscall_BEC, @Syscall_BED, @Syscall_BEE,
    @Syscall_BEF, @Syscall_BF0, @Syscall_BF1, @Syscall_BF2, @Syscall_BF3,
    @Syscall_BF4, @Syscall_BF5, @Syscall_BF6, @Syscall_BF7, @Syscall_BF8,
    @Syscall_BF9, @Syscall_BFA, @Syscall_BFB, @Syscall_BFC, @Syscall_BFD,
    @Syscall_BFE, @Syscall_BFF, @Syscall_C00, @Syscall_C01, @Syscall_C02,
    @Syscall_C03, @Syscall_C04, @Syscall_C05, @Syscall_C06, @Syscall_C07,
    @Syscall_C08, @Syscall_C09, @Syscall_C0A, @Syscall_C0B, @Syscall_C0C,
    @Syscall_C0D, @Syscall_C0E, @Syscall_C0F, @Syscall_C10, @Syscall_C11,
    @Syscall_C12, @Syscall_C13, @Syscall_C14, @Syscall_C15, @Syscall_C16,
    @Syscall_C17, @Syscall_C18, @Syscall_C19, @Syscall_C1A, @Syscall_C1B,
    @Syscall_C1C, @Syscall_C1D, @Syscall_C1E, @Syscall_C1F, @Syscall_C20,
    @Syscall_C21, @Syscall_C22, @Syscall_C23, @Syscall_C24, @Syscall_C25,
    @Syscall_C26, @Syscall_C27, @Syscall_C28, @Syscall_C29, @Syscall_C2A,
    @Syscall_C2B, @Syscall_C2C, @Syscall_C2D, @Syscall_C2E, @Syscall_C2F,
    @Syscall_C30, @Syscall_C31, @Syscall_C32, @Syscall_C33, @Syscall_C34,
    @Syscall_C35, @Syscall_C36, @Syscall_C37, @Syscall_C38, @Syscall_C39,
    @Syscall_C3A, @Syscall_C3B, @Syscall_C3C, @Syscall_C3D, @Syscall_C3E,
    @Syscall_C3F, @Syscall_C40, @Syscall_C41, @Syscall_C42, @Syscall_C43,
    @Syscall_C44, @Syscall_C45, @Syscall_C46, @Syscall_C47, @Syscall_C48,
    @Syscall_C49, @Syscall_C4A, @Syscall_C4B, @Syscall_C4C, @Syscall_C4D,
    @Syscall_C4E, @Syscall_C4F, @Syscall_C50, @Syscall_C51, @Syscall_C52,
    @Syscall_C53, @Syscall_C54, @Syscall_C55, @Syscall_C56, @Syscall_C57,
    @Syscall_C58, @Syscall_C59, @Syscall_C5A, @Syscall_C5B, @Syscall_C5C,
    @Syscall_C5D, @Syscall_C5E, @Syscall_C5F, @Syscall_C60, @Syscall_C61,
    @Syscall_C62, @Syscall_C63, @Syscall_C64, @Syscall_C65, @Syscall_C66,
    @Syscall_C67, @Syscall_C68, @Syscall_C69, @Syscall_C6A, @Syscall_C6B,
    @Syscall_C6C, @Syscall_C6D, @Syscall_C6E, @Syscall_C6F, @Syscall_C70,
    @Syscall_C71, @Syscall_C72, @Syscall_C73, @Syscall_C74, @Syscall_C75,
    @Syscall_C76, @Syscall_C77, @Syscall_C78, @Syscall_C79, @Syscall_C7A,
    @Syscall_C7B, @Syscall_C7C, @Syscall_C7D, @Syscall_C7E, @Syscall_C7F,
    @Syscall_C80, @Syscall_C81, @Syscall_C82, @Syscall_C83, @Syscall_C84,
    @Syscall_C85, @Syscall_C86, @Syscall_C87, @Syscall_C88, @Syscall_C89,
    @Syscall_C8A, @Syscall_C8B, @Syscall_C8C, @Syscall_C8D, @Syscall_C8E,
    @Syscall_C8F, @Syscall_C90, @Syscall_C91, @Syscall_C92, @Syscall_C93,
    @Syscall_C94, @Syscall_C95, @Syscall_C96, @Syscall_C97, @Syscall_C98,
    @Syscall_C99, @Syscall_C9A, @Syscall_C9B, @Syscall_C9C, @Syscall_C9D,
    @Syscall_C9E, @Syscall_C9F, @Syscall_CA0, @Syscall_CA1, @Syscall_CA2,
    @Syscall_CA3, @Syscall_CA4, @Syscall_CA5, @Syscall_CA6, @Syscall_CA7,
    @Syscall_CA8, @Syscall_CA9, @Syscall_CAA, @Syscall_CAB, @Syscall_CAC,
    @Syscall_CAD, @Syscall_CAE, @Syscall_CAF, @Syscall_CB0, @Syscall_CB1,
    @Syscall_CB2, @Syscall_CB3, @Syscall_CB4, @Syscall_CB5, @Syscall_CB6,
    @Syscall_CB7, @Syscall_CB8, @Syscall_CB9, @Syscall_CBA, @Syscall_CBB,
    @Syscall_CBC, @Syscall_CBD, @Syscall_CBE, @Syscall_CBF, @Syscall_CC0,
    @Syscall_CC1, @Syscall_CC2, @Syscall_CC3, @Syscall_CC4, @Syscall_CC5,
    @Syscall_CC6, @Syscall_CC7, @Syscall_CC8, @Syscall_CC9, @Syscall_CCA,
    @Syscall_CCB, @Syscall_CCC, @Syscall_CCD, @Syscall_CCE, @Syscall_CCF,
    @Syscall_CD0, @Syscall_CD1, @Syscall_CD2, @Syscall_CD3, @Syscall_CD4,
    @Syscall_CD5, @Syscall_CD6, @Syscall_CD7, @Syscall_CD8, @Syscall_CD9,
    @Syscall_CDA, @Syscall_CDB, @Syscall_CDC, @Syscall_CDD, @Syscall_CDE,
    @Syscall_CDF, @Syscall_CE0, @Syscall_CE1, @Syscall_CE2, @Syscall_CE3,
    @Syscall_CE4, @Syscall_CE5, @Syscall_CE6, @Syscall_CE7, @Syscall_CE8,
    @Syscall_CE9, @Syscall_CEA, @Syscall_CEB, @Syscall_CEC, @Syscall_CED,
    @Syscall_CEE, @Syscall_CEF, @Syscall_CF0, @Syscall_CF1, @Syscall_CF2,
    @Syscall_CF3, @Syscall_CF4, @Syscall_CF5, @Syscall_CF6, @Syscall_CF7,
    @Syscall_CF8, @Syscall_CF9, @Syscall_CFA, @Syscall_CFB, @Syscall_CFC,
    @Syscall_CFD, @Syscall_CFE, @Syscall_CFF, @Syscall_D00, @Syscall_D01,
    @Syscall_D02, @Syscall_D03, @Syscall_D04, @Syscall_D05, @Syscall_D06,
    @Syscall_D07, @Syscall_D08, @Syscall_D09, @Syscall_D0A, @Syscall_D0B,
    @Syscall_D0C, @Syscall_D0D, @Syscall_D0E, @Syscall_D0F, @Syscall_D10,
    @Syscall_D11, @Syscall_D12, @Syscall_D13, @Syscall_D14, @Syscall_D15,
    @Syscall_D16, @Syscall_D17, @Syscall_D18, @Syscall_D19, @Syscall_D1A,
    @Syscall_D1B, @Syscall_D1C, @Syscall_D1D, @Syscall_D1E, @Syscall_D1F,
    @Syscall_D20, @Syscall_D21, @Syscall_D22, @Syscall_D23, @Syscall_D24,
    @Syscall_D25, @Syscall_D26, @Syscall_D27, @Syscall_D28, @Syscall_D29,
    @Syscall_D2A, @Syscall_D2B, @Syscall_D2C, @Syscall_D2D, @Syscall_D2E,
    @Syscall_D2F, @Syscall_D30, @Syscall_D31, @Syscall_D32, @Syscall_D33,
    @Syscall_D34, @Syscall_D35, @Syscall_D36, @Syscall_D37, @Syscall_D38,
    @Syscall_D39, @Syscall_D3A, @Syscall_D3B, @Syscall_D3C, @Syscall_D3D,
    @Syscall_D3E, @Syscall_D3F, @Syscall_D40, @Syscall_D41, @Syscall_D42,
    @Syscall_D43, @Syscall_D44, @Syscall_D45, @Syscall_D46, @Syscall_D47,
    @Syscall_D48, @Syscall_D49, @Syscall_D4A, @Syscall_D4B, @Syscall_D4C,
    @Syscall_D4D, @Syscall_D4E, @Syscall_D4F, @Syscall_D50, @Syscall_D51,
    @Syscall_D52, @Syscall_D53, @Syscall_D54, @Syscall_D55, @Syscall_D56,
    @Syscall_D57, @Syscall_D58, @Syscall_D59, @Syscall_D5A, @Syscall_D5B,
    @Syscall_D5C, @Syscall_D5D, @Syscall_D5E, @Syscall_D5F, @Syscall_D60,
    @Syscall_D61, @Syscall_D62, @Syscall_D63, @Syscall_D64, @Syscall_D65,
    @Syscall_D66, @Syscall_D67, @Syscall_D68, @Syscall_D69, @Syscall_D6A,
    @Syscall_D6B, @Syscall_D6C, @Syscall_D6D, @Syscall_D6E, @Syscall_D6F,
    @Syscall_D70, @Syscall_D71, @Syscall_D72, @Syscall_D73, @Syscall_D74,
    @Syscall_D75, @Syscall_D76, @Syscall_D77, @Syscall_D78, @Syscall_D79,
    @Syscall_D7A, @Syscall_D7B, @Syscall_D7C, @Syscall_D7D, @Syscall_D7E,
    @Syscall_D7F, @Syscall_D80, @Syscall_D81, @Syscall_D82, @Syscall_D83,
    @Syscall_D84, @Syscall_D85, @Syscall_D86, @Syscall_D87, @Syscall_D88,
    @Syscall_D89, @Syscall_D8A, @Syscall_D8B, @Syscall_D8C, @Syscall_D8D,
    @Syscall_D8E, @Syscall_D8F, @Syscall_D90, @Syscall_D91, @Syscall_D92,
    @Syscall_D93, @Syscall_D94, @Syscall_D95, @Syscall_D96, @Syscall_D97,
    @Syscall_D98, @Syscall_D99, @Syscall_D9A, @Syscall_D9B, @Syscall_D9C,
    @Syscall_D9D, @Syscall_D9E, @Syscall_D9F, @Syscall_DA0, @Syscall_DA1,
    @Syscall_DA2, @Syscall_DA3, @Syscall_DA4, @Syscall_DA5, @Syscall_DA6,
    @Syscall_DA7, @Syscall_DA8, @Syscall_DA9, @Syscall_DAA, @Syscall_DAB,
    @Syscall_DAC, @Syscall_DAD, @Syscall_DAE, @Syscall_DAF, @Syscall_DB0,
    @Syscall_DB1, @Syscall_DB2, @Syscall_DB3, @Syscall_DB4, @Syscall_DB5,
    @Syscall_DB6, @Syscall_DB7, @Syscall_DB8, @Syscall_DB9, @Syscall_DBA,
    @Syscall_DBB, @Syscall_DBC, @Syscall_DBD, @Syscall_DBE, @Syscall_DBF,
    @Syscall_DC0, @Syscall_DC1, @Syscall_DC2, @Syscall_DC3, @Syscall_DC4,
    @Syscall_DC5, @Syscall_DC6, @Syscall_DC7, @Syscall_DC8, @Syscall_DC9,
    @Syscall_DCA, @Syscall_DCB, @Syscall_DCC, @Syscall_DCD, @Syscall_DCE,
    @Syscall_DCF, @Syscall_DD0, @Syscall_DD1, @Syscall_DD2, @Syscall_DD3,
    @Syscall_DD4, @Syscall_DD5, @Syscall_DD6, @Syscall_DD7, @Syscall_DD8,
    @Syscall_DD9, @Syscall_DDA, @Syscall_DDB, @Syscall_DDC, @Syscall_DDD,
    @Syscall_DDE, @Syscall_DDF, @Syscall_DE0, @Syscall_DE1, @Syscall_DE2,
    @Syscall_DE3, @Syscall_DE4, @Syscall_DE5, @Syscall_DE6, @Syscall_DE7,
    @Syscall_DE8, @Syscall_DE9, @Syscall_DEA, @Syscall_DEB, @Syscall_DEC,
    @Syscall_DED, @Syscall_DEE, @Syscall_DEF, @Syscall_DF0, @Syscall_DF1,
    @Syscall_DF2, @Syscall_DF3, @Syscall_DF4, @Syscall_DF5, @Syscall_DF6,
    @Syscall_DF7, @Syscall_DF8, @Syscall_DF9, @Syscall_DFA, @Syscall_DFB,
    @Syscall_DFC, @Syscall_DFD, @Syscall_DFE, @Syscall_DFF, @Syscall_E00,
    @Syscall_E01, @Syscall_E02, @Syscall_E03, @Syscall_E04, @Syscall_E05,
    @Syscall_E06, @Syscall_E07, @Syscall_E08, @Syscall_E09, @Syscall_E0A,
    @Syscall_E0B, @Syscall_E0C, @Syscall_E0D, @Syscall_E0E, @Syscall_E0F,
    @Syscall_E10, @Syscall_E11, @Syscall_E12, @Syscall_E13, @Syscall_E14,
    @Syscall_E15, @Syscall_E16, @Syscall_E17, @Syscall_E18, @Syscall_E19,
    @Syscall_E1A, @Syscall_E1B, @Syscall_E1C, @Syscall_E1D, @Syscall_E1E,
    @Syscall_E1F, @Syscall_E20, @Syscall_E21, @Syscall_E22, @Syscall_E23,
    @Syscall_E24, @Syscall_E25, @Syscall_E26, @Syscall_E27, @Syscall_E28,
    @Syscall_E29, @Syscall_E2A, @Syscall_E2B, @Syscall_E2C, @Syscall_E2D,
    @Syscall_E2E, @Syscall_E2F, @Syscall_E30, @Syscall_E31, @Syscall_E32,
    @Syscall_E33, @Syscall_E34, @Syscall_E35, @Syscall_E36, @Syscall_E37,
    @Syscall_E38, @Syscall_E39, @Syscall_E3A, @Syscall_E3B, @Syscall_E3C,
    @Syscall_E3D, @Syscall_E3E, @Syscall_E3F, @Syscall_E40, @Syscall_E41,
    @Syscall_E42, @Syscall_E43, @Syscall_E44, @Syscall_E45, @Syscall_E46,
    @Syscall_E47, @Syscall_E48, @Syscall_E49, @Syscall_E4A, @Syscall_E4B,
    @Syscall_E4C, @Syscall_E4D, @Syscall_E4E, @Syscall_E4F, @Syscall_E50,
    @Syscall_E51, @Syscall_E52, @Syscall_E53, @Syscall_E54, @Syscall_E55,
    @Syscall_E56, @Syscall_E57, @Syscall_E58, @Syscall_E59, @Syscall_E5A,
    @Syscall_E5B, @Syscall_E5C, @Syscall_E5D, @Syscall_E5E, @Syscall_E5F,
    @Syscall_E60, @Syscall_E61, @Syscall_E62, @Syscall_E63, @Syscall_E64,
    @Syscall_E65, @Syscall_E66, @Syscall_E67, @Syscall_E68, @Syscall_E69,
    @Syscall_E6A, @Syscall_E6B, @Syscall_E6C, @Syscall_E6D, @Syscall_E6E,
    @Syscall_E6F, @Syscall_E70, @Syscall_E71, @Syscall_E72, @Syscall_E73,
    @Syscall_E74, @Syscall_E75, @Syscall_E76, @Syscall_E77, @Syscall_E78,
    @Syscall_E79, @Syscall_E7A, @Syscall_E7B, @Syscall_E7C, @Syscall_E7D,
    @Syscall_E7E, @Syscall_E7F, @Syscall_E80, @Syscall_E81, @Syscall_E82,
    @Syscall_E83, @Syscall_E84, @Syscall_E85, @Syscall_E86, @Syscall_E87,
    @Syscall_E88, @Syscall_E89, @Syscall_E8A, @Syscall_E8B, @Syscall_E8C,
    @Syscall_E8D, @Syscall_E8E, @Syscall_E8F, @Syscall_E90, @Syscall_E91,
    @Syscall_E92, @Syscall_E93, @Syscall_E94, @Syscall_E95, @Syscall_E96,
    @Syscall_E97, @Syscall_E98, @Syscall_E99, @Syscall_E9A, @Syscall_E9B,
    @Syscall_E9C, @Syscall_E9D, @Syscall_E9E, @Syscall_E9F, @Syscall_EA0,
    @Syscall_EA1, @Syscall_EA2, @Syscall_EA3, @Syscall_EA4, @Syscall_EA5,
    @Syscall_EA6, @Syscall_EA7, @Syscall_EA8, @Syscall_EA9, @Syscall_EAA,
    @Syscall_EAB, @Syscall_EAC, @Syscall_EAD, @Syscall_EAE, @Syscall_EAF,
    @Syscall_EB0, @Syscall_EB1, @Syscall_EB2, @Syscall_EB3, @Syscall_EB4,
    @Syscall_EB5, @Syscall_EB6, @Syscall_EB7, @Syscall_EB8, @Syscall_EB9,
    @Syscall_EBA, @Syscall_EBB, @Syscall_EBC, @Syscall_EBD, @Syscall_EBE,
    @Syscall_EBF, @Syscall_EC0, @Syscall_EC1, @Syscall_EC2, @Syscall_EC3,
    @Syscall_EC4, @Syscall_EC5, @Syscall_EC6, @Syscall_EC7, @Syscall_EC8,
    @Syscall_EC9, @Syscall_ECA, @Syscall_ECB, @Syscall_ECC, @Syscall_ECD,
    @Syscall_ECE, @Syscall_ECF, @Syscall_ED0, @Syscall_ED1, @Syscall_ED2,
    @Syscall_ED3, @Syscall_ED4, @Syscall_ED5, @Syscall_ED6, @Syscall_ED7,
    @Syscall_ED8, @Syscall_ED9, @Syscall_EDA, @Syscall_EDB, @Syscall_EDC,
    @Syscall_EDD, @Syscall_EDE, @Syscall_EDF, @Syscall_EE0, @Syscall_EE1,
    @Syscall_EE2, @Syscall_EE3, @Syscall_EE4, @Syscall_EE5, @Syscall_EE6,
    @Syscall_EE7, @Syscall_EE8, @Syscall_EE9, @Syscall_EEA, @Syscall_EEB,
    @Syscall_EEC, @Syscall_EED, @Syscall_EEE, @Syscall_EEF, @Syscall_EF0,
    @Syscall_EF1, @Syscall_EF2, @Syscall_EF3, @Syscall_EF4, @Syscall_EF5,
    @Syscall_EF6, @Syscall_EF7, @Syscall_EF8, @Syscall_EF9, @Syscall_EFA,
    @Syscall_EFB, @Syscall_EFC, @Syscall_EFD, @Syscall_EFE, @Syscall_EFF,
    @Syscall_F00, @Syscall_F01, @Syscall_F02, @Syscall_F03, @Syscall_F04,
    @Syscall_F05, @Syscall_F06, @Syscall_F07, @Syscall_F08, @Syscall_F09,
    @Syscall_F0A, @Syscall_F0B, @Syscall_F0C, @Syscall_F0D, @Syscall_F0E,
    @Syscall_F0F, @Syscall_F10, @Syscall_F11, @Syscall_F12, @Syscall_F13,
    @Syscall_F14, @Syscall_F15, @Syscall_F16, @Syscall_F17, @Syscall_F18,
    @Syscall_F19, @Syscall_F1A, @Syscall_F1B, @Syscall_F1C, @Syscall_F1D,
    @Syscall_F1E, @Syscall_F1F, @Syscall_F20, @Syscall_F21, @Syscall_F22,
    @Syscall_F23, @Syscall_F24, @Syscall_F25, @Syscall_F26, @Syscall_F27,
    @Syscall_F28, @Syscall_F29, @Syscall_F2A, @Syscall_F2B, @Syscall_F2C,
    @Syscall_F2D, @Syscall_F2E, @Syscall_F2F, @Syscall_F30, @Syscall_F31,
    @Syscall_F32, @Syscall_F33, @Syscall_F34, @Syscall_F35, @Syscall_F36,
    @Syscall_F37, @Syscall_F38, @Syscall_F39, @Syscall_F3A, @Syscall_F3B,
    @Syscall_F3C, @Syscall_F3D, @Syscall_F3E, @Syscall_F3F, @Syscall_F40,
    @Syscall_F41, @Syscall_F42, @Syscall_F43, @Syscall_F44, @Syscall_F45,
    @Syscall_F46, @Syscall_F47, @Syscall_F48, @Syscall_F49, @Syscall_F4A,
    @Syscall_F4B, @Syscall_F4C, @Syscall_F4D, @Syscall_F4E, @Syscall_F4F,
    @Syscall_F50, @Syscall_F51, @Syscall_F52, @Syscall_F53, @Syscall_F54,
    @Syscall_F55, @Syscall_F56, @Syscall_F57, @Syscall_F58, @Syscall_F59,
    @Syscall_F5A, @Syscall_F5B, @Syscall_F5C, @Syscall_F5D, @Syscall_F5E,
    @Syscall_F5F, @Syscall_F60, @Syscall_F61, @Syscall_F62, @Syscall_F63,
    @Syscall_F64, @Syscall_F65, @Syscall_F66, @Syscall_F67, @Syscall_F68,
    @Syscall_F69, @Syscall_F6A, @Syscall_F6B, @Syscall_F6C, @Syscall_F6D,
    @Syscall_F6E, @Syscall_F6F, @Syscall_F70, @Syscall_F71, @Syscall_F72,
    @Syscall_F73, @Syscall_F74, @Syscall_F75, @Syscall_F76, @Syscall_F77,
    @Syscall_F78, @Syscall_F79, @Syscall_F7A, @Syscall_F7B, @Syscall_F7C,
    @Syscall_F7D, @Syscall_F7E, @Syscall_F7F, @Syscall_F80, @Syscall_F81,
    @Syscall_F82, @Syscall_F83, @Syscall_F84, @Syscall_F85, @Syscall_F86,
    @Syscall_F87, @Syscall_F88, @Syscall_F89, @Syscall_F8A, @Syscall_F8B,
    @Syscall_F8C, @Syscall_F8D, @Syscall_F8E, @Syscall_F8F, @Syscall_F90,
    @Syscall_F91, @Syscall_F92, @Syscall_F93, @Syscall_F94, @Syscall_F95,
    @Syscall_F96, @Syscall_F97, @Syscall_F98, @Syscall_F99, @Syscall_F9A,
    @Syscall_F9B, @Syscall_F9C, @Syscall_F9D, @Syscall_F9E, @Syscall_F9F,
    @Syscall_FA0, @Syscall_FA1, @Syscall_FA2, @Syscall_FA3, @Syscall_FA4,
    @Syscall_FA5, @Syscall_FA6, @Syscall_FA7, @Syscall_FA8, @Syscall_FA9,
    @Syscall_FAA, @Syscall_FAB, @Syscall_FAC, @Syscall_FAD, @Syscall_FAE,
    @Syscall_FAF, @Syscall_FB0, @Syscall_FB1, @Syscall_FB2, @Syscall_FB3,
    @Syscall_FB4, @Syscall_FB5, @Syscall_FB6, @Syscall_FB7, @Syscall_FB8,
    @Syscall_FB9, @Syscall_FBA, @Syscall_FBB, @Syscall_FBC, @Syscall_FBD,
    @Syscall_FBE, @Syscall_FBF, @Syscall_FC0, @Syscall_FC1, @Syscall_FC2,
    @Syscall_FC3, @Syscall_FC4, @Syscall_FC5, @Syscall_FC6, @Syscall_FC7,
    @Syscall_FC8, @Syscall_FC9, @Syscall_FCA, @Syscall_FCB, @Syscall_FCC,
    @Syscall_FCD, @Syscall_FCE, @Syscall_FCF, @Syscall_FD0, @Syscall_FD1,
    @Syscall_FD2, @Syscall_FD3, @Syscall_FD4, @Syscall_FD5, @Syscall_FD6,
    @Syscall_FD7, @Syscall_FD8, @Syscall_FD9, @Syscall_FDA, @Syscall_FDB,
    @Syscall_FDC, @Syscall_FDD, @Syscall_FDE, @Syscall_FDF, @Syscall_FE0,
    @Syscall_FE1, @Syscall_FE2, @Syscall_FE3, @Syscall_FE4, @Syscall_FE5,
    @Syscall_FE6, @Syscall_FE7, @Syscall_FE8, @Syscall_FE9, @Syscall_FEA,
    @Syscall_FEB, @Syscall_FEC, @Syscall_FED, @Syscall_FEE, @Syscall_FEF,
    @Syscall_FF0, @Syscall_FF1, @Syscall_FF2, @Syscall_FF3, @Syscall_FF4,
    @Syscall_FF5, @Syscall_FF6, @Syscall_FF7, @Syscall_FF8, @Syscall_FF9,
    @Syscall_FFA, @Syscall_FFB, @Syscall_FFC, @Syscall_FFD, @Syscall_FFE,
    @Syscall_FFF);

{$ENDIF}

function SyscallTrampoline;
begin
  {$IFDEF Win64}
  if Number <= High(SyscallMap) then
    Result := SyscallMap[Number]
  else
  {$ENDIF}
    Result := nil;
end;

end.
