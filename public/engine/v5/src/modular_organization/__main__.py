"""Structured CLI for the same API used by a website worker."""
import argparse,json,sys
from pathlib import Path
from . import api

def main(argv=None):
    ap=argparse.ArgumentParser(description='Modular Organization geometry engine')
    ap.add_argument('command',choices=['schema','inspect','manufacture','project','audit','bom','nest','compare'])
    ap.add_argument('--request',type=Path,help='Typed JSON request for inspect/manufacture')
    ap.add_argument('-o','--output',type=Path)
    args,rest=ap.parse_known_args(argv)
    if args.command in ('project','audit','bom','nest','compare'):
        from importlib import import_module
        name={'audit':'validation','nest':'nesting','compare':'interfaces'}.get(args.command,args.command)
        tail=rest+(['-o',str(args.output)] if args.output else [])
        return import_module('.'+name,__package__).main(tail)
    if rest:ap.error('Unrecognized arguments: '+' '.join(rest))
    try:
        if args.command=='schema': result=api.describe()
        else:
            if args.request is None:ap.error('--request is required')
            request=json.loads(args.request.read_text())
            allowed={'frontend','preset','parameters','common','hardware_id'}
            if not isinstance(request,dict) or set(request)-allowed:raise ValueError('Unexpected request fields')
            if args.command=='inspect':result=api.inspect(**request)
            else:
                if args.output is None:ap.error('-o is required')
                api.manufacture(output=args.output,**request);return 0
        encoded=json.dumps(result,indent=2,allow_nan=False)
        if args.output:
            args.output.parent.mkdir(parents=True,exist_ok=True);args.output.write_text(encoded)
        else:print(encoded)
        return 2 if result.get('status')=='ERROR' else 0
    except (ValueError,RuntimeError,TypeError) as exc:
        print(json.dumps({'status':'ERROR','message':str(exc)}),file=sys.stderr);return 2
if __name__=='__main__':raise SystemExit(main())
