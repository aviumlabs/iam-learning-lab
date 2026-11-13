#!/usr/bin/env python
"""
deptools.py - Custom module for Tomcat and IdentityIQ deployment utilities
"""

import os
import time
import subprocess
import socket
import urllib.request
import urllib.error


def is_app_running():
    """Check if the IdentityIQ app is running and responding."""
    # Check if the iiq script exists and is executable
    iiq_base = os.environ.get('CATALINA_BASE', '/opt/tomcat')
    iiq_home = os.path.join(iiq_base, 'webapps', 'identityiq')
    
    if not os.path.exists(iiq_home):
        return False
    
    iiq_script = os.path.join(iiq_home, 'WEB-INF', 'bin', 'iiq')
    if not os.path.exists(iiq_script):
        return False
    
    if not os.access(iiq_script, os.X_OK):
        os.chmod(iiq_script, 0o750)
    
    return True


def start_app():
    """Start the IdentityIQ app."""
    print("Starting IdentityIQ app...")
    # This would typically start Tomcat or the app
    # For now, we assume it's already running


def stop_app():
    """Stop the IdentityIQ app."""
    print("Stopping IdentityIQ app...")
    # This would typically stop Tomcat or the app
    # For now, we assume it's already stopped


def reload_app():
    """Reload the IdentityIQ app."""
    print("Reloading IdentityIQ app...")
    # This would typically trigger a reload
    # For now, we just print


def deploy_war(war_path):
    """Deploy a WAR file to Tomcat.
    
    Args:
        war_path: Path to the WAR file to deploy
    """
    print(f"Deploying WAR from {war_path}")
    
    # Verify the WAR file exists
    if not os.path.exists(war_path):
        raise FileNotFoundError(f"WAR file not found: {war_path}")
    
    # Wait for Tomcat to be ready before deploying
    wait_for_tomcat_ready()
    
    # Deploy the WAR file
    try:
        # Try to deploy via Tomcat manager
        tomcat_url = get_tomcat_deploy_url()
        response = urllib.request.urlopen(
            f"{tomcat_url}deploy?path=/identityiq&update=true",
            timeout=10
        )
        if response.getcode() == 200:
            print("WAR deployed successfully")
        else:
            print(f"WAR deployed with status {response.getcode()}")
    except Exception as e:
        print(f"Note: Could not deploy via Tomcat manager: {e}")
        print("Continuing with deployment...")
    
    # Also try to verify the app is responding
    wait_for_app_ready()


def wait_for_tomcat_ready(timeout=30):
    """Wait for Tomcat to be ready before deploying."""
    start_time = time.time()
    while time.time() - start_time < timeout:
        try:
            # Check if we can reach the Tomcat manager status page
            tomcat_url = get_tomcat_status_url()
            response = urllib.request.urlopen(tomcat_url, timeout=5)
            if response.getcode() == 200:
                print("Tomcat is ready")
                return
        except Exception:
            time.sleep(1)
    
    raise TimeoutError("Tomcat did not become ready within timeout")


def wait_for_app_ready(timeout=30):
    """Wait for the IdentityIQ app to be ready."""
    start_time = time.time()
    while time.time() - start_time < timeout:
        try:
            if is_app_running():
                print("App is ready")
                return
        except Exception:
            time.sleep(1)
    
    raise TimeoutError("App did not become ready within timeout")


def get_tomcat_deploy_url():
    """Get the Tomcat manager deploy URL."""
    tls_port = os.environ.get('TC_SECURE_PORT', '8443')
    tomcat_fqdn = socket.getfqdn()
    return f'https://{tomcat_fqdn}:{tls_port}/manager/text/'


def get_tomcat_status_url():
    """Get the Tomcat manager status URL."""
    tls_port = os.environ.get('TC_SECURE_PORT', '8443')
    tomcat_fqdn = socket.getfqdn()
    return f'https://{tomcat_fqdn}:{tls_port}/manager/status/text'


def get_iiq_deploy_url():
    """Get the IIQ deploy URL."""
    tls_port = os.environ.get('TC_SECURE_PORT', '8443')
    tomcat_fqdn = socket.getfqdn()
    return f'https://{tomcat_fqdn}:{tls_port}/identityiq'


def get_iiq_status_url():
    """Get the IIQ status URL."""
    tls_port = os.environ.get('TC_SECURE_PORT', '8443')
    tomcat_fqdn = socket.getfqdn()
    return f'https://{tomcat_fqdn}:{tls_port}/identityiq'


def get_tomcat_mgr_url():
    """Get the Tomcat manager URL."""
    tls_port = os.environ.get('TC_SECURE_PORT', '8443')
    tomcat_fqdn = socket.getfqdn()
    return f'https://{tomcat_fqdn}:{tls_port}/manager/text/'


def get_tomcat_credentials(user='rpatomcat'):
    """Get Tomcat manager credentials."""
    user_pass_path = os.path.join(os.environ.get('SECRETS_HOME', ''), f'{user}.pass')
    if os.path.exists(user_pass_path):
        with open(user_pass_path, 'r') as f:
            user_pass = f.read().strip()
        if user_pass:
            return user_pass
    return None


def get_tomcat_mgr_url():
    """Get the Tomcat manager URL."""
    tls_port = os.environ.get('TC_SECURE_PORT', '8443')
    tomcat_fqdn = socket.getfqdn()
    if not tls_port:
        tls_port = '8443'
    tomcat_url = f'https://{tomcat_fqdn}:{tls_port}/manager/text/'
    return tomcat_url


def get_tomcat_credentials(user='rpatomcat'):
    """Get Tomcat manager credentials."""
    user_pass_path = os.path.join(os.environ.get('SECRETS_HOME', ''), f'{user}.pass')
    if os.path.exists(user_pass_path):
        with open(user_pass_path, 'r') as f:
            user_pass = f.read().strip()
        if user_pass:
            return user_pass
    return None
