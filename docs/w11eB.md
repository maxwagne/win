# Install Windows
 - install virtio drivers
 - Change Computername
*restart*
*shutdown*
*backup1*
# Update Windows
*restart*
*restart*
*shutdown*
*backup2*
# Set Management
 - change efi vnc resolution
 - enable Remote Desktop
# Prepare Environment 1
 - winget install Microsoft.Powershell
 - winget install --id Git.Git -e --source winget
 - mkdir .\config
 - git clone .\config
 **as Admin **
 - Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
 - deploy.sh
*shutdown*
*backup3*
# Prepare Environment 2
 - iwr -useb get.scoop.sh | iex
 - scoop install neovim
    - if missing VCRRUNTIME140.dll https://support.microsoft.com/en-us/kb/2977003
 - winget install Microsoft.WindowsTerminal **upnexttime**

# Settings

# Passthrough
    Logitech Options +
