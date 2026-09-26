const fs=require('fs'),cp=require('child_process'),assert=require('assert/strict'),path=require('path');
const temp=fs.mkdtempSync(path.join(process.cwd(),'.layout-check-'));
try{
const run=(family,settings)=>{const result=cp.spawnSync('openscad',['-o',path.join(temp,family+'.csg'),...Object.entries(settings).flatMap(([k,v])=>['-D',k+'='+JSON.stringify(v)]),'public/engine/v5/src/modular_organization/data/scad/'+family+'.scad'],{encoding:'utf8',timeout:30000});assert.equal(result.status,0,result.stderr);assert(!/ECHO: "ERROR\||CHECK\|ERROR|^ERROR:/m.test(result.stderr),result.stderr);return result.stderr};
const stack=run('stackable',{cabinet_width:800,drawer_bank_count:2,drawer_bank_layout_mode:'independent',drawer_bank_drawer_counts:[2,3,4,4]});assert(/DIM\|DRAWER_BANK\|B1\|[^\n]*DRAWERS=2/.test(stack));assert(/DIM\|DRAWER_BANK\|B2\|[^\n]*DRAWERS=3/.test(stack));
const kitchen=run('kitchen',{cabinet_width:1600,cabinet_layout_mode:'mixed_bays',mixed_bay_count:4,mixed_bay_types:['drawers','drawers','drawers','drawers'],mixed_bay_drawer_counts:[1,2,3,4]});for(let n=1;n<=4;n++){const line=kitchen.split('\n').find(line=>line.includes('"  bank/bay ", '+n+','));assert(line&&line.includes('", drawers = ", '+n+','),line);}

console.log('Native stackable independent banks and all four kitchen column drawer counts passed.');
}finally{fs.rmSync(temp,{recursive:true,force:true})}
