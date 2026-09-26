"""Installed resource locations; never derived from request input."""
from pathlib import Path
DATA_DIR=Path(__file__).resolve().parent/'data'
SCAD_DIR=DATA_DIR/'scad'
CONFIG_DIR=DATA_DIR/'config'
FRONTENDS={name:(name+'.scad',name+'.json') for name in ('utility','shop_cart','benchtop','stackable','kitchen','drawer','equipment_stand')}
