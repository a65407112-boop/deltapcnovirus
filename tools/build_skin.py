"""Generate the supplied GUI without redesigning its geometry or appearance."""
import importlib.util
import json
from pathlib import Path
import sys

ROOT=Path(__file__).resolve().parents[1]
decoder_path=Path(sys.argv[2]) if len(sys.argv)>2 else ROOT/'tools/read_rbxm.py'
spec=importlib.util.spec_from_file_location('reader',decoder_path)
reader=importlib.util.module_from_spec(spec);spec.loader.exec_module(reader)
nodes,types=reader.read(sys.argv[1])
# Compress extreme captured ZIndex values without losing a single ordering relation.
layers={v:i for i,v in enumerate(sorted({n['props']['ZIndex'] for n in nodes.values() if 'ZIndex' in n['props']}))}

SKIP=set('AttributesSerialize Capabilities DefinesCapabilities Tags SerializedOverrides Source AutoLocalize RootLocalizationTable LocalizationMatchIdentifier LocalizationMatchedSourceText OpenTypeFeatures Draggable Selected Sink HoverHapticEffect PressHapticEffect IconTint BorderOffset BorderStrokePosition StrokeSizingMode'.split())
SKIP.update('SelectionBehaviorDown SelectionBehaviorLeft SelectionBehaviorRight SelectionBehaviorUp SelectionGroup NextSelectionDown NextSelectionLeft NextSelectionRight NextSelectionUp SelectionImageObject SelectionOrder'.split())
ENUM={'AutomaticCanvasSize':'AutomaticSize','HorizontalScrollBarInset':'ScrollBarInset','VerticalScrollBarInset':'ScrollBarInset',
      'VerticalScrollBarPosition':'VerticalScrollBarPosition','Style':'ButtonStyle','ApplyStrokeMode':'ApplyStrokeMode',
      'HorizontalFlex':'UIFlexAlignment','VerticalFlex':'UIFlexAlignment','ResampleMode':'ResamplerMode'}

def quote(s):
    return json.dumps(s,ensure_ascii=False).replace('\\u0000','\\000')
def number(n):
    return str(int(n)) if int(n)==n else format(n,'.8g')
def val(kind,name,v):
    typ=types[kind+'.'+name]
    if typ==1:
        if name=='Image' and v.startswith('rbxasset://') and not v.startswith('rbxasset://textures/'):
            return 'asset('+quote(v)+')'
        return quote(v)
    if typ==2:return str(v).lower()
    if typ in (3,4):return number(v)
    if typ==6:return 'UDim.new('+','.join(map(number,v))+')'
    if typ==7:return 'UDim2.new('+','.join(map(number,v))+')'
    if typ==12:return 'Color3.new('+','.join(map(number,v))+')'
    if typ==13:return 'Vector2.new('+','.join(map(number,v))+')'
    if typ==24:return 'Rect.new('+','.join(map(number,v))+')'
    if typ==18:
        category=ENUM.get(name,name)
        if name=='Style' and kind=='Frame':return None
        return 'E('+quote(category)+','+str(v)+')'
    if typ==32:
        family=v['family']
        family=quote(family) if family.startswith('rbxasset://fonts/') else 'asset('+quote(family)+')'
        return 'Font.new('+family+',E("FontWeight",'+str(v['weight'])+'),E("FontStyle",'+str(v['style'])+'))'
    return None

lines=['-- Generated from the supplied gethui snapshot. No exported scripts are executed.',
'return function(asset)',
'local nodes, failures = {}, {}',
'local enums = {}',
'local function E(category, value)',
'    if not enums[category] then',
'        enums[category] = {}',
'        for _, item in ipairs(Enum[category]:GetEnumItems()) do enums[category][item.Value] = item end',
'    end',
'    return assert(enums[category][value], "Unknown enum " .. category .. ":" .. value)',
'end',
'local function put(id, kind, parent, properties)',
'    local object = Instance.new(kind)',
'    nodes[id] = object',
'    for property, value in pairs(properties) do',
'        local ok, reason = pcall(function() object[property] = value end)',
'        if not ok then table.insert(failures, kind .. "." .. property .. ": " .. tostring(reason)) end',
'    end',
'    if parent >= 0 then object.Parent = nodes[parent] end',
'end']
for n in sorted(nodes.values(),key=lambda n:n['id']):
    if n['class']=='Script':continue
    props=[]
    for k,v in sorted(n['props'].items()):
        if k in SKIP or k.endswith('Radius') or k=='Style':continue
        if k=='Name' and ('�' in v or any(ord(x)<32 for x in v)):
            v='Captured'+str(n['id'])
        if k=='ZIndex':v=layers[v]
        if k=='Text' and n['id']==514:v=''
        value=val(n['class'],k,v)
        if value is not None:props.append(k+'='+value)
    if n['class']=='UICorner':
        v=n['props'].get('TopLeftRadius',[0,8]);props.append('CornerRadius=UDim.new('+','.join(map(number,v))+')')
    lines.append('put('+str(n['id'])+','+quote(n['class'])+','+str(n['parent'])+',{'+','.join(props)+'})')
lines += ['return nodes, failures','end','']
(ROOT/'src/skin.lua').write_text('\n'.join(lines))
assets={}
for n in nodes.values():
    uri=n['props'].get('Image','')
    if uri.startswith('rbxasset://') and not uri.startswith('rbxasset://textures/'):
        assets.setdefault(uri.rsplit('/',1)[-1],[]).append(n['id'])
(ROOT/'docs/asset-map.json').write_text(json.dumps(assets,indent=2)+'\n')
print('Generated',len(nodes)-1,'objects;',len(assets),'original texture names mapped.')
