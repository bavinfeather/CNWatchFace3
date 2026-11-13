// Execute the production drawing block; verify capacity maps to arc length.
const fs=require('node:fs'),path=require('node:path'),vm=require('node:vm'),assert=require('node:assert/strict');
const text=fs.readFileSync(path.join(__dirname,'../source/SolView.mc'),'utf8');
const block=text.slice(text.indexOf('        var n=progress==null?'),text.indexOf('        drawProgressValue(dc,now);'));
const trackMethod=text.slice(text.indexOf('    function mipProgressTrackColor()'),text.indexOf('    function progressIcon()')).replace(/\.size\(\)/g,'.length');
for(const width of [240,260,280,416]) for(const amoled of [false,true]) {
 for(const value of [null,-1,0,1,19,20,21,40,50,60,80,99,100,101]) {
  const arcs=[];let pen=0,color=null;const ctx=vm.createContext({progress:value,width,colors:{ArcColor:0xFF5500,Background:0xAA5555},
   Graphics:{COLOR_TRANSPARENT:-1,ARC_CLOCKWISE:0},isAmoled:()=>amoled,
   p:v=>Math.trunc(v*width/280),dc:{setColor(c){color=c;},setPenWidth(v){pen=v;},drawArc:(...a)=>{a.pen=pen;a.color=color;arcs.push(a);}}});
  vm.runInContext('Number.prototype.toNumber=function(){return Math.trunc(this);};'+trackMethod+block.replace('dc has :setAntiAlias','"setAntiAlias" in dc'),ctx);
  if(amoled) {
   assert.equal(arcs.length,5);
   arcs.forEach((a,i)=>assert.deepEqual(a.slice(4),[128-i*16,116-i*16]));
  } else {
   const thickness=Math.trunc(4*width/280),filled=Math.max(0,Math.min(100,value??0));
   assert.equal(arcs.length,5+Math.ceil(filled/20));
   const expectedRadius=Math.trunc(132*width/280)+Math.trunc(Math.trunc(3*width/280)/2)-Math.trunc((thickness-1)/2);
   arcs.slice(0,5).forEach((a,i)=>{assert.deepEqual(a.slice(4),[128-i*16,116-i*16]);assert.equal(a[2],expectedRadius);assert.equal(a.pen,thickness);assert.notEqual(a.color,0xFF5500);});
   arcs.splice(0,5);
   let sweep=0;
   for(const a of arcs) {
    sweep+=a[4]-a[5];
    assert.equal(a[2],expectedRadius);assert.equal(a.pen,thickness);assert.equal(a.color,0xFF5500);assert(a[4]>a[5]);
   }
   assert(Math.abs(sweep-filled*.6)<1e-8);
  }
 }
}
// Every RGB222 background/progress pair gets a track distinct from both.
const palette=[];
for(const r of [0,85,170,255]) for(const g of [0,85,170,255]) for(const b of [0,85,170,255]) palette.push((r<<16)|(g<<8)|b);
const colorCtx=vm.createContext({colors:{}});
vm.runInContext(trackMethod,colorCtx);
for(const bg of palette) for(const fg of palette) {
 colorCtx.colors={Background:bg,ArcColor:fg};
 const track=colorCtx.mipProgressTrackColor();
 assert.notEqual(track,bg);assert.notEqual(track,fg);
}
assert(!block.includes('setAntiAlias'), 'MIP antialias dithering must not leave a noisy edge');
console.log('PASS: MIP arc length proportional at 0/1/19/20/21/40/50/60/80/99/100%; null/range bounds; shared outer circle; AMOLED unchanged.');
