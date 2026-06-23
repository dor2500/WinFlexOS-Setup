# menu.ps1 - WinFlexOS Setup Menu Configuration

$browsers = @(
    @{Name="Google Chrome"; WingetId="Google.Chrome"; R=$true},
    @{Name="Mozilla Firefox"; WingetId="Mozilla.Firefox"},
    @{Name="Zen Browser"; WingetId="Zen-Team.Zen-Browser"},
    @{Name="Brave Browser"; WingetId="BraveSoftware.BraveBrowser"},
    @{Name="Arc Browser"; WingetId="TheBrowserCompany.Arc"},
    @{Name="Opera GX"; WingetId="Opera.OperaGX"},
    @{Name="Vivaldi"; WingetId="VivaldiTechnologies.Vivaldi"},
    @{Name="Tor Browser"; WingetId="TorProject.TorBrowser"}
)
$communicationApps = @(
    @{Name="Discord"; WingetId="Discord.Discord"; R=$true},
    @{Name="Telegram Desktop"; WingetId="Telegram.TelegramDesktop"},
    @{Name="WhatsApp"; WingetId="WhatsApp.WhatsApp"; R=$true},
    @{Name="Zoom"; WingetId="Zoom.Zoom"},
    @{Name="Microsoft Teams"; WingetId="Microsoft.Teams"},
    @{Name="Signal"; WingetId="OpenWhisperSystems.Signal"},
    @{Name="Slack"; WingetId="SlackTechnologies.Slack"}
)
$multimediaApps = @(
    @{Name="VLC Media Player"; WingetId="VideoLAN.VLC"; R=$true},
    @{Name="Spotify"; WingetId="Spotify.Spotify"},
    @{Name="OBS Studio"; WingetId="OBSProject.OBSStudio"},
    @{Name="CapCut"; WingetId="Bytedance.CapCut"},
    @{Name="HandBrake"; WingetId="HandBrake.HandBrake"},
    @{Name="DaVinci Resolve"; WingetId="BlackmagicDesign.DaVinciResolve"},
    @{Name="Audacity"; WingetId="Audacity.Audacity"},
    @{Name="GIMP"; WingetId="GIMP.GIMP"},
    @{Name="ShareX"; WingetId="ShareX.ShareX"; R=$true}
)
$gameLaunchers = @(
    @{Name="Steam"; WingetId="Valve.Steam"; R=$true},
    @{Name="Epic Games Launcher"; WingetId="EpicGames.EpicGamesLauncher"},
    @{Name="GOG Galaxy"; WingetId="GOG.Galaxy"},
    @{Name="EA App"; WingetId="ElectronicArts.EADesktop"},
    @{Name="Ubisoft Connect"; WingetId="Ubisoft.Connect"},
    @{Name="Playnite"; WingetId="Playnite.Playnite"}
)
$devTools = @(
    @{Name="Visual Studio Code"; WingetId="Microsoft.VisualStudioCode"},
    @{Name="Git"; WingetId="Git.Git"},
    @{Name="Windows Terminal"; WingetId="Microsoft.WindowsTerminal"},
    @{Name="Node.js LTS"; WingetId="OpenJS.NodeJS.LTS"},
    @{Name="Python 3"; WingetId="Python.Python.3.12"},
    @{Name="Docker Desktop"; WingetId="Docker.DockerDesktop"}
)
$utilityApps = @(
    @{Name="7-Zip"; WingetId="7zip.7zip"; R=$true},
    @{Name="WinRAR"; WingetId="RARLab.WinRAR"},
    @{Name="Notepad++"; WingetId="Notepad++.Notepad++"; R=$true},
    @{Name="PowerToys"; WingetId="Microsoft.PowerToys"},
    @{Name="Everything Search"; WingetId="voidtools.Everything"; R=$true},
    @{Name="TreeSize Free"; WingetId="JAMSoftware.TreeSize.Free"},
    @{Name="Bitwarden"; WingetId="Bitwarden.Bitwarden"},
    @{Name="qBittorrent"; WingetId="qBittorrent.qBittorrent"},
    @{Name="Rufus"; WingetId="Rufus.Rufus"}
)
$graphicsDrivers = @(
    @{Name="NVIDIA App"; WingetId="Nvidia.GeForceExperience"},
    @{Name="AMD Radeon Software"; Path="C:\MENU\All other files\EXE\amd-software-adrenalin-edition-24.8.1-minimalsetup-240926_web.exe"},
    @{Name="Intel Graphics Driver"; WingetId="Intel.GraphicsDriver"},
    @{Name="MSI Afterburner"; WingetId="Guru3D.Afterburner"}
)
$runtimeApps = @(
    @{Name=".NET Desktop Runtime 8"; WingetId="Microsoft.DotNet.DesktopRuntime.8"; R=$true},
    @{Name="VC++ Redistributable 2015-2022"; WingetId="Microsoft.VCRedist.2015+.x64"; R=$true},
    @{Name="Java Runtime (JRE)"; WingetId="Oracle.JavaRuntimeEnvironment"}
)
$securityApps = @(
    @{Name="Malwarebytes"; WingetId="Malwarebytes.Malwarebytes"},
    @{Name="HWiNFO"; WingetId="REALiX.HWiNFO"; R=$true},
    @{Name="CPU-Z"; WingetId="CPUID.CPU-Z"}
)

$script:Categories = @(
    @{ Key="browsers";   Icon=[char]0xE774; TitleHe=(-join([char]0x05D3,[char]0x05E4,[char]0x05D3,[char]0x05E4,[char]0x05E0,[char]0x05D9,[char]0x05DD));   TitleEn="Browsers";       Items=$browsers },
    @{ Key="chat";       Icon=[char]0xE8BD; TitleHe=(-join([char]0x05EA,[char]0x05E7,[char]0x05E9,[char]0x05D5,[char]0x05E8,[char]0x05EA));       TitleEn="Communication";  Items=$communicationApps },
    @{ Key="media";      Icon=[char]0xE8D6; TitleHe=(-join([char]0x05DE,[char]0x05D5,[char]0x05DC,[char]0x05D8,[char]0x05D9,[char]0x05DE,[char]0x05D3,[char]0x05D4)); TitleEn="Multimedia";     Items=$multimediaApps },
    @{ Key="launchers";  Icon=[char]0xE7FC; TitleHe=(-join([char]0x05DC,[char]0x05D0,[char]0x05E0,[char]0x05E6,[char]0x0027,[char]0x05E8,[char]0x05D9,[char]0x05DD));  TitleEn="Game Launchers"; Items=$gameLaunchers },
    @{ Key="dev";        Icon=[char]0xE943; TitleHe=(-join([char]0x05DB,[char]0x05DC,[char]0x05D9,[char]0x0020,[char]0x05E4,[char]0x05D9,[char]0x05EA,[char]0x05D5,[char]0x05D7));   TitleEn="Dev Tools";      Items=$devTools },
    @{ Key="utils";      Icon=[char]0xE74C; TitleHe=(-join([char]0x05DB,[char]0x05DC,[char]0x05D9,[char]0x05DD));      TitleEn="Utilities";      Items=$utilityApps },
    @{ Key="drivers";    Icon=[char]0xE7F8; TitleHe=(-join([char]0x05D3,[char]0x05E8,[char]0x05D9,[char]0x05D1,[char]0x05E8,[char]0x05D3,[char]0x05DD));    TitleEn="Drivers";        Items=$graphicsDrivers },
    @{ Key="runtime";    Icon=[char]0xE756; TitleHe=(-join([char]0x05E1,[char]0x05D1,[char]0x05D9,[char]0x05D1,[char]0x05D5,[char]0x05EA,[char]0x0020,[char]0x05E8,[char]0x05D9,[char]0x05E6,[char]0x05D4));    TitleEn="Runtimes";       Items=$runtimeApps },
    @{ Key="security";   Icon=[char]0xE72E; TitleHe=(-join([char]0x05D0,[char]0x05D1,[char]0x05D8,[char]0x05D7,[char]0x05D4));   TitleEn="Security";       Items=$securityApps },
    @{ Key="custom";     Icon=[char]0xE721; TitleHe=(-join([char]0x05EA,[char]0x05D5,[char]0x05DB,[char]0x05E0,[char]0x05D5,[char]0x05EA,[char]0x0020,[char]0x05E0,[char]0x05D5,[char]0x05E1,[char]0x05E4,[char]0x05D5,[char]0x05EA));   TitleEn="Custom Apps";    Items=@() }
)
