#!/usr/bin/env python3
"""Place authentic iPhone captures in the bundled editorial layouts.

Requires Python 3, Inkscape and ImageMagick (magick or convert + identify).
The script performs no image generation and never fills missing captures.
"""
from pathlib import Path
import argparse, base64, json, shutil, subprocess, tempfile, os
import xml.etree.ElementTree as ET

def main():
 parser=argparse.ArgumentParser(description=__doc__)
 parser.add_argument('--captures',required=True,type=Path)
 parser.add_argument('--locale',choices=['en','da'],default='en')
 parser.add_argument('--device',choices=['6.9','6.5'],default='6.9')
 parser.add_argument('--output',required=True,type=Path)
 args=parser.parse_args()
 here=Path(__file__).resolve().parent
 root=here.parent
 ink=shutil.which('inkscape')
 magick=shutil.which('magick')
 converter=[magick] if magick else [shutil.which('convert') or '']
 identifier=[magick,'identify'] if magick else [shutil.which('identify') or '']
 if not ink or not converter[0] or not identifier[0]:
  parser.error('Install Inkscape and ImageMagick and make their commands available on PATH.')
 if not args.captures.is_dir(): parser.error('The captures folder does not exist.')
 if args.captures.resolve()==args.output.resolve(): parser.error('Use a separate output folder.')
 templates=json.loads((here/'template_map.json').read_text(encoding='utf-8'))
 templates=[t for t in templates if t['locale']==args.locale and t['device_group']==args.device]
 args.output.mkdir(parents=True,exist_ok=True)
 available=[]
 # Validate all present inputs before writing outputs.
 for t in templates:
  source=args.captures/t['capture_filename']
  if not source.is_file():
   print('Skipped missing capture:',source.name)
   continue
  raw=subprocess.check_output(identifier+['-format','%w %h',str(source)],text=True)
  dims=[int(v) for v in raw.split()]
  if dims!=t['canvas']:
   parser.error(f'{source.name}: expected authentic {t["canvas"][0]}x{t["canvas"][1]} capture, got {dims}. Capture at the required size; do not stretch gameplay.')
  target=args.output/(source.stem+'-'+args.locale+'.png')
  if target.exists(): parser.error(f'Output already exists: {target}. Choose an empty output folder.')
  available.append((t,source,target))
 if not available: parser.error('No matching captures found. See CAPTURE_GUIDE.md for required filenames.')
 for t,source,target in available:
  svg=(root/t['svg']).read_text(encoding='utf-8')
  x,y,w,h=t['capture_rect']
  uri='data:image/png;base64,'+base64.b64encode(source.read_bytes()).decode('ascii')
  replacement=f'<image x="{x}" y="{y}" width="{w}" height="{h}" preserveAspectRatio="xMidYMid meet" xlink:href="{uri}"/>'
  start='<!-- CAPTURE_START -->'; end='<!-- CAPTURE_END -->'
  svg=svg.split(start)[0]+replacement+svg.split(end)[1]
  ET.fromstring(svg)
  with tempfile.TemporaryDirectory(prefix='donkey-trump-') as temp:
   stage=Path(temp)/'layout.svg';stage.write_text(svg,encoding='utf-8')
   raster=Path(temp)/'render.png'
   subprocess.run([ink,str(stage),'--export-type=png','--export-filename='+str(raster)],check=True,stdout=subprocess.PIPE,stderr=subprocess.PIPE)
   result=subprocess.run(converter+[str(raster),'-background','#06162C','-alpha','remove','-alpha','off','-colorspace','sRGB','-depth','8','-define','png:color-type=2','png:-'],check=True,stdout=subprocess.PIPE)
   staged=target.with_suffix('.png.tmp')
   with open(staged,'wb') as f:
    f.write(result.stdout);f.flush();os.fsync(f.fileno())
   os.replace(staged,target)
  print('Created:',target)
 print('Done. Inspect the exported screenshots before uploading to App Store Connect.')

if __name__=='__main__': main()
