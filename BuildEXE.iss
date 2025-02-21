#define MyAppName "WaterTime"
#define MyAppVersion "1.3.0"
#define MyAppPublisher "JulioHeroZ"
#define MyAppURL "https://github.com/JulioHeroZ/WaterTime"
#define MyAppExeName "watertime.exe"
#define CertificatePath "C:\Users\071444\Documents\Projetos\WaterTime\Certificado\WaterTime Certificate.pfx"
#define CertificatePassword "Julio1065671133"

[Setup]
AppId={{YOUR-APP-ID-HERE}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}
AppUpdatesURL={#MyAppURL}
DefaultDirName={autopf}\{#MyAppName}
DisableProgramGroupPage=yes
OutputBaseFilename=watertime-{#MyAppVersion}+1-windows-setup
Compression=lzma
SolidCompression=yes
WizardStyle=modern
SignTool=sign /f "{#CertificatePath}" /p {#CertificatePassword} /tr http://timestamp.digicert.com /td sha256 /fd sha256 $f
SignedUninstaller=yes

[Languages]
Name: "portuguese"; MessagesFile: "compiler:Languages\Portuguese.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
Source: "build\windows\x64\runner\Release\{#MyAppExeName}"; DestDir: "{app}"; Flags: ignoreversion
Source: "build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs
Source: "dsa_pub.pem"; DestDir: "{app}"; Flags: ignoreversion

[Icons]
Name: "{autoprograms}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#StringChange(MyAppName, '&', '&&')}}"; Flags: nowait postinstall skipifsilent

[Code]
// Adicione código para inicializar o WinSparkle durante a instalação