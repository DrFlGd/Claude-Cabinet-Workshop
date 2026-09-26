#!/usr/bin/env python3
"""Compare Modular Organization MOI-4 external interface reports.

Inputs are REPORTS/system_contract.json files produced by
modular-organization manufacture. The checker does not infer geometry;
it compares the standards and compatibility keys emitted by OpenSCAD.
"""
from __future__ import annotations

import argparse
import json
from pathlib import Path

ROLE_MATES={
    ("male","female"),
    ("female","male"),
    ("peer","peer"),
}


def load(path: Path) -> dict:
    data=json.loads(path.read_text(encoding="utf-8"))
    if "interfaces" not in data:
        raise SystemExit(f"{path}: not a Modular Organization system_contract.json")
    return data


def external_interfaces(data: dict) -> list[dict]:
    return [r for r in data.get("interfaces",[]) if "external" in r.get("tags","").split(";")]


def parse_key(key: str|None) -> dict[str,str]:
    out={}
    for field in (key or "").split(";"):
        if "=" in field:
            k,v=field.split("=",1)
            out[k]=v
    return out


def compatible(a: dict,b: dict) -> tuple[bool,list[str]]:
    reasons=[]
    if any(not item.get(k) for item in (a,b) for k in ("standard","role","key")):
        return False,["Missing interface standard, role or key"]
    if a.get("standard") != b.get("standard"):
        reasons.append(f"standard differs ({a.get('standard')} vs {b.get('standard')})")
    if (a.get("role"),b.get("role")) not in ROLE_MATES:
        reasons.append(f"roles do not mate ({a.get('role')} vs {b.get('role')})")
    if a.get("key") != b.get("key"):
        ka,kb=parse_key(a.get("key")),parse_key(b.get("key"))
        fields=sorted(set(ka)|set(kb))
        diffs=[f"{k}: {ka.get(k,'<missing>')} vs {kb.get(k,'<missing>')}" for k in fields if ka.get(k)!=kb.get(k)]
        if diffs:
            reasons.append("compatibility geometry differs ("+"; ".join(diffs)+")")
        else:
            reasons.append("compatibility KEY differs")
    return (not reasons,reasons)


def choose(data: dict, interface_id: str|None) -> list[dict]:
    rows=external_interfaces(data)
    if interface_id is None:
        return rows
    found=[r for r in rows if r.get("id")==interface_id]
    if not found:
        raise SystemExit(f"Interface {interface_id!r} was not found")
    return found


def main(argv=None) -> int:
    ap=argparse.ArgumentParser()
    ap.add_argument("a",type=Path,help="First system_contract.json")
    ap.add_argument("b",type=Path,help="Second system_contract.json")
    ap.add_argument("--interface-a",help="Specific interface ID from first report")
    ap.add_argument("--interface-b",help="Specific interface ID from second report")
    ap.add_argument("--json",dest="json_out",type=Path,help="Optional result JSON")
    args=ap.parse_args(argv)

    da,db=load(args.a),load(args.b)
    aa,bb=choose(da,args.interface_a),choose(db,args.interface_b)
    rows=[]
    for a in aa:
        for b in bb:
            ok,reasons=compatible(a,b)
            # With no explicit IDs, only surface plausible same-standard role mates.
            if args.interface_a is None and args.interface_b is None:
                if a.get("standard") != b.get("standard"):
                    continue
                if (a.get("role"),b.get("role")) not in ROLE_MATES:
                    continue
            rows.append({
                "interface_a":a.get("id"),
                "interface_b":b.get("id"),
                "standard":a.get("standard") if a.get("standard")==b.get("standard") else None,
                "compatible":ok,
                "reasons":reasons,
                "key_a":a.get("key"),
                "key_b":b.get("key"),
            })

    result={"contract":"MOI-4","comparisons":rows}
    if args.json_out:
        args.json_out.write_text(json.dumps(result,indent=2),encoding="utf-8")
    if not rows:
        print("No plausible external interface pairs found.")
        return 1
    for r in rows:
        state="COMPATIBLE" if r["compatible"] else "INCOMPATIBLE"
        print(f"{state}: {r['interface_a']} <-> {r['interface_b']}")
        for reason in r["reasons"]:
            print(f"  - {reason}")
    return 0 if any(r["compatible"] for r in rows) else 2


if __name__=="__main__":
    raise SystemExit(main())
