# Microsoft Graph PowerShell Tools

A collection of PowerShell tools for working with Microsoft Graph API, including workarounds for known issues in the Microsoft.Graph PowerShell SDK.

## Remove-UserLicense.ps1

### Problem

In Microsoft.Graph PowerShell SDK version 2.26.1, the `Set-MgUserLicense` cmdlet is broken. Even when following the documented syntax with `-RemoveLicenses @()`, the command fails with the error:
Set-MgUserLicense : One or more parameters of the operation 'assignLicense' are missing from the request payload. The missing parameters are: removeLicenses.

After extensive testing, I found that even when explicitly passing -RemoveLicenses, the cmdlet would still fail unless an empty array was also included for -AddLicenses. However, I was able to bypass this bug entirely by using a direct JSON API call via Invoke-MgGraphRequest instead of Set-MgUserLicense.

This issue has been reported to Microsoft [in this GitHub issue](https://github.com/microsoftgraph/msgraph-sdk-powershell/issues/3213) and in the [Microsoft Q&A community](https://learn.microsoft.com/en-us/answers/questions/2202408/set-mguserlicense-error-message).

### Solution

This script provides a workaround by using `Invoke-MgGraphRequest` to make direct Graph API calls instead of using the broken cmdlet. It offers an interactive menu to select which licenses to remove from a user.

### Key Code That Fixes the Issue

```powershell
# Create JSON payload for license removal
$jsonBody = @{
    addLicenses    = @()  # Must be explicitly empty
    removeLicenses = $LicensesToRemove
} | ConvertTo-Json -Depth 10

# Send Graph API request to remove the licenses
Invoke-MgGraphRequest -Method POST -Uri "https://graph.microsoft.com/v1.0/users/$($UserId)/assignLicense" -Body $jsonBody -ContentType "application/json"
```

### Features

- Interactive menu showing all licenses assigned to a user
- Option to remove specific licenses or all licenses at once
- Confirmation before making changes
- Verification of remaining licenses after removal
- Works with Microsoft.Graph 2.26.1 (and should continue to work with future versions)

### Usage
# Basic usage (will prompt for email)
```powershell
.\Remove-UserLicense.ps1
```
# Specify user email
```powershell
.\Remove-UserLicense.ps1 -UserEmail user@example.com
```

### Example Output
```powershell
================ Licenses for user@example.com ================
[1] POWER_BI_STANDARD (PURVIEW_DISCOVERY) - a403ebcc-fae0-4ca2-8c8c-7a907fd6c235
[2] Microsoft_Teams_Audio_Conferencing_select_dial_out (MCOMEETBASIC) - 1c27243e-fb4d-42b1-ae8c-fe25c9616588
[3] SPB (PLACES_CORE) - cbdc14ab-d96c-4c30-b9f4-6ada7cdc1d46
[A] Select All
[Q] Quit
=========================================
Select multiple options by entering numbers separated by commas (e.g., 1,3,5)
```

## Requirements

- PowerShell 5.1 or higher
- Microsoft.Graph PowerShell module (`Install-Module Microsoft.Graph`)
- Appropriate permissions (`User.ReadWrite.All`, `Directory.ReadWrite.All`)

### Other Microsoft Graph Issues & Solutions
More tools will be added here as they are developed

### Workaround for Adding Licenses
The same approach can be used to add licenses by populating the addLicenses array in the JSON payload:
```powershell
$jsonBody = @{
    addLicenses    = @(
        @{
            skuId = "YOUR-LICENSE-SKU-ID"
        }
    )
    removeLicenses = @()
} | ConvertTo-Json -Depth 10
```

### Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

### License

This project is licensed under the MIT License - see the LICENSE file for details.
