package com.finegamedesign.freedom
{
    import org.flixel.*;

    public class Pickup extends FlxSprite
    {
        [Embed(source="../../../../gfx/pickup.png")] internal static var Img:Class;

        internal var duration:Number;

        public function Pickup(X:int = 0, Y:int = 0, ImgClass:Class = null) 
        {
            super(X, Y, Img);
            width = 1.5 * frameWidth;
            height = 1.5 * frameHeight;
            offset.x = 0.5 * (frameWidth - width);
            offset.y = 0.5 * (frameHeight - height);
        }
    }
}
