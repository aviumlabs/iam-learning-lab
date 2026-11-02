#!/usr/bin/env python
# iiqdeptools.py
# Copyright 2024, 2025, 2026 Michael Konrad 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

import getopt
import logging
import os
import re
import shutil
import socket
import subprocess
import sys
import time

from pathlib import Path
from deptools import deploy_war, start_app, stop_app, reload_app, is_app_running


bk_path = os.environ['BACKUP_HOME']
log_file = f'{bk_path}/deptools.log'
logging.basicConfig(format='%(asctime)s %(message)s', filename=log_file, encoding='utf-8', level=logging.INFO)
logger = logging.getLogger(__name__)
STAGING_DIR = os.path.join(bk_path, 'iiqbuild')


class CommandFailedError(Exception):
    """Custom exception for command failures."""
    pass


def setup_pgpass():
    pgpass_src = os.path.abspath(os.path.join('./.pgpass'))
    pgpass_dest = os.path.abspath(os.path.join(STAGING_DIR, '.pgpass'))
    
    print(f"DEBUG: pgpass_src = {pgpass_src}")
    print(f"DEBUG: pgpass_dest = {pgpass_dest}")
    print(f"DEBUG: STAGING_DIR = {STAGING_DIR}")

    if not os.path.exists(pgpass_src):
        logger.warning(f"Source .pgpass file not found at {pgpass_src}")
        print(f"Source .pgpass file not found at {pgpass_src}")
        return

    with open(pgpass_src, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Ensure the directory exists
    os.makedirs(os.path.dirname(pgpass_dest), exist_ok=True)

    with open(pgpass_dest, 'w', encoding='utf-8') as f:
        f.write(content)
    
    os.chmod(pgpass_dest, 0o600)
    os.chown(pgpass_dest, os.getuid(), os.getgid())
    
    os.environ['PGPASSFILE'] = pgpass_dest
    logger.info(f"Set PGPASSFILE to {pgpass_dest}")
    print(f"Set PGPASSFILE to {pgpass_dest}")


def run_command(cmd, description, cwd=None):

    """
    Runs a command, prints output to terminal in real-time, 
    and logs it. Also checks for 'BUILD FAILED' in output.
    """
    logger.info(f"Running {description}...")
    print(f"Running {description}...")
    
    build_failed_by_content = False
    
    try:
        process = subprocess.Popen(
            cmd,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True,
            bufsize=1,  # Line buffered
            cwd=cwd
        )
        
        if process.stdout:
            for line in process.stdout:
                clean_line = line.rstrip()
                if clean_line:
                    print(clean_line)
                    logger.info(clean_line)
                    if "BUILD FAILED" in clean_line:
                        build_failed_by_content = True
        
        process.wait()
        return_code = process.returncode
        
        if return_code != 0 or build_failed_by_content:
            error_msg = f"{description} failed"
            if build_failed_by_content and return_code == 0:
                error_msg += " (detected via 'BUILD FAILED' in output)"
            else:
                error_msg += f" with exit code {return_code}"
            
            logger.error(error_msg)
            print(error_msg)
            raise CommandFailedError(error_msg)
        
        return return_code
            
    except Exception as e:
        if isinstance(e, CommandFailedError):
            raise e
        error_msg = f"Exception during {description}: {str(e)}"
        logger.error(error_msg)
        print(error_msg)
        raise CommandFailedError(error_msg)


def normalize_line_endings(dest):
    with open(dest, 'r', encoding='utf-8') as f:
        lines = f.readlines()
    with open(dest, 'w', encoding='utf-8') as f:
        for line in lines:
            f.write(line.replace('\r', ''))

def safe_copy(src, dest, is_dir=True):
    """
    Helper to copy files or directories with error handling and logging.
    """
    try:
        if is_dir:
            shutil.copytree(src, dest, dirs_exist_ok=True)
        else:
            shutil.copy2(src, dest)
        logger.info(f"Successfully copied {src} to {dest}")
    except Exception as e:
        error_msg = f"Failed to copy {src} to {dest}: {str(e)}"
        logger.error(error_msg)
        print(error_msg)
        raise CommandFailedError(error_msg)


def main(argv):
    inst_name = os.environ.get('INSTANCE_NAME', '')
    os.environ['SPTARGET'] = inst_name
    #setup_pgpass()
    
    # main program
    help_text = """iiqdeptools.py [-h|--help] [-c|--config-iiq] [-r|--backup-db SCHEMA] 
                               [-d|--deploy-iiq EXTEND] [-H|--db-host HOST] [-P|--db-port PORT]
    Options:
    -h, --help              Show this help message and exit
    -c, --config-iiq        Configure the IdentityIQ environment
    -r, --backup-db SCHEMA  Backup the specified database schema
    -b, --build-iiq  WAR    Build IdentityIQ, pass y if war should be built, n if only the database schema should be extracted.
    -d, --deploy-iiq EXTEND Build and deploy IdentityIQ, pass y if extended schema 
                            should be installed.
    -H, --db-host HOST      Database hostname (default: 'db')
    -P, --db-port PORT      Database port (default: '5432')
    """

    db_host = 'db'
    db_port = '5432'
    
    command = None
    command_arg = None

    try:
        opts, args = getopt.getopt(argv, "hcr:b:d:H:P:", ["help", "config-iiq", "backup-db=", "build-iiq=", "deploy-iiq=", "db-host=", "db-port="])

        for opt, arg in opts:
            if opt in ('-h', '--help'):
                print(help_text)
                sys.exit()
            elif opt in ('-c', '--config-iiq'):
                command = 'config'
            elif opt in ('-r', '--backup-db'):
                command = 'backup'
                command_arg = arg
            elif opt in ('-b', '--build-iiq'):
                command = 'build'
                command_arg = arg
            elif opt in ('-d', '--deploy-iiq'):
                command = 'deploy'
                command_arg = arg
            elif opt in ('-H', '--db-host'):
                db_host = arg
            elif opt in ('-P', '--db-port'):
                db_port = arg
            else:
                print(help_text)
                sys.exit()

        if command == 'config':
            config_iiq(db_host, db_port)
        elif command == 'backup':
            backup_db(command_arg)
        elif command == 'build':
            if not command_arg:
                build_iiq(db_host=db_host, db_port=db_port)
            elif command_arg.lower() == 'y':
                build_iiq(war=True, db_host=db_host, db_port=db_port)
            elif command_arg.lower() == 'n':
                build_iiq(war=False, db_host=db_host, db_port=db_port)
            else:
                print(help_text)
                sys.exit()
        elif command == 'deploy':
            if not command_arg:
                deploy_iiq(db_host=db_host, db_port=db_port)
            elif command_arg.lower() == 'y':
                deploy_iiq(extend_schema=True, db_host=db_host, db_port=db_port)
            elif command_arg.lower() == 'n':
                deploy_iiq(extend_schema=False, db_host=db_host, db_port=db_port)
            else:
                print(help_text)
                sys.exit()
        elif command is None:
            print(help_text)
            sys.exit()

    except getopt.GetoptError:
        print(help_text)
        sys.exit(2)
    except CommandFailedError as e:
        print(f"\nFATAL ERROR: {e}")
        sys.exit(1)
    except Exception as e:
        print(f"\nUNEXPECTED ERROR: {e}")
        sys.exit(1)


def config_iiq(db_host: str = 'db', db_port: str = '5432'):
    """
    This build specifically supports PostgreSQL.
    Initialize the IdentityIQ environment by extracting the build,
    copying and updating properties files, and installing the databases.
    """

    logger.info("Initializing IdentityIQ environment...")
    print("Initializing IdentityIQ environment...")
    # Always run build_iiq to ensure STAGING_DIR is correctly populated.
    # build_iiq(war=False) will handle the Ant execution and will run
    # a 'clean' if extract/ is already present.
    build_iiq(war=False, db_host=db_host, db_port=db_port)

    #copy_update_iiq_properties(db_host, db_port)
    
    ssb_home = os.environ['SSB_HOME']
    extract_path = os.path.join(STAGING_DIR, 'build', 'extract', 'WEB-INF', 'database')
    
    # Now that build_iiq has run, extract_path is guaranteed to exist if the build succeeded.
    iiq_tables_path = os.path.join(extract_path,'create_identityiq_tables-8.4.postgresql')
    up_file = list(Path(extract_path).glob('upgrade_identityiq_tables-8.4*.postgresql'))
    
    if not up_file:
        raise FileNotFoundError(f"Could not find upgrade script in {extract_path}")

    iiq_tables_update_path = str(up_file[0])
    
    logger.info("Installing IdentityIQ databases...")
    print("Installing IdentityIQ databases...")
    install_db_schema(iiq_tables_path)
    install_db_schema(iiq_tables_update_path)
    logger.info("IdentityIQ environment initialization complete.")
    print("IdentityIQ environment initialization complete.")


def build_iiq(war: bool = True, db_host: str = 'db', db_port: str = '5432'):
    """
    Build IdentityIQ by running the build.sh script. If war is True, build the 
    war file, otherwise extract the database schema.
    """
    ssb_home = os.environ['SSB_HOME']
    cat_base = os.environ['CATALINA_BASE']
    inst_name = os.environ['INSTANCE_NAME']
    os.environ['SPTARGET'] = inst_name
    #build = get_build_script()
    initialize_sphome()
    os.makedirs(STAGING_DIR, exist_ok=True)
    #setup_pgpass()

    # Prepare properties for Ant in STAGING_DIR
    copy_update_iiq_properties(db_host, db_port)

    # Copy essential build files first so Ant can perform extraction
    safe_copy(os.path.join(ssb_home, "build.xml"), os.path.join(STAGING_DIR, "build.xml"), is_dir=False)
    safe_copy(os.path.join(ssb_home, "servers.properties"), os.path.join(STAGING_DIR, "servers.properties"), is_dir=False)
    safe_copy(os.path.join(ssb_home, "build.properties"), os.path.join(STAGING_DIR, "build.properties"), is_dir=False)
    safe_copy(os.path.join(ssb_home, ".pgpass"), os.path.join(STAGING_DIR, ".pgpass"), is_dir=False)
    os.chmod(os.path.join(STAGING_DIR, ".pgpass"), 0o600)

    build_dir = os.path.join(STAGING_DIR, 'build')
    os.makedirs(build_dir, exist_ok=True)

    # Point Ant to the build.xml in STAGING_DIR
    build_xml = os.path.join(STAGING_DIR, 'build.xml')
    ant_cmd_args = ['ant', '-d', '-f', build_xml]
    #+ ant_overrides

    # Copy the supporting IdentityIQ build files and directories
    safe_copy(os.path.join(ssb_home, "base"), os.path.join(STAGING_DIR, "base"), is_dir=True)
    safe_copy(os.path.join(ssb_home, "config"), os.path.join(STAGING_DIR, "config"), is_dir=True)
    safe_copy(os.path.join(ssb_home, "connectorsrc"), os.path.join(STAGING_DIR, "connectorsrc"), is_dir=True)
    safe_copy(os.path.join(ssb_home, "db"), os.path.join(STAGING_DIR, "db"), is_dir=True)
    safe_copy(os.path.join(ssb_home, "dependency-check-ant"), os.path.join(STAGING_DIR, "dependency-check-ant"), is_dir=True)
    safe_copy(os.path.join(ssb_home, "lib"), os.path.join(STAGING_DIR, "lib"), is_dir=True)
    safe_copy(os.path.join(ssb_home, "pluginsrc"), os.path.join(STAGING_DIR, "pluginsrc"), is_dir=True)
    safe_copy(os.path.join(ssb_home, "scripts"), os.path.join(STAGING_DIR, "scripts"), is_dir=True)
    safe_copy(os.path.join(ssb_home, "servicestools"), os.path.join(STAGING_DIR, "servicestools"), is_dir=True)
    
    # Normalize Java files in servicestools
    servicestools_dir = os.path.join(STAGING_DIR, "servicestools")
    logger.info(f"Normalizing Java files in {servicestools_dir}...")
    print(f"Normalizing Java files in {servicestools_dir}...")
    for java_file in Path(servicestools_dir).rglob("*.java"):
        normalize_line_endings(str(java_file))
    safe_copy(os.path.join(ssb_home, "src"), os.path.join(STAGING_DIR, "src"), is_dir=True)
    safe_copy(os.path.join(ssb_home, "web"), os.path.join(STAGING_DIR, "web"), is_dir=True)

    # Run build clean if previous build is existing 
    if os.path.exists(os.path.join(STAGING_DIR, 'build', 'extract')):
        run_command(ant_cmd_args + ["clean"], "build clean", cwd=STAGING_DIR)

    if war:
        # Run final WAR build
        run_command(ant_cmd_args + ["war"], "building war", cwd=STAGING_DIR)
        logger.info("IdentityIQ build completed.")
        print("IdentityIQ build completed.")

    else:
        # Run build to extract the database schema
        run_command(ant_cmd_args, "building IdentityIQ", cwd=STAGING_DIR)
        logger.info("IdentityIQ build completed.")
        print("IdentityIQ build completed.")


def deploy_iiq(extend_schema: bool = False, db_host: str = 'db', db_port: str = '5432'):
    ssb_home = os.environ['SSB_HOME']
    logger.info("Preparing deployment...")
    print("Preparing deployment...")

    # Deploy the war
    iiq_war_path = os.path.join(STAGING_DIR, 'build', 'deploy', 'identityiq.war')

    if os.path.exists(iiq_war_path):
        logger.info("Deploying IdentityIQ...")
        print("Deploying IdentityIQ...")
        deploy_war(iiq_war_path)
    
    else:
        raise FileNotFoundError("WAR file not found, unable to deploy IdentityIQ.")

    # Import the IIQ initialization files
    initialize_iiq("sp.init-custom.xml")

    if extend_schema:
        install_iiq_extended_schema()


def install_iiq_extended_schema():
    """
    Install the IdentityIQ extended schema by running the iiq extendedSchema 
    command, then initialize the database tables with the 
    add_identityiq_extensions.postgresql script.
    """
    logger.info("Extending database schema...")
    print("Extending database schema...")
    iiq_base = os.environ['CATALINA_BASE']
    iiq_wi_path = os.path.join(iiq_base, 'webapps', 'identityiq', 'WEB-INF')

    iiq = get_iiq_script()
    if os.path.exists(iiq_wi_path):
        run_command([iiq, 'extendedSchema'], "extended schema initialization")

        # add_identityiq_extensions.postgresql
        # location: $CATALINA_BASE\webapps\identityiq\WEB-INF\database\add_identityiq_extensions.postgresql
        extend_iiq_db_path = os.path.join(iiq_wi_path, 'database', 'add_identityiq_extensions.postgresql')
        install_db_schema(extend_iiq_db_path, database='identityiq')


def backup_db(database: str):
    logger.info("Backup database...")
    backup_path = os.environ['BACKUP_HOME']

    pg_url = get_postgresql_url(database)

    run_command(['pg_dump',
                 pg_url,
                 '-F',
                 'c',
                 '-f',
                 os.path.join(backup_path, f'{database}_backup.dump')], "database backup")


def copy_update_iiq_properties(db_host: str = 'db', db_port: str = '5432'):
    logger.info("Copying IdentityIQ property files...")
    print("Copying IdentityIQ property files...")

    ssb_home = os.environ['SSB_HOME']
    inst_name = os.environ['INSTANCE_NAME']
    
    src_iiq = os.path.join(ssb_home, 'sandbox.iiq.properties')
    src_log4j2 = os.path.join(ssb_home, 'sandbox.log4j2.properties')
    src_target = os.path.join(ssb_home, 'sandbox.target.properties')

    dest_iiq_stg = os.path.join(STAGING_DIR, inst_name + '.iiq.properties')
    dest_log4j2_stg = os.path.join(STAGING_DIR, inst_name + '.log4j2.properties')
    dest_target_stg = os.path.join(STAGING_DIR, inst_name + '.target.properties')

    # Ensure STAGING_DIR exists for these copies
    os.makedirs(STAGING_DIR, exist_ok=True)

    # 1. iiq.properties
    if not os.path.exists(dest_iiq_stg):
        print(f"  Copying {src_iiq} to {dest_iiq_stg}")
        shutil.copyfile(src_iiq, dest_iiq_stg)
    normalize_line_endings(dest_iiq_stg)
    update_iiq_properties(dest_iiq_stg, db_host, db_port)

    # 2. log4j2.properties
    if not os.path.exists(dest_log4j2_stg):
        print(f"  Copying {src_log4j2} to {dest_log4j2_stg}")
        shutil.copyfile(src_log4j2, dest_log4j2_stg)
    normalize_line_endings(dest_log4j2_stg)
    update_log4j2_properties(dest_log4j2_stg)

    # 3. target.properties
    if not os.path.exists(dest_target_stg):
        print(f"  Copying {src_target} to {dest_target_stg}")
        shutil.copyfile(src_target, dest_target_stg)
    normalize_line_endings(dest_target_stg)


def create_database(database: str = 'postgres'):
    pg_url = get_postgresql_url(database)

    # Create the parent database if it does not exist
    create_database_sql = f'"CREATE DATABASE {database};"'

    psql_command = [
        'psql',
        pg_url,
        '-c',
        create_database_sql
    ]

    run_command(psql_command, "database creation")


def get_build_script() -> str:
    os.environ['SPTARGET'] = os.environ['INSTANCE_NAME']
    ssb_home = os.environ['SSB_HOME']
    build_script = os.path.join(ssb_home, 'build.sh')
    if not os.path.exists(build_script):
        logger.info("Build script not found.")
        raise FileNotFoundError("Build script not found.")
    else:
        if not os.access(build_script, os.X_OK):
            os.chmod(build_script, 0o750)

        return build_script


def get_iiq_script() -> str:
    iiq_base = os.environ['CATALINA_BASE']
    iiq_home = os.path.join(iiq_base, 'webapps', 'identityiq')
    while not os.path.exists(iiq_home):
        logger.info("Waiting for IIQ to be deployed...")
        time.sleep(3)

    iiq_script = os.path.join(iiq_home, 'WEB-INF', 'bin', 'iiq')
    if not os.access(iiq_script, os.X_OK):
        os.chmod(iiq_script, 0o750)

    # Set CLASSPATH 
    iiq_wi_path = os.path.join(iiq_home, 'WEB-INF')
    if 'CLASSPATH' in os.environ:
        os.environ['CLASSPATH'] = f"{os.getenv('CLASSPATH')}:{iiq_wi_path}/classes:{iiq_wi_path}/lib/identityiq.jar"

    if os.path.exists(iiq_script):
        return iiq_script
    else:
        raise FileNotFoundError("IIQ script not found.")


def get_postgresql_url(database: str = 'postgres') -> str:
    # Construct the PostgreSQL connection URL
    if 'PG_HOST' in os.environ:
        pg_host = os.environ["PG_HOST"]
    else:
        pg_host = os.uname().nodename

    if 'PG_PORT' in os.environ:
        pg_port = os.environ["PG_PORT"]
    else:
        pg_port = '5432'

    if 'PG_USER' in os.environ:
        pg_user = os.environ["PG_USER"]
    else:
        pg_user = 'postgres'

    pg_pass_path = os.environ['POSTGRES_PASSWORD_FILE']

    if not os.path.exists(pg_pass_path):
        raise FileNotFoundError("PostgreSQL password file not found.")

    pg_pass = None
    with open(pg_pass_path, 'r') as f:
       content = f.read().strip()
        if not pg_pass_path.endswith('.pgpass'):
            pg_pass = content

    if pg_pass:
        pg_url = f'postgresql://{pg_user}:{pg_pass}@{pg_host}:{pg_port}/{database}'
    else:
        pg_url = f'postgresql://{pg_user}@{pg_host}:{pg_port}/{database}'

    logger.debug(f'DEBUG pg_url...{pg_url}')
    
    return pg_url
    

def get_tomcat_mgr_url() -> str:
    tls_port = os.environ['TC_SECURE_PORT']
    #tomcat_host = os.uname().nodename
    tomcat_fqdn = socket.getfqdn()
    if not tls_port:
        tls_port = '8443'
    tomcat_url = f'https://{tomcat_fqdn}:{tls_port}/manager/text/'
    return tomcat_url


def get_tomcat_credentials(user: str) -> str:
    user_pass_path = os.path.join(os.environ['SECRETS_HOME'], f'{user}.pass')
    if os.path.exists(user_pass_path):
        with open(user_pass_path, 'r') as f:
            user_pass = f.read().strip()
        if user_pass:
            return user_pass
        else:
            raise ValueError(f"{user} password file is empty.")
    else:
        raise FileNotFoundError(f"{user} password file not found.")
    

def initialize_iiq(init_file: str = 'init.xml'):
    """
    Run the post-install initialization script to set up IIQ after the WAR 
    file has been deployed and the application is running.
    """
    logger.info("Initialization IdentityIQ...")
    print("Initializing IdentityIQ...")
    
    iiq_base = os.environ['CATALINA_BASE']
    iiq_wi_path = os.path.join(iiq_base, 'webapps', 'identityiq', 'WEB-INF')
    iiq = get_iiq_script()

    # IdentityIQ initialization file to be imported
    init_xml_path = f"{iiq_wi_path}/config/{init_file}"

    # Create the file for automating import
    bk_path = os.environ['BACKUP_HOME']
    import_inits_path = os.path.join(bk_path, 'import-inits.txt')

    if not os.path.exists(import_inits_path):
        with open(import_inits_path, 'w') as f:
            f.write('import ' + init_xml_path + '\n')

    run_command([iiq, 'console', '-f', import_inits_path], "initialization")
    logger.info("Initialization completed.")
    print("Initialization completed.")


def initialize_sphome():
    if not 'SPHOME' in os.environ:
        webapps_base = os.path.join(os.environ['CATALINA_BASE'], 'webapps')
        sphome = os.path.join(webapps_base, 'identityiq')

        # Set SPHOME environment variable to the path of the deployed IdentityIQ 
        # application
        os.environ['SPHOME'] = sphome


def install_db_schema(sql_file: str, database: str = 'postgres'):
    pg_url = get_postgresql_url(database)
    
    if os.path.exists(sql_file):
        logger.info(f"Loading schema file... {sql_file}")
        print(f"Loading schema file... {sql_file}")
        load_sql_file(pg_url, sql_file)
    else:
        logger.error(f"Schema file not found...{sql_file}")
        print(f"Schema file not found... {sql_file}")
        raise FileNotFoundError(f"SQL file not found.")


def load_sql_file(pg_url, sql_file_path):
    # Load the SQL file into the PostgreSQL database using psql
    psql_command = [
        'psql',
        pg_url,
        '-f',
        sql_file_path
    ]

    run_command(psql_command, "SQL file load")
    logger.info("SQL file load completed.")


def update_iiq_properties(prop_file_path: str, db_host: str, db_port: str):
    logger.info("Updating IdentityIQ properties...")
    iiq_properties_path = prop_file_path

    # Update the IdentityIQ properties database connection settings
    # We look for lines containing 'jdbc:postgresql://' and replace the host/port portion
    # This is more robust than looking for 'devsrv' specifically.
    
    with open(iiq_properties_path, 'r') as f:
        iiq_properties = f.read()

    # Regex targets: jdbc:postgresql://<any_host>:<any_port>/<rest_of_url>
    # Capturing groups: 1 (prefix), 2 (rest of URL)
    pattern = r'(jdbc:postgresql://)[^:/]+:\d+(/.*)'
    replacement = rf'\1{db_host}:{db_port}\2'

    iiq_properties = re.sub(pattern, replacement, iiq_properties)

    with open(iiq_properties_path, 'w') as f:
        f.write(iiq_properties)

    logger.info("IdentityIQ properties updated.")


def update_log4j2_properties(log4j2_prop_path: str):
    logger.info("Updating log4j2 properties...")
    log4j2_properties_path = log4j2_prop_path

    # Update the log4j2 properties to write logs to the instance logs directory
    match_term = r'env:TC_INSTANCE'
    replace_term = r'env:INSTANCE_NAME'

    with open(log4j2_properties_path, 'r') as f:
        log4j2_properties = f.read()

    log4j2_properties = re.sub(match_term, replace_term, log4j2_properties)

    with open(log4j2_properties_path, 'w') as f:
        f.write(log4j2_properties)
    
    logger.info("Log4j2 properties updated.")


if __name__ == '__main__':
    main(sys.argv[1:])
