# Mecademic Demo Project

This repository serves as the main project wrapper for setting up and running a Mecademic robotic application demo. It relies on Git submodules to pull in the application code and the specific workspace configuration.

## Project Structure

*   **`mecademic_demo_app`**: The core application engine (added as a submodule).
*   **`mecademic_demo_template`**: The configuration, logic, and workspace files for the demo (added as a submodule).
*   **`start_demo.bat`**: A convenient batch script to initialize the python environment and start the application.
*   **`create_project.bat`**: Creates a new custom workspace from the template.

## Prerequisites

*   Python 3.8+ installed and added to your system PATH.
*   Git installed.

## Setup Instructions

### 1. Clone the Repository

Because this project uses Git submodules, make sure to clone it recursively:

```bash
git clone --recursive https://github.com/maximeriera/mecademic_demo_project.git
cd mecademic_demo_project
```

*(If you have already cloned it normally, you can initialize the submodules using `git submodule update --init --recursive`)*

### 2. Creating a Dedicated Demo Workspace (Recommended)

By default, the demo uses the `mecademic_demo_template` submodule as its configuration workspace. If you plan to customize this demo for a specific client or use-case:

1. Create a custom workspace from the template:

```cmd
create_project.bat mecademic_client_line1
```

2. Launch the demo against your custom workspace:

```cmd
start_demo.bat mecademic_client_line1
```

3. Optional fast-iteration mode (hot reload hooks enabled):

```cmd
set MECADEMIC_DEV_RELOAD=1
start_demo.bat mecademic_client_line1
```

### 3. Running the Demo

To run the demo, simply execute the included batch script from your command prompt or by double-clicking it in Windows Explorer:

```cmd
start_demo.bat
```

Or with a custom workspace:

```cmd
start_demo.bat mecademic_client_line1
```

**What `start_demo.bat` does:**
1. Checks for a Python virtual environment (`.venv`) inside the application folder and creates it if it doesn't exist.
2. Activates the virtual environment.
3. Installs all required dependencies from `requirements.txt`.
4. Sets the PYTHONPATH.
5. Launches the application, passing the designated workspace directory as an argument.

### 4. Linux Deployment with Docker Compose (USB + Network Devices)

This repository now includes a Linux-focused container stack:

- `docker-compose.yml` (app + nginx)
- `mecademic_demo_app/Dockerfile` (app image)
- `docker/nginx.conf` (reverse proxy)

Build and run:

```bash
docker compose build
docker compose up -d
```

Stop:

```bash
docker compose down
```

Notes:

1. The stack uses `network_mode: host` to simplify access to industrial LAN devices.
2. USB serial devices are mapped as `/dev/ttyUSB0` and `/dev/ttyACM0` by default in `docker-compose.yml`.
3. For production, prefer stable device mapping through `/dev/serial/by-id/*`.
4. Persistent mounts are configured for:
	- `./logs -> /app/logs`
	- `./mecademic_demo_app/backups -> /app/backups`
	- `./mecademic_demo_app/app_logic -> /app/app_logic`

### 4. Reload Custom Code During Development

When dev mode is enabled (`MECADEMIC_DEV_RELOAD=1` or `--dev-reload`), you can reload workspace logic without restarting the process:

```http
POST /api/dev/reload-custom-code
```

Safety rule: reload is only accepted while the controller state is `READY`.
