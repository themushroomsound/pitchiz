import Pitchiz
import os

os.system('cls')  # on windows

kbd = Pitchiz.pitchiz_MIDIKeyboard( -2 );

gsharp1 = kbd.getNote( 32 )
a3 = kbd.getNote( 69 )

interval = Pitchiz.pitchiz_Note.getInterval( gsharp1, a3 )
print("interval from A3: " + str(interval))

freq = gsharp1.getKey(kbd).getFrequency();
print("freq G#1: " + str(freq))

for i in range(9,128,12):
    key = kbd.getKey( i );
    freq = key.getFrequency();
    keyFromFreq = kbd.getKeyFromFrequency( freq );
    print(str(i) + " -> " + key.toString() + " -> " + str(freq) + "hz -> " + keyFromFreq.toString())
