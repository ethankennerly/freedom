package com.finegamedesign.freedomisboring
{
    import org.flixel.*;
   
    public class PlayState extends FlxState
    {
        private static var first:Boolean = true;
        [Embed(source="../../../../gfx/map.png")]
        private static const Map:Class;
        [Embed(source="../../../../gfx/tiles.png")]
        private static const Tiles:Class;

        private var textColor:uint = 0xFFFFFF;
        private var state:String;
        private var instructionText:FlxText;
        private var scoreText:FlxText;
        private var player:Player;
        private var lifeTime:Number;
        private var spawnTime:Number;
        private var enemies:FlxGroup;
        private var cellWidth:int;
        private var bullet:Bullet;
        private var map:FlxTilemap;
        // TODO
        private var gibs:FlxEmitter;

        private function createScores():void
        {
            if (null == FlxG.scores || FlxG.scores.length <= 0) {
                FlxG.scores = [0];
                FlxG.score = 0;
                FlxG.flashFramerate = 60;
                // FlxG.visualDebug = true;
                FlxG.worldBounds = new FlxRect(0, 0, 1280, 960);
            }
            else {
                FlxG.scores.push(FlxG.score);
            }
        }

        override public function create():void
        {
            super.create();
            createScores();
            // loadMap();
            FlxG.bgColor = 0xFFFFD9C6;
            player = new Player(FlxG.width / 2, FlxG.height / 2);
            player.y -= player.height / 2;
            player.x -= player.width / 2;
            add(player);
            enemies = new FlxGroup();
            for (var concurrentBullet:int = 0; concurrentBullet < 128; concurrentBullet++) {
                bullet = new Bullet();
                bullet.exists = false;
                enemies.add(bullet);
            }
            cellWidth = bullet.frameWidth;
            add(enemies);
            addHud();
            state = "start";
            first = false;
        }

        /**
         * Annoyed me.
         */
        private function loadMap():void
        {
            map = new FlxTilemap();
            map.loadMap(FlxTilemap.imageToCSV(Map), Tiles);
            add(map);
        }

        private function addHud():void
        {
            instructionText = new FlxText(0, 0, FlxG.width, 
                first ? "CLICK HERE"
                      : "PRESS ARROW KEYS TO DODGE BOXES");
            instructionText.color = textColor;
            instructionText.scrollFactor.x = 0.0;
            instructionText.scrollFactor.y = 0.0;
            instructionText.alignment = "center";
            add(instructionText);
            scoreText = new FlxText(FlxG.width - 30, 0, 30, "0");
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
                instructionText.text = "PRESS ARROW KEYS TO DODGE BOXES";
                FlxG.playMusic(Sounds.music);
            }
            if ("play" == state) {
                FlxG.collide(player, map);
                maySpawnBullet();
                updateBulletSpeed();
                FlxG.overlap(player, enemies, collide);
                updateHud();
            }
            if (60 <= lifeTime) {
                instructionText.text = "";
            }
            super.update();
        }

        // bullet

        private var lastExcludedRow:Number = 0.5;
        private var lastExcludedColumn:Number = 0.5;

        private function maySpawnBullet():void
        {
            if (spawnTime + 4 < lifeTime) {
                var startSide:int = (lifeTime / 4) % 4; 
                for (var b:Number = 0; b < Math.pow(lifeTime, 0.67); b += speedFactor) {
                    spawnBullet((b + startSide) % 4, lastExcludedRow, lastExcludedColumn);
                }
                spawnTime = lifeTime;
                lastExcludedRow = randomWalk(lastExcludedRow, cellWidth / FlxG.height);
                lastExcludedColumn = randomWalk(lastExcludedColumn, cellWidth / FlxG.width);
            }
        }

        /**
         * @param   previous    Expects between [0..1]
         * @return between [0..1]
         */
        private function randomWalk(previous:Number, maxDrift:Number):Number
        {
            var next:Number = previous + 2 * maxDrift * FlxG.random() - maxDrift;
            if (1 < next) {
                next = 1 - next;
            }
            if (next < 0) {
                next = -next;
            }
            return next;
        }

        private var rowDeck:Array = [];
        private var columnDeck:Array = [];

        /**
         * Gap always exists that follows a random walk.
         * Example: 13/7/6 Invincible, speed x8. Play 400 seconds. Speed x1. 
         * Play 120 seconds.  Expect no solid wall.  Repeat twice.
         */
        private function spawnBullet(side:int, excludedRow:Number, excludedColumn:Number):void
        {
            bullet = Bullet(enemies.getFirstAvailable());
            if (bullet == null)
            {
                return;
            }
            bullet.revive();
            bullet.solid = false;
            if (0 == side % 2) {
                bullet.y = drawCard(rowDeck, cellWidth, FlxG.height, excludedRow);
                bullet.x = FlxG.width / 2 + (1 - side) * (FlxG.width / 2 + cellWidth);
                bullet.velocity.x = (side - 1) * bullet.speed;
                bullet.velocity.y = 0;
            }
            else {
                bullet.x = drawCard(columnDeck, cellWidth, FlxG.width, excludedColumn);
                bullet.y = FlxG.height / 2 + (2 - side) * (FlxG.height / 2 + cellWidth);
                bullet.velocity.y = (side - 2) * bullet.speed;
                bullet.velocity.x = 0;
            }
        }

        /**
         * Random position, except not at excluded.
         * Expects width greater than 2 cellWidth.
         */
        private function drawCard(deck:Array, cellWidth:int, width:int, excluded:Number):int
        {
            var excludedPosition:int = excluded * (width - cellWidth);
            excludedPosition = int(excludedPosition / cellWidth) * cellWidth;
            if (deck.length <= 0 || (deck.length == 1 && deck[0] == excludedPosition)) {
                deck = [];
                for (var position:int = 0; position <= width - cellWidth / 2; position += cellWidth) {
                    deck.push(position);
                }
                for (var i:int = deck.length - 1; 1 <= i; i--) {
                    var r:int = FlxG.random() * (i + 1);
                    if (r != i) {
                        var tmp:int = deck[i];
                        deck[i] = deck[r];
                        deck[r] = tmp;
                    }
                }
            }
            var draw:int = deck.pop();
            if (draw == excludedPosition) {
                draw = deck.pop();
                deck.push(excludedPosition);
            }
            if (draw == excludedPosition) {
                throw new Error("Expected not excluded " + excluded + " deck " + deck);
            }
            FlxG.log("drawCard: " + draw.toString() + " ex " + excludedPosition);
            return draw;
        }

        private function updateBulletSpeed():void
        {
            var inCycle:int = lifeTime % 50;
            if (inCycle < 10) {
                FlxG.bgColor = 0xFFFFD9C6;
                setBulletSpeed(1.0);
            }
            else if (inCycle < 20) {
                FlxG.bgColor = 0xFFFDFF97;
                setBulletSpeed(2.0);
            }
            else if (inCycle < 30) {
                FlxG.bgColor = 0xFFFFD9C6;
                setBulletSpeed(1.0);
            }
            else if (inCycle < 40) {
                FlxG.bgColor = 0xFFEAD2FF;
                setBulletSpeed(0.5);
            }
        }

        private var speedFactor:Number = 1.0;

        private function setBulletSpeed(factor:Number):void
        {
            speedFactor = factor;
            player.speed = 2 * cellWidth * factor;
            for (var e:int = 0; e < enemies.members.length; e++) {
                bullet = enemies.members[e];
                if (null == bullet) {
                    continue;
                }
                bullet.speed = cellWidth * factor;
                if (bullet.velocity.x < 0) {
                    bullet.velocity.x = -bullet.speed;
                }
                else if (0 < bullet.velocity.x) {
                    bullet.velocity.x = bullet.speed;
                }
                if (bullet.velocity.y < 0) {
                    bullet.velocity.y = -bullet.speed;
                }
                else if (0 < bullet.velocity.y) {
                    bullet.velocity.y = bullet.speed;
                }
            }
        }

        // end bullet

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
            //+ player.play("collide");
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
            setBulletSpeed(0.25);
            FlxG.playMusic(Sounds.music, 0.0);
            FlxG.resetState();
        }

        /**
         * Press arrow key to move.
         * To make it harder, play 2x speed: press Shift+2.  
         * To make it normal again, play 1x speed: press Shift+1.  
         */ 
        private function updateInput():void
        {
            if (FlxG.mouse.justPressed()) {
                instructionText.text = "PRESS ARROW KEYS TO DODGE BOXES";
            }
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
            player.x = Math.max(player.frameWidth / 2, Math.min(FlxG.width - player.frameWidth, player.x));
            player.y = Math.max(player.frameHeight / 2, Math.min(FlxG.height - player.frameHeight, player.y));
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
