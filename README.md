# Vhost Manager

This is a PowerShell script to manage Apache virtual hosts (vhosts) in XAMPP on Windows.

## Features

- Add a new vhost
  - Specify vhost name and document root
  - Option to add SSL certificates using mkcert
- Remove an existing vhost
  - Deletes vhost config, SSL certs, hosts file entry
- Update an existing vhost
  - Change vhost name, document root, or SSL config
- Menu driven interface

## Requirements

- XAMPP installed on Windows
- Apache vhosts enabled in XAMPP config
- mkcert installed and available in PATH (for SSL vhosts)

## Usage

1. Update the settings.ini file with your paths
2. Run the script with PowerShell
3. Follow the prompts to add, remove, or update a vhost

## Configuration

The settings.ini file contains the following config:

- XAMPP installation path
- Apache config file path
- Vhosts config file path 
- SSL certs path
- Hosts file path

Update these paths to match your environment.

## Adding SSL

To add SSL to a vhost, mkcert must be installed. The script will check for this and prompt to install if missing.

Certificates will be generated when adding a new SSL vhost.

## Hosts File

The script will automatically add an entry to your hosts file when adding a new vhost.

Make sure the hosts file path is configured correctly in settings.ini.

## Credits

Script created by Bundit Nuntates
