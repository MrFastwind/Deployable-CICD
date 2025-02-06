import subprocess
import os

BACKUP_PATH = "/backup/backup.tar.gz"

def find_stack_files():
    """Find all docker-compose*.yml files and return them as formatted arguments."""
    result = subprocess.run(
        [
            "powershell", "-Command",
            "Get-ChildItem -Path . -Filter 'docker-compose*.yml' | Sort-Object Name | ForEach-Object { '-f ' + '\"' + $_.FullName + '\"' }"
        ],
        stdout=subprocess.PIPE,
        check=True
    )
    files = result.stdout.decode().strip().splitlines()
    return " ".join(files)

def get_targets(stack_files):
    """Get the list of service targets from the docker-compose config."""
    result = subprocess.run(
        f"docker compose {stack_files} config --services",
        shell=True,
        stdout=subprocess.PIPE,
        check=True
    )
    return result.stdout.decode().strip().splitlines()

def run_command(command):
    """Run a shell command."""
    print(f"Running: {command}")
    subprocess.run(command, shell=True, check=True)

def status(stack_files):
    """Show the status of the containers."""
    run_command(f"docker compose -p cicd {stack_files} ps")

def start_service(stack_files, service):
    """Start a specific service."""
    run_command(f"docker compose -p cicd {stack_files} up -d {service}")

def stop_service(stack_files, service):
    """Stop a specific service by scaling it down to 0."""
    # Workaround for older docker compose version: it use the scale down size
    run_command(f"docker compose -p cicd {stack_files} up --scale {service}=0 {service}")

def deploy(stack_files):
    """Deploy the stack (start all services)."""
    destroy(stack_files)
    run_command(f"docker compose -p cicd {stack_files} up -d")

def destroy(stack_files):
    """Destroy the stack (stop and remove all services)."""
    run_command(f"docker compose -p cicd {stack_files} down")

def save(stack_files):
    """Save the git-server data to a backup."""
    stop_service(stack_files, "git-server")
    run_command(
        f"docker compose -p cicd {stack_files} run --rm git-server sh -c \"tar -czf {BACKUP_PATH} /data\""
    )
    stop_service(stack_files, "git-server")

def load(stack_files):
    """Load the git-server data from a backup."""
    stop_service(stack_files, "git-server")
    run_command(
        f"docker compose -p cicd {stack_files} run --rm git-server sh -c \"tar -xzf {BACKUP_PATH} -C /\""
    )
    stop_service(stack_files, "git-server")

def main():
    stack_files = find_stack_files()
    targets = get_targets(stack_files)

    import argparse
    parser = argparse.ArgumentParser(description="Manage docker-compose services.")
    parser.add_argument("action", choices=["status", "deploy", "destroy", "save", "load"] + targets, help="Action to perform")
    args = parser.parse_args()

    if args.action == "status":
        status(stack_files)
    elif args.action == "deploy":
        deploy(stack_files)
    elif args.action == "destroy":
        destroy(stack_files)
    elif args.action == "save":
        save(stack_files)
    elif args.action == "load":
        load(stack_files)
    elif args.action in targets:
        stop_service(stack_files, args.action)
        start_service(stack_files, args.action)
    else:
        print(f"Unknown action: {args.action}")

if __name__ == "__main__":
    main()
