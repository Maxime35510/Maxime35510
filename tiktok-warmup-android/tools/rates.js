// Does a requested "per 100 videos" target actually come out at that rate?
const ELIG={like:0.455,save:0.172,comm:0.510,prof:0.291,repost:0.131};
const GATE={like:5000,save:12000,comm:4000,prof:8000,repost:15000};
const SKIP_BASE=0.35,SKIP_GROWTH=0.15,LONG_SHARE=0.10,SKIP_MIN=1200,SKIP_MAX=3200;
const LN_MU=9.05,LN_SIGMA=0.5,NORMAL_MIN=3000,NORMAL_MAX=25000;
const LONG_MIN=18000,LONG_MAX=45000,REWATCH=0.30,DECAY=0.65;
let sp=null;
function gauss(){if(sp!==null){const s=sp;sp=null;return s;}let u,v,s;
 do{u=Math.random()*2-1;v=Math.random()*2-1;s=u*u+v*v;}while(s>=1||s===0);
 const m=Math.sqrt(-2*Math.log(s)/s);sp=v*m;return u*m;}
const ri=(a,b)=>a+Math.floor(Math.random()*(b-a+1));
function watch(pr){const d=1-(1-DECAY)*pr,sk=SKIP_BASE+SKIP_GROWTH*pr,r=Math.random();
 if(r<sk)return ri(SKIP_MIN,SKIP_MAX);
 if(r<sk+LONG_SHARE){let b=ri(LONG_MIN,LONG_MAX);
  if(Math.random()<REWATCH)b=Math.floor(b*(1.5+Math.random()));return Math.floor(b*d);}
 return Math.max(NORMAL_MIN,Math.min(NORMAL_MAX,Math.floor(Math.exp(LN_MU+LN_SIGMA*gauss())*d)));}

// mirrors Behavior.resolve()
function resolve(per100,elig,gate){const t=per100/100;if(t<=0)return[0,gate];
 const p=t/elig;return p>1?[Math.min(1,t),0]:[p,gate];}

function measure(kind,per100){
 const [p,gate]=resolve(per100,ELIG[kind],GATE[kind]);
 const N=500000;let hit=0,onSkipped=0;
 for(let i=0;i<N;i++){const w=watch(i/N);
  if(w>=gate&&Math.random()<p){hit++;if(w<4000)onSkipped++;}}
 return {got:hit/N*100,gate,skipShare:hit?onSkipped/hit*100:0};
}

console.log('requested vs produced, per 100 videos\n');
console.log('action    asked   produced   gate    on <4s videos');
for(const [kind,vals] of Object.entries({
    like:[2,4,15,40,60], save:[1,3,10,25], comm:[3,6,12,30], repost:[0,1,5]})){
  for(const v of vals){
    const m=measure(kind,v);
    console.log('  '+kind.padEnd(8)+String(v).padStart(4)
      +m.got.toFixed(1).padStart(10)
      +((m.gate/1000)+'s').padStart(8)
      +(m.skipShare.toFixed(0)+'%').padStart(10)
      +(m.gate===0?'   <-- gate dropped to hit the target':''));
  }
}
