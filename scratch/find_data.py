import os
print(f"Current Working Directory: {os.getcwd()}")
print(f"Absolute path of 'data': {os.path.abspath('data')}")
print(f"Exists: {os.path.exists('data')}")
if os.path.exists('data'):
    print(f"Contents of 'data': {os.listdir('data')}")
