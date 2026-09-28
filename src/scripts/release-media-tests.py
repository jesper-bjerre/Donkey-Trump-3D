import importlib.util
import json
from pathlib import Path
import tempfile
import unittest
from PIL import Image
spec=importlib.util.spec_from_file_location('media',Path(__file__).with_name('validate-release-media.py'))
media=importlib.util.module_from_spec(spec);spec.loader.exec_module(media)

class MediaTests(unittest.TestCase):
    def setUp(self):
        self.temp=tempfile.TemporaryDirectory();self.addCleanup(self.temp.cleanup);self.root=Path(self.temp.name)
        entries=[]
        for i in range(1,6):
            name=f'{i}.png';Image.new('RGB',(2868,1320),(i*30,0,0)).save(self.root/name)
            sha=media.digest(self.root/name)
            entries.append(dict(order=i,file=name,source=name,sha256=sha,sourceSHA256=sha,caption=f'Scene {i}',provenance='synthetic validator fixture'))
        Image.new('RGB',(1024,1024),(0,0,0)).save(self.root/'icon.png')
        self.data=dict(candidateId='fixture',configurationHash='fixture',language='en-US',screenshots=entries,icon=dict(file='icon.png',sha256=media.digest(self.root/'icon.png')))
        self.manifest=self.root/'manifest.json'
    def run_manifest(self):
        self.manifest.write_text(json.dumps(self.data));return media.validate(self.manifest)
    def test_complete_set(self):self.assertEqual(5,self.run_manifest())
    def test_alpha_and_small_phone_are_rejected(self):
        for mode,size in [('RGBA',(2868,1320)),('RGB',(2532,1170)),('RGB',(1320,2868))]:
            Image.new(mode,size).save(self.root/'1.png')
            with self.assertRaises(ValueError):self.run_manifest()
    def test_changed_bytes_order_missing_provenance_and_duplicates_fail(self):
        self.data['screenshots'][0]['sha256']='changed'
        with self.assertRaisesRegex(ValueError,'checksum'):self.run_manifest()
        self.data['screenshots'][0]['sha256']=self.data['screenshots'][0]['sourceSHA256']
        self.data['screenshots'][0]['order']=2
        with self.assertRaisesRegex(ValueError,'ordered'):self.run_manifest()
        self.data['screenshots'][0]['order']=1;self.data['screenshots'][0]['provenance']=''
        with self.assertRaisesRegex(ValueError,'provenance'):self.run_manifest()

if __name__=='__main__':unittest.main()
