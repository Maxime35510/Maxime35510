let sp=null;
function gauss(){if(sp!==null){const s=sp;sp=null;return s;}let u,v,s;
 do{u=Math.random()*2-1;v=Math.random()*2-1;s=u*u+v*v;}while(s>=1||s===0);
 const m=Math.sqrt(-2*Math.log(s)/s);sp=v*m;return u*m;}
const ri=(a,b)=>a+Math.floor(Math.random()*(b-a+1));
const C={bounce:0.24,bMin:2200,bMax:4800,full:0.16,fMin:14000,fMax:30000,
         rew:0.22,rLo:1.3,rHi:0.5,mu:9.16,sg:0.40,min:3500,max:21000,decay:0.80};
function watch(pr){const d=1-(1-C.decay)*pr,r=Math.random();
  if(r<C.bounce)return ri(C.bMin,C.bMax);
  if(r<C.bounce+C.full){let b=ri(C.fMin,C.fMax);
    if(Math.random()<C.rew)b=Math.floor(b*(C.rLo+Math.random()*C.rHi));return Math.floor(b*d);}
  return Math.max(C.min,Math.min(C.max,Math.floor(Math.exp(C.mu+C.sg*gauss())*d)));}

// gates halved to track the halved watch times
const G={like:3000,comment:2200,profile:5000,save:7000,repost:9000};
const NEED={like:80,comment:60,profile:20,save:40,repost:40};
const N=600000, hit={};
for(const k in G) hit[k]=0;
for(let i=0;i<N;i++){const w=watch(i/N);for(const k in G) if(w>=G[k]) hit[k]++;}

console.log('gate      seconds   eligible   max/100   level-100 needs');
let ok=true;
for(const k of ['comment','like','profile','save','repost']){
  const e=hit[k]/N, max=Math.floor(e*100), bad=NEED[k]>max;
  if(bad) ok=false;
  console.log('  '+k.padEnd(9)+(G[k]/1000+'s').padStart(6)
    +e.toFixed(3).padStart(11)+String(max).padStart(10)
    +String(NEED[k]).padStart(16)+(bad?'   DROPS':'   ok'));
}
console.log('\n'+(ok?'PASS - every level stays inside its dwell gate'
                   :'FAIL - some rates still exceed'));
console.log('\nELIG constants for Behavior.java:');
for(const k of ['like','save','comment','profile','repost'])
  console.log('  '+k+' gate '+G[k]+'  elig '+(hit[k]/N).toFixed(3));
