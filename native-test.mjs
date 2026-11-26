import assert from 'node:assert/strict';
import {execFileSync} from 'node:child_process';
import {mkdtempSync,rmSync} from 'node:fs';
import {tmpdir} from 'node:os';
import {join} from 'node:path';
import {pathToFileURL} from 'node:url';
import Life from './life.mjs';
import {advance,getCell,makeBoard,putCell} from './board.mjs';

const dir=mkdtempSync(join(tmpdir(),'bend2-life-native-'));
try {
  async function compile(name){
    const out=join(dir,name+'.mjs');
    execFileSync(process.env.BEND||'bend',[name+'.bend','-o',out],{cwd:new URL('.',import.meta.url),stdio:'inherit'});
    return (await import(pathToFileURL(out))).default;
  }
  const G=await compile('native-board'), M=await compile('native-state'), V=await compile('native-view');
  const key=(s,code,down=true)=>M.event({$:'Key',code,down},s).value;
  const mouse={$:'Tool.Mouse'};
  const press=(s,x,y,down=true)=>M.event({$:'Press',id:0,tool:mouse,x,y,time:0,button:0,down},s).value;
  const move=(s,x,y)=>M.event({$:'Move',id:0,tool:mouse,x,y,time:0},s).value;
  const cells=(b)=>Array.from({length:b.width*b.height},(_,i)=>G.get(b,i%b.width,Math.floor(i/b.width)));
  const positions=(b)=>cells(b).flatMap((v,i)=>v?[[i%b.width,Math.floor(i/b.width)]]:[]);

  // Each actual glyph is centered, including pause and every size digit.
  for(const preset of [49,50,51])for(const running of [false,true]){
    const paused=key(M.initial(),preset), state=running?key(paused,32):paused;
    for(let i=0;i<5;i++){
      const pixels=[];
      for(let y=4;y<18;y++)for(let x=0;x<14;x++){
        if(V.color(4+17*i+x,y,state)===16763543)pixels.push([x,y]);
      }
      assert.ok(pixels.length>=20);
      const xs=pixels.map(p=>p[0]), ys=pixels.map(p=>p[1]);
      assert.deepEqual([Math.min(...xs),Math.min(...ys),Math.max(...xs),Math.max(...ys)],[2,6,11,15]);
    }
  }

  const nil={$:'Nil'};
  const batch=(e)=>({$:'Con',head:e,tail:nil});
  let s=M.initial();
  assert.equal(M.finish_frame(0,M.events_dirty(nil,s,false)).snd,false,'idle frame reuses the image');
  const activated=M.events_dirty(batch({$:'Key', code:32, down:true}),s,false);
  assert.equal(activated.snd,true);
  assert.equal(M.finish_frame(0,activated).fst.value.running,true);
  assert.equal(positions(s.board).length,5);
  const initial=s.board;
  s=key(s,32);
  assert.equal(s.running,true);
  assert.equal(key(s,32).running,true,'held Space does not retrigger');
  s=M.clock_step(100,s);
  assert.deepEqual(s.board,G.advance(initial));
  assert.deepEqual(M.clock_step(234,s),s);
  assert.notDeepEqual(M.clock_step(235,s).board,s.board);
  s=key(key(s,32,false),32);
  assert.equal(s.running,false);
  assert.deepEqual(M.clock_step(999,s),s);
  const after=key(s,63235);
  assert.deepEqual(after.board,G.advance(s.board));
  assert.equal(after.running,false);
  assert.equal(M.event({$:'Close'},s).$,'None');

  s=key(M.initial(),99);
  const bx=16*4, by=37*4;
  s=press(s,bx+1,by+1);
  assert.equal(G.get(s.board,0,0),1);
  s=move(s,bx+5,by+1);
  assert.equal(G.get(s.board,1,0),1);
  s=move(s,-1,by);
  assert.equal(positions(s.board).length,2,'outside a drag does not edit the board');
  s=press(s,bx+5,by+1,false);
  assert.deepEqual(move(s,bx+9,by+1).board,s.board);
  assert.notEqual(V.color(16,37,s),V.color(18,37,s),'live/dead pixels differ');
  assert.equal(press(s,22,20).running,true,'play toolbar hit target');
  assert.equal(press(s,342,20).board.width,128,'size toolbar hit target');

  const minus=(4+17*5+7)*4, plus=(113+7)*4;
  let mag=key(M.initial(),99);
  const unzoomed=mag.board;
  assert.equal(press(mag,minus,44).zoom,1);
  const labels=new Set();
  for(let level=1;level<=4;level++){
    assert.equal(mag.zoom,level);
    const glyph=[];
    for(let y=9;y<14;y++)for(let x=104;x<107;x++){
      glyph.push(V.color(x,y,mag)===11451601);
    }
    assert.ok(glyph.some(Boolean));
    assert.equal(V.color(108,11,mag),11451601,'x suffix is visible');
    labels.add(glyph.join(','));
    if(level===3){
      const clicked=press(mag,269,273);
      assert.deepEqual(positions(clicked.board),[[49,29]]);
      assert.equal(V.color(67,68,clicked),16759152);
      assert.equal(V.color(69,70,clicked),16759152,'the cell spans 3 x 3 tiles');
      assert.notEqual(V.color(70,70,clicked),16759152);
    }
    if(level<4)mag=press(mag,plus,44);
  }
  assert.equal(labels.size,4,'all four levels render distinct digits');
  assert.equal(press(mag,429,44).zoom,4,'label does not act like a zoom button');
  assert.equal(press(mag,plus,44).zoom,4);
  assert.deepEqual(mag.board,unzoomed,'zoom buttons never edit cells');
  mag=press(mag,273,277);
  assert.deepEqual(positions(mag.board),[[49,29]]);
  assert.equal(V.color(68,69,mag),16759152);
  assert.equal(V.color(71,72,mag),16759152,'the cell spans 4 x 4 tiles at maximum zoom');
  assert.notEqual(V.color(72,72,mag),16759152);
  const lost=M.event({$:'Lost',id:0},mag).value;
  assert.deepEqual(move(lost,290,277).board,mag.board,'a canceled drag cannot paint again on hover');
  assert.deepEqual(press(mag,273,430).board,mag.board,'clicks below the clipped viewport are ignored');
  for(let level=3;level>=1;level--){
    mag=press(mag,minus,44);
    assert.equal(mag.zoom,level);
  }
  assert.equal(mag.zoom,1);
  assert.deepEqual(positions(mag.board),[[49,29]]);
  assert.equal(V.color(65,66,mag),16759152);
  assert.equal(key(mag,61).zoom,2);
  const playing=key(mag,32), increased=press(playing,plus,44);
  assert.equal(increased.running,true);
  assert.equal(increased.due,playing.due);

  let edge=G.empty(64,40);
  for(const y of [19,20,21])edge=G.paint(edge,63,y,true);
  edge=G.advance(edge);
  assert.deepEqual(positions(edge),[[62,20],[63,20]]);
  edge=G.resize(edge,96,56);
  assert.equal(G.get(edge,64,20),0);
  assert.equal(positions(G.advance(edge)).length,0,'enlarging does not revive clipped cells');

  let seed=6103;
  const next=()=>seed=(Math.imul(seed,1664525)+1013904223)>>>0;
  for(const [w,h] of [[64,40],[96,56],[128,72]]){
    let b=G.empty(w,h), reference=makeBoard(w,h);
    for(let i=0;i<800;i++){
      const x=(next()>>>8)%w,y=(next()>>>8)%h,on=Boolean(next()&64);
      b=G.paint(b,x,y,on);putCell(reference,x,y,on);
    }
    for(let i=0;i<5;i++){
      b=G.advance(b);reference=advance(Life,reference);
      assert.deepEqual(cells(b),Array.from({length:w*h},(_,k)=>getCell(reference,k%w,Math.floor(k/w))));
    }
  }
  console.log('PASS: native Bend board, keyboard, pointer, rendering, resizing, and browser-engine parity');
} finally {
  rmSync(dir,{recursive:true,force:true});
}
