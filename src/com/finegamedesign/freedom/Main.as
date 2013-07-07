package com.finegamedesign.freedom
{
    import org.flixel.*;
    [SWF(width="600", height="600", backgroundColor="#FFD9C6")]
    [Frame(factoryClass="Preloader")]

    public class Main extends FlxGame
    {
        public function Main()
        {
            super(300, 300, PlayState, 2);
        }
    }
}
