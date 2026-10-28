'use strict';
const $ = id => document.getElementById(id);
const key = 'threadbound-nox-audition-review-v1';
const pageSize = 25;
let items = [], filtered = [], selected = null, page = 0, reviews = {}, storageWorks = true;
try { reviews = JSON.parse(localStorage.getItem(key) || '{}'); } catch (_) { reviews = {}; storageWorks = false; }
const categoryOrder = ['Footsteps', 'Landings', 'Water splashes', 'Doors & objects', 'Cloth & handling', 'Water ambience', 'Cave ambience', 'Hearth & fire', 'Weather & wind', 'Village & nature'];
const surfaceOrder = ['Wood', 'Rock', 'Water', 'Grass', 'Gravel', 'Mud', 'Leaves', 'Metal'];
const natural = (a, b) => String(a).localeCompare(String(b), undefined, {numeric:true, sensitivity:'base'});
const duration = n => n == null ? '—' : n >= 60 ? `${Math.floor(Math.round(n)/60)}:${String(Math.round(n)%60).padStart(2,'0')}` : `${n < 10 ? n.toFixed(2) : n.toFixed(1)}s`;
const rank = (list, x) => list.includes(x) ? list.indexOf(x) : 99;
const player = $('player');
player.volume = .45;

function label(item) {
  if (item.source === 'NOX CC0' && item.surface && ['Footsteps','Landings','Jump takeoffs','Water splashes'].includes(item.category)) {
    const variant = item.filename.match(/_(\d+)\.wav$/i)?.[1] || '';
    const waterSize = item.category === 'Water splashes' ? (/Big/.test(item.filename) ? ' · big' : /Light/.test(item.filename) ? ' · light' : '') : '';
    return `${item.surface} · ${item.action}${waterSize}${variant ? ' · '+variant : ''}`;
  }
  return item.title.replace(/^Ambiance /, '').replace(/ Loop (Stereo|Mono)/, '').replace(/ (Stereo|Mono)$/, '');
}
function error(message) { $('error').hidden = !message; $('error').textContent = message; }
function save() {
  try { localStorage.setItem(key, JSON.stringify(reviews)); }
  catch (_) { storageWorks = false; }
  $('saved').textContent = storageWorks ? 'Saved in this browser. Export my picks to share or back them up.' : 'Browser storage is unavailable. Export my picks before leaving this page.';
}
function record() {
  if (!selected) return;
  const decision = $('decision').value, notes = $('notes').value;
  if (decision || notes.trim()) reviews[selected.id] = {decision, notes, updated:new Date().toISOString()};
  else delete reviews[selected.id];
  save();
  if (['favorites','reviewed'].includes($('collection').value)) applyFilters(false,true);
  else renderRows();
}
function stop() {
  player.pause();
  if (Number.isFinite(player.duration)) player.currentTime = 0;
  $('playing').textContent = 'Stopped.';
}
async function play(item, prefix) {
  error(''); player.pause();
  player.src = `/audio/${item.id}`;
  player.loop = $('loop').checked;
  player.volume = Number($('volume').value)/100;
  player.dataset.label = `${prefix}: ${item.filename}`;
  $('playing').textContent = player.dataset.label;
  try { await player.play(); }
  catch (e) { if (e.name !== 'AbortError') error('Preview did not start. Press Play again, or check that the local sound library is available.'); }
}
function select(item, autoplay=false) {
  selected = item; stop();
  player.src = `/audio/${item.id}`;
  player.dataset.label = `${item.source==='Current game'?'Current source':'Candidate'}: ${item.filename}`;
  $('title').textContent = label(item);
  $('purpose').textContent = item.purpose;
  $('source').textContent = `${item.source} · ${item.category}${item.surface ? ' · '+item.surface : ''}`;
  $('caution').textContent = item.caution;
  $('filename').textContent = item.filename;
  $('path').textContent = item.member;
  $('metadata').textContent = `${duration(item.duration)}${item.sample_rate ? ' · '+(item.sample_rate/1000)+' kHz' : ''}${item.channels ? ' · '+(item.channels===1?'mono':item.channels+' channels') : ''}${item.peak_db!=null ? ' · source peak '+item.peak_db+' dBFS' : ''}`;
  $('decision').disabled = $('notes').disabled = $('play-candidate').disabled = $('stop').disabled = false;
  $('play-candidate').textContent = item.source === 'Current game' ? 'Play source' : 'Play candidate';
  $('decision').value = reviews[item.id]?.decision || '';
  $('notes').value = reviews[item.id]?.notes || '';
  const baselines = items.filter(x => x.source==='Current game' && x.events?.some(event => item.compare_events.includes(event)));
  $('baseline').replaceChildren();
  if (!baselines.length) $('baseline').add(new Option('No direct current comparison listed', ''));
  baselines.forEach(x => $('baseline').add(new Option(`${x.filename} · ${x.events.join(', ')}`, x.id)));
  $('play-baseline').disabled = !baselines.length;
  $('baseline-note').textContent = baselines.length ? 'Compare the source character and texture; the game mixes and varies these clips during play.' : 'An addition candidate or a use with no directly matched source in this list.';
  const idx = filtered.findIndex(x => x.id === item.id);
  $('next-clip').disabled = idx >= filtered.length-1;
  renderRows();
  if (autoplay) play(item, item.source==='Current game' ? 'Current source' : 'Candidate');
}
function renderRows() {
  const body = $('sounds'); body.replaceChildren();
  for (const item of filtered.slice(page*pageSize,(page+1)*pageSize)) {
    const row = document.createElement('tr'); row.classList.toggle('selected', selected?.id===item.id);
    const playCell = document.createElement('td'), playButton = document.createElement('button');
    playButton.className='play'; playButton.textContent='▶'; playButton.setAttribute('aria-label',`Play ${label(item)} (${item.filename})`);
    playButton.onclick = () => select(item,true); playCell.append(playButton);
    const main = document.createElement('td');
    for (const [cls,text] of [['sound-name',label(item)],['sound-use',item.purpose],['sound-file',item.filename]]) {
      const node=document.createElement('div'); node.className=cls; node.textContent=text; main.append(node);
    }
    const cat = document.createElement('td'); cat.className='category'; cat.textContent=item.category;
    const length = document.createElement('td'); length.className='duration'; length.textContent=duration(item.duration);
    const pick = document.createElement('td'), button = document.createElement('button'); button.className='pick';
    const favorite=reviews[item.id]?.decision==='favorite'; button.textContent=favorite?'★':'☆';
    button.setAttribute('aria-label',`${favorite?'Unfavorite':'Favorite'} ${item.filename}`); button.setAttribute('aria-pressed',String(favorite));
    button.onclick=()=>{
      const previous=reviews[item.id]||{};
      reviews[item.id]={...previous,decision:favorite?'':'favorite',updated:new Date().toISOString()};
      if(!reviews[item.id].decision&&!reviews[item.id].notes)delete reviews[item.id];
      if(selected?.id===item.id)$('decision').value=favorite?'':'favorite'; save();
      if(['favorites','reviewed'].includes($('collection').value)) applyFilters(false); else renderRows();
    };
    pick.append(button); row.append(playCell,main,cat,length,pick); body.append(row);
  }
  $('empty').hidden=!!filtered.length;
  $('count').textContent=`${filtered.length.toLocaleString()} sounds${$('collection').value==='shortlist'?' in the starter shortlist':''}`;
  const total=Math.max(1,Math.ceil(filtered.length/pageSize));
  $('page').textContent=`Page ${page+1} of ${total}`;
  $('previous-page').disabled=page===0; $('next-page').disabled=page+1>=total;
}
function applyFilters(resetSelection=true,keepPage=false) {
  const query=$('search').value.trim().toLowerCase().split(/\s+/).filter(Boolean);
  const collection=$('collection').value, category=$('category').value, surface=$('surface').value;
  filtered=items.filter(x=>{
    const inCollection=collection==='shortlist'?x.shortlist:collection==='nox'?x.source==='NOX CC0':collection==='game'?x.source==='Current game':collection==='favorites'?reviews[x.id]?.decision==='favorite':!!reviews[x.id];
    const text=[label(x),x.filename,x.member,x.purpose,x.category,x.surface,x.action,reviews[x.id]?.notes||''].join(' ').toLowerCase();
    return inCollection&&(!category||category===x.category)&&(!surface||surface===x.surface)&&query.every(q=>text.includes(q));
  });
  const sort=$('sort').value;
  filtered.sort((a,b)=>{
    if(sort==='duration')return (a.duration??Infinity)-(b.duration??Infinity)||natural(a.filename,b.filename);
    if(sort==='longest')return (b.duration??-Infinity)-(a.duration??-Infinity)||natural(a.filename,b.filename);
    if(sort==='name')return natural(label(a),label(b));
    if(sort==='filename')return natural(a.filename,b.filename);
    if(sort==='category')return natural(a.category,b.category)||natural(label(a),label(b));
    return a.priority-b.priority||rank(categoryOrder,a.category)-rank(categoryOrder,b.category)||rank(surfaceOrder,a.surface)-rank(surfaceOrder,b.surface)||rank(['Walk','Run','Landing','Splash','Takeoff'],a.action)-rank(['Walk','Run','Landing','Splash','Takeoff'],b.action)||natural(a.filename,b.filename);
  });
  page=keepPage?Math.min(page,Math.max(0,Math.ceil(filtered.length/pageSize)-1)):0;
  if(resetSelection&&filtered.length)select(filtered[0]);
  else renderRows();
}
$('search').oninput=()=>applyFilters();
for(const id of ['collection','category','surface','sort'])$(id).onchange=()=>applyFilters();
$('clear').onclick=()=>{ $('search').value=''; $('category').value=$('surface').value=''; $('sort').value='recommended'; $('collection').value='shortlist'; applyFilters(); };
$('previous-page').onclick=()=>{page--;renderRows();}; $('next-page').onclick=()=>{page++;renderRows();};
$('play-candidate').onclick=()=>selected&&play(selected,selected.source==='Current game'?'Current source':'Candidate');
$('play-baseline').onclick=()=>{const item=items.find(x=>x.id===$('baseline').value);if(item)play(item,'Current source');};
$('next-clip').onclick=()=>{const idx=filtered.findIndex(x=>x.id===selected?.id);const next=filtered[idx+1];if(next){page=Math.floor((idx+1)/pageSize);select(next,true);}};
$('stop').onclick=stop; $('loop').onchange=()=>{player.loop=$('loop').checked;};
$('volume').oninput=()=>{player.volume=Number($('volume').value)/100;$('volume-label').textContent=`${$('volume').value}%`;};
$('decision').onchange=record; $('notes').oninput=record;
player.onended=()=>{$('playing').textContent='Finished. Replay, compare, or try the next sound.';};
player.onplay=()=>{$('playing').textContent=player.dataset.label||'Playing.';};
player.onerror=()=>error('This preview could not load. Check that the audition server and original local archive are available.');
$('export').onclick=()=>{
  const picks=items.filter(x=>reviews[x.id]).map(x=>({id:x.id,source:x.source,filename:x.filename,member:x.member,sha256:x.sha256,proposed_use:x.purpose,...reviews[x.id]}));
  const content={project:'Threadbound',exported:new Date().toISOString(),purpose:'Audition decisions only; no game replacements',picks};
  const url=URL.createObjectURL(new Blob([JSON.stringify(content,null,2)],{type:'application/json'}));
  const a=document.createElement('a');a.href=url;a.download='threadbound-sound-picks.json';a.hidden=true;document.body.append(a);a.click();a.remove();setTimeout(()=>URL.revokeObjectURL(url),30000);
};
async function init(){
  try{
    const response=await fetch('/api/catalog');if(!response.ok)throw new Error('Catalog unavailable');
    const data=await response.json();items=data.items;
    const nox=items.filter(x=>x.source==='NOX CC0').length,current=items.length-nox,short=items.filter(x=>x.shortlist).length;
    $('summary').textContent=`${short} starter candidates · ${nox.toLocaleString()} NOX sounds · ${current} current game sources`;
    for(const id of ['category','surface']){
      const values=[...new Set(items.map(x=>x[id]).filter(Boolean))].sort(natural);
      values.forEach(x=>$(id).add(new Option(x,x)));
    }
    applyFilters();
    if(!storageWorks)$('saved').textContent='Browser storage is unavailable. Export my picks before leaving.';
  }catch(e){error('The local catalog is unavailable. Start tools/audio/start_nox_audition.ps1, then reload this page.');}
}
init();
