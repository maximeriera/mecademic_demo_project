# Mecademic Demo Project

This repository serves as the main project wrapper for setting up and running a Mecademic robotic application demo. It relies on Git submodules to pull in the application code and the specific workspace configuration.

## Project Structure

*   **`mecademic_demo_app`**: The core application engine (added as a submodule).
*   **`mecademic_demo_template`**: The configuration, logic, and workspace files for the demo (added as a submodule).
*   **`start_demo.bat`**: A convenient batch script to initialize the python environment and start the application.

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

### 2. Creating a Dedicated Demo Workspace (Optional)

By default, the demo uses the `mecademic_demo_template` submodule as its configuration workspace. If you plan to customize this demo for a specific client or use-case:

1. Duplicate the `mecademic_demo_template` folder, or fork its repository and add it as a new submodule under a custom name (e.g., `mecademic_my_dedicated_demo`).
2. Update the `start_demo.bat` script to point to your new folder instead of `mecademic_demo_template` by changing the `set "TEMPLATE_DIR=mecademic_demo_template"` line.

### 3. Running the Demo

To run the demo, simply execute the included batch script from your command prompt or by double-clicking it in Windows Explorer:

```cmd
start_demo.bat
```

**What `start_demo.bat` does:**
1. Checks for a Python virtual environment (`.venv`) inside the application folder and creates it if it doesn't exist.
2. Activates the virtual environment.
3. Installs all required dependencies from `requirements.txt`.
4. Sets the PYTHONPATH.
5. Launches the application, passing the designated workspace directory as an argument.
