import subprocess
import os
import argparse
import concurrent.futures

def run_test(runs=1, width=5):
    folders_with_makefile = []
    for root, _, files in os.walk("."):
        if "Makefile" in files or "makefile" in files:
            folders_with_makefile.append(root)
    folders_with_makefile.remove('.')
    print(f"Folders with Makefile: {folders_with_makefile}")

    def run_make(folder, run_idx):
        module_name = os.path.basename(os.path.abspath(folder))
        result = subprocess.run(
            ["make"],
            cwd=folder,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True
        )
        log_header = f"\n=== {module_name} run {run_idx} ===\n"
        print(f"Running {module_name} (run {run_idx})...")
        return log_header + result.stdout

    # Create a flat list of all tasks
    tasks = []
    for folder in folders_with_makefile:
        for run_idx in range(1, runs + 1):
            tasks.append((folder, run_idx))
    print(f"Total tasks: {len(tasks)}")
    print(f"Running {width} batches at a time.")

    # Use ThreadPoolExecutor to divide tasks among threads
    logs = [None] * len(tasks)
    with concurrent.futures.ThreadPoolExecutor(max_workers=width) as executor:
        future_to_idx = {
            executor.submit(run_make, folder, run_idx): idx
            for idx, (folder, run_idx) in enumerate(tasks)
        }
        for future in concurrent.futures.as_completed(future_to_idx):
            idx = future_to_idx[future]
            logs[idx] = future.result()

    # Write all logs to the master log file in order
    master_log_filename = "master.log"
    with open(master_log_filename, "a") as master_log:
        for log in logs:
            master_log.write(log)

def main():
    parser = argparse.ArgumentParser(description="Run make in folders with Makefile.")
    parser.add_argument("-runs", type=int, default=1, help="Number of repetitions per folder")
    parser.add_argument("-width", type=int, default=4, help="Number of threads to use")
    args = parser.parse_args()
    run_test(runs=args.runs, width=args.width)

if __name__ == "__main__":
    main()