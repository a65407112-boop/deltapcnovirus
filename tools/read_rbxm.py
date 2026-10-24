import collections
import json
import struct
from pathlib import Path


def string(data, offset):
    size = struct.unpack_from('<I', data, offset)[0]
    return data[offset+4:offset+4+size].decode('utf-8', errors='replace'), offset+4+size


def ints(data, count, signed=False):
    values = [int.from_bytes(bytes(data[i+count*j] for j in range(4)), 'big') for i in range(count)]
    return [(x >> 1) ^ -(x & 1) for x in values] if signed else values


def floats(data, count):
    return [struct.unpack('<f', struct.pack('<I', (x >> 1) | ((x & 1) << 31)))[0] for x in ints(data, count)]


def refs(data, count):
    acc = 0
    result = []
    for value in ints(data, count, True):
        acc += value
        result.append(acc)
    return result


def read(path):
    data = Path(path).read_bytes()
    assert data[:8] == b'<roblox!'
    classes, nodes, types = {}, {}, {}
    pos = 32
    while pos + 16 <= len(data):
        tag, compressed, size, _ = struct.unpack_from('<4sIII', data, pos)
        chunk = data[pos+16:pos+16+(compressed or size)]
        pos += 16 + (compressed or size)
        assert not compressed, 'This snapshot reader expects uncompressed chunks'
        if tag == b'INST':
            cid = struct.unpack_from('<I', chunk)[0]
            name, at = string(chunk, 4)
            count = struct.unpack_from('<I', chunk, at+1)[0]
            ids = refs(chunk[at+5:], count)
            classes[cid] = (name, ids)
            for iid in ids:
                nodes[iid] = {'id': iid, 'class': name, 'parent': -1, 'props': {}}
        elif tag == b'PROP':
            cid = struct.unpack_from('<I', chunk)[0]
            name, at = string(chunk, 4)
            typ, raw = chunk[at], chunk[at+1:]
            classname, ids = classes[cid]
            count = len(ids)
            types[classname + '.' + name] = typ
            if typ == 1:
                values, cursor = [], 0
                for _ in ids:
                    value, cursor = string(raw, cursor)
                    values.append(value)
            elif typ == 2:
                values = [bool(x) for x in raw]
            elif typ == 3:
                values = ints(raw, count, True)
            elif typ == 4:
                values = floats(raw, count)
            elif typ in (6,7,12,13,24):
                components = {6:2,7:4,12:3,13:2,24:4}[typ]
                arrays = []
                for j in range(components):
                    part = raw[4*count*j:4*count*(j+1)]
                    arrays.append(ints(part,count,True) if (typ==6 and j==1) or (typ==7 and j>=2) else floats(part,count))
                values = [list(x) for x in zip(*arrays)]
                if typ == 7:
                    values = [[x[0],x[2],x[1],x[3]] for x in values]
            elif typ == 18:
                values = ints(raw,count)
            elif typ == 19:
                values = refs(raw,count)
            elif typ == 32:
                values, cursor = [], 0
                for _ in ids:
                    family,cursor = string(raw,cursor)
                    weight,style=struct.unpack_from('<HB',raw,cursor)
                    cache,cursor=string(raw,cursor+3)
                    values.append({'family':family,'weight':weight,'style':style,'cache':cache})
            else:
                continue
            assert len(values)==count,(classname,name,typ,len(values),count)
            for iid,value in zip(ids,values):
                nodes[iid]['props'][name] = value
        elif tag == b'PRNT':
            count=struct.unpack_from('<I',chunk,1)[0]
            children=refs(chunk[5:5+4*count],count)
            parents=refs(chunk[5+4*count:],count)
            for child,parent in zip(children,parents):
                nodes[child]['parent']=parent
        elif tag == b'END\x00':
            break
    return nodes,types


if __name__ == '__main__':
    nodes,types=read('upload/gethui_dump_20261023_204400(1).rbxm')
    Path('model.json').write_text(json.dumps({'nodes':list(nodes.values()),'types':types},ensure_ascii=False,indent=2))
    def fullpath(node):
        name=node['props'].get('Name',node['class'])
        return (fullpath(nodes[node['parent']])+'/' if node['parent']>=0 else '')+name
    rows=[]
    for node in sorted(nodes.values(),key=lambda n:n['id']):
        p=node['props']
        if node['class'] not in ('UICorner','UIPadding','UIAspectRatioConstraint','UIStroke','UIListLayout'):
            rows.append(f"{node['id']:3} {node['class']:16} {fullpath(node)} | "+json.dumps({k:v for k,v in p.items() if k in ('Text','Value','PlaceholderText','Source','Image','Position','Size','Visible')},ensure_ascii=False))
    Path('model-tree.txt').write_text('\n'.join(rows))
    print('Decoded',len(nodes),'instances. Top-level:',[(n['id'],n['class'],n['props'].get('Name')) for n in nodes.values() if n['parent'] in (-1,0)])
    print('\n'.join(rows[:40]))
    for n in nodes.values():
        if n['class']=='Script':print('SCRIPT SOURCE:',n['props'].get('Source'))
