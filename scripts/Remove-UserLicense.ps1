# Remove-UserLicense.ps1
# Interactive script to remove Microsoft 365 licenses from a user using Graph API directly
# This script works around the bug in Set-MgUserLicense in Microsoft.Graph 2.26.1

param (
    [Parameter(Mandatory=$false)]
    [string]$UserEmail
)

# Check if Microsoft.Graph module is installed
if (-not (Get-Module -ListAvailable -Name Microsoft.Graph)) {
    Write-Host "Microsoft.Graph module is not installed. Please install it using 'Install-Module Microsoft.Graph' and try again." -ForegroundColor Red
    exit
}

# Import Microsoft.Graph module if not loaded
if (-not (Get-Module -Name Microsoft.Graph)) {
    Import-Module Microsoft.Graph
}

# Connect to Microsoft Graph if not already connected
try {
    Get-MgContext -ErrorAction Stop | Out-Null
    Write-Host "Already connected to Microsoft Graph" -ForegroundColor Green
}
catch {
    Write-Host "Connecting to Microsoft Graph..." -ForegroundColor Yellow
    Connect-MgGraph -Scopes "User.ReadWrite.All", "Directory.ReadWrite.All"
}

# Function to remove licenses
function Remove-UserLicenseViaGraph {
    param (
        [string]$UserEmail,
        [string[]]$LicensesToRemove
    )

    # Get User ID from Microsoft Graph
    $user = Get-MgUser -Filter "UserPrincipalName eq '$UserEmail'" -ErrorAction SilentlyContinue
    
    if (-not $user) {
        Write-Host "Error: User $UserEmail not found in Microsoft Graph." -ForegroundColor Red
        return $false
    }
    
    $UserId = $user.Id

    # Create JSON payload for license removal
    $jsonBody = @{
        addLicenses    = @()  # Must be explicitly empty
        removeLicenses = $LicensesToRemove
    } | ConvertTo-Json -Depth 10

    try {
        # Send Graph API request to remove the licenses
        Invoke-MgGraphRequest -Method POST -Uri "https://graph.microsoft.com/v1.0/users/$($UserId)/assignLicense" -Body $jsonBody -ContentType "application/json"
        Write-Host "Successfully removed licenses from $UserEmail" -ForegroundColor Green
        return $true
    }
    catch {
        # Fixed the error message syntax here
        $errorMessage = $_.Exception.Message
        Write-Host "Failed to remove licenses from $UserEmail. Error: $errorMessage" -ForegroundColor Red
        return $false
    }
}

# Function to display an interactive menu
function Show-Menu {
    param (
        [string]$Title,
        [array]$Options,
        [switch]$AllowMultiple,
        [switch]$IncludeAllOption
    )
    
    Clear-Host
    Write-Host "================ $Title ================" -ForegroundColor Cyan
    
    for ($i = 0; $i -lt $Options.Count; $i++) {
        Write-Host "[$($i+1)] $($Options[$i])" -ForegroundColor Yellow
    }
    
    if ($IncludeAllOption) {
        Write-Host "[A] Select All" -ForegroundColor Green
    }
    
    Write-Host "[Q] Quit" -ForegroundColor Red
    Write-Host "=========================================" -ForegroundColor Cyan
    
    if ($AllowMultiple) {
        Write-Host "Select multiple options by entering numbers separated by commas (e.g., 1,3,5)" -ForegroundColor Magenta
    }
    
    $selection = Read-Host "Please make your selection"
    return $selection
}

# Main script execution
if (-not $UserEmail) {
    $UserEmail = Read-Host "Enter the user's email address"
}

# Get User ID from Microsoft Graph
$user = Get-MgUser -Filter "UserPrincipalName eq '$UserEmail'" -ErrorAction SilentlyContinue

if (-not $user) {
    Write-Host "Error: User $UserEmail not found in Microsoft Graph." -ForegroundColor Red
    exit
}

$UserId = $user.Id

# Get all assigned licenses
$assignedLicenses = Get-MgUserLicenseDetail -UserId $UserId

if ($assignedLicenses.Count -eq 0) {
    Write-Host "No licenses found for $UserEmail." -ForegroundColor Yellow
    exit
}

# Prepare license options for menu
$licenseOptions = @()
foreach ($license in $assignedLicenses) {
    # Try to get a friendly name for the license if possible
    $friendlyName = $license.ServicePlans | Where-Object { $_.ServicePlanName -match "^[A-Z]+" } | Select-Object -First 1 -ExpandProperty ServicePlanName
    if (-not $friendlyName) {
        $friendlyName = $license.SkuPartNumber
    }
    
    $licenseOptions += "$($license.SkuPartNumber) ($friendlyName) - $($license.SkuId)"
}

# Show interactive menu
$selection = Show-Menu -Title "Licenses for $UserEmail" -Options $licenseOptions -AllowMultiple -IncludeAllOption

if ($selection -eq "Q" -or $selection -eq "q") {
    Write-Host "Operation cancelled" -ForegroundColor Yellow
    exit
}

# Handle selection
$licensesToRemove = @()

if ($selection -eq "A" -or $selection -eq "a") {
    # Remove all licenses
    $licensesToRemove = $assignedLicenses | Select-Object -ExpandProperty SkuId
    Write-Host "Removing ALL licenses from $UserEmail" -ForegroundColor Yellow
}
else {
    # Parse multiple selections (comma-separated)
    $selectedIndices = $selection -split ',' | ForEach-Object { $_.Trim() }
    
    foreach ($index in $selectedIndices) {
        if ([int]::TryParse($index, [ref]$null)) {
            $adjustedIndex = [int]$index - 1
            
            if ($adjustedIndex -ge 0 -and $adjustedIndex -lt $assignedLicenses.Count) {
                $licensesToRemove += $assignedLicenses[$adjustedIndex].SkuId
                Write-Host "Will remove license: $($assignedLicenses[$adjustedIndex].SkuPartNumber)" -ForegroundColor Yellow
            }
        }
    }
}

if ($licensesToRemove.Count -eq 0) {
    Write-Host "No valid licenses selected for removal." -ForegroundColor Yellow
    exit
}

# Confirm before proceeding
$confirmation = Read-Host "Are you sure you want to remove the selected license(s)? (Y/N)"
if ($confirmation -ne "Y" -and $confirmation -ne "y") {
    Write-Host "Operation cancelled" -ForegroundColor Yellow
    exit
}

# Remove selected licenses
$result = Remove-UserLicenseViaGraph -UserEmail $UserEmail -LicensesToRemove $licensesToRemove

if ($result) {
    # Verify removal
    $remainingLicenses = Get-MgUserLicenseDetail -UserId $UserId
    Write-Host "Remaining licenses for $UserEmail" -ForegroundColor Cyan
    
    if ($remainingLicenses.Count -eq 0) {
        Write-Host "  - None" -ForegroundColor Cyan
    }
    else {
        foreach ($license in $remainingLicenses) {
            # Modified to avoid any colon issues
            Write-Host "  - $($license.SkuPartNumber) ($($license.SkuId))" -ForegroundColor Cyan
        }
    }
}