#!/usr/bin/env python3
"""Validate native landscape iPhone media provenance and checksums, without editing images."""
import argparse
import hashlib
import json
from pathlib import Path
from PIL import Image

# Apple screenshot specifications, checked 2026-09-27; recheck actual Connect slots before upload.
SIZES = {(2868,1320),(2796,1290),(2736,1260)}


def digest(path): return hashlib.sha256(Path(path).read_bytes()).hexdigest()

def inspect(path, sizes):
    with Image.open(path) as image:
        image.load()
        if image.format not in ('PNG','JPEG') or image.size not in sizes:
            raise ValueError('Unsupported format or native dimensions')
        if 'A' in image.getbands() or 'transparency' in image.info:
            raise ValueError('Alpha channels/transparency are not accepted')
        if image.getexif().get(274,1) != 1: raise ValueError('Rotated metadata is not a landscape pixel export')
        return image.size


def validate(manifest_path):
    manifest_path = Path(manifest_path)
    base = manifest_path.parent
    data = json.loads(manifest_path.read_text())
    if not data.get('candidateId') or not data.get('configurationHash') or data.get('language') != 'en-US':
        raise ValueError('Candidate/configuration/language identity missing')
    entries = data['screenshots']
    if len(entries) != 5 or [e['order'] for e in entries] != [1,2,3,4,5]:
        raise ValueError('Exactly five ordered screenshots are required')
    outputs=[]
    for item in entries:
        source,output = base/item['source'],base/item['file']
        if not item.get('caption') or not item.get('provenance'): raise ValueError('Caption/provenance missing')
        if inspect(source,SIZES) != inspect(output,SIZES): raise ValueError('Source/output native dimensions differ')
        if digest(source) != item['sourceSHA256'] or digest(output) != item['sha256']: raise ValueError('Media checksum mismatch')
        outputs.append(item['sha256'])
    if len(set(outputs)) != 5: raise ValueError('Five distinct final scenes are required')
    icon=base/data['icon']['file'];inspect(icon,{(1024,1024)})
    if digest(icon)!=data['icon']['sha256']:raise ValueError('Icon checksum mismatch')
    return len(entries)

if __name__=='__main__':
    parser=argparse.ArgumentParser(description=__doc__);parser.add_argument('manifest');args=parser.parse_args()
    print(f'PASS: {validate(args.manifest)} ordered native images and icon; remote acceptance and visual/content review remain separate.')
