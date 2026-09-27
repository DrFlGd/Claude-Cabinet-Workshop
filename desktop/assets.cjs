const path=require('node:path');
const types={'.html':'text/html; charset=utf-8','.js':'text/javascript; charset=utf-8','.css':'text/css; charset=utf-8','.json':'application/json','.wasm':'application/wasm','.svg':'image/svg+xml','.png':'image/png','.jpg':'image/jpeg','.ttf':'font/ttf'};
exports.resolveAsset=(root,input)=>{
 const url=new URL(input);if(url.protocol!=='cabinet:'||url.host!=='app')return null;
 const name=decodeURIComponent(url.pathname);
 if(name.includes('\\')||name.includes('\0'))return null;
 const file=path.resolve(root,'.'+(name==='/'?'/index.html':name));
 if(!file.startsWith(path.resolve(root)+path.sep))return null;
 return {file,type:types[path.extname(file)]||'application/octet-stream'};
};
