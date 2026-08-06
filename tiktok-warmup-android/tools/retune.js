// Current vs proposed matched-watch distribution, and the gate eligibility each gives.
let sp=null;
function gauss(){if(sp!==null){const s=sp;sp=null;return s;}let u,v,s;
 do{u=Math.random()*2-1;v=Math.random()*2-1;s=u*u+v*v;}while(s>=1||s===0);
 const m=Math.sqrt(-2*Math.log(s)/s);sp=v*m;return u*m;}
const ri=(a,b)=>a+Math.floor(Math.random()*(b-a+1));

const CUR={bounce:0.12,bMin:3000,bMax:6000,full:0.40,fMin:20000,fMax:50000,
           rew:0.45,rLo:1.5,rHi:1.3,mu:9.55,sg:0.42,min:5000,max:34000,decay:0.80};
const NEW={bounce:0.24,bMin:2200,bMax:4800,full:0.16,fMin:14000,fMax:30000,
           rew:0.22,rLo:1.3,rHi:0.5,mu:9.16,sg:0.40,min:3500,max:21000,decay:0.80};

function watch(C,pr){
  const d=1-(1-C.decay)*pr, r=Math.random();
  if(r<C.bounce) return ri(C.bMin,C.bMax);
  if(r<C.bounce+C.full){let b=ri(C.fMin,C.fMax);
    if(Math.random()<C.rew) b=Math.floor(b*(C.rLo+Math.random()*C.rHi));
    return Math.floor(b*d);}
  return Math.max(C.min,Math.min(C.max,Math.floor(Math.exp(C.mu+C.sg*gauss())*d)));
}

const gates=[4000,5000,8000,12000,15000];
function profile(C,name){
  const N=600000,hit={},arr=[];let sum=0,full=0;
  gates.forEach(g=>hit[g]=0);
  for(let i=0;i<N;i++){const w=watch(C,i/N);sum+=w;arr.push(w);
    if(w>=15000)full++;gates.forEach(g=>{if(w>=g)hit[g]++;});}
  arr.sort((a,b)=>a-b);
  console.log('\n'+name);
  console.log('  mean '+(sum/N/1000).toFixed(1)+'s   median '
    +(arr[N>>1]/1000).toFixed(1)+'s   p90 '+(arr[Math.floor(N*0.9)]/1000).toFixed(1)+'s');
  console.log('  watched >=15s: '+(full/N*100).toFixed(0)+'%');
  const e={};
  gates.forEach(g=>{e[g]=hit[g]/N;
    console.log('  gate '+(g/1000)+'s  elig '+e[g].toFixed(3)
      +'   max '+Math.floor(e[g]*100)+'/100');});
  return e;
}
profile(CUR,'CURRENT (too slow)');
const e=profile(NEW,'PROPOSED');

console.log('\nlevel 100 wants: 80 likes, 40 saves, 60 comments, 12 follows, 40 reposts');
const need={4000:60,5000:80,8000:20,12000:40,15000:40};
let ok=true;
for(const g of gates){
  const max=Math.floor(e[g]*100);
  const bad=need[g]>max;
  if(bad) ok=false;
  console.log('  '+(g/1000)+'s gate: need '+need[g]+', max '+max+(bad?'   GATE WOULD DROP':'   ok'));
}
console.log('\n'+(ok?'PASS':'note: some level-100 rates exceed their ceiling'));
