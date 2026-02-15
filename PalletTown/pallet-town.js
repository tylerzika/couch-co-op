// Pallet Town Game Engine
class PalletTownGame {
    constructor(canvasId) {
        this.canvas = document.getElementById(canvasId);
        this.ctx = this.canvas.getContext('2d');
        // Make canvas focusable so keyboard input reliably registers
        try {
            this.canvas.tabIndex = 0;
            this.canvas.style.outline = 'none';
            this.canvas.addEventListener('click', () => { this.canvas.focus(); });
            this.canvas.addEventListener('mousedown', () => { this.canvas.focus(); });
        } catch (e) {
            // ignore in environments that don't support DOM tweaks
        }
        
        // Game state
        this.tileSize = 32;
        this.mapWidth = 30;
        this.mapHeight = 25;
        this.isInside = false; // Track whether player is inside or outside
        // Use grid movement: one tile per key press
        this.gridMovement = true;
        // Track the first key pressed to ignore simultaneous keys
        this.firstKey = null;
        // Repeat-on-hold settings (ms)
        this.repeatDelay = 300; // delay before repeating
        this.repeatInterval = 120; // interval between repeats
        this._repeatTimeout = null;
        this._repeatTimer = null;
        
        // Player
        this.player = {
            // Start player outside the house so collision doesn't lock movement
            x: 4,
            y: 12,
            width: 1,
            height: 1,
            // Increased speed for better visibility during testing
            speed: 0.4,
            direction: 'down',
            isMoving: false,
            targetX: 14,
            targetY: 12,
            animationFrame: 0
        };
        
        // Input handling
        this.keys = {};
        this.nearDoorId = null; // Track which door we're near
        this.setupInputHandlers();
        
        // Game loop
        this.lastFrameTime = 0;
        this.frameCount = 0;
        this.fps = 60;
        
        // Initialize game
        this.initializeMap();
    }
    
    setupInputHandlers() {
        // Keyboard input
        window.addEventListener('keydown', (e) => {
            const key = e.key.toLowerCase();
            // Prevent default for movement keys
            if (['arrowup', 'arrowdown', 'arrowleft', 'arrowright', 'w', 'a', 's', 'd'].includes(key)) {
                e.preventDefault();
            }

            // If this is the first keydown (avoid repeats while held), process it
            if (!this.keys[key]) {
                // If there's no first key recorded, take this as the first key
                if (this.firstKey === null) {
                    this.firstKey = key;

                    // Grid movement: move exactly one tile per key press
                    if (this.gridMovement) {
                        if (key === 'w' || key === 'arrowup') this.attemptGridMove('up');
                        else if (key === 's' || key === 'arrowdown') this.attemptGridMove('down');
                        else if (key === 'a' || key === 'arrowleft') this.attemptGridMove('left');
                        else if (key === 'd' || key === 'arrowright') this.attemptGridMove('right');
                    }

                    // Reset with R
                    if (key === 'r') {
                        this.resetPlayer();
                    }
                    // start repeat-on-hold timer
                    const dirForKey = (k) => {
                        if (k === 'w' || k === 'arrowup') return 'up';
                        if (k === 's' || k === 'arrowdown') return 'down';
                        if (k === 'a' || k === 'arrowleft') return 'left';
                        if (k === 'd' || k === 'arrowright') return 'right';
                        return null;
                    };

                    const repeatDir = dirForKey(key);
                    if (repeatDir) {
                        // set timeout to start repeating
                        this._repeatTimeout = setTimeout(() => {
                            // begin interval repeats
                            this._repeatTimer = setInterval(() => {
                                this.attemptGridMove(repeatDir);
                            }, this.repeatInterval);
                        }, this.repeatDelay);
                    }
                } else {
                    // Ignore other keys while firstKey is held
                }
            }

            this.keys[key] = true;
        });
        
        window.addEventListener('keyup', (e) => {
            const key = e.key.toLowerCase();
            this.keys[key] = false;
            // If the released key was the first key, clear it so next key becomes active
            if (this.firstKey === key) {
                this.firstKey = null;
                // clear repeat timers
                if (this._repeatTimeout) { clearTimeout(this._repeatTimeout); this._repeatTimeout = null; }
                if (this._repeatTimer) { clearInterval(this._repeatTimer); this._repeatTimer = null; }
            }
        });
        
        // Touch controls for mobile
        this.canvas.addEventListener('touchstart', (e) => {
            if (e.touches.length > 0) {
                const touch = e.touches[0];
                const rect = this.canvas.getBoundingClientRect();
                const x = touch.clientX - rect.left;
                const y = touch.clientY - rect.top;
                this.handleTouchMove(x, y);
            }
        });
    }

    attemptGridMove(dir) {
        const originalX = this.player.x;
        const originalY = this.player.y;

        let nx = originalX;
        let ny = originalY;
        if (dir === 'up') ny -= 1;
        else if (dir === 'down') ny += 1;
        else if (dir === 'left') nx -= 1;
        else if (dir === 'right') nx += 1;

        // Clamp
        nx = Math.max(0, Math.min(nx, this.mapWidth - 1));
        ny = Math.max(0, Math.min(ny, this.mapHeight - 1));

        this.player.targetX = nx;
        this.player.targetY = ny;

        // Run collision checks which may revert target to original
        this.checkCollisions();

        // Apply move
        this.player.x = this.player.targetX;
        this.player.y = this.player.targetY;
        this.player.isMoving = (this.player.x !== originalX || this.player.y !== originalY);

        // Update map interactions (doors)
        this.checkDoorInteraction();
    }
    
    checkDoorInteraction() {
        // Check if player is near a door
        let currentNearDoorId = null;
        let doorIndex = 0;
        
        for (let door of this.objects) {
            if (door.type === 'door') {
                const distance = Math.hypot(this.player.x - door.x, this.player.y - door.y);
                if (distance < 1.2) {
                    currentNearDoorId = doorIndex;
                }
            }
            doorIndex++;
        }
        
        // Only transition if entering a new door proximity (state change)
        if (currentNearDoorId !== null && this.nearDoorId === null) {
            // Entering door zone
            this.isInside = !this.isInside;
            this.updateCurrentMap();
            
            // Move player slightly away from door to prevent immediate re-entry
            if (this.isInside) {
                this.player.x = 11;
                this.player.y = 8;
            } else {
                this.player.x = 11;
                this.player.y = 5.5;
            }
            this.player.targetX = this.player.x;
            this.player.targetY = this.player.y;
        }
        
        this.nearDoorId = currentNearDoorId;
    }
    
    handleTouchMove(x, y) {
        const centerX = this.canvas.width / 2;
        const centerY = this.canvas.height / 2;
        
        const dx = x - centerX;
        const dy = y - centerY;
        
        if (Math.abs(dx) > Math.abs(dy)) {
            // Horizontal movement
            if (dx > 0) {
                this.keys['arrowright'] = true;
            } else {
                this.keys['arrowleft'] = true;
            }
        } else {
            // Vertical movement
            if (dy > 0) {
                this.keys['arrowdown'] = true;
            } else {
                this.keys['arrowup'] = true;
            }
        }
    }
    
    initializeMap() {
        // Generate both maps
        this.outsideTerrain = this.generateOutsideTerrain();
        // Start with an empty map (clear buildings/objects/npcs)
        this.outsideBuildings = [];
        this.outsideObjects = [];
        this.outsideNPCs = [];
        
        this.insideTerrain = this.generateInsideTerrain();
        this.insideBuildings = [];
        this.insideObjects = [];
        this.insideNPCs = [];
        
        // Start outside
        this.updateCurrentMap();
    }
    
    updateCurrentMap() {
        if (this.isInside) {
            this.terrain = this.insideTerrain;
            this.buildings = this.insideBuildings;
            this.objects = this.insideObjects;
            this.npcs = this.insideNPCs;
        } else {
            this.terrain = this.outsideTerrain;
            this.buildings = this.outsideBuildings;
            this.objects = this.outsideObjects;
            this.npcs = this.outsideNPCs;
        }
    }
    
    generateOutsideTerrain() {
        const terrain = [];
        for (let y = 0; y < this.mapHeight; y++) {
            const row = [];
            for (let x = 0; x < this.mapWidth; x++) {
                row.push('grass');
            }
            terrain.push(row);
        }
        return terrain;
    }
    
    generateInsideTerrain() {
        const terrain = [];
        for (let y = 0; y < this.mapHeight; y++) {
            const row = [];
            for (let x = 0; x < this.mapWidth; x++) {
                // Floor inside the house
                if (x >= 5 && x <= 15 && y >= 3 && y <= 15) {
                    row.push('floor');
                } else {
                    row.push('grass'); // Outside the visible house area
                }
            }
            terrain.push(row);
        }
        return terrain;
    }
    
    createOutsideBuildings() {
        // Single house: 14x14 tiles, roughly 2000 square feet
        // Centered roughly on the map
        return [
            { name: "House", x: 8, y: 5, width: 14, height: 14, color: '#c41e3a', roofColor: '#8b4513' }
        ];
    }
    
    createOutsideObjects() {
        return [
            // Door on north wall, center-left (roughly x:4-6 offset from house start at x:8)
            { x: 11, y: 4.5, width: 1, height: 1, type: 'door', text: "Press ENTER\nto enter" }
        ];
    }
    
    createOutsideNPCs() {
        return [];
    }
    
    createInsideObjects() {
        return [
            // Door to exit (north wall area)
            { x: 11, y: 3.5, width: 1, height: 1, type: 'door', text: "Press ENTER\nto exit" },
            
            // Furniture
            { x: 6, y: 4, width: 2, height: 1, type: 'bed', text: "Bed" },
            { x: 6, y: 6, width: 1, height: 1, type: 'table', text: "Table" },
            { x: 13, y: 6, width: 1, height: 1, type: 'chair', text: "Chair" },
            { x: 8, y: 13, width: 2, height: 1, type: 'shelf', text: "Shelf" },
        ];
    }
    
    handleInput() {
        // If using gridMovement, input is handled on keydown (one-tile moves),
        // so skip per-frame continuous movement here.
        if (this.gridMovement) return;
        const moveSpeed = this.player.speed;
        let moved = false;
        
        if (this.keys['arrowup'] || this.keys['w']) {
            this.player.targetY -= moveSpeed;
            this.player.direction = 'up';
            moved = true;
        }
        if (this.keys['arrowdown'] || this.keys['s']) {
            this.player.targetY += moveSpeed;
            this.player.direction = 'down';
            moved = true;
        }
        if (this.keys['arrowleft'] || this.keys['a']) {
            this.player.targetX -= moveSpeed;
            this.player.direction = 'left';
            moved = true;
        }
        if (this.keys['arrowright'] || this.keys['d']) {
            this.player.targetX += moveSpeed;
            this.player.direction = 'right';
            moved = true;
        }
        
        // Collision detection
        this.checkCollisions();
        
        // Update player position
        this.player.x = this.player.targetX;
        this.player.y = this.player.targetY;
        
        // Clamp to map bounds
        this.player.x = Math.max(0, Math.min(this.player.x, this.mapWidth - 1));
        this.player.y = Math.max(0, Math.min(this.player.y, this.mapHeight - 1));
        
        this.player.isMoving = moved;
    }
    
    checkCollisions() {
        const margin = 0.5;
        
        // Building collisions (outside only)
        for (let building of this.buildings) {
            if (this.player.targetX + margin < building.x + building.width &&
                this.player.targetX > building.x - margin &&
                this.player.targetY + margin < building.y + building.height &&
                this.player.targetY > building.y - margin) {
                
                // Revert to previous position
                this.player.targetX = this.player.x;
                this.player.targetY = this.player.y;
            }
        }
        
        // Object collisions (furniture and doors)
        for (let obj of this.objects) {
            if (obj.type !== 'sign' && obj.type !== 'door') {
                // Collision for furniture
                if (this.player.targetX + margin < obj.x + (obj.width || 1) &&
                    this.player.targetX > obj.x - margin &&
                    this.player.targetY + margin < obj.y + (obj.height || 1) &&
                    this.player.targetY > obj.y - margin) {
                    
                    this.player.targetX = this.player.x;
                    this.player.targetY = this.player.y;
                }
            }
        }
    }
    
    resetPlayer() {
        this.player.x = 4;
        this.player.y = 12;
        this.player.targetX = 4;
        this.player.targetY = 12;
        this.player.direction = 'down';
    }
    
    update() {
        this.handleInput();
        this.checkDoorInteraction();
        // Only animate when moving
        if (this.player.isMoving) {
            this.player.animationFrame = (this.player.animationFrame + 1) % 60;
        }
    }
    
    draw() {
        // Clear canvas
        this.ctx.fillStyle = '#87ceeb';
        this.ctx.fillRect(0, 0, this.canvas.width, this.canvas.height);
        
        // Calculate camera offset (center on player)
        const cameraX = this.player.x - (this.canvas.width / this.tileSize / 2);
        const cameraY = this.player.y - (this.canvas.height / this.tileSize / 2);
        
        // Draw terrain
        this.drawTerrain(cameraX, cameraY);
        
        // Draw objects
        this.drawObjects(cameraX, cameraY);
        
        // Draw buildings
        this.drawBuildings(cameraX, cameraY);
        
        // Draw NPCs
        this.drawNPCs(cameraX, cameraY);
        
        // Draw player
        this.drawPlayer(cameraX, cameraY);
        
        // Update FPS and coordinates
        this.updateUI();
    }
    
    drawTerrain(cameraX, cameraY) {
        // Defensive drawing: fall back to grass if terrain data missing
        for (let y = 0; y < this.mapHeight; y++) {
            for (let x = 0; x < this.mapWidth; x++) {
                const screenX = (x - cameraX) * this.tileSize;
                const screenY = (y - cameraY) * this.tileSize;

                // Only draw if on screen
                if (screenX + this.tileSize > 0 && screenX < this.canvas.width &&
                    screenY + this.tileSize > 0 && screenY < this.canvas.height) {

                    let terrain = 'grass';
                    if (this.terrain && Array.isArray(this.terrain) && this.terrain[y] && typeof this.terrain[y][x] === 'string') {
                        terrain = this.terrain[y][x];
                    }

                    if (terrain === 'grass') {
                        this.drawGrassTile(screenX, screenY);
                    } else if (terrain === 'water') {
                        this.drawWaterTile(screenX, screenY);
                    } else if (terrain === 'forest') {
                        this.drawForestTile(screenX, screenY);
                    } else if (terrain === 'floor') {
                        this.drawFloorTile(screenX, screenY);
                    } else {
                        // Unknown terrain type fallback
                        this.drawGrassTile(screenX, screenY);
                    }
                }
            }
        }
    }
    
    drawGrassTile(x, y) {
        // Light green background
        this.ctx.fillStyle = '#7cb342';
        this.ctx.fillRect(x, y, this.tileSize, this.tileSize);
        
        // Darker green grass pattern
        this.ctx.fillStyle = '#689f38';
        this.ctx.fillRect(x + 2, y + 2, this.tileSize - 4, this.tileSize - 4);
        
        // Grass details
        this.ctx.fillStyle = '#558b2f';
        this.ctx.fillRect(x + 4, y + 8, 4, 2);
        this.ctx.fillRect(x + 20, y + 16, 4, 2);
    }
    
    drawFloorTile(x, y) {
        // Wood floor
        this.ctx.fillStyle = '#d2691e';
        this.ctx.fillRect(x, y, this.tileSize, this.tileSize);
        
        // Wood grain pattern
        this.ctx.fillStyle = '#a0522d';
        this.ctx.fillRect(x + 2, y + 2, 10, 2);
        this.ctx.fillRect(x + 18, y + 10, 10, 2);
        this.ctx.fillRect(x + 6, y + 22, 10, 2);
    }
    
    drawWaterTile(x, y) {
        // Water
        this.ctx.fillStyle = '#0277bd';
        this.ctx.fillRect(x, y, this.tileSize, this.tileSize);
        
        // Wave animation
        const wavePattern = Math.sin(Date.now() / 500 + x + y) * 3;
        this.ctx.fillStyle = '#01579b';
        this.ctx.fillRect(x + 8, y + 8 + wavePattern, 16, 16);
    }
    
    drawForestTile(x, y) {
        // Dark green for forest
        this.ctx.fillStyle = '#558b2f';
        this.ctx.fillRect(x, y, this.tileSize, this.tileSize);
        
        // Tree-like pattern
        this.ctx.fillStyle = '#33691e';
        this.ctx.beginPath();
        this.ctx.moveTo(x + 16, y + 2);
        this.ctx.lineTo(x + 28, y + 16);
        this.ctx.lineTo(x + 4, y + 16);
        this.ctx.fill();
    }
    
    drawBuildings(cameraX, cameraY) {
        for (let building of this.buildings) {
            const screenX = (building.x - cameraX) * this.tileSize;
            const screenY = (building.y - cameraY) * this.tileSize;
            const width = building.width * this.tileSize;
            const height = building.height * this.tileSize;
            
            if (screenX + width > 0 && screenX < this.canvas.width &&
                screenY + height > 0 && screenY < this.canvas.height) {
                
                // Building shadow
                this.ctx.fillStyle = 'rgba(0, 0, 0, 0.2)';
                this.ctx.fillRect(screenX + 3, screenY + height - 3, width, 3);
                
                // Building main
                this.ctx.fillStyle = building.color;
                this.ctx.fillRect(screenX, screenY, width, height);
                
                // Roof shadow
                this.ctx.fillStyle = 'rgba(0, 0, 0, 0.1)';
                this.ctx.fillRect(screenX, screenY, width, 3);
                
                // Windows
                this.ctx.fillStyle = '#ffff00';
                const windowSize = 8;
                for (let wx = 0; wx < width; wx += 20) {
                    for (let wy = 15; wy < height - 15; wy += 20) {
                        this.ctx.fillRect(screenX + 5 + wx, screenY + 5 + wy, windowSize, windowSize);
                    }
                }
                
                // Door
                this.ctx.fillStyle = '#8b4513';
                this.ctx.fillRect(screenX + width / 2 - 8, screenY + height - 16, 16, 16);
                this.ctx.fillStyle = '#daa520';
                this.ctx.fillRect(screenX + width / 2 - 2, screenY + height - 10, 4, 4);
                
                // Name label
                if (screenX + width / 2 > 0 && screenX + width / 2 < this.canvas.width) {
                    this.ctx.fillStyle = 'rgba(0, 0, 0, 0.7)';
                    this.ctx.fillRect(screenX, screenY - 20, width, 18);
                    this.ctx.fillStyle = '#ffffff';
                    this.ctx.font = 'bold 10px Arial';
                    this.ctx.textAlign = 'center';
                    this.ctx.fillText(building.name, screenX + width / 2, screenY - 5);
                }
            }
        }
    }
    
    drawObjects(cameraX, cameraY) {
        for (let obj of this.objects) {
            const screenX = (obj.x - cameraX) * this.tileSize;
            const screenY = (obj.y - cameraY) * this.tileSize;
            const width = (obj.width || 1) * this.tileSize;
            const height = (obj.height || 1) * this.tileSize;
            
            if (screenX + width > 0 && screenX < this.canvas.width &&
                screenY + height > 0 && screenY < this.canvas.height) {
                
                if (obj.type === 'tree') {
                    this.drawTree(screenX, screenY);
                } else if (obj.type === 'fence') {
                    this.drawFence(screenX, screenY);
                } else if (obj.type === 'sign') {
                    this.drawSign(screenX, screenY, obj.text);
                } else if (obj.type === 'door') {
                    this.drawDoor(screenX, screenY, obj.text);
                } else if (obj.type === 'bed') {
                    this.drawBed(screenX, screenY);
                } else if (obj.type === 'table') {
                    this.drawTable(screenX, screenY);
                } else if (obj.type === 'chair') {
                    this.drawChair(screenX, screenY);
                } else if (obj.type === 'shelf') {
                    this.drawShelf(screenX, screenY);
                }
            }
        }
    }
    
    drawDoor(x, y, text) {
        // Door frame
        this.ctx.fillStyle = '#8b4513';
        this.ctx.fillRect(x + 6, y + 2, 20, 28);
        
        // Door / opening
        this.ctx.fillStyle = '#654321';
        this.ctx.fillRect(x + 8, y + 4, 16, 24);
        
        // Door handle
        this.ctx.fillStyle = '#ffd700';
        this.ctx.beginPath();
        this.ctx.arc(x + 22, y + 16, 2, 0, Math.PI * 2);
        this.ctx.fill();
    }
    
    drawBed(x, y) {
        // Mattress
        this.ctx.fillStyle = '#ff6b6b';
        this.ctx.fillRect(x + 2, y + 8, 28, 20);
        
        // Pillow
        this.ctx.fillStyle = '#ffffff';
        this.ctx.fillRect(x + 4, y + 4, 12, 8);
        
        // Bedframe
        this.ctx.strokeStyle = '#8b4513';
        this.ctx.lineWidth = 2;
        this.ctx.strokeRect(x + 2, y + 8, 28, 20);
    }
    
    drawTable(x, y) {
        // Tabletop
        this.ctx.fillStyle = '#d2691e';
        this.ctx.fillRect(x + 4, y + 8, 24, 16);
        
        // Legs
        this.ctx.fillStyle = '#8b4513';
        this.ctx.fillRect(x + 6, y + 20, 4, 8);
        this.ctx.fillRect(x + 22, y + 20, 4, 8);
    }
    
    drawChair(x, y) {
        // Seat
        this.ctx.fillStyle = '#a0522d';
        this.ctx.fillRect(x + 8, y + 12, 16, 10);
        
        // Backrest
        this.ctx.fillStyle = '#8b4513';
        this.ctx.fillRect(x + 10, y + 4, 12, 8);
        
        // Legs
        this.ctx.strokeStyle = '#8b4513';
        this.ctx.lineWidth = 2;
        this.ctx.beginPath();
        this.ctx.moveTo(x + 10, y + 22);
        this.ctx.lineTo(x + 10, y + 28);
        this.ctx.stroke();
        
        this.ctx.beginPath();
        this.ctx.moveTo(x + 22, y + 22);
        this.ctx.lineTo(x + 22, y + 28);
        this.ctx.stroke();
    }
    
    drawShelf(x, y) {
        // Shelf unit
        this.ctx.fillStyle = '#8b4513';
        this.ctx.fillRect(x + 2, y + 4, 28, 20);
        
        // Shelves
        this.ctx.strokeStyle = '#654321';
        this.ctx.lineWidth = 1;
        for (let i = 0; i < 3; i++) {
            this.ctx.beginPath();
            this.ctx.moveTo(x + 4, y + 12 + i * 6);
            this.ctx.lineTo(x + 28, y + 12 + i * 6);
            this.ctx.stroke();
        }
        
        // Books on shelf
        this.ctx.fillStyle = '#ff0000';
        this.ctx.fillRect(x + 6, y + 13, 3, 5);
        this.ctx.fillStyle = '#0000ff';
        this.ctx.fillRect(x + 10, y + 13, 3, 5);
        this.ctx.fillStyle = '#ffff00';
        this.ctx.fillRect(x + 14, y + 13, 3, 5);
    }

    drawSign(x, y, text) {
        // Sign board
        this.ctx.fillStyle = '#b87333';
        this.ctx.fillRect(x + 4, y + 4, 24, 16);

        // Post
        this.ctx.fillStyle = '#8b4513';
        this.ctx.fillRect(x + 14, y + 16, 4, 16);

        // Border and text
        this.ctx.lineWidth = 1;
        this.ctx.strokeStyle = '#654321';
        this.ctx.strokeRect(x + 4, y + 4, 24, 16);

        this.ctx.fillStyle = '#000000';
        this.ctx.font = '8px Arial';
        this.ctx.textAlign = 'center';
        this.ctx.textBaseline = 'middle';
        const lines = (text || '').split('\n');
        lines.forEach((line, idx) => {
            this.ctx.fillText(line, x + 16, y + 10 + idx * 6);
        });
    }
    
    drawNPCs(cameraX, cameraY) {
        for (let npc of this.npcs) {
            const screenX = (npc.x - cameraX) * this.tileSize;
            const screenY = (npc.y - cameraY) * this.tileSize;
            
            if (screenX + this.tileSize > 0 && screenX < this.canvas.width &&
                screenY + this.tileSize > 0 && screenY < this.canvas.height) {
                
                // NPC sprite
                this.drawNPCSprite(screenX, screenY, npc.sprite);
                
                // Name label
                this.ctx.fillStyle = 'rgba(0, 0, 0, 0.7)';
                this.ctx.fillRect(screenX + 2, screenY - 15, this.tileSize - 4, 12);
                this.ctx.fillStyle = '#ffffff';
                this.ctx.font = 'bold 8px Arial';
                this.ctx.textAlign = 'center';
                this.ctx.fillText(npc.name, screenX + this.tileSize / 2, screenY - 7);
            }
        }
    }
    
    drawNPCSprite(x, y, spriteType) {
        if (spriteType === 'oak') {
            // Professor Oak - elderly with hat
            this.ctx.fillStyle = '#f4a460';
            this.ctx.beginPath();
            this.ctx.arc(x + 16, y + 8, 6, 0, Math.PI * 2);
            this.ctx.fill();
            
            // Hat
            this.ctx.fillStyle = '#8b4513';
            this.ctx.beginPath();
            this.ctx.moveTo(x + 10, y + 7);
            this.ctx.lineTo(x + 22, y + 7);
            this.ctx.lineTo(x + 20, y + 3);
            this.ctx.lineTo(x + 12, y + 3);
            this.ctx.fill();
            
            // Body
            this.ctx.fillStyle = '#32cd32';
            this.ctx.fillRect(x + 8, y + 14, 16, 14);
            
        } else if (spriteType === 'mom') {
            // Mom - friendly appearance
            this.ctx.fillStyle = '#f4a460';
            this.ctx.beginPath();
            this.ctx.arc(x + 16, y + 8, 6, 0, Math.PI * 2);
            this.ctx.fill();
            
            // Hair
            this.ctx.fillStyle = '#8b6914';
            this.ctx.beginPath();
            this.ctx.arc(x + 16, y + 6, 7, 0, Math.PI * 2);
            this.ctx.fill();
            
            // Body
            this.ctx.fillStyle = '#ff69b4';
            this.ctx.fillRect(x + 8, y + 14, 16, 14);
            
        } else if (spriteType === 'rival') {
            // Rival - athletic stance
            this.ctx.fillStyle = '#f4a460';
            this.ctx.beginPath();
            this.ctx.arc(x + 16, y + 8, 6, 0, Math.PI * 2);
            this.ctx.fill();
            
            // Hair
            this.ctx.fillStyle = '#1a1a1a';
            this.ctx.beginPath();
            this.ctx.moveTo(x + 10, y + 5);
            this.ctx.lineTo(x + 22, y + 5);
            this.ctx.lineTo(x + 20, y + 2);
            this.ctx.lineTo(x + 12, y + 2);
            this.ctx.fill();
            
            // Body
            this.ctx.fillStyle = '#4169e1';
            this.ctx.fillRect(x + 8, y + 14, 16, 14);
        }
    }
    
    drawPlayer(cameraX, cameraY) {
        const screenX = (this.player.x - cameraX) * this.tileSize;
        const screenY = (this.player.y - cameraY) * this.tileSize;
        const animFrame = this.player.animationFrame;
        
        // Call direction-specific draw function
        switch(this.player.direction) {
            case 'up':
                this.drawPlayerNorth(screenX, screenY, animFrame);
                break;
            case 'down':
                this.drawPlayerSouth(screenX, screenY, animFrame);
                break;
            case 'left':
                this.drawPlayerWest(screenX, screenY, animFrame);
                break;
            case 'right':
                this.drawPlayerEast(screenX, screenY, animFrame);
                break;
        }
    }
    
    drawPlayerNorth(x, y, animFrame) {
        // Character facing north (back view)
        const legSwing = Math.sin((animFrame / 60) * Math.PI * 2) * 2;
        
        // Brown hair (back of head)
        this.ctx.fillStyle = '#8b4513';
        this.ctx.beginPath();
        this.ctx.arc(x + 16, y + 6, 7, 0, Math.PI * 2);
        this.ctx.fill();
        
        // Left arm (back view - swinging)
        this.ctx.fillStyle = '#ffdbac';
        const leftArmX = x + 4;
        this.ctx.save();
        this.ctx.translate(leftArmX + 2, y + 16);
        this.ctx.rotate((legSwing / 5) * Math.PI / 180);
        this.ctx.fillRect(0, 0, 3, 12);
        this.ctx.beginPath();
        this.ctx.arc(1.5, 12, 2.5, 0, Math.PI * 2);
        this.ctx.fill();
        this.ctx.restore();
        
        // Right arm (back view - swinging opposite)
        const rightArmX = x + 26;
        this.ctx.save();
        this.ctx.translate(rightArmX, y + 16);
        this.ctx.rotate((-legSwing / 5) * Math.PI / 180);
        this.ctx.fillRect(0, 0, 3, 12);
        this.ctx.beginPath();
        this.ctx.arc(1.5, 12, 2.5, 0, Math.PI * 2);
        this.ctx.fill();
        this.ctx.restore();
        
        // Red shirt/body
        this.ctx.fillStyle = '#ff6b6b';
        this.ctx.fillRect(x + 6, y + 14, 20, 14);
        
        // Black shorts
        this.ctx.fillStyle = '#1a1a1a';
        this.ctx.fillRect(x + 8, y + 26, 16, 4);
        
        // Left leg
        this.ctx.fillStyle = '#ffdbac';
        this.ctx.fillRect(x + 8, y + 30, 6, 8 + legSwing);
        
        // Right leg
        this.ctx.fillRect(x + 18, y + 30, 6, 8 - legSwing);
        
        // Left foot
        this.ctx.fillStyle = '#ff8c00';
        this.ctx.fillRect(x + 8, y + 38 + legSwing, 6, 3);
        
        // Right foot
        this.ctx.fillRect(x + 18, y + 38 - legSwing, 6, 3);
    }
    
    drawPlayerSouth(x, y, animFrame) {
        // Character facing south (front view)
        const legSwing = Math.sin((animFrame / 60) * Math.PI * 2) * 2;
        
        // Skin head
        this.ctx.fillStyle = '#ffdbac';
        this.ctx.beginPath();
        this.ctx.arc(x + 16, y + 6, 6, 0, Math.PI * 2);
        this.ctx.fill();
        
        // Brown hair (front)
        this.ctx.fillStyle = '#8b4513';
        this.ctx.fillRect(x + 10, y + 2, 12, 6);
        
        // Left arm (front view - swinging)
        this.ctx.fillStyle = '#ffdbac';
        const leftArmX = x + 3;
        this.ctx.save();
        this.ctx.translate(leftArmX + 2, y + 16);
        this.ctx.rotate((-legSwing / 5) * Math.PI / 180);
        this.ctx.fillRect(0, 0, 3, 12);
        this.ctx.beginPath();
        this.ctx.arc(1.5, 12, 2.5, 0, Math.PI * 2);
        this.ctx.fill();
        this.ctx.restore();
        
        // Right arm (front view - swinging opposite)
        const rightArmX = x + 27;
        this.ctx.save();
        this.ctx.translate(rightArmX, y + 16);
        this.ctx.rotate((legSwing / 5) * Math.PI / 180);
        this.ctx.fillRect(0, 0, 3, 12);
        this.ctx.beginPath();
        this.ctx.arc(1.5, 12, 2.5, 0, Math.PI * 2);
        this.ctx.fill();
        this.ctx.restore();
        
        // Red shirt/body
        this.ctx.fillStyle = '#ff6b6b';
        this.ctx.fillRect(x + 6, y + 14, 20, 14);
        
        // Black shorts
        this.ctx.fillStyle = '#1a1a1a';
        this.ctx.fillRect(x + 8, y + 26, 16, 4);
        
        // Left leg
        this.ctx.fillStyle = '#ffdbac';
        this.ctx.fillRect(x + 8, y + 30, 6, 8 + legSwing);
        
        // Right leg
        this.ctx.fillRect(x + 18, y + 30, 6, 8 - legSwing);
        
        // Left foot
        this.ctx.fillStyle = '#ff8c00';
        this.ctx.fillRect(x + 8, y + 38 + legSwing, 6, 3);
        
        // Right foot
        this.ctx.fillRect(x + 18, y + 38 - legSwing, 6, 3);
        
        // Eyes
        this.ctx.fillStyle = '#000000';
        this.ctx.beginPath();
        this.ctx.arc(x + 12, y + 5, 1.5, 0, Math.PI * 2);
        this.ctx.fill();
        this.ctx.beginPath();
        this.ctx.arc(x + 20, y + 5, 1.5, 0, Math.PI * 2);
        this.ctx.fill();
        
        // Mouth
        this.ctx.strokeStyle = '#000000';
        this.ctx.lineWidth = 1;
        this.ctx.beginPath();
        this.ctx.arc(x + 16, y + 10, 2, 0, Math.PI);
        this.ctx.stroke();
    }
    
    drawPlayerEast(x, y, animFrame) {
        // Character facing east (right profile)
        const legSwing = Math.sin((animFrame / 60) * Math.PI * 2) * 2;
        
        // Skin head (profile)
        this.ctx.fillStyle = '#ffdbac';
        this.ctx.beginPath();
        this.ctx.arc(x + 20, y + 6, 6, 0, Math.PI * 2);
        this.ctx.fill();
        
        // Brown hair (right side)
        this.ctx.fillStyle = '#8b4513';
        this.ctx.fillRect(x + 20, y + 2, 8, 8);
        
        // Right arm (visible - swinging forward)
        this.ctx.fillStyle = '#ffdbac';
        const rightArmX = x + 24;
        this.ctx.save();
        this.ctx.translate(rightArmX + 2, y + 16);
        this.ctx.rotate((legSwing / 4) * Math.PI / 180);
        this.ctx.fillRect(0, 0, 3, 12);
        this.ctx.beginPath();
        this.ctx.arc(1.5, 12, 2.5, 0, Math.PI * 2);
        this.ctx.fill();
        this.ctx.restore();
        
        // Left arm (hidden behind body)
        this.ctx.fillStyle = '#8b4513';
        this.ctx.fillRect(x + 5, y + 16, 3, 6);
        
        // Red shirt/body
        this.ctx.fillStyle = '#ff6b6b';
        this.ctx.beginPath();
        this.ctx.moveTo(x + 8, y + 14);
        this.ctx.lineTo(x + 24, y + 14);
        this.ctx.lineTo(x + 24, y + 28);
        this.ctx.lineTo(x + 8, y + 28);
        this.ctx.fill();
        
        // Black shorts
        this.ctx.fillStyle = '#1a1a1a';
        this.ctx.fillRect(x + 8, y + 26, 14, 4);
        
        // Left leg (back leg)
        this.ctx.fillStyle = '#ffdbac';
        this.ctx.fillRect(x + 10, y + 30, 5, 8 - legSwing);
        
        // Right leg (front leg)
        this.ctx.fillRect(x + 17, y + 30, 5, 8 + legSwing);
        
        // Left foot
        this.ctx.fillStyle = '#ff8c00';
        this.ctx.fillRect(x + 10, y + 38 - legSwing, 5, 3);
        
        // Right foot
        this.ctx.fillRect(x + 17, y + 38 + legSwing, 5, 3);
        
        // Eye (profile view)
        this.ctx.fillStyle = '#000000';
        this.ctx.beginPath();
        this.ctx.arc(x + 22, y + 5, 1.5, 0, Math.PI * 2);
        this.ctx.fill();
        
        // Mouth (profile)
        this.ctx.strokeStyle = '#000000';
        this.ctx.lineWidth = 1;
        this.ctx.beginPath();
        this.ctx.arc(x + 22, y + 10, 1.5, 0, Math.PI);
        this.ctx.stroke();
    }
    
    drawPlayerWest(x, y, animFrame) {
        // Character facing west (left profile)
        const legSwing = Math.sin((animFrame / 60) * Math.PI * 2) * 2;
        
        // Skin head (profile)
        this.ctx.fillStyle = '#ffdbac';
        this.ctx.beginPath();
        this.ctx.arc(x + 12, y + 6, 6, 0, Math.PI * 2);
        this.ctx.fill();
        
        // Brown hair (left side)
        this.ctx.fillStyle = '#8b4513';
        this.ctx.fillRect(x + 4, y + 2, 8, 8);
        
        // Left arm (visible - swinging forward)
        this.ctx.fillStyle = '#ffdbac';
        const leftArmX = x + 6;
        this.ctx.save();
        this.ctx.translate(leftArmX - 2, y + 16);
        this.ctx.rotate((-legSwing / 4) * Math.PI / 180);
        this.ctx.fillRect(-3, 0, 3, 12);
        this.ctx.beginPath();
        this.ctx.arc(-1.5, 12, 2.5, 0, Math.PI * 2);
        this.ctx.fill();
        this.ctx.restore();
        
        // Right arm (hidden behind body)
        this.ctx.fillStyle = '#8b4513';
        this.ctx.fillRect(x + 24, y + 16, 3, 6);
        
        // Red shirt/body
        this.ctx.fillStyle = '#ff6b6b';
        this.ctx.beginPath();
        this.ctx.moveTo(x + 8, y + 14);
        this.ctx.lineTo(x + 24, y + 14);
        this.ctx.lineTo(x + 24, y + 28);
        this.ctx.lineTo(x + 8, y + 28);
        this.ctx.fill();
        
        // Black shorts
        this.ctx.fillStyle = '#1a1a1a';
        this.ctx.fillRect(x + 10, y + 26, 14, 4);
        
        // Left leg (front leg)
        this.ctx.fillStyle = '#ffdbac';
        this.ctx.fillRect(x + 10, y + 30, 5, 8 + legSwing);
        
        // Right leg (back leg)
        this.ctx.fillRect(x + 17, y + 30, 5, 8 - legSwing);
        
        // Left foot
        this.ctx.fillStyle = '#ff8c00';
        this.ctx.fillRect(x + 10, y + 38 + legSwing, 5, 3);
        
        // Right foot
        this.ctx.fillRect(x + 17, y + 38 - legSwing, 5, 3);
        
        // Eye (profile view)
        this.ctx.fillStyle = '#000000';
        this.ctx.beginPath();
        this.ctx.arc(x + 10, y + 5, 1.5, 0, Math.PI * 2);
        this.ctx.fill();
        
        // Mouth (profile)
        this.ctx.strokeStyle = '#000000';
        this.ctx.lineWidth = 1;
        this.ctx.beginPath();
        this.ctx.arc(x + 10, y + 10, 1.5, 0, Math.PI);
        this.ctx.stroke();
    }
    
    updateUI() {
        // Update FPS
        const now = performance.now();
        if (now - this.lastFrameTime >= 1000) {
            this.fps = this.frameCount;
            this.frameCount = 0;
            this.lastFrameTime = now;
        }
        this.frameCount++;
        
        const fpsEl = document.getElementById('fps');
        if (fpsEl) {
            fpsEl.textContent = `FPS: ${this.fps}`;
        }
        
        // Update coordinates + pressed keys for debugging
        const coordEl = document.getElementById('coordinates');
        if (coordEl) {
            const mapX = Math.floor(this.player.x);
            const mapY = Math.floor(this.player.y);
            const pressed = Object.keys(this.keys).filter(k => this.keys[k]);
            const pressedText = pressed.length ? ` | Keys: ${pressed.join(',')}` : '';
            coordEl.textContent = `Position: (${mapX}, ${mapY})${pressedText}`;
        }
    }
    
    gameLoop() {
        try {
            this.update();
            this.draw();
        } catch (err) {
            // Render error overlay on canvas
            try {
                this.ctx.fillStyle = 'rgba(0,0,0,0.6)';
                this.ctx.fillRect(0, 0, this.canvas.width, this.canvas.height);
                this.ctx.fillStyle = '#fff';
                this.ctx.font = '16px Arial';
                const message = 'Error: ' + (err && err.message ? err.message : String(err));
                this.ctx.fillText(message, 10, 30);
                // Also write to an error div if present
                const errEl = document.getElementById('gameError');
                if (errEl) errEl.textContent = message;
            } catch (e) {
                // ignore
            }
            console.error(err);
            return; // stop the loop so user can see the error
        }
        requestAnimationFrame(() => this.gameLoop());
    }
    
    start() {
        // Try to focus the canvas so keyboard controls are active
        try { this.canvas.focus(); } catch (e) {}
        this.gameLoop();
    }
}

// Initialize game when page loads
window.addEventListener('DOMContentLoaded', () => {
    const game = new PalletTownGame('gameCanvas');
    game.start();
});
