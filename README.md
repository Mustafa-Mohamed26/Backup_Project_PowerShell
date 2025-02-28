# Backup Project (PowerShell) 🛡️

This project, **Backup_Project_PowerShell**, is a **robust and configurable backup system** written in **PowerShell**. It automates the process of **backing up critical files and directories**, ensuring data safety with incremental backups, error handling, and detailed logging.

## 🔍 Features
- ✅ **Incremental & full backups** for efficient storage.
- ✅ **Configurable backup schedules** using **Task Scheduler**.
- ✅ **Error handling & logging** to track backup success/failure.
- ✅ **Backup validation** to ensure data integrity.
- ✅ **Compatible with Windows systems**.

## 🔧 How to Use
1. **Clone the repository**:
   ```powershell
   git clone https://github.com/Mustafa-Mohamed26/Backup_Project_PowerShell.git
   cd Backup_Project_PowerShell
   ```
2. **Run the PowerShell script**:
   ```powershell
   ./backup project.ps1
   ```
3. **Schedule automated backups** using Windows Task Scheduler:
   - Open **Task Scheduler**.
   - Create a new task and set the trigger (e.g., daily at midnight).
   - Set the action to run **PowerShell** with the script path:
     ```powershell
     powershell.exe -ExecutionPolicy Bypass -File "C:\path\to\backup project.ps1"
     ```

## 📝 Configuration
- Modify the **backup project.ps1** script to specify:
  - Source directories/files to back up.
  - Destination directory for backups.
  - Backup frequency & retention policy.

## 🚀 Contributions
Contributions are welcome! Feel free to improve error handling, add compression support, or enhance logging.

## 📜 License
This project is licensed under the **MIT License** – feel free to use and modify it.

---
📩 **Have suggestions? Open an issue or contribute!** 🚀

