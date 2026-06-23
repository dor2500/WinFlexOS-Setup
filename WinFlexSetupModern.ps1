# WinFlexSetupModern.ps1 - V4.1 Design
#Requires -Version 5.1

param(
    [switch]$SkipWelcome,
    [string]$MenuPath
)

$script:isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
$scriptPath = $MyInvocation.MyCommand.Path
# If running via irm/iex, $scriptPath will be empty. We handle this gracefully.
if (-not $scriptPath) {
    $scriptDir = $env:TEMP
} else {
    $scriptDir = Split-Path -Parent $scriptPath
}

if (-not $script:isAdmin) {
    if ($scriptPath) {
        Write-Host "Elevating to Administrator..." -ForegroundColor Yellow
        Start-Process powershell.exe -Verb RunAs -ArgumentList @("-NoProfile", "-ExecutionPolicy", "Bypass", "-STA", "-File", "`"$scriptPath`"")
        exit
    } else {
        Write-Warning "Running in-memory (irm | iex). Please run PowerShell as Administrator first!"
        Write-Host "Example: Right-click PowerShell -> Run as Administrator, then paste your command." -ForegroundColor Cyan
        exit
    }
}

Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase, System.Windows.Forms
[System.Windows.Forms.Application]::EnableVisualStyles() | Out-Null

$backgroundImagePath = "C:\MENU\Discovery+of+The+Lost+Vista+1+-+4K.jpg"
$audioPath = "C:\MENU\winflex.wav"
$script:LogPath = Join-Path $env:TEMP "winflex-setup.log"
function He([int[]]$codes){$s="";foreach($c in $codes){$s+=[char]$c};$s}

function Write-Log([string]$Message) {
    $ts = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    try { Add-Content -Path $script:LogPath -Value "[$ts] $Message" -Encoding UTF8 } catch {}
}

$script:player = $null; $script:isMuted = $false
if (Test-Path -LiteralPath $audioPath) {
    try { $script:player = New-Object System.Media.SoundPlayer -ArgumentList $audioPath; $script:player.Load() } catch { $script:player = $null }
}
function Play-Sound { if ($script:player -and -not $script:isMuted) { try { $script:player.PlayLooping() } catch {} } }
function Toggle-Mute {
    if (-not $script:player) { return }
    if ($script:isMuted) { $script:isMuted = $false; try { $script:player.PlayLooping() } catch {} }
    else { $script:isMuted = $true; try { $script:player.Stop() } catch {} }
}

function Test-Winget { [bool](Get-Command winget -ErrorAction SilentlyContinue) }
function Install-Winget {
    if (Test-Winget) { return $true }
    $tmpDir = Join-Path $env:TEMP "winget-install"
    New-Item -ItemType Directory -Force -Path $tmpDir -ErrorAction SilentlyContinue | Out-Null
    $bundle = Join-Path $tmpDir "Microsoft.DesktopAppInstaller.msixbundle"
    try { (New-Object Net.WebClient).DownloadFile("https://aka.ms/getwinget", $bundle) } catch {}
    try { Add-AppxPackage -Path $bundle -ErrorAction SilentlyContinue | Out-Null } catch {}
    Start-Sleep -Seconds 2; return (Test-Winget)
}
function Invoke-WingetInstall([string]$Id, [bool]$IsExact=$true) {
    if ($IsExact) {
        $a = @("install","-e","--id",$Id,"--silent","--accept-package-agreements","--accept-source-agreements")
    } else {
        $a = @("install",$Id,"--silent","--accept-package-agreements","--accept-source-agreements")
    }
    $p = Start-Process -FilePath "winget" -ArgumentList $a -PassThru -Wait -NoNewWindow
    if ($p.ExitCode -ne 0) { throw "winget failed for $Id (ExitCode=$($p.ExitCode))" }
}

# # -------- Software Lists (Loaded Dynamically) --------
# The software lists ($browsers, etc.) and $script:Categories are loaded dynamically from GitHub during the Preflight check.

$script:Lang = "he"
function L([string]$he, [string]$en) { if ($script:Lang -eq "he") { $he } else { $en } }

$script:Themes = @(
    @{ Name="Neon Cyan";    Bg="#0F0F0F"; Sidebar="#141414"; Card="#1E1E1E"; Card2="#181818"; Fg="#FFFFFF"; Sub="#B0B0B0"; Accent="#00BFFF"; Border="#2A2A2A" },
    @{ Name="Material You"; Bg="#0F0F10"; Sidebar="#14151A"; Card="#1C1F27"; Card2="#161A22"; Fg="#EEF2F8"; Sub="#A5AFBE"; Accent="#4C8BF5"; Border="#2A3240" },
    @{ Name="Tokyo Night";  Bg="#1A1B26"; Sidebar="#16161E"; Card="#24283B"; Card2="#1F2335"; Fg="#C0CAF5"; Sub="#787C99"; Accent="#7AA2F7"; Border="#2A3240" },
    @{ Name="Pitch Black";  Bg="#000000"; Sidebar="#0A0A0A"; Card="#121212"; Card2="#0F0F0F"; Fg="#FAFAFA"; Sub="#A1A1AA"; Accent="#00BFFF"; Border="#27272A" }
)
$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="WinFlexOS Setup" WindowStyle="None" ResizeMode="CanResize" WindowState="Maximized"
        AllowsTransparency="True" Background="Transparent" FontFamily="Bahnschrift, Segoe UI, sans-serif" FontSize="14">
  <Window.Resources>
    <SolidColorBrush x:Key="ThemeBg" Color="#0F0F0F"/><SolidColorBrush x:Key="ThemeSidebar" Color="#141414"/>
    <SolidColorBrush x:Key="ThemeCard" Color="#1E1E1E"/><SolidColorBrush x:Key="ThemeCard2" Color="#181818"/>
    <SolidColorBrush x:Key="ThemeFg" Color="#FFFFFF"/><SolidColorBrush x:Key="ThemeSub" Color="#B0B0B0"/>
    <SolidColorBrush x:Key="ThemeBorder" Color="#2A2A2A"/><SolidColorBrush x:Key="ThemeAccent" Color="#00BFFF"/>
    <CornerRadius x:Key="Rxl">22</CornerRadius><CornerRadius x:Key="Rl">18</CornerRadius>
    <CornerRadius x:Key="Rm">14</CornerRadius><CornerRadius x:Key="Rs">10</CornerRadius>
    <DropShadowEffect x:Key="CardShadow" BlurRadius="20" ShadowDepth="5" Direction="270" Color="Black" Opacity="0.2"/>
    <DropShadowEffect x:Key="SoftGlow" BlurRadius="15" ShadowDepth="0" Color="#00BFFF" Opacity="0.4"/>
    <Style TargetType="ScrollBar"><Setter Property="Background" Value="Transparent"/><Setter Property="Width" Value="8"/>
      <Setter Property="Template"><Setter.Value><ControlTemplate TargetType="ScrollBar">
        <Grid x:Name="G" Width="8" Background="Transparent"><Track x:Name="PART_Track" IsDirectionReversed="true"><Track.Thumb><Thumb><Thumb.Template><ControlTemplate TargetType="Thumb">
          <Border x:Name="T" Background="#55888888" CornerRadius="4"/>
          <ControlTemplate.Triggers><Trigger Property="IsMouseOver" Value="True"><Setter TargetName="T" Property="Background" Value="{DynamicResource ThemeAccent}"/></Trigger>
          <Trigger Property="IsDragging" Value="True"><Setter TargetName="T" Property="Background" Value="{DynamicResource ThemeFg}"/></Trigger></ControlTemplate.Triggers>
        </ControlTemplate></Thumb.Template></Thumb></Track.Thumb></Track></Grid>
        <ControlTemplate.Triggers><Trigger Property="IsMouseOver" Value="True"><Setter TargetName="G" Property="Width" Value="12"/></Trigger></ControlTemplate.Triggers>
      </ControlTemplate></Setter.Value></Setter></Style>
    <Style TargetType="ComboBox"><Setter Property="Foreground" Value="{DynamicResource ThemeFg}"/><Setter Property="Background" Value="{DynamicResource ThemeCard}"/>
      <Setter Property="BorderBrush" Value="{DynamicResource ThemeBorder}"/><Setter Property="BorderThickness" Value="1"/><Setter Property="Height" Value="32"/><Setter Property="FontSize" Value="14"/>
      <Setter Property="Template"><Setter.Value><ControlTemplate TargetType="ComboBox"><Grid>
        <ToggleButton Name="ToggleButton" Focusable="false" IsChecked="{Binding Path=IsDropDownOpen,Mode=TwoWay,RelativeSource={RelativeSource TemplatedParent}}" ClickMode="Press">
          <ToggleButton.Template><ControlTemplate TargetType="ToggleButton"><Border Background="{DynamicResource ThemeCard}" BorderBrush="{DynamicResource ThemeBorder}" BorderThickness="1" CornerRadius="6">
            <Grid><Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="20"/></Grid.ColumnDefinitions>
            <Path Grid.Column="1" HorizontalAlignment="Center" VerticalAlignment="Center" Fill="{DynamicResource ThemeSub}" Data="M 0 0 L 4 4 L 8 0 Z"/></Grid>
          </Border></ControlTemplate></ToggleButton.Template></ToggleButton>
        <ContentPresenter Name="ContentSite" IsHitTestVisible="False" Content="{TemplateBinding SelectionBoxItem}" Margin="10,0,23,0" VerticalAlignment="Center" HorizontalAlignment="Left"/>
        <Popup Name="Popup" Placement="Bottom" IsOpen="{TemplateBinding IsDropDownOpen}" AllowsTransparency="True" Focusable="False" PopupAnimation="Slide">
          <Grid MinWidth="{TemplateBinding ActualWidth}" MaxHeight="{TemplateBinding MaxDropDownHeight}"><Border Background="{DynamicResource ThemeCard}" BorderBrush="{DynamicResource ThemeBorder}" BorderThickness="1" CornerRadius="6"/>
            <ScrollViewer Margin="4,6" SnapsToDevicePixels="True"><StackPanel IsItemsHost="True"/></ScrollViewer></Grid></Popup>
      </Grid></ControlTemplate></Setter.Value></Setter></Style>
    <Style TargetType="ComboBoxItem"><Setter Property="Foreground" Value="{DynamicResource ThemeFg}"/><Setter Property="Background" Value="{DynamicResource ThemeCard}"/>
      <Setter Property="Template"><Setter.Value><ControlTemplate TargetType="ComboBoxItem">
        <Border x:Name="Bd" Background="{TemplateBinding Background}" Padding="5" CornerRadius="4"><ContentPresenter/></Border>
        <ControlTemplate.Triggers><Trigger Property="IsMouseOver" Value="True"><Setter TargetName="Bd" Property="Background" Value="{DynamicResource ThemeAccent}"/><Setter Property="Foreground" Value="White"/></Trigger>
          <Trigger Property="IsSelected" Value="True"><Setter TargetName="Bd" Property="Background" Value="{DynamicResource ThemeBorder}"/></Trigger>
        </ControlTemplate.Triggers></ControlTemplate></Setter.Value></Setter></Style>
    <Style x:Key="WinCtrlBtn" TargetType="Button"><Setter Property="Width" Value="45"/><Setter Property="Height" Value="35"/><Setter Property="Background" Value="Transparent"/>
      <Setter Property="Foreground" Value="#AAAAAA"/><Setter Property="FontFamily" Value="Segoe MDL2 Assets"/><Setter Property="FontSize" Value="12"/><Setter Property="BorderThickness" Value="0"/><Setter Property="Cursor" Value="Hand"/>
      <Setter Property="Template"><Setter.Value><ControlTemplate TargetType="Button"><Border x:Name="Bd" Background="{TemplateBinding Background}" CornerRadius="6"><ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/></Border>
        <ControlTemplate.Triggers><Trigger Property="IsMouseOver" Value="True"><Setter TargetName="Bd" Property="Background" Value="#22888888"/><Setter Property="Foreground" Value="{DynamicResource ThemeFg}"/></Trigger>
        <Trigger Property="IsEnabled" Value="False"><Setter Property="Opacity" Value="0.55"/></Trigger></ControlTemplate.Triggers></ControlTemplate></Setter.Value></Setter></Style>
    <Style x:Key="CloseBtn" TargetType="Button"><Setter Property="Width" Value="45"/><Setter Property="Height" Value="35"/><Setter Property="Background" Value="Transparent"/>
      <Setter Property="Foreground" Value="#AAAAAA"/><Setter Property="FontFamily" Value="Segoe MDL2 Assets"/><Setter Property="FontSize" Value="12"/><Setter Property="BorderThickness" Value="0"/><Setter Property="Cursor" Value="Hand"/>
      <Setter Property="Template"><Setter.Value><ControlTemplate TargetType="Button"><Border x:Name="Bd" Background="{TemplateBinding Background}" CornerRadius="0,12,0,0"><ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/></Border>
        <ControlTemplate.Triggers><Trigger Property="IsMouseOver" Value="True"><Setter TargetName="Bd" Property="Background" Value="#E81123"/><Setter Property="Foreground" Value="White"/></Trigger></ControlTemplate.Triggers></ControlTemplate></Setter.Value></Setter></Style>
    <Style x:Key="PrimaryBtn" TargetType="Button"><Setter Property="Background" Value="{DynamicResource ThemeCard}"/><Setter Property="Foreground" Value="{DynamicResource ThemeFg}"/>
      <Setter Property="BorderBrush" Value="{DynamicResource ThemeAccent}"/><Setter Property="BorderThickness" Value="1"/><Setter Property="Cursor" Value="Hand"/>
      <Setter Property="Template"><Setter.Value><ControlTemplate TargetType="Button">
        <Border x:Name="Bd" Background="{TemplateBinding Background}" BorderBrush="{TemplateBinding BorderBrush}" BorderThickness="{TemplateBinding BorderThickness}" CornerRadius="{StaticResource Rs}" RenderTransformOrigin="0.5,0.5">
          <Border.RenderTransform><ScaleTransform x:Name="PS" ScaleX="1" ScaleY="1"/></Border.RenderTransform>
          <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/></Border>
        <ControlTemplate.Triggers>
          <EventTrigger RoutedEvent="MouseEnter"><BeginStoryboard><Storyboard><DoubleAnimation Storyboard.TargetName="PS" Storyboard.TargetProperty="ScaleX" To="1.06" Duration="0:0:0.15"/><DoubleAnimation Storyboard.TargetName="PS" Storyboard.TargetProperty="ScaleY" To="1.06" Duration="0:0:0.15"/></Storyboard></BeginStoryboard></EventTrigger>
          <EventTrigger RoutedEvent="MouseLeave"><BeginStoryboard><Storyboard><DoubleAnimation Storyboard.TargetName="PS" Storyboard.TargetProperty="ScaleX" To="1" Duration="0:0:0.2"/><DoubleAnimation Storyboard.TargetName="PS" Storyboard.TargetProperty="ScaleY" To="1" Duration="0:0:0.2"/></Storyboard></BeginStoryboard></EventTrigger>
          <Trigger Property="IsMouseOver" Value="True"><Setter TargetName="Bd" Property="Background" Value="{DynamicResource ThemeAccent}"/><Setter TargetName="Bd" Property="BorderBrush" Value="Transparent"/><Setter Property="Foreground" Value="White"/></Trigger>
          <Trigger Property="IsEnabled" Value="False"><Setter Property="Opacity" Value="0.55"/></Trigger>
        </ControlTemplate.Triggers></ControlTemplate></Setter.Value></Setter></Style>
    <Style x:Key="SidebarBtn" TargetType="Button"><Setter Property="Background" Value="Transparent"/><Setter Property="Foreground" Value="{DynamicResource ThemeSub}"/>
      <Setter Property="Height" Value="50"/><Setter Property="FontSize" Value="15"/><Setter Property="Margin" Value="8,3"/><Setter Property="Cursor" Value="Hand"/><Setter Property="HorizontalContentAlignment" Value="Left"/>
      <Setter Property="Template"><Setter.Value><ControlTemplate TargetType="Button">
        <Border x:Name="Bd" Background="{TemplateBinding Background}" CornerRadius="8" RenderTransformOrigin="0.5,0.5">
          <Border.RenderTransform><ScaleTransform x:Name="SS" ScaleX="1" ScaleY="1"/></Border.RenderTransform>
          <Grid><Grid.ColumnDefinitions><ColumnDefinition Width="4"/><ColumnDefinition Width="40"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
            <Border x:Name="Ind" Grid.Column="0" Width="3" Height="25" Background="Transparent" CornerRadius="1.5"/>
            <TextBlock x:Name="Ic" Grid.Column="1" FontFamily="Segoe MDL2 Assets" FontSize="18" Text="{TemplateBinding Tag}" Foreground="{TemplateBinding Foreground}" VerticalAlignment="Center" HorizontalAlignment="Center"/>
            <ContentPresenter Grid.Column="2" VerticalAlignment="Center"/></Grid></Border>
        <ControlTemplate.Triggers>
          <EventTrigger RoutedEvent="MouseEnter"><BeginStoryboard><Storyboard>
            <DoubleAnimation Storyboard.TargetName="SS" Storyboard.TargetProperty="ScaleX" To="1.05" Duration="0:0:0.2"/>
            <DoubleAnimation Storyboard.TargetName="SS" Storyboard.TargetProperty="ScaleY" To="1.05" Duration="0:0:0.2"/>
            <ColorAnimation Storyboard.TargetName="Bd" Storyboard.TargetProperty="(Border.Background).(SolidColorBrush.Color)" To="#15888888" Duration="0:0:0.2"/>
          </Storyboard></BeginStoryboard></EventTrigger>
          <EventTrigger RoutedEvent="MouseLeave"><BeginStoryboard><Storyboard>
            <DoubleAnimation Storyboard.TargetName="SS" Storyboard.TargetProperty="ScaleX" To="1" Duration="0:0:0.2"/>
            <DoubleAnimation Storyboard.TargetName="SS" Storyboard.TargetProperty="ScaleY" To="1" Duration="0:0:0.2"/>
            <ColorAnimation Storyboard.TargetName="Bd" Storyboard.TargetProperty="(Border.Background).(SolidColorBrush.Color)" To="Transparent" Duration="0:0:0.3"/>
          </Storyboard></BeginStoryboard></EventTrigger>
        </ControlTemplate.Triggers></ControlTemplate></Setter.Value></Setter></Style>
  </Window.Resources>
  <Grid>
    <Grid><Image x:Name="BgImage" Stretch="UniformToFill" Opacity="0.92"/><Rectangle Fill="#AA0B0D12"/>
      <Rectangle><Rectangle.Fill><LinearGradientBrush StartPoint="0,0" EndPoint="1,1"><GradientStop Color="#55000000" Offset="0"/><GradientStop Color="#AA000000" Offset="1"/></LinearGradientBrush></Rectangle.Fill></Rectangle></Grid>
    <Border x:Name="MainBorder" Background="{DynamicResource ThemeBg}" CornerRadius="{StaticResource Rxl}" BorderBrush="{DynamicResource ThemeBorder}" BorderThickness="1" Margin="18" Effect="{StaticResource CardShadow}">
      <Grid><Grid.ColumnDefinitions><ColumnDefinition Width="260"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
        <Border Grid.Column="0" Background="{DynamicResource ThemeSidebar}" CornerRadius="12,0,0,12">
          <Grid><Grid.RowDefinitions><RowDefinition Height="Auto"/><RowDefinition Height="*"/><RowDefinition Height="Auto"/></Grid.RowDefinitions>
            <StackPanel Grid.Row="0" Margin="0,35,0,30" HorizontalAlignment="Center">
              <Border Width="50" Height="50" CornerRadius="15" Background="{DynamicResource ThemeAccent}" HorizontalAlignment="Center" Margin="0,0,0,10" Effect="{StaticResource SoftGlow}">
                <TextBlock Text="&#xE7F4;" FontFamily="Segoe MDL2 Assets" FontSize="24" Foreground="White" HorizontalAlignment="Center" VerticalAlignment="Center"/></Border>
              <TextBlock Text="WinFlexOS" FontSize="22" FontWeight="Bold" Foreground="{DynamicResource ThemeFg}" HorizontalAlignment="Center"/>
              <TextBlock x:Name="SideSub" Text="Setup wizard" Foreground="{DynamicResource ThemeSub}" FontSize="10" HorizontalAlignment="Center"/></StackPanel>
            <ScrollViewer Grid.Row="1" VerticalScrollBarVisibility="Auto" Margin="10,0"><StackPanel x:Name="SideMenu"/></ScrollViewer>
            <StackPanel Grid.Row="2" Margin="15,10"><TextBlock x:Name="SideFooter" Visibility="Collapsed"/></StackPanel></Grid></Border>
        <Grid x:Name="MainArea" Grid.Column="1" Margin="18,14" IsEnabled="False" Opacity="0.6">
          <Grid.RowDefinitions><RowDefinition Height="60"/><RowDefinition Height="*"/><RowDefinition Height="64"/></Grid.RowDefinitions>
          <Grid Grid.Row="0"><Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions>
            <StackPanel Orientation="Vertical" VerticalAlignment="Center">
              <TextBlock x:Name="TopTitle" Text="Good Evening" Foreground="{DynamicResource ThemeFg}" FontSize="26" FontWeight="SemiBold"/>
              <TextBlock x:Name="TopSub" Text="Choose apps" Foreground="{DynamicResource ThemeSub}" FontSize="13"/></StackPanel>
            <StackPanel Grid.Column="1" Orientation="Horizontal" VerticalAlignment="Center">
              <TextBlock Text="Theme:" VerticalAlignment="Center" Margin="0,0,8,0" Foreground="{DynamicResource ThemeSub}" FontSize="14"/>
              <ComboBox x:Name="CmbTheme" Width="160" Height="32" Margin="0,0,12,0"/>
              <Button x:Name="BtnLang" Content="EN" Margin="0,0,8,0" Width="50" Height="34" FontSize="14" Foreground="{DynamicResource ThemeSub}" Background="Transparent" BorderThickness="0" Cursor="Hand"/>
              <Button x:Name="BtnMute" Content="Mute" Margin="0,0,8,0" Height="34" FontSize="14" Foreground="{DynamicResource ThemeSub}" Background="Transparent" BorderThickness="0" Cursor="Hand"/>
              <Button x:Name="BtnMin" Content="&#xE921;" Style="{StaticResource WinCtrlBtn}"/>
              <Button x:Name="BtnMax" Content="&#xE922;" Style="{StaticResource WinCtrlBtn}"/>
              <Button x:Name="BtnClose" Content="&#xE8BB;" Style="{StaticResource CloseBtn}"/></StackPanel></Grid>
          <Border Grid.Row="1" Background="{DynamicResource ThemeCard}" BorderBrush="{DynamicResource ThemeBorder}" BorderThickness="1" CornerRadius="{StaticResource Rl}" Padding="18" Effect="{StaticResource CardShadow}">
            <Grid><Grid.RowDefinitions><RowDefinition Height="Auto"/><RowDefinition Height="*"/></Grid.RowDefinitions>
              <DockPanel><StackPanel><TextBlock x:Name="PageTitle" Text="Welcome" Foreground="{DynamicResource ThemeFg}" FontSize="18" FontWeight="SemiBold"/>
                <TextBlock x:Name="PageDesc" Text="Select" Foreground="{DynamicResource ThemeSub}" Margin="0,6,0,0" TextWrapping="Wrap"/></StackPanel>
                <StackPanel DockPanel.Dock="Right" Orientation="Horizontal" VerticalAlignment="Top">
                  <Button x:Name="BtnSelectAll" Content="Select All" Padding="14,6" Margin="0,0,8,0" FontSize="12" Background="Transparent" Foreground="{DynamicResource ThemeAccent}" BorderBrush="{DynamicResource ThemeAccent}" BorderThickness="1" Cursor="Hand"/>
                  <Button x:Name="BtnDeselectAll" Content="Deselect" Padding="14,6" FontSize="12" Background="Transparent" Foreground="{DynamicResource ThemeSub}" BorderBrush="{DynamicResource ThemeBorder}" BorderThickness="1" Cursor="Hand"/></StackPanel></DockPanel>
              <Grid x:Name="BrowsePanel" Grid.Row="1" Margin="0,14,0,0"><Grid.RowDefinitions><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/><RowDefinition Height="*"/><RowDefinition Height="Auto"/></Grid.RowDefinitions>
                <Border x:Name="SearchBoxBorder" Grid.Row="0" Background="{DynamicResource ThemeCard2}" BorderBrush="{DynamicResource ThemeBorder}" BorderThickness="1" CornerRadius="8" Margin="0,0,0,12" Padding="8,4" Visibility="Collapsed">
                  <DockPanel><TextBlock Text="&#xE721;" FontFamily="Segoe MDL2 Assets" Foreground="{DynamicResource ThemeSub}" VerticalAlignment="Center" Margin="5,0,10,0"/>
                    <TextBox x:Name="TxtSearch" Background="Transparent" BorderThickness="0" Foreground="{DynamicResource ThemeFg}" VerticalContentAlignment="Center" FontSize="14" CaretBrush="{DynamicResource ThemeAccent}"/>
                  </DockPanel></Border>
                <Border x:Name="InternetBanner" Grid.Row="1" Background="#14202B" BorderBrush="{DynamicResource ThemeBorder}" BorderThickness="1" CornerRadius="{StaticResource Rm}" Padding="12" Margin="0,0,0,12" Visibility="Collapsed">
                  <DockPanel><ProgressBar IsIndeterminate="True" Width="120" Height="12" Margin="0,0,12,0" DockPanel.Dock="Left"/>
                    <TextBlock x:Name="InternetText" Text="Waiting..." Foreground="{DynamicResource ThemeFg}" VerticalAlignment="Center"/></DockPanel></Border>
                <ScrollViewer Grid.Row="1"><ItemsControl x:Name="ItemsList"><ItemsControl.ItemTemplate><DataTemplate>
                  <Border Background="{DynamicResource ThemeCard2}" BorderBrush="{DynamicResource ThemeBorder}" BorderThickness="1" CornerRadius="{StaticResource Rm}" Padding="14" Margin="0,0,0,12">
                    <DockPanel><CheckBox IsChecked="{Binding Selected}" Margin="0,0,12,0" VerticalAlignment="Center" Foreground="{DynamicResource ThemeFg}"/>
                      <StackPanel><TextBlock Text="{Binding Name}" Foreground="{DynamicResource ThemeFg}" FontSize="16" FontWeight="SemiBold"/>
                        <TextBlock Text="{Binding Sub}" Foreground="{DynamicResource ThemeSub}" FontSize="12"/></StackPanel></DockPanel></Border>
                </DataTemplate></ItemsControl.ItemTemplate></ItemsControl></ScrollViewer>
                <Border Grid.Row="2" Background="#111318" BorderBrush="{DynamicResource ThemeBorder}" BorderThickness="1" CornerRadius="{StaticResource Rm}" Padding="10" Margin="0,12,0,0">
                  <DockPanel><ProgressBar x:Name="InstallProgress" Height="12" Minimum="0" Maximum="100" Value="0" Margin="0,0,12,0" Width="260" DockPanel.Dock="Left"/>
                    <TextBlock x:Name="StatusText" Text="Ready." Foreground="{DynamicResource ThemeSub}" VerticalAlignment="Center" TextTrimming="CharacterEllipsis"/></DockPanel></Border></Grid>
              <Grid x:Name="InstallPanel" Grid.Row="1" Margin="0,14,0,0" Visibility="Collapsed">
                <StackPanel VerticalAlignment="Center" HorizontalAlignment="Center" Width="500">
                  <Border Width="70" Height="70" CornerRadius="20" Background="{DynamicResource ThemeAccent}" HorizontalAlignment="Center" Margin="0,0,0,24" Effect="{StaticResource SoftGlow}">
                    <TextBlock Text="&#xE896;" FontFamily="Segoe MDL2 Assets" FontSize="32" Foreground="White" HorizontalAlignment="Center" VerticalAlignment="Center"/></Border>
                  <TextBlock x:Name="InstTitle" Text="Installing..." Foreground="{DynamicResource ThemeFg}" FontSize="26" FontWeight="Bold" HorizontalAlignment="Center" Margin="0,0,0,8"/>
                  <TextBlock x:Name="InstAppName" Text="" Foreground="{DynamicResource ThemeAccent}" FontSize="20" FontWeight="SemiBold" HorizontalAlignment="Center" Margin="0,0,0,6"/>
                  <TextBlock x:Name="InstCount" Text="0 / 0" Foreground="{DynamicResource ThemeSub}" FontSize="14" HorizontalAlignment="Center" Margin="0,0,0,24"/>
                  <Border Background="{DynamicResource ThemeCard2}" CornerRadius="8" Padding="4" Margin="0,0,0,10">
                    <ProgressBar x:Name="InstProgressBig" Height="22" Minimum="0" Maximum="100" Value="0"/></Border>
                  <TextBlock x:Name="InstPct" Text="0%" Foreground="{DynamicResource ThemeFg}" FontSize="32" FontWeight="Bold" HorizontalAlignment="Center" Margin="0,8,0,12"/>
                  <TextBlock x:Name="InstStatus" Text="" Foreground="{DynamicResource ThemeSub}" FontSize="13" HorizontalAlignment="Center" TextWrapping="Wrap"/></StackPanel></Grid>
            </Grid></Border>
          <StackPanel Grid.Row="2" Orientation="Horizontal" HorizontalAlignment="Right" VerticalAlignment="Center">
            <Button x:Name="BtnBack" Content="Back" Padding="20,10" Margin="0,0,12,0" Style="{StaticResource PrimaryBtn}"/>
            <Button x:Name="BtnNext" Content="Next" Padding="20,10" Style="{StaticResource PrimaryBtn}"/></StackPanel>
        </Grid>
      </Grid></Border>
    <Grid x:Name="StartupOverlay" Visibility="Visible" Panel.ZIndex="100" Background="{DynamicResource ThemeCard}">
      <StackPanel Orientation="Horizontal" HorizontalAlignment="Right" VerticalAlignment="Top" Margin="0,8,8,0" Panel.ZIndex="10">
        <Button x:Name="OvMute" Content="Mute" Margin="0,0,8,0" Height="34" FontSize="14" Foreground="{DynamicResource ThemeSub}" Background="Transparent" BorderThickness="0" Cursor="Hand"/>
        <Button x:Name="OvMin" Content="&#xE921;" Style="{StaticResource WinCtrlBtn}"/>
        <Button x:Name="OvClose" Content="&#xE8BB;" Style="{StaticResource CloseBtn}"/></StackPanel>
      <Border Background="Transparent" BorderThickness="0" CornerRadius="0" Padding="60,40" Margin="0,40,0,0">
        <Grid MaxWidth="1200">
          <Grid.RowDefinitions><RowDefinition Height="Auto"/><RowDefinition Height="*"/><RowDefinition Height="Auto"/></Grid.RowDefinitions>
          <StackPanel Grid.Row="0" Margin="0,0,0,30">
            <TextBlock x:Name="WelcomeTitle" Text="WinFlexOS" Foreground="{DynamicResource ThemeFg}" FontSize="36" FontWeight="Bold"/>
            <TextBlock x:Name="WelcomeDesc" Text="Setup &amp; Optimization" Foreground="{DynamicResource ThemeAccent}" FontSize="16" Margin="2,4,0,0"/></StackPanel>
          <Grid Grid.Row="1">
            <Grid.RowDefinitions><RowDefinition Height="*"/><RowDefinition Height="Auto"/></Grid.RowDefinitions>
            <Border x:Name="WelcomePanel" Grid.Row="0" Background="{DynamicResource ThemeCard2}" BorderBrush="{DynamicResource ThemeBorder}" BorderThickness="1" CornerRadius="16" Padding="32" Effect="{StaticResource CardShadow}">
              <Grid>
                <Grid.RowDefinitions><RowDefinition Height="*"/><RowDefinition Height="Auto"/></Grid.RowDefinitions>
                <ScrollViewer Grid.Row="0" VerticalScrollBarVisibility="Auto" Margin="0,0,0,24" Padding="0,0,20,0">
                  <StackPanel>
                    <!-- Header & Intro -->
                    <TextBlock x:Name="WelcomeBodyTitle" Text="Welcome" Foreground="{DynamicResource ThemeFg}" FontSize="32" FontWeight="SemiBold" Margin="0,0,0,16"/>
                    <TextBlock x:Name="WelcomeIntroText" Text="Loading..." Foreground="{DynamicResource ThemeSub}" TextWrapping="Wrap" FontSize="16" LineHeight="26" Margin="0,0,0,36"/>
                    
                    <!-- About System Card -->
                    <Border Background="{DynamicResource ThemeSidebar}" BorderBrush="{DynamicResource ThemeBorder}" BorderThickness="1" CornerRadius="14" Padding="24" Margin="0,0,0,24">
                      <StackPanel>
                        <StackPanel Orientation="Horizontal" Margin="0,0,0,16">
                          <TextBlock Text="&#xE9D5;" FontFamily="Segoe MDL2 Assets" FontSize="20" Foreground="{DynamicResource ThemeAccent}" Margin="0,0,12,0" VerticalAlignment="Center"/>
                          <TextBlock x:Name="AboutTitleText" Text="About" Foreground="{DynamicResource ThemeFg}" FontSize="20" FontWeight="SemiBold" VerticalAlignment="Center"/>
                        </StackPanel>
                        <TextBlock x:Name="AboutBodyText" Text="Loading details..." Foreground="{DynamicResource ThemeSub}" TextWrapping="Wrap" FontSize="15" LineHeight="28"/>
                      </StackPanel>
                    </Border>
                    
                    <!-- Usage Card -->
                    <Border Background="{DynamicResource ThemeSidebar}" BorderBrush="{DynamicResource ThemeBorder}" BorderThickness="1" CornerRadius="14" Padding="24" Margin="0,0,0,24">
                      <StackPanel>
                        <StackPanel Orientation="Horizontal" Margin="0,0,0,16">
                          <TextBlock Text="&#xE9EE;" FontFamily="Segoe MDL2 Assets" FontSize="20" Foreground="{DynamicResource ThemeAccent}" Margin="0,0,12,0" VerticalAlignment="Center"/>
                          <TextBlock x:Name="UsageTitleText" Text="How to use" Foreground="{DynamicResource ThemeFg}" FontSize="20" FontWeight="SemiBold" VerticalAlignment="Center"/>
                        </StackPanel>
                        <TextBlock x:Name="UsageBodyText" Text="Loading steps..." Foreground="{DynamicResource ThemeSub}" TextWrapping="Wrap" FontSize="15" LineHeight="28"/>
                      </StackPanel>
                    </Border>
                    
                    <!-- Hint Footer -->
                    <TextBlock x:Name="HintText" Text="" Foreground="{DynamicResource ThemeSub}" TextWrapping="Wrap" FontSize="14" FontStyle="Italic" HorizontalAlignment="Center" Margin="0,10,0,10"/>
                  </StackPanel>
                </ScrollViewer>
                <StackPanel Grid.Row="1" Orientation="Horizontal" HorizontalAlignment="Center">
                  <Button x:Name="BtnContinue" Content="Continue" Padding="45,16" Margin="0,0,24,0" Style="{StaticResource PrimaryBtn}" FontSize="18" FontWeight="SemiBold"/>
                  <Button x:Name="BtnExitWelcome" Content="Exit" Padding="45,16" FontSize="18" Background="Transparent" Foreground="{DynamicResource ThemeSub}" BorderBrush="{DynamicResource ThemeBorder}" BorderThickness="1" Cursor="Hand"/></StackPanel>
              </Grid>
            </Border>
            <Border x:Name="PreflightPanel" Grid.Row="1" Background="{DynamicResource ThemeCard2}" BorderBrush="{DynamicResource ThemeBorder}" BorderThickness="1" CornerRadius="16" Padding="24" Margin="0,20,0,0" Visibility="Collapsed">
              <StackPanel>
                <TextBlock x:Name="PreflightHeader" Text="Pre-flight Check" Foreground="{DynamicResource ThemeFg}" FontSize="18" FontWeight="SemiBold"/>
                <TextBlock x:Name="PreflightStatus" Text="Verifying components..." Foreground="{DynamicResource ThemeSub}" Margin="0,12,0,0" TextWrapping="Wrap"/>
                <ProgressBar x:Name="PreflightBar" Height="14" Margin="0,18,0,0" Minimum="0" Maximum="100" Value="0"/>
                <TextBlock x:Name="PreflightPct" Text="0%" Foreground="{DynamicResource ThemeSub}" FontSize="12" HorizontalAlignment="Right" Margin="0,6,0,0"/></StackPanel></Border></Grid>
          <TextBlock Grid.Row="2" x:Name="WelcomeFoot" Visibility="Collapsed"/>
        </Grid>
      </Border>
    </Grid>
  </Grid>
</Window>
"@

try {
    $reader = New-Object System.Xml.XmlNodeReader ([xml]$xaml)
    $window = [Windows.Markup.XamlReader]::Load($reader)
} catch { throw "XAML load failed: $($_.Exception.Message)" }
function Find([string]$name) { $window.FindName($name) }

$BgImage=Find "BgImage"; $TopTitle=Find "TopTitle"; $TopSub=Find "TopSub"
$PageTitle=Find "PageTitle"; $PageDesc=Find "PageDesc"; $ItemsList=Find "ItemsList"
$InstallProgress=Find "InstallProgress"; $StatusText=Find "StatusText"
$InternetBanner=Find "InternetBanner"; $InternetText=Find "InternetText"
$BtnBack=Find "BtnBack"; $BtnNext=Find "BtnNext"
$BtnLang=Find "BtnLang"; $BtnMute=Find "BtnMute"; $BtnMin=Find "BtnMin"
$BtnMax=Find "BtnMax"; $BtnClose=Find "BtnClose"; $SideMenu=Find "SideMenu"
$SideSub=Find "SideSub"; $SideFooter=Find "SideFooter"; $CmbTheme=Find "CmbTheme"
$MainBorder=Find "MainBorder"; $MainArea=Find "MainArea"; $StartupOverlay=Find "StartupOverlay"
$BrowsePanel=Find "BrowsePanel"; $InstallPanel=Find "InstallPanel"
$InstTitle=Find "InstTitle"; $InstAppName=Find "InstAppName"; $InstCount=Find "InstCount"
$InstProgressBig=Find "InstProgressBig"; $InstPct=Find "InstPct"; $InstStatus=Find "InstStatus"
$WelcomeTitle=Find "WelcomeTitle"; $WelcomeDesc=Find "WelcomeDesc"
$WelcomePanel=Find "WelcomePanel"; $WelcomeBodyTitle=Find "WelcomeBodyTitle"
$WelcomeIntroText=Find "WelcomeIntroText"; $AboutTitleText=Find "AboutTitleText"
$AboutBodyText=Find "AboutBodyText"; $UsageTitleText=Find "UsageTitleText"
$UsageBodyText=Find "UsageBodyText"; $HintText=Find "HintText"
$PreflightPanel=Find "PreflightPanel"
$PreflightHeader=Find "PreflightHeader"; $PreflightStatus=Find "PreflightStatus"
$PreflightBar=Find "PreflightBar"; $PreflightPct=Find "PreflightPct"
$BtnContinue=Find "BtnContinue"; $BtnExitWelcome=Find "BtnExitWelcome"; $WelcomeFoot=Find "WelcomeFoot"
$BtnSelectAll=Find "BtnSelectAll"; $BtnDeselectAll=Find "BtnDeselectAll"
$OvMin=Find "OvMin"; $OvClose=Find "OvClose"; $OvMute=Find "OvMute"
$TxtSearch=Find "TxtSearch"; $SearchBoxBorder=Find "SearchBoxBorder"

if (Test-Path -LiteralPath $backgroundImagePath) {
    try { $bmp=New-Object System.Windows.Media.Imaging.BitmapImage; $bmp.BeginInit(); $bmp.CacheOption=[System.Windows.Media.Imaging.BitmapCacheOption]::OnLoad; $bmp.UriSource=[Uri]::new("file:///$backgroundImagePath"); $bmp.EndInit(); $BgImage.Source=$bmp } catch {} }
# Log labels removed

$MainBorder.Add_MouseLeftButtonDown({ try { if ($_.ClickCount -eq 2) { if ($window.WindowState -eq 'Maximized') { $window.WindowState='Normal' } else { $window.WindowState='Maximized' } } else { $window.DragMove() } } catch {} })
$BtnClose.Add_Click({ $window.Close() }); $OvClose.Add_Click({ $window.Close() })
$BtnMin.Add_Click({ $window.WindowState='Minimized' }); $OvMin.Add_Click({ $window.WindowState='Minimized' })
$BtnMax.Add_Click({ if ($window.WindowState -eq 'Maximized') { $window.WindowState='Normal' } else { $window.WindowState='Maximized' } })
$MuteHandler = { 
    Toggle-Mute
    $text = $(if ($script:isMuted) { (L (-join([char]0x05D1,[char]0x05D8,[char]0x05DC,[char]0x0020,[char]0x05D4,[char]0x05E9,[char]0x05EA,[char]0x05E7,[char]0x05D4)) "Unmute") } 
            else { (L (-join([char]0x05D4,[char]0x05E9,[char]0x05EA,[char]0x05E7)) "Mute") })
    $BtnMute.Content = $text
    $OvMute.Content = $text
}
$BtnMute.Add_Click($MuteHandler)
$OvMute.Add_Click($MuteHandler)

foreach ($t in $script:Themes) { [void]$CmbTheme.Items.Add($t.Name) }; $CmbTheme.SelectedIndex=0
function Apply-ThemeByName([string]$Name) {
    $t=$script:Themes|Where-Object{$_.Name -eq $Name}|Select-Object -First 1; if(-not $t){return}
    function SetBrush([string]$key,[string]$hex){$bc=New-Object System.Windows.Media.BrushConverter;$brush=[System.Windows.Media.Brush]$bc.ConvertFromString($hex);$brush.Freeze();$window.Resources[$key]=$brush}
    SetBrush "ThemeBg" $t.Bg; SetBrush "ThemeSidebar" $t.Sidebar; SetBrush "ThemeCard" $t.Card; SetBrush "ThemeCard2" $t.Card2
    SetBrush "ThemeFg" $t.Fg; SetBrush "ThemeSub" $t.Sub; SetBrush "ThemeAccent" $t.Accent; SetBrush "ThemeBorder" $t.Border
}
$CmbTheme.Add_SelectionChanged({ Apply-ThemeByName ([string]$CmbTheme.SelectedItem) }); Apply-ThemeByName ([string]$CmbTheme.SelectedItem)

function New-ItemVm($item) {
    $sub=if($item.WingetId){"winget: $($item.WingetId)"}elseif($item.Path){"file: $($item.Path)"}else{""}
    $sel=$false
    [pscustomobject]@{Name=$item.Name;Sub=$sub;Raw=$item;Selected=$sel}
}
$script:CurrentCategoryIndex=0; $script:CategoryVms=@(); $script:IsInstallPhase=$false
function Initialize-CategoryVms {
    $script:CategoryVms=@()
    foreach($cat in $script:Categories){$script:CategoryVms+=,(@($cat.Items|ForEach-Object{New-ItemVm $_}))}
}

function Get-CategorySelectedCount([int]$idx) { $c=0; foreach($vm in $script:CategoryVms[$idx]){if($vm.Selected){$c++}}; return $c }
function Get-TotalSelectedCount { $c=0; for($i=0;$i -lt $script:CategoryVms.Count;$i++){$c+=(Get-CategorySelectedCount $i)}; return $c }

function Apply-Language {
    $script:isHe = ($script:Lang -eq "he")
    $BtnLang.Content = $(if ($script:isHe) { "EN" } else { "HE" })
    
    $BtnMute.Content = $(if ($script:isMuted) { (L (He @(0x05D1,0x05D8,0x05DC,0x0020,0x05D4,0x05E9,0x05EA,0x05E7,0x05D4)) "Unmute") } else { (L (He @(0x05D4,0x05E9,0x05EA,0x05E7)) "Mute") })
    $BtnBack.Content = $(L (He @(0x05D4,0x05E7,0x05D5,0x05D3,0x05DD)) "Back")
    $BtnNext.Content = $(L (He @(0x05D4,0x05D1,0x05D0)) "Next")
    $TopSub.Text = $(L (He @(0x05D1,0x05D7,0x05E8,0x20,0x05EA,0x05D5,0x05DB,0x05E0,0x05D5,0x05EA,0x20,0x05DC,0x05D4,0x05EA,0x05E7,0x05E0,0x05D4)) "Choose apps to install")
    $SideSub.Text = $(L (He @(0x05EA,0x05E4,0x05E8,0x05D9,0x05D8,0x20,0x05D4,0x05EA,0x05E7,0x05E0,0x05D4)) "Installation menu")
    $StatusText.Text = $(L (He @(0x05DE,0x05D5,0x05DB,0x05DF,0x2E)) "Ready.")
    $InternetText.Text = $(L (He @(0x5DE,0x5DE,0x5EA,0x5D9,0x5E0,0x5D9,0x5DD,0x20,0x5DC,0x5D0,0x5D9,0x5E0,0x5D8,0x5E8,0x5E0,0x5D8,0x2E,0x2E,0x2E)) "Waiting for internet...")
    $BtnSelectAll.Content = $(L (He @(0x05D1,0x05D7,0x05E8,0x20,0x05D4,0x05DB,0x05DC)) "Select All")
    $BtnDeselectAll.Content = $(L (He @(0x05D1,0x05D8,0x05DC,0x05D4,0x05DB,0x05DC)) "Deselect All")
    $BtnContinue.Content = $(L (He @(0x05D4,0x05D1,0x05D0)) "Next")
    $BtnExitWelcome.Content = $(L (He @(0x05DC,0x05D0,0x20,0x05DE,0x05E2,0x05D5,0x05E0,0x05D9,0x05D9,0x05DF)) "No thanks")
    
    $userName = $env:USERNAME
    $wGreHe = (He @(0x05E9, 0x05DC, 0x05D5, 0x05DD, 0x20)) + $userName
    $wTitleHe = He @(0x05D1,0x05E8,0x05D5,0x05DB,0x05D9,0x05DD,0x20,0x05D4,0x05D1,0x05D0,0x05D9,0x05DD,0x20,0x05DC,0x2D,0x57,0x69,0x6E,0x46,0x6C,0x65,0x78,0x4F,0x53)
    $wDescHe = He @(0x05D4,0x05D2,0x05E8,0x05E1,0x05D4,0x20,0x05E9,0x05DC,0x05DA,0x2C,0x20,0x05D4,0x05E9,0x05DC,0x05D9,0x05D8,0x05D4,0x20,0x05E9,0x05DC,0x05DA,0x2E)
    $WelcomeTitle.Text = $(L $wTitleHe "Welcome to WinFlexOS")
    $WelcomeDesc.Text = $(L $wGreHe ("Hello " + $userName))
    
    $window.FlowDirection = $(if ($script:isHe) { "RightToLeft" } else { "LeftToRight" })
}
$BtnLang.Add_Click({ $script:Lang=$(if($script:Lang -eq "he"){"en"}else{"he"}); Apply-Language; Render-SideMenu; Show-Category })

$TxtSearch.Add_KeyDown({
    if ($_.Key -eq 'Return' -or $_.Key -eq 'Enter') {
        $val = $TxtSearch.Text.Trim()
        if ($val -ne "") {
            $newItem = [pscustomobject]@{Name=$val; Sub="winget: $val"; Raw=@{Name=$val; WingetId=$val; IsCustom=$true}; Selected=$true}
            $script:CategoryVms[$script:CurrentCategoryIndex] += $newItem
            $ItemsList.ItemsSource = $null
            $ItemsList.ItemsSource = $script:CategoryVms[$script:CurrentCategoryIndex]
            $TxtSearch.Text = ""
            Render-SideMenu
        }
    }
})

$script:SideButtons=@()
function Render-SideMenu {
    $SideMenu.Children.Clear(); $script:SideButtons=@()
    for($i=0;$i -lt $script:Categories.Count;$i++){
        $cat=$script:Categories[$i]; $cnt=Get-CategorySelectedCount $i
        $label=(L $cat.TitleHe $cat.TitleEn); if($cnt -gt 0){$label+=" ($cnt)"}
        $btn=New-Object System.Windows.Controls.Button
        $btn.Content=$label; $btn.Tag=$cat.Icon; $btn.Uid=$i.ToString(); $btn.Style=$window.FindResource("SidebarBtn")
        $btn.Add_Click({$script:CurrentCategoryIndex=[int]$this.Uid;Show-Category})
        $SideMenu.Children.Add($btn)|Out-Null; $script:SideButtons+=$btn
    }
    for($j=0;$j -lt $script:SideButtons.Count;$j++){
        $b=$script:SideButtons[$j]
        if($j -eq $script:CurrentCategoryIndex){$b.Foreground=$window.Resources["ThemeFg"];$b.Background=New-Object System.Windows.Media.SolidColorBrush([System.Windows.Media.ColorConverter]::ConvertFromString("#15222E"))}
        else{$b.Foreground=$window.Resources["ThemeSub"];$b.Background=[System.Windows.Media.Brushes]::Transparent}
    }
}
function Show-Category {
    $script:IsInstallPhase=$false; $cat=$script:Categories[$script:CurrentCategoryIndex]
    $PageTitle.Text=(L $cat.TitleHe $cat.TitleEn)
    $PageDesc.Text=(L (-join([char]0x05D1,[char]0x05D7,[char]0x05E8,[char]0x0020,[char]0x05DE,[char]0x05D4,[char]0x0020,[char]0x05DC,[char]0x05D4,[char]0x05EA,[char]0x05E7,[char]0x05D9,[char]0x05DF,[char]0x002E)) "Select what to install.")
    $ItemsList.ItemsSource=$script:CategoryVms[$script:CurrentCategoryIndex]
    if($cat.Key -eq "custom"){$SearchBoxBorder.Visibility='Visible'}else{$SearchBoxBorder.Visibility='Collapsed'}
    $BrowsePanel.Visibility='Visible'; $InstallPanel.Visibility='Collapsed'
    $InstallProgress.Value=0; $StatusText.Text=(L (-join([char]0x05DE,[char]0x05D5,[char]0x05DB,[char]0x05DF,[char]0x002E)) "Ready.")
    $BtnBack.IsEnabled=$true; $BtnNext.IsEnabled=$true; Render-SideMenu
}
function Get-SelectedSoftware { $sel=New-Object System.Collections.Generic.List[object]; for($i=0;$i -lt $script:CategoryVms.Count;$i++){foreach($vm in $script:CategoryVms[$i]){if($vm.Selected){$sel.Add($vm.Raw)}}}; return $sel }

$BtnSelectAll.Add_Click({ foreach($vm in $script:CategoryVms[$script:CurrentCategoryIndex]){$vm.Selected=$true}; $ItemsList.ItemsSource=$null; $ItemsList.ItemsSource=$script:CategoryVms[$script:CurrentCategoryIndex]; Render-SideMenu })
$BtnDeselectAll.Add_Click({ foreach($vm in $script:CategoryVms[$script:CurrentCategoryIndex]){$vm.Selected=$false}; $ItemsList.ItemsSource=$null; $ItemsList.ItemsSource=$script:CategoryVms[$script:CurrentCategoryIndex]; Render-SideMenu })

function Start-InstallPhase {
    $selected=@(Get-SelectedSoftware)
    if($selected.Count -eq 0){$StatusText.Text=(L (-join([char]0x05DC,[char]0x05D0,[char]0x0020,[char]0x05E0,[char]0x05D1,[char]0x05D7,[char]0x05E8,[char]0x0020,[char]0x05DB,[char]0x05DC,[char]0x05D5,[char]0x05DD,[char]0x002E)) "Nothing selected.");return}
    $script:IsInstallPhase=$true; $BrowsePanel.Visibility='Collapsed'; $InstallPanel.Visibility='Visible'
    $PageTitle.Text=(L (-join([char]0x05DE,[char]0x05EA,[char]0x05E7,[char]0x05D9,[char]0x05DF,[char]0x0020,[char]0x05EA,[char]0x05D5,[char]0x05DB,[char]0x05E0,[char]0x05D5,[char]0x05EA,[char]0x002E,[char]0x002E,[char]0x002E)) "Installing..."); $PageDesc.Text=(L (-join([char]0x05D0,[char]0x05E0,[char]0x05D0,[char]0x0020,[char]0x05D4,[char]0x05DE,[char]0x05EA,[char]0x05DF,[char]0x002E,[char]0x002E,[char]0x002E)) "Please wait...")
    $InstTitle.Text=(L (-join([char]0x05DE,[char]0x05EA,[char]0x05E7,[char]0x05D9,[char]0x05DF,[char]0x0020,[char]0x05EA,[char]0x05D5,[char]0x05DB,[char]0x05E0,[char]0x05D5,[char]0x05EA,[char]0x002E,[char]0x002E,[char]0x002E)) "Installing software..."); $InstProgressBig.Value=0; $InstPct.Text="0%"
    $InstAppName.Text=""; $InstCount.Text=""; $InstStatus.Text=""
    $BtnBack.IsEnabled=$false; $BtnNext.IsEnabled=$false; $window.Dispatcher.Invoke([action]{},"Background")
    $hasWinget=[bool](Get-Command winget -ErrorAction SilentlyContinue)
    if(-not $hasWinget){
        Write-Log "winget missing"; $InstAppName.Text="Winget"
        $InstStatus.Text=(L (-join([char]0x05DE,[char]0x05EA,[char]0x05E7,[char]0x05D9,[char]0x05DF,[char]0x0020,[char]0x0057,[char]0x0069,[char]0x006E,[char]0x0067,[char]0x0065,[char]0x0074,[char]0x002E,[char]0x002E,[char]0x002E)) "Installing Winget..."); $window.Dispatcher.Invoke([action]{},"Background")
        $tmpDir=Join-Path $env:TEMP "winget-install"; New-Item -ItemType Directory -Force -Path $tmpDir -ErrorAction SilentlyContinue|Out-Null
        $bundle=Join-Path $tmpDir "Microsoft.DesktopAppInstaller.msixbundle"
        try{(New-Object Net.WebClient).DownloadFile("https://aka.ms/getwinget",$bundle)}catch{}
        try{Add-AppxPackage -Path $bundle -ErrorAction SilentlyContinue|Out-Null}catch{}; Start-Sleep -Seconds 2 }
    $total=$selected.Count
    for($i=0;$i -lt $total;$i++){
        $sw=$selected[$i]; $name=$sw.Name
        $InstAppName.Text=$name; $InstCount.Text="$($i+1) / $total"
        $InstPct.Text="$([int](($i*100)/$total))%"; $InstProgressBig.Value=[int](($i*100)/$total)
        $InstStatus.Text=(L ((-join([char]0x05DE,[char]0x05EA,[char]0x05E7,[char]0x05D9,[char]0x05DF,[char]0x003A,[char]0x0020))+$name) "Installing: $name"); $window.Dispatcher.Invoke([action]{},"Background")
        try{ Write-Log "Install start: $name"
            if($sw.IsCustom) { Invoke-WingetInstall $sw.WingetId $false }
            elseif($sw.WingetId){Invoke-WingetInstall $sw.WingetId}
            elseif($sw.Path){if(-not(Test-Path -LiteralPath $sw.Path)){throw "Not found: $($sw.Path)"};Start-Process -FilePath $sw.Path -Wait}
            else{throw "Unknown method"}; Write-Log "Install success: $name"
        }catch{Write-Log "Install failed: $name :: $($_.Exception.Message)"}
    }
    $InstProgressBig.Value=100; $InstPct.Text="100%"
    $InstTitle.Text=(L (-join([char]0x05D4,[char]0x05D5,[char]0x05E9,[char]0x05DC,[char]0x05DD,[char]0x05D5,[char]0x0021)) "Completed!"); $InstAppName.Text=(L (-join([char]0x05DB,[char]0x05DC,[char]0x0020,[char]0x05D4,[char]0x05EA,[char]0x05D5,[char]0x05DB,[char]0x05E0,[char]0x05D5,[char]0x05EA,[char]0x0020,[char]0x05D4,[char]0x05D5,[char]0x05EA,[char]0x05E7,[char]0x05E0,[char]0x05D5,[char]0x002E)) "All software installed.")
    $InstCount.Text="$total / $total"; $InstStatus.Text=(L (-join([char]0x05D1,[char]0x05D3,[char]0x05D5,[char]0x05E7,[char]0x0020,[char]0x05DC,[char]0x05D5,[char]0x05D2,[char]0x002E)) "Check log.")
    $PageTitle.Text=(L (-join([char]0x05D4,[char]0x05D5,[char]0x05E9,[char]0x05DC,[char]0x05DD,[char]0x05D5,[char]0x0021)) "Completed."); $PageDesc.Text=(L (-join([char]0x05DB,[char]0x05DC,[char]0x0020,[char]0x05D4,[char]0x05EA,[char]0x05D5,[char]0x05DB,[char]0x05E0,[char]0x05D5,[char]0x05EA,[char]0x05D4,[char]0x05D5,[char]0x05EA,[char]0x05E7,[char]0x05E0,[char]0x05D5,[char]0x002E)) "All software installed.")
    $BtnBack.IsEnabled=$true; $BtnNext.IsEnabled=$false
}

function Set-PreflightUI([int]$pct,[string]$msg) { if($pct -lt 0){$pct=0}; if($pct -gt 100){$pct=100}; $PreflightBar.Value=$pct; $PreflightPct.Text="$pct%"; $PreflightStatus.Text=$msg }
function Run-PreflightAsync {
    if($script:preflightTimer){try{$script:preflightTimer.Stop()}catch{};$script:preflightTimer=$null}
    $BtnContinue.IsEnabled=$false; $BtnExitWelcome.IsEnabled=$false
    $script:preflightPhase="ping"; $script:preflightPingIdx=0; $script:preflightPingOk=0
    $script:preflightWingetPs=$null; $script:preflightWingetAsync=$null; $script:preflightWingetTick=0
    Write-Log "Preflight: starting ICMP ping sequence"
    Set-PreflightUI 2 (L (-join([char]0x05E9,[char]0x05D5,[char]0x05DC,[char]0x05D7,[char]0x0020,[char]0x0070,[char]0x0069,[char]0x006E,[char]0x0067)) "Starting ping...")
    $script:preflightTimer = New-Object System.Windows.Threading.DispatcherTimer
    $script:preflightTimer.Interval = [TimeSpan]::FromMilliseconds(450)
    $script:preflightTimer.Add_Tick({
        try {
            if ($script:preflightPhase -eq "ping") {
                if ($script:preflightPingIdx -lt 4) {
                    $n=$script:preflightPingIdx+1; $pct=[int](5+[Math]::Round($n*30/4)); $line=""
                    $p=New-Object System.Net.NetworkInformation.Ping
                    try { $r=$p.Send("1.1.1.1",4000)
                        if($r.Status -eq [System.Net.NetworkInformation.IPStatus]::Success){$script:preflightPingOk++;$ttl=$(if($null -ne $r.Options){$r.Options.Ttl}else{"?"});$line="Reply: time=$($r.RoundtripTime)ms TTL=$ttl"}
                        else{$line="Ping $n/4: $($r.Status)"} } catch { $line="Ping error" } finally { $p.Dispose() }
                    Set-PreflightUI $pct "Ping ($n/4) - $line"; $script:preflightPingIdx++; return }
                if ($script:preflightPingOk -lt 1) { Set-PreflightUI 36 (L (-join([char]0x05D0,[char]0x05D9,[char]0x05DF,[char]0x0020,[char]0x05EA,[char]0x05E9,[char]0x05D5,[char]0x05D3,[char]0x05D4,[char]0x002E)) "No reply.") }
                else { Set-PreflightUI 36 (L (-join([char]0x0050,[char]0x0069,[char]0x006E,[char]0x0067,[char]0x0020,[char]0x05D4,[char]0x05E6,[char]0x05DC,[char]0x05D7,[char]0x05D3,[char]0x002E)) "Ping OK.") }
                $script:preflightPhase="menu"
                return
            }
            if ($script:preflightPhase -eq "menu") {
                Set-PreflightUI 40 (L (-join([char]0x05DE,[char]0x05D5,[char]0x05E8,0x05D9,0x05D3,0x20,0x05EA,0x05E4,0x05E8,0x05D9,0x05D8,0x2E,0x2E,0x2E)) "Downloading menu...")
                $menuUrl = "https://raw.githubusercontent.com/dor2500/WinFlexOS-Setup/refs/heads/main/menu.ps1"
                $tempMenuPath = Join-Path $env:TEMP "winflex-menu-downloaded.ps1"
                try {
                    (New-Object Net.WebClient).DownloadFile($menuUrl, $tempMenuPath)
                    if (Test-Path -LiteralPath $tempMenuPath) {
                        . $tempMenuPath
                        Initialize-CategoryVms
                        Render-SideMenu
                        Show-Category
                        Play-Sound
                        Write-Log "Preflight: menu downloaded and loaded successfully"
                    } else {
                        throw "Downloaded file not found"
                    }
                    $script:preflightPhase="winget"
                    $ps=[PowerShell]::Create()
                    $ps.AddScript({param($LogPath);function Write-Log([string]$Message){$ts=(Get-Date).ToString("yyyy-MM-dd HH:mm:ss");try{Add-Content -Path $LogPath -Value "[$ts] $Message" -Encoding UTF8}catch{}};function Test-Winget{[bool](Get-Command winget -ErrorAction SilentlyContinue)};function Install-Winget{if(Test-Winget){return $true};$tmpDir=Join-Path $env:TEMP "winget-install";New-Item -ItemType Directory -Force -Path $tmpDir|Out-Null;$bundle=Join-Path $tmpDir "Microsoft.DesktopAppInstaller.msixbundle";(New-Object Net.WebClient).DownloadFile("https://aka.ms/getwinget",$bundle);Add-AppxPackage -Path $bundle -ErrorAction Stop|Out-Null;Start-Sleep -Seconds 2;return(Test-Winget)};Write-Log "Preflight: ensuring winget...";if(-not(Install-Winget)){throw "winget installation failed"};Write-Log "Preflight: OK";return $true}).AddArgument($script:LogPath)|Out-Null
                    $script:preflightWingetPs=$ps; $script:preflightWingetAsync=$ps.BeginInvoke(); return
                } catch {
                    Set-PreflightUI 0 (L ((-join([char]0x05E9,[char]0x05D2,[char]0x05D9,[char]0x05D0,[char]0x05D4,[char]0x003A,[char]0x0020))+$_.Exception.Message) ("Error: "+$_.Exception.Message))
                    $script:preflightTimer.Stop()
                    $BtnContinue.IsEnabled=$true
                    return
                }
            }
            if ($script:preflightPhase -eq "winget") {
                $wa=$script:preflightWingetAsync; if(-not $wa){return}; $script:preflightWingetTick++
                $cap=[Math]::Min(94,38+[Math]::Min(50,$script:preflightWingetTick))
                Set-PreflightUI $cap (L (-join([char]0x05DE,[char]0x05DB,[char]0x05D9,[char]0x05DF,[char]0x0020,[char]0x0077,[char]0x0069,[char]0x0065,[char]0x0067)) "Preparing winget...")
                if($wa.IsCompleted){$script:preflightTimer.Stop()
                    try{$null=$script:preflightWingetPs.EndInvoke($script:preflightWingetAsync)
                        Set-PreflightUI 100 (L (-join([char]0x05D1,[char]0x05D3,[char]0x05D9,[char]0x05E7,[char]0x05D5,[char]0x05EA,[char]0x0020,[char]0x05D4,[char]0x05D5,[char]0x05E9,[char]0x05DC,[char]0x05DE,[char]0x05D5,[char]0x002E)) "Checks complete.")
                        $StartupOverlay.Visibility='Collapsed';$MainArea.IsEnabled=$true;$MainArea.Opacity=1
                    }catch{Set-PreflightUI 0 (L ((-join([char]0x05E9,[char]0x05D2,[char]0x05D9,[char]0x05D0,[char]0x05D4,[char]0x003A,[char]0x0020))+$_.Exception.Message) ("Error: "+$_.Exception.Message));$BtnContinue.IsEnabled=$true}
                    finally{if($script:preflightWingetPs){$script:preflightWingetPs.Dispose()};$script:preflightWingetPs=$null;$script:preflightWingetAsync=$null} } }
        } catch {} })
    $script:preflightTimer.Start()
}

$BtnContinue.Add_Click({$WelcomePanel.Visibility='Collapsed';$PreflightPanel.Visibility='Visible';$BtnContinue.IsEnabled=$false;Run-PreflightAsync})
$BtnExitWelcome.Add_Click({$window.Close()})
$BtnBack.Add_Click({if($script:IsInstallPhase){$script:CurrentCategoryIndex=$script:Categories.Count-1;Show-Category}elseif($script:CurrentCategoryIndex -gt 0){$script:CurrentCategoryIndex--;Show-Category}})
$BtnNext.Add_Click({
    if($script:IsInstallPhase){return}
    if($script:CurrentCategoryIndex -lt ($script:Categories.Count-1)){$script:CurrentCategoryIndex++;Show-Category}
    else{Start-InstallPhase}
})

Apply-Language
$userName = $env:USERNAME

# Helper to decode Hebrew numeric arrays (and emojis)
function He { 
    param($arr) 
    $out = ""
    foreach($v in $arr) {
        if ($v -gt 0xFFFF) { $out += [char]::ConvertFromUtf32($v) }
        else { $out += [char]$v }
    }
    return $out
}

# Title and Description
# 🚀 ברוכים הבאים ל-WinFlexOS
$wTitHe = He @(0x1F680, 0x20, 0x5D1, 0x5E8, 0x5D5, 0x5DB, 0x5D9, 0x5DD, 0x20, 0x5D4, 0x5D1, 0x5D0, 0x5D9, 0x5DD, 0x20, 0x5DC, 0x2D, 0x57, 0x69, 0x6E, 0x46, 0x6C, 0x65, 0x78, 0x4F, 0x53)
$WelcomeTitle.Text = L $wTitHe "🚀 Welcome to WinFlexOS"

# הגרסה שלך. השליטה שלך.
$wDesHe = He @(0x5D4, 0x5D2, 0x5E8, 0x5E1, 0x5D4, 0x20, 0x5E9, 0x5DC, 0x5DA, 0x2E, 0x20, 0x5D4, 0x5E9, 0x5DC, 0x5D9, 0x5D8, 0x5D4, 0x20, 0x5E9, 0x5DC, 0x5DA, 0x2E)
$WelcomeDesc.Text = L $wDesHe "Your version. Your control."

# שלום [משתמש]
$wGreHe = (He @(0x5E9, 0x5DC, 0x5D5, 0x5DD, 0x20)) + $userName
$WelcomeBodyTitle.Text = L $wGreHe "Hello $userName"

# Large Body Text - Broken into chunks for safety
$b1 = He @(0x05D1, 0x05E8, 0x05D5, 0x05DB, 0x05D9, 0x05DD, 0x0020, 0x05D4, 0x05D1, 0x05D0, 0x05D9, 0x05DD, 0x0020, 0x05DC, 0x002D, 0x0057, 0x0069, 0x006E, 0x0046, 0x006C, 0x0065, 0x0078, 0x004F, 0x0053, 0x0021, 0x000A)
$b2 = He @(0x05DC, 0x05E8, 0x05E9, 0x05D5, 0x05EA, 0x05DB, 0x05DD, 0x0020, 0x05EA, 0x05E4, 0x05E8, 0x05D9, 0x05D8, 0x0020, 0x05D4, 0x05EA, 0x05E7, 0x05E0, 0x05D5, 0x05EA, 0x0020, 0x05DE, 0x05D5, 0x05E8, 0x05D7, 0x05D1, 0x000A)
$b3 = He @(0x05E9, 0x05EA, 0x05E4, 0x05E7, 0x05D9, 0x05D3, 0x05D5, 0x0020, 0x05DC, 0x05D0, 0x05E4, 0x05E9, 0x05E8, 0x0020, 0x05DC, 0x05DB, 0x05DD, 0x0020, 0x05E9, 0x05DC, 0x05D9, 0x05D8, 0x05D4, 0x0020, 0x05DE, 0x05DC, 0x05D0, 0x05D4, 0x0020, 0x05E2, 0x05DC, 0x0020, 0x05DE, 0x05D4, 0x0020, 0x05E9, 0x05DE, 0x05D5, 0x05EA, 0x05E7, 0x05DF, 0x002E, 0x000A, 0x000A)
$b4 = He @(0xD83D, 0xDEE0, 0xFE0F, 0x0020, 0x05E2, 0x05DC, 0x0020, 0x05D4, 0x05DE, 0x05E2, 0x05E8, 0x05DB, 0x05EA, 0x000A, 0x000A)
$b5 = He @(0x0057, 0x0069, 0x006E, 0x0046, 0x006C, 0x0065, 0x0078, 0x004F, 0x0053, 0x0020, 0x05D4, 0x05D9, 0x05D0, 0x0020, 0x05DC, 0x05D0, 0x0020, 0x05E1, 0x05EA, 0x05DD, 0x0020, 0x05E2, 0x05D5, 0x05D3, 0x0020, 0x05D4, 0x05EA, 0x05E7, 0x05E0, 0x05D4, 0x002E, 0x0020, 0x05D4, 0x05D9, 0x05D0, 0x0020, 0x05E4, 0x05E8, 0x05D5, 0x05D9, 0x05E7, 0x05D8, 0x0020, 0x05E9, 0x05DC, 0x0020, 0x05D0, 0x05D5, 0x05E4, 0x05D8, 0x05D9, 0x05DE, 0x05D9, 0x05D6, 0x05E6, 0x05D9, 0x05D4, 0x0020, 0x05D5, 0x05D3, 0x05D9, 0x05D5, 0x05E7, 0x003A, 0x000A, 0x000A)
$b6 = He @(0x2022, 0x0020, 0x05D1, 0x05D9, 0x05E6, 0x05D5, 0x05E2, 0x05D9, 0x05DD, 0x0020, 0x05DE, 0x05E7, 0x05E1, 0x05D9, 0x05DE, 0x05DC, 0x05D9, 0x05D9, 0x05DD, 0x003A, 0x0020, 0x05D4, 0x05E1, 0x05E8, 0x05EA, 0x0020, 0x05E8, 0x05DB, 0x05D9, 0x05D1, 0x05D9, 0x05DD, 0x0020, 0x05DE, 0x05D9, 0x05D5, 0x05EA, 0x05E8, 0x05D9, 0x05DD, 0x0020, 0x0028, 0x0042, 0x006C, 0x006F, 0x0061, 0x0074, 0x0077, 0x0061, 0x0072, 0x0065, 0x0029, 0x0020, 0x05DB, 0x05D3, 0x05D9, 0x0020, 0x05DC, 0x05D4, 0x05D1, 0x05D8, 0x05D9, 0x05D7, 0x0020, 0x05DE, 0x05D4, 0x05D9, 0x05E8, 0x05D5, 0x05EA, 0x0020, 0x05EA, 0x05D2, 0x05D5, 0x05D1, 0x05D4, 0x0020, 0x05E9, 0x05D9, 0x05D0, 0x002E, 0x000A, 0x000A)
$b7 = He @(0x2022, 0x0020, 0x05DE, 0x05D9, 0x05E0, 0x05D9, 0x05DE, 0x05DC, 0x05D9, 0x05D6, 0x05DD, 0x0020, 0x05D7, 0x05DB, 0x05DD, 0x003A, 0x0020, 0x05DE, 0x05DE, 0x05E9, 0x05E7, 0x0020, 0x05E0, 0x05E7, 0x05D9, 0x0020, 0x05E9, 0x05DE, 0x05D0, 0x05E4, 0x05E9, 0x05E8, 0x0020, 0x05DC, 0x05DA, 0x0020, 0x05DC, 0x05D4, 0x05EA, 0x05E8, 0x05DB, 0x05D6, 0x0020, 0x05D1, 0x05DE, 0x05D4, 0x0020, 0x05E9, 0x05D7, 0x05E9, 0x05D5, 0x05D1, 0x002C, 0x0020, 0x05D1, 0x05DC, 0x05D9, 0x0020, 0x05D4, 0x05E4, 0x05E8, 0x05E2, 0x05D5, 0x05EA, 0x0020, 0x05E8, 0x05E7, 0x05E2, 0x002E, 0x000A, 0x000A)
$b7a = He @(0x2022, 0x0020, 0x05DB, 0x05DC, 0x05D9, 0x0020, 0x05D0, 0x05D1, 0x05D7, 0x05D5, 0x05DF, 0x0020, 0x05DE, 0x05D5, 0x05D1, 0x05E0, 0x05D9, 0x05DD, 0x003A, 0x0020, 0x05E9, 0x05D9, 0x05DC, 0x05D5, 0x05D1, 0x0020, 0x05E9, 0x05DC, 0x0020, 0x05E1, 0x05E7, 0x05E8, 0x05D9, 0x05E4, 0x05D8, 0x05D9, 0x05DD, 0x0020, 0x05DE, 0x05EA, 0x05E7, 0x05D3, 0x05DE, 0x05D9, 0x05DD, 0x0020, 0x0028, 0x05DB, 0x05DE, 0x05D5, 0x0020, 0x05D4, 0x002D, 0x0050, 0x006F, 0x0077, 0x0065, 0x0072, 0x0053, 0x0068, 0x0065, 0x006C, 0x006C, 0x0020, 0x0047, 0x0055, 0x0049, 0x0020, 0x05E9, 0x05E4, 0x05D9, 0x05EA, 0x05D7, 0x05E0, 0x05D5, 0x0029, 0x0020, 0x05DC, 0x05E0, 0x05D9, 0x05D4, 0x05D5, 0x05DC, 0x0020, 0x05D5, 0x05EA, 0x05E7, 0x05D9, 0x05E0, 0x05D5, 0x05EA, 0x0020, 0x05D4, 0x05DE, 0x05D7, 0x05E9, 0x05D1, 0x0020, 0x05D1, 0x05DC, 0x05D7, 0x05D9, 0x05E6, 0x05EA, 0x0020, 0x05DB, 0x05E4, 0x05EA, 0x05D5, 0x05E8, 0x002E, 0x000A, 0x000A)
$b7b = He @(0x2022, 0x0020, 0x05D2, 0x05DE, 0x05D9, 0x05E9, 0x05D5, 0x05EA, 0x0020, 0x0028, 0x0046, 0x006C, 0x0065, 0x0078, 0x0029, 0x003A, 0x0020, 0x05D4, 0x05DE, 0x05E2, 0x05E8, 0x05DB, 0x05EA, 0x0020, 0x05E0, 0x05D1, 0x05E0, 0x05EA, 0x05D4, 0x0020, 0x05DB, 0x05D3, 0x05D9, 0x0020, 0x05DC, 0x05D4, 0x05D9, 0x05D5, 0x05EA, 0x0020, 0x05D5, 0x05E8, 0x05E1, 0x05D8, 0x05D9, 0x05DC, 0x05D9, 0x05EA, 0x0020, 0x2013, 0x0020, 0x05D1, 0x05D9, 0x05DF, 0x0020, 0x05D0, 0x05DD, 0x0020, 0x05D6, 0x05D4, 0x0020, 0x05DC, 0x05E2, 0x05D1, 0x05D5, 0x05D3, 0x05D4, 0x0020, 0x05D1, 0x002D, 0x0056, 0x004D, 0x0020, 0x05D5, 0x05D1, 0x05D9, 0x05DF, 0x0020, 0x05D0, 0x05DD, 0x0020, 0x05DC, 0x05DE, 0x05DB, 0x05D5, 0x05E0, 0x05D4, 0x0020, 0x05E4, 0x05D9, 0x05D6, 0x05D9, 0x05EA, 0x002E, 0x000A)
$b8 = He @(0x000A)
$b9 = He @(0x05D0, 0x05D9, 0x05DA, 0x0020, 0x05DE, 0x05E9, 0x05EA, 0x05DE, 0x05E9, 0x05D9, 0x05DD, 0x0020, 0x05D1, 0x05EA, 0x05E4, 0x05E8, 0x05D9, 0x05D8, 0x0020, 0x05D4, 0x05D4, 0x05EA, 0x05E7, 0x05E0, 0x05D5, 0x05EA, 0x003F, 0x000A)
$b10 = He @(0x0031, 0x002E, 0x0020, 0x05D1, 0x05E8, 0x05D2, 0x05E2, 0x0020, 0x05E9, 0x05EA, 0x05DE, 0x05E9, 0x05D9, 0x05DB, 0x05D5, 0x002C, 0x0020, 0x05D4, 0x05DE, 0x05E2, 0x05E8, 0x05DB, 0x05EA, 0x0020, 0x05EA, 0x05D1, 0x05E6, 0x05E2, 0x0020, 0x05E1, 0x05E8, 0x05D9, 0x05E7, 0x05EA, 0x0020, 0x05E8, 0x05E9, 0x05EA, 0x002E, 0x000A)
$b11 = He @(0x0032, 0x002E, 0x0020, 0x05DC, 0x05D0, 0x05D7, 0x05E8, 0x0020, 0x05DE, 0x05DB, 0x05DF, 0x002C, 0x0020, 0x05D9, 0x05D5, 0x05E6, 0x05D2, 0x0020, 0x05DC, 0x05DB, 0x05DD, 0x0020, 0x05EA, 0x05E4, 0x05E8, 0x05D9, 0x05D8, 0x0020, 0x05E7, 0x05D8, 0x05D2, 0x05D5, 0x05E8, 0x05D9, 0x05D5, 0x05EA, 0x0020, 0x05E0, 0x05D5, 0x05D7, 0x0020, 0x05D1, 0x05D7, 0x05DC, 0x05E7, 0x05D5, 0x0020, 0x05D4, 0x05E6, 0x05D9, 0x05D3, 0x05D9, 0x0020, 0x05E9, 0x05DC, 0x0020, 0x05D4, 0x05DE, 0x05E1, 0x05DA, 0x002E, 0x000A)
$b12 = He @(0x0033, 0x002E, 0x0020, 0x05D1, 0x05D7, 0x05E8, 0x05D5, 0x0020, 0x05D0, 0x05EA, 0x0020, 0x05D4, 0x05E7, 0x05D8, 0x05D2, 0x05D5, 0x05E8, 0x05D9, 0x05D5, 0x05EA, 0x0020, 0x05D4, 0x05E9, 0x05D5, 0x05E0, 0x05D5, 0x05EA, 0x0020, 0x05D5, 0x05E1, 0x05DE, 0x05E0, 0x05D5, 0x0020, 0x05D0, 0x05D9, 0x05DC, 0x05D5, 0x0020, 0x05EA, 0x05D5, 0x05DB, 0x05E0, 0x05D5, 0x05EA, 0x0020, 0x05EA, 0x05E8, 0x05E6, 0x05D5, 0x0020, 0x05DC, 0x05D4, 0x05EA, 0x05E7, 0x05D9, 0x05DF, 0x002E, 0x000A)
$b13 = He @(0x0034, 0x002E, 0x0020, 0x05D1, 0x05E1, 0x05D9, 0x05D5, 0x05DD, 0x0020, 0x05D4, 0x05D1, 0x05D7, 0x05D9, 0x05E8, 0x05D4, 0x002C, 0x0020, 0x05DC, 0x05D7, 0x05E6, 0x05D5, 0x0020, 0x05E2, 0x05DC, 0x0020, 0x0027, 0x05D4, 0x05D1, 0x05D0, 0x0027, 0x002C, 0x0020, 0x05D5, 0x05D4, 0x05DE, 0x05E2, 0x05E8, 0x05DB, 0x05EA, 0x0020, 0x05EA, 0x05EA, 0x05D7, 0x05D9, 0x05DC, 0x0020, 0x05D1, 0x05D4, 0x05EA, 0x05E7, 0x05E0, 0x05D4, 0x0020, 0x05E9, 0x05E7, 0x05D8, 0x05D4, 0x0020, 0x05D1, 0x05E8, 0x05E7, 0x05E2, 0x0021, 0x000A)
$b14 = He @(0x000A)
$b15 = He @(0x05DC, 0x05D7, 0x05E6, 0x05D5, 0x0020, 0x05E2, 0x05DC, 0x0020, 0x0027, 0x05D4, 0x05D1, 0x05D0, 0x0027, 0x0020, 0x05DB, 0x05D3, 0x05D9, 0x0020, 0x05DC, 0x05D4, 0x05DE, 0x05E9, 0x05D9, 0x05DA, 0x002C, 0x0020, 0x05D0, 0x05D5, 0x0020, 0x05E2, 0x05DC, 0x0020, 0x0027, 0x05DC, 0x05D0, 0x0020, 0x05DE, 0x05E2, 0x05D5, 0x05E0, 0x05D9, 0x05D9, 0x05DF, 0x0027, 0x0020, 0x05DB, 0x05D3, 0x05D9, 0x0020, 0x05DC, 0x05E6, 0x05D0, 0x05EA, 0x0020, 0x05DE, 0x05DB, 0x05D0, 0x05DF, 0x002E)
$WelcomeIntroText.Text=(L ($b1+$b2+$b3) "").Trim(); $AboutTitleText.Text=(L $b4 "").Trim()
$AboutBodyText.Text=(L ($b5+$b6+$b7+$b7a+$b7b) "").Trim(); $UsageTitleText.Text=(L $b9 "").Trim()
$UsageBodyText.Text=(L ($b10+$b11+$b12+$b13) "").Trim(); $HintText.Text=(L $b15 "").Trim()
Apply-Language

# Preflight
$phHe = He @(0x05D1, 0x05D5, 0x05D3, 0x05E7, 0x20, 0x05D7, 0x05D9, 0x05D1, 0x05D5, 0x05E8, 0x20, 0x2D, 0x57, 0x69, 0x6E, 0x67, 0x65, 0x74)
$psHe = He @(0x05DE, 0x05DE, 0x05EA, 0x05D9, 0x05E0, 0x05D9, 0x05DD, 0x2E, 0x2E, 0x2E)
$PreflightHeader.Text = L $phHe "Checking connectivity & Winget..."
$PreflightStatus.Text = L $psHe "Please wait..."

if ($SkipWelcome) {
    Write-Log "Starting in SkipWelcome mode"
    $StartupOverlay.Visibility = 'Collapsed'
    $MainArea.IsEnabled = $true
    $MainArea.Opacity = 1
    
    if ($MenuPath -and (Test-Path -LiteralPath $MenuPath)) {
        Write-Log "Loading menu from parameter path: $MenuPath"
        . $MenuPath
    } else {
        $menuUrl = "https://raw.githubusercontent.com/dor2500/WinFlexOS-Setup/refs/heads/main/menu.ps1"
        $tempMenuPath = Join-Path $env:TEMP "winflex-menu-downloaded.ps1"
        try {
            Write-Log "Downloading menu from $menuUrl"
            (New-Object Net.WebClient).DownloadFile($menuUrl, $tempMenuPath)
            . $tempMenuPath
        } catch {
            Write-Log "Failed to download menu: $_"
            [System.Windows.MessageBox]::Show("Error loading menu from GitHub: " + $_.Exception.Message)
            $window.Close()
            exit
        }
    }
    Initialize-CategoryVms
    Render-SideMenu
    Show-Category
    Play-Sound
}

$window.ShowDialog()|Out-Null
