# Microsoft Graph PowerShell Tools

A collection of PowerShell tools for working with Microsoft Graph API, including workarounds for known issues in the Microsoft.Graph PowerShell SDK.

## Remove-UserLicense.ps1

### Problem

In Microsoft.Graph PowerShell SDK version 2.26.1, the `Set-MgUserLicense` cmdlet is broken. Even when following the documented syntax with `-RemoveLicenses @()`, the command fails with the error:
"One or more parameters of the operation 'assignLicense' are missing from the request payload. The missing parameters are: removeLicenses."

After extensive testing, I found that even when explicitly passing -RemoveLicenses, the cmdlet would still fail unless an empty array was also included for -AddLicenses. However, I was able to bypass this bug entirely by using a direct JSON API call via Invoke-MgGraphRequest instead of Set-MgUserLicense.

This issue has been reported to Microsoft [in this GitHub issue](https://github.com/microsoftgraph/msgraph-sdk-powershell/issues/3213).

### Solution

This script provides a workaround by using `Invoke-MgGraphRequest` to make direct Graph API calls instead of using the broken cmdlet. It offers an interactive menu to select which licenses to remove from a user.

### Features

- Interactive menu showing all licenses assigned to a user
- Option to remove specific licenses or all licenses at once
- Confirmation before making changes
- Verification of remaining licenses after removal
- Works with Microsoft.Graph 2.26.1 (and should continue to work with future versions)

### Usage

```powershell
# Basic usage (will prompt for email)
.\Remove-UserLicense.ps1

# Specify user email
.\Remove-UserLicense.ps1 -UserEmail user@example.com
