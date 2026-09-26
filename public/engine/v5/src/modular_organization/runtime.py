"""Bounded OpenSCAD invocation shared by every rendering path.

The executable and timeout are trusted host configuration, never request fields.
"""
from __future__ import annotations
import os,re,subprocess

def run_scad(cmd, *, cwd=None, capture_output=True, text=True):
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
