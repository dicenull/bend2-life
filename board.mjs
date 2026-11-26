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
  const edge=(i,left,right)=>((left?a[i-1]>>>31:0)|((right?a[i+1]&1:0)<<1));
  for(let y=0;y<b.height;y++)for(let w=0;w<s;w++){
    const i=y*s+w, above=i-s, below=i+s, left=w>0,right=w+1<s;
    out.words[i]=Life.next_word(
      y>0?a[above]:0,a[i],y+1<b.height?a[below]:0,
      y>0?edge(above,left,right):0,edge(i,left,right),y+1<b.height?edge(below,left,right):0
    );
  }
  return out;
}
