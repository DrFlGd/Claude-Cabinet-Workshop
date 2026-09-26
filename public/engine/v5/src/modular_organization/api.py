"""Website-facing API. Run in a bounded worker with an isolated output directory."""
from __future__ import annotations
import json,tempfile
from pathlib import Path
from .configuration import compile_config,write_parameter_file,catalog
from .paths import SCAD_DIR,FRONTENDS
from .runtime import run_scad
from .bom import parse_bom_lines
from .project import parse_echo_payloads,parse_record

def describe():
    # Return a copy so an API client cannot mutate the process cache.
    return json.loads(json.dumps(catalog()))

def inspect(frontend,*,preset=None,parameters=None,common=None,hardware_id=None,openscad='openscad'):
    config=compile_config(frontend,preset=preset,parameters=parameters,common=common,hardware_id=hardware_id)
    with tempfile.TemporaryDirectory(prefix='mo-inspect-') as td:
        td=Path(td); param=td/'parameters.json';write_parameter_file(config,param)
        p=run_scad([openscad,'-p',str(param),'-P','Request','-o',str(td/'metadata.csg'),str(SCAD_DIR/FRONTENDS[frontend][0])],cwd=SCAD_DIR)
        log=(p.stdout or '')+'\n'+(p.stderr or '')
        if p.returncode:raise RuntimeError('OpenSCAD metadata failed: '+log[-3000:])
        checks=[]
        for line in parse_echo_payloads(log,'CHECK|'):
            _,severity,code,message=line.split('|',3);checks.append(dict(severity=severity,code=code,message=message))
        bom=parse_bom_lines(log)
        if not bom:raise RuntimeError('Renderer emitted no BOM; metadata is incomplete')
        status='ERROR' if any(c['severity']=='ERROR' for c in checks) else 'WARN' if any(c['severity']=='WARN' for c in checks) else 'PASS'
        return {'status':status,'configuration':config,'checks':checks,'bom':bom,
                'dimensions':parse_echo_payloads(log,'DIM|'),
                'interfaces':[parse_record(x) for x in parse_echo_payloads(log,'INTERFACE|')],
                'runtime_warnings':[line for line in log.splitlines() if line.startswith('WARNING:')]}

def manufacture(frontend,output,*,preset=None,parameters=None,common=None,hardware_id=None,openscad='openscad'):
    from .export import main
    config=compile_config(frontend,preset=preset,parameters=parameters,common=common,hardware_id=hardware_id)
    with tempfile.TemporaryDirectory(prefix='mo-export-') as td:
        param=Path(td)/'parameters.json';write_parameter_file(config,param)
        code=main([str(SCAD_DIR/FRONTENDS[frontend][0]),'--json',str(param),'--preset','Request','--openscad',openscad,'-o',str(Path(output).resolve())])
        if code:raise RuntimeError(f'Manufacturing export failed ({code})')
    return Path(output)

def preview(frontend,output,*,view='assembly',preset=None,parameters=None,common=None,hardware_id=None,openscad='openscad'):
    """Write an STL preview. Output path belongs to the host, never the request."""
    import os
    if view not in ('assembly','flat_3d'):raise ValueError('view must be assembly or flat_3d')
    config=compile_config(frontend,preset=preset,parameters=parameters,common=common,hardware_id=hardware_id)
    output=Path(output).resolve()
    if output.suffix.lower()!='.stl':raise ValueError('Preview output must have .stl extension')
    output.parent.mkdir(parents=True,exist_ok=True)
    with tempfile.TemporaryDirectory(prefix='mo-preview-',dir=output.parent) as td:
        td=Path(td);param=td/'parameters.json';write_parameter_file(config,param,mode=view)
        target=td/'preview.stl'
        p=run_scad([openscad,'-p',str(param),'-P','Request','-o',str(target),str(SCAD_DIR/FRONTENDS[frontend][0])],cwd=SCAD_DIR)
        log=(p.stdout or '')+'\n'+(p.stderr or '')
        if p.returncode or 'CHECK|ERROR|' in log or not target.exists():raise RuntimeError('Preview failed: '+log[-3000:])
        warnings=[line for line in log.splitlines() if line.startswith(('WARNING:','EXPORT-WARNING:'))]
        os.replace(target,output)
    return {'path':str(output),'warnings':warnings,'configuration':config}

def compose(project,*,openscad='openscad'):
    """Resolve validated MORG-1 JSON; does not mutate caller data or emit filenames."""
    from .project import resolve_project
    with tempfile.TemporaryDirectory(prefix='mo-project-') as td:
        return resolve_project(project,openscad,Path(td))
