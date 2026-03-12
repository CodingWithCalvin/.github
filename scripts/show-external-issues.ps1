# Show all open issues across CodingWithCalvin organization's public repositories
# that were opened by someone other than the authenticated user
#
# Usage:
#   .\show-external-issues.ps1
#

$ErrorActionPreference = "Stop"
$Org = "CodingWithCalvin"

# Get the authenticated user's login
$me = gh api user --jq '.login'

Write-Host "Fetching open issues across $Org public repositories (excluding yours, $me)..." -ForegroundColor Cyan
Write-Host ""

# Get all open issues across the org using gh search
$issues = gh search issues --owner $Org --state open --json repository,number,title,author,createdAt,url,body --limit 500 | ConvertFrom-Json

if (-not $issues -or $issues.Count -eq 0) {
    Write-Host "No open issues found." -ForegroundColor Yellow
    exit 0
}

# Filter out issues opened by the authenticated user
$issues = $issues | Where-Object { $_.author.login -ne $me }

if (-not $issues -or $issues.Count -eq 0) {
    Write-Host "No open issues from external contributors found." -ForegroundColor Yellow
    exit 0
}

# Column widths
$colRepo   = 30
$colTitle  = 50
$colAuthor = 15
$colAge    = 10
$colURL    = 60

# Helper to truncate/pad strings with 1 char padding on each side
function Format-Cell([string]$text, [int]$width) {
    $innerWidth = $width - 2  # Account for padding
    if ($text.Length -gt $innerWidth) {
        return " " + $text.Substring(0, $innerWidth - 3) + "..." + " "
    }
    return " " + $text.PadRight($innerWidth) + " "
}

# Build table
$hLine = "+" + ("-" * $colRepo) + "+" + ("-" * $colTitle) + "+" + ("-" * $colAuthor) + "+" + ("-" * $colAge) + "+" + ("-" * $colURL) + "+"
$totalInnerWidth = $colRepo + $colTitle + $colAuthor + $colAge + $colURL + 4  # +4 for inner separators

Write-Host $hLine
Write-Host "|" -NoNewline
Write-Host (Format-Cell "Repo" $colRepo) -NoNewline -ForegroundColor Green
Write-Host "|" -NoNewline
Write-Host (Format-Cell "Title" $colTitle) -NoNewline -ForegroundColor Green
Write-Host "|" -NoNewline
Write-Host (Format-Cell "Author" $colAuthor) -NoNewline -ForegroundColor Green
Write-Host "|" -NoNewline
Write-Host (Format-Cell "Age" $colAge) -NoNewline -ForegroundColor Green
Write-Host "|" -NoNewline
Write-Host (Format-Cell "URL" $colURL) -NoNewline -ForegroundColor Green
Write-Host "|"
Write-Host $hLine

foreach ($issue in $issues | Sort-Object { $_.repository.name }, number) {
    $age = [math]::Max(0, [math]::Floor(((Get-Date) - [datetime]$issue.createdAt).TotalDays))
    $ageText = if ($age -eq 0) { "today" } elseif ($age -eq 1) { "1 day" } else { "$age days" }

    $row = "|" + (Format-Cell $issue.repository.name $colRepo) + "|" + (Format-Cell $issue.title $colTitle) + "|" + (Format-Cell $issue.author.login $colAuthor) + "|" + (Format-Cell $ageText $colAge) + "|" + (Format-Cell $issue.url $colURL) + "|"
    Write-Host $row

    # Description rows spanning all columns (up to 3 lines)
    $desc = if ($issue.body) { ($issue.body -replace "`r?`n", " " -replace "\s+", " ").Trim() } else { "(no description)" }
    $descWidth = $totalInnerWidth - 5  # Account for padding (1) + indent (3) + padding (1)
    $maxLines = 3
    $emptyRow = "|" + (" " * $totalInnerWidth) + "|"

    # Top padding
    Write-Host $emptyRow

    for ($i = 0; $i -lt $maxLines -and $desc.Length -gt 0; $i++) {
        $isLastLine = ($i -eq $maxLines - 1) -or ($desc.Length -le $descWidth)
        if ($isLastLine -and $desc.Length -gt $descWidth) {
            $lineText = $desc.Substring(0, $descWidth - 3) + "..."
        } elseif ($desc.Length -gt $descWidth) {
            $lineText = $desc.Substring(0, $descWidth)
            $desc = $desc.Substring($descWidth)
        } else {
            $lineText = $desc
            $desc = ""
        }
        Write-Host "|" -NoNewline
        Write-Host (" " + "   " + $lineText.PadRight($descWidth) + " ") -NoNewline -ForegroundColor DarkGray
        Write-Host "|"
    }

    # Bottom padding
    Write-Host $emptyRow
    Write-Host $hLine
}
