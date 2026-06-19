#!/usr/bin/python3

import os
import sys
import yaml
import subprocess
import shutil
import shlex

def copy_outputs_to_tracking(outputs, exclude_files, tracking_dir):
    exclude_files = {os.path.abspath(f) for f in exclude_files}

    print(outputs, exclude_files, tracking_dir)
    
    if os.path.exists(tracking_dir):
        shutil.rmtree(tracking_dir)
    os.makedirs(tracking_dir)
    
    base_dir = os.getcwd()
    
    for output in outputs:
        output_abs = os.path.abspath(output)
        if not os.path.exists(output_abs):
            continue
            
        if os.path.isfile(output_abs):
            rel_path = os.path.relpath(output_abs, base_dir)
            dest = os.path.join(tracking_dir, rel_path)
            os.makedirs(os.path.dirname(dest), exist_ok=True)
            if os.path.abspath(dest) not in exclude_files:
                shutil.copy2(output_abs, dest)
        elif os.path.isdir(output_abs):
            for dirpath, _, filenames in os.walk(output_abs):
                for f in filenames:
                    src = os.path.abspath(os.path.join(dirpath, f))
                    if src in exclude_files:
                        continue
                    rel_path = os.path.relpath(src, base_dir)
                    dest = os.path.join(tracking_dir, rel_path)
                    os.makedirs(os.path.dirname(dest), exist_ok=True)
                    shutil.copy2(src, dest)

def main():
    if len(sys.argv) < 3:
        print("Usage: check.py <config.yaml> <tracking_dir>")
        sys.exit(1)
        
    with open(sys.argv[1], 'r') as f:
        config = yaml.safe_load(f)
    
    tracking_dir = os.path.abspath(sys.argv[2])
        
    repo_url = config.get('repo')
    deps = config.get('deps', [])
    run_cmd = config.get('run', '')
    outputs = config.get('outputs', [])
    exclude = config.get('exclude', [])
    
    if deps:
        cmd = "apt-get install -y " + " ".join(shlex.quote(dep) for dep in deps)
        subprocess.run(cmd, shell=True, check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        
    temp_dir = './check_repo'
    if os.path.exists(temp_dir):
        shutil.rmtree(temp_dir)
    os.makedirs(temp_dir)
    
    try:
        subprocess.run(['git', 'clone', repo_url, temp_dir], check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        
        os.chdir(temp_dir)
        
        if run_cmd:
            subprocess.run(['bash', '-c', 'set -e\n' + run_cmd], check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            
        abs_outputs = [os.path.abspath(out) for out in outputs]
        
        expanded_exclude = []
        for exc in exclude:
            paths_to_check = [exc]
            for out in outputs:
                paths_to_check.append(os.path.join(out, exc))
                
            for p in paths_to_check:
                p_abs = os.path.abspath(p)
                if os.path.isdir(p_abs):
                    for dirpath, _, filenames in os.walk(p_abs):
                        for f in filenames:
                            expanded_exclude.append(os.path.abspath(os.path.join(dirpath, f)))
                elif os.path.isfile(p_abs):
                    expanded_exclude.append(p_abs)
                
        copy_outputs_to_tracking(abs_outputs, expanded_exclude, tracking_dir)
        
    finally:
        os.chdir('/')
        # shutil.rmtree(temp_dir, ignore_errors=True)

if __name__ == '__main__':
    main()
