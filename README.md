# do-firewall-updater

A simple Bash script to keep your DigitalOcean firewall's SSH rule up-to-date with your dynamic home IP address.

This is useful when your ISP changes your IP, and you want to ensure that your home IP always has SSH access to your droplets protected by a firewall.

## Features

- No dependencies (pure Bash + `curl`)
- CLI arguments for easy automation
- Automatically updates IP in the firewall if it changes
- Removes the old IP from the firewall
- Optional custom cache file to track last known IP
- Designed for use in cron jobs or headless servers

---

## Installation

Clone or copy the script locally:

```bash
curl -o do-firewall-updater https://raw.githubusercontent.com/stefanomarra/do-firewall-updater/refs/heads/master/do-firewall-updater.sh
chmod +x do-firewall-updater
```

> Place it somewhere in your $PATH (like /usr/local/bin) if you'd like to use it globally.

---

## Usage

```bash
./do-firewall-updater --token=YOUR_DIGITALOCEAN_TOKEN --firewall-id=YOUR_FIREWALL_ID
```

## Options

| Option              | Description                                                                 |
|---------------------|-----------------------------------------------------------------------------|
| `--token=`          | Your DigitalOcean API token (required)                                      |
| `--firewall-id=`    | The ID of the DigitalOcean firewall to update (required)                    |
| `--cache-file=`     | (Optional) Custom path to store the last known IP (default: `~/.do_last_ip`)|
| `--help`            | Show help and usage                                                         |


---

## Example (Crontab)

To run this every 15 minutes, use:

```bash
*/15 * * * * /path/to/do-firewall-updater --token=your_token --firewall-id=your_firewall_id >> /var/log/do-furewall-updater.log 2>&1
```
