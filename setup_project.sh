#!/usr/bin/env bash

PROJECT_INPUT=""
PROJECT_DIR=""

cleanup_on_interrupt() {
    echo ""
    echo "=============================================================="
    echo "[SIGNAL] SIGINT (Ctrl+C) caught. Performing graceful shutdown."
    echo "=============================================================="

    if [ -n "$PROJECT_DIR" ] && [ -d "$PROJECT_DIR" ]; then
        archive_name="attendance_tracker_${PROJECT_INPUT}_archive.tar.gz"

        echo "[SIGNAL] Archiving current state into: ${archive_name}"
        tar -czf "$archive_name" "$PROJECT_DIR" 2>/dev/null

        echo "[SIGNAL] Removing incomplete directory: ${PROJECT_DIR}"
        rm -rf "$PROJECT_DIR"

        echo "[SIGNAL] Done. Recoverable archive saved as: ${archive_name}"
    else
        echo "[SIGNAL] No project directory existed yet. Nothing to clean up."
    fi

    exit 130
}

trap cleanup_on_interrupt SIGINT

echo "=============================================================="
echo "   STUDENT ATTENDANCE TRACKER - PROJECT FACTORY"
echo "=============================================================="

read -p "Enter a name/tag for this build (e.g. v1): " PROJECT_INPUT

if [ -z "$PROJECT_INPUT" ]; then
    echo "[ERROR] No build name was entered. Aborting."
    exit 1
fi

PROJECT_DIR="attendance_tracker_${PROJECT_INPUT}"

if [ -d "$PROJECT_DIR" ]; then
    echo "[WARN] Directory '${PROJECT_DIR}' already exists."
    read -p "       Overwrite it? (y/n): " overwrite_choice
    if [ "$overwrite_choice" = "y" ] || [ "$overwrite_choice" = "Y" ]; then
        rm -rf "$PROJECT_DIR"
        echo "[INFO] Old directory removed. Rebuilding from scratch."
    else
        echo "[INFO] Keeping existing directory. Aborting to avoid conflicts."
        exit 0
    fi
fi

echo "[STEP 1] Creating directory architecture..."

if ! mkdir -p "${PROJECT_DIR}/Helpers" "${PROJECT_DIR}/reports" 2>/dev/null; then
    echo "[ERROR] Could not create directories. Check your file permissions."
    exit 1
fi

echo "[STEP 1] Directory tree created successfully."

echo "[STEP 2] Generating source files..."

cat > "${PROJECT_DIR}/attendance_checker.py" << 'EOF'
import csv
import json
import os
from datetime import datetime

def run_attendance_check():
    # 1. Load Config
    with open('Helpers/config.json', 'r') as f:
        config = json.load(f)

    # 2. Archive old reports.log if it exists
    if os.path.exists('reports/reports.log'):
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        os.rename('reports/reports.log', f'reports/reports_{timestamp}.log.archive')

    # 3. Process Data
    with open('Helpers/assets.csv', mode='r') as f, open('reports/reports.log', 'w') as log:
        reader = csv.DictReader(f)
        total_sessions = config['total_sessions']

        log.write(f"--- Attendance Report Run: {datetime.now()} ---\n")

        for row in reader:
            name = row['Names']
            email = row['Email']
            attended = int(row['Attendance Count'])

            # Simple Math: (Attended / Total) * 100
            attendance_pct = (attended / total_sessions) * 100

            message = ""
            if attendance_pct < config['thresholds']['failure']:
                message = f"URGENT: {name}, your attendance is {attendance_pct:.1f}%. You will fail this class."
            elif attendance_pct < config['thresholds']['warning']:
                message = f"WARNING: {name}, your attendance is {attendance_pct:.1f}%. Please be careful."

            if message:
                if config['run_mode'] == "live":
                    log.write(f"[{datetime.now()}] ALERT SENT TO {email}: {message}\n")
                    print(f"Logged alert for {name}")
                else:
                    print(f"[DRY RUN] Email to {email}: {message}")

if __name__ == "__main__":
    run_attendance_check()
EOF

cat > "${PROJECT_DIR}/Helpers/assets.csv" << 'EOF'
Email,Names,Attendance Count,Absence Count
alice@example.com,Alice Johnson,14,1
bob@example.com,Bob Smith,7,8
charlie@example.com,Charlie Davis,4,11
diana@example.com,Diana Prince,15,0
EOF

cat > "${PROJECT_DIR}/Helpers/config.json" << 'EOF'
{
    "thresholds": {
        "warning": 75,
        "failure": 50
    },
    "run_mode": "live",
    "total_sessions": 15
}
EOF

cat > "${PROJECT_DIR}/reports/reports.log" << 'EOF'
--- Attendance Report Run: 2026-02-06 18:10:01.468726 ---
[2026-02-06 18:10:01.469363] ALERT SENT TO bob@example.com: URGENT: Bob Smith, your attendance is 46.7%. You will fail this class.
[2026-02-06 18:10:01.469424] ALERT SENT TO charlie@example.com: URGENT: Charlie Davis, your attendance is 26.7%. You will fail this class.
EOF

echo "[STEP 2] All source files generated."

CONFIG_FILE="${PROJECT_DIR}/Helpers/config.json"

echo "[STEP 3] Configuration setup."
read -p "Do you want to update the attendance thresholds? (y/n): " update_choice

if [ "$update_choice" = "y" ] || [ "$update_choice" = "Y" ]; then

    read -p "Enter new WARNING threshold [default 75]: " new_warning
    if [ -z "$new_warning" ]; then
        new_warning=75
    fi
    if ! [[ "$new_warning" =~ ^[0-9]+$ ]]; then
        echo "[ERROR] '${new_warning}' is not a valid number. Keeping default 75."
        new_warning=75
    fi

    read -p "Enter new FAILURE threshold [default 50]: " new_failure
    if [ -z "$new_failure" ]; then
        new_failure=50
    fi
    if ! [[ "$new_failure" =~ ^[0-9]+$ ]]; then
        echo "[ERROR] '${new_failure}' is not a valid number. Keeping default 50."
        new_failure=50
    fi

    sed -i "s/\"warning\": [0-9]*/\"warning\": ${new_warning}/" "$CONFIG_FILE"
    sed -i "s/\"failure\": [0-9]*/\"failure\": ${new_failure}/" "$CONFIG_FILE"

    echo "[STEP 3] config.json updated -> warning=${new_warning}, failure=${new_failure}"
else
    echo "[STEP 3] Keeping default thresholds (warning=75, failure=50)."
fi

echo "[STEP 4] Running environment health check..."

if command -v python3 > /dev/null 2>&1; then
    py_version=$(python3 --version 2>&1)
    echo "[HEALTH] SUCCESS: python3 is installed (${py_version})."
else
    echo "[HEALTH] WARNING: python3 was not found on this system."
fi

echo "=============================================================="
echo "[DONE] Project '${PROJECT_DIR}' is ready."
echo "       Structure:"
echo "         ${PROJECT_DIR}/"
echo "           |- attendance_checker.py"
echo "           |- Helpers/  (assets.csv, config.json)"
echo "           |- reports/  (reports.log)"
echo "=============================================================="
exit 0
