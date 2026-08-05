const SKIP_BASE=0.35,SKIP_GROWTH=0.15,LONG_SHARE=0.10,SKIP_MIN=1200,SKIP_MAX=3200;
const LN_MU=9.05,LN_SIGMA=0.5,NORMAL_MIN=3000,NORMAL_MAX=25000;
const LONG_MIN=18000,LONG_MAX=45000,REWATCH_CHANCE=0.30,DECAY_AT_END=0.65;
let sp=null;
function gauss(){if(sp!==null){const s=sp;sp=null;return s;}let u,v,s;
 do{u=Math.random()*2-1;v=Math.random()*2-1;s=u*u+v*v;}while(s>=1||s===0);
 const m=Math.sqrt(-2*Math.log(s)/s);sp=v*m;return u*m;}
const ri=(a,b)=>a+Math.floor(Math.random()*(b-a+1));
function watch(pr){const d=1-(1-DECAY_AT_END)*pr,sk=SKIP_BASE+SKIP_GROWTH*pr,r=Math.random();
 if(r<sk)return ri(SKIP_MIN,SKIP_MAX);
 if(r<sk+LONG_SHARE){let b=ri(LONG_MIN,LONG_MAX);
  if(Math.random()<REWATCH_CHANCE)b=Math.floor(b*(1.5+Math.random()));return Math.floor(b*d);}
 return Math.max(NORMAL_MIN,Math.min(NORMAL_MAX,Math.floor(Math.exp(LN_MU+LN_SIGMA*gauss())*d)));}
const gates=[4000,5000,8000,12000,15000];
const N=1000000,hit={};gates.forEach(g=>hit[g]=0);
for(let i=0;i<N;i++){const w=watch(i/N);gates.forEach(g=>{if(w>=g)hit[g]++;});}
console.log('dwell gate   share of videos watched at least that long');
gates.forEach(g=>console.log('  '+(g/1000+'s').padEnd(11)+(hit[g]/N*100).toFixed(1)+'%'));
console.log('\nmax achievable per 100 videos while keeping the dwell gate:');
gates.forEach(g=>console.log('  '+(g/1000+'s').padEnd(11)+Math.floor(hit[g]/N*100)+' per 100'));
