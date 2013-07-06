package com.finegamedesign.freedomisboring
{
    import org.flixel.*;

    public class Bullet extends FlxSprite
    {
        [Embed(source="../../../../gfx/car.png")] internal static var Img:Class;
        internal var sound:Boolean;

        public function Bullet(X:int = 0, Y:int = 0, ImgClass:Class = null) 
        {

            super(X, Y, Img);
            loadGraphic(Img, true, false, 628 / 4, 81, true);
            width = 0.25 * frameWidth;
            // addAnimation("collide", [0], 30, true);
            // addAnimation("idle", [1], 30, true);
            // play("idle");
        }
        
        override public function update():void 
        {
            if (x < -frameWidth) {
                sound = false;
                kill();
            }
            else if (solid && alive && x < 640 && sound) {
                sound = false;
                FlxG.play(Sounds.bullet);
            }
            super.update();
        }
    }
}
