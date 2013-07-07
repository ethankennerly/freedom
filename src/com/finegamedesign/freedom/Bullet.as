package com.finegamedesign.freedom
{
    import org.flixel.*;

    public class Bullet extends FlxSprite
    {
        [Embed(source="../../../../gfx/bullet.png")] internal static var Img:Class;
        internal var speed:Number;

        public function Bullet(X:int = 0, Y:int = 0, ImgClass:Class = null) 
        {
            super(X, Y, Img);
            // loadGraphic(Img, true, false, 16, 16, true);
            speed = frameWidth;
            width = 0.9 * frameWidth;
            height = 0.9 * frameHeight;
            offset.x = 0.5 * (frameWidth - width);
            offset.y = 0.5 * (frameHeight - height);
        }
        
        override public function update():void 
        {
            if (onScreen() && !solid)
            {
                solid = true;
                // FlxG.play(Sounds.bullet);
            }
            else if (solid && alive && !onScreen()) {
                kill();
            }
            super.update();
        }
    }
}
