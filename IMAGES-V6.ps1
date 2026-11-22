#Requires -Version 5.1
<#
.SYNOPSIS
    DGs Explorer Toolkit unified application hub.
.DESCRIPTION
    One searchable Windows Forms launcher for the applications and scripts in this folder.
.VERSION
    1.4.0
#>
param([switch]$SmokeTest)

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()

$script:Root = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }
$script:PowerShell = Join-Path $PSHOME 'powershell.exe'
if (-not (Test-Path -LiteralPath $script:PowerShell)) { $script:PowerShell = 'powershell.exe' }
$script:SettingsPath = Join-Path $env:LOCALAPPDATA 'DGsImageTools\ExplorerToolkit.settings.json'
$script:CustomAppsPath = Join-Path $env:LOCALAPPDATA 'DGsImageTools\IMAGES-V6.custom-apps.json'
$script:Settings = [ordered]@{ Theme = 'Dark'; Category = 'All'; CardSize = 'Comfortable'; AlwaysOnTop = $false }
if (Test-Path -LiteralPath $script:SettingsPath -PathType Leaf) {
    try {
        $saved = Get-Content -LiteralPath $script:SettingsPath -Raw -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop
        if ($saved.Theme -in @('Dark','Light','System')) { $script:Settings.Theme = [string]$saved.Theme }
        if ($saved.Category -is [string]) { $script:Settings.Category = [string]$saved.Category }
        if ($saved.CardSize -in @('Compact','Comfortable','Large')) { $script:Settings.CardSize = [string]$saved.CardSize }
        $script:Settings.AlwaysOnTop = [bool]$saved.AlwaysOnTop
    } catch { }
}
$script:ThemeColors = @{}
$script:Items = @(
    [pscustomobject]@{ Name='IMAGES-V6'; Category='Core'; File='IMAGES-V6.exe'; Kind='Exe'; Description='Open this unified hub for all bundled apps and scripts.' }
    [pscustomobject]@{ Name='Suite Uninstaller'; Category='Legacy'; File='Uninstall DGs image tools.exe'; Kind='Exe'; Description='Open the bundled suite uninstaller; review its confirmation prompts before proceeding.' }
    [pscustomobject]@{ Name='Image Tools'; Category='Images'; File='DGs Image Tools-V2.AMAZING.ps1'; Kind='Gui'; Description='Convert images, build icons, recolor icons and generate color variants.' }
    [pscustomobject]@{ Name='Bulk Rename Tool'; Category='Files'; File='RenameTool-2.1.1.ps1'; Kind='Gui'; Description='Preview batch filename changes, save settings, and undo rename batches.' }
    [pscustomobject]@{ Name='Hardened Toolkit'; Category='System'; File='HardenedToolkit-2.5.1.ps1'; Kind='Gui'; Description='Cleanup, duplicate scans, system views and uninstall helpers. Review confirmations carefully.' }
    [pscustomobject]@{ Name='Icon & Shortcut Changer'; Category='Images'; File='Icon-Color-Changer.v2.PS1'; Kind='Gui'; Description='Recolor .ico files and shortcut icons.' }
    [pscustomobject]@{ Name='Color Variant Generator'; Category='Images'; File='DG_Color_GeneratoV2.ps1'; Kind='Gui'; Description='Generate image color variants.' }
    [pscustomobject]@{ Name='PowerPlan Importer'; Category='System'; File='insopti-PowerPlan-1.1.1.ps1'; Kind='Console'; Description='Import and activate a selected Windows power plan; requires confirmation and administrator rights.' }
    [pscustomobject]@{ Name='Explorer Maintenance'; Category='System'; File='ExplorerToolkit-3.1.2.ps1'; Kind='Menu'; Description='Open the Explorer maintenance console for registry backups and Explorer settings.' }
    [pscustomobject]@{ Name='Windows Utility'; Category='Advanced'; File='winutil.ps1'; Kind='Gui'; Description='Advanced Windows utility. Review each system change before applying.' }
    [pscustomobject]@{ Name='Convert Dark Script to Light'; Category='Utilities'; File='Convert-To-LightTheme.ps1'; Kind='Converter'; Description='Choose a PowerShell script or folder, preview changes, or write converted copies.' }
    [pscustomobject]@{ Name='ColorConsole'; Category='Utilities'; File='ColorConsole.exe'; Kind='Exe'; Description='Open the bundled ColorConsole application.' }
    [pscustomobject]@{ Name='AME Settings'; Category='Advanced'; File='ame10_settings.exe'; Kind='Exe'; Description='Open the bundled AME settings utility. Verify its actions before applying.' }
    [pscustomobject]@{ Name='AppFetch'; Category='Advanced'; File='appfetch.exe'; Kind='Exe'; Description='Open the bundled AppFetch utility.' }
    [pscustomobject]@{ Name='DG Applications Setup'; Category='Installers'; File='Dg-Applicationssetup.exe'; Kind='Installer'; Description='Install the bundled DG applications package. Review the installer before proceeding.' }
    [pscustomobject]@{ Name='Chrome Setup'; Category='Installers'; File='Dg-Chromesetup.exe'; Kind='Installer'; Description='Install Google Chrome using the bundled installer.' }
    [pscustomobject]@{ Name='Everything Search Setup'; Category='Installers'; File='Dg-Everything1.4.1.1032.X64setup.exe'; Kind='Installer'; Description='Install Everything file search.' }
    [pscustomobject]@{ Name='Inno Setup'; Category='Installers'; File='Dg-Innosetup6.7.3.exe'; Kind='Installer'; Description='Install Inno Setup.' }
    [pscustomobject]@{ Name='PC Cleaner & Uninstaller'; Category='Utilities'; File='Dg-Pccleaneruninstallerv1.0.0.exe'; Kind='Utility'; Description='Open DG PC Cleaner & Uninstaller.' }
    [pscustomobject]@{ Name='DG File Search Setup'; Category='Installers'; File='Dg-S.S.Sfilesearchsetup2.0.0.exe'; Kind='Installer'; Description='Install DGs File Search v2.0.' }
    [pscustomobject]@{ Name='DG File Search Setup (Alternate Build)'; Category='Installers'; File='Dg-Sfilesearchsetup2.0.0.exe'; Kind='Installer'; Description='Install the alternate DGs File Search build.' }
    [pscustomobject]@{ Name='DG Setup Logic'; Category='Installers'; File='Dg-Setuplogic.exe'; Kind='Installer'; Description='Open the bundled DG setup utility. Confirm its source and prompts before proceeding.' }
    [pscustomobject]@{ Name='DG Uninstaller Setup'; Category='Installers'; File='Dg-Uninstaller-Setup-1.2.1.exe'; Kind='Installer'; Description='Install DG Uninstaller & Cleaner v1.2.1.' }
    [pscustomobject]@{ Name='DG Uninstaller'; Category='Utilities'; File='Dg-Uninstaller.exe'; Kind='Utility'; Description='Open DG Uninstaller & Cleaner.' }
    [pscustomobject]@{ Name='Windows Explorer Install'; Category='Installers'; File='Dg-Windows4explorerinstaller.exe'; Kind='Installer'; Description='Open the bundled Windows Explorer installer.' }
    [pscustomobject]@{ Name='Xbox Installer'; Category='Installers'; File='Dg-Xboxinstaller.exe'; Kind='Installer'; Description='Open the bundled Xbox installer.' }
)
$script:CustomApps = @()
if (Test-Path -LiteralPath $script:CustomAppsPath -PathType Leaf) {
    try {
        $savedApps = @(Get-Content -LiteralPath $script:CustomAppsPath -Raw -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop)
        $script:CustomApps = @($savedApps | Where-Object {
            $_.Name -is [string] -and $_.Path -is [string] -and $_.Category -is [string] -and
            (Test-Path -LiteralPath $_.Path -PathType Leaf) -and ([IO.Path]::GetExtension($_.Path) -in @('.exe','.ps1'))
        } | ForEach-Object {
            [pscustomobject]@{ Name=[string]$_.Name; Category=[string]$_.Category; File=[string]$_.Path; Kind='Custom'; Description=[string]$_.Description; Arguments=[string]$_.Arguments; IsCustom=$true }
        })
    } catch { $script:CustomApps = @() }
}
$script:Items = @($script:Items) + @($script:CustomApps)

$script:Form = New-Object System.Windows.Forms.Form
$form = $script:Form
$form.Text = 'IMAGES-V6 v1.4.0 | Unified Image & Explorer Toolkit'
$form.StartPosition = 'CenterScreen'
$form.Size = New-Object System.Drawing.Size(1000, 720)
$form.MinimumSize = New-Object System.Drawing.Size(820, 580)
$form.BackColor = [System.Drawing.Color]::FromArgb(20, 24, 32)
$form.ForeColor = [System.Drawing.Color]::White
$form.Font = New-Object System.Drawing.Font('Segoe UI', 9)
$form.TopMost = [bool]$script:Settings.AlwaysOnTop
$form.KeyPreview = $true
$iconPath = Join-Path $script:Root 'icons\DGsImageTools-Suite.ico'
if (Test-Path -LiteralPath $iconPath) { try { $form.Icon = New-Object System.Drawing.Icon($iconPath) } catch {} }

$layout = New-Object System.Windows.Forms.TableLayoutPanel
$layout.Dock = 'Fill'
$layout.ColumnCount = 1
$layout.RowCount = 5
$layout.Margin = [System.Windows.Forms.Padding]::Empty
$layout.Padding = [System.Windows.Forms.Padding]::Empty
[void]$layout.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent, 100)))
[void]$layout.RowStyles.Add((New-Object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::Absolute, 100)))
[void]$layout.RowStyles.Add((New-Object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::Absolute, 48)))
[void]$layout.RowStyles.Add((New-Object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::Absolute, 38)))
[void]$layout.RowStyles.Add((New-Object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::Percent, 100)))
[void]$layout.RowStyles.Add((New-Object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::Absolute, 38)))
$form.Controls.Add($layout)

$script:ThemeColors = @{
    Dark = @{ Form=[System.Drawing.Color]::FromArgb(20,24,32); Panel=[System.Drawing.Color]::FromArgb(27,34,46); Card=[System.Drawing.Color]::FromArgb(31,38,50); Input=[System.Drawing.Color]::FromArgb(35,40,50); Button=[System.Drawing.Color]::FromArgb(45,55,72); Fore=[System.Drawing.Color]::White; Muted=[System.Drawing.Color]::Gainsboro; Accent=[System.Drawing.Color]::FromArgb(98,201,255) }
    Light = @{ Form=[System.Drawing.Color]::FromArgb(242,245,249); Panel=[System.Drawing.Color]::FromArgb(225,232,241); Card=[System.Drawing.Color]::White; Input=[System.Drawing.Color]::White; Button=[System.Drawing.Color]::FromArgb(218,228,240); Fore=[System.Drawing.Color]::FromArgb(30,41,59); Muted=[System.Drawing.Color]::FromArgb(71,85,105); Accent=[System.Drawing.Color]::FromArgb(0,103,180) }
}
$header = New-Object System.Windows.Forms.Panel
$header.Dock = 'Fill'
$header.Margin = [System.Windows.Forms.Padding]::Empty
$header.BackColor = [System.Drawing.Color]::FromArgb(27, 34, 46)
[void]$layout.Controls.Add($header, 0, 0)
$title = New-Object System.Windows.Forms.Label
$title.Text = 'IMAGES-V6  |  v1.4.0'
$title.Font = New-Object System.Drawing.Font('Segoe UI Semibold', 22, [System.Drawing.FontStyle]::Bold)
$title.AutoSize = $true
$title.Location = New-Object System.Drawing.Point(24, 12)
$title.ForeColor = [System.Drawing.Color]::FromArgb(98, 201, 255)
$header.Controls.Add($title)
$subtitle = New-Object System.Windows.Forms.Label
$subtitle.Text = 'Unified image, file, Explorer and system tools'
$subtitle.AutoSize = $true
$subtitle.Location = New-Object System.Drawing.Point(28, 62)
$subtitle.ForeColor = [System.Drawing.Color]::Gainsboro
$script:HeaderTitle = $title
$script:HeaderSubtitle = $subtitle
$header.Controls.Add($subtitle)

$searchPanel = New-Object System.Windows.Forms.Panel
$searchPanel.Dock = 'Fill'
$searchPanel.Margin = [System.Windows.Forms.Padding]::Empty
$searchPanel.Padding = New-Object System.Windows.Forms.Padding(16, 8, 16, 8)
$searchPanel.BackColor = [System.Drawing.Color]::FromArgb(20, 24, 32)
[void]$layout.Controls.Add($searchPanel, 0, 1)
$search = New-Object System.Windows.Forms.TextBox
$search.Dock = 'Fill'
$search.Font = New-Object System.Drawing.Font('Segoe UI', 11)
$search.AccessibleName = 'Search tools'
$search.Text = ''
$search.BackColor = [System.Drawing.Color]::FromArgb(35, 40, 50)
$search.ForeColor = [System.Drawing.Color]::White
$search.BorderStyle = 'FixedSingle'
$searchPanel.Controls.Add($search)
$script:SearchControl = $search

$toolbar = New-Object System.Windows.Forms.FlowLayoutPanel
$toolbar.Dock = 'Top'
$toolbar.Height = 38
$toolbar.WrapContents = $false
$toolbar.AutoScroll = $true
$toolbar.Padding = New-Object System.Windows.Forms.Padding(12, 4, 8, 2)
$toolbar.BackColor = [System.Drawing.Color]::FromArgb(27, 34, 46)
[void]$layout.Controls.Add($toolbar, 0, 2)
$themeLabel = New-Object System.Windows.Forms.Label
$themeLabel.Text = 'Theme'
$themeLabel.AutoSize = $true
$themeLabel.Margin = New-Object System.Windows.Forms.Padding(2, 7, 4, 0)
$themeLabel.ForeColor = [System.Drawing.Color]::Gainsboro
$toolbar.Controls.Add($themeLabel)
$themeCombo = New-Object System.Windows.Forms.ComboBox
$themeCombo.DropDownStyle = 'DropDownList'
$themeCombo.Width = 110
[void]$themeCombo.Items.AddRange(@('Dark','Light','System'))
$themeCombo.SelectedItem = $script:Settings.Theme
$toolbar.Controls.Add($themeCombo)
$categoryLabel = New-Object System.Windows.Forms.Label
$categoryLabel.Text = 'Category'
$categoryLabel.AutoSize = $true
$categoryLabel.Margin = New-Object System.Windows.Forms.Padding(12, 7, 4, 0)
$categoryLabel.ForeColor = [System.Drawing.Color]::Gainsboro
$toolbar.Controls.Add($categoryLabel)
$categoryCombo = New-Object System.Windows.Forms.ComboBox
$categoryCombo.DropDownStyle = 'DropDownList'
$categoryCombo.Width = 120
$categories = @('All') + @($script:Items | Select-Object -ExpandProperty Category -Unique | Sort-Object)
[void]$categoryCombo.Items.AddRange([string[]]$categories)
if ($script:Settings.Category -notin $categories) { $script:Settings.Category = 'All' }
$categoryCombo.SelectedItem = $script:Settings.Category
$toolbar.Controls.Add($categoryCombo)
$sizeLabel = New-Object System.Windows.Forms.Label
$sizeLabel.Text = 'Cards'
$sizeLabel.AutoSize = $true
$sizeLabel.Margin = New-Object System.Windows.Forms.Padding(12, 7, 4, 0)
$sizeLabel.ForeColor = [System.Drawing.Color]::Gainsboro
$toolbar.Controls.Add($sizeLabel)
$sizeCombo = New-Object System.Windows.Forms.ComboBox
$sizeCombo.DropDownStyle = 'DropDownList'
$sizeCombo.Width = 112
[void]$sizeCombo.Items.AddRange(@('Compact','Comfortable','Large'))
$sizeCombo.SelectedItem = $script:Settings.CardSize
$toolbar.Controls.Add($sizeCombo)
$topMostCheck = New-Object System.Windows.Forms.CheckBox
$topMostCheck.Text = 'Always on top'
$topMostCheck.AutoSize = $true
$topMostCheck.Checked = [bool]$script:Settings.AlwaysOnTop
$topMostCheck.Margin = New-Object System.Windows.Forms.Padding(12, 6, 4, 0)
$topMostCheck.ForeColor = [System.Drawing.Color]::Gainsboro
$toolbar.Controls.Add($topMostCheck)

$body = New-Object System.Windows.Forms.Panel
$body.Dock = 'Fill'
$body.Margin = [System.Windows.Forms.Padding]::Empty
$body.BackColor = [System.Drawing.Color]::FromArgb(20, 24, 32)
[void]$layout.Controls.Add($body, 0, 3)
$list = New-Object System.Windows.Forms.FlowLayoutPanel
$list.Dock = 'Fill'
$list.AutoScroll = $true
$list.WrapContents = $true
$list.Padding = New-Object System.Windows.Forms.Padding(14)
$list.BackColor = [System.Drawing.Color]::FromArgb(20, 24, 32)
$body.Controls.Add($list)

$footer = New-Object System.Windows.Forms.Panel
$footer.Dock = 'Fill'
$footer.Margin = [System.Windows.Forms.Padding]::Empty
$footer.BackColor = [System.Drawing.Color]::FromArgb(27, 34, 46)
[void]$layout.Controls.Add($footer, 0, 4)
$status = New-Object System.Windows.Forms.Label
$status.Text = 'Ready'
$status.Dock = 'Fill'
$status.TextAlign = 'MiddleLeft'
$status.Padding = New-Object System.Windows.Forms.Padding(12, 0, 0, 0)
$status.ForeColor = [System.Drawing.Color]::White
$footer.Controls.Add($status)
$openFolder = New-Object System.Windows.Forms.Button
$openFolder.Text = 'Open tools folder'
$openFolder.Dock = 'Right'
$openFolder.Width = 150
$openFolder.FlatStyle = 'Flat'
$openFolder.BackColor = [System.Drawing.Color]::FromArgb(45, 55, 72)
$openFolder.ForeColor = [System.Drawing.Color]::White
$openFolder.Add_Click({ Start-Process -FilePath 'explorer.exe' -ArgumentList ('"' + $script:Root + '"') })
$footer.Controls.Add($openFolder)
$addCustomApp = New-Object System.Windows.Forms.Button
$addCustomApp.Text = 'Add custom app'
$addCustomApp.Dock = 'Right'
$addCustomApp.Width = 145
$addCustomApp.FlatStyle = 'Flat'
$addCustomApp.BackColor = [System.Drawing.Color]::FromArgb(45, 55, 72)
$addCustomApp.ForeColor = [System.Drawing.Color]::White
$footer.Controls.Add($addCustomApp)

function Start-Tool {
    param([Parameter(Mandatory)]$Tool)
    $path = if ($Tool.IsCustom) { $Tool.File } else { Join-Path $script:Root $Tool.File }
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        [System.Windows.Forms.MessageBox]::Show("Tool file was not found:`r`n$path", 'Tool unavailable', 'OK', 'Warning') | Out-Null
        return
    }
    try {
        if ($Tool.IsCustom -and [IO.Path]::GetExtension($path) -ieq '.ps1') {
            $args = '-NoProfile -ExecutionPolicy Bypass -STA -File "' + $path + '"'
            if ($Tool.Arguments) { $args += ' ' + $Tool.Arguments }
            Start-Process -FilePath $script:PowerShell -ArgumentList $args -WorkingDirectory (Split-Path -Parent $path) -ErrorAction Stop | Out-Null
        } elseif ($Tool.IsCustom -or $Tool.Kind -in @('Exe','Utility','Installer')) {
            if ($Tool.Kind -eq 'Installer') {
                $answer = [System.Windows.Forms.MessageBox]::Show(
                    "Launch this installer? Only continue if you trust its source.`r`n`r`n$($Tool.Name)`r`n$path",
                    'Confirm installer', [System.Windows.Forms.MessageBoxButtons]::YesNo,
                    [System.Windows.Forms.MessageBoxIcon]::Warning)
                if ($answer -ne [System.Windows.Forms.DialogResult]::Yes) { return }
            }
            Start-Process -FilePath $path -WorkingDirectory $script:Root -ErrorAction Stop | Out-Null
        } else {
            $args = '-NoProfile -ExecutionPolicy Bypass -STA'
            switch ($Tool.Kind) {
                'Gui'     { $args += ' -WindowStyle Hidden' }
                'Menu'    { }
                'Console' { }
                default   { }
            }
            $args += ' -File "' + $path + '"'
            if ($Tool.Kind -eq 'Menu') { $args += ' -Action Menu' }
            Start-Process -FilePath $script:PowerShell -ArgumentList $args -WorkingDirectory $script:Root -ErrorAction Stop | Out-Null
        }
        $status.Text = "Launched: $($Tool.Name)"
    } catch {
        [System.Windows.Forms.MessageBox]::Show("Could not launch $($Tool.Name):`r`n$($_.Exception.Message)", 'Launch failed', 'OK', 'Error') | Out-Null
        $status.Text = "Launch failed: $($Tool.Name)"
    }
}

function Start-ThemeConverter {
    $tool = $script:Items | Where-Object { $_.Kind -eq 'Converter' } | Select-Object -First 1
    $scriptPath = Join-Path $script:Root $tool.File
    if (-not (Test-Path -LiteralPath $scriptPath -PathType Leaf)) {
        [System.Windows.Forms.MessageBox]::Show("Converter script was not found:`r`n$scriptPath", 'Tool unavailable', 'OK', 'Warning') | Out-Null
        return
    }
    $choice = [System.Windows.Forms.MessageBox]::Show('Choose Yes to convert one script file, or No to convert a folder.', 'Light Theme Converter', 'YesNoCancel', 'Question')
    if ($choice -eq [System.Windows.Forms.DialogResult]::Cancel) { return }
    if ($choice -eq [System.Windows.Forms.DialogResult]::Yes) {
        $dialog = New-Object System.Windows.Forms.OpenFileDialog
        $dialog.Title = 'Choose a PowerShell script'
        $dialog.Filter = 'PowerShell scripts (*.ps1)|*.ps1|All files (*.*)|*.*'
        if ($dialog.ShowDialog($form) -ne [System.Windows.Forms.DialogResult]::OK) { return }
        $target = $dialog.FileName
    } else {
        $dialog = New-Object System.Windows.Forms.FolderBrowserDialog
        $dialog.Description = 'Choose a folder containing PowerShell scripts'
        if ($dialog.ShowDialog($form) -ne [System.Windows.Forms.DialogResult]::OK) { return }
        $target = $dialog.SelectedPath
    }
    $preview = [System.Windows.Forms.MessageBox]::Show('Run preview only? Choose No to create converted .light.ps1 copies without changing originals.', 'Preview or convert', 'YesNoCancel', 'Question')
    if ($preview -eq [System.Windows.Forms.DialogResult]::Cancel) { return }
    $args = '-NoProfile -ExecutionPolicy Bypass -File "' + $scriptPath + '" -Path "' + $target + '"'
    if ($preview -eq [System.Windows.Forms.DialogResult]::Yes) { $args += ' -Preview' }
    try {
        Start-Process -FilePath $script:PowerShell -ArgumentList $args -WorkingDirectory $script:Root -ErrorAction Stop | Out-Null
        $status.Text = 'Launched: Light Theme Converter'
    } catch {
        [System.Windows.Forms.MessageBox]::Show("Could not launch the converter:`r`n$($_.Exception.Message)", 'Launch failed', 'OK', 'Error') | Out-Null
    }
}

function Save-HubSettings {
    try {
        $settingsDir = Split-Path -Parent $script:SettingsPath
        if (-not (Test-Path -LiteralPath $settingsDir)) { New-Item -ItemType Directory -Path $settingsDir -Force -ErrorAction Stop | Out-Null }
        $script:Settings.Theme = [string]$themeCombo.SelectedItem
        $script:Settings.Category = [string]$categoryCombo.SelectedItem
        $script:Settings.CardSize = [string]$sizeCombo.SelectedItem
        $script:Settings.AlwaysOnTop = [bool]$topMostCheck.Checked
        $script:Settings | ConvertTo-Json | Set-Content -LiteralPath $script:SettingsPath -Encoding UTF8 -ErrorAction Stop
        $customData = @($script:CustomApps | ForEach-Object { [ordered]@{ Name=$_.Name; Category=$_.Category; Path=$_.File; Description=$_.Description; Arguments=$_.Arguments } })
        ConvertTo-Json -InputObject $customData -Depth 5 | Set-Content -LiteralPath $script:CustomAppsPath -Encoding UTF8 -ErrorAction Stop
    } catch { $status.Text = "Could not save settings: $($_.Exception.Message)" }
}

function Show-AddCustomAppDialog {
    $dialog = New-Object System.Windows.Forms.Form
    $dialog.Text = 'Add custom app'
    $dialog.StartPosition = 'CenterParent'
    $dialog.Size = New-Object System.Drawing.Size(560, 330)
    $dialog.FormBorderStyle = 'FixedDialog'
    $dialog.MaximizeBox = $false
    $dialog.MinimizeBox = $false
    $dialog.BackColor = $script:ActivePalette.Form
    $dialog.ForeColor = $script:ActivePalette.Fore
    $dialog.Font = $form.Font

    $nameLabel = New-Object System.Windows.Forms.Label
    $nameLabel.Text = 'App name'
    $nameLabel.Location = New-Object System.Drawing.Point(16, 18)
    $nameLabel.Size = New-Object System.Drawing.Size(110, 22)
    $dialog.Controls.Add($nameLabel)
    $nameBox = New-Object System.Windows.Forms.TextBox
    $nameBox.Location = New-Object System.Drawing.Point(132, 16)
    $nameBox.Size = New-Object System.Drawing.Size(390, 24)
    $dialog.Controls.Add($nameBox)

    $pathLabel = New-Object System.Windows.Forms.Label
    $pathLabel.Text = 'App file (.exe/.ps1)'
    $pathLabel.Location = New-Object System.Drawing.Point(16, 58)
    $pathLabel.Size = New-Object System.Drawing.Size(115, 22)
    $dialog.Controls.Add($pathLabel)
    $pathBox = New-Object System.Windows.Forms.TextBox
    $pathBox.Location = New-Object System.Drawing.Point(132, 56)
    $pathBox.Size = New-Object System.Drawing.Size(300, 24)
    $dialog.Controls.Add($pathBox)
    $browse = New-Object System.Windows.Forms.Button
    $browse.Text = 'Browse...'
    $browse.Location = New-Object System.Drawing.Point(440, 54)
    $browse.Size = New-Object System.Drawing.Size(82, 28)
    $dialog.Controls.Add($browse)
    $browse.Add_Click({
        $picker = New-Object System.Windows.Forms.OpenFileDialog
        $picker.Title = 'Choose an application or PowerShell script'
        $picker.Filter = 'Apps and scripts (*.exe;*.ps1)|*.exe;*.ps1|Applications (*.exe)|*.exe|PowerShell scripts (*.ps1)|*.ps1|All files (*.*)|*.*'
        if ($picker.ShowDialog($dialog) -eq [System.Windows.Forms.DialogResult]::OK) {
            $pathBox.Text = $picker.FileName
            if (-not $nameBox.Text.Trim()) { $nameBox.Text = [IO.Path]::GetFileNameWithoutExtension($picker.FileName) }
        }
    }.GetNewClosure())

    $categoryLabel = New-Object System.Windows.Forms.Label
    $categoryLabel.Text = 'Category'
    $categoryLabel.Location = New-Object System.Drawing.Point(16, 100)
    $categoryLabel.Size = New-Object System.Drawing.Size(110, 22)
    $dialog.Controls.Add($categoryLabel)
    $categoryBox = New-Object System.Windows.Forms.TextBox
    $categoryBox.Location = New-Object System.Drawing.Point(132, 98)
    $categoryBox.Size = New-Object System.Drawing.Size(390, 24)
    $categoryBox.Text = 'Custom'
    $dialog.Controls.Add($categoryBox)

    $descriptionLabel = New-Object System.Windows.Forms.Label
    $descriptionLabel.Text = 'Description'
    $descriptionLabel.Location = New-Object System.Drawing.Point(16, 140)
    $descriptionLabel.Size = New-Object System.Drawing.Size(110, 22)
    $dialog.Controls.Add($descriptionLabel)
    $descriptionBox = New-Object System.Windows.Forms.TextBox
    $descriptionBox.Location = New-Object System.Drawing.Point(132, 138)
    $descriptionBox.Size = New-Object System.Drawing.Size(390, 24)
    $dialog.Controls.Add($descriptionBox)

    $argsLabel = New-Object System.Windows.Forms.Label
    $argsLabel.Text = 'Arguments (optional)'
    $argsLabel.Location = New-Object System.Drawing.Point(16, 180)
    $argsLabel.Size = New-Object System.Drawing.Size(115, 22)
    $dialog.Controls.Add($argsLabel)
    $argsBox = New-Object System.Windows.Forms.TextBox
    $argsBox.Location = New-Object System.Drawing.Point(132, 178)
    $argsBox.Size = New-Object System.Drawing.Size(390, 24)
    $dialog.Controls.Add($argsBox)

    $saveButton = New-Object System.Windows.Forms.Button
    $saveButton.Text = 'Add app'
    $saveButton.Location = New-Object System.Drawing.Point(332, 230)
    $saveButton.Size = New-Object System.Drawing.Size(90, 32)
    $saveButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
    $dialog.AcceptButton = $saveButton
    $dialog.Controls.Add($saveButton)
    $cancelButton = New-Object System.Windows.Forms.Button
    $cancelButton.Text = 'Cancel'
    $cancelButton.Location = New-Object System.Drawing.Point(432, 230)
    $cancelButton.Size = New-Object System.Drawing.Size(90, 32)
    $cancelButton.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
    $dialog.CancelButton = $cancelButton
    $dialog.Controls.Add($cancelButton)

    if ($dialog.ShowDialog($form) -ne [System.Windows.Forms.DialogResult]::OK) { $dialog.Dispose(); return }
    $selectedPath = $pathBox.Text.Trim().Trim('"')
    if ([string]::IsNullOrWhiteSpace($nameBox.Text) -or [string]::IsNullOrWhiteSpace($categoryBox.Text) -or
        -not (Test-Path -LiteralPath $selectedPath -PathType Leaf) -or
        [IO.Path]::GetExtension($selectedPath) -notin @('.exe','.ps1')) {
        [System.Windows.Forms.MessageBox]::Show('Enter an app name and category, and select an existing .exe or .ps1 file.', 'Invalid custom app', 'OK', 'Warning') | Out-Null
        $dialog.Dispose(); return
    }
    $selectedPath = [IO.Path]::GetFullPath($selectedPath)
    if ($script:CustomApps | Where-Object { $_.File.Equals($selectedPath, [StringComparison]::OrdinalIgnoreCase) }) {
        [System.Windows.Forms.MessageBox]::Show('That app is already in the custom apps list.', 'Already added', 'OK', 'Information') | Out-Null
        $dialog.Dispose(); return
    }
    $custom = [pscustomobject]@{ Name=$nameBox.Text.Trim(); Category=$categoryBox.Text.Trim(); File=$selectedPath; Kind='Custom'; Description=$descriptionBox.Text.Trim(); Arguments=$argsBox.Text.Trim(); IsCustom=$true }
    $script:CustomApps += $custom
    $script:Items = @($script:Items) + @($custom)
    $newCategories = @('All') + @($script:Items | Select-Object -ExpandProperty Category -Unique | Sort-Object)
    $categoryCombo.Items.Clear()
    [void]$categoryCombo.Items.AddRange([string[]]$newCategories)
    if ($script:Settings.Category -notin $newCategories) { $script:Settings.Category = 'All' }
    $categoryCombo.SelectedItem = $script:Settings.Category
    Save-HubSettings
    Update-ToolCards
    $status.Text = "Added custom app: $($custom.Name)"
    $dialog.Dispose()
}

function Get-EffectiveTheme {
    if ($themeCombo.SelectedItem -ne 'System') { return [string]$themeCombo.SelectedItem }
    try {
        $value = Get-ItemPropertyValue -LiteralPath 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize' -Name AppsUseLightTheme -ErrorAction Stop
        if ($value -eq 1) { return 'Light' }
    } catch { }
    return 'Dark'
}

function Set-HubTheme {
    $themeName = Get-EffectiveTheme
    $palette = $script:ThemeColors[$themeName]
    $form.BackColor = $palette.Form; $form.ForeColor = $palette.Fore
    $header.BackColor = $palette.Panel; $footer.BackColor = $palette.Panel
    $searchPanel.BackColor = $palette.Form; $toolbar.BackColor = $palette.Panel
    $body.BackColor = $palette.Form; $list.BackColor = $palette.Form
    $search.BackColor = $palette.Input; $search.ForeColor = $palette.Fore
    $status.ForeColor = $palette.Fore; $title.ForeColor = $palette.Accent
    $subtitle.ForeColor = $palette.Muted
    foreach ($control in @($themeLabel, $categoryLabel, $sizeLabel, $topMostCheck)) { $control.ForeColor = $palette.Fore }
    $script:ActivePalette = $palette
    Update-ToolCards
}

function Update-ToolCards {
    $list.SuspendLayout()
    $list.Controls.Clear()
    $query = $search.Text.Trim()
    $category = [string]$categoryCombo.SelectedItem
    $shown = @($script:Items | Where-Object {
        (($category -eq 'All') -or ($_.Category -eq $category)) -and
        (-not $query -or $_.Name.IndexOf($query, [StringComparison]::OrdinalIgnoreCase) -ge 0 -or
         $_.Category.IndexOf($query, [StringComparison]::OrdinalIgnoreCase) -ge 0 -or
         $_.Description.IndexOf($query, [StringComparison]::OrdinalIgnoreCase) -ge 0)
    })
    $cardWidth = switch ([string]$sizeCombo.SelectedItem) { 'Compact' { 240 } 'Large' { 340 } default { 292 } }
    $cardHeight = switch ([string]$sizeCombo.SelectedItem) { 'Compact' { 112 } 'Large' { 150 } default { 125 } }
    foreach ($tool in $shown) {
        $card = New-Object System.Windows.Forms.Panel
        $card.Width = $cardWidth
        $card.Height = $cardHeight
        $card.Margin = New-Object System.Windows.Forms.Padding(8)
        $card.BackColor = $script:ActivePalette.Card
        $label = New-Object System.Windows.Forms.Label
        $label.Text = "$($tool.Name)  |  $($tool.Category)"
        $label.Location = New-Object System.Drawing.Point(12, 10)
        $label.Size = New-Object System.Drawing.Size(($cardWidth - 27), 25)
        $label.Font = New-Object System.Drawing.Font('Segoe UI Semibold', 10, [System.Drawing.FontStyle]::Bold)
        $label.ForeColor = $script:ActivePalette.Accent
        $card.Controls.Add($label)
        $desc = New-Object System.Windows.Forms.Label
        $desc.Text = $tool.Description
        $desc.Location = New-Object System.Drawing.Point(12, 38)
        $desc.Size = New-Object System.Drawing.Size(($cardWidth - 27), ($cardHeight - 82))
        $desc.ForeColor = $script:ActivePalette.Muted
        $card.Controls.Add($desc)
        $button = New-Object System.Windows.Forms.Button
        $button.Text = 'Open tool'
        $button.Location = New-Object System.Drawing.Point(12, ($cardHeight - 36))
        $button.Size = New-Object System.Drawing.Size(($cardWidth - 27), 28)
        $button.FlatStyle = 'Flat'
        $button.BackColor = $script:ActivePalette.Button
        $button.ForeColor = $script:ActivePalette.Fore
        $button.Cursor = [System.Windows.Forms.Cursors]::Hand
        if ($tool.IsCustom) {
            $context = New-Object System.Windows.Forms.ContextMenuStrip
            $removeItem = $context.Items.Add('Remove custom app')
            $capturedForRemove = $tool
            $removeItem.Add_Click({
                $script:CustomApps = @($script:CustomApps | Where-Object { -not $_.File.Equals($capturedForRemove.File, [StringComparison]::OrdinalIgnoreCase) })
                $script:Items = @($script:Items | Where-Object { -not ($_.IsCustom -and $_.File.Equals($capturedForRemove.File, [StringComparison]::OrdinalIgnoreCase)) })
                $newCategories = @('All') + @($script:Items | Select-Object -ExpandProperty Category -Unique | Sort-Object)
                $categoryCombo.Items.Clear()
                [void]$categoryCombo.Items.AddRange([string[]]$newCategories)
                if ($script:Settings.Category -notin $newCategories) { $script:Settings.Category = 'All' }
                $categoryCombo.SelectedItem = $script:Settings.Category
                Save-HubSettings
                Update-ToolCards
            }.GetNewClosure())
            $button.ContextMenuStrip = $context
        }
        $capturedTool = $tool
        if ($capturedTool.Kind -eq 'Converter') {
            $button.Add_Click({ Start-ThemeConverter }.GetNewClosure())
        } else {
            $button.Add_Click({ Start-Tool -Tool $capturedTool }.GetNewClosure())
        }
        $card.Controls.Add($button)
        $list.Controls.Add($card)
    }
    $list.ResumeLayout()
    $status.Text = "$($shown.Count) tool(s) available"
}

$addCustomApp.Add_Click({ Show-AddCustomAppDialog })
$search.Add_TextChanged({ Update-ToolCards })
$categoryCombo.Add_SelectedIndexChanged({ Save-HubSettings; Update-ToolCards })
$sizeCombo.Add_SelectedIndexChanged({ Save-HubSettings; Update-ToolCards })
$themeCombo.Add_SelectedIndexChanged({ Save-HubSettings; Set-HubTheme })
$topMostCheck.Add_CheckedChanged({ $form.TopMost = $topMostCheck.Checked; Save-HubSettings })
$form.Add_FormClosing({ Save-HubSettings })
$form.Add_KeyDown({ if ($_.Control -and $_.KeyCode -eq [System.Windows.Forms.Keys]::F) { $search.Focus() } })
Set-HubTheme
if ($SmokeTest) {
    $smokeTimer = New-Object System.Windows.Forms.Timer
    $smokeTimer.Interval = 1200
    $smokeTimer.Add_Tick({ $smokeTimer.Stop(); $form.Close() })
    $form.Add_Shown({ $smokeTimer.Start() })
}
[void]$form.ShowDialog()
if ($smokeTimer) { $smokeTimer.Dispose() }
