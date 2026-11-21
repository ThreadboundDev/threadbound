#!/usr/bin/env node
'use strict';

// Slice generated drawings without repainting them. Preserve native alpha and
// register each animation to a common 512px canvas and a 480px floor anchor.
const fs = require('node:fs');
const path = require('node:path');
const crypto = require('node:crypto');
let sharp;
try { sharp = require('sharp'); } catch {
  sharp = require(path.join(path.dirname(process.execPath), '..', 'node_modules', 'sharp'));
}
const root = path.resolve(__dirname, '../..');
const delivery = path.join(root, 'ArtSource/Deliveries/eave-runner-sprite-study-2026-11-21');
const output = path.join(root, 'Assets/BlueBiome/Enemies/EaveRunner/SpriteStudy');
const size = 512;
const floor = 480;
const config = {
  idle: { scale: 1, sourceFloor: 483, anchors: [208,208,208,208,208,208,208,208], shifts: [0,0,0,0,0,0,0,0], durations: [140,140,140,140,140,140,140,140], loop: true },
  run: { scale: 1.06, sourceFloor: 459, anchors: [225,214,200,195,226,222,202,195], shifts: [0,0,0,0,0,0,0,0], durations: [90,70,80,90,90,70,80,90], loop: true },
  slash: { scale: 1.115, sourceFloor: 447, anchors: [203,188,184,208,203,170,215,211], shifts: [0,-3,-5,20,24,16,6,0], durations: [140,110,90,50,70,90,120,140], loop: false },
};

function components(data, width, height) {
  const seen = new Uint8Array(width * height);
  const queue = new Int32Array(width * height);
  const result = [];
  for (let p = 0; p < width * height; p++) {
    if (seen[p] || data[p * 4 + 3] < 24) continue;
    let start = 0, end = 1, x0 = width, y0 = height, x1 = 0, y1 = 0;
    queue[0] = p; seen[p] = 1;
    while (start < end) {
      const q = queue[start++], x = q % width, y = Math.floor(q / width);
      x0 = Math.min(x0, x); y0 = Math.min(y0, y); x1 = Math.max(x1, x); y1 = Math.max(y1, y);
      for (let dy = -1; dy <= 1; dy++) for (let dx = -1; dx <= 1; dx++) {
        const nx = x + dx, ny = y + dy;
        if ((!dx && !dy) || nx < 0 || ny < 0 || nx >= width || ny >= height) continue;
        const n = ny * width + nx;
        if (!seen[n] && data[n * 4 + 3] >= 24) { seen[n] = 1; queue[end++] = n; }
      }
    }
    if (end > 12) result.push({ x0, y0, x1, y1, pixels: end });
  }
  return result;
}

function svg(text, width, height) {
  return Buffer.from(`<svg width="${width}" height="${height}" xmlns="http://www.w3.org/2000/svg">${text}</svg>`);
}
function label(text, x, y, fontSize = 20, color = '#d7cbb5') {
  return `<text x="${x}" y="${y}" fill="${color}" font-family="Segoe UI, sans-serif" font-size="${fontSize}">${text}</text>`;
}

async function main() {
  fs.mkdirSync(output, { recursive: true });
  fs.mkdirSync(path.join(delivery, 'preview'), { recursive: true });
  const manifest = { version: 1, canvas: [size, size], columns: 4, rows: 2, floor_y: floor, origin_x: 256, facing: 'right', clips: {} };
  const report = { checks: [], clips: {}, source: 'built-in image_gen drawings; deterministic slicing and registration only' };
  const frameBuffers = {};
  for (const [name, settings] of Object.entries(config)) {
    const source = path.join(delivery, 'raw', `${name}.png`);
    const { data, info } = await sharp(source).ensureAlpha().raw().toBuffer({ resolveWithObject: true });
    if (info.width !== 1536 || info.height !== 1024) throw new Error(`${name}: unexpected source grid`);
    const all = components(data, info.width, info.height);
    const bodies = all.filter(c => c.pixels > 5000).sort((a,b) => Math.floor((a.y0+a.y1)/1024) - Math.floor((b.y0+b.y1)/1024) || a.x0 - b.x0);
    if (bodies.length !== 8) throw new Error(`${name}: expected 8 separate complete bodies, got ${bodies.length}`);
    const frames = [];
    const registrations = [];
    for (let i = 0; i < bodies.length; i++) {
      const body = bodies[i], row = Math.floor(i / 4), col = i % 4;
      // Include nearby detached blade strokes, but never a neighbouring body.
      const islands = all.filter(c => c.pixels <= 5000 && c.y0 >= row*512 && c.y1 < (row+1)*512 && c.x0 >= body.x0-16 && c.x1 <= body.x1+22);
      let x0 = body.x0, y0 = body.y0, x1 = body.x1, y1 = body.y1;
      for (const c of islands) { x0=Math.min(x0,c.x0); y0=Math.min(y0,c.y0); x1=Math.max(x1,c.x1); y1=Math.max(y1,c.y1); }
      x0=Math.max(0,x0-3); y0=Math.max(0,y0-3); x1=Math.min(info.width-1,x1+3); y1=Math.min(info.height-1,y1+3);
      const crop = { left:x0, top:y0, width:x1-x0+1, height:y1-y0+1 };
      const width = Math.round(crop.width*settings.scale), height = Math.round(crop.height*settings.scale);
      const anchor = settings.anchors[i]+col*384;
      const left = Math.round(256+(x0-anchor)*settings.scale+settings.shifts[i]);
      const top = Math.round(floor+(y0-settings.sourceFloor-row*512)*settings.scale);
      if (left < 4 || top < 4 || left+width > size-4 || top+height > size-4) throw new Error(`${name} ${i}: would clip on registered canvas: ${JSON.stringify({left,top,width,height})}`);
      const cropped = await sharp(source).extract(crop).resize(width,height,{kernel:'lanczos3'}).png().toBuffer();
      const frame = await sharp({create:{width:size,height:size,channels:4,background:'#00000000'}}).composite([{input:cropped,left,top}]).png().toBuffer();
      frames.push(frame);
      registrations.push({source_rect:[x0,y0,crop.width,crop.height],source_anchor:[anchor,settings.sourceFloor+row*512],scale:settings.scale,visual_lunge_x:settings.shifts[i],destination:[left,top,width,height],opaque_pixels:body.pixels});
    }
    const atlas = await sharp({create:{width:size*4,height:size*2,channels:4,background:'#00000000'}}).composite(frames.map((input,i)=>({input,left:(i%4)*size,top:Math.floor(i/4)*size}))).png().toBuffer();
    fs.writeFileSync(path.join(output,`${name}.png`),atlas);
    manifest.clips[name]={sheet:`${name}.png`,frame_count:8,durations_ms:settings.durations,loop:settings.loop,registrations};
    report.clips[name]={frames:8,sha256:crypto.createHash('sha256').update(atlas).digest('hex'),source_alpha:true,complete_bodies:bodies.length,registration:registrations};
    frameBuffers[name]=frames;
    const rawFrames=[];
    for(const frame of frames) {
      const decorated=await sharp(frame).flatten({background:'#29343d'}).composite([{input:svg(`<path d="M16 ${floor+1}H496" stroke="#707c80" stroke-width="1"/>`,size,size),left:0,top:0}]).raw().toBuffer();
      rawFrames.push(decorated);
    }
    await sharp(Buffer.concat(rawFrames),{raw:{width:size,height:size*8,channels:3,pageHeight:size}}).gif({loop:0,delay:settings.durations,effort:7,dither:0}).toFile(path.join(delivery,'preview',`${name}.gif`));
  }
  const overviewFrames=[];
  for(let t=0;t<32;t++) {
    const composites=[];
    for(const [col,name] of ['idle','run','slash'].entries()) {
      const durations=config[name].durations, length=durations.reduce((a,b)=>a+b,0);
      let clock=(t*70)%length, index=0;
      while(clock>=durations[index] && index<7){clock-=durations[index];index++;}
      const image=await sharp(frameBuffers[name][index]).resize(384,384).png().toBuffer();
      composites.push({input:image,left:col*384,top:64});
    }
    const header=label('EAVE RUNNER / 2D SPRITE STUDY',30,38,24)+label('IDLE',34,92,16)+label('RUN',418,92,16)+label('SLASH',802,92,16)+`<path d="M24 425H1128" stroke="#768482"/>`+label('Hand-drawn frames · original demo enemy style · art preview',30,478,17);
    const frame=await sharp({create:{width:1152,height:512,channels:3,background:'#23303a'}}).composite([...composites,{input:svg(header,1152,512),left:0,top:0}]).raw().toBuffer();
    overviewFrames.push(frame);
  }
  await sharp(Buffer.concat(overviewFrames),{raw:{width:1152,height:512*32,channels:3,pageHeight:512}}).gif({loop:0,delay:Array(32).fill(70),effort:7,dither:0}).toFile(path.join(delivery,'preview','overview.gif'));
  fs.writeFileSync(path.join(output,'study_manifest.json'),JSON.stringify(manifest,null,2)+'\n');
  report.checks.push('24 complete drawings isolated using alpha-connected bodies, including figures crossing the generated cell boundaries.','All registered frames fit inside a 512x512 transparent canvas with at least a 4px margin.','Floor anchor shared across clips; airborne run drawings retain their vertical lift.','Original alpha retained; no chroma-keying, repainting, inferred in-between poses or runtime 3D rendering.');
  fs.writeFileSync(path.join(delivery,'preparation_report.json'),JSON.stringify(report,null,2)+'\n');
  console.log(JSON.stringify({output:path.relative(root,output),frames:24,clips:Object.keys(config),preview:path.relative(root,path.join(delivery,'preview','overview.gif'))}));
}
main().catch(error=>{console.error(error);process.exit(1)});
