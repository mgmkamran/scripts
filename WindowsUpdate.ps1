#Author: mgmkamran

# Function to perform a command with retry logic
function Invoke-WithRetry {
    param (
        [ScriptBlock]$Command,
        [int]$RetryCount = 3
    )
    $currentCount = 0
    while ($currentCount -lt $RetryCount) {
        try {
            & $Command
            return
        } catch {
            Write-Host "Attempt $currentCount failed: $_"
            Start-Sleep -Seconds 20
            $currentCount++
        }
    }
    Write-Host "Command failed after $RetryCount attempts."
}

# Add TLS1.2 if not already set
Invoke-WithRetry {
    if ([Net.ServicePointManager]::SecurityProtocol -notcontains [Net.SecurityProtocolType]::Tls12) {
        [Net.ServicePointManager]::SecurityProtocol += [Net.SecurityProtocolType]::Tls12
    }
}

# # Ensure the directory exists for the transcript
# $transcriptPath = "C:\temp\windowsupdate$(Get-Date -Format 'yyyyMMddHHmmss').log"
# Invoke-WithRetry {
#     if (!(Test-Path -Path "C:\temp")) {
#         New-Item -ItemType Directory -Force -Path "C:\temp"
#     }
# }

# # Start transcript to log the output of the script only if not already started
# Invoke-WithRetry {
#     Start-Transcript -Path $transcriptPath
# }

# Register the PSRepository only if it's not already registered
$repositoryName = "PSGallery"
$repositorySourceLocation = "https://www.powershellgallery.com/api/v2"
Invoke-WithRetry {
    if (!(Get-PSRepository -Name $repositoryName -ErrorAction SilentlyContinue)) {
        Register-PSRepository -Name $repositoryName -SourceLocation $repositorySourceLocation -InstallationPolicy Untrusted
    }
}

# Asynchronously install the necessary modules and packages only if they are not already installed
Invoke-WithRetry {
    # Install NuGet package provider if not already installed
    if (!(Get-PackageProvider -Name 'Nuget' -ListAvailable)) {
        Install-PackageProvider -Name "NuGet" -Force -SkipPublisherCheck
    }
    # Install PSWindowsUpdate module if not already installed
    if (!(Get-Module -Name PSWindowsUpdate -ListAvailable)) {
        Install-Module PSWindowsUpdate -Force -SkipPublisherCheck
    }
}


# Import the PSWindowsUpdate module only if it's not already imported
Invoke-WithRetry {
    if (!(Get-Module -Name PSWindowsUpdate)) {
        Import-Module PSWindowsUpdate -Force
        Write-Host "PSWindowsUpdate module imported"
    }
}

# Get and install available updates only if they are not already installed
Invoke-WithRetry {
    $updates = Get-WindowsUpdate -IgnoreReboot
    if ($updates) {
        Install-WindowsUpdate -AcceptAll -IgnoreReboot
    } else {
        Write-Host "No new updates to install."
    }
}

# # Stop transcript only if it was started by this script
# Invoke-WithRetry {
#     Stop-Transcript
# }
