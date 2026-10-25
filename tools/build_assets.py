"""Build integrity metadata for the unmodified files from Assets.zip."""
from pathlib import Path
import hashlib, json, zlib
ROOT=Path(__file__).resolve().parents[1]
names=sorted(set(json.loads((ROOT/'docs/asset-map.json').read_text())) | {'f1','logo.png'})
records=[]
for name in names:
    data=(ROOT/'assets'/name).read_bytes()
    digest=hashlib.sha256(data).hexdigest()
    ext='.json' if name=='f1' else '.png'
    records.append(dict(name=name, path='DeltaPC/assets/'+digest[:12]+'-'+name+(ext if not name.endswith(ext) else ''), size=len(data), checksum=zlib.adler32(data)))
version=hashlib.sha256(json.dumps(records).encode()).hexdigest()[:16]
lines=['-- Generated from the original Assets.zip. Do not hand-edit the manifest.', 'local version='+json.dumps(version),'local records={']
for r in records:
    lines.append('    {name='+json.dumps(r['name'])+',path='+json.dumps(r['path'])+',size='+str(r['size'])+',checksum='+str(r['checksum'])+'},')
lines+=['}',(ROOT/'src/asset_loader.lua').read_text()]
(ROOT/'src/assets.lua').write_text('\n'.join(lines))
(ROOT/'docs/asset-manifest.json').write_text(json.dumps({'version':version,'files':records},indent=2)+'\n')
print('Generated original asset manifest:',len(records),'files')
