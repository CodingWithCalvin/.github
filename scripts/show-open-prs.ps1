# Show all open PRs across CodingWithCalvin organization's public repositories
#
# Usage:
#   .\show-open-prs.ps1
#

$ErrorActionPreference = "Stop"
$Org = "CodingWithCalvin"

Write-Host "Fetching open PRs across $Org public repositories..." -ForegroundColor Cyan
Write-Host ""

# Get all open PRs across the org using gh search
$prs = gh search prs --owner $Org --state open --json repository,number,title,author,createdAt,url,body --limit 500 | ConvertFrom-Json

if (-not $prs -or $prs.Count -eq 0) {
    Write-Host "No open PRs found." -ForegroundColor Yellow
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

foreach ($pr in $prs | Sort-Object { $_.repository.name }, number) {
    $age = [math]::Max(0, [math]::Floor(((Get-Date) - [datetime]$pr.createdAt).TotalDays))
    $ageText = if ($age -eq 0) { "today" } elseif ($age -eq 1) { "1 day" } else { "$age days" }

    $row = "|" + (Format-Cell $pr.repository.name $colRepo) + "|" + (Format-Cell $pr.title $colTitle) + "|" + (Format-Cell $pr.author.login $colAuthor) + "|" + (Format-Cell $ageText $colAge) + "|" + (Format-Cell $pr.url $colURL) + "|"
    Write-Host $row

    # Description rows spanning all columns (up to 3 lines)
    $desc = if ($pr.body) { ($pr.body -replace "`r?`n", " " -replace "\s+", " ").Trim() } else { "(no description)" }
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
