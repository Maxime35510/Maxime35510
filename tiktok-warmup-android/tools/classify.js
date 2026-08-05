// Mirror of ScreenState.classify(), old vs new, against the frames from the log.
const W = 1080, H = 2376;
const item = (o) => Object.assign(
  { cx: 0, cy: 0, w: 60, h: 60, desc: '', text: '', clickable: false, editable: false }, o);

// A normal FOR YOU frame: right-hand rail, top nav tabs, no text field.
const feed = [
  item({ cx: 0.30*W, cy: 0.07*H, text: 'following', clickable: true }),
  item({ cx: 0.50*W, cy: 0.07*H, text: 'for you',   clickable: true }),
  item({ cx: 0.92*W, cy: 0.33*H, desc: 'profile photo',    clickable: true }),
  item({ cx: 0.92*W, cy: 0.46*H, desc: 'like 12.3k',       clickable: true }),
  item({ cx: 0.92*W, cy: 0.57*H, desc: 'read or add comments 418 comments', clickable: true }),
  item({ cx: 0.92*W, cy: 0.68*H, desc: 'add to favorites', clickable: true }),
  item({ cx: 0.92*W, cy: 0.79*H, desc: 'share',            clickable: true }),
];

const commentSheet = [
  item({ cx: 0.50*W, cy: 0.35*H, text: '1 comment' }),
  item({ cx: 0.50*W, cy: 0.94*H, editable: true, text: '' }),
  item({ cx: 0.88*W, cy: 0.94*H, desc: 'post', clickable: true }),
];

const profile = [
  item({ cx: 0.30*W, cy: 0.30*H, text: 'followers' }),
  item({ cx: 0.50*W, cy: 0.30*H, text: 'following' }),
];

const search = [ item({ cx: 0.50*W, cy: 0.08*H, editable: true }) ];
const unknown = [ item({ cx: 0.50*W, cy: 0.50*H, text: 'loading' }) ];

const rail = (items) => items.filter(it =>
  it.clickable && it.cx >= 0.78*W && it.cy >= 0.12*H && it.cy <= 0.88*H && it.w <= 0.35*W);

// ---- OLD ----
function classifyOld(items) {
  if (items.some(it => it.editable && it.cy > 0.62*H)) return 'COMMENTS';
  if (items.some(it => ['comments','commentaires'].some(n =>
      it.text.includes(n) || it.desc.includes(n)))) return 'COMMENTS';
  if (items.some(it => it.editable && it.cy < 0.22*H)) return 'SEARCH';
  if (items.some(it => ['followers','following','abonnés'].some(n =>
      it.text.includes(n) || it.desc.includes(n)))) return 'PROFILE';
  if (rail(items).length >= 3) return 'FEED';
  return 'OTHER_TIKTOK';
}

// ---- NEW ----
const hasWord = (items, needles) => items.some(it =>
  needles.some(n => it.text === n || it.text.startsWith(n+' ') || it.text.endsWith(' '+n)));

function classifyNew(items, keyboardOpen) {
  const hasEditable  = items.some(it => it.editable);
  const editableLow  = items.some(it => it.editable && it.cy > 0.60*H);
  const editableHigh = items.some(it => it.editable && it.cy < 0.22*H);
  const hasRail = rail(items).length >= 3;

  if (hasRail && !hasEditable) return 'FEED';
  if (editableLow) return 'COMMENTS';
  if (editableHigh) return 'SEARCH';
  if (hasEditable && keyboardOpen) return 'COMMENTS';
  if (!hasRail && hasWord(items, ['followers','abonnés','seguidores'])) return 'PROFILE';
  return 'OTHER_TIKTOK';
}

const DISMISSABLE = new Set(['COMMENTS','PROFILE','SEARCH']);

const cases = [
  ['for-you feed',   feed,         'FEED'],
  ['comment sheet',  commentSheet, 'COMMENTS'],
  ['profile page',   profile,      'PROFILE'],
  ['search page',    search,       'SEARCH'],
  ['unknown screen', unknown,      'OTHER_TIKTOK'],
];

console.log('screen'.padEnd(16) + 'old'.padEnd(16) + 'new'.padEnd(16) + 'expected');
let pass = true, backOnFeed = false;
for (const [name, items, expected] of cases) {
  const o = classifyOld(items), n = classifyNew(items, false);
  if (n !== expected) pass = false;
  if (name === 'for-you feed' && DISMISSABLE.has(o)) backOnFeed = true;
  console.log(name.padEnd(16) + o.padEnd(16) + n.padEnd(16) + expected
      + (n === expected ? '' : '   <-- WRONG'));
}

console.log('\nold behaviour on the feed: ' + classifyOld(feed)
    + (backOnFeed ? '  -> presses BACK -> exits TikTok  (the reported bug)' : ''));
console.log('new behaviour on the feed: ' + classifyNew(feed, false)
    + '  -> swipes, never presses BACK');
console.log('\n' + (pass && !DISMISSABLE.has(classifyNew(feed, false))
    ? 'PASS - feed is classified correctly and BACK can no longer fire on it'
    : 'FAIL'));
