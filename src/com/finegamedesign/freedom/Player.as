package com.finegamedesign.freedom
{
    import org.flixel.*;

    public class Player extends FlxSprite
    {
        [Embed(source="../../../../gfx/player.png")] internal static var Img:Class;
        internal var speed:Number = 60;
                                    // 160;

        public function Player(X:int = 0, Y:int = 0, ImgClass:Class = null) 
        {
            super(X, Y, Img);
            width = 1.0 * frameWidth;
            height = 1.0 * frameHeight;
            offset.x = 0.5 * (frameWidth - width);
            offset.y = 0.5 * (frameHeight - height);
            // loadGraphic(Img, true, false, 16, 16, true);
            //+ addAnimation("left", [0], 30, true);
            //+ addAnimation("right", [1], 30, true);
            //+ addAnimation("collide", [2], 30, true);
            //+ addAnimation("idle", [3, 4, 5, 6], 30, true);
            //+ play("idle");
        }
    }
}
