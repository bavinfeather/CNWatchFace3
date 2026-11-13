// Production menu metadata and refresh control flow with mocked Garmin APIs.
const fs=require('node:fs'),path=require('node:path'),vm=require('node:vm'),assert=require('node:assert/strict');
const root=path.resolve(__dirname,'..');
const data=fs.readFileSync(path.join(root,'source/SolSettingsData.mc'),'utf8');
const menu=fs.readFileSync(path.join(root,'source/SolSettings.mc'),'utf8');
const keys=['Language','ShowSecondsActive','SolarDisplay','TemperatureUnit','Units','ProgressMetric','Field1','Field2','Field3','Field4'];
function method(text,name) {
 const start=text.indexOf('function '+name+'('),open=text.indexOf('{',start);let end=open+1,depth=1;
 while(depth){if(text[end]==='{')depth++;if(text[end]==='}')depth--;end++;}
 return text.slice(start,end).replace(/\.size\(\)/g,'.length').replace(/\.length\(\)/g,'.length')
  .replace(/([\w.\[\]]+)\.equals\(([^)]*)\)/g,'($1===$2)');
}
for(const amoled of [false,true]) for(const language of [0,1]) {
 const strings=new Proxy({},{get:(_,key)=>String(key)});let reads=[];
 const ctx=vm.createContext({String,Rez:{Strings:strings},WatchUi:{loadResource:id=>id},
  isAmoled:()=>amoled,language:()=>language,Application:{Properties:{getValue:key=>{reads.push(key);return 0;}}}});
 vm.runInContext('String.prototype.equals=function(v){return String(this)===v;};',ctx);
 for(const name of ['rows','choices','option','label']) vm.runInContext(method(data,name),ctx);
 ctx.SolSettingsData={choices:ctx.choices,option:ctx.option,label:ctx.label};
 const rows=ctx.rows(language);assert.deepEqual(Array.from(rows,r=>r[0]),keys);
 for(const key of ['Field1','Field2','Field3','Field4']) {
  const choices=ctx.choices(key,language);assert.equal(choices.length/2,56);
  for(let i=0;i<56;i++){assert.equal(choices[i*2],i);assert.equal(ctx.option(choices,i),'FieldOpt'+i);}
 }
 // Phone-only colors keep their full MIP/AMOLED palettes and saved values.
 assert.equal(ctx.choices('ArcColor',language).length/2,amoled?41:25);
 ctx.rows=rows;let changed=[];
 ctx.items=Array.from(rows,(_,i)=>({setSubLabel:value=>changed.push(i)}));
 ctx.isSection=()=>false;ctx.hiddenText=()=>'(Hidden)';
 vm.runInContext(method(menu,'refresh'),ctx);
 ctx.refresh(null);assert.equal(reads.length,10);assert.equal(changed.length,10);
 reads=[];changed=[];ctx.refresh('Field3');assert.deepEqual(reads,['Field3']);assert.deepEqual(changed,[8]);
 reads=[];changed=[];ctx.refresh('missing');assert.equal(reads.length,0);assert.equal(changed.length,0);
}
assert(!menu.includes('function onShow()'), 'returning from a submenu must not repeat the full refresh');
assert(menu.includes('menu.refresh(row[0])'));assert(menu.includes('menu.refresh(key)'));
const generator=fs.readFileSync(path.join(root,'tools/generate_resources.py'),'utf8');
assert(generator.includes('if key in watch_menu_keys:'));
console.log('PASS: 10 watch rows; 56 field choices; both languages and palettes; initial and targeted refresh; phone options preserved.');
