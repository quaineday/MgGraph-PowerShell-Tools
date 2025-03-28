# Microsoft Graph PowerShell Tools

A collection of PowerShell tools for working with Microsoft Graph API, including workarounds for known issues in the Microsoft.Graph PowerShell SDK.

## Remove-UserLicense.ps1

### Problem

In Microsoft.Graph PowerShell SDK version 2.26.1, the `Set-MgUserLicense` cmdlet is broken. Even when following the documented syntax with `-RemoveLicenses @()`, the command fails with the error:
