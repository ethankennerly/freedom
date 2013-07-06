package com.finegamedesign.freedomisboring
{
    import org.flixel.*;

    public class Bullet extends FlxSprite
    {
        [Embed(source="../../../../gfx/car.png")] internal static var Img:Class;
        internal var speed:Number = 160;

        public function Bullet(X:int = 0, Y:int = 0, ImgClass:Class = null) 
        {

            super(X, Y, Img);
            loadGraphic(Img, true, false, 628 / 4, 81, true);
            width = 0.25 * frameWidth;
        }
        
        override public function update():void 
        {
            if (x < -frameWidth) {
                kill();
            }
            else if (solid && alive && x < FlxG.width) {
                FlxG.play(Sounds.bullet);
            }
            super.update();
        }
    }
}
