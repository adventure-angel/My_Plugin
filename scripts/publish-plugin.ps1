param(
    [Parameter(Mandatory = $true)][string]$Source,
    [Parameter(Mandatory = $true)][ValidatePattern('^[a-zA-Z0-9][a-zA-Z0-9._-]*$')][string]$Name,
    [string]$RepoPath = '.',
    [switch]$Publish
)

$ErrorActionPreference = 'Stop'
function Run-Git([string[]]$Arguments) {
    & git -C $repoRoot @Arguments
    if ($LASTEXITCODE -ne 0) { throw "git $($Arguments -join ' ') failed ($LASTEXITCODE)" }
}

if (-not (Get-Command git -ErrorAction SilentlyContinue)) { throw 'Git is not installed or not on PATH.' }
$sourceRoot = (Resolve-Path -LiteralPath $Source).Path.TrimEnd('\')
$repoRoot = (Resolve-Path -LiteralPath $RepoPath).Path.TrimEnd('\')
$gitRoot = (& git -C $repoRoot rev-parse --show-toplevel 2>$null)
if ($LASTEXITCODE -ne 0 -or -not $gitRoot) { throw 'RepoPath must be a Git working tree.' }
if (-not [string]::Equals([IO.Path]::GetFullPath($gitRoot).TrimEnd('\'), [IO.Path]::GetFullPath($repoRoot), [StringComparison]::OrdinalIgnoreCase)) {
    throw 'Run this script with RepoPath set to the repository root.'
}
if (& git -C $repoRoot status --porcelain) { throw 'The repository has uncommitted changes. Commit or discard them first.' }

$target = [IO.Path]::GetFullPath((Join-Path $repoRoot $Name))
$repoPrefix = [IO.Path]::GetFullPath($repoRoot).TrimEnd('\') + '\'
if (-not $target.StartsWith($repoPrefix, [StringComparison]::OrdinalIgnoreCase)) { throw 'Target escapes the repository.' }
if ($sourceRoot.StartsWith($target + '\', [StringComparison]::OrdinalIgnoreCase) -or [string]::Equals($sourceRoot, $target, [StringComparison]::OrdinalIgnoreCase)) {
    throw 'Source cannot be inside the target folder.'
}
if ($target.StartsWith($sourceRoot + '\', [StringComparison]::OrdinalIgnoreCase)) { throw 'Target cannot be inside Source.' }

$skipDirs = @('.git', '.venv', 'venv', 'node_modules', '__pycache__', '.pytest_cache', '.mypy_cache', '.idea', '.vscode')
$blockedNames = '(?i)^(\.env($|\.)|.*\.token$|.*\.pem$|.*\.p12$|id_rsa.*|credentials?\..*|secrets?\..*)$'
$secretPattern = 'github_pat_[A-Za-z0-9_]{20,}|ghp_[A-Za-z0-9]{20,}|sk-[A-Za-z0-9]{20,}|C:\\Users\\[^\\\r\n]+\\'
$files = New-Object 'System.Collections.Generic.List[System.IO.FileInfo]'
function Visit([string]$dir) {
    foreach ($item in Get-ChildItem -LiteralPath $dir -Force) {
        if ($item.Attributes -band [IO.FileAttributes]::ReparsePoint) { throw "Symlink/reparse point needs manual review: $($item.FullName)" }
        if ($item.PSIsContainer) {
            if ($skipDirs -contains $item.Name) { continue }
            Visit $item.FullName
        } else {
            if ($item.Name -match $blockedNames) { throw "Sensitive filename needs review: $($item.FullName)" }
            if ($item.Extension -in @('.pyc', '.pyo', '.log', '.tmp')) { continue }
            $files.Add($item)
        }
    }
}
Visit $sourceRoot
if ($files.Count -eq 0) { throw 'No publishable files found.' }
foreach ($file in $files) {
    if ($file.Length -gt 0 -and $file.Length -lt 2MB -and $file.Extension -in @('.md','.txt','.py','.js','.cjs','.mjs','.ts','.json','.yaml','.yml','.ps1','.toml','.xml','.html','.css')) {
        $body = [IO.File]::ReadAllText($file.FullName)
        if ($body -match $secretPattern) { throw "Potential credential or personal path needs review: $($file.FullName)" }
    }
}

if (-not $Publish) {
    Write-Host "Preview: $($files.Count) files would be copied to $Name."
    $files | ForEach-Object { $_.FullName.Substring($sourceRoot.Length).TrimStart('\') }
    Write-Host 'No repository files were changed. Add -Publish to copy, commit and push.'
    return
}

if (Test-Path -LiteralPath $target) { Remove-Item -LiteralPath $target -Recurse -Force }
New-Item -ItemType Directory -Path $target -Force | Out-Null
foreach ($file in $files) {
    $relative = $file.FullName.Substring($sourceRoot.Length).TrimStart('\')
    $dest = Join-Path $target $relative
    New-Item -ItemType Directory -Path (Split-Path -Parent $dest) -Force | Out-Null
    Copy-Item -LiteralPath $file.FullName -Destination $dest
}
Run-Git -Arguments @('add', '--', $Name)
Run-Git -Arguments @('diff', '--cached', '--stat', '--', $Name)
Write-Host "Prepared $($files.Count) files in $Name."
if (-not (& git -C $repoRoot diff --cached --name-only -- $Name)) { throw 'No changes to publish.' }
Run-Git -Arguments @('commit', '-m', "Publish $Name")
Run-Git -Arguments @('push')
Write-Host 'Pushed. Open GitHub and verify the published files.'

