package com.finegamedesign.freedomisboring
{
    import flash.utils.Dictionary;
    import org.flixel.*;
   
    public class PlayState extends FlxState
    {
        private var textColor:uint = 0xFFFFFF;
        private var state:String;
        private var instructionText:FlxText;
        private var waveText:FlxText;
        private var scoreText:FlxText;
        private var player:Player;
        private var enemies:FlxGroup;
        private var gibs:FlxEmitter;
        private var driftDistance:int = 60;
        private var driftTime:Number = 0.25;
        private var middleY:int = 120;
        private var targetY:int;
        private var direction:int;
        private var signDirection:int;
        private var bullet:Bullet;
        private var baseVelocityX:int = -160;
        private var velocityX:int;
        private var road:Road;
        private var roads:FlxGroup;
        private var baseSpawnTime:Number = 15.0;
        private var progressTimer:FlxTimer;
        private var baseProgressTime:Number = 1.0;
        private var progressTime:Number;
        private var distance:int;
        private var signDistance:int;
        private var obstacles:FlxGroup;
        private var signs:FlxGroup;
        private var sign:FlxSprite;
        private var levelDistance:int = 256;

        private function createScores():void
        {
            FlxG.stage.frameRate = 60;
            FlxG.bgColor = 0xFFFFFF00;
            if (null == FlxG.scores || FlxG.scores.length <= 0) {
                FlxG.scores = [0];
                FlxG.score = 0;
                FlxG.playMusic(Sounds.music);
            }
            else {
                FlxG.scores.push(FlxG.score);
            }
        }

        override public function create():void
        {
            super.create();
            createScores();
            // FlxG.visualDebug = true;
            FlxG.worldBounds = new FlxRect(0, 100, 320, 380);
            FlxG.stage.frameRate = 60;
            enemies = new FlxGroup();
            for (var concurrentBullet:int = 0; concurrentBullet < 4; concurrentBullet++) {
                bullet = new Bullet();
                bullet.exists = false;
                enemies.add(bullet);
            }
            progressTimer = new FlxTimer();
            direction = 1;
            player = new Player(40, middleY + direction * driftDistance);
            player.y -= player.height / 2;
            targetY = middleY + direction * driftDistance;
            add(player);
            addHud();
            if (FlxG.score < levelDistance * 2) {
                FlxG.score = Math.max(0, FlxG.score - levelDistance / 3);
                distance = FlxG.score;
            }
            else {
                distance = levelDistance;
                FlxG.score = levelDistance;
                FlxG.timeScale = 2.0;
                FlxG.log("Double speed");
            }
            state = "play";
        }

        /**
         * Player drifts to other side.
         */
        private function switchLane():void
        {
            direction = -direction;
            var directions:Dictionary = new Dictionary();
            directions[-1] = "left";
            directions[1] = "right";
            player.play(directions[direction]);
            targetY = middleY + direction * driftDistance - player.height / 2;
            player.velocity.y = 2 * direction * driftDistance * (1.0 / driftTime);
            FlxG.play(Sounds.turn);
            // FlxG.log("switchLane: at " + player.velocity.y + " to " + targetY);
        }

        private function spawnBullet(warningFrame:int):void
        {
            bullet = Bullet(enemies.getFirstAvailable());
            placeInRoad(bullet, signDirection, 1.5, 1.0);
            bullet.frame = warningFrame;
            bullet.sound = true;
        }
            
        private function placeInRoad(bullet:FlxSprite, signDirection:int, speed:Number, collisionWidthRatio:Number):void
        {
            bullet.revive();
            bullet.y = middleY + -signDirection * driftDistance - bullet.height / 2;
            bullet.x = -speed * baseSpawnTime * baseVelocityX;
            bullet.velocity.x = speed * velocityX;
            bullet.width = collisionWidthRatio * bullet.frameWidth;
            bullet.offset.x = 0.5 * (1.0 - collisionWidthRatio) * bullet.frameWidth;
            add(bullet);
        }

        private function addHud():void
        {
            instructionText = new FlxText(0, 0, FlxG.width, 
                "CLICK OR PRESS SPACEBAR SWITCH SIDES");
            instructionText.color = textColor;
            instructionText.scrollFactor.x = 0.0;
            instructionText.scrollFactor.y = 0.0;
            instructionText.alignment = "center";
            add(instructionText);
            waveText = new FlxText(0, 0, 100, "");
            waveText.color = textColor;
            waveText.scrollFactor.x = 0.0;
            waveText.scrollFactor.y = 0.0;
            add(waveText);
            scoreText = new FlxText(FlxG.width - 50, 0, 100, " of " + levelDistance * 2);
            scoreText.color = textColor;
            scoreText.scrollFactor.x = 0.0;
            scoreText.scrollFactor.y = 0.0;
            add(scoreText);
            scoreText = new FlxText(FlxG.width - 120, 0, 100, "");
            scoreText.color = textColor;
            scoreText.scrollFactor.x = 0.0;
            scoreText.scrollFactor.y = 0.0;
            add(scoreText);
        }

		override public function update():void 
        {
            updateInput();
            enemies.update();
            FlxG.overlap(player, enemies, collide);
            FlxG.overlap(player, obstacles, collide);
            updateHud();
            super.update();
        }

        private function updateHud():void
        {
            if ("play" == state) {
                scoreText.text = "DISTANCE " + FlxG.score;
            }
        }

        private function lose():void
        {
            FlxG.switchState(new PlayState());
        }

        private function win():void
        {
            setVelocityX(0);
            FlxG.switchState(new PlayState());
        }

        private function stop():void
        {
            setVelocityX(0);
            progressTimer.stop();
        }
        
        private function collide(me:FlxObject, you:FlxObject):void
        {
            var player:FlxSprite = FlxSprite(me);
            var enemy:FlxSprite = FlxSprite(you);
            if ("play" == state) {
                enemy.solid = false;
                FlxG.timeScale = 1.0;
                Player(player).play("collide");
                enemy.frame--;
                if (player.y == enemy.y || player.x + player.width / 2 < enemy.x) {
                    enemy.x = player.x + player.width - enemy.offset.x;
                }
                var showSigns:Boolean = false;
                if (showSigns) {
                    if (enemy is Bullet) {
                        bullet = Bullet(enemies.getFirstAvailable());
                        bullet.frame = enemy.frame - 1;
                        bullet.reset(enemy.x + enemy.width, middleY + driftDistance - bullet.height / 2);
                        bullet = Bullet(enemies.getFirstAvailable());
                        bullet.frame = enemy.frame - 2;
                        bullet.reset(enemy.x + enemy.width, middleY - driftDistance - bullet.height / 2);
                    }
                }
                FlxG.play(Sounds.explosion);
                FlxG.camera.shake(0.05, 0.5, null, false, FlxCamera.SHAKE_HORIZONTAL_ONLY);
                stop();
                instructionText.text = "YOU CRASHED";
                FlxG.fade(0xFF000000, 4.0, lose);
                state = "lose";
            }
        }

        private function fuelUp():void
        {
            FlxG.timeScale = 1.0;
            player.solid = false;
            FlxG.score += 1;
            instructionText.text = "YOU MADE IT!  FUEL UP!";
            state = "win";
            FlxG.fade(0xFFFFFFFF, 3.0, win);
        }
        
        private function setVelocityX(v:int):void
        {
            velocityX = v;
            for each (bullet in enemies.members) {
                bullet.velocity.x = 1.5 * v;
            }
            progressTime = baseProgressTime * baseVelocityX / Math.min( -0.0625, v);
            // FlxG.log("setVelocityX: progress " + progressTime);
        }
        
        /**
         * Press SPACE, or click mouse.
         * To make it harder, play 2x speed: press Shift+2.  
         * To make it normal again, play 1x speed: press Shift+1.  
         */ 
        private function updateInput():void
        {
            if ("play" == state) {
                if (FlxG.mouse.justPressed() || FlxG.keys.justPressed("SPACE") || FlxG.keys.justPressed("X")) {
                    switchLane();
                }
            }
            if (FlxG.keys.pressed("SHIFT")) {
                if (FlxG.keys.justPressed("ONE")) {
                    FlxG.timeScale = 1.0;
                }
                else if (FlxG.keys.justPressed("TWO")) {
                    FlxG.timeScale *= 2.0;
                }
                else if (FlxG.keys.justPressed("THREE")) {
                    FlxG.timeScale *= 0.5;
                }
                else if (FlxG.keys.justPressed("NINE")) {
                    player.solid = !player.solid;
                    player.alpha = 0.5 + (player.solid ? 0.5 : 0.0);
                }
            }
        }
    }
}
