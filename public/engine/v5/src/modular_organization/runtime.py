"""Bounded OpenSCAD invocation shared by every rendering path.

The executable and timeout are trusted host configuration, never request fields.
"""
from __future__ import annotations
import json,os,re,subprocess
from pathlib import Path

_NESTED=re.compile(r'^\[\s*\[')
_LITERAL=re.compile(r'^[\[\]\s0-9A-Za-z_.,"+\-]*$')

def nested_vector_defines(cmd, cwd=None):
    """OpenSCAD 2021 parameter files silently drop vectors of vectors (the workbench's
    module rows, for example). Repeat such values from the selected parameter set as -D
    literals right after -P, so later explicit -D definitions still override them."""
    cmd=list(cmd)
    if '-p' not in cmd or '-P' not in cmd: return cmd
    try:
        path=Path(cmd[cmd.index('-p')+1]); name=cmd[cmd.index('-P')+1]
        if not path.is_absolute() and cwd: path=Path(cwd)/path
        values=json.loads(path.read_text(encoding='utf-8'))['parameterSets'][name]
    except (OSError,KeyError,IndexError,ValueError):
        return cmd
    extra=[]
    for key,value in values.items():
        if re.fullmatch(r'[A-Za-z_][A-Za-z0-9_]*',key) and isinstance(value,str) and _NESTED.match(value) and _LITERAL.match(value):
            extra+=['-D',f'{key}={value}']
    at=cmd.index('-P')+2
    return cmd[:at]+extra+cmd[at:]

def run_scad(cmd, *, cwd=None, capture_output=True, text=True):
    cmd=nested_vector_defines(cmd,cwd)
    timeout=float(os.environ.get('MO_OPENSCAD_TIMEOUT_SECONDS','120'))
    if not 0<timeout<=1800: raise ValueError('OpenSCAD timeout must be 0..1800 seconds')
    try:
        result=subprocess.run(cmd,cwd=cwd,capture_output=capture_output,text=text,timeout=timeout)
    except subprocess.TimeoutExpired as exc:
        raise RuntimeError(f'OpenSCAD exceeded {timeout:g} seconds') from exc
    except FileNotFoundError as exc:
        raise RuntimeError('OpenSCAD executable was not found; install it or configure the host path') from exc
    # OpenSCAD can emit errors while returning zero for CSG metadata exports.
    log=(result.stdout or '')+'\n'+(result.stderr or '')
    if re.search(r'(?m)^(?:ERROR:|Parser error:)',log) and result.returncode==0:
        result.returncode=2
    return result
