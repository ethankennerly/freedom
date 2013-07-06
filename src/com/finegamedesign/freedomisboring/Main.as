package com.finegamedesign.freedomisboring
{
    import org.flixel.*;
    [SWF(width="640", height="640", backgroundColor="#FFD9C6")]
    [Frame(factoryClass="Preloader")]

    public class Main extends FlxGame
    {
        public function Main()
        {
            super(320, 320, PlayState, 2);
        }
    }
}
