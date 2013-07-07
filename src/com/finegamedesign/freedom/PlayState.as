package com.finegamedesign.freedom
{
    import flash.display.Bitmap;
    import flash.geom.Rectangle;
    import flash.utils.Dictionary;

    import org.flixel.*;
   
    public class PlayState extends FlxState
    {
        private static var first:Boolean = true;
        [Embed(source="../../../../gfx/map.png")]
        private static const Map:Class;
        [Embed(source="../../../../gfx/tiles.png")]
        private static const Tiles:Class;
        [Embed(source="../../../../gfx/palette.png")]
        private static const Palette:Class;
        private static var palette:Vector.<uint>;
        private static var textColor:uint;

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

        /**
         * Restart. Simeon may expect to pickup pace quicker.
         */
        private function createScores():void
        {
            if (null == FlxG.scores || FlxG.scores.length <= 0) {
                FlxG.scores = [0];
                FlxG.flashFramerate = 60;
                var paletteImage:Bitmap = new Palette();
                palette = paletteImage.bitmapData.getVector(
                    new Rectangle(0, 0, paletteImage.width, paletteImage.height));
                textColor = palette[0];
                FlxG.bgColor = palette[1];
                // FlxG.visualDebug = true;
                FlxG.worldBounds = new FlxRect(0, 0, 1280, 960);
            }
            else {
                FlxG.scores.push(FlxG.score);
            }
            if (9 <= FlxG.score) {
                FlxG.score = 2;
            }
            else {
                FlxG.score = 0;
            }
        }

        /**
         * 13/7/6 Simeon may expect night phase does not completely fill the screen.
         */
        override public function create():void
        {
            super.create();
            createScores();
            pickupInit();
            // loadMap();
            tweenBgColor(palette[4], 1.0);
            player = new Player(FlxG.width / 2, FlxG.height / 2);
            player.y -= player.height / 2;
            player.x -= player.width / 2;
            add(player);
            enemies = new FlxGroup();
            for (var concurrentBullet:int = 0; concurrentBullet < 96; concurrentBullet++) {
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
                      : "PRESS ARROW KEYS TO PICKUP SURVIVORS");
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
            if ("lose" != state) {
                updateInput();
            }
            if ("start" == state && (player.velocity.x != 0.0 || player.velocity.y != 0.0))
            {
                state = "pickup";
                instructionText.text = "PRESS ARROW KEYS TO RESCUE SURVIVORS";
            }
            if ("play" == state) {
                FlxG.collide(player, map);
                maySpawnBullet();
                updateBulletSpeed();
                updatePickup();
                FlxG.overlap(player, enemies, collide);
            }
            FlxG.overlap(player, pickups, scoreUp);
            interpolateBgColor();
            updateHud();
            super.update();
        }

        // bullet

        private var lastExcludedRow:Number = 0.5;
        private var lastExcludedColumn:Number = 0.5;

        /**
         * 13/7/6 Simeon may expect density increases rapidly.
         */
        private function maySpawnBullet():void
        {
            lifeTime += FlxG.elapsed;
            if (spawnTime + 4 < lifeTime) {
                var startSide:int = (lifeTime / 4) % 4;
                var count:Number = Math.pow(FlxG.score * 10, 0.5);
                for (var b:Number = 0; b < count; b += speedFactor) {
                    bullet = spawnBullet((b + startSide) % 4, lastExcludedRow, lastExcludedColumn);
                    countPickup(bullet, ((b + startSide) % 2) == 0);
                }
                spawnTime = lifeTime;
                lastExcludedRow = randomWalk(lastExcludedRow, cellWidth / FlxG.height);
                lastExcludedColumn = randomWalk(lastExcludedColumn, cellWidth / FlxG.width);
                FlxG.log("spawn " + count.toFixed(2) + " ex " + lastExcludedRow.toFixed(2) + "," + lastExcludedColumn.toFixed(2));
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
         * Two gaps always exists that follows a random walk.
         * Example: 13/7/6 Invincible, speed x8. Play 400 seconds. Speed x1. 
         * Play 120 seconds.  Expect no solid wall.  Repeat twice.
         * Translucent.  Play 40 seconds.  Do not see two on top of each other.
         */
        private function spawnBullet(side:int, excludedRow:Number, excludedColumn:Number):Bullet
        {
            bullet = Bullet(enemies.getFirstAvailable());
            if (bullet == null)
            {
                return null;
            }
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
            var other:Bullet;
            for (var e:int = 0; e < enemies.members.length; e++) {
                other = enemies.members[e];
                if (null != other && other != bullet 
                        && other.x == bullet.x && other.y == bullet.y) {
                    return null;
                }
            }
            bullet.revive();
            bullet.solid = false;
            return bullet;
        }

        /**
         * Random position, except not at excluded or half away from excluded.
         * Excluded never at edge, because cannot see what may emerge from offscreen.
         * Expects width greater than 5 cellWidth.
         */
        private function drawCard(deck:Array, cellWidth:int, width:int, excluded:Number):int
        {
            var excludedPosition:int = excluded * (width - 3 * cellWidth) + cellWidth;
            excludedPosition = int(excludedPosition / cellWidth) * cellWidth;
            var excludedPosition1:int = ((0.5 + excluded) - Math.floor(0.5 + excluded)) 
                * (width - 3 * cellWidth) + cellWidth;
            excludedPosition1 = int(excludedPosition / cellWidth) * cellWidth;
            if (deck.length <= 2) {
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
                deck.unshift(excludedPosition);
            }
            if (draw == excludedPosition) {
                throw new Error("Expected not excluded " + excluded + " deck " + deck);
            }
            // FlxG.log("drawCard: " + draw.toString() + " ex " + excludedPosition);
            return draw;
        }

        /**
         * 13/7/7 Simeon may expect to read when more drones appear.
         */
        private function updateBulletSpeed():void
        {
            var inCycle:int = lifeTime % 50;
            if (inCycle < 10) {
                if (50 <= lifeTime && "play" == state) {
                    instructionText.text = "";
                }
                tweenBgColor(palette[2], 1.0);
            }
            else if (inCycle < 20) {
                if (lifeTime < 50) {
                    instructionText.text = "NIGHT IS SLOW YET DENSE!";
                }
                tweenBgColor(palette[3], 0.5);
            }
            else if (inCycle < 40) {
                if (lifeTime < 50) {
                    instructionText.text = "TWILIGHT IS MEDIUM";
                }
                tweenBgColor(palette[2], 1.0);
            }
            else if (inCycle < 50) {
                if (lifeTime < 50) {
                    instructionText.text = "DAYTIME IS EMPTY YET FAST!";
                }
                tweenBgColor(palette[1], 2.0);
            }
        }

        private var toColor:uint;
        private var fromColor:uint;
        private var fromSpeed:Number;
        private var toSpeed:Number;
        private var progressTime:Number;
        private var toTime:Number;

        private function tweenBgColor(newColor:uint, speed:Number, seconds:Number=2.0):void
        {
            // FlxG.bgColor = newColor;
            if (FlxG.bgColor == newColor) {
                progressTime = seconds;
                toTime = 0.0;
                toColor = FlxG.bgColor;
                toSpeed = speedFactor;
            }
            else if (seconds <= 0.0) {
                FlxG.bgColor = newColor;
                toTime = 0.0;
                progressTime = 0.0;
                setBulletSpeed(speed);
            }
            else if (toColor != newColor) {
                fromColor = FlxG.bgColor;
                progressTime = 0.0;
                toTime = seconds;
                toColor = newColor;
                fromSpeed = speedFactor;
                toSpeed = speed;
            }
        }

        private function interpolateBgColor():void
        {
            progressTime += FlxG.elapsed;
            if (0.0 < toTime && toTime <= progressTime) {
                FlxG.bgColor = toColor;
                toTime = 0.0;
                speedFactor = toSpeed;
                // FlxG.log("interpolated " + toColor.toString(16));
            }
            else 
            {
                var progress:Number = Math.min(1.0, progressTime / toTime);
                var fromB:int = (fromColor & 0xFF);
                var fromG:int = ((fromColor >> 8) & 0xFF);
                var fromR:int = ((fromColor >> 16) & 0xFF);
                var b:int = (toColor & 0xFF) - fromB;
                var g:int = ((toColor >> 8) & 0xFF) - fromG;
                var r:int = ((toColor >> 16) & 0xFF) - fromR;
                var progressColor:uint = 0xFF000000;
                progressColor |= (int(progress * b) + fromB);
                progressColor |= (int(progress * g) + fromG) << 8;
                progressColor |= (int(progress * r) + fromR) << 16;
                FlxG.bgColor = progressColor;
                setBulletSpeed(progress * (toSpeed - fromSpeed) + fromSpeed);
                // FlxG.log("interpolate " + progress.toFixed(2) + " to " + toColor.toString(16));
            }
        }

        private var speedFactor:Number = 1.0;

        /**
         * 13/7/6 Simeon may expect player moves at constant speed.
         */
        private function setBulletSpeed(factor:Number):void
        {
            speedFactor = factor;
            // player.speed = 2 * cellWidth * factor;
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

        // pickup

        private var rowSincePickup:Dictionary;
        private var columnSincePickup:Dictionary;
        private var pickups:FlxGroup;
        private var pickup:Pickup;

        /**
         * 13/7/6 Two pickups near each other. Do not read instructions. Confused.
         */
        private function pickupInit():void
        {
            rowSincePickup = new Dictionary();
            columnSincePickup = new Dictionary();
            pickups = new FlxGroup();
            for (var concurrentPickup:int = 0; concurrentPickup < 16; concurrentPickup++) {
                pickup = new Pickup();
                if (concurrentPickup < 4) {
                    pickup.x = FlxG.width * (0.25 + 0.5 * (concurrentPickup % 2));
                    pickup.y = FlxG.height * (0.25 + 0.5 * int(concurrentPickup / 2));
                    pickup.revive();
                }
                /*-
                else if (concurrentPickup == 4) {
                    pickup.x = FlxG.width * 0.625;
                    pickup.y = FlxG.height * 0.375;
                    pickup.revive();
                }
                -*/
                else {
                    pickup.exists = false;
                }
                pickups.add(pickup);
                
            }
            add(pickups);
        }
        
        /**
         * Do not spawn at edge.  Cannot see what emerges from off screen.
         */
        private function countPickup(bullet:Bullet, horizontal:Boolean):void
        {
            if (null == bullet) {
                return;
            }
            var sincePickup:Dictionary;
            var value:int;
            if (horizontal) {
                sincePickup = rowSincePickup;
                value = bullet.y;
                if (value < cellWidth || FlxG.width - cellWidth <= value) {
                    return;
                }
            }
            else {
                sincePickup = columnSincePickup;
                value = bullet.x;
                if (value < cellWidth || FlxG.height - cellWidth <= value) {
                    return;
                }
            }
            if (!(value in sincePickup)) {
                sincePickup[value] = 0;
            }
            sincePickup[value] ++;
        }

        private function updatePickup():void
        {
            maySpawnPickup();
            mayKillPickup();
        }

        private function maySpawnPickup():void
        {
            for (var y:* in rowSincePickup) {
                for (var x:* in columnSincePickup) {
                    if (Math.abs(player.x - columnSincePickup[x]) < cellWidth
                     && Math.abs(player.y - rowSincePickup[y]) < cellWidth) {
                        continue;
                    }
                    if (8 <= rowSincePickup[y] + columnSincePickup[x]) {
                        pickup = Pickup(pickups.getFirstAvailable());
                        if (null == pickup) {
                            pickup = pickups.members[int(FlxG.random() * pickups.members.length)];
                        }
                        pickup.x = int(x + cellWidth / 2);
                        pickup.y = int(y + cellWidth / 2);
                        pickup.duration = 16.0;
                        pickup.revive();
                        rowSincePickup[y] = 0;
                        columnSincePickup[x] = 0;
                    }
                }
            }
        }

        private function mayKillPickup():void
        {
            for (var p:int = 0; p < pickups.members.length; p++) {
                pickup = pickups.members[p];
                if (pickup.alive) {
                    pickup.duration -= FlxG.elapsed;
                    if (pickup.duration <= 0.0) {
                        pickup.kill();
                        pickup.exists = false;
                    }
                    else if (pickup.duration <= 4.0) {
                        if (!pickup.flickering) {
                            pickup.flicker(4.0);
                        }
                    }
                }
            }
        }

        private function scoreUp(me:FlxObject, you:FlxObject):void
        {
            var player:Player = Player(me);
            var picked:Pickup = Pickup(you);
            picked.kill();
            if (FlxG.score == 0) {
                instructionText.text = "EACH RESCUE SCORES A POINT -->";
            }
            else if (FlxG.score == 1) {
                instructionText.text = "BUT EACH RESCUE ALSO SUMMONS MORE DRONES!";
            }
            else if (FlxG.score == 2) {
                instructionText.text = "DODGE DRONES!";
                lifeTime = 0.0;
                spawnTime = 0.0;
                FlxG.playMusic(Sounds.music);
                state = "play";
            }
            FlxG.score += 1;
            FlxG.play(Sounds.pickup);
        }

        // end pickup

        private function updateHud():void
        {
            // FlxG.score = int(lifeTime);
            scoreText.text = FlxG.score.toString();
        }

        private function collide(me:FlxObject, you:FlxObject):void
        {
            var enemy:FlxSprite = FlxSprite(you);
            var player:Player = Player(me);
            var my:FlxPoint = new FlxPoint(player.x, player.y);
            var yours:FlxPoint = new FlxPoint(you.x, you.y);
            if (0.7 * enemy.frameWidth < FlxU.getDistance(my, yours)) {
                return;
            }
            player.hurt(1);
            enemy.solid = false;
            if (1 <= player.health) {
                return;
            }
            FlxG.timeScale = 1.0;
            //+ player.play("collide");
            player.velocity.x = 0.0;
            player.velocity.y = 0.0;
            FlxG.play(Sounds.explosion);
            FlxG.camera.shake(0.05, 0.5, null, false, FlxCamera.SHAKE_HORIZONTAL_ONLY);
            instructionText.text = "A DRONE SHOT YOU";
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
                instructionText.text = "PRESS ARROW KEYS TO RESCUE SURVIVORS";
                FlxG.play(Sounds.start);
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
                    player.health = player.health < 2 ? int.MAX_VALUE : 1;
                    player.alpha = 0.5 + (player.health < 2 ? 0.5 : 0.0);
                }
            }
        }
    }
}
