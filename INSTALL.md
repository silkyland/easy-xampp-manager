# XAMPP Installer PowerShell Script

This PowerShell script installs XAMPP on Windows using the Windows Package Manager (winget).

## Usage

1. Open PowerShell as an administrator.
2. Navigate to the directory where the `install.ps1` script is located.
3. Run the script by typing `.\install.ps1` and pressing Enter.
4. Follow the prompts to select the version of XAMPP to install.
5. Wait for the installation to complete.

## Output

The script outputs the following messages:

- "Searching for XAMPP..." when searching for XAMPP using winget.
- A list of available XAMPP versions with corresponding numbers.
- "Enter the number of the version you want to install (from the list above)" prompt.
- "Installing XAMPP version [version number] ..." when installing XAMPP.
- "Adding PHP path to PATH environment variable..." when adding PHP to the PATH environment variable.
- "Adding Apache path to PATH environment variable..." when adding Apache to the PATH environment variable.
- "Installation complete" when the installation is complete.
- "Invalid number entered, installation aborted" when an invalid number is entered.