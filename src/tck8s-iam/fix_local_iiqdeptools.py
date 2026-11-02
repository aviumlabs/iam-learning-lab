import os

target_file = './scripts/iiqdeptools.py'

with open(target_file, 'r') as f:
    lines = f.readlines()

new_lines = []
inserted_safe_copy = False
replaced_build_iiq = False

safe_copy_func = [
    '\n',
    'def safe_copy(src, dest, is_dir=True):\n',
    '    """\n',
    '    Helper to copy files or directories with error handling and logging.\n',
    '    """\n',
    '    try:\n',
    '        if is_dir:\n',
    '            shutil.copytree(src, dest, dirs_exist_ok=True)\n',
    '        else:\n',
    '            shutil.copy2(src, dest)\n',
    '        logger.info(f"Successfully copied {src} to {dest}")\n',
    '    except Exception as e:\n',
    '        error_msg = f"Failed to copy {src} to {dest}: {str(e)}"\n',
    '        logger.error(error_msg)\n',
    '        print(error_msg)\n',
    '        raise CommandFailedError(error_msg)\n',
    '\n'
]

to_replace = [
    "    shutil.copy2(os.path.join(ssb_home, 'build.xml'), os.path.join(STAGING_DIR, 'build.xml'))\n",
    "    shutil.copytree(os.path.join(ssb_home, 'scripts'), os.path.join(STAGING_DIR, 'scripts'), dirs_exist_ok=True)\n",
    "    shutil.copytree(os.path.join(ssb_home, 'lib'), os.path.join(STAGING_DIR, 'lib'), dirs_exist_ok=True)\n",
    "    shutil.copytree(os.path.join(ssb_home, 'base'), os.path.join(STAGING_DIR, 'base'), dirs_exist_ok=True)\n",
    "    shutil.copytree(os.path.join(ssb_home, 'web'), os.path.join(STAGING_DIR, 'web'), dirs_exist_ok=True)\n",
    "    shutil.copy2(os.path.join(ssb_home, 'servers.properties'), os.path.join(STAGING_DIR, 'servers.properties'))\n",
    "    shutil.copy2(os.path.join(ssb_home, 'build.properties'), os.path.join(STAGING_DIR, 'build.properties'))\n"
]

new_build_iiq_block = [
    '    safe_copy(os.path.join(ssb_home, "build.xml"), os.path.join(STAGING_DIR, "build.xml"), is_dir=False)\n',
    '    safe_copy(os.path.join(ssb_home, "scripts"), os.path.join(STAGING_DIR, "scripts"), is_dir=True)\n',
    '    safe_copy(os.path.join(ssb_home, "lib"), os.path.join(STAGING_DIR, "lib"), is_dir=True)\n',
    '    safe_copy(os.path.join(ssb_home, "base"), os.path.join(STAGING_DIR, "base"), is_dir=True)\n',
    '    safe_copy(os.path.join(ssb_home, "web"), os.path.join(STAGING_DIR, "web"), is_dir=True)\n',
    '    safe_copy(os.path.join(ssb_home, "servers.properties"), os.path.join(STAGING_DIR, "servers.properties"), is_dir=False)\n',
    '    safe_copy(os.path.join(ssb_home, "build.properties"), os.path.join(STAGING_DIR, "build.properties"), is_dir=False)\n'
]

i = 0
while i < len(lines):
    line = lines[i]
    
    # Insert safe_copy after run_command
    if not inserted_safe_copy and "raise CommandFailedError(error_msg)" in line and i < 100:
        new_lines.append(line)
        new_lines.extend(safe_copy_func)
        inserted_safe_copy = True
        i += 1
        continue
    
    # Replace build_iiq block
    if not replaced_build_iiq and line.strip() == to_replace[0].strip():
        match = True
        for j in range(1, len(to_replace)):
            if i + j >= len(lines) or lines[i+j].strip() != to_replace[j].strip():
                match = False
                break
        
        if match:
            new_lines.extend(new_build_iiq_block)
            replaced_build_iiq = True
            i += len(to_replace)
            continue
            
    new_lines.append(line)
    i += 1

with open(target_file, 'w') as f:
    f.writelines(new_lines)

print(f"Updated {target_file}: safe_copy={inserted_safe_copy}, build_iiq_replaced={replaced_build_iiq}")
