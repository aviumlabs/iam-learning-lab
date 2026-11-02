"""
Setup Secrets Utility
This script generates cryptographically secure secrets and injects them into
the Kubernetes cluster as Secret objects.

Usage:
  python3 scripts/setup_secrets.py --name <secret_name> --keys <key1=val1,key2=val2> --namespace <namespace>

Arguments:
  --name, -n : The name of the Kubernetes Secret (e.g., "db-secret").
  --keys, -k : A comma-separated list of key=value pairs (e.g., "postgres_password=pass,database_url=url").
  --namespace, -ns : The Kubernetes namespace (default: "default").
  --length, -l : The length of the generated passwords (default: 32).
  --type, -t : The type of password: "alphanumeric" or "complex" (default: "alphanumeric").

Prerequisites:
- kubectl installed and configured.
- Python 3.8+
"""

import secrets
import string
import subprocess
import sys
import argparse

def generate_password(length, password_type):
    """Generates a secure random password based on the specified type."""
    if password_type == "alphanumeric":
        characters = string.ascii_letters + string.digits
    elif password_type == "complex":
        characters = string.ascii_letters + string.digits + "!@#$%^&*()-_=+<>?\"'\""
    else:
        raise ValueError(f"Invalid password type: {password_type}. Use 'alphanumeric' or 'complex'.")

    return ''.join(secrets.choice(characters) for _ in range(length))

def create_kubernetes_secret(secret_name, keys, namespace):
    """
    Creates a Kubernetes Secret using 'kubectl create secret generic'.
    """
    try:
        # Base command
        cmd = ["kubectl", "create", "secret", "generic", secret_name, "--namespace", namespace]
        
        # Add each key/value pair
        for key, value in keys.items():
            cmd.extend(["--from-literal", f"{key}={value}"])
        
        subprocess.run(cmd, check=True, capture_output=True)
        print(f"Successfully created secret {secret_name} in namespace {namespace}")
    except subprocess.CalledProcessError as e:
        print(f"Error creating secret {secret_name}: {e.stderr.decode()}")
    except FileNotFoundError:
        print("Error: 'kubectl' not found. Please ensure kubectl is installed and in your PATH.")
        sys.exit(1)

def main():
    parser = argparse.ArgumentParser(description="Generate and inject secrets into Kubernetes.")
    parser.add_argument("--name", "-n", required=True, help="The name of the Kubernetes Secret (e.g., 'db-secret').")
    parser.add_argument("--keys", "-k", required=True, help="A comma-separated list of key=value pairs (e.g., 'postgres_password=pass,database_url=url').")
    parser.add_argument("--namespace", "-ns", default="default", help="The Kubernetes namespace (default: 'default').")
    parser.add_argument("--length", "-l", type=int, default=32, help="The length of the generated passwords (default: 32).")
    parser.add_argument("--type", "-t", choices=["alphanumeric", "complex"], default="alphanumeric", 
                         help="The type of password: 'alphanumeric' or 'complex' (default: alphanumeric).")

    args = parser.parse_args()

    # Parse keys
    # Logic: if a pair is "key=value", use the value. 
    # If a pair is just "key", generate a password.
    secret_data = {}
    key_pairs = args.keys.split(",")
    
    for pair in key_pairs:
        if "=" in pair:
            k, v = pair.split("=", 1)
            secret_data[k.strip()] = v.strip()
        else:
            k = pair.strip()
            secret_data[k] = generate_password(args.length, args.type)
            print(f"Generated password for {k}: {secret_data[k]}")

    create_kubernetes_secret(args.name, secret_data, args.namespace)
    print("Success!")

if __name__ == "__main__":
    main()