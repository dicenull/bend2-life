// Flat row-major bitboard. Widths are multiples of 32; one U32 per word.
export function makeBoard(width,height){
  if(!Number.isSafeInteger(width)||width<32||width%32!==0||!Number.isSafeInteger(height)||height<1)throw RangeError('Invalid board dimensions');
  return {width,height,stride:width/32,words:new Uint32Array(width/32*height)};
}
export function getCell(b,x,y){
  if(x<0||x>=b.width||y<0||y>=b.height)return 0;
  return (b.words[y*b.stride+(x>>>5)]>>>(x&31))&1;
}
export function putCell(b,x,y,on){
  if(x<0||x>=b.width||y<0||y>=b.height)return;
  const i=y*b.stride+(x>>>5), mask=1<<(x&31);
  b.words[i]=on?b.words[i]|mask:b.words[i]&~mask;
}
export function resizeBoard(b,width,height){
  const out=makeBoard(width,height), stride=Math.min(b.stride,out.stride);
  for(let y=0;y<Math.min(height,b.height);y++){
    const start=y*b.stride;
    out.words.set(b.words.subarray(start,start+stride),y*out.stride);
  }
  return out;
}
export function advance(Life,b){
  const out=makeBoard(b.width,b.height), a=b.words, s=b.stride;
  for(let y=0;y<b.height;y++)for(let w=0;w<s;w++){
    const i=y*s+w, above=i-s, below=i+s;
    // These are flat-array candidates, not necessarily geometric neighbors.
    // Bend masks out any slot that lies beyond one of the four board edges.
    out.words[i]=Life.next_bounded(
      w,s-1-w,y,b.height-1-y,
      a[above-1]??0,a[above]??0,a[above+1]??0,
      a[i-1]??0,a[i],a[i+1]??0,
      a[below-1]??0,a[below]??0,a[below+1]??0
    );
  }
  return out;
}
