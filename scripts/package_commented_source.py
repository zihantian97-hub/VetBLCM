"""Build a source/example archive; excludes generated analysis output."""
from pathlib import Path
import hashlib, json, zipfile

root = Path(__file__).resolve().parents[1]
version = next(line.split(':', 1)[1].strip() for line in (root/'DESCRIPTION').read_text().splitlines() if line.startswith('Version:'))
output = root.parent / f'VetBLCM-{version}-source.zip'
def include(path):
    rel = path.relative_to(root)
    return (path.is_file() and not any(p in {'.git','.vetblcm','__pycache__','reports','.Rproj.user','renv'} for p in rel.parts)
            and path.suffix.lower() not in {'.rds','.log','.zip','.diff'} and path.name != 'release_manifest.json')
files = [{'path':f.relative_to(root).as_posix(),'bytes':f.stat().st_size,'sha256':hashlib.sha256(f.read_bytes()).hexdigest()}
         for f in sorted(root.rglob('*')) if include(f)]
manifest = {'application':'VetBLCM','version':version,'kind':'source and simulated examples',
            'contains_empirical_study_data':False,'files':files}
(root/'release_manifest.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
with zipfile.ZipFile(output,'w',zipfile.ZIP_DEFLATED,compresslevel=6) as z:
    for item in files:
        z.write(root/item['path'],f'VetBLCM-{version}/'+item['path'])
    z.write(root/'release_manifest.json',f'VetBLCM-{version}/release_manifest.json')
with zipfile.ZipFile(output) as z:
    assert z.testzip() is None
    for item in files:
        assert hashlib.sha256(z.read(f'VetBLCM-{version}/'+item['path'])).hexdigest()==item['sha256']
sha=hashlib.sha256(output.read_bytes()).hexdigest()
output.with_suffix('.zip.sha256').write_text(f'{sha}  {output.name}\n',encoding='ascii')
print(json.dumps({'zip':str(output),'bytes':output.stat().st_size,'sha256':sha,'files':len(files)+1}))
