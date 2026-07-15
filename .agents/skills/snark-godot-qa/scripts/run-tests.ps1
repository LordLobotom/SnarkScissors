[CmdletBinding()]
param(
    [ValidateSet("all", "ui")]
    [string]$Suite = "all",
    [string]$GodotPath = "",
    [string]$CapturePath = "",
    [ValidateSet("menu", "settings", "game")]
    [string]$CaptureView = "game",
    [string]$CaptureSize = "1280x720",
    [switch]$SkipImport
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..\..\..")).Path

function Resolve-GodotExecutable {
    if ($GodotPath) {
        if (-not (Test-Path -LiteralPath $GodotPath -PathType Leaf)) {
            throw "Godot executable not found: $GodotPath"
        }
        return (Resolve-Path -LiteralPath $GodotPath).Path
    }

    foreach ($commandName in @("godot4", "godot")) {
        $command = Get-Command $commandName -ErrorAction SilentlyContinue
        if ($null -ne $command) {
            return $command.Source
        }
    }

    $godotDirectory = Join-Path (Split-Path $repoRoot -Parent) "Godot"
    if (Test-Path -LiteralPath $godotDirectory -PathType Container) {
        $candidate = Get-ChildItem -LiteralPath $godotDirectory -File |
            Where-Object { $_.Name -match '^Godot.*_console\.exe$' } |
            Sort-Object Name -Descending |
            Select-Object -First 1
        if ($null -ne $candidate) {
            return $candidate.FullName
        }
    }

    throw "Godot was not found on PATH or in the sibling Godot directory. Pass -GodotPath."
}

function ConvertTo-ProcessArgumentLine {
    param([string[]]$Arguments)

    return (($Arguments | ForEach-Object {
        '"' + $_.Replace('"', '\"') + '"'
    }) -join " ")
}

function Assert-CleanGodotOutput {
    param(
        [string]$Label,
        [string]$Output
    )

    if ($Output -match '(?m)SCRIPT ERROR:|Parse Error:') {
        throw "$Label reported a GDScript error."
    }
}

function Invoke-GodotCheck {
    param(
        [string]$Label,
        [string[]]$Arguments,
        [string]$ExpectedMarker = "",
        [hashtable]$Environment = @{},
        [int]$TimeoutSeconds = 60
    )

    $startInfo = New-Object System.Diagnostics.ProcessStartInfo
    $startInfo.FileName = $script:GodotExecutable
    $startInfo.Arguments = ConvertTo-ProcessArgumentLine -Arguments $Arguments
    $startInfo.UseShellExecute = $false
    $startInfo.CreateNoWindow = $true
    $startInfo.RedirectStandardOutput = $true
    $startInfo.RedirectStandardError = $true
    foreach ($name in $Environment.Keys) {
        $startInfo.EnvironmentVariables[$name] = [string]$Environment[$name]
    }

    $process = New-Object System.Diagnostics.Process
    $process.StartInfo = $startInfo
    try {
        Write-Host "`n[$Label]"
        if (-not $process.Start()) {
            throw "Could not start $Label."
        }
        $standardOutput = $process.StandardOutput.ReadToEndAsync()
        $standardError = $process.StandardError.ReadToEndAsync()
        if (-not $process.WaitForExit($TimeoutSeconds * 1000)) {
            $process.Kill()
            throw "$Label timed out after $TimeoutSeconds seconds."
        }
        $output = $standardOutput.Result + $standardError.Result
        if ($output.Trim()) {
            Write-Host $output.TrimEnd()
        }

        if ($process.ExitCode -ne 0) {
            throw "$Label failed with exit code $($process.ExitCode)."
        }
        Assert-CleanGodotOutput -Label $Label -Output $output
        if ($ExpectedMarker -and $output -notmatch [regex]::Escape($ExpectedMarker)) {
            throw "$Label did not print $ExpectedMarker."
        }
    }
    finally {
        if (-not $process.HasExited) {
            $process.Kill()
        }
        $process.Dispose()
    }
}

$script:GodotExecutable = Resolve-GodotExecutable
Write-Host "Godot: $script:GodotExecutable"
Write-Host "Project: $repoRoot"

if (-not $SkipImport) {
    Invoke-GodotCheck -Label "Project load" -Arguments @(
        "--headless", "--editor", "--path", $repoRoot, "--quit"
    )
}

if ($Suite -in @("all", "ui")) {
    $environment = @{ "SNARK_QA" = "1" }
    if ($CapturePath) {
        if ($CaptureSize -notmatch '^\d+x\d+$') {
            throw "CaptureSize must use WIDTHxHEIGHT, for example 390x844."
        }
        $resolvedCapturePath = if ([IO.Path]::IsPathRooted($CapturePath)) {
            [IO.Path]::GetFullPath($CapturePath)
        }
        else {
            [IO.Path]::GetFullPath((Join-Path $repoRoot $CapturePath))
        }
        $captureDirectory = Split-Path $resolvedCapturePath -Parent
        New-Item -ItemType Directory -Path $captureDirectory -Force | Out-Null
        $environment["SNARK_CAPTURE_PATH"] = $resolvedCapturePath
        $environment["SNARK_CAPTURE_VIEW"] = $CaptureView
        $environment["SNARK_CAPTURE_SIZE"] = $CaptureSize
    }

    $uiArguments = @("--path", $repoRoot, "--scene", "res://tests/UISmoke.tscn")
    if (-not $CapturePath) {
        $uiArguments = @("--headless") + $uiArguments
    }
    Invoke-GodotCheck -Label "UI and gameplay smoke" -Arguments $uiArguments `
        -ExpectedMarker "UI_SMOKE_OK" -Environment $environment

    Invoke-GodotCheck -Label "Background music smoke" -Arguments @(
        "--headless", "--path", $repoRoot, "--scene", "res://tests/AudioSmoke.tscn"
    ) -ExpectedMarker "AUDIO_SMOKE_OK"

    if ($CapturePath) {
        $capture = Get-Item -LiteralPath $resolvedCapturePath -ErrorAction Stop
        if ($capture.Length -eq 0) {
            throw "UI capture is empty: $resolvedCapturePath"
        }
        Write-Host "UI capture ($CaptureView, $CaptureSize): $resolvedCapturePath"
    }
}

Write-Host "`nSNARK_QA_OK"
