import('./entry').catch(error=>{
 const root=document.getElementById('root');
 if(root){root.textContent='Cabinet Workshop could not load. Refresh the page. '+String(error);root.setAttribute('role','alert');}
});
