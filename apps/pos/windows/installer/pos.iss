; Kassa ilovasi — Windows o'rnatuvchisi (T-093, docs/RELEASE.md).
; Yig'ish: apps/pos/tool/build-windows-installer.ps1 (flutter build windows + ISCC).
; Parametrlar (ISCC /D...): AppVersion, BuildNumber, SourceDir (Release papkasi), OutputDir.
;
; Ma'lumot (lokal baza) foydalanuvchi AppData papkasida — o'chirishda TEGILMAYDI
; (CLAUDE.md: ma'lumot hech qachon o'chirilmaydi; qayta o'rnatilsa davom etadi).

#ifndef AppVersion
  #define AppVersion "0.0.0"
#endif
#ifndef BuildNumber
  #define BuildNumber "0"
#endif
#ifndef SourceDir
  #define SourceDir "..\..\build\windows\x64\runner\Release"
#endif
#ifndef OutputDir
  #define OutputDir "..\..\..\..\dist"
#endif

#define AppName "Kassa"
#define AppExe "pos_app.exe"

[Setup]
; AppId o'zgarmaydi — yangilash eski o'rnatish ustiga yoziladi.
AppId={{6F1C2B8E-3A4D-4E5F-9C7B-2D8A1E0F5B63}
AppName={#AppName}
AppVersion={#AppVersion}
AppVerName={#AppName} {#AppVersion}
VersionInfoVersion={#AppVersion}.{#BuildNumber}
AppPublisher=POS
DefaultDirName={autopf}\{#AppName}
DefaultGroupName={#AppName}
DisableProgramGroupPage=yes
; Standart — faqat joriy foydalanuvchi (admin huquqi shart emas); dialogda "barcha
; foydalanuvchilar" tanlansa — Program Files ga (admin).
PrivilegesRequired=lowest
PrivilegesRequiredOverridesAllowed=dialog commandline
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
MinVersion=10.0
OutputDir={#OutputDir}
OutputBaseFilename=kassa-setup-{#AppVersion}
SetupIconFile=..\runner\resources\app_icon.ico
UninstallDisplayIcon={app}\{#AppExe}
Compression=lzma2/max
SolidCompression=yes
WizardStyle=modern
; Ishlab turgan ilovani yopib, yangilaydi.
CloseApplications=yes
RestartApplications=no

[Languages]
Name: "ru"; MessagesFile: "compiler:Languages\Russian.isl"
Name: "en"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"

[Files]
; Flutter Release papkasi: exe, DLL'lar (flutter, sqlite3, plaginlar, VC++ runtime), data/.
Source: "{#SourceDir}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\{#AppName}"; Filename: "{app}\{#AppExe}"
Name: "{group}\{cm:UninstallProgram,{#AppName}}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\{#AppName}"; Filename: "{app}\{#AppExe}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#AppExe}"; Description: "{cm:LaunchProgram,{#AppName}}"; Flags: nowait postinstall skipifsilent
