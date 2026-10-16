import fs from 'node:fs';
import path from 'node:path';
import {execFileSync} from 'node:child_process';
const root=process.cwd();
const kit=path.join(root,'docs/design/app-store/Donkey_Trump_iOS_Release_Artwork');
const release=path.join(root,'docs/releases/app-store/1.0-2');
const all=JSON.parse(fs.readFileSync(path.join(kit,'04_AppStore_Screenshots/template_map.json'),'utf8'));
const templates=all.filter(x=>x.locale==='en'&&x.device_group==='6.9');
const captures=[['01-overview.png','JUMP INTO THE CHAOS','A satirical 3D arcade adventure.'],['02-barrels.png','DODGE THE BARRELS','Keep moving. Keep jumping.'],['03-controls.png','PLAY YOUR WAY','Touch controls, keyboards and game controllers.'],['04-title.png','CLIMB. DODGE. RESCUE.','An original satirical parody.'],['05-highscores.png','CHASE YOUR BEST','Climb the global highscore list.']];
for(const d of ['screenshots-en','screenshot-layouts'])fs.mkdirSync(path.join(release,d),{recursive:true});
for(let i=0;i<captures.length;i++){
 const [file,title,subtitle]=captures[i];const bytes=fs.readFileSync(path.join(release,'raw-captures',file));
 if(bytes.readUInt32BE(16)!==2868||bytes.readUInt32BE(20)!==1320)throw Error('Native capture size mismatch');
 const t=templates[i];let svg=fs.readFileSync(path.join(kit,t.svg),'utf8');
 const texts=[...svg.matchAll(/<text[^>]*>([^<]*)<\/text>/g)].map(x=>x[1]);
 svg=svg.replace(texts[0],title).replace(texts[1],subtitle).replace(texts[2],`${String(i+1).padStart(2,'0')} / ${String(captures.length).padStart(2,'0')}`);
 const [x,y,w,h]=t.capture_rect;
 svg=svg.split('<!-- CAPTURE_START -->')[0]+`<image x="${x}" y="${y}" width="${w}" height="${h}" preserveAspectRatio="xMidYMid meet" xlink:href="data:image/png;base64,${bytes.toString('base64')}"/>`+svg.split('<!-- CAPTURE_END -->')[1];
 svg=svg.replace(/<text\b[^>]*>TEMPLATE — NOT FOR UPLOAD<\/text>/g,'');
 svg=svg.replaceAll('DejaVu Sans','Arial');
 const layout=path.join(release,'screenshot-layouts',file.replace('.png','.svg'));fs.writeFileSync(layout,svg);
 const png=path.join('/tmp/dt3d-release-20260929',file);
 execFileSync('/opt/homebrew/bin/rsvg-convert',['--output',png,layout]);
 execFileSync('/usr/bin/sips',['-s','format','jpeg','-s','formatOptions','95',png,'--out',path.join(release,'screenshots-en',file.replace('.png','.jpg'))],{stdio:'pipe'});
 console.log(file+' composed from authentic capture');
}
