#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Automatically updates the Home.md wiki file with links to all markdown files in the repository.

.DESCRIPTION
    This script scans the repository for markdown files (excluding Home.md itself),
    organizes them by directory structure, and automatically updates the Home.md file
    with properly formatted links and categories.

.PARAMETER RepoRoot
    The root directory of the repository. Defaults to the script's parent directory.

.PARAMETER HomeFile
    Path to the Home.md file. Defaults to ./Markdown/Home.md

.PARAMETER DryRun
    If specified, shows what would be changed without actually modifying Home.md

.EXAMPLE
    .\Update-WikiHome.ps1
    Updates Home.md with all markdown files found in the repository

.EXAMPLE
    .\Update-WikiHome.ps1 -DryRun
    Shows what would be updated without making changes

.EXAMPLE
    .\Update-WikiHome.ps1 -RepoRoot "C:\MyRepo"
    Updates Home.md in a specific repository location
#>

[CmdletBinding()]
param(
    [Parameter()]
    [string]$RepoRoot = $PSScriptRoot,

    [Parameter()]
    [string]$HomeFile = (Join-Path $PSScriptRoot "Markdown\Home.md"),

    [Parameter()]
    [switch]$DryRun
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

# Function to get relative path from Home.md to target file
function Get-RelativePath {
    param(
        [string]$From,
        [string]$To
    )

    $fromUri = New-Object System.Uri($From)
    $toUri = New-Object System.Uri($To)

    $relativeUri = $fromUri.MakeRelativeUri($toUri)
    $relativePath = [System.Uri]::UnescapeDataString($relativeUri.ToString())

    # Convert forward slashes and URL encode spaces
    $relativePath = $relativePath -replace '/', '\'
    $relativePath = $relativePath -replace ' ', '%20'

    return $relativePath
}

# Function to extract title from markdown file
function Get-MarkdownTitle {
    param([string]$FilePath)

    try {
        $content = Get-Content $FilePath -First 10 -ErrorAction Stop

        # Look for first H1 header
        $h1 = $content | Where-Object { $_ -match '^#\s+(.+)$' } | Select-Object -First 1

        if ($h1) {
            if ($h1 -match '^#\s+(.+)$') {
                return $Matches[1].Trim()
            }
        }

        # Fallback to filename without extension
        return [System.IO.Path]::GetFileNameWithoutExtension($FilePath)
    }
    catch {
        Write-Warning "Could not read title from $FilePath"
        return [System.IO.Path]::GetFileNameWithoutExtension($FilePath)
    }
}

# Function to categorize files by directory
function Get-FileCategories {
    param([array]$Files, [string]$RepoRoot)

    $categories = @{}

    foreach ($file in $Files) {
        $relativePath = $file.FullName.Substring($RepoRoot.Length + 1)
        $pathParts = $relativePath -split '\\'

        # Determine category based on path
        if ($pathParts[0] -eq "DO") {
            $category = "DigitalOcean"
            $subcategory = if ($pathParts.Length -gt 2) { $pathParts[1] } else { "General" }
        }
        elseif ($pathParts[0] -eq "Markdown" -and $pathParts.Length -gt 2) {
            $category = "Applications"
            $subcategory = $pathParts[1]
        }
        else {
            $category = "Other"
            $subcategory = $pathParts[0]
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

# Function to generate markdown section
function New-MarkdownSection {
    param(
        [string]$CategoryName,
        [hashtable]$Subcategories,
        [string]$HomeFilePath,
        [string]$RepoRoot
    )

    $markdown = @()
    $markdown += "## $CategoryName"
    $markdown += ""

    foreach ($subcategory in ($Subcategories.Keys | Sort-Object)) {
        $files = $Subcategories[$subcategory]

        if ($files.Count -gt 1 -or $subcategory -ne "General") {
            $markdown += "### $subcategory"
            $markdown += ""
        }

        foreach ($file in ($files | Sort-Object Name)) {
            $title = Get-MarkdownTitle -FilePath $file.FullName
            $relativePath = Get-RelativePath -From $HomeFilePath -To $file.FullName

            # Get a brief description if available
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
                # Ignore errors reading description
            }

            $markdown += "* [$title]($relativePath)$description"
        }

        $markdown += ""
    }

    return $markdown
}

# Main script execution
try {
    Write-Info "Starting wiki home update..."
    Write-Info "Repository: $RepoRoot"
    Write-Info "Home file: $HomeFile"

    # Validate paths
    if (-not (Test-Path $RepoRoot)) {
        Write-Error "Repository root not found: $RepoRoot"
        exit 1
    }

    if (-not (Test-Path $HomeFile)) {
        Write-Error "Home.md file not found: $HomeFile"
        exit 1
    }

    # Find all markdown files excluding Home.md, README.md, and .git folder
    Write-Info "Scanning for markdown files..."

    $markdownFiles = Get-ChildItem -Path $RepoRoot -Filter "*.md" -Recurse -File |
        Where-Object {
            $_.Name -ne "Home.md" -and
            $_.Name -ne "README.md" -and
            $_.Name -ne "QUICK-START.md" -and
            $_.FullName -notlike "*\.git\*"
        }

    Write-Success "Found $($markdownFiles.Count) markdown file(s)"

    if ($markdownFiles.Count -eq 0) {
        Write-Warning "No markdown files found to link. Exiting."
        exit 0
    }

    # Organize files by category
    Write-Info "Organizing files by category..."
    $categories = Get-FileCategories -Files $markdownFiles -RepoRoot $RepoRoot

    # Generate new Home.md content
    Write-Info "Generating new Home.md content..."

    $newContent = @()
    $newContent += "# Welcome to the Fellows & Associates Wiki!"
    $newContent += ""
    $newContent += "This is where I keep the documentation and help for the various applications that I am either working on or have developed."
    $newContent += ""
    $newContent += "> **Last Updated:** $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    $newContent += "> **Auto-generated by:** Update-WikiHome.ps1"
    $newContent += ""

    # Generate table of contents
    $newContent += "## Table of Contents"
    $newContent += ""
    foreach ($category in ($categories.Keys | Sort-Object)) {
        $anchor = $category.ToLower() -replace '\s+', '-'
        $newContent += "- [$category](#$anchor)"
    }
    $newContent += ""
    $newContent += "---"
    $newContent += ""

    # Generate sections for each category
    foreach ($category in ($categories.Keys | Sort-Object)) {
        $section = New-MarkdownSection -CategoryName $category -Subcategories $categories[$category] -HomeFilePath $HomeFile -RepoRoot $RepoRoot
        $newContent += $section
        $newContent += "---"
        $newContent += ""
    }

    # Add footer
    $newContent += "## Additional Resources"
    $newContent += ""
    $newContent += "For more information or to contribute, please visit the [Fellows & Associates GitHub Repository](https://github.com/rfellows-ops/Fellows-Associates)."
    $newContent += ""

    # Show preview in dry run mode
    if ($DryRun) {
        Write-Warning "DRY RUN MODE - No changes will be made"
        Write-Info "Generated content preview:"
        Write-Host "----------------------------------------"
        $newContent | ForEach-Object { Write-Host $_ -ForegroundColor Gray }
        Write-Host "----------------------------------------"
        Write-Info "Files that would be linked:"
        $markdownFiles | ForEach-Object {
            Write-Host "  • $($_.FullName.Substring($RepoRoot.Length + 1))" -ForegroundColor Gray
        }
        exit 0
    }

    # Write new content to Home.md
    Write-Info "Writing updated content to Home.md..."
    $newContent | Out-File -FilePath $HomeFile -Encoding UTF8 -Force

    Write-Success "Home.md has been successfully updated!"
    Write-Info "Linked $($markdownFiles.Count) file(s) across $($categories.Keys.Count) category(ies)"

    # Show summary
    Write-Host ""
    Write-Host "Summary of linked files:" -ForegroundColor Cyan
    foreach ($file in ($markdownFiles | Sort-Object FullName)) {
        $relativePath = $file.FullName.Substring($RepoRoot.Length + 1)
        Write-Host "  ✓ $relativePath" -ForegroundColor Green
    }

}
catch {
    Write-Error "An error occurred: $_"
    Write-Error $_.Exception.Message
    exit 1
}
