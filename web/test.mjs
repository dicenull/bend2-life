import assert from 'node:assert/strict';
import Life from './life.mjs';
import {advance,getCell,putCell,makeBoard,resizeBoard} from './board.mjs';
const next=(b)=>advance(Life,b);
function plain(b){
  const a=Array.from({length:b.height},(_,y)=>Array.from({length:b.width},(_,x)=>
    (b.words[y*(b.width/32)+Math.floor(x/32)]>>> (x%32))&1));
  const out=new Uint32Array(b.width/32*b.height);
  for(let y=0;y<b.height;y++)for(let x=0;x<b.width;x++){
    let count=0;
    for(let j=-1;j<=1;j++)for(let i=-1;i<=1;i++){
      if(i||j)count+=a[y+j]?.[x+i]??0;
    }
    if(count===3||(count===2&&a[y][x]))out[y*(b.width/32)+Math.floor(x/32)]|=1<<(x%32);
  }
  return out;
}
function board(cells,w=96,h=56){const b=makeBoard(w,h);for(const[x,y] of cells)putCell(b,x,y,1);return b;}
function gridAt(x,y){return [[x+1,y],[x+2,y+1],[x,y+2],[x+1,y+2],[x+2,y+2]];}
const windows=[30,31,62,63,94,95]; // center a window on both sides of each internal boundary
for(const left of windows)for(let p=0;p<512;p++){
  const b=board(Array.from({length:9},(_,i)=>[left+i%3,14+Math.floor(i/3)]).filter((_,i)=>p&(1<<i)),128,20);
  assert.deepEqual(next(b).words,plain(b),`neighborhood at x ${left+1}, pattern ${p}`);
}
const block=board([[126,70],[127,70],[126,71],[127,71]],128,72);
assert.deepEqual(next(block),block);
const seamBlock=board([[31,2],[32,2],[31,3],[32,3]],64,5);
assert.deepEqual(next(seamBlock),seamBlock,'block across an internal seam');
for(const x of [31,63,95]){
  const b=board([[x-1,1],[x,1],[x+1,1]],128,72);
  assert.deepEqual(next(b),board([[x,0],[x,1],[x,2]],128,72));
  assert.deepEqual(next(next(b)),b);
}
let glider=board(gridAt(30,13));
for(let i=0;i<4;i++)glider=next(glider);
assert.deepEqual(glider,board(gridAt(31,14)));
assert.deepEqual(next(board([[127,0],[0,0],[1,0]],128,72)),board([],128,72),'no horizontal wrap');
assert.deepEqual(next(board([[2,71],[2,0],[2,1]],128,72)),board([],128,72),'no vertical wrap');
assert.deepEqual(next(board([[127,3],[127,4],[0,5]],128,72)),board([],128,72),'no wrap between row storage');
const original=board([[31,39],[32,0],[63,0],[95,55]]);
const small=resizeBoard(original,64,40), big=resizeBoard(small,128,72);
assert.equal(getCell(big,31,39),1);assert.equal(getCell(big,32,0),1);assert.equal(getCell(big,63,0),1);
assert.equal(getCell(big,95,55),0);assert.equal(getCell(big,128,0),0);
const samples=[4294967295, 3, 1, 2147483648, 2147483649, 3, 1073741824, 1, 7];
for(let mask=0;mask<16;mask++){
  const [l,r,u,d]=[1,2,4,8].map((bit)=>mask&bit?3:0);
  const inside=[u&&l,u,u&&r,l,true,r,d&&l,d,d&&r];
  const clipped=samples.map((word,i)=>inside[i]?word:0);
  const fixture=makeBoard(96,3);fixture.words.set(clipped);
  assert.equal(Life.next_bounded(l,r,u,d,...samples),plain(fixture)[4],`dead exterior mask ${mask}`);
}
const widths=[[32,1],[64,1],[32,2],[32,32],[64,40],[96,56],[128,72]];
let state=59613;
const rand=()=>((state=(Math.imul(state,1664525)+1013904223)>>>0)>>>16)/65536;
for(let k=0;k<100;k++){
  const [w,h]=widths[k%widths.length];let a=makeBoard(w,h);const p=(k%10+1)/12;
  for(let y=0;y<h;y++)for(let x=0;x<w;x++)if(rand()<p)putCell(a,x,y,1);
  for(let t=0;t<5;t++){const b=next(a);assert.deepEqual(b.words,plain(a),`board ${k} / generation ${t}`);a=b;}
}
console.log('PASS: 3072 seam neighborhoods, 500 random-board generations, patterns, resize, and non-wrapping edges');
