;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; NSIS installer script for vlc ;
; (http://nsis.sourceforge.net) ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

!include "languages\declaration.nsh"

!define PRODUCT_NAME "VLC media player"
!define VERSION 0.9.4
!define PRODUCT_VERSION 0.9.4
!define PRODUCT_GROUP "VideoLAN"
!define PRODUCT_PUBLISHER "VideoLAN Team"
!define PRODUCT_WEB_SITE "http://www.videolan.org"
!define PRODUCT_DIR_REGKEY "Software\VideoLAN\VLC"
!define PRODUCT_UNINST_KEY "Software\Microsoft\Windows\CurrentVersion\Uninstall\${PRODUCT_NAME}"
!define PRODUCT_UNINST_ROOT_KEY "HKLM"
!define PRODUCT_ID "{ea92ef52-afe4-4212-bacb-dfe9fca94cd6}"

!define MUI_LANGDLL_REGISTRY_ROOT "HKLM"
!define MUI_LANGDLL_REGISTRY_KEY "${PRODUCT_DIR_REGKEY}"
!define MUI_LANGDLL_REGISTRY_VALUENAME "Language"

!define LIBVLCCORE_DLL libvlccore.dll
!define LIBVLC_DLL libvlc.dll

;;;;;;;;;;;;;;;;;;;;;;;;;
; General configuration ;
;;;;;;;;;;;;;;;;;;;;;;;;;

Name "${PRODUCT_NAME} ${PRODUCT_VERSION}"
OutFile ..\vlc-${VERSION}-win32.exe
InstallDir "$PROGRAMFILES\VideoLAN\VLC"
InstallDirRegKey HKLM "${PRODUCT_DIR_REGKEY}" ""
!ifdef NSIS_LZMA_COMPRESS_WHOLE
SetCompressor lzma
!else
SetCompressor /SOLID lzma
!endif

;ShowInstDetails show
;ShowUnInstDetails show
SetOverwrite ifnewer
CRCCheck on
BrandingText "${PRODUCT_GROUP} ${PRODUCT_NAME}"

InstType $Name_InstTypeRecommended
InstType $Name_InstTypeMinimum
InstType $Name_InstTypeFull

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; NSIS Modern User Interface configuration ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; MUI 1.67 compatible ------
  !include "MUI.nsh"

; MUI Settings
  !define MUI_ABORTWARNING
  !define MUI_ICON "vlc48x48.ico"
  !define MUI_UNICON "vlc48x48.ico"
  !define MUI_COMPONENTSPAGE_SMALLDESC

; Installer pages
  ; Welcome page
    !define MUI_WELCOMEPAGE_TITLE_3LINES
    !insertmacro MUI_PAGE_WELCOME
  ; License page
    !insertmacro MUI_PAGE_LICENSE "COPYING.txt"
  ; Components page
    !insertmacro MUI_PAGE_COMPONENTS
  ; Directory page
    !insertmacro MUI_PAGE_DIRECTORY
  ; Instfiles page
    !insertmacro MUI_PAGE_INSTFILES
  ; Finish page
    !define MUI_FINISHPAGE_RUN "$INSTDIR\vlc.exe"
    !define MUI_FINISHPAGE_SHOWREADME "$INSTDIR\README.txt"
    !define MUI_FINISHPAGE_SHOWREADME_NOTCHECKED
    !define MUI_FINISHPAGE_LINK $Link_VisitWebsite
    !define MUI_FINISHPAGE_LINK_LOCATION "http://www.videolan.org/vlc/"
    !define MUI_FINISHPAGE_NOREBOOTSUPPORT
    !insertmacro MUI_PAGE_FINISH

; Uninstaller pages
    !insertmacro MUI_UNPAGE_CONFIRM
    !insertmacro MUI_UNPAGE_COMPONENTS
    !insertmacro MUI_UNPAGE_INSTFILES
    !insertmacro MUI_UNPAGE_FINISH

; Language files
  !insertmacro MUI_LANGUAGE "English" # first language is the default language
  !insertmacro MUI_LANGUAGE "French"
  !insertmacro MUI_LANGUAGE "German"
  !insertmacro MUI_LANGUAGE "Spanish"
  !insertmacro MUI_LANGUAGE "SimpChinese"
  !insertmacro MUI_LANGUAGE "TradChinese"
  !insertmacro MUI_LANGUAGE "Japanese"
  !insertmacro MUI_LANGUAGE "Korean"
  !insertmacro MUI_LANGUAGE "Italian"
  !insertmacro MUI_LANGUAGE "Dutch"
  !insertmacro MUI_LANGUAGE "Danish"
  !insertmacro MUI_LANGUAGE "Swedish"
  !insertmacro MUI_LANGUAGE "Norwegian"
  !insertmacro MUI_LANGUAGE "Finnish"
  !insertmacro MUI_LANGUAGE "Greek"
  !insertmacro MUI_LANGUAGE "Russian"
  !insertmacro MUI_LANGUAGE "Portuguese"
  !insertmacro MUI_LANGUAGE "Arabic"
  !insertmacro MUI_LANGUAGE "Polish"
  !insertmacro MUI_LANGUAGE "Romanian"
  !insertmacro MUI_LANGUAGE "Slovak"
  !insertmacro MUI_LANGUAGE "Czech"
  !insertmacro MUI_LANGUAGE "Hungarian"
  !insertmacro MUI_LANGUAGE "Catalan"
  !insertmacro MUI_LANGUAGE "Bulgarian"

; Reserve files for solid compression
  !insertmacro MUI_RESERVEFILE_LANGDLL
  !insertmacro MUI_RESERVEFILE_INSTALLOPTIONS

; MUI end ------

;;;;;;;;;;;;;;;;;;;;;;;
; Macro and Functions ;
;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; 1. File type associations ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Function that register one extension for VLC
Function RegisterExtension
  ; back up old value for extension $R0 (eg. ".opt")
  ReadRegStr $1 HKCR "$R0" ""
  StrCmp $1 "" NoBackup
    StrCmp $1 "VLC$R0" "NoBackup"
    WriteRegStr HKCR "$R0" "VLC.backup" $1
NoBackup:
  WriteRegStr HKCR "$R0" "" "VLC$R0"
  ReadRegStr $0 HKCR "VLC$R0" ""
  WriteRegStr HKCR "VLC$R0" "" "VLC media file ($R0)"
  WriteRegStr HKCR "VLC$R0\shell" "" "Play"
  WriteRegStr HKCR "VLC$R0\shell\Play" "" $ShellAssociation_Play
  WriteRegStr HKCR "VLC$R0\shell\Play\command" "" '"$INSTDIR\vlc.exe" --started-from-file "%1"'
  WriteRegStr HKCR "VLC$R0\DefaultIcon" "" '"$INSTDIR\vlc.exe",0'

;;; Vista Only part
  ; Vista detection
  ReadRegStr $R1 HKLM "SOFTWARE\Microsoft\Windows NT\CurrentVersion" CurrentVersion
  StrCpy $R2 $R1 3
  StrCmp $R2 '6.0' ForVista ToEnd
ForVista:
  WriteRegStr HKLM "Software\Clients\Media\VLC\Capabilities\FileAssociations" "$R0" "VLC$R0"

ToEnd:
FunctionEnd

;; Function that removes one extension that VLC owns.
Function un.RegisterExtension
  ;start of restore script
  ReadRegStr $1 HKCR "$R0" ""
  StrCmp $1 "VLC$R0" 0 NoOwn ; only do this if we own it
    ; Read the old value from Backup
    ReadRegStr $1 HKCR "$R0" "VLC.backup"
    StrCmp $1 "" 0 Restore ; if backup="" then delete the whole key
      DeleteRegKey HKCR "$R0"
    Goto NoOwn
Restore:
      WriteRegStr HKCR "$R0" "" $1
      DeleteRegValue HKCR "$R0" "VLC.backup"
NoOwn:
    DeleteRegKey HKCR "VLC$R0" ;Delete key with association settings
    DeleteRegKey HKLM "Software\Clients\Media\VLC\Capabilities\FileAssociations\VLC$R0" ; for vista
FunctionEnd

!macro RegisterExtensionSection EXT
  Section ${EXT}
    SectionIn 1 3
    Push $R0
    StrCpy $R0 ${EXT}
    Call RegisterExtension
    Pop $R0
  SectionEnd
!macroend

!macro UnRegisterExtensionSection EXT
  Push $R0
  StrCpy $R0 ${EXT}
  Call un.RegisterExtension
  Pop $R0
!macroend

!macro WriteRegStrSupportedTypes EXT
  WriteRegStr HKCR Applications\vlc.exe\SupportedTypes ${EXT} ""
!macroend

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Extension lists  Macros                    ;
; Those macros calls the previous functions  ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

!macro MacroAudioExtensions _action
  !insertmacro ${_action} ".a52"
  !insertmacro ${_action} ".aac"
  !insertmacro ${_action} ".ac3"
  !insertmacro ${_action} ".dts"
  !insertmacro ${_action} ".flac"
  !insertmacro ${_action} ".m4a"
  !insertmacro ${_action} ".m4p"
  !insertmacro ${_action} ".mka"
  !insertmacro ${_action} ".mod"
  !insertmacro ${_action} ".mp1"
  !insertmacro ${_action} ".mp2"
  !insertmacro ${_action} ".mp3"
  !insertmacro ${_action} ".oma"
  !insertmacro ${_action} ".ogg"
  !insertmacro ${_action} ".spx"
  !insertmacro ${_action} ".wav"
  !insertmacro ${_action} ".wma"
  !insertmacro ${_action} ".xm"
!macroend

!macro MacroVideoExtensions _action
  !insertmacro ${_action} ".asf"
  !insertmacro ${_action} ".avi"
  !insertmacro ${_action} ".divx"
  !insertmacro ${_action} ".dv"
  !insertmacro ${_action} ".flv"
  !insertmacro ${_action} ".gxf"
  !insertmacro ${_action} ".m1v"
  !insertmacro ${_action} ".m2v"
  !insertmacro ${_action} ".m2ts"
  !insertmacro ${_action} ".m4v"
  !insertmacro ${_action} ".mkv"
  !insertmacro ${_action} ".mov"
  !insertmacro ${_action} ".mp4"
  !insertmacro ${_action} ".mpeg"
  !insertmacro ${_action} ".mpeg1"
  !insertmacro ${_action} ".mpeg2"
  !insertmacro ${_action} ".mpeg4"
  !insertmacro ${_action} ".mpg"
  !insertmacro ${_action} ".mts"
  !insertmacro ${_action} ".mxf"
  !insertmacro ${_action} ".ogm"
  !insertmacro ${_action} ".ts"
  !insertmacro ${_action} ".vob"
  !insertmacro ${_action} ".wmv"
!macroend

!macro MacroOtherExtensions _action
  !insertmacro ${_action} ".asx"
  !insertmacro ${_action} ".bin"
  !insertmacro ${_action} ".cue"
  !insertmacro ${_action} ".m3u"
  !insertmacro ${_action} ".pls"
  !insertmacro ${_action} ".vlc"
  !insertmacro ${_action} ".xspf"
!macroend

; One macro to rule them all
!macro MacroAllExtensions _action
  !insertmacro MacroAudioExtensions ${_action}
  !insertmacro MacroVideoExtensions ${_action}
  !insertmacro MacroOtherExtensions ${_action}
!macroend

;;;;;;;;;;;;;;;;;;;;;;;;;;;
; 2. Context menu entries ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Generic function for adding the context menu for one ext.
!macro AddContextMenuExt EXT
  WriteRegStr HKCR ${EXT}\shell\PlayWithVLC "" $ContextMenuEntry_PlayWith
  WriteRegStr HKCR ${EXT}\shell\PlayWithVLC\command "" '$INSTDIR\vlc.exe --started-from-file --no-playlist-enqueue "%1"'

  WriteRegStr HKCR ${EXT}\shell\AddToPlaylistVLC "" $ContextMenuEntry_AddToPlaylist
  WriteRegStr HKCR ${EXT}\shell\AddToPlaylistVLC\command "" '$INSTDIR\vlc.exe --started-from-file --playlist-enqueue "%1"'
!macroend

!macro AddContextMenu EXT
  Push $R0
  ReadRegStr $R0 HKCR ${EXT} ""
  !insertmacro AddContextMenuExt $R0
  Pop $R0
!macroend

!macro DeleteContextMenuExt EXT
  DeleteRegKey HKCR ${EXT}\shell\PlayWithVLC
  DeleteRegKey HKCR ${EXT}\shell\AddToPlaylistVLC
!macroend

!macro DeleteContextMenu EXT
  Push $R0
  ReadRegStr $R0 HKCR ${EXT} ""
  !insertmacro DeleteContextMenuExt $R0
  Pop $R0
!macroend

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; 3. Delete prefs and cache ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

!macro delprefs
  StrCpy $0 0
  !define Index 'Line${__LINE__}'
  "${Index}-Loop:"
  ; FIXME
  ; this will loop through all the logged users and "virtual" windows users
  ; (it looks like users are only present in HKEY_USERS when they are logged in)
    ClearErrors
    EnumRegKey $1 HKU "" $0
    StrCmp $1 "" "${Index}-End"
    IntOp $0 $0 + 1
    ReadRegStr $2 HKU "$1\Software\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders" AppData
    StrCmp $2 "" "${Index}-Loop"
    RMDir /r "$2\vlc"
    Goto "${Index}-Loop"
  "${Index}-End:"
  !undef Index
!macroend

;;;;;;;;;;;;;;;
; 4. Logging  ;
;;;;;;;;;;;;;;;
Var UninstallLog
!macro OpenUninstallLog
  FileOpen $UninstallLog "$INSTDIR\uninstall.log" a
  FileSeek $UninstallLog 0 END
!macroend

!macro CloseUninstallLog
  FileClose $UninstallLog
  SetFileAttributes "$INSTDIR\uninstall.log" HIDDEN
!macroend

;;;;;;;;;;;;;;;;;;;;
; 5. Installations ;
;;;;;;;;;;;;;;;;;;;;
!macro InstallFile FILEREGEX
  File "${FILEREGEX}"
  !define Index 'Line${__LINE__}'
  FindFirst $0 $1 "$INSTDIR\${FILEREGEX}"
  StrCmp $0 "" "${Index}-End"
  "${Index}-Loop:"
    StrCmp $1 "" "${Index}-End"
    FileWrite $UninstallLog "$1$\r$\n"
    FindNext $0 $1
    Goto "${Index}-Loop"
  "${Index}-End:"
  !undef Index
!macroend

!macro InstallFolder FOLDER
  File /r "${FOLDER}"
  Push "${FOLDER}"
  Call InstallFolderInternal
!macroend

Function InstallFolderInternal
  Pop $9
  !define Index 'Line${__LINE__}'
  FindFirst $0 $1 "$INSTDIR\$9\*"
  StrCmp $0 "" "${Index}-End"
  "${Index}-Loop:"
    StrCmp $1 "" "${Index}-End"
    StrCmp $1 "." "${Index}-Next"
    StrCmp $1 ".." "${Index}-Next"
    IfFileExists "$9\$1\*" 0 "${Index}-Write"
      Push $0
      Push $9
      Push "$9\$1"
      Call InstallFolderInternal
      Pop $9
      Pop $0
      Goto "${Index}-Next"
    "${Index}-Write:"
    FileWrite $UninstallLog "$9\$1$\r$\n"
    "${Index}-Next:"
    FindNext $0 $1
    Goto "${Index}-Loop"
  "${Index}-End:"
  !undef Index
FunctionEnd
;;; End of Macros


;;;;;;;;;;;;;;;;;;;;;;
; Installer sections ;
; The CORE of the    ;
; installer          ;
;;;;;;;;;;;;;;;;;;;;;;
  
Section $Name_Section01 SEC01
  SectionIn 1 2 3 RO
  SetShellVarContext all
  SetOutPath "$INSTDIR"

  !insertmacro OpenUninstallLog

  ; VLC.exe, libvlc.dll
  !insertmacro InstallFile vlc.exe
  !insertmacro InstallFile vlc.exe.manifest

  ; All dlls
  !insertmacro InstallFile *.dll

  ; Text files
  !insertmacro InstallFile *.txt

  ; Subfolders
  !insertmacro InstallFolder plugins
  !insertmacro InstallFolder locale
  !insertmacro InstallFolder osdmenu
  !insertmacro InstallFolder skins
  !insertmacro InstallFolder http
  !insertmacro InstallFolder lua

  ; URLs
  WriteIniStr "$INSTDIR\${PRODUCT_GROUP} Website.url" "InternetShortcut" "URL" \
    "${PRODUCT_WEB_SITE}"
  FileWrite $UninstallLog "${PRODUCT_GROUP} Website.url$\r$\n"
  WriteIniStr "$INSTDIR\Documentation.url" "InternetShortcut" "URL" \
    "${PRODUCT_WEB_SITE}/doc/"
  FileWrite $UninstallLog "Documentation.url$\r$\n"
  WriteIniStr "$INSTDIR\New_Skins.url" "InternetShortcut" "URL" \
    "${PRODUCT_WEB_SITE}/vlc/skins.php"
  FileWrite $UninstallLog "New_Skins.url$\r$\n"

  !insertmacro CloseUninstallLog

  ; Add VLC to "recomended programs" for the following extensions
  WriteRegStr HKCR Applications\vlc.exe "" ""
  WriteRegStr HKCR Applications\vlc.exe "FriendlyAppName" "VLC media player"
  WriteRegStr HKCR Applications\vlc.exe\shell\Play "" $ContextMenuEntry_PlayWith
  WriteRegStr HKCR Applications\vlc.exe\shell\Play\command "" \
    '$INSTDIR\vlc.exe --started-from-file "%1"'
  !insertmacro MacroAllExtensions WriteRegStrSupportedTypes

; Vista Registration
  ; Vista detection
  ReadRegStr $R0 HKLM "SOFTWARE\Microsoft\Windows NT\CurrentVersion" CurrentVersion
  StrCpy $R1 $R0 3
  StrCmp $R1 '6.0' lbl_vista lbl_done

  lbl_vista:
  WriteRegStr HKLM "Software\RegisteredApplications" "VLC" "Software\Clients\Media\VLC\Capabilities"
  WriteRegStr HKLM "Software\Clients\Media\VLC\Capabilities" "ApplicationName" "VLC media player"
  WriteRegStr HKLM "Software\Clients\Media\VLC\Capabilities" "ApplicationDescription" "VLC - The video swiss knife"

  lbl_done:
SectionEnd

Section $Name_Section02a SEC02a
  SectionIn 1 2 3
  CreateDirectory "$SMPROGRAMS\VideoLAN"
  CreateDirectory "$SMPROGRAMS\VideoLAN\Quick Settings"
  CreateDirectory "$SMPROGRAMS\VideoLAN\Quick Settings\Audio"
  CreateShortCut "$SMPROGRAMS\VideoLAN\Quick Settings\Audio\Set Audio mode to DirectX (default).lnk" \
    "$INSTDIR\vlc.exe" "--aout aout_directx --save-config vlc://quit"
  CreateShortCut "$SMPROGRAMS\VideoLAN\Quick Settings\Audio\Set Audio mode to Waveout.lnk" \
    "$INSTDIR\vlc.exe" "--aout waveout --save-config vlc://quit"
  CreateDirectory "$SMPROGRAMS\VideoLAN\Quick Settings\Interface"
  CreateShortCut "$SMPROGRAMS\VideoLAN\Quick Settings\Interface\Set Main Interface to Skinnable.lnk" \
    "$INSTDIR\vlc.exe" "-I skins --save-config vlc://quit"
  CreateShortCut "$SMPROGRAMS\VideoLAN\Quick Settings\Interface\Set Main Interface to Qt (default).lnk" \
    "$INSTDIR\vlc.exe" "-I qt --save-config vlc://quit"
  CreateDirectory "$SMPROGRAMS\VideoLAN\Quick Settings\Video"
  ; FIXME add detection for Vista. Direct3D will be default there, for all others it's DirectX
  CreateShortCut "$SMPROGRAMS\VideoLAN\Quick Settings\Video\Set Video mode to Direct3D.lnk" \
    "$INSTDIR\vlc.exe" "--vout direct3d --overlay --directx-hw-yuv --save-config vlc://quit"
  CreateShortCut "$SMPROGRAMS\VideoLAN\Quick Settings\Video\Set Video mode to Direct3D (no hardware acceleration).lnk" \
    "$INSTDIR\vlc.exe" "--vout direct3d --overlay --no-directx-hw-yuv --save-config vlc://quit"
  CreateShortCut "$SMPROGRAMS\VideoLAN\Quick Settings\Video\Set Video mode to DirectX.lnk" \
    "$INSTDIR\vlc.exe" "--vout directx --overlay --directx-hw-yuv --save-config vlc://quit"
  CreateShortCut "$SMPROGRAMS\VideoLAN\Quick Settings\Video\Set Video mode to DirectX (no hardware acceleration).lnk" \
    "$INSTDIR\vlc.exe" "--vout directx --no-overlay --no-directx-hw-yuv --save-config vlc://quit"
  CreateShortCut "$SMPROGRAMS\VideoLAN\Quick Settings\Video\Set Video mode to DirectX (no video overlay).lnk" \
    "$INSTDIR\vlc.exe" "--vout directx --no-overlay --directx-hw-yuv --save-config vlc://quit"
  CreateShortCut "$SMPROGRAMS\VideoLAN\Quick Settings\Video\Set Video mode to OpenGL.lnk" \
    "$INSTDIR\vlc.exe" "--vout opengl --overlay --save-config vlc://quit"
  CreateShortCut "$SMPROGRAMS\VideoLAN\Quick Settings\Reset VLC media player preferences and cache files.lnk" \
    "$INSTDIR\vlc.exe" "--reset-config --reset-plugins-cache vlc://quit"
  CreateShortCut "$SMPROGRAMS\VideoLAN\Documentation.lnk" \
    "$INSTDIR\Documentation.url"
  CreateShortCut "$SMPROGRAMS\VideoLAN\Release Notes.lnk" \
    "$INSTDIR\NEWS.txt" ""
  CreateShortCut "$SMPROGRAMS\VideoLAN\${PRODUCT_GROUP} Website.lnk" \
    "$INSTDIR\${PRODUCT_GROUP} Website.url"
  CreateShortCut "$SMPROGRAMS\VideoLAN\VLC media player.lnk" \
    "$INSTDIR\vlc.exe" ""
SectionEnd

Section $Name_Section02b SEC02b
  SectionIn 1 2 3
  CreateShortCut "$DESKTOP\VLC media player.lnk" \
    "$INSTDIR\vlc.exe" ""
SectionEnd

Section /o $Name_Section03 SEC03
  SectionIn 3

  SetOutPath "$INSTDIR"
  !insertmacro OpenUninstallLog
  !insertmacro InstallFile mozilla\npvlc.dll
  !insertmacro CloseUninstallLog

  !define Moz "SOFTWARE\MozillaPlugins\@videolan.org/vlc,version=${VERSION}"
  WriteRegStr HKLM ${Moz} "Description" "VLC Multimedia Plugin"
  WriteRegStr HKLM ${Moz} "Path" "$INSTDIR\npvlc.dll"
  WriteRegStr HKLM ${Moz} "Product" "VLC media player"
  WriteRegStr HKLM ${Moz} "Vendor" "VideoLAN"
  WriteRegStr HKLM ${Moz} "Version" "${VERSION}"

 ; for very old version of mozilla, these lines may be needed
 ;Push $R0
 ;Push $R1
 ;Push $R2

 ;!define Index 'Line${__LINE__}'
 ;StrCpy $R1 "0"

 ;"${Index}-Loop:"

 ;  ; Check for Key
 ;  EnumRegKey $R0 HKLM "SOFTWARE\Mozilla" "$R1"
 ;  StrCmp $R0 "" "${Index}-End"
 ;  IntOp $R1 $R1 + 1
 ;  ReadRegStr $R2 HKLM "SOFTWARE\Mozilla\$R0\Extensions" "Plugins"
 ;  StrCmp $R2 "" "${Index}-Loop" ""

 ;  CopyFiles "$INSTDIR\npvlc.dll" "$R2"
 ;  !ifdef LIBVLC_DLL
 ;  CopyFiles ${LIBVLC_DLL} "$R2"
 ;  !endif
 ;  !ifdef LIBVLC_CONTROL_DLL
 ;  CopyFiles ${LIBVLC_CONTROL_DLL} "$R2"
 ;  !endif
 ;  Goto "${Index}-Loop"

 ;"${Index}-End:"
 ;!undef Index

SectionEnd

Section /o $Name_Section04 SEC04
  SectionIn 3
  SetOutPath "$INSTDIR"
  !insertmacro OpenUninstallLog
  !insertmacro InstallFile activex\axvlc.dll
  !insertmacro CloseUninstallLog
  RegDLL "$INSTDIR\axvlc.dll"
SectionEnd

SectionGroup /e !$Name_Section06 SEC05
  SectionGroup $Name_SectionGroupAudio
    !insertmacro MacroAudioExtensions RegisterExtensionSection
  SectionGroupEnd
  SectionGroup $Name_SectionGroupVideo
    !insertmacro MacroVideoExtensions RegisterExtensionSection
  SectionGroupEnd
  SectionGroup $Name_SectionGroupOther
    !insertmacro MacroOtherExtensions RegisterExtensionSection
  SectionGroupEnd
SectionGroupEnd


Section $Name_Section05 SEC06
  SectionIn 1 2 3
  WriteRegStr HKCR "AudioCD\shell\PlayWithVLC" "" $ContextMenuEntry_PlayWith
  WriteRegStr HKCR "AudioCD\shell\PlayWithVLC\command" "" \
    "$INSTDIR\vlc.exe --started-from-file cdda://%1"
  WriteRegStr HKCR "DVD\shell\PlayWithVLC" "" $ContextMenuEntry_PlayWith
  WriteRegStr HKCR "DVD\shell\PlayWithVLC\command" "" \
    "$INSTDIR\vlc.exe --started-from-file dvd://%1"

  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Explorer\AutoplayHandlers\EventHandlers\PlayDVDMovieOnArrival" "VLCPlayDVDMovieOnArrival" ""
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Explorer\AutoplayHandlers\Handlers\VLCPlayDVDMovieOnArrival" "Action" $Action_OnArrivalDVD
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Explorer\AutoplayHandlers\Handlers\VLCPlayDVDMovieOnArrival" "DefaultIcon" '"$INSTDIR\vlc.exe",0'
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Explorer\AutoplayHandlers\Handlers\VLCPlayDVDMovieOnArrival" "InvokeProgID" "VLC.DVDMovie"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Explorer\AutoplayHandlers\Handlers\VLCPlayDVDMovieOnArrival" "InvokeVerb" "play"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Explorer\AutoplayHandlers\Handlers\VLCPlayDVDMovieOnArrival" "Provider" "VideoLAN VLC media player"

  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Explorer\AutoplayHandlers\EventHandlers\PlayCDAudioOnArrival" "VLCPlayCDAudioOnArrival" ""
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Explorer\AutoplayHandlers\Handlers\VLCPlayCDAudioOnArrival" "Action" $Action_OnArrivalAudioCD
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Explorer\AutoplayHandlers\Handlers\VLCPlayCDAudioOnArrival" "DefaultIcon" '"$INSTDIR\vlc.exe",0'
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Explorer\AutoplayHandlers\Handlers\VLCPlayCDAudioOnArrival" "InvokeProgID" "VLC.CDAudio"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Explorer\AutoplayHandlers\Handlers\VLCPlayCDAudioOnArrival" "InvokeVerb" "play"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Explorer\AutoplayHandlers\Handlers\VLCPlayCDAudioOnArrival" "Provider" "VideoLAN VLC media player"
  WriteRegStr HKCR "VLC.DVDMovie" "" "VLC DVD Movie"
  WriteRegStr HKCR "VLC.DVDMovie\shell" "" "Play"
  WriteRegStr HKCR "VLC.DVDMovie\shell\Play\command" "" \
    '$INSTDIR\vlc.exe --started-from-file dvd://%1'
  WriteRegStr HKCR "VLC.DVDMovie\DefaultIcon" "" '"$INSTDIR\vlc.exe",0'
  WriteRegStr HKCR "VLC.CDAudio" "" "VLC CD Audio"
  WriteRegStr HKCR "VLC.CDAudio\shell" "" "Play"
  WriteRegStr HKCR "VLC.CDAudio\shell\Play\command" "" \
    '$INSTDIR\vlc.exe --started-from-file cdda://%1'
  WriteRegStr HKCR "VLC.CDAudio\DefaultIcon" "" '"$INSTDIR\vlc.exe",0'

SectionEnd

Section $Name_Section07 SEC07
  SectionIn 1 3
  !insertmacro MacroAllExtensions AddContextMenu
  !insertmacro AddContextMenuExt "Directory"
SectionEnd

Section $Name_Section08 SEC08
  !insertmacro delprefs
SectionEnd

; Installer section descriptions
!insertmacro MUI_FUNCTION_DESCRIPTION_BEGIN
  !insertmacro MUI_DESCRIPTION_TEXT ${SEC01} $Desc_Section01
  !insertmacro MUI_DESCRIPTION_TEXT ${SEC02a} $Desc_Section02a
  !insertmacro MUI_DESCRIPTION_TEXT ${SEC02b} $Desc_Section02b
  !insertmacro MUI_DESCRIPTION_TEXT ${SEC03} $Desc_Section03
  !insertmacro MUI_DESCRIPTION_TEXT ${SEC04} $Desc_Section04
  !insertmacro MUI_DESCRIPTION_TEXT ${SEC05} $Desc_Section06
  !insertmacro MUI_DESCRIPTION_TEXT ${SEC06} $Desc_Section05
  !insertmacro MUI_DESCRIPTION_TEXT ${SEC07} $Desc_Section07
  !insertmacro MUI_DESCRIPTION_TEXT ${SEC08} $Desc_Section08
!insertmacro MUI_FUNCTION_DESCRIPTION_END

;;; Start function
Function .onInit
  !insertmacro MUI_LANGDLL_DISPLAY

  !include "languages\english.nsh"
  StrCmp $LANGUAGE ${LANG_FRENCH} French 0
  StrCmp $LANGUAGE ${LANG_ITALIAN} Italian 0
  StrCmp $LANGUAGE ${LANG_HUNGARIAN} Hungarian 0
  StrCmp $LANGUAGE ${LANG_ROMANIAN} Romanian 0
  StrCmp $LANGUAGE ${LANG_CATALAN} Catalan 0
  StrCmp $LANGUAGE ${LANG_BULGARIAN} Bulgarian 0
  StrCmp $LANGUAGE ${LANG_SLOVAK} Slovak 0
  StrCmp $LANGUAGE ${LANG_POLISH} Polish 0
  StrCmp $LANGUAGE ${LANG_DUTCH} Dutch 0
  StrCmp $LANGUAGE ${LANG_SIMPCHINESE} SChinese 0
  StrCmp $LANGUAGE ${LANG_FINNISH} Finnish EndLanguageCmp
  French:
  !include "languages\french.nsh"
  Goto EndLanguageCmp
  Italian:
  !include "languages\italian.nsh"
  Goto EndLanguageCmp
  Hungarian:
  !include "languages\hungarian.nsh"
  Goto EndLanguageCmp
  Romanian:
  !include "languages\romanian.nsh"
  Goto EndLanguageCmp
  Catalan:
  !include "languages\catalan.nsh"
  Goto EndLanguageCmp
  Bulgarian:
  !include "languages\bulgarian.nsh"
  Goto EndLanguageCmp
  Slovak:
  !include "languages\slovak.nsh"
  Goto EndLanguageCmp
  Polish:
  !include "languages\polish.nsh"
  Goto EndLanguageCmp
  Dutch:
  !include "languages\dutch.nsh"
  Goto EndLanguageCmp
  Schinese:
  !include "languages\schinese.nsh"
  Goto EndLanguageCmp
  Finnish:
  !include "languages\finnish.nsh"
  EndLanguageCmp:

  ReadRegStr $R0  ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}" \
  "UninstallString"
  StrCmp $R0 "" done

  MessageBox MB_YESNO|MB_ICONEXCLAMATION $Message_AlreadyInstalled IDNO done

  ;Run the uninstaller
  ;uninst:
    ClearErrors
    ExecWait '$R0 _?=$INSTDIR' ;Do not copy the uninstaller to a temp file
  done:

FunctionEnd

;; End function
Section -Post
  WriteUninstaller "$INSTDIR\uninstall.exe"
  WriteRegStr HKLM "${PRODUCT_DIR_REGKEY}" "InstallDir" $INSTDIR
  WriteRegStr HKLM "${PRODUCT_DIR_REGKEY}" "Version" "${VERSION}"
  WriteRegStr HKLM "${PRODUCT_DIR_REGKEY}" "" "$INSTDIR\vlc.exe"

  WriteRegStr ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}" \
    "DisplayName" "$(^Name)"
  WriteRegStr ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}" \
    "UninstallString" "$INSTDIR\uninstall.exe"
  WriteRegStr ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}" \
    "DisplayIcon" "$INSTDIR\vlc.exe"
  WriteRegStr ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}" \
    "DisplayVersion" "${PRODUCT_VERSION}"
  WriteRegStr ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}" \
    "URLInfoAbout" "${PRODUCT_WEB_SITE}"
  WriteRegStr ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}" \
    "Publisher" "${PRODUCT_PUBLISHER}"
SectionEnd

;;;;;;;;;;;;;;;;;;;;;;;;
; Uninstaller sections ;
;;;;;;;;;;;;;;;;;;;;;;;;

; TrimNewlines (copied from NSIS documentation)
; input, top of stack  (e.g. whatever$\r$\n)
; output, top of stack (replaces, with e.g. whatever)
; modifies no other variables.

Function un.TrimNewlines
 Exch $R0
 Push $R1
 Push $R2
 StrCpy $R1 0

 loop:
   IntOp $R1 $R1 - 1
   StrCpy $R2 $R0 1 $R1
   StrCmp $R2 "$\r" loop
   StrCmp $R2 "$\n" loop
   IntOp $R1 $R1 + 1
   IntCmp $R1 0 no_trim_needed
   StrCpy $R0 $R0 $R1

 no_trim_needed:
   Pop $R2
   Pop $R1
   Exch $R0
FunctionEnd

Function un.RemoveEmptyDirs
  Pop $9
  !define Index 'Line${__LINE__}'
  FindFirst $0 $1 "$INSTDIR$9*"
  StrCmp $0 "" "${Index}-End"
  "${Index}-Loop:"
    StrCmp $1 "" "${Index}-End"
    StrCmp $1 "." "${Index}-Next"
    StrCmp $1 ".." "${Index}-Next"
      Push $0
      Push $1
      Push $9
      Push "$9$1\"
      Call un.RemoveEmptyDirs
      Pop $9
      Pop $1
      Pop $0
    "${Index}-Remove:"
    RMDir "$INSTDIR$9$1"
    "${Index}-Next:"
    FindNext $0 $1
    Goto "${Index}-Loop"
  "${Index}-End:"
  FindClose $0
  !undef Index
FunctionEnd

Section "un.$Name_Section91" SEC91
  SectionIn 1 2 3 RO
  SetShellVarContext all

  !insertmacro MacroAllExtensions DeleteContextMenu
  !insertmacro MacroAllExtensions UnRegisterExtensionSection
  !insertmacro DeleteContextMenuExt "Directory"

  ;remove activex plugin
  UnRegDLL "$INSTDIR\axvlc.dll"
  Delete /REBOOTOK "$INSTDIR\axvlc.dll"

  ;remove mozilla plugin
  Push $R0
  Push $R1
  Push $R2

  !define Index 'Line${__LINE__}'
  StrCpy $R1 "0"

  "${Index}-Loop:"

    ; Check for Key
    EnumRegKey $R0 HKLM "SOFTWARE\Mozilla" "$R1"
    StrCmp $R0 "" "${Index}-End"
    IntOp $R1 $R1 + 1
    ReadRegStr $R2 HKLM "SOFTWARE\Mozilla\$R0\Extensions" "Plugins"
    StrCmp $R2 "" "${Index}-Loop" ""

    ; old files (0.8.5 and before) that may be lying around
    Delete /REBOOTOK "$R2\npvlc.dll"
    Delete /REBOOTOK "$R2\libvlc.dll"
    Delete /REBOOTOK "$R2\vlcintf.xpt"
    Goto "${Index}-Loop"

  "${Index}-End:"
  !undef Index
  Delete /REBOOTOK "$INSTDIR\npvlc.dll"

  RMDir "$SMPROGRAMS\VideoLAN"
  RMDir /r $SMPROGRAMS\VideoLAN

  FileOpen $UninstallLog "$INSTDIR\uninstall.log" r
  UninstallLoop:
    ClearErrors
    FileRead $UninstallLog $R0
    IfErrors UninstallEnd
    Push $R0
    Call un.TrimNewLines
    Pop $R0
    Delete "$INSTDIR\$R0"
    Goto UninstallLoop
  UninstallEnd:
  FileClose $UninstallLog
  Delete "$INSTDIR\uninstall.log"
  Delete "$INSTDIR\uninstall.exe"
  Push "\"
  Call un.RemoveEmptyDirs
  RMDir "$INSTDIR"

  DeleteRegKey HKLM Software\VideoLAN

  DeleteRegKey HKCR Applications\vlc.exe
  DeleteRegKey HKCR AudioCD\shell\PlayWithVLC
  DeleteRegKey HKCR DVD\shell\PlayWithVLC
  DeleteRegValue HKLM "Software\Microsoft\Windows\CurrentVersion\Explorer\AutoplayHandlers\EventHandlers\PlayDVDMovieOnArrival" "VLCPlayDVDMovieOnArrival"
  DeleteRegKey HKLM Software\Microsoft\Windows\CurrentVersion\Explorer\AutoplayHandlers\Handlers\VLCPlayDVDMovieOnArrival
  DeleteRegValue HKLM "Software\Microsoft\Windows\CurrentVersion\Explorer\AutoplayHandlers\EventHandlers\PlayCDAudioOnArrival" "VLCPlayCDAudioOnArrival"
  DeleteRegKey HKLM Software\Microsoft\Windows\CurrentVersion\Explorer\AutoplayHandlers\Handlers\VLCPlayCDAudioOnArrival
  DeleteRegKey HKLM Software\Clients\Media\VLC
  DeleteRegKey HKCR "VLC.MediaFile"

  DeleteRegKey HKLM \
    "SOFTWARE\MozillaPlugins\@videolan.org/vlc,version=${VERSION}"

  DeleteRegKey HKLM \
    "Software\Microsoft\Windows\CurrentVersion\Uninstall\${PRODUCT_NAME}"

  Delete "$DESKTOP\VLC media player.lnk"

  DeleteRegKey ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}"
  DeleteRegKey HKLM "${PRODUCT_DIR_REGKEY}"
  SetAutoClose true
SectionEnd

Section /o "un.$Name_Section92" SEC92
  !insertmacro delprefs
SectionEnd

; Uninstaller section descriptions
!insertmacro MUI_UNFUNCTION_DESCRIPTION_BEGIN
  !insertmacro MUI_DESCRIPTION_TEXT ${SEC91} $Desc_Section91
  !insertmacro MUI_DESCRIPTION_TEXT ${SEC92} $Desc_Section92
!insertmacro MUI_UNFUNCTION_DESCRIPTION_END

;Function un.onUninstSuccess
;  HideWindow
;  MessageBox MB_ICONINFORMATION|MB_OK \
;    "$(^Name) was successfully removed from your computer."
;FunctionEnd

Function un.onInit
  !insertmacro MUI_UNGETLANGUAGE
  
  !include "languages\english.nsh"
  StrCmp $LANGUAGE ${LANG_FRENCH} French 0
  StrCmp $LANGUAGE ${LANG_ITALIAN} Italian 0
  StrCmp $LANGUAGE ${LANG_HUNGARIAN} Hungarian 0
  StrCmp $LANGUAGE ${LANG_ROMANIAN} Romanian 0
  StrCmp $LANGUAGE ${LANG_CATALAN} Catalan 0
  StrCmp $LANGUAGE ${LANG_BULGARIAN} Bulgarian 0
  StrCmp $LANGUAGE ${LANG_SLOVAK} Slovak 0
  StrCmp $LANGUAGE ${LANG_POLISH} Polish 0
  StrCmp $LANGUAGE ${LANG_DUTCH} Dutch 0
  StrCmp $LANGUAGE ${LANG_SIMPCHINESE} SChinese 0
  StrCmp $LANGUAGE ${LANG_FINNISH} Finnish EndLanguageCmp
  French:
  !include "languages\french.nsh"
  Goto EndLanguageCmp
  Italian:
  !include "languages\italian.nsh"
  Goto EndLanguageCmp
  Hungarian:
  !include "languages\hungarian.nsh"
  Goto EndLanguageCmp
  Romanian:
  !include "languages\romanian.nsh"
  Goto EndLanguageCmp
  Catalan:
  !include "languages\catalan.nsh"
  Goto EndLanguageCmp
  Bulgarian:
  !include "languages\bulgarian.nsh"
  Goto EndLanguageCmp
  Slovak:
  !include "languages\slovak.nsh"
  Goto EndLanguageCmp
  Polish:
  !include "languages\polish.nsh"
  Goto EndLanguageCmp
  Dutch:
  !include "languages\dutch.nsh"
  Goto EndLanguageCmp
  Schinese:
  !include "languages\schinese.nsh"
  Goto EndLanguageCmp
  Finnish:
  !include "languages\finnish.nsh"
  EndLanguageCmp:
  
FunctionEnd
