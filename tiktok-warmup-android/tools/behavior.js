// Mirror of Behavior.java. Checks the emitted rates against published human benchmarks.
const SKIP_BASE=0.35, SKIP_GROWTH=0.15, LONG_SHARE=0.10;
const SKIP_MIN=1200, SKIP_MAX=3200;
const LN_MU=9.05, LN_SIGMA=0.5, NORMAL_MIN=3000, NORMAL_MAX=25000;
const LONG_MIN=18000, LONG_MAX=45000, REWATCH_CHANCE=0.30;
const DECAY_AT_END=0.65;

const LIKE_MIN=5000,  LIKE_P=0.082;
const SAVE_MIN=12000, SAVE_P=0.030;
const COMM_MIN=4000,  COMM_P=0.123;
const PROF_MIN=8000,  PROF_P=0.043;
const REPOST_MIN=15000, REPOST_P=0.013;
const BACK_P=0.030;

let g_spare=null;
function gauss(){ if(g_spare!==null){const s=g_spare;g_spare=null;return s;}
  let u,v,s; do{u=Math.random()*2-1;v=Math.random()*2-1;s=u*u+v*v;}while(s>=1||s===0);
  const m=Math.sqrt(-2*Math.log(s)/s); g_spare=v*m; return u*m; }
const ri=(a,b)=>a+Math.floor(Math.random()*(b-a+1));

function watchTime(progress){
  const decay=1.0-(1.0-DECAY_AT_END)*progress;
  const skipP=SKIP_BASE+SKIP_GROWTH*progress;
  const r=Math.random();
  if(r<skipP) return ri(SKIP_MIN,SKIP_MAX);
  if(r<skipP+LONG_SHARE){
    let base=ri(LONG_MIN,LONG_MAX);
    if(Math.random()<REWATCH_CHANCE) base=Math.floor(base*(1.5+Math.random()));
    return Math.floor(base*decay);
  }
  let ms=Math.floor(Math.exp(LN_MU+LN_SIGMA*gauss())*decay);
  return Math.max(NORMAL_MIN,Math.min(NORMAL_MAX,ms));
}

function run(preset){
  const scale = preset==='light'?0.55 : preset==='heavy'?1.80 : 1.0;
  const roll=(p)=>Math.random()<Math.min(1,p*scale);
  const N=400000;
  let watched=[], like=0,save=0,comm=0,prof=0,rep=0,back=0, full=0;
  for(let i=0;i<N;i++){
    const progress=i/N;
    const w=watchTime(progress);
    watched.push(w);
    if(w>=20000) full++;
    if(w>=LIKE_MIN   && roll(LIKE_P))   like++;
    if(w>=SAVE_MIN   && roll(SAVE_P))   save++;
    if(w>=COMM_MIN   && roll(COMM_P))   comm++;
    if(w>=PROF_MIN   && roll(PROF_P))   prof++;
    if(w>=REPOST_MIN && roll(REPOST_P)) rep++;
    if(roll(BACK_P)) back++;
  }
  watched.sort((a,b)=>a-b);
  return {
    median: watched[Math.floor(N/2)]/1000,
    mean: (watched.reduce((a,b)=>a+b,0)/N/1000),
    p10: watched[Math.floor(N*0.10)]/1000,
    p90: watched[Math.floor(N*0.90)]/1000,
    sub3: watched.filter(x=>x<3000).length/N*100,
    full: full/N*100,
    like: like/N*100, save: save/N*100, comm: comm/N*100,
    prof: prof/N*100, rep: rep/N*100, back: back/N*100,
  };
}

const target = {
  median:'~8.4s', full:'~10%', like:'3.4-4%', save:'<1%',
  comm:'~5-8%', prof:'~1-2%', back:'~3%',
};

console.log('watch-time distribution (normal preset)');
const n = run('normal');
console.log('  mean        ' + n.mean.toFixed(1) + 's   target ~8.4s (benchmark is a mean)');
console.log('  median      ' + n.median.toFixed(1) + 's   (low by design: 38% are instant skips)');
console.log('  p10 / p90   ' + n.p10.toFixed(1) + 's / ' + n.p90.toFixed(1) + 's');
console.log('  sub-3s      ' + n.sub3.toFixed(1) + '%');
console.log('  >=20s       ' + n.full.toFixed(1) + '%   target ' + target.full);

console.log('\nengagement rate per video viewed');
console.log('           light    normal     heavy    human benchmark');
const l = run('light'), h = run('heavy');
const row=(k,name,t)=>console.log('  '+name.padEnd(9)
  +(l[k].toFixed(2)+'%').padStart(7)+(n[k].toFixed(2)+'%').padStart(10)
  +(h[k].toFixed(2)+'%').padStart(10)+'    '+t);
row('like','like',target.like);
row('save','save',target.save);
row('comm','comments',target.comm);
row('prof','profile',target.prof);
row('back','rewatch',target.back);
row('rep','repost','rare');

const ok = n.like>=3.4&&n.like<=4.2 && n.save<1.0 && n.comm>=5&&n.comm<=8.5
        && n.mean>=7.5&&n.mean<=9.5 && n.full>=8&&n.full<=13;
console.log('\n' + (ok ? 'PASS - normal preset lands inside human benchmarks'
                       : 'FAIL - retune constants'));

console.log('\nfor comparison, current shipped build:');
console.log('  like 17.4%   save 16.6%   comments 15.6%   watch time flat 6-9s');
