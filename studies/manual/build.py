"""Build the local half-letter manual mockup. Requires reportlab and Pillow."""
from pathlib import Path
from reportlab.pdfgen import canvas
from reportlab.platypus import Paragraph
from reportlab.lib.styles import ParagraphStyle
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
ART = Path(__file__).parent / 'art'
OUT = ROOT / 'output/pdf/cairn-manual-mockup.pdf'
OUT.parent.mkdir(parents=True, exist_ok=True)
pdfmetrics.registerFont(TTFont('Gothic', str(ROOT / 'asset-sources/fonts/grenze-gotisch.ttf')))
W,H=396,612
c=canvas.Canvas(str(OUT),pagesize=(W,H))
c.setTitle('CAIRN - A Book of Ash & Bone - Manual Mockup')
c.setAuthor('Maximum Force / CAIRN')
body=ParagraphStyle('body',fontName='Times-Roman',fontSize=10.5,leading=13.2)
small=ParagraphStyle('small',parent=body,fontSize=8,leading=10)
def para(text,x,y,w=324,style=body):
    p=Paragraph(text,style); _,h=p.wrap(w,1000)
    assert y-h>=38, (text,y,h)
    p.drawOn(c,x,y-h)
    return y-h-10
def label(text,x,y,size=8):
    c.setFont('Helvetica-Bold',size);c.drawString(x,y,text)
def title(text,y=547,size=30):
    c.setFont('Gothic',size);c.drawString(36,y,text)
def art(name,x,y,w,h):
    p=ART/(name+'.png');iw,ih=Image.open(p).size
    scale=min(w/iw,h/ih);dw,dh=iw*scale,ih*scale
    c.drawImage(str(p),x+(w-dw)/2,y+(h-dh)/2,dw,dh,mask='auto')
def begin(num,section):
    c.setStrokeColorRGB(0,0,0);c.setFillColorRGB(0,0,0)
    label('CAIRN  /  A BOOK OF ASH & BONE',36,583,7)
    c.setLineWidth(.7);c.line(36,575,360,575)
    c.line(36,31,360,31)
    label(section.upper(),36,19,6.5)
    c.setFont('Times-Roman',8);c.drawRightString(360,19,f'{num:02}')
def end():c.showPage()
def entry(head,text,y):
    label(head.upper(),36,y,9)
    return para(text,36,y-7)-4

# 1 - cover
c.setLineWidth(2);c.rect(20,20,356,572);c.setLineWidth(.5);c.rect(25,25,346,562)
c.setFont('Gothic',64);c.drawCentredString(198,517,'CAIRN')
c.setFont('Helvetica-Bold',9);c.drawCentredString(198,496,'A BOOK OF ASH & BONE')
art('hero',40,111,316,377)
c.setFont('Gothic',22);c.drawCentredString(198,89,'The Adventurer\'s Manual')
c.setFont('Helvetica',7);c.drawCentredString(198,66,'COMBAT  /  CREATURES  /  THE WORLD BEYOND THE GATE')
c.setFont('Helvetica-Bold',7);c.drawCentredString(198,43,'MAXIMUM FORCE     -     MOCKUP EDITION 01')
end()

# 2 - proposed lore and contents
begin(2,'The old account');title('The dead remember.')
y=para('Before the marsh swallowed its roads, before ash filled the wells, the citadel kept a fire for every grave. So long as the fires burned, the dead were said to sleep.',36,518)
y=para('Then the king demanded a flame that would never die. The furnaces worked through winter. The grave fires went cold. Under the city, something answered the hammers.',36,y)
y=para('Now the soldiers walk without breath. Roots wear a crown beneath the drowned trees. Far below, a saint of iron tends a furnace that has forgotten what it was built to burn.',36,y)
y=para('You have come with an axe and no banner. At the road\'s end you stack a few stones for those who will not return. There is still room for one more.',36,y)
art('relics',70,192,256,115)
label('WITHIN THESE PAGES',36,169,9)
for i,(name,n) in enumerate([('The wanderer','03'),('The restless host','04'),('Servants of mire & fire','05'),('Lords of the ruin','06'),('Three forsaken lands','07'),('The art of staying alive','08')]):
    yy=152-i*13;c.setFont('Times-Roman',9);c.drawString(36,yy,name);c.drawRightString(360,yy,n)
para('EDITORIAL NOTE: Story passages and biographies are proposed lore for this mockup. Creature names and combat guidance follow the current game.',36,64,324,small)
end()

# 3 - hero
begin(3,'The wanderer');title('The Barbarian')
label('NO CROWN. NO COMPANY. ONE MORE MILE.',36,523,8)
art('hero',36,253,324,258)
y=para('No herald remembers his name. He comes from the hard country beyond the roads, where a grave is marked with stones because timber is too precious to spare. He has buried kin, companions, and men he once meant to kill. He knows how much a cairn weighs.',36,246)
y=para('He did not come to claim the citadel. He came because the dead have begun crossing the passes, and there is nowhere left to retreat. Whatever woke them must be reached on foot.',36,y)
y=entry('Arms & temperament','A double-headed axe, a stubborn stride, and a willingness to close the distance. Strength wins an opening; patience keeps it from becoming a trap.',y-2)
para('<i>"A king leaves a monument. The rest of us leave stones."</i>',36,y-2)
end()

# 4 - rank and file
begin(4,'Bestiary / I');title('The Restless Host')
art('host',24,347,348,183)
for x,roman in zip([62,130,198,266,334],['I','II','III','IV','V']):
    c.setFont('Helvetica-Bold',8);c.drawCentredString(x,339,roman)
y=entry('I / Bone warrior','The grave has taken everything except the habit of violence. These scraps of soldiers drift toward the living, finding courage in numbers.',318)
y=entry('II / Legionary','An old oath held inside ruined armor. The face is gone; the formation survives. Never assume the first fallen soldier has left the road empty.',y)
y=entry('III / Shield revenant','A shield raised for a kingdom that no longer exists. Watch the windup: the guard lowers just before the attack. That brief opening is your invitation.',y)
y=entry('IV / Skeleton archer','A patient hunter with neither pulse nor pity. It draws, fires, and retreats when pressed. Change your approach instead of chasing straight into the bow.',y)
entry('V / Marauder','Not all who haunt the ruins are dead. Fur-clad raiders have made a trade of following the slaughter. Their committed rush punishes an idle target.',y)
end()

# 5 - specialist enemies
begin(5,'Bestiary / II');title('Mire & Fire')
art('wilds',29,298,338,233)
y=entry('The Bog Witch','Before the roads sank, she knew every path through the reeds. Now she keeps the paths for herself. Her staff carries the little bones of travelers who trusted a voice in the fog.',285)
y=para('<b>In battle:</b> Her black mire grips the feet, weakens jumps, and drains life. Killing the witch clears her mire. Do not settle into a fight on ground she has chosen.',36,y)
y=entry('The Furnace Bearer','The old furnaces needed hands long after the workers were buried. Bent beneath a load of slag, the bearer follows a shift bell that no living ear can hear.',y-4)
para('<b>In battle:</b> Watch for thrown clinker and keep space to move. A crowded floor makes every ranged threat harder to escape.',36,y)
end()

# 6 - bosses
begin(6,'Bestiary / III');title('Lords of the Ruin')
art('bosses',23,322,350,205)
y=entry('The Cairn Champion','The last bright thing in the fallen court. Crowned and armored, he still stands as though an audience waits beyond the gate. His kingdom has narrowed to the ground beneath his feet.',304)
y=entry('The Drowned King','He would not abandon his throne when the waters rose. The roots took his command literally. Now the marsh carries him, and his great wooden arm drags the drowned earth into battle.',y-2)
y=entry('The Kiln Saint','A sealed iron reliquary built to endure the heat below. Within its chest lies the small remnant of the thing once called holy. Its chains drag through ash; its rake still tends the fire.',y-2)
para('<b>A word to the reckless:</b> The King and Saint resist ordinary blows while closed. Read their attacks, survive the commitment, and answer when their defenses open.',36,y-4)
end()

# 7 - environments
begin(7,'A traveler\'s gazetteer');title('Three Forsaken Lands',size=26)
art('lands',31,83,189,445)
mini=ParagraphStyle('mini',parent=body,fontSize=9,leading=11.5)
for yy,head,txt in [
    (442,'I / THE FALLEN<br/>CITADEL','Walls built to keep death outside now hold it in. Broken courtyards lead toward the Champion, still keeping his last watch.'),
    (337,'II / THE SUNKEN<br/>WILDS','The road goes under the water. Reeds hide the stones; roots hide the dead. Somewhere beyond the mist, a king refuses to sink.'),
    (232,'III / THE ASHEN<br/>DEPTHS','Below the world, the work continues. Chains swing over cold ash and the furnace doors breathe. The Kiln Saint is waiting.')]:
    y=para('<b>'+head+'</b>',230,yy,130,mini);para(txt,230,y,130,mini)
para('<i>Three episodes. Four areas in each. A lord at the end of the road.</i>',36,66,324,small)
end()

# 8 - actual controls
begin(8,'Keep this page beside you');title('The Art of Staying Alive',size=26)
rows=[('Move','W A S D or arrow keys'),('Run','Hold Shift, or double-tap left / right'),('Swing','J or Z'),('Crowd breaker','Hold J; release before the next spin'),('Jump / diving strike','Space (also K / X); J while airborne'),('Back attack','J + Space together on the ground'),('Magic','L or C when the mana meter is full'),('Change weapon','Q'),('Pause / resume','Escape or P')]
y=519
for a,b in rows:
    c.setLineWidth(.35);c.line(36,y-23,360,y-23)
    label(a.upper(),36,y-9,7)
    para(b,151,y-1,209,small);y-=26
y=para('<b>Fight on your terms.</b> Line up with your target before swinging. Leave room to retreat, watch the bowstring, and save a diving strike for an opening you can reach. A missed landing gives the enemy time to answer.',36,270)
y=para('<b>Earn your magic.</b> Successful melee hits build mana. When full, finish your current action and cast from the ground. Keep an eye on the meter while the crowd is still manageable.',36,y)
art('relics',67,59,262,104)
c.setFont('Gothic',15);c.drawCentredString(198,44,'Leave a stone. Keep walking.')
end()
c.save()
print(OUT)
