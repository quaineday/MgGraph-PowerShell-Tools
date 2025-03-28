# Microsoft Graph PowerShell Tools

A collection of PowerShell tools for working with Microsoft Graph API, including workarounds for known issues in the Microsoft.Graph PowerShell SDK.

## Remove-UserLicense.ps1

### Problem

In Microsoft.Graph PowerShell SDK version 2.26.1, the `Set-MgUserLicense` cmdlet is broken. Even when following the documented syntax with `-RemoveLicenses @()`, the command fails with the error:
"One or more parameters of the operation 'assignLicense' are missing from the request payload. The missing parameters are: removeLicenses."

After extensive testing, I found that even when explicitly passing -RemoveLicenses, the cmdlet would still fail unless an empty array was also included for -AddLicenses. However, I was able to bypass this bug entirely by using a direct JSON API call via Invoke-MgGraphRequest instead of Set-MgUserLicense.
