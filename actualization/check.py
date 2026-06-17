#!/usr/bin/python3

import os
import sys
import yaml
import hashlib
import subprocess
import shutil
import shlex

def get_tree_hash(roots, exclude_files):
    exclude_files = {os.path.abspath(f) for f in exclude_files}
    h = hashlib.sha256()
    all_files = []
    
    for root in roots:
        root = os.path.abspath(root)
        if os.path.isfile(root):
            all_files.append(root)
        elif os.path.isdir(root):
            for dirpath, _, filenames in os.walk(root):
                for f in filenames:
                    all_files.append(os.path.abspath(os.path.join(dirpath, f)))
                    
    for path in sorted(set(all_files)):
        if path in exclude_files:
            continue
        try:
            with open(path, 'r', encoding='utf-8') as file:
                h.update(path.encode('utf-8'))
                h.update(file.read().encode('utf-8'))
        except (UnicodeDecodeError, OSError):
            pass
            
    return h.hexdigest()

def main():
    if len(sys.argv) < 2:
        print("Usage: check.py <config.yaml>")
        sys.exit(1)
        
    with open(sys.argv[1], 'r') as f:
        config = yaml.safe_load(f)
        
    repo_url = config.get('repo')
    deps = config.get('deps', [])
    run_cmd = config.get('run', '')
    outputs = config.get('outputs', [])
    exclude = config.get('exclude', [])
    
    if deps:
        cmd = "apt-get install -y " + " ".join(shlex.quote(dep) for dep in deps)
        subprocess.run(cmd, shell=True, check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        
    temp_dir = '/tmp/check_repo'
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
                
        tree_hash = get_tree_hash(abs_outputs, expanded_exclude)
        print(tree_hash)
        
    finally:
        os.chdir('/')
        shutil.rmtree(temp_dir, ignore_errors=True)

if __name__ == '__main__':
    main()
