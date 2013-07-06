package com.finegamedesign.freedomisboring
{
    import org.flixel.*;

    public class Road extends FlxSprite
    {
        [Embed(source="../../../../gfx/road.png")] internal static var Img:Class;

        public function Road(X:int = 0, Y:int = 0, ImgClass:Class = null) 
        {
            super(X, Y, Img);
            solid = false;
        }
        
        override public function update():void 
        {
            if (x < -width) {
                x += FlxG.width + 2 * int(width - 3);
            }
            super.update();
        }
    }
}
