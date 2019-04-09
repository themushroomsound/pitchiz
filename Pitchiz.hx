package pitchiz;

// PITCHIZ
@:expose
@:keep
class Pitchiz
{
    public static var A440Freq(default, null):Float = 440.0;
    public static var A440Index(default, null):Int = 69;
    public static var TwelfthRootOf2(default, null):Float = Math.pow(2, 1.0 / 12.0);
}

// CHROMA (a note, at any octave)
@:expose
@:keep
class Chroma
{
    // static members
    public static var Names(default, null):Array<String> = ["C", "C♯", "D", "E♭", "E", "F", "F♯", "G", "G♯", "A", "B♭", "B"];

    // create a Chroma object from a chroma name
    public static function createFromName( name:String ):Chroma
    {
        var found:Bool = false;
        var index = -1;
        name = name.split("#").join("♯").split("b").join("♭");
        name = name.split("D♯").join("E♭").split("A♯").join("B♭").split("D♭").join("C♯").split("G♭").join("F♯").split("A♭").join("G♯");
        while(!found && index < Chroma.Names.length) {
            index++;
            found = name == Chroma.Names[ index ];
        }
        if( found )
            return new Chroma( index );
        //throw "Unknow chroma name"; // seems unsupported by Python 2.7, forget it for now
        return null;
    }

    // instance members
    public var index(default, null):Int;

    // constructor - chroma is A by default
    public function new( ?index:Int = 9 )
    {
        //trace( "new chroma: " + index + " (" + Chroma.Names[ index ] + ")" );
        this.index = index;
    }

    // create a new chroma by adding an interval to this one
    public function addInterval( interval:Int ):Chroma
    {
        var newIndex:Int = ( this.index + interval ) % 12;
        // for some reason modulo fucks up (at least) in python, so:
        if(newIndex < 0) newIndex += 12;
        return new Chroma( newIndex );
    }

    // gets the interval between 2 chromas
    public static function getInterval( chroma1:Chroma, chroma2:Chroma )
    {
        var interval:Int = chroma1.index - chroma2.index;
        return interval;
    }

    public function toString():String
    {
        return Chroma.Names[ index ];
    }
}

// NOTE (a chroma at a certain octave)
@:expose
@:keep
class Note
{
    public var chroma(default, default):Chroma;
    public var octave(default, default):Int;
    public static var NameRegex(default, null) = ~/([A-G][#b♯♭]{0,1})(-{0,1}[0-9])/;

    public static function findNoteInString( str:String ):Note
    {
        var r = Note.NameRegex;
        if( r.match( str ) ) {
            var chroma:Chroma = Chroma.createFromName( r.matched(1) );
            var octave:Int = Std.parseInt( r.matched(2) );
            return new Note( chroma, octave );
        }
        //throw "No note name found in string"; // seems unsupported by Python 2.7, forget it for now
        return null;
    }

    public function new( noteChroma:Chroma, noteOctave:Int )
    {
        //trace("new note: " + noteChroma.toString() + Std.int(noteOctave));
        this.chroma = noteChroma;
        this.octave = noteOctave;
    }

    // gets a new note by adding an interval to this one
    public function addInterval( interval:Int ):Note
    {
        var newChroma = this.chroma.addInterval( interval );
        var newOctave = this.octave + Math.floor( interval / 12 );
        return new Note( newChroma, newOctave );
    }

    // get the interval between 2 notes
    public static function getInterval( note1:Note, note2:Note ):Int
    {
        var octaveDelta:Int = note1.octave - note2.octave;
        var interval:Int = Chroma.getInterval( note1.chroma, note2.chroma );
        return Std.int(octaveDelta * 12 + interval);
    }

    public function getKey( kbd:MIDIKeyboard ):MIDIKey
    {
        return kbd.getKeyFromNote( this );
    }

    public function toString():String
    {
        return chroma.toString() + Std.int(octave);
    }
}

// Scale (a chroma + a mode)
@:expose
@:keep
class Scale
{
    public var chroma(default, default):Chroma;
    public var mode(default, default):Bool; // true -> major, false -> minor
    public var circle5thIndex(get, null):Int;

    public function new( chroma:Chroma, mode:Bool )
    {
        this.chroma = chroma;
        this.mode = mode;
    }

    public function get_circle5thIndex():Int
    {
        var shift:Int = mode ? 0 : 3;
        return ((chroma.index + shift) * 7) % 12 + 1;
    }

    public function transpose(transposition:Int):Scale
    {
        return new Scale( this.chroma.addInterval(transposition), this.mode );
    }

    public function toString():String
    {
        var min:String = mode ? "" : "m";
        return chroma.toString() + min;
    }

    public function equals(other:Scale):Bool
    {
        return this.chroma.index == other.chroma.index && this.mode == other.mode;
    }

    public function isRelativeTo(other:Scale):Bool
    {
        return this.circle5thIndex == other.circle5thIndex && this.mode != other.mode;
    }
}

// MIDI KEY (a note, but relative to a keyboard, with a key index)
@:expose
@:keep
class MIDIKey
{
    public var index(default, default):Int;
    public var midiKeyboard(default, default):MIDIKeyboard;

    public function new( midiKeyboard:MIDIKeyboard, index:Int )
    {
        //trace("new MIDI key");
        this.midiKeyboard = midiKeyboard;
        this.index = index;
    }

    public function getNote()
    {
        return midiKeyboard.lowestNote.addInterval( index );
    }

    public function getFrequency()
    {
        if( index == Pitchiz.A440Index )
            return Pitchiz.A440Freq;
        return Pitchiz.A440Freq * Math.pow( Pitchiz.TwelfthRootOf2, index - Pitchiz.A440Index );
    }

    public function toString():String
    {
        return getNote().toString() + " (" + index + ")";
    }
}

// KEYBOARD DEFINITION
@:expose
@:keep
class MIDIKeyboard
{
    public var lowestOctave(default, default):Int;
    public var lowestNote(default, null):Note;

    public function new( lowestOctave:Int )
    {
        //trace("new MIDI keyboard");
        this.lowestOctave = lowestOctave;
        var c:Chroma = new Chroma( 0 );
        this.lowestNote = new Note( c, lowestOctave );
    }

    public function getKey( keyIndex:Int ):MIDIKey
    {
        return new MIDIKey( this, keyIndex );
    }

    public function getNote( keyIndex:Int ):Note
    {
        return getKey( keyIndex ).getNote();
    }

    public function getKeyFromNote( note:Note ):MIDIKey
    {
        return new MIDIKey( this, Note.getInterval(note, this.lowestNote) );
    }

    public function getKeyFromFrequency( freq:Float ):MIDIKey
    {
        var freqRatio:Float = freq / 440.0;
        var keyIndex = Pitchiz.A440Index + (12 * Math.log(freqRatio)/Math.log(2.0));
        return getKey( Std.int( Math.round(keyIndex) ) );
    }
}
