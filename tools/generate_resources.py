"""Generate licensed Roboto Mono BMFont resources at native device sizes."""
from pathlib import Path
from urllib.request import urlopen
from PIL import Image, ImageDraw, ImageFont
from xml.sax.saxutils import escape
import json, uuid

ROOT = Path(__file__).resolve().parents[1]
def write(path, text):
    p = ROOT / path
    p.parent.mkdir(parents=True, exist_ok=True)
    p.write_text(text, encoding='utf-8')

assets = ROOT / 'assets/fonts'
assets.mkdir(parents=True, exist_ok=True)
for name, url in {
    'RobotoMono.ttf': 'https://raw.githubusercontent.com/google/fonts/main/ofl/robotomono/RobotoMono%5Bwght%5D.ttf',
    'RobotoCondensed.ttf': 'https://raw.githubusercontent.com/google/fonts/main/ofl/robotocondensed/RobotoCondensed%5Bwght%5D.ttf',
    'RobotoCondensed-OFL.txt': 'https://raw.githubusercontent.com/google/fonts/main/ofl/robotocondensed/OFL.txt',
    'NotoSansSC.ttf': 'https://raw.githubusercontent.com/google/fonts/main/ofl/notosanssc/NotoSansSC%5Bwght%5D.ttf',
    'OFL.txt': 'https://raw.githubusercontent.com/google/fonts/main/ofl/robotomono/OFL.txt',
    'NotoSansSC-OFL.txt': 'https://raw.githubusercontent.com/google/fonts/main/ofl/notosanssc/OFL.txt',
}.items():
    if not (assets / name).exists():
        (assets / name).write_bytes(urlopen(url).read())

devices = {
    # Round 240 MIP
    'fenix7s': (240,False), 'fenix7spro': (240,False),
    # Round 260 MIP
    'fenix7': (260,False),
    'fenix7pro': (260,False), 'fenix7pronowifi': (260,False),
    'fenix8solar47mm': (260,False), 'fenix9prosolar47mm': (260,False),
    'fr255': (260,False), 'fr255m': (260,False), 'fr955': (260,False),
    # Round 280 MIP
    'fenix7x': (280,False), 'fenix7xpro': (280,False),
    'fenix7xpronowifi': (280,False),
    'fenix8solar51mm': (280,False), 'fenix9prosolar51mm': (280,False),
    'enduro3': (280,False),
    # Round 390 AMOLED
    'approachs50': (390,True), 'approachs7042mm': (390,True),
    'descentg2': (390,True), 'descentmk343mm': (390,True),
    'epix2pro42mm': (390,True), 'fr165': (390,True), 'fr165m': (390,True),
    'fr170': (390,True), 'fr170m': (390,True), 'fr57042mm': (390,True),
    'fr70': (390,True), 'instinct3amoled45mm': (390,True),
    'instinctcrossoveramoled': (390,True), 'marq2': (390,True),
    'marq2aviator': (390,True), 'venu3s': (390,True), 'venu441mm': (390,True),
    'vivoactive5': (390,True), 'vivoactive6': (390,True),
    # Round 416 AMOLED
    'd2airx10': (416,True), 'd2mach1': (416,True), 'epix2': (416,True),
    'epix2pro47mm': (416,True), 'fenix843mm': (416,True), 'fenix943mm': (416,True),
    'fenix9pro43mm': (416,True), 'fenixe': (416,True), 'fr265': (416,True),
    'instinct3amoled50mm': (416,True), 'venu2': (416,True), 'venu2plus': (416,True),
    # Round 454 AMOLED
    'approachs7047mm': (454,True), 'd2mach2': (454,True), 'd2mach2pro': (454,True),
    'descentmk351mm': (454,True), 'epix2pro51mm': (454,True), 'fenix847mm': (454,True),
    'fenix8pro47mm': (454,True), 'fenix947mm': (454,True), 'fenix9pro47mm': (454,True),
    'fr57047mm': (454,True), 'fr965': (454,True), 'fr970': (454,True),
    'venu3': (454,True), 'venu445mm': (454,True),
    # Round 466 AMOLED
    'fenix9pro51mm': (466,True),
    # Existing third-face profile retained for backwards compatibility.
    'fr265s': (360,True),
}
# Modern round devices; each profile has a native font atlas.
jungle = ['project.manifest = manifest.xml','base.sourcePath = source','base.resourcePath = resources']
for name,(size,amoled) in devices.items():
    resource_path = f'{name}.resourcePath = $(base.resourcePath);resources-{size}'
    if name == 'instinct3amoled45mm': resource_path += ';resources-instinct3-390'
    if name == 'instinct3amoled50mm': resource_path += ';resources-instinct3-416'
    if amoled: resource_path += ';resources-amoled'
    jungle.append(resource_path)
    jungle.append(f'{name}.excludeAnnotations = '+ ('mip' if amoled else 'amoled'))
write('monkey.jungle','\n'.join(jungle)+'\n')
source_cjk = sorted({c for c in (ROOT/'source/SolView.mc').read_text(encoding='utf-8') if '\u4e00' <= c <= '\u9fff'})
for size in sorted(set(d[0] for d in devices.values())):
    folder = ROOT / f'resources-{size}/fonts'
    folder.mkdir(parents=True, exist_ok=True)
    xml=['<fonts>']
    font_specs=[
        ('Time',54,500,''.join(chr(i) for i in range(32,127)),'RobotoMono.ttf'),
        ('Data',22,700,''.join(chr(i) for i in range(32,127)),'RobotoCondensed.ttf'),
        ('Small',15,700,''.join(chr(i) for i in range(32,127)),'RobotoCondensed.ttf'),
        ('Status',18,700,''.join(chr(i) for i in range(32,127)),'RobotoCondensed.ttf'),
        ('Aod',44,300,'0123456789:','RobotoMono.ttf'),
        # Fixed Chinese labels and Chinese-format dates only: small enough for MIP.
        ('CjkData',15,500,'0123456789 ./月日周本跑步今爬升身体能压力数心率海拔电量距离楼层活动热总分钟秒日期星期出落下次温度最高低感湿降水概率公里英尺里米次千卡度华氏恢复时间天气描述骑行晴少云雨雪风雷暴雾霾冰雹零星阵未知小大阴局部可能薄沙尘毛龙卷烟火山灰好飓带冻夹一正二三四五六七八九十冬腊初廿闰寒立春水惊蛰分清明谷夏满芒种至暑秋处白露霜降目标静息氧呼吸频摄通知睡眠评剩余天平面强近','NotoSansSC.ttf'),
        ('CjkSmall',11,500,'0123456789 ./月日周本跑步今爬升身体能压力数心率海拔电量距离楼层活动热总分钟秒日期星期出落下次温度最高低感湿降水概率公里英尺里米次千卡度华氏恢复时间天气描述骑行晴少云雨雪风雷暴雾霾冰雹零星阵未知小大阴局部可能薄沙尘毛龙卷烟火山灰好飓带冻夹一正二三四五六七八九十冬腊初廿闰寒立春水惊蛰分清明谷夏满芒种至暑秋处白露霜降目标静息氧呼吸频摄通知睡眠评剩余天平面强近','NotoSansSC.ttf'),
    ]
    for name, base, weight, chars, font_file in font_specs:
        if name in ('CjkData', 'CjkSmall'):
            chars = ''.join(dict.fromkeys(chars + ''.join(chr(i) for i in range(32,127)) + ''.join(source_cjk)))
            if size <= 280:
                mip_sizes = {
                    'CjkData': {240:15, 260:19, 280:20},
                    'CjkSmall': {240:10, 260:13, 280:14},
                }
                px = mip_sizes[name][size]
            else:
                base = 24 if name=='CjkData' else 15
                px = round(base*size/280)
        else:
            px=round(base*size/280)
        font=ImageFont.truetype(str(assets/font_file),px)
        if font_file in ('RobotoMono.ttf','RobotoCondensed.ttf'): font.set_variation_by_axes([weight])
        if font_file == 'NotoSansSC.ttf': font.set_variation_by_axes([weight])
        boxes=[font.getbbox(c) for c in chars]
        top=min(b[1] for b in boxes); bottom=max(b[3] for b in boxes)
        h=bottom-top
        # CJK glyphs are full-width; sizing from the digit "0" clipped them.
        cell=max(round(font.getlength(c)) for c in chars)+3
        cols=min(len(chars),1024//cell); rows=(len(chars)+cols-1)//cols
        atlas=Image.new('RGBA',(cols*cell,rows*(h+2)),(255,255,255,0))
        draw=ImageDraw.Draw(atlas)
        face = 'Noto Sans SC' if font_file == 'NotoSansSC.ttf' else 'Roboto Mono'
        aa = 1 if size <= 280 else 2
        lines=[f'info face="{face}" size={px} bold=0 italic=0 unicode=1 smooth=1 aa={aa}',f'common lineHeight={h} base={h} scaleW={atlas.width} scaleH={atlas.height} pages=1 packed=0',f'page id=0 file="{name}.png"',f'chars count={len(chars)}']
        for i,c in enumerate(chars):
            x=(i%cols)*cell;y=(i//cols)*(h+2)
            draw.text((x,y-top),c,font=font,fill='white')
            lines.append(f'char id={ord(c)} x={x} y={y} width={cell-1} height={h} xoffset=0 yoffset=0 xadvance={round(font.getlength(c))} page=0 chnl=15')
        atlas.save(folder/f'{name}.png')
        (folder/f'{name}.fnt').write_text('\n'.join(lines),encoding='utf-8')
        antialias = ' antialias="true"' if name in ('CjkData', 'CjkSmall') else ''
        xml.append(f'<font id="{name}" filename="{name}.fnt"{antialias}/>')
    # Tight numeral-only atlas: fixed ink height, no alphabet/descender padding.
    compact_chars='0123456789:'
    compact_font=ImageFont.truetype(str(assets/'RobotoCondensed.ttf'),round(70*size/280))
    compact_font.set_variation_by_axes([800])
    ink_h=round(44*size/280)
    digit_w=round(23*size/280)
    colon_w=round(9*size/280)
    gap=max(1,round(size/280))
    atlas=Image.new('RGBA',(10*(digit_w+gap)+colon_w+gap,ink_h),(255,255,255,0))
    lines=[f'info face="Roboto Condensed Compact Bold" size={ink_h} bold=1 italic=0 unicode=1',f'common lineHeight={ink_h} base={ink_h} scaleW={atlas.width} scaleH={ink_h} pages=1 packed=0','page id=0 file="CompactTime.png"','chars count=11']
    x=0
    for c in compact_chars:
        box=compact_font.getbbox(c)
        glyph=Image.new('RGBA',(round(compact_font.getlength(c)),box[3]-box[1]),(255,255,255,0))
        ImageDraw.Draw(glyph).text((0,-box[1]),c,font=compact_font,fill='white')
        w=colon_w if c==':' else digit_w
        h=round(24*size/280) if c==':' else ink_h
        glyph=glyph.resize((w,h),Image.Resampling.LANCZOS)
        atlas.alpha_composite(glyph,(x,(ink_h-h)//2))
        lines.append(f'char id={ord(c)} x={x} y=0 width={w} height={ink_h} xoffset=0 yoffset=0 xadvance={w+gap} page=0 chnl=15')
        x+=w+gap
    if size<=280:
        atlas.putalpha(atlas.getchannel('A').point(lambda a:255 if a>=110 else 0))
    atlas.save(folder/'CompactTime.png')
    (folder/'CompactTime.fnt').write_text('\n'.join(lines),encoding='utf-8')
    xml.append('<font id="CompactTime" filename="CompactTime.fnt"/>')
    (folder/'fonts.xml').write_text('\n'.join(xml+['</fonts>']),encoding='utf-8')

# Instinct 3 AMOLED uses a compact, regular-weight CJK atlas. Its display
# density is lower than the other AMOLED families, so the shared 24-unit face
# crowds the four-row data block.
source_font = assets/'NotoSansSC.ttf'
for size in (390, 416):
    folder = ROOT/f'resources-instinct3-{size}/fonts'
    folder.mkdir(parents=True, exist_ok=True)
    source_atlas = ROOT/f'resources-{size}/fonts/CjkData.fnt'
    chars = ''.join(chr(int(line.split()[1][3:])) for line in source_atlas.read_text(encoding='utf-8').splitlines() if line.startswith('char id='))
    px = round(18*size/280)
    font = ImageFont.truetype(str(source_font), px)
    font.set_variation_by_axes([400])
    boxes = [font.getbbox(c) for c in chars]
    top = min(b[1] for b in boxes); bottom = max(b[3] for b in boxes)
    height = bottom-top
    cell = max(round(font.getlength(c)) for c in chars)+3
    cols = min(len(chars), 1024//cell); rows = (len(chars)+cols-1)//cols
    atlas = Image.new('RGBA',(cols*cell,rows*(height+2)),(255,255,255,0))
    draw = ImageDraw.Draw(atlas)
    lines = [f'info face="Noto Sans SC" size={px} bold=0 italic=0 unicode=1 smooth=1 aa=2',
             f'common lineHeight={height} base={height} scaleW={atlas.width} scaleH={atlas.height} pages=1 packed=0',
             'page id=0 file="InstinctCjkData.png"',f'chars count={len(chars)}']
    for i,c in enumerate(chars):
        x=(i%cols)*cell; y=(i//cols)*(height+2)
        draw.text((x,y-top),c,font=font,fill='white')
        lines.append(f'char id={ord(c)} x={x} y={y} width={cell-1} height={height} xoffset=0 yoffset=0 xadvance={round(font.getlength(c))} page=0 chnl=15')
    atlas.save(folder/'InstinctCjkData.png')
    (folder/'InstinctCjkData.fnt').write_text('\n'.join(lines),encoding='utf-8')
    (folder/'fonts.xml').write_text('<fonts>\n<font id="CjkData" filename="InstinctCjkData.fnt" antialias="true"/>\n</fonts>',encoding='utf-8')

strings={'AppName':'几何旷野 SOL','CustomText':'个性文字（留空隐藏）','Language':'显示语言','English':'English','Chinese':'中文','TimeStyle':'时间字体','Mono':'Roboto Mono','Condensed':'紧凑粗体（设备支持时）'}
properties=[]; settings=[]

def section(key, title):
    strings[key+'Title']=title
    properties.append(f'<property id="{key}" type="string"></property>')
    settings.append(f'<setting propertyKey="@Properties.{key}" title="@Strings.{key}Title"><settingConfig type="alphaNumeric" readonly="true"/></setting>')
def prop(key,typ,val,title,options=None,config=None,option_group=None):
    strings[key+'Title']=title
    properties.append(f'<property id="{key}" type="{typ}">{escape(str(val))}</property>')
    if options is not None:
        entries=''
        for i,(v,label) in enumerate(options):
            sid=(option_group or key)+'Opt'+str(i);strings[sid]=label
            entries+=f'<listEntry value="{v}">@Strings.{sid}</listEntry>'
        cfg=f'<settingConfig type="list">{entries}</settingConfig>'
    else: cfg=config
    settings.append(f'<setting propertyKey="@Properties.{key}" title="@Strings.{key}Title">{cfg}</setting>')
section('SectionGeneral','常规')
prop('CustomText','string','SOL','个性文字（留空隐藏）',config='<settingConfig type="alphaNumeric"/>')
prop('Language','number',0,'显示语言',[(0,'英文'),(1,'中文')])
prop('TimeStyle','number',0,'时间字体',[(0,'紧凑粗体（设备支持时）'),(1,'Roboto Mono')])
prop('ShowSecondsActive','boolean','false','抬腕时显示秒',config='<settingConfig type="boolean"/>')
prop('UpdateFrequency','number',60,'刷新频率',[(60,'标准（1分钟）'),(30,'及时（30秒）'),(300,'省电（5分钟）')])
prop('SolarDisplay','number',2,'太阳信息',[(2,'隐藏（完整山景）'),(0,'下次日出 / 日落时间'),(1,'距离下次日出 / 日落的时长')])
prop('TemperatureUnit','number',0,'温度单位',[(0,'摄氏 (C)'),(1,'华氏 (F)')])
prop('Units','number',0,'距离与高度单位',[(0,'跟随设备'),(1,'公制'),(2,'英制')])
section('SectionProgress','顶部进度')
prop('ProgressMetric','number',0,'进度内容',[(0,'电量'),(1,'身体电量'),(2,'压力')])
section('SectionDate','日期行')
prop('ShowWeekday','boolean','true','显示星期',config='<settingConfig type="boolean"/>')
prop('ShowMonthDay','boolean','true','显示月日',config='<settingConfig type="boolean"/>')
prop('ShowLunar','boolean','false','显示农历',config='<settingConfig type="boolean"/>')
prop('ShowSolarTerm','boolean','false','显示下一个节气',config='<settingConfig type="boolean"/>')

field_en=['Hidden','Weekly run','Elevation gain','Body battery','Stress','Steps','Heart rate','Altitude','Battery','Daily distance','Floors','Active calories','Total calories','Active minutes','Seconds','Date','Weekday','Sunrise','Sunset','Next sun event','Temperature','High temperature','Low temperature','Feels like','Humidity','Precipitation chance','Recovery','Weather description','Daily running distance','Monthly running distance','Daily cycling distance','Weekly cycling distance','Monthly cycling distance','Weekly active minutes','Step goal','Resting heart rate','Pulse Ox','Respiration rate','Running VO2 max','Cycling VO2 max','Notifications','Sleep score','Floors descended','Battery days','Sea level pressure','Solar intensity','7-day distance','Weekly active goal','Resting calories','Training status','Tomorrow weather','Weather in 2 days','Weather in 3 days','Next calendar event time','Last golf round score','Weather location']
fields=[
    (0,'隐藏'),(1,'本周跑步'),(2,'今日爬升'),(3,'身体电量'),(4,'压力'),(5,'步数'),
    (6,'心率'),(7,'海拔'),(8,'电量'),(9,'今日距离'),(10,'楼层'),(11,'活动热量'),
    (12,'总热量'),(13,'活动分钟'),(14,'秒'),(15,'日期'),(16,'星期'),(17,'日出'),
    (18,'日落'),(19,'下次日出/日落'),(20,'温度'),(21,'最高温'),(22,'最低温'),
    (23,'体感温'),(24,'湿度'),(25,'降水概率'),(26,'恢复时间'),(27,'天气描述'),
    (28,'每日跑步距离'),(29,'每月跑步距离'),(30,'每日骑行距离'),(31,'每周骑行距离'),(32,'每月骑行距离'),
    (33,'每周活动分钟'),(34,'步数目标'),(35,'静息心率'),(36,'血氧'),(37,'呼吸频率'),
    (38,'跑步最大摄氧量'),(39,'骑行最大摄氧量'),(40,'通知'),(41,'睡眠评分'),(42,'下楼层数'),
    (43,'剩余电量天数'),(44,'海平面气压'),(45,'太阳能强度'),(46,'近7日距离'),(47,'活动分钟目标'),(48,'静息热量'),(49,'训练状态'),(50,'明天天气描述'),(51,'后天天气描述'),(52,'三天天气描述'),(53,'下次日历事件时间'),(54,'上次高尔夫成绩'),(55,'天气地点')]
section('SectionFields','自定义字段')
for i in range(1,5):prop('Field'+str(i),'number',i,'数据行 '+str(i),fields,option_group='Field')
colors=[
    (0xA63E32,'山景赤陶'),(0x4A6A7A,'山景远蓝'),(0x243747,'山景深蓝'),(0x000055,'山景靛蓝'),
    (0xF5E6D3,'山景暖白'),(0xC7CBCB,'山景雾灰'),(0xFF6633,'山景珊瑚'),(0xFF5500,'山景亮橙'),
    (0xFBCB77,'柔琥珀'),(0xFF9161,'蜜桃'),(0x89EFD2,'薄荷'),(0x96E0AC,'春绿'),(0x3DA855,'原野绿'),
    (0xFF5566,'珊瑚粉'),(0xFF77BB,'粉色'),(0xB77CFF,'紫色'),(0x55AAFF,'蓝色'),(0x00DDCC,'青色'),
    (0x55FF99,'绿色'),(0xFFEE44,'黄色'),(0xFFCC33,'金色'),(0xFFAA55,'橙色'),
    (0xC7C7C7,'灰色'),(0x000000,'黑色'),(0xFFFFFF,'白色')]

# Retain the original nuanced and accent RGB values; omit seven standard solid colors.
soft_colors=[(0xD6A0A7,'柔玫瑰','Soft rose'),(0x9DB6CC,'雾蓝','Misty blue'),
    (0xA8B89C,'鼠尾草','Sage'),(0xB8A7CC,'浅薰衣草','Soft lavender'),
    (0xD8C3A5,'柔沙色','Soft sand'),(0xE7D5A0,'奶油黄','Cream yellow'),
    (0x91B8B1,'灰青','Muted teal'),(0xC58B78,'柔赤陶','Soft terracotta'),
    (0x8F5967,'烟玫瑰','Dusty rose'),(0x6C6086,'暮紫','Dusk violet'),
    (0x657B68,'深鼠尾草','Deep sage'),(0x5D7E95,'雾海蓝','Muted ocean blue'),
    (0x486F73,'深青灰','Deep muted teal'),(0x8D6655,'陶土棕','Clay brown'),
    (0xA17A50,'黄昏赭','Dusk ochre'),(0x898176,'暖石灰','Warm stone')]
for i,(_,label,_) in enumerate(soft_colors): strings['AmoledSoftOpt'+str(i)]=label
defaults={'Background':0xA63E32,'Sky':0xA63E32,'SkyThird':0xA63E32,'Sun':0xFF5500,'Dots':0xC7CBCB,'Ridge':0x4A6A7A,'Foreground':0x243747,'TimeColor':0xF5E6D3,'SecondsColor':0xFF6633,'DateColor':0xFFFFFF,'LabelColor':0xFFFFFF,'ValueColor':0xF5E6D3,'CustomColor':0xFF6633,'ArcColor':0xFF5500,'ProgressValueColor':0xC7CBCB,'EventColor':0xFF6633}
section('SectionColors','配色')
prop('SkyColorCount','number',1,'天空颜色数量',[(1,'1 色'),(2,'2 色'),(3,'3 色')])
positions=[(v,str(v)+'%') for v in range(5,100,5)]
prop('SkyBoundary1','number',0,'天空第一分界（距顶部）',[(0,'原位置')]+positions)
prop('SkyBoundary2','number',85,'天空第二分界（3色，距顶部）',positions)
for key,label in [('Background','天空第1层'),('Sky','天空第2层'),('SkyThird','天空第3层'),('Sun','太阳图标'),('Dots','远山'),('Ridge','近山'),('Foreground','山体阴影与树影'),('TimeColor','时间'),('SecondsColor','秒数'),('DateColor','日期'),('LabelColor','数据标签'),('ValueColor','数据数值'),('CustomColor','个性文字'),('ArcColor','顶部进度弧'),('ProgressValueColor','顶部数值与图标'),('EventColor','太阳时间')]:
    prop(key,'number',defaults[key],label+'颜色',colors,option_group='Color')
write('resources/settings/properties.xml','<properties>\n'+'\n'.join(properties)+'\n</properties>')
write('resources/settings/settings.xml','<settings>\n'+'\n'.join(settings)+'\n</settings>')
# Override only color lists on AMOLED devices; retain all property IDs and defaults.
import xml.etree.ElementTree as ET
amoled_settings=ET.Element('settings')
for setting in ET.fromstring('<settings>'+''.join(settings)+'</settings>'):
    if setting.attrib['propertyKey'].split('.')[-1] in defaults:
        cfg=setting.find('settingConfig')
        base_entries=list(cfg)
        for entry in base_entries: cfg.remove(entry)
        # Existing nuanced colors, AMOLED additions, then vivid/native colors.
        cfg.extend(base_entries[:13])
        for i,(value,_,_) in enumerate(soft_colors):
            ET.SubElement(cfg,'listEntry',value=str(value)).text='@Strings.AmoledSoftOpt'+str(i)
        cfg.extend(base_entries[13:])
        amoled_settings.append(setting)
write('resources-amoled/settings/settings.xml',ET.tostring(amoled_settings,encoding='unicode'))
strings_en=dict(strings)
strings_en.update({
    'AppName':'Geometric Wilds SOL','CustomText':'Custom text (empty to hide)',
    'Language':'Display language','English':'English','Chinese':'Chinese','TimeStyle':'Time font',
    'Condensed':'Compact Bold (when supported)','CustomTextTitle':'Custom text (empty to hide)',
    'LanguageTitle':'Display language','LanguageOpt0':'English','LanguageOpt1':'Chinese',
     'TimeStyleTitle':'Time font','TimeStyleOpt0':'Compact Bold (when supported)','TimeStyleOpt1':'Roboto Mono','ShowSecondsActiveTitle':'Show seconds when active',
    'UpdateFrequencyTitle':'Data refresh frequency','UpdateFrequencyOpt0':'Standard (1 min)','UpdateFrequencyOpt1':'Frequent (30 sec)','UpdateFrequencyOpt2':'Power save (5 min)',
    'SolarDisplayTitle':'Sun information','SolarDisplayOpt0':'Hidden (full landscape)',
    'SolarDisplayOpt1':'Next sunrise / sunset time','SolarDisplayOpt2':'Time until next sunrise / sunset',
    'TemperatureUnitTitle':'Temperature unit','TemperatureUnitOpt0':'Celsius (C)','TemperatureUnitOpt1':'Fahrenheit (F)',
    'UnitsTitle':'Distance and elevation units','UnitsOpt0':'Follow device','UnitsOpt1':'Metric','UnitsOpt2':'Imperial',
    'SectionGeneralTitle':'General','SectionProgressTitle':'Top progress','SectionFieldsTitle':'Custom fields','SectionColorsTitle':'Colors',
    'SectionDateTitle':'Date line','ShowWeekdayTitle':'Show weekday','ShowMonthDayTitle':'Show month and day',
    'ShowLunarTitle':'Show lunar date','ShowSolarTermTitle':'Show next solar term',
    'SkyColorCountTitle':'Sky color count','SkyColorCountOpt0':'1 color','SkyColorCountOpt1':'2 colors','SkyColorCountOpt2':'3 colors',
    'SkyBoundary1Title':'First sky boundary (from top)','SkyBoundary1Opt0':'Original position','SkyBoundary2Title':'Second sky boundary (3 colors, from top)',
    'BackgroundTitle':'Sky layer 1 color','SkyTitle':'Sky layer 2 color','SkyThirdTitle':'Sky layer 3 color','SunTitle':'Sun icon color',
    'DotsTitle':'Far mountain color','RidgeTitle':'Near mountain color','ForegroundTitle':'Mountain shadow and trees color',
     'TimeColorTitle':'Time color','SecondsColorTitle':'Seconds color','DateColorTitle':'Date color','LabelColorTitle':'Data label color',
    'ProgressMetricTitle':'Progress content','ProgressMetricOpt0':'Battery','ProgressMetricOpt1':'Body battery','ProgressMetricOpt2':'Stress',
    'ValueColorTitle':'Data value color','CustomColorTitle':'Custom text color','ArcColorTitle':'Top progress arc color','ProgressValueColorTitle':'Top value and icon color','EventColorTitle':'Sun time color'
})
color_en={'山景赤陶':'Terracotta','山景远蓝':'Far blue','山景深蓝':'Deep blue','山景靛蓝':'Indigo','山景暖白':'Warm white','山景雾灰':'Mist gray','山景珊瑚':'Coral','山景亮橙':'Vivid orange','珊瑚粉':'Coral pink','灰色':'Gray','紫色':'Purple','蓝色':'Blue','青色':'Cyan','绿色':'Green','原野绿':'Field green','黄色':'Yellow','金色':'Gold','橙色':'Orange','粉色':'Pink','黑色':'Black','白色':'White','纸白':'Paper white','柔琥珀':'Soft amber','薄荷':'Mint','春绿':'Spring green','蜜桃':'Peach','墨褐':'Ink brown'}
color_en.update({'纯红':'Red','深红':'Dark red','深绿':'Dark green','纯蓝':'Deep blue','标准紫':'Standard purple','深灰':'Dark gray'})
for key,value in strings.items(): strings_en[key]=color_en.get(value,strings_en[key])
for i,(_,_,label) in enumerate(soft_colors): strings_en['AmoledSoftOpt'+str(i)]=label
for i in range(1,5):
    strings_en['Field'+str(i)+'Title']='Custom field '+str(i)
for j,label in enumerate(field_en): strings_en['FieldOpt'+str(j)]=label
write('resources/strings/strings.xml','<strings>\n'+'\n'.join(f'<string id="{k}">{escape(v)}</string>' for k,v in strings_en.items())+'\n</strings>')
write('resources-zhs/strings/strings.xml','<strings>\n'+'\n'.join(f'<string id="{k}">{escape(v)}</string>' for k,v in strings.items())+'\n</strings>')
if not (ROOT/'manifest.xml').exists():
    write('manifest.xml','<?xml version="1.0"?>\n<iq:manifest xmlns:iq="http://www.garmin.com/xml/connectiq" version="3">\n'+f'<iq:application id="{uuid.uuid4().hex}" entry="SolApp" name="@Strings.AppName" launcherIcon="@Drawables.LauncherIcon" type="watchface" minApiLevel="4.2.2" version="0.1.0">\n<iq:products>'+''.join(f'<iq:product id="{n}"/>' for n in devices)+'</iq:products>\n<iq:permissions><iq:uses-permission id="ComplicationSubscriber"/><iq:uses-permission id="Positioning"/><iq:uses-permission id="SensorHistory"/><iq:uses-permission id="UserProfile"/></iq:permissions><iq:languages><iq:language>eng</iq:language><iq:language>zhs</iq:language></iq:languages><iq:barrels/></iq:application></iq:manifest>')
icon=Image.new('RGB',(40,40),'black'); d=ImageDraw.Draw(icon);d.ellipse((17,5,35,23),fill='#ff5500');d.polygon([(0,29),(11,18),(22,29),(30,22),(39,30),(39,39),(0,39)],fill='#5555aa')
(ROOT/'resources/drawables').mkdir(parents=True,exist_ok=True)
icon.save(ROOT/'resources/drawables/icon.png')
write('resources/drawables/drawables.xml','<drawables><bitmap id="LauncherIcon" filename="icon.png"/><bitmap id="BodyBatteryIcon" filename="body_battery_handsup.svg" dithering="none" packingFormat="png" automaticPalette="false"/><bitmap id="MdiBattery" filename="mdi_battery.svg" dithering="none" packingFormat="png" automaticPalette="false"/><bitmap id="MdiBrain" filename="mdi_brain.svg" dithering="none" packingFormat="png" automaticPalette="false"/></drawables>')
print('Resources generated for', ', '.join(devices))

# Use the same ordered schema for phone and native watch menus.
import xml.etree.ElementTree as ET
rows=[]
color_keys=set(defaults)
color_choices=None
field_choices=None
for setting in ET.fromstring('<settings>'+''.join(settings)+'</settings>'):
    key=setting.attrib['propertyKey'].split('.')[-1]
    title=strings[setting.attrib['title'].split('.')[-1]]
    title_en=strings_en.get(setting.attrib['title'].split('.')[-1],title)
    if key.startswith('Section'):
        rows.append([key,title,None,title_en])
        continue
    cfg=setting.find('settingConfig')
    choices=None
    if cfg.attrib['type']=='list':
        choices=[]
        for e in cfg:
            label_key=e.text.split('.')[-1]
            choices.append([int(e.attrib['value']),strings[label_key],strings_en.get(label_key,strings[label_key])])
    elif cfg.attrib['type']=='boolean':
        choices=[[False,'关闭','Off'],[True,'开启','On']]
    if key in color_keys:
        if color_choices is None: color_choices=choices
        assert choices==color_choices, 'All color settings must expose the same palette'
        choices='__COLOR_CHOICES__'
    if key in ['Field1','Field2','Field3','Field4']:
        if field_choices is None: field_choices=choices
        assert choices==field_choices, 'All four field settings must expose the same options'
        choices='__FIELD_CHOICES__'
    rows.append([key,title,choices,title_en])
# Native settings use the same localized resources as phone settings.
watch_menu_keys=['Language', 'ShowSecondsActive', 'SolarDisplay', 'TemperatureUnit', 'Units', 'ProgressMetric', 'Field1', 'Field2', 'Field3', 'Field4']
menu_rows=[]
choice_cases=[]
seen=set()
for setting in ET.fromstring('<settings>'+''.join(settings)+'</settings>'):
    key=setting.attrib['propertyKey'].split('.')[-1]
    title_id=setting.attrib['title'].split('.')[-1]
    cfg=setting.find('settingConfig');kind=cfg.attrib['type']
    if key in watch_menu_keys:
        menu_rows.append('['+json.dumps(key)+',WatchUi.loadResource(Rez.Strings.'+title_id+'),'+('true' if kind in ['list','boolean'] else 'false')+']')
    if kind not in ['list','boolean']: continue
    group='Color' if key in defaults else ('Field' if key in ['Field1','Field2','Field3','Field4'] else key)
    if group in seen: continue
    seen.add(group)
    if group=='Color': condition=' || '.join('key.equals('+json.dumps(k)+')' for k in defaults)
    elif group=='Field': condition=' || '.join('key.equals('+json.dumps('Field'+str(i))+')' for i in range(1,5))
    else: condition='key.equals('+json.dumps(key)+')'
    if kind=='boolean': body='return [false,language==1?"关闭":"Off",true,language==1?"开启":"On"];'
    else:
        entries=[e.attrib['value']+',Rez.Strings.'+e.text.split('.')[-1] for e in cfg]
        if group=='Color':
            additions=[str(v)+',Rez.Strings.AmoledSoftOpt'+str(i) for i,(v,_,_) in enumerate(soft_colors)]
            body='return isAmoled()?['+','.join(entries[:13]+additions+entries[13:])+']:['+','.join(entries)+'];'
        else: body='return ['+','.join(entries)+'];'
    choice_cases.append(' if('+condition+') {'+body+' }')
write('source/SolSettingsData.mc','// Generated from the phone settings schema; do not edit.\nimport Toybox.WatchUi;\nimport Toybox.Lang;\nmodule SolSettingsData {\n (:amoled) function isAmoled() { return true; }\n (:mip) function isAmoled() { return false; }\n function rows(language) { return ['+','.join(menu_rows)+']; }\n function choices(key,language) {'+''.join(choice_cases)+' return null; }\n function option(choices,index) { var label=choices[index*2+1]; return label instanceof String?label:WatchUi.loadResource(label); }\n function label(key,value,language) { var options=SolSettingsData.choices(key,language); for(var i=0;i<options.size();i+=2) { if(options[i]==value) { return SolSettingsData.option(options,i/2); } } return value==null?"":value.toString(); }\n}\n')
