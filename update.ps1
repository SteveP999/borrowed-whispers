$ErrorActionPreference = "Stop"

$RepoName = "borrowed-whispers"
$RepoUrl = "https://github.com/SteveP999/borrowed-whispers.git"
$LogPath = Join-Path $PSScriptRoot "update-log.txt"

function Write-Both($Text) {
    Write-Host $Text
    Add-Content -Path $LogPath -Value $Text
}

Set-Content -Path $LogPath -Value @(
"==========================================",
"HTR Update - $RepoName",
"==========================================",
"Running from: $PSScriptRoot",
""
)

try {
    Set-Location $PSScriptRoot
    Write-Both "Checking Git..."
    $git = Get-Command git -ErrorAction SilentlyContinue
    if (-not $git) { throw "Git is not installed or not available in PATH." }

    if (-not (Test-Path ".git")) {
        Write-Both "No .git folder found. Initializing repo..."
        git init | Tee-Object -FilePath $LogPath -Append
        git branch -M main | Tee-Object -FilePath $LogPath -Append
        git remote add origin $RepoUrl | Tee-Object -FilePath $LogPath -Append
    } else {
        Write-Both "Existing .git folder found."
        $remote = ""
        try { $remote = git remote get-url origin } catch { $remote = "" }
        if ([string]::IsNullOrWhiteSpace($remote)) {
            Write-Both "No origin remote found. Adding origin..."
            git remote add origin $RepoUrl | Tee-Object -FilePath $LogPath -Append
        } elseif ($remote.Trim() -ne $RepoUrl) {
            Write-Both "Origin remote is wrong. Replacing it."
            git remote set-url origin $RepoUrl | Tee-Object -FilePath $LogPath -Append
        }
        git branch -M main | Tee-Object -FilePath $LogPath -Append
    }

    Write-Both ""
    Write-Both "Fetching remote..."
    git fetch origin main | Tee-Object -FilePath $LogPath -Append

    Write-Both ""
    Write-Both "Syncing remote before commit..."
    git pull origin main --allow-unrelated-histories --no-rebase -X ours | Tee-Object -FilePath $LogPath -Append

    Write-Both ""
    Write-Both "Making update-log.txt local-only going forward..."
    Set-Content -Path ".gitignore" -Value "update-log.txt"

    Write-Both ""
    Write-Both "Staging files..."
    git add -A | Tee-Object -FilePath $LogPath -Append

    Write-Both ""
    Write-Both "Git status:"
    git status | Tee-Object -FilePath $LogPath -Append

    $changes = git status --porcelain
    if ($changes) {
        Write-Both ""
        $msg = Read-Host "Commit message (Enter = update artist site)"
        if ([string]::IsNullOrWhiteSpace($msg)) { $msg = "update artist site" }
        Write-Both "Committing..."
        git commit -m $msg | Tee-Object -FilePath $LogPath -Append
    } else {
        Write-Both "No changes to commit."
    }

    Write-Both ""
    Write-Both "Pushing to GitHub..."
    git push -u origin main | Tee-Object -FilePath $LogPath -Append
    Write-Both ""
    Write-Both "SUCCESS: $RepoName pushed to GitHub."
}
catch {
    Write-Both ""
    Write-Both "ERROR:"
    Write-Both $_.Exception.Message
    Write-Both ""
    Write-Both "See update-log.txt in this folder."
}
Write-Host ""
Read-Host "Press Enter to close"
