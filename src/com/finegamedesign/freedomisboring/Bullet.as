package com.finegamedesign.freedomisboring
{
    import org.flixel.*;

    public class Bullet extends FlxSprite
    {
        [Embed(source="../../../../gfx/bullet.png")] internal static var Img:Class;
        internal var speed:Number = 20;
                                    // 40;
                                    // 80;
                                    // 160;  // too fast?

        public function Bullet(X:int = 0, Y:int = 0, ImgClass:Class = null) 
        {

            super(X, Y, Img);
            loadGraphic(Img, true, false, 16, 16, true);
            width = 0.5 * frameWidth;
            height = 0.5 * frameWidth;
            offset.x = width / 2;
            offset.y = height / 2;
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
