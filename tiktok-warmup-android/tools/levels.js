// Mirrors Behavior.ratesForLevel(). What each slider position actually means.
const curve=(t,lo,hi,e)=>Math.round(lo+(hi-lo)*Math.pow(t,e));
function rates(level){const t=level<=0?0:(level>=100?1:level/100);
 return {like:curve(t,1,80,1.55),save:curve(t,0,40,1.85),comment:curve(t,1,60,1.50),
   clike:curve(t,0,25,1.70),profile:curve(t,0,20,1.75),repost:curve(t,0,40,2.40),
   rewatch:curve(t,1,25,1.40),follow:curve(t,0,12,2.10)};}
// ceilings measured against the matched-video distribution
const CEIL={like:92,save:66,comment:96,profile:81,repost:56,follow:56};
console.log('level  likes saves comm profile follow repost rewatch   note');
for(const l of [1,5,12,25,35,50,65,75,85,100]){
  const r=rates(l);
  const over=Object.keys(CEIL).filter(k=>r[k]>CEIL[k]);
  console.log(String(l).padStart(4)
    +String(r.like).padStart(7)+String(r.save).padStart(6)
    +String(r.comment).padStart(5)+String(r.profile).padStart(8)
    +String(r.follow).padStart(7)+String(r.repost).padStart(7)
    +String(r.rewatch).padStart(8)
    +'   '+(over.length?'GATE DROPPED: '+over.join(','):'all within dwell gates'));
}
