package com.finegamedesign.freedomisboring
{
    import org.flixel.*;

    public class Player extends FlxSprite
    {
        [Embed(source="../../../../gfx/car.png")] internal static var Img:Class;

        public function Player(X:int = 0, Y:int = 0, ImgClass:Class = null) 
        {
            super(X, Y, Img);
            width *= 0.5;
            height *= 0.5;
            loadGraphic(Img, true, false, 129, 46, true);
            addAnimation("left", [0], 30, true);
            addAnimation("right", [1], 30, true);
            addAnimation("collide", [2], 30, true);
            addAnimation("idle", [3, 4, 5, 6], 30, true);
            play("idle");
        }
    }
}
