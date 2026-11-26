import assert from 'node:assert/strict';
import Life from './life.mjs';
const next=(a)=>Uint32Array.from(a,(m,y)=>Life.next_row(a[y-1]??0,m,a[y+1]??0));
function plain(a){
  const out=new Uint32Array(32);
  for(let y=0;y<32;y++)for(let x=0;x<32;x++){
    let count=0;
    for(let j=-1;j<=1;j++)for(let i=-1;i<=1;i++){
      if((i||j)&&x+i>=0&&x+i<32)count+=((a[y+j]??0)>>>(x+i))&1;
    }
    if(count===3||(count===2&&((a[y]>>>x)&1)))out[y]|=1<<x;
  }
  return out;
}
function board(cells){const a=new Uint32Array(32);for(const[x,y]of cells)a[y]|=1<<x;return a;}
function gridAt(x,y){return [[x+1,y],[x+2,y+1],[x,y+2],[x+1,y+2],[x+2,y+2]];}
for(let p=0;p<512;p++){
  const a=board(Array.from({length:9},(_,i)=>[14+i%3,14+Math.floor(i/3)]).filter((_,i)=>p&(1<<i)));
  assert.deepEqual(next(a),plain(a),`neighborhood ${p}`);
}
const block=board([[30,30],[31,30],[30,31],[31,31]]);
assert.deepEqual(next(block),block);
const blinker=board([[0,1],[1,1],[2,1]]);
assert.deepEqual(next(blinker),board([[1,0],[1,1],[1,2]]));
assert.deepEqual(next(next(blinker)),blinker);
let glider=board(gridAt(12,13));
for(let i=0;i<4;i++)glider=next(glider);
assert.deepEqual(glider,board(gridAt(13,14)));
assert.deepEqual(next(board([[31,0],[0,0],[1,0]])),board([]),'no horizontal wrap');
assert.deepEqual(next(board([[2,31],[2,0],[2,1]])),board([]),'no vertical wrap');
let state=59613;
const rand=()=>((state=(Math.imul(state,1664525)+1013904223)>>>0)>>>16)/65536;
for(let k=0;k<100;k++){
  let a=new Uint32Array(32); const p=(k%10+1)/12;
  for(let y=0;y<32;y++)for(let x=0;x<32;x++)if(rand()<p)a[y]|=1<<x;
  for(let t=0;t<5;t++){const b=next(a);assert.deepEqual(b,plain(a),`board ${k} / generation ${t}`);a=b;}
}
console.log('PASS: 512 local neighborhoods, 500 random-board generations, and glider/blinker/block/edge tests');
