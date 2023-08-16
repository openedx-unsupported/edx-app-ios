#!/usr/bin/env python3

import subprocess
import re

def get_simulator_udid(device_name, os_version):
    output = subprocess.run(['xcrun', 'simctl', 'list', 'devices'], capture_output=True, text=True).stdout
    lines = output.split('\n')
    os_found = False
    
    for line in lines:
        if f"-- iOS {os_version} --" in line:
            os_found = True
        elif os_found and device_name in line:
            match = re.search(r"(\w{8}-\w{4}-\w{4}-\w{4}-\w{12})", line)
            if match:
                return match.group(0)

    return None

def test_build_arguments(workspace, scheme, os_version, record):
    device_name = "iPhone 14 Pro" if os_version.startswith("16") else "iPhone 13 Pro"
    udid = get_simulator_udid(device_name, os_version)
    
    args = [
        'xcodebuild', '-workspace', workspace, '-scheme', scheme, '-sdk', 'iphonesimulator',
        '-destination', f'id={udid},arch=x86_64', 'test'
    ]

    if record:
        args.extend(['OTHER_SWIFT_FLAGS=\$(OTHER_SWIFT_FLAGS) -D RECORD_SNAPSHOTS'])
    
    xcodebuild_cmd = ' '.join(args)
    full_command = f"{xcodebuild_cmd} | xcpretty"
    
    return ['/bin/bash', '-c', full_command]

def rtl_scheme_for_scheme(scheme):
    return f"{scheme}-RTL"

operating_systems = {"currentOS": "16.4", "previousOS": "15"}
directions = {"LTR": "edX", "RTL": rtl_scheme_for_scheme("edX")}
commands = {"test": {"record": False}, "recordSnapshots": {"record": True}}

for os_key, os_value in operating_systems.items():
    for direction_key, direction_value in directions.items():
        for command_key, command_value in commands.items():
            record = command_value["record"]
            task_name = f"{command_key}{direction_key.capitalize()}{os_key.capitalize()}"
            args = test_build_arguments("edX.xcworkspace", direction_value, os_value, record)
            
            try:
                process = subprocess.Popen(args, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
                print(f"Running {task_name} task...")
                
                while process.poll() is None:
                    line = process.stdout.readline()
                    if line:
                        print(line.strip())
                
                stdout, stderr = process.communicate()
                if process.returncode == 0:
                    print(f"{task_name} task completed successfully.")
                else:
                    print(f"Error executing {task_name} task:")
                    print(stderr)
            except subprocess.CalledProcessError as e:
                print(f"Error executing {task_name} task: {e}")
                print(e.stderr)

print("All tasks completed.")
