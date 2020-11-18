#define MyAppName "SageMath"

#ifndef SageVersion
  #error SageVersion must be defined--pass /DSageVersion=<version> to InnoSetup with the correct version
#endif

#ifndef InstallerVersion
  #error InstallerVersion must be defined--pass /DInstallerVersion=<version> to InnoSetup with the correct version
#endif

#ifndef SageArch
  #define SageArch "x86_64"
#endif

#if SageArch == "x86_64"
  #define MyArchitecturesAllowed "x64"
#else
  #define MyArchitecturesAllowed "x86 x64"
#endif

#ifndef SageTestInstaller
  #define SageTestInstaller "0"
#endif

#if SageTestInstaller == "1"
  #define SageExcludes "\opt\*,\home\*"
#else
  #define SageExcludes "\home\*"
#endif

#define MyAppVersion SageVersion
#define MyAppPublisher "SageMath"
#define MyAppURL "http://www.sagemath.org/"
#define MyAppContact "http://www.sagemath.org/"

#define SageGroupName MyAppName + " " + MyAppVersion

#ifndef Compression
  #define Compression "lzma2"
#endif

#ifndef EnvsDir
  #define EnvsDir "envs"
#endif

#ifndef OutputDir
  #define OutputDir "dist"
#endif

#ifndef DiskSpanning
  #if Compression == "none"
    #define DiskSpanning="yes"
  #else
    #define DiskSpanning="no"
  #endif
#endif

#define Source      EnvsDir + "\runtime-" + SageVersion + "-" + SageArch

#define Runtime     "{app}\runtime"
#define Bin         Runtime + "\bin"
#define SageRoot "\opt\sagemath-" + MyAppVersion
#define SageRootWin Runtime + SageRoot
#define SageRootPosix "/opt/sagemath-" + MyAppVersion

#define SageDoc SageRoot + "\local\share\doc\sage\html"

[Setup]
AppCopyright={#MyAppPublisher}
AppId={#MyAppName}-{#MyAppVersion}
AppContact={#MyAppContact}
AppComments={#MyAppURL}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}
AppUpdatesURL={#MyAppURL}
ArchitecturesAllowed={#MyArchitecturesAllowed}
ArchitecturesInstallIn64BitMode=x64
DefaultDirName={pf}\{#SageGroupName}
DefaultGroupName={#SageGroupName}
DisableProgramGroupPage=yes
DisableWelcomePage=no
DiskSpanning={#DiskSpanning}
OutputDir={#OutputDir}
OutputBaseFilename={#MyAppName}-{#MyAppVersion}-Installer-v{#InstallerVersion}
OutputManifestFile=SageMath-Manifest.txt
PrivilegesRequired=lowest
Compression={#Compression}
SolidCompression=yes
WizardImageFile=resources\sage-banner.bmp
WizardSmallImageFile=resources\sage-sticker.bmp
WizardImageStretch=yes
UninstallDisplayIcon={app}\unins000.exe
SetupIconFile=resources\sage-floppy-disk.ico
ChangesEnvironment=true
SetupLogging=yes
LicenseFile="{#Source}\opt\sagemath-{#SageVersion}\COPYING.txt"

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Types]
Name: "full"; Description: "Full installation"
Name: "custom"; Description: "Custom installation"; Flags: iscustom

[Components]
Name: "sage"; Description: "SageMath Core"; Types: full custom; Flags: fixed
Name: "sagedoc"; Description: "SageMath HTML Documentation"; Types: full

[Tasks]
Name: startmenu; Description: "Create &start menu icons"; GroupDescription: "Additional icons"
Name: desktop; Description: "Create &desktop icons"; GroupDescription: "Additional icons"

[Files]
Source: "dot_sage\*"; DestDir: "{#SageRootWin}\dot_sage"; Flags: recursesubdirs ignoreversion; Components: sage
Source: "{#Source}\*"; DestDir: "{#Runtime}"; Excludes: "{#SageExcludes},{#SageDoc}"; Flags: recursesubdirs ignoreversion; Components: sage
Source: "{#Source}{#SageDoc}\*"; DestDir: "{#Runtime}{#SageDoc}"; Flags: recursesubdirs ignoreversion solidbreak; Components: sagedoc
Source: "resources\sagemath.ico"; DestDir: "{app}"; Flags: ignoreversion; AfterInstall: PostInstall; Components: sage

; InnoSetup will not create empty directories found when including files
; recursively in the [Files] section, so any directories that must exist
; (but start out empty) in the cygwin distribution must be created
;
; /etc/fstab.d is where user-specific mount tables go--this is used in
; sage for windows by /etc/sagerc to set up the /dot_sage mount point for
; each user's DOT_SAGE directory, since the actual path name might contain
; spaces and other special characters not handled well by some software that
; uses DOT_SAGE
;
; /dev/shm and /dev/mqueue are used by the system for POSIX semaphores, shared
; memory, and message queues and must be created world-writeable
[Dirs]
Name: "{#Runtime}\etc\fstab.d"; Permissions: users-modify
Name: "{#Runtime}\dev\shm"; Permissions: users-modify
Name: "{#Runtime}\dev\mqueue"; Permissions: users-modify
Name: "{#Runtime}\home\sage"; Permissions: users-modify

[UninstallDelete]
Type: filesandordirs; Name: "{#Runtime}\etc\fstab.d"
Type: filesandordirs; Name: "{#Runtime}\dev\shm"
Type: filesandordirs; Name: "{#Runtime}\dev\mqueue"
Type: files; Name: "{#Runtime}\*.stackdump"

#define RunSage "/bin/bash --login -c '" + SageRootPosix + "/sage'"
#define RunSageName "SageMath " + SageVersion
#define RunSageTitle "SageMath " + SageVersion + " Console"
#define RunSageDoc "The SageMath console interface"

#define RunSageSh "/bin/bash --login -c '" + SageRootPosix + "/sage -sh'"
#define RunSageShName "SageMath " + SageVersion + " Shell"
#define RunSageShTitle RunSageShName
#define RunSageShDoc "Command prompt in the SageMath shell environment"

#define RunSageNb "/bin/bash --login -c '" + SageRootPosix + "/sage --notebook jupyter'"
#define RunSageNbName "SageMath " + SageVersion + " Notebook"
#define RunSageNbTitle "SageMath " + SageVersion + " Notebook Server"
#define RunSageNbDoc "Start SageMath notebook server"

[Icons]
Name: "{app}\{#RunSageName}"; Filename: "{#Bin}\mintty.exe"; Parameters: "-t '{#RunSageTitle}' -i sagemath.ico {#RunSage}"; WorkingDir: "{app}"; Comment: "{#RunSageDoc}"; IconFilename: "{app}\sagemath.ico"
Name: "{group}\{#RunSageName}"; Filename: "{#Bin}\mintty.exe"; Parameters: "-t '{#RunSageTitle}' -i sagemath.ico {#RunSage}"; WorkingDir: "{app}"; Comment: "{#RunSageDoc}"; IconFilename: "{app}\sagemath.ico"; Tasks: startmenu
Name: "{code:GetDesktopPath}\{#RunSageName}"; Filename: "{#Bin}\mintty.exe"; Parameters: "-t '{#RunSageTitle}' -i sagemath.ico {#RunSage}"; WorkingDir: "{app}"; Comment: "{#RunSageDoc}"; IconFilename: "{app}\sagemath.ico"; Tasks: desktop

Name: "{app}\{#RunSageShName}"; Filename: "{#Bin}\mintty.exe"; Parameters: "-t '{#RunSageShTitle}' -i sagemath.ico {#RunSageSh}"; WorkingDir: "{app}"; Comment: "{#RunSageShDoc}"; IconFilename: "{app}\sagemath.ico"
Name: "{group}\{#RunSageShName}"; Filename: "{#Bin}\mintty.exe"; Parameters: "-t '{#RunSageShTitle}' -i sagemath.ico {#RunSageSh}"; WorkingDir: "{app}"; Comment: "{#RunSageShDoc}"; IconFilename: "{app}\sagemath.ico"; Tasks: startmenu
Name: "{code:GetDesktopPath}\{#RunSageShName}"; Filename: "{#Bin}\mintty.exe"; Parameters: "-t '{#RunSageShTitle}' -i sagemath.ico {#RunSageSh}"; WorkingDir: "{app}"; Comment: "{#RunSageShDoc}"; IconFilename: "{app}\sagemath.ico"; Tasks: desktop

Name: "{app}\{#RunSageNbName}"; Filename: "{#Bin}\mintty.exe"; Parameters: "-t '{#RunSageNbTitle}' -i sagemath.ico {#RunSageNb}"; WorkingDir: "{app}"; Comment: "{#RunSageNbDoc}"; IconFilename: "{app}\sagemath.ico"
Name: "{group}\{#RunSageNbName}"; Filename: "{#Bin}\mintty.exe"; Parameters: "-t '{#RunSageNbTitle}' -i sagemath.ico {#RunSageNb}"; WorkingDir: "{app}"; Comment: "{#RunSageNbDoc}"; IconFilename: "{app}\sagemath.ico"; Tasks: startmenu
Name: "{code:GetDesktopPath}\{#RunSageNbName}"; Filename: "{#Bin}\mintty.exe"; Parameters: "-t '{#RunSageNbTitle}' -i sagemath.ico {#RunSageNb}"; WorkingDir: "{app}"; Comment: "{#RunSageNbDoc}"; IconFilename: "{app}\sagemath.ico"; Tasks: desktop

[Code]
var
    UserInstall: Boolean;
    UserHomeDir: String;
    InstallModeSelectPageID: Integer;
    UserHomeDirSelectPageID: Integer;


// This function is used above in the [Icons] section to get the correct
// installation path for desktop icons depending on what installation mode
// was selected
function GetDesktopPath(Param: String): String;
begin
    if UserInstall then
    begin
        Result := ExpandConstant('{userdesktop}');
    end
    else begin
        Result := ExpandConstant('{commondesktop}');
    end;
end;


// ******************* Custom Install Wizard Pages ***************************


function ProcessInstallModeSelectPage(Page: TWizardPage): Boolean;
begin
    if TInputOptionWizardPage(Page).CheckListBox.Checked[0] then
    begin
        WizardForm.DirEdit.Text := ExpandConstant('{localappdata}\{#SageGroupName}');
        UserInstall := True;
    end
    else begin
        WizardForm.DirEdit.Text := ExpandConstant('{pf}\{#SageGroupName}');
        UserInstall := False;
    end;

    Result := True;
end;


procedure CreateInstallModeSelectPage();
var
    Page: TInputOptionWizardPage;
begin
    Page := CreateInputOptionPage(wpUserInfo, 'Install Mode Select',
    'Install either for a single user or for all users on the system (requires Administrator privileges).', '', True, False);
    InstallModeSelectPageID := Page.ID;

    Page.Add('Install just for the current user');
    Page.Add('Install for all users (installer must be run with Administrator privileges)');

    UserInstall := Boolean(
        StrToInt(
            GetPreviousData('UserInstall', IntToStr(Integer(not IsAdminLoggedOn())))));

    with Page do
    begin
        CheckListBox.Checked[0] := UserInstall;
        CheckListBox.Checked[1] := (not UserInstall);
        CheckListBox.ItemEnabled[1] := IsAdminLoggedOn();
        OnNextButtonClick := @ProcessInstallModeSelectPage;
    end;
end;


function ProcessUserHomeDirSelectPage(Page: TWizardPage): Boolean;
begin
    UserHomeDir := TInputDirWizardPage(Page).Values[0];
    Result := True;
end;


procedure CreateUserHomeDirSelectPage();
var
    Page: TInputDirWizardPage;
begin
    Page := CreateInputDirPage(InstallModeSelectPageID, 'Select Sage home directory',
    'Select the default directory that Sage will start in', '', False, '');
    Page.Add('Sage will start with this folder as your working directory by default; you can also change this after installation using the sage-sethome command:');
    UserHomeDirSelectPageID := Page.ID;
    with Page do
    begin
        Values[0] := ExpandConstant('{%USERPROFILE}');
        OnNextButtonClick := @ProcessUserHomeDirSelectPage;
    end;
end;


procedure RegisterPreviousData(PreviousDataKey: Integer);
begin
    SetPreviousData(PreviousDataKey, 'UserInstall', IntToStr(Integer(UserInstall)));
end;


function ShouldSkipPage(PageID: Integer): Boolean;
begin
    Result := False;
    if (PageID = UserHomeDirSelectPageID) and (not UserInstall) then
        Result := True;
end;


procedure InitializeWizard();
begin
    UserInstall := not IsAdminLoggedOn();
    CreateInstallModeSelectPage();
    CreateUserHomeDirSelectPage();
end;


// Symlinks from the Cygwin runtime are stored in the .lnk file format
// which is one of the different ways of storing symlinks supported by Cygwin;
// for this to work they must have the READ ONLY attribute set on them.
// When the files are compressed by InnoSetup they lose this attribute, so
// we must have a list of files that are supposed to by symlinks, which is
// created by the Makefile as <runtime-env>/etc/symlinks.lst and included in
// the installer.  This procedure loops over all the files in this list and
// applies the READ ONLY attribute to them so they can once again be recognized
// by Cygwin as symlinks.
procedure FixupSymlinks();
var
    n: Integer;
    i: Integer;
    resultCode: Integer;
    filenames: TArrayOfString;
    filenam: String;
begin
    LoadStringsFromFile(ExpandConstant('{#Runtime}\etc\symlinks.lst'), filenames);
    n := GetArrayLength(filenames);
    WizardForm.ProgressGauge.Min := 0;
    WizardForm.ProgressGauge.Max := n - 1;
    WizardForm.ProgressGauge.Position := 0;
    WizardForm.StatusLabel.Caption := 'Fixing up symlinks...';
    for i := 0 to n - 1 do
    begin
        filenam := filenames[i] + '.lnk';
        WizardForm.FilenameLabel.Caption := Copy(filenam, 2, Length(filenam));
        WizardForm.ProgressGauge.Position := i;
        Exec(ExpandConstant('{sys}\attrib.exe'), '+R ' + filenam,
             ExpandConstant('{#Runtime}'), SW_HIDE, ewNoWait, resultCode);
    end;
end;


// In principle we should be able to run the sage-sethome script with the
// just-installed bash.exe, but this seems to encounter insurmountable
// problems with quoting or I'm not sure what else, so we essentially
// reimplement that script here to write the appropriate /etc/fstab.d file.
procedure SetHome();
var
    resultCode: Integer;
    userHome: String;
    fstabdFile: String;
    fstabLine: String;
    fstabLines: TArrayOfString;
begin
    fstabdFile := ExpandConstant('{#Runtime}\etc\fstab.d\') + GetUserNameString();
    userHome := Copy(UserHomeDir, 1, Length(UserHomeDir));
    StringChangeEx(userHome, ' ', '\040', True)
    fstabLine := userHome + ' /home/sage ntfs binary,posix=1,user,acl 0 0';
    SetArrayLength(fstabLines, 2);
    fstabLines[0] := fstabLine;
    fstabLines[1] := 'none /tmp usertemp binary,posix=0 0 0';
    SaveStringsToUTF8File(fstabdFile, fstabLines, False);
    // The above nevertheless writes the file with a bunch of stupid
    // ideosyncracies (most notably, a useless UTF-8 BOM) which confuse
    // Cygwin; we run this final cleanup script to fix everything, ugh.
    Exec(ExpandConstant('{#Bin}\dash.exe'),
         '/usr/local/bin/_sage-complete-install.sh',
         ExpandConstant('{#Runtime}'), 
         SW_HIDE, ewNoWait, resultCode);
end;


procedure PostInstall();
begin
    FixupSymlinks();
    if UserInstall then
        SetHome();
end;
