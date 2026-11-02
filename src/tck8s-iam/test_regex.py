import re
import os

def update_iiq_properties(prop_file_path, db_host, db_port):
    with open(prop_file_path, 'r') as f:
        iiq_properties = f.read()

    # Regex targets: jdbc:postgresql://<any_host>:<any_port>/<rest_of_url>
    # Capturing groups: 1 (prefix), 2 (rest of URL)
    pattern = r'(jdbc:postgresql://)devsrv:\d+(/.*)'
    replacement = rf'\1{db_host}:{db_port}\2'

    iiq_properties = re.sub(pattern, replacement, iiq_properties)

    with open(prop_file_path, 'w') as f:
        f.write(iiq_properties)

def test_update():
    test_file = 'test_sandbox.iiq.properties'
    content = """
# Some properties
jdbc:postgresql://devsrv:5432/identityiq
another_prop=value
jdbc:postgresql://devsrv:5432/access_history
"""
    with open(test_file, 'w') as f:
        f.write(content)

    print(f"Original content:\n{content}")

    db_host = 'tck8s-iam-db'
    db_port = '5432'
    update_iiq_properties(test_file, db_host, db_port)

    with open(test_file, 'r') as f:
        new_content = f.read()

    print(f"Updated content:\n{new_content}")

    expected_substring1 = 'jdbc:postgresql://tck8s-iam-db:5432/identityiq'
    expected_substring2 = 'jdbc:postgresql://tck8s-iam-db:5432/access_history'

    if expected_substring1 in new_content and expected_substring2 in new_content:
        print("SUCCESS: Properties updated correctly.")
    else:
        print("FAILURE: Properties not updated correctly.")
        exit(1)

    os.remove(test_file)

if __name__ == '__main__':
    test_update()
