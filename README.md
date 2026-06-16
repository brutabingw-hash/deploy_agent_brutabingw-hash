## Walkthrough Video

[Watch the run-through here]()

# Automated Project Bootstrapping — Student Attendance Tracker

A **Project Factory**: a single shell script (`setup_project.sh`) that deploys a
complete Student Attendance Tracker workspace in seconds. It demonstrates
Infrastructure as Code (IaC) — reproducible, efficient, and free of human error.

The script builds the directory structure, generates every source file,
lets you reconfigure the attendance thresholds, validates the environment,
and shuts down gracefully (with an automatic backup) if it is interrupted.

---

## What the script produces

Running the script creates the following structure, where `{input}` is a tag
you type at the first prompt (for example `v1`):

```
attendance_tracker_{input}/
├── attendance_checker.py        # the main Python logic
├── Helpers/
│   ├── assets.csv               # student attendance data
│   └── config.json              # thresholds + run settings
└── reports/
    └── reports.log              # generated report output
```

---

## Requirements

- A Linux / WSL environment (or Git Bash on Windows) with **bash**.
- **GNU sed** (standard on Linux). The in-place edit uses `sed -i`.
- **python3** (optional — the script only *checks* for it and warns if missing).

---

## How to run it

1. Open a terminal in the folder that contains `setup_project.sh`.
2. Make the script executable (only needed once):

   ```bash
   chmod +x setup_project.sh
   ```

3. Run it:

   ```bash
   ./setup_project.sh
   ```

4. Answer the prompts:
   - **Build name** — any tag you like, e.g. `v1`. This becomes
     `attendance_tracker_v1/`.
   - **Update thresholds? (y/n)** — choose `y` to set custom Warning and Failure
     percentages, or `n` to keep the defaults (Warning = 75, Failure = 50).
     If you pick `y`, just press Enter at a prompt to accept that default, and
     any non-numeric entry is rejected and falls back to the default.

When it finishes you will see a `[DONE]` banner and the full directory tree.

### Running the attendance checker afterwards

```bash
cd attendance_tracker_v1
python3 attendance_checker.py
cat reports/reports.log
```

---

## How to trigger the archive feature (the SIGINT trap)

The script installs a **signal trap** for `SIGINT` (Ctrl+C). This is the safety
net that keeps your workspace clean if you cancel a deployment halfway through.

**To trigger it:** while the script is running — for example, when it is waiting
at the *"Do you want to update the attendance thresholds?"* prompt — press
**Ctrl+C**.

When the trap fires, the script will:

1. Catch the interrupt instead of dying messily.
2. Bundle the partially-built directory into a compressed archive named
   `attendance_tracker_{input}_archive.tar.gz`.
3. Delete the incomplete `attendance_tracker_{input}/` directory so no
   half-finished files are left behind.
4. Exit with status code `130` (the conventional code for "terminated by Ctrl+C").

You can inspect or restore the saved work at any time:

```bash
tar -tzf attendance_tracker_v1_archive.tar.gz   # list contents
tar -xzf attendance_tracker_v1_archive.tar.gz   # restore it
```

---

## How it works (summary)

| Stage | What happens |
|-------|--------------|
| **1. Directory architecture** | Creates the parent and sub-directories with `mkdir -p`, after checking for an existing directory and verifying it has permission to write. |
| **2. File generation** | Writes all four source files using here-documents (`cat << 'EOF'`). |
| **3. Dynamic configuration** | Uses `read` to capture new thresholds, validates they are numeric, then performs an in-place edit of `config.json` with `sed -i`. |
| **4. Environment validation** | Runs a health check for `python3` and reports success or a warning. |
| **Signal trap** | Catches `SIGINT` at any point, archives the work, and removes the incomplete directory. |
