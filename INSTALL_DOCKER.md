# Docker Installation Guide for Windows

## Install Docker Desktop

You need Docker Desktop to run this project. Follow these steps:

### Step 1: Download Docker Desktop

1. Go to: https://www.docker.com/products/docker-desktop/
2. Click "Download for Windows"
3. Wait for the installer to download (approximately 500MB)

### Step 2: Install Docker Desktop

1. Run the downloaded installer (`Docker Desktop Installer.exe`)
2. Follow the installation wizard
3. **Important**: Make sure to enable WSL 2 when prompted (recommended)
4. Complete the installation
5. **Restart your computer** when prompted

### Step 3: Start Docker Desktop

1. Launch "Docker Desktop" from the Start menu
2. Accept the Docker Subscription Service Agreement
3. Wait for Docker to start (you'll see a green icon in the system tray)
4. Docker is ready when you see "Docker Desktop is running"

### Step 4: Verify Installation

Open PowerShell and run:

```powershell
docker --version
docker compose version
```

You should see version information for both commands.

### Step 5: Configure Docker Resources (Recommended)

1. Open Docker Desktop
2. Click the Settings gear icon
3. Go to "Resources" → "Advanced"
4. Allocate resources:
   - **Memory**: At least 8GB (recommended for this project)
   - **CPUs**: At least 4 cores
   - **Disk**: At least 20GB
5. Click "Apply & Restart"

### Step 6: Run the AIOps Platform

Once Docker is installed and running:

```powershell
cd c:\Users\dldec\OneDrive\Documents\Projects\aiops
.\start.bat
```

## Troubleshooting

### "WSL 2 installation is incomplete"

If you see this error:

1. Open PowerShell as Administrator
2. Run: `wsl --install`
3. Restart your computer
4. Start Docker Desktop again

### "Docker daemon is not running"

1. Make sure Docker Desktop is running (check system tray)
2. If not, launch it from the Start menu
3. Wait for it to fully start (green icon)

### "Hardware assisted virtualization is not enabled"

You need to enable virtualization in your BIOS:

1. Restart your computer
2. Enter BIOS/UEFI (usually F2, F10, F12, or Del key during boot)
3. Find "Virtualization Technology" or "Intel VT-x" or "AMD-V"
4. Enable it
5. Save and exit BIOS

### Still Having Issues?

Check Docker's official documentation:
https://docs.docker.com/desktop/install/windows-install/

## Alternative: Using Docker without Docker Desktop

If you can't install Docker Desktop (licensing, system requirements, etc.):

### Option 1: Install Docker Engine with WSL 2

1. Install WSL 2: `wsl --install`
2. Install Ubuntu from Microsoft Store
3. Inside Ubuntu, install Docker Engine:
   ```bash
   curl -fsSL https://get.docker.com -o get-docker.sh
   sudo sh get-docker.sh
   sudo usermod -aG docker $USER
   ```
4. Use the Linux terminal to run docker commands

### Option 2: Use Cloud-based Docker (Free Tier)

- **Play with Docker**: https://labs.play-with-docker.com/ (4 hours free sessions)
- **GitHub Codespaces**: Free tier with Docker support
- **Gitpod**: Free tier with Docker support

## System Requirements

- **Windows 10 64-bit**: Pro, Enterprise, or Education (Build 19044 or higher)
- **Windows 11 64-bit**: Home or Pro (Build 22000 or higher)
- **WSL 2** enabled
- **Virtualization** enabled in BIOS
- **8GB RAM minimum** (16GB recommended)
- **20GB free disk space**

---

**Once Docker is installed, come back to this project and run `.\start.bat`**
