// Production font-selection control flow with mocked metrics, not native-font visual proof.
const fs=require('node:fs'),path=require('node:path'),vm=require('node:vm'),assert=require('node:assert/strict');
const source=fs.readFileSync(path.join(__dirname,'../source/SolView.mc'),'utf8');
const method=source.slice(source.indexOf('function fittedDateFont('),source.indexOf('function dateLine('))
    .replace(/Graphics has :getVectorFont/g,'"getVectorFont" in Graphics')
    .replace(/:(face|size)=>/g,'$1:').replace(/\.size\(\)/g,'.length');
let cases=0;
for(const width of [240,260,280,360,390,416,454,466]) {
    for(const chinese of [false,true]) {
        const scale=width/280;
        const normal={size:24*scale},small={size:14*scale},tiny={size:9*scale};
        let loads=0;
        const ctx=vm.createContext({dateFitText:null,dateFitFont:null,dateFitWidth:-1,Math,
            cn:()=>chinese,isAmoled:()=>true,isInstinct3:false,p:n=>Math.trunc(n*scale),
            dataCjkFont:normal,dataLatinFont:normal,fonts:[normal,normal,small,small,normal,small,small],
            Graphics:{FONT_SYSTEM_XTINY:tiny,FONT_XTINY:tiny,
                getVectorFont:o=>{loads++;return {size:o.size};}}});
        vm.runInContext('Number.prototype.toNumber=function(){return Math.trunc(this);};String.prototype.equals=function(v){return String(this)===v;};',ctx);
        vm.runInContext(method,ctx);
        const dc={getFontHeight:f=>f.size*1.2,
            getTextWidthInPixels:(text,f)=>[...text].reduce((n,c)=>n+(c.charCodeAt(0)>127?1:.55)*f.size,0)};
        const short=chinese?'周日 10月11日':'SUN. 11.10';
        const long=chinese?'周日 12月31日 闰十一月廿九 冬至15日':'WED. 31.12 R11/29 WinterSol15D';
        const max=ctx.p(200);
        assert.equal(ctx.fittedDateFont(dc,short,max),normal);
        const chosen=ctx.fittedDateFont(dc,long,max);
        assert(dc.getTextWidthInPixels(long,chosen)<=max);assert(chosen.size<normal.size);
        const priorLoads=loads;assert.equal(ctx.fittedDateFont(dc,long,max),chosen);assert.equal(loads,priorLoads);
        assert.equal(ctx.fittedDateFont(dc,short,max),normal);
        // Native API absence/null/exception all fall back without crashing.
        for(const failure of ['absent','null','throw']) {
            ctx.dateFitText=null;
            if(failure==='absent') delete ctx.Graphics.getVectorFont;
            else ctx.Graphics.getVectorFont=()=>{if(failure==='throw')throw Error('unavailable');return null;};
            const fallback=ctx.fittedDateFont(dc,long,max);
            assert(dc.getTextWidthInPixels(long,fallback)<=max);cases++;
        }
    }
}
assert(source.includes('dateText=fitTag(dc,dateText,dateFont,p(200));'));
assert(source.slice(source.indexOf('function loadSettings()'),source.indexOf('function palette()')).includes('dateFitText=null;'));
assert(source.slice(source.indexOf('function onLayout(dc)'),source.indexOf('function onEnterSleep()')).includes('dateFitText=null;'));
console.log(`PASS: ${cases} language/resolution/fallback cases; full text fits, font cache reused, short text restores size, settings/layout invalidate cache.`);
