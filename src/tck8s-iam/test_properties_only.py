import os
import shutil
import re
import logging

def update_iiq_properties(prop_file_path, db_host, db_port):
    print(f"Updating {prop_file_path}")
    with open(prop_file_path, 'r') as f:
        iiq_properties = f.read()
    pattern = r'(jdbc:postgresql://)[^:/]+:\d+(/.*)'
    replacement = rf'\1{db_host}:{db_port}\2'
    iiq_properties = re.sub(pattern, replacement, iiq_properties)
    with open(prop_file_path, 'w') as f:
        f.write(iiq_properties)

def update_log4j2_properties(log4j2_prop_path):
    print(f"Updating {log4j2_prop_path}")
    with open(log4j2_prop_path, 'r') as f:
        log4j2_properties = f.read()
    match_term = r'env:TC_INSTANCE'
    replace_term = r'env:INSTANCE_NAME'
    log4j2_properties = re.sub(match_term, replace_term, log4j2_properties)
    with open(log4j2_prop_path, 'w') as f:
        f.write(log4j2_properties)

def copy_update_iiq_properties(db_host, db_port):
    ssb_home = os.environ['SSB_HOME']
    cat_base = os.environ['CATALINA_BASE']
    inst_name = os.environ['INSTANCE_NAME']
    
    src_iiq = os.path.join(ssb_home, 'sandbox.iiq.properties')
    dest_iiq = os.path.join(cat_base, inst_name + '.iiq.properties')
    
    if not os.path.exists(dest_iiq):
        shutil.copyfile(src_iiq, dest_iiq)
    update_iiq_properties(dest_iiq, db_host, db_port)

    src_log4j2 = os.path.join(ssb_home, 'sandbox.log4j2.properties')
    dest_log4j2 = os.path.join(cat_base, inst_name + '.log4j2.properties')

    if not os.path.exists(dest_log4j2):
        shutil.copyfile(src_log4j2, dest_log4j2)
    update_log4j2_properties(dest_log4j2)

if __name__ == '__main__':
    copy_update_iiq_properties('tck8s-iam-db', '5432')
