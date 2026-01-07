# Cleanup script for all CodingWithCalvin repositories
# Switches to main/master, pulls latest, and deletes all other local branches

$rootPath = "C:\code\personal\CodingWithCalvin"

# Find all git repositories recursively
$repos = Get-ChildItem -Path $rootPath -Directory -Recurse -Force |
    Where-Object { Test-Path (Join-Path $_.FullName ".git") } |
    Select-Object -ExpandProperty FullName

Write-Host "Found $($repos.Count) repositories to process`n" -ForegroundColor Cyan

foreach ($repo in $repos) {
    Write-Host "Processing: $repo" -ForegroundColor Yellow
    Push-Location $repo

    try {
        # Determine the default branch (main or master)
        $defaultBranch = $null
        $localBranches = git branch --list 2>$null | ForEach-Object { $_.Trim().TrimStart("* ") }

        if ($localBranches -contains "main") {
            $defaultBranch = "main"
        } elseif ($localBranches -contains "master") {
            $defaultBranch = "master"
        } else {
            # Check remote for default branch
            $remoteDefault = git symbolic-ref refs/remotes/origin/HEAD 2>$null
            if ($remoteDefault -match "origin/(.+)$") {
                $defaultBranch = $Matches[1]
            }
        }

        if (-not $defaultBranch) {
            Write-Host "  Skipping: Could not determine default branch" -ForegroundColor Red
            Pop-Location
            Write-Host ""
            continue
        }

        Write-Host "  Default branch: $defaultBranch" -ForegroundColor Gray

        # Get current branch
        $currentBranch = git branch --show-current 2>$null

        # Switch to default branch if not already there
        if ($currentBranch -ne $defaultBranch) {
            Write-Host "  Switching to $defaultBranch..." -ForegroundColor Gray
            git checkout $defaultBranch 2>&1 | Out-Null
        }

        # Pull latest
        Write-Host "  Pulling latest..." -ForegroundColor Gray
        $pullResult = git pull 2>&1
        if ($LASTEXITCODE -ne 0) {
            Write-Host "  Warning: Pull failed - $pullResult" -ForegroundColor Red
        }

        # Get all local branches except the default branch
        $branches = git branch --list |
            ForEach-Object { $_.Trim().TrimStart("* ") } |
            Where-Object { $_ -ne $defaultBranch -and $_ -ne "" }

        if ($branches) {
            $deletedCount = 0
            foreach ($branch in $branches) {
                # Check if remote branch exists
                $remoteBranch = git ls-remote --heads origin $branch 2>$null
                if ($remoteBranch) {
                    Write-Host "  Keeping branch: $branch (remote still exists)" -ForegroundColor Cyan
                } else {
                    Write-Host "  Deleting branch: $branch" -ForegroundColor Magenta
                    git branch -D $branch 2>&1 | Out-Null
                    $deletedCount++
                }
            }
            if ($deletedCount -gt 0) {
                Write-Host "  Deleted $deletedCount branch(es)" -ForegroundColor Green
            } else {
                Write-Host "  No branches deleted (all have remotes)" -ForegroundColor Gray
            }
        } else {
            Write-Host "  No other branches to delete" -ForegroundColor Gray
        }
    }
    catch {
        Write-Host "  Error: $_" -ForegroundColor Red
    }
    finally {
        Pop-Location
    }

    Write-Host ""
}

Write-Host "Done!" -ForegroundColor Cyan
