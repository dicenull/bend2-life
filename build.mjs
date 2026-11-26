import {readFileSync,writeFileSync} from 'node:fs';
import {execFileSync} from 'node:child_process';
const root=new URL('./',import.meta.url);
execFileSync(process.env.BEND || 'bend',['main.bend','-o','life.mjs'],{cwd:root,stdio:'inherit'});
const read=(name)=>readFileSync(new URL(name,root),'utf8');
const js=read('life.mjs');
if(!/export default \{/.test(js))throw Error('ES module default export not found');
const baked=js.replace(/export default \{/,'return {').replace(/<\/script/gi,'<\\/script');
const board=read('board.mjs').replace(/^export\s+/gm,'');
const html=read('browser.template.html')
  .replace('// BEND_COMPILED_MODULE',()=>baked)
  .replace('// BOARD_MODULE',()=>board);
writeFileSync(new URL('index.html',root),html);
