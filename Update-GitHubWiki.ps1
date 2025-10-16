#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Updates the GitHub Wiki Home.md with links to all documentation from the main repository.

.DESCRIPTION
    This script scans the main Fellows-Associates repository for markdown files,
    then updates the GitHub Wiki Home.md file with properly formatted links.
    The wiki repository must be cloned separately (Fellows-Associates.wiki).

.PARAMETER RepoRoot
    The root directory of the main repository. Defaults to the script's parent directory.

.PARAMETER WikiRoot
    The root directory of the wiki repository. Auto-detected or can be specified.

.PARAMETER DryRun
    If specified, shows what would be changed without actually modifying the wiki.

.EXAMPLE
    .\Update-GitHubWiki.ps1
    Updates the GitHub Wiki Home.md with all documentation links

.EXAMPLE
    .\Update-GitHubWiki.ps1 -DryRun
    Preview changes without modifying the wiki

.EXAMPLE
    .\Update-GitHubWiki.ps1 -WikiRoot "C:\Path\To\Fellows-Associates.wiki"
    Specify custom wiki repository location
#>

[CmdletBinding()]
param(
    [Parameter()]
    [string]$RepoRoot = $PSScriptRoot,

    [Parameter()]
    [string]$WikiRoot,

    [Parameter()]
    [switch]$DryRun,

    [Parameter()]
    [switch]$AutoCommit
)

# Color output functions
function Write-Info {
    param([string]$Message)
    Write-Host "ℹ️  $Message" -ForegroundColor Cyan
}

function Write-Success {
    param([string]$Message)
    Write-Host "✓ $Message" -ForegroundColor Green
}

function Write-Warning {
    param([string]$Message)
    Write-Host "⚠️  $Message" -ForegroundColor Yellow
}

function Write-Error {
    param([string]$Message)
    Write-Host "✗ $Message" -ForegroundColor Red
}

# Function to find wiki repository
function Find-WikiRepository {
    param([string]$RepoRoot)

    $possiblePaths = @(
        (Join-Path (Split-Path $RepoRoot -Parent) "Fellows-Associates.wiki"),
        (Join-Path $RepoRoot ".wiki"),
        (Join-Path $RepoRoot "wiki")
    )

    foreach ($path in $possiblePaths) {
        if (Test-Path $path) {
            $gitPath = Join-Path $path ".git"
            if (Test-Path $gitPath) {
                return $path
            }
        }
    }

    return $null
}

# Function to get GitHub URL for file
function Get-GitHubFileUrl {
    param(
        [string]$FilePath,
        [string]$RepoRoot
    )

    $relativePath = $FilePath.Substring($RepoRoot.Length + 1)
    $urlPath = $relativePath -replace '\\', '/'
    $urlPath = [System.Uri]::EscapeDataString($urlPath) -replace '%2F', '/'

    return "https://github.com/rfellows-ops/Fellows-Associates/blob/main/$urlPath"
}

# Function to extract title from markdown file
function Get-MarkdownTitle {
    param([string]$FilePath)

    try {
        $content = Get-Content $FilePath -First 10 -ErrorAction Stop
        $h1 = $content | Where-Object { $_ -match '^#\s+(.+)$' } | Select-Object -First 1

        if ($h1) {
            if ($h1 -match '^#\s+(.+)$') {
                return $Matches[1].Trim()
            }
        }

        return [System.IO.Path]::GetFileNameWithoutExtension($FilePath)
    }
    catch {
        return [System.IO.Path]::GetFileNameWithoutExtension($FilePath)
    }
}

# Function to categorize files
function Get-FileCategories {
    param([array]$Files, [string]$RepoRoot)

    $categories = @{}

    foreach ($file in $Files) {
        $relativePath = $file.FullName.Substring($RepoRoot.Length + 1)
        $pathParts = $relativePath -split '\\'

        if ($pathParts[0] -eq "DO") {
            $category = "DigitalOcean Guides"
            $subcategory = if ($pathParts.Length -gt 2) {
                $pathParts[1] -replace '-', ' ' -replace '_', ' '
            } else { "General" }
        }
        elseif ($pathParts[0] -eq "Markdown" -and $pathParts.Length -gt 2) {
            $category = "Applications"
            $subcategory = $pathParts[1]
        }
        else {
            $category = "Documentation"
            $subcategory = "General"
        }

        if (-not $categories.ContainsKey($category)) {
            $categories[$category] = @{}
        }

        if (-not $categories[$category].ContainsKey($subcategory)) {
            $categories[$category][$subcategory] = @()
        }

        $categories[$category][$subcategory] += $file
    }

    return $categories
}

# Main script execution
try {
    Write-Info "Starting GitHub Wiki update..."
    Write-Info "Main repository: $RepoRoot"

    # Validate main repository
    if (-not (Test-Path $RepoRoot)) {
        Write-Error "Repository root not found: $RepoRoot"
        exit 1
    }

    # Find or validate wiki repository
    if (-not $WikiRoot) {
        Write-Info "Auto-detecting wiki repository..."
        $WikiRoot = Find-WikiRepository -RepoRoot $RepoRoot

        if (-not $WikiRoot) {
            Write-Error "Wiki repository not found!"
            Write-Host ""
            Write-Host "To clone the wiki repository, run:" -ForegroundColor Yellow
            Write-Host "  cd $(Split-Path $RepoRoot -Parent)" -ForegroundColor White
            Write-Host "  git clone https://github.com/rfellows-ops/Fellows-Associates.wiki.git" -ForegroundColor White
            exit 1
        }
    }

    if (-not (Test-Path $WikiRoot)) {
        Write-Error "Wiki repository not found at: $WikiRoot"
        exit 1
    }

    $wikiHome = Join-Path $WikiRoot "Home.md"
    Write-Success "Found wiki repository: $WikiRoot"

    # Find all markdown files in main repository
    Write-Info "Scanning for documentation files..."

    $markdownFiles = Get-ChildItem -Path $RepoRoot -Filter "*.md" -Recurse -File |
        Where-Object {
            $_.Name -ne "Home.md" -and
            $_.Name -ne "README.md" -and
            $_.Name -ne "QUICK-START.md" -and
            $_.FullName -notlike "*\.git\*" -and
            $_.FullName -notlike "*\node_modules\*"
        }

    Write-Success "Found $($markdownFiles.Count) documentation file(s)"

    if ($markdownFiles.Count -eq 0) {
        Write-Warning "No documentation files found to link."
    }

    # Organize files by category
    Write-Info "Organizing documentation by category..."
    $categories = Get-FileCategories -Files $markdownFiles -RepoRoot $RepoRoot

    # Generate wiki Home.md content
    Write-Info "Generating wiki content..."

    $wikiContent = @()
    $wikiContent += "# Welcome to the Fellows & Associates Wiki!"
    $wikiContent += ""
    $wikiContent += "This is where the documentation and help for the various applications and services are maintained."
    $wikiContent += ""
    $wikiContent += "> **Last Updated:** $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    $wikiContent += ""
    $wikiContent += "---"
    $wikiContent += ""

    # Generate sections for each category
    foreach ($category in ($categories.Keys | Sort-Object)) {
        $wikiContent += "## $category"
        $wikiContent += ""

        foreach ($subcategory in ($categories[$category].Keys | Sort-Object)) {
            $files = $categories[$category][$subcategory]

            if ($files.Count -gt 1 -or $subcategory -ne "General") {
                $wikiContent += "### $subcategory"
                $wikiContent += ""
            }

            foreach ($file in ($files | Sort-Object Name)) {
                $title = Get-MarkdownTitle -FilePath $file.FullName
                $url = Get-GitHubFileUrl -FilePath $file.FullName -RepoRoot $RepoRoot

                # Get brief description
                $description = ""
                try {
                    $content = Get-Content $file.FullName -First 20
                    $descLine = $content | Where-Object {
                        $_ -match '^(This|A |An ).*\.' -and $_ -notmatch '^#'
                    } | Select-Object -First 1

                    if ($descLine) {
                        $description = " - $($descLine.Trim())"
                    }
                }
                catch {
                    # Ignore
                }

                $wikiContent += "- [$title]($url)$description"
            }

            $wikiContent += ""
        }

        $wikiContent += "---"
        $wikiContent += ""
    }

    # Add footer
    $wikiContent += "## Contributing"
    $wikiContent += ""
    $wikiContent += "To add or update documentation:"
    $wikiContent += ""
    $wikiContent += "1. Create or edit markdown files in the [main repository](https://github.com/rfellows-ops/Fellows-Associates)"
    $wikiContent += "2. Run ``Update-GitHubWiki.ps1`` to update this wiki page"
    $wikiContent += "3. Commit and push changes to both repositories"
    $wikiContent += ""

    # Show preview in dry run mode
    if ($DryRun) {
        Write-Warning "DRY RUN MODE - No changes will be made"
        Write-Host ""
        Write-Info "Generated wiki content preview:"
        Write-Host "========================================" -ForegroundColor DarkGray
        $wikiContent | ForEach-Object { Write-Host $_ -ForegroundColor Gray }
        Write-Host "========================================" -ForegroundColor DarkGray
        exit 0
    }

    # Write to wiki Home.md
    Write-Info "Writing to wiki Home.md..."
    $wikiContent | Out-File -FilePath $wikiHome -Encoding UTF8 -Force

    Write-Success "Wiki Home.md has been successfully updated!"
    Write-Info "Updated file: $wikiHome"

    # Auto-commit if requested
    if ($AutoCommit) {
        Write-Info "Committing and pushing wiki changes..."

        Push-Location $WikiRoot
        try {
            git add Home.md
            git commit -m "Update wiki home with latest documentation (auto-generated)"
            git push

            Write-Success "Wiki changes have been pushed to GitHub!"
            Write-Host ""
            Write-Host "View your wiki at:" -ForegroundColor Cyan
            Write-Host "  https://github.com/rfellows-ops/Fellows-Associates/wiki" -ForegroundColor White
        }
        catch {
            Write-Error "Failed to commit/push wiki changes: $_"
        }
        finally {
            Pop-Location
        }
    }
    else {
        Write-Host ""
        Write-Warning "Changes have been made to the wiki repository but not committed."
        Write-Host "To push changes to GitHub, run:" -ForegroundColor Yellow
        Write-Host "  cd $WikiRoot" -ForegroundColor White
        Write-Host "  git add Home.md" -ForegroundColor White
        Write-Host "  git commit -m `"Update wiki home`"" -ForegroundColor White
        Write-Host "  git push" -ForegroundColor White
        Write-Host ""
        Write-Host "Or re-run with -AutoCommit flag to do this automatically." -ForegroundColor Yellow
    }

    Write-Host ""
    Write-Host "Summary:" -ForegroundColor Cyan
    Write-Host "  • Linked $($markdownFiles.Count) file(s)" -ForegroundColor White
    Write-Host "  • Across $($categories.Keys.Count) category(ies)" -ForegroundColor White
    Write-Host "  • Wiki location: $WikiRoot" -ForegroundColor White

}
catch {
    Write-Error "An error occurred: $_"
    Write-Error $_.Exception.Message
    exit 1
}
