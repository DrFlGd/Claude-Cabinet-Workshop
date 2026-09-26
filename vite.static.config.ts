import {defineConfig} from 'vite';
import react from '@vitejs/plugin-react';
import {fileURLToPath} from 'node:url';
export default defineConfig({
 base:process.env.CABINET_BASE_PATH||'/',
 plugins:[react()],
 resolve:{alias:{'@':fileURLToPath(new URL('.',import.meta.url))}},
 build:{outDir:'web-dist',emptyOutDir:true},
});
