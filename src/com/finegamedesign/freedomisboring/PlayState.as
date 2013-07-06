package com.finegamedesign.freedomisboring
{
    import flash.utils.Dictionary;
    import org.flixel.*;
   
    public class PlayState extends FlxState
    {
        private var textColor:uint = 0xFFFFFF;
        private var state:String;
        private var instructionText:FlxText;
        private var scoreText:FlxText;
        private var player:Player;
        private var lifeTime:Number;
        private var spawnTime:Number;
        private var enemies:FlxGroup;
        private var gibs:FlxEmitter;
        private var bullet:Bullet;

        private function createScores():void
        {
            FlxG.stage.frameRate = 60;
            FlxG.bgColor = 0xFFFFD9C6;
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
            FlxG.worldBounds = new FlxRect(0, 0, 1280, 960);
            FlxG.stage.frameRate = 60;
            player = new Player(FlxG.width / 2, FlxG.height / 2);
            player.y -= player.height / 2;
            player.x -= player.width / 2;
            add(player);
            enemies = new FlxGroup();
            for (var concurrentBullet:int = 0; concurrentBullet < 64; concurrentBullet++) {
                bullet = new Bullet();
                bullet.exists = false;
                enemies.add(bullet);
            }
            add(enemies);
            addHud();
            state = "start";
        }

        private function addHud():void
        {
            instructionText = new FlxText(0, 0, FlxG.width, 
                "PRESS ARROW KEY TO DODGE BULLETS");
            instructionText.color = textColor;
            instructionText.scrollFactor.x = 0.0;
            instructionText.scrollFactor.y = 0.0;
            instructionText.alignment = "center";
            add(instructionText);
            scoreText = new FlxText(280, 0, 40, "0");
            scoreText.color = textColor;
            scoreText.scrollFactor.x = 0.0;
            scoreText.scrollFactor.y = 0.0;
            add(scoreText);
        }

		override public function update():void 
        {
            if ("start" == state || "play" == state) {
                updateInput();
            }
            if ("start" == state && (player.velocity.x != 0.0 || player.velocity.y != 0.0))
            {
                state = "play";
                lifeTime = 0.0;
                spawnTime = 0.0;
            }
            if ("play" == state) {
                maySpawnBullet();
                FlxG.overlap(player, enemies, collide);
                updateHud();
            }
            super.update();
        }

        private function maySpawnBullet():void
        {
            if (spawnTime + 1 < lifeTime) {
                spawnBullet();
                spawnTime = lifeTime;
            }
        }

        private function spawnBullet():void
        {
            FlxG.log("spawnBullet");
            bullet = Bullet(enemies.getFirstAvailable());
            bullet.revive();
            bullet.y = FlxG.height / 2 - bullet.height / 2;
            bullet.x = FlxG.width + bullet.width;
            bullet.velocity.x = -bullet.speed;
            bullet.solid = false;
            add(bullet);
        }

        private function updateHud():void
        {
            lifeTime += FlxG.elapsed;
            FlxG.score = int(lifeTime);
            scoreText.text = FlxG.score.toString();
        }

        private function collide(me:FlxObject, you:FlxObject):void
        {
            var player:Player = Player(me);
            var enemy:FlxSprite = FlxSprite(you);
            enemy.solid = false;
            FlxG.timeScale = 1.0;
            player.play("collide");
            player.velocity.x = 0.0;
            player.velocity.y = 0.0;
            FlxG.play(Sounds.explosion);
            FlxG.camera.shake(0.05, 0.5, null, false, FlxCamera.SHAKE_HORIZONTAL_ONLY);
            instructionText.text = "YOU WERE HIT";
            FlxG.fade(0xFF000000, 4.0, lose);
            state = "lose";
        }

        private function lose():void
        {
            FlxG.switchState(new PlayState());
        }

        /**
         * Press arrow key to move.
         * To make it harder, play 2x speed: press Shift+2.  
         * To make it normal again, play 1x speed: press Shift+1.  
         */ 
        private function updateInput():void
        {
            mayMovePlayer();
            mayCheat();
        }

        private function mayMovePlayer():void
        {
            player.velocity.x = 0;
            player.velocity.y = 0;
            if (FlxG.keys.pressed("LEFT") || FlxG.keys.pressed("A")) {
                player.velocity.x -= player.speed;
            }
            if (FlxG.keys.pressed("RIGHT") || FlxG.keys.pressed("D")) {
                player.velocity.x += player.speed;
            }
            if (FlxG.keys.pressed("UP") || FlxG.keys.pressed("W")) {
                player.velocity.y -= player.speed;
            }
            if (FlxG.keys.pressed("DOWN") || FlxG.keys.pressed("S")) {
                player.velocity.y += player.speed;
            }
            player.x = Math.max(player.width / 2, Math.min(FlxG.width - player.width, player.x));
            player.y = Math.max(player.height / 2, Math.min(FlxG.height - player.height, player.y));
        }

        private function mayCheat():void
        {
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
