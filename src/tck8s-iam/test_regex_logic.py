import re

def test_regex(pattern, replacement, text):
    return re.sub(pattern, replacement, text)

pattern = r'(jdbc:postgresql://)[^:/]+:\d+(/.*)'
replacement = r'\1tck8s-iam-db:5432\2'
text = 'dataSource.url=jdbc:postgresql://db:5432/identityiq'

print(f"Text: {text}")
print(f"Pattern: {pattern}")
print(f"Result: {test_regex(pattern, replacement, text)}")

text2 = 'pluginsDataSource.url=jdbc:postgresql://devsrv:5432/identityiqPlugin'
print(f"Text2: {text2}")
print(f"Result2: {test_regex(pattern, replacement, text2)}")
