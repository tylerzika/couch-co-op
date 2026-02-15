import SwiftUI
import GameplayKit

// MARK: - Game Models
struct GamePlayer {
    var x: Float = 14
    var y: Float = 12
    var direction: Direction = .down
    var speed: Float = 0.08
    var animationFrame: Int = 0
}

enum Direction: String, CaseIterable {
    case up, down, left, right
}

struct Building {
    let name: String
    let x: Int
    let y: Int
    let width: Int
    let height: Int
    let color: Color
}

struct GameObject {
    let type: GameObjectType
    let x: Int
    let y: Int
    let width: Int = 1
    let height: Int = 1
    let text: String?
    
    enum GameObjectType {
        case tree
        case fence
        case sign
        case door
        case bed
        case table
        case chair
        case shelf
    }
}

struct NPC {
    let name: String
    let x: Int
    let y: Int
    let sprite: NPCType
    
    enum NPCType {
        case oak, mom, rival
    }
}

// MARK: - Game State
class PalletTownGame: NSObject, ObservableObject {
    @Published var player = GamePlayer()
    @Published var playerScreenX: CGFloat = 0
    @Published var playerScreenY: CGFloat = 0
    @Published var fps: Int = 60
    @Published var positionText: String = "Position: (0, 0)"
    
    let tileSize: CGFloat = 32
    let mapWidth = 30
    let mapHeight = 25
    var isInside = false
    
    var buildings: [Building] = []
    var objects: [GameObject] = []
    var npcs: [NPC] = []
    
    var terrain: [[String]] = []
    var outsideTerrain: [[String]] = []
    var insideTerrain: [[String]] = []
    
    var outsideBuildings: [Building] = []
    var outsideObjects: [GameObject] = []
    var outsideNPCs: [NPC] = []
    
    var insideBuildings: [Building] = []
    var insideObjects: [GameObject] = []
    var insideNPCs: [NPC] = []
    
    var keyPressed: Set<String> = []
    var currentNearDoorId: Int? = nil
    var gameTimer: Timer?
    var displayLink: CVDisplayLink?
    
    var frameCount = 0
    var lastFpsUpdate = Date()
    
    override init() {
        super.init()
        setupGame()
    }
    
    func setupGame() {
        generateOutsideTerrain()
        generateInsideTerrain()
        
        outsideBuildings = createOutsideBuildings()
        outsideObjects = createOutsideObjects()
        outsideNPCs = createOutsideNPCs()
        
        insideBuildings = []
        insideObjects = createInsideObjects()
        insideNPCs = []
        
        updateCurrentMap()
    }
    
    func updateCurrentMap() {
        if isInside {
            terrain = insideTerrain
            buildings = insideBuildings
            objects = insideObjects
            npcs = insideNPCs
        } else {
            terrain = outsideTerrain
            buildings = outsideBuildings
            objects = outsideObjects
            npcs = outsideNPCs
        }
    }
    
    func generateOutsideTerrain() {
        var t: [[String]] = []
        for _ in 0..<mapHeight {
            var row: [String] = []
            for _ in 0..<mapWidth {
                row.append("grass")
            }
            t.append(row)
        }
        outsideTerrain = t
    }
    
    func generateInsideTerrain() {
        var t: [[String]] = []
        for y in 0..<mapHeight {
            var row: [String] = []
            for x in 0..<mapWidth {
                if x >= 5 && x <= 15 && y >= 3 && y <= 15 {
                    row.append("floor")
                } else {
                    row.append("grass")
                }
            }
            t.append(row)
        }
        insideTerrain = t
    }
    
    func createOutsideBuildings() -> [Building] {
        return [
            Building(name: "House", x: 8, y: 5, width: 14, height: 14, color: .red)
        ]
    }
    
    func createOutsideObjects() -> [GameObject] {
        return [
            GameObject(type: .door, x: 11, y: 4, width: 1, height: 1, text: "Press ENTER\nto enter"),
        ]
    }
    
    func createOutsideNPCs() -> [NPC] {
        return []
    }
    
    func createInsideObjects() -> [GameObject] {
        return [
            GameObject(type: .door, x: 11, y: 3, width: 1, height: 1, text: "Press ENTER\nto exit"),
            GameObject(type: .bed, x: 6, y: 4, width: 2, height: 1, text: "Bed"),
            GameObject(type: .table, x: 6, y: 6, width: 1, height: 1, text: "Table"),
            GameObject(type: .chair, x: 13, y: 6, width: 1, height: 1, text: "Chair"),
            GameObject(type: .shelf, x: 8, y: 13, width: 2, height: 1, text: "Shelf"),
        ]
    }
    
    func resetPlayer() {
        player.x = 14
        player.y = 12
        player.direction = .down
    }
    
    func update() {
        handleInput()
        checkDoorInteraction()
        checkCollisions()
        updateUI()
        // Only animate when moving
        let movementKeys = ["up", "down", "left", "right", "w", "a", "s", "d"]
        if movementKeys.contains(where: { keyPressed.contains($0) }) {
            player.animationFrame = (player.animationFrame + 1) % 60
        }
    }
    
    func handleInput() {
        let moveSpeed = player.speed
        
        if keyPressed.contains("up") || keyPressed.contains("w") {
            player.y -= moveSpeed
            player.direction = .up
        }
        if keyPressed.contains("down") || keyPressed.contains("s") {
            player.y += moveSpeed
            player.direction = .down
        }
        if keyPressed.contains("left") || keyPressed.contains("a") {
            player.x -= moveSpeed
            player.direction = .left
        }
        if keyPressed.contains("right") || keyPressed.contains("d") {
            player.x += moveSpeed
            player.direction = .right
        }
        
        // Clamp to map bounds
        player.x = max(0, min(Float(mapWidth - 1), player.x))
        player.y = max(0, min(Float(mapHeight - 1), player.y))
    }
    
    func checkDoorInteraction() {
        var newNearDoorId: Int? = nil
        var doorIndex = 0
        
        for door in objects {
            if door.type == .door {
                let distance = hypot(Float(player.x) - Float(door.x), Float(player.y) - Float(door.y))
                if distance < 1.2 {
                    newNearDoorId = doorIndex
                }
            }
            doorIndex += 1
        }
        
        // Only transition if entering a new door proximity (state change)
        if newNearDoorId != nil && currentNearDoorId == nil {
            // Entering door zone
            isInside = !isInside
            updateCurrentMap()
            
            if isInside {
                player.x = 11
                player.y = 8
            } else {
                player.x = 11
                player.y = 5.5
            }
        }
        
        currentNearDoorId = newNearDoorId
    }
    
    func checkCollisions() {
        let margin: Float = 0.5
        let originalX = player.x
        let originalY = player.y
        
        // Building collisions
        for building in buildings {
            if player.x + margin < Float(building.x + building.width) &&
               player.x - margin > Float(building.x) &&
               player.y + margin < Float(building.y + building.height) &&
               player.y - margin > Float(building.y) {
                
                player.x = originalX
                player.y = originalY
                return
            }
        }
        
        // Object collisions (furniture and doors)
        for obj in objects {
            if obj.type != .sign && obj.type != .door {
                // Collision for furniture
                if player.x + margin < Float(obj.x + obj.width) &&
                   player.x - margin > Float(obj.x) &&
                   player.y + margin < Float(obj.y + obj.height) &&
                   player.y - margin > Float(obj.y) {
                    
                    player.x = originalX
                    player.y = originalY
                    return
                }
            }
        }
    }
    
    func updateUI() {
        frameCount += 1
        let now = Date()
        if now.timeIntervalSince(lastFpsUpdate) >= 1.0 {
            fps = frameCount
            frameCount = 0
            lastFpsUpdate = now
        }
        
        let mapX = Int(player.x)
        let mapY = Int(player.y)
        positionText = "Position: (\(mapX), \(mapY))"
    }
    
    func startGameLoop() {
        gameTimer = Timer.scheduledTimer(withTimeInterval: 1.0/60.0, repeats: true) { [weak self] _ in
            DispatchQueue.main.async {
                self?.update()
            }
        }
    }
    
    func stopGameLoop() {
        gameTimer?.invalidate()
    }
    
    deinit {
        stopGameLoop()
    }
}

// MARK: - Canvas View
struct GameCanvasView: NSViewRepresentable {
    @ObservedObject var game: PalletTownGame
    
    func makeNSView(context: Context) -> GameView {
        let view = GameView(game: game)
        return view
    }
    
    func updateNSView(_ nsView: GameView, context: Context) {
        nsView.game = game
        nsView.setNeedsDisplay(nsView.bounds)
    }
}

class GameView: NSView {
    var game: PalletTownGame
    
    init(game: PalletTownGame) {
        self.game = game
        super.init(frame: .zero)
        self.wantsLayer = true
        self.layer?.backgroundColor = NSColor(red: 0.53, green: 0.81, blue: 0.92, alpha: 1.0).cgColor
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        let ctx = NSGraphicsContext.current?.cgContext
        guard let ctx = ctx else { return }
        
        let tileSize = game.tileSize
        let mapWidth = game.mapWidth
        let mapHeight = game.mapHeight
        
        let canvasWidth = bounds.width
        let canvasHeight = bounds.height
        
        // Calculate camera offset
        let cameraX = CGFloat(game.player.x) - canvasWidth / tileSize / 2
        let cameraY = CGFloat(game.player.y) - canvasHeight / tileSize / 2
        
        // Draw terrain tiles
        for y in 0..<mapHeight {
            for x in 0..<mapWidth {
                let screenX = (CGFloat(x) - cameraX) * tileSize
                let screenY = (CGFloat(y) - cameraY) * tileSize
                
                if screenX + tileSize > 0 && screenX < canvasWidth &&
                   screenY + tileSize > 0 && screenY < canvasHeight {
                    let terrain = game.terrain[y][x]
                    if terrain == "grass" {
                        drawGrassTile(ctx, x: screenX, y: screenY)
                    } else if terrain == "floor" {
                        drawFloorTile(ctx, x: screenX, y: screenY)
                    }
                }
            }
        }
        
        // Draw objects
        for obj in game.objects {
            let screenX = (CGFloat(obj.x) - cameraX) * tileSize
            let screenY = (CGFloat(obj.y) - cameraY) * tileSize
            
            if screenX + tileSize > 0 && screenX < canvasWidth &&
               screenY + tileSize > 0 && screenY < canvasHeight {
                
                switch obj.type {
                case .tree:
                    drawTree(ctx, x: screenX, y: screenY)
                case .fence:
                    drawFence(ctx, x: screenX, y: screenY)
                case .sign:
                    drawSign(ctx, x: screenX, y: screenY, text: obj.text ?? "")
                case .door:
                    drawDoor(ctx, x: screenX, y: screenY)
                case .bed:
                    drawBed(ctx, x: screenX, y: screenY)
                case .table:
                    drawTable(ctx, x: screenX, y: screenY)
                case .chair:
                    drawChair(ctx, x: screenX, y: screenY)
                case .shelf:
                    drawShelf(ctx, x: screenX, y: screenY)
                }
            }
        }
        
        // Draw buildings
        for building in game.buildings {
            let screenX = (CGFloat(building.x) - cameraX) * tileSize
            let screenY = (CGFloat(building.y) - cameraY) * tileSize
            let width = CGFloat(building.width) * tileSize
            let height = CGFloat(building.height) * tileSize
            
            if screenX + width > 0 && screenX < canvasWidth &&
               screenY + height > 0 && screenY < canvasHeight {
                drawBuilding(ctx, x: screenX, y: screenY, width: width, height: height, building: building)
            }
        }
        
        // Draw NPCs
        for npc in game.npcs {
            let screenX = (CGFloat(npc.x) - cameraX) * tileSize
            let screenY = (CGFloat(npc.y) - cameraY) * tileSize
            
            if screenX + tileSize > 0 && screenX < canvasWidth &&
               screenY + tileSize > 0 && screenY < canvasHeight {
                drawNPC(ctx, x: screenX, y: screenY, npc: npc)
            }
        }
        
        // Draw player
        let playerScreenX = (CGFloat(game.player.x) - cameraX) * tileSize
        let playerScreenY = (CGFloat(game.player.y) - cameraY) * tileSize
        drawPlayer(ctx, x: playerScreenX, y: playerScreenY)
    }
    
    func drawGrassTile(_ ctx: CGContext, x: CGFloat, y: CGFloat) {
        let tileSize = game.tileSize
        
        // Light green background
        ctx.setFillColor(NSColor(red: 0.49, green: 0.64, blue: 0.26, alpha: 1.0).cgColor)
        ctx.fill(CGRect(x: x, y: y, width: tileSize, height: tileSize))
        
        // Darker grass
        ctx.setFillColor(NSColor(red: 0.41, green: 0.62, blue: 0.22, alpha: 1.0).cgColor)
        ctx.fill(CGRect(x: x + 2, y: y + 2, width: tileSize - 4, height: tileSize - 4))
    }
    
    func drawTree(_ ctx: CGContext, x: CGFloat, y: CGFloat) {
        let tileSize = game.tileSize
        
        // Trunk
        ctx.setFillColor(NSColor(red: 0.55, green: 0.27, blue: 0.07, alpha: 1.0).cgColor)
        ctx.fill(CGRect(x: x + 10, y: y + 16, width: 12, height: 16))
        
        // Foliage
        ctx.setFillColor(NSColor(red: 0.2, green: 0.42, blue: 0.12, alpha: 1.0).cgColor)
        ctx.addEllipse(in: CGRect(x: x + 2, y: y - 4, width: 28, height: 28))
        ctx.fillPath()
    }
    
    func drawFence(_ ctx: CGContext, x: CGFloat, y: CGFloat) {
        let tileSize = game.tileSize
        
        // Fence posts
        ctx.setFillColor(NSColor(red: 0.63, green: 0.32, blue: 0.18, alpha: 1.0).cgColor)
        for i in 0..<4 {
            ctx.fill(CGRect(x: x + CGFloat(i) * 8, y: y + 12, width: 4, height: 12))
        }
        
        // Rails
        ctx.setStrokeColor(NSColor(red: 0.55, green: 0.27, blue: 0.07, alpha: 1.0).cgColor)
        ctx.setLineWidth(2)
        
        var path = CGMutablePath()
        path.move(to: CGPoint(x: x + 4, y: y + 16))
        path.addLine(to: CGPoint(x: x + 28, y: y + 16))
        ctx.addPath(path)
        ctx.strokePath()
    }
    
    func drawSign(_ ctx: CGContext, x: CGFloat, y: CGFloat, text: String) {
        // Sign board
        ctx.setFillColor(NSColor(red: 0.81, green: 0.52, blue: 0.25, alpha: 1.0).cgColor)
        ctx.fill(CGRect(x: x + 4, y: y + 4, width: 24, height: 16))
        
        // Post
        ctx.setFillColor(NSColor(red: 0.55, green: 0.27, blue: 0.07, alpha: 1.0).cgColor)
        ctx.fill(CGRect(x: x + 14, y: y + 16, width: 4, height: 16))
    }
    
    func drawFloorTile(_ ctx: CGContext, x: CGFloat, y: CGFloat) {
        let tileSize = game.tileSize
        
        // Wood floor
        ctx.setFillColor(NSColor(red: 0.82, green: 0.41, blue: 0.12, alpha: 1.0).cgColor)
        ctx.fill(CGRect(x: x, y: y, width: tileSize, height: tileSize))
        
        // Wood grain pattern
        ctx.setFillColor(NSColor(red: 0.63, green: 0.32, blue: 0.18, alpha: 1.0).cgColor)
        ctx.fill(CGRect(x: x + 2, y: y + 2, width: 10, height: 2))
        ctx.fill(CGRect(x: x + 18, y: y + 10, width: 10, height: 2))
        ctx.fill(CGRect(x: x + 6, y: y + 22, width: 10, height: 2))
    }
    
    func drawDoor(_ ctx: CGContext, x: CGFloat, y: CGFloat) {
        // Door frame
        ctx.setFillColor(NSColor(red: 0.55, green: 0.27, blue: 0.07, alpha: 1.0).cgColor)
        ctx.fill(CGRect(x: x + 6, y: y + 2, width: 20, height: 28))
        
        // Door opening
        ctx.setFillColor(NSColor(red: 0.4, green: 0.26, blue: 0.13, alpha: 1.0).cgColor)
        ctx.fill(CGRect(x: x + 8, y: y + 4, width: 16, height: 24))
        
        // Door handle
        ctx.setFillColor(NSColor.yellow.cgColor)
        ctx.addEllipse(in: CGRect(x: x + 20, y: y + 14, width: 4, height: 4))
        ctx.fillPath()
    }
    
    func drawBed(_ ctx: CGContext, x: CGFloat, y: CGFloat) {
        // Mattress
        ctx.setFillColor(NSColor(red: 1.0, green: 0.42, blue: 0.42, alpha: 1.0).cgColor)
        ctx.fill(CGRect(x: x + 2, y: y + 8, width: 28, height: 20))
        
        // Pillow
        ctx.setFillColor(NSColor.white.cgColor)
        ctx.fill(CGRect(x: x + 4, y: y + 4, width: 12, height: 8))
        
        // Bedframe
        ctx.setStrokeColor(NSColor(red: 0.55, green: 0.27, blue: 0.07, alpha: 1.0).cgColor)
        ctx.setLineWidth(2)
        ctx.stroke(CGRect(x: x + 2, y: y + 8, width: 28, height: 20))
    }
    
    func drawTable(_ ctx: CGContext, x: CGFloat, y: CGFloat) {
        // Tabletop
        ctx.setFillColor(NSColor(red: 0.82, green: 0.41, blue: 0.12, alpha: 1.0).cgColor)
        ctx.fill(CGRect(x: x + 4, y: y + 8, width: 24, height: 16))
        
        // Legs
        ctx.setFillColor(NSColor(red: 0.55, green: 0.27, blue: 0.07, alpha: 1.0).cgColor)
        ctx.fill(CGRect(x: x + 6, y: y + 20, width: 4, height: 8))
        ctx.fill(CGRect(x: x + 22, y: y + 20, width: 4, height: 8))
    }
    
    func drawChair(_ ctx: CGContext, x: CGFloat, y: CGFloat) {
        // Seat
        ctx.setFillColor(NSColor(red: 0.63, green: 0.32, blue: 0.18, alpha: 1.0).cgColor)
        ctx.fill(CGRect(x: x + 8, y: y + 12, width: 16, height: 10))
        
        // Backrest
        ctx.setFillColor(NSColor(red: 0.55, green: 0.27, blue: 0.07, alpha: 1.0).cgColor)
        ctx.fill(CGRect(x: x + 10, y: y + 4, width: 12, height: 8))
        
        // Legs
        ctx.setStrokeColor(NSColor(red: 0.55, green: 0.27, blue: 0.07, alpha: 1.0).cgColor)
        ctx.setLineWidth(2)
        
        var path = CGMutablePath()
        path.move(to: CGPoint(x: x + 10, y: y + 22))
        path.addLine(to: CGPoint(x: x + 10, y: y + 28))
        ctx.addPath(path)
        ctx.strokePath()
        
        path = CGMutablePath()
        path.move(to: CGPoint(x: x + 22, y: y + 22))
        path.addLine(to: CGPoint(x: x + 22, y: y + 28))
        ctx.addPath(path)
        ctx.strokePath()
    }
    
    func drawShelf(_ ctx: CGContext, x: CGFloat, y: CGFloat) {
        // Shelf unit
        ctx.setFillColor(NSColor(red: 0.55, green: 0.27, blue: 0.07, alpha: 1.0).cgColor)
        ctx.fill(CGRect(x: x + 2, y: y + 4, width: 28, height: 20))
        
        // Shelves
        ctx.setStrokeColor(NSColor(red: 0.4, green: 0.2, blue: 0.05, alpha: 1.0).cgColor)
        ctx.setLineWidth(1)
        for i in 0..<3 {
            var path = CGMutablePath()
            path.move(to: CGPoint(x: x + 4, y: y + 12 + CGFloat(i) * 6))
            path.addLine(to: CGPoint(x: x + 28, y: y + 12 + CGFloat(i) * 6))
            ctx.addPath(path)
            ctx.strokePath()
        }
        
        // Books on shelf
        ctx.setFillColor(NSColor.red.cgColor)
        ctx.fill(CGRect(x: x + 6, y: y + 13, width: 3, height: 5))
        ctx.setFillColor(NSColor.blue.cgColor)
        ctx.fill(CGRect(x: x + 10, y: y + 13, width: 3, height: 5))
        ctx.setFillColor(NSColor.yellow.cgColor)
        ctx.fill(CGRect(x: x + 14, y: y + 13, width: 3, height: 5))
    }
    
    func drawBuilding(_ ctx: CGContext, x: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat, building: Building) {
        // Shadow
        ctx.setFillColor(NSColor(red: 0, green: 0, blue: 0, alpha: 0.2).cgColor)
        ctx.fill(CGRect(x: x + 3, y: y + height - 3, width: width, height: 3))
        
        // Main building using building color
        let color = NSColor(building.color)
        ctx.setFillColor(color.cgColor)
        ctx.fill(CGRect(x: x, y: y, width: width, height: height))
        
        // Windows
        ctx.setFillColor(NSColor.yellow.cgColor)
        let windowSize: CGFloat = 8
        var wx = CGFloat(0)
        while wx < width {
            var wy = CGFloat(15)
            while wy < height - 15 {
                ctx.fill(CGRect(x: x + 5 + wx, y: y + 5 + wy, width: windowSize, height: windowSize))
                wy += 20
            }
            wx += 20
        }
        
        // Door
        ctx.setFillColor(NSColor(red: 0.55, green: 0.27, blue: 0.07, alpha: 1.0).cgColor)
        ctx.fill(CGRect(x: x + width / 2 - 8, y: y + height - 16, width: 16, height: 16))
    }
    
    func drawNPC(_ ctx: CGContext, x: CGFloat, y: CGFloat, npc: NPC) {
        let tileSize = game.tileSize
        
        // Head
        ctx.setFillColor(NSColor(red: 0.96, green: 0.64, blue: 0.68, alpha: 1.0).cgColor)
        ctx.addEllipse(in: CGRect(x: x + 10, y: y + 2, width: 12, height: 12))
        ctx.fillPath()
        
        // Body color based on NPC
        switch npc.sprite {
        case .oak:
            ctx.setFillColor(NSColor.green.cgColor)
        case .mom:
            ctx.setFillColor(NSColor(red: 1.0, green: 0.41, blue: 0.71, alpha: 1.0).cgColor)
        case .rival:
            ctx.setFillColor(NSColor.blue.cgColor)
        }
        
        ctx.fill(CGRect(x: x + 8, y: y + 14, width: 16, height: 14))
    }
    
    func drawPlayer(_ ctx: CGContext, x: CGFloat, y: CGFloat) {
        switch game.player.direction {
        case .up:
            drawPlayerNorth(ctx, x: x, y: y)
        case .down:
            drawPlayerSouth(ctx, x: x, y: y)
        case .left:
            drawPlayerWest(ctx, x: x, y: y)
        case .right:
            drawPlayerEast(ctx, x: x, y: y)
        }
    }
    
    func drawPlayerNorth(_ ctx: CGContext, x: CGFloat, y: CGFloat) {
        // Character facing north (back view)
        let animFrame = game.player.animationFrame
        let legSwing = sin(CGFloat(animFrame) / 60.0 * CGFloat.pi * 2) * 2
        
        // Brown hair (back of head)
        ctx.setFillColor(NSColor(red: 0.55, green: 0.27, blue: 0.07, alpha: 1.0).cgColor)
        ctx.addEllipse(in: CGRect(x: x + 10, y: y + 2, width: 12, height: 12))
        ctx.fillPath()
        
        // Left arm (back view)
        ctx.setFillColor(NSColor(red: 1.0, green: 0.86, blue: 0.67, alpha: 1.0).cgColor)
        ctx.saveGState()
        ctx.translateBy(x: x + 6, y: y + 16)
        ctx.rotate(by: (legSwing / 5) * .pi / 180)
        ctx.fill(CGRect(x: 0, y: 0, width: 3, height: 12))
        ctx.addEllipse(in: CGRect(x: -1.25, y: 12, width: 5, height: 5))
        ctx.fillPath()
        ctx.restoreGState()
        
        // Right arm (back view)
        ctx.saveGState()
        ctx.translateBy(x: x + 26, y: y + 16)
        ctx.rotate(by: (-legSwing / 5) * .pi / 180)
        ctx.fill(CGRect(x: 0, y: 0, width: 3, height: 12))
        ctx.addEllipse(in: CGRect(x: -1.25, y: 12, width: 5, height: 5))
        ctx.fillPath()
        ctx.restoreGState()
        
        // Red shirt/body
        ctx.setFillColor(NSColor(red: 1.0, green: 0.42, blue: 0.42, alpha: 1.0).cgColor)
        ctx.fill(CGRect(x: x + 6, y: y + 14, width: 20, height: 14))
        
        // Black shorts
        ctx.setFillColor(NSColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1.0).cgColor)
        ctx.fill(CGRect(x: x + 8, y: y + 26, width: 16, height: 4))
        
        // Left leg
        ctx.setFillColor(NSColor(red: 1.0, green: 0.86, blue: 0.67, alpha: 1.0).cgColor)
        ctx.fill(CGRect(x: x + 8, y: y + 30, width: 6, height: 8 + legSwing))
        
        // Right leg
        ctx.fill(CGRect(x: x + 18, y: y + 30, width: 6, height: 8 - legSwing))
        
        // Left foot
        ctx.setFillColor(NSColor(red: 1.0, green: 0.55, blue: 0.0, alpha: 1.0).cgColor)
        ctx.fill(CGRect(x: x + 8, y: y + 38 + legSwing, width: 6, height: 3))
        
        // Right foot
        ctx.fill(CGRect(x: x + 18, y: y + 38 - legSwing, width: 6, height: 3))
    }
    
    func drawPlayerSouth(_ ctx: CGContext, x: CGFloat, y: CGFloat) {
        // Character facing south (front view)
        let animFrame = game.player.animationFrame
        let legSwing = sin(CGFloat(animFrame) / 60.0 * CGFloat.pi * 2) * 2
        
        // Skin head
        ctx.setFillColor(NSColor(red: 1.0, green: 0.86, blue: 0.67, alpha: 1.0).cgColor)
        ctx.addEllipse(in: CGRect(x: x + 10, y: y + 2, width: 12, height: 12))
        ctx.fillPath()
        
        // Brown hair (front)
        ctx.setFillColor(NSColor(red: 0.55, green: 0.27, blue: 0.07, alpha: 1.0).cgColor)
        ctx.fill(CGRect(x: x + 10, y: y + 2, width: 12, height: 6))
        
        // Left arm (front view)
        ctx.setFillColor(NSColor(red: 1.0, green: 0.86, blue: 0.67, alpha: 1.0).cgColor)
        ctx.saveGState()
        ctx.translateBy(x: x + 5, y: y + 16)
        ctx.rotate(by: (-legSwing / 5) * .pi / 180)
        ctx.fill(CGRect(x: 0, y: 0, width: 3, height: 12))
        ctx.addEllipse(in: CGRect(x: -1.25, y: 12, width: 5, height: 5))
        ctx.fillPath()
        ctx.restoreGState()
        
        // Right arm (front view)
        ctx.saveGState()
        ctx.translateBy(x: x + 27, y: y + 16)
        ctx.rotate(by: (legSwing / 5) * .pi / 180)
        ctx.fill(CGRect(x: 0, y: 0, width: 3, height: 12))
        ctx.addEllipse(in: CGRect(x: -1.25, y: 12, width: 5, height: 5))
        ctx.fillPath()
        ctx.restoreGState()
        
        // Red shirt/body
        ctx.setFillColor(NSColor(red: 1.0, green: 0.42, blue: 0.42, alpha: 1.0).cgColor)
        ctx.fill(CGRect(x: x + 6, y: y + 14, width: 20, height: 14))
        
        // Black shorts
        ctx.setFillColor(NSColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1.0).cgColor)
        ctx.fill(CGRect(x: x + 8, y: y + 26, width: 16, height: 4))
        
        // Left leg
        ctx.setFillColor(NSColor(red: 1.0, green: 0.86, blue: 0.67, alpha: 1.0).cgColor)
        ctx.fill(CGRect(x: x + 8, y: y + 30, width: 6, height: 8 + legSwing))
        
        // Right leg
        ctx.fill(CGRect(x: x + 18, y: y + 30, width: 6, height: 8 - legSwing))
        
        // Left foot
        ctx.setFillColor(NSColor(red: 1.0, green: 0.55, blue: 0.0, alpha: 1.0).cgColor)
        ctx.fill(CGRect(x: x + 8, y: y + 38 + legSwing, width: 6, height: 3))
        
        // Right foot
        ctx.fill(CGRect(x: x + 18, y: y + 38 - legSwing, width: 6, height: 3))
        
        // Eyes
        ctx.setFillColor(NSColor.black.cgColor)
        ctx.addEllipse(in: CGRect(x: x + 12, y: y + 5, width: 3, height: 3))
        ctx.fillPath()
        ctx.addEllipse(in: CGRect(x: x + 17, y: y + 5, width: 3, height: 3))
        ctx.fillPath()
        
        // Mouth
        ctx.setStrokeColor(NSColor.black.cgColor)
        ctx.setLineWidth(1)
        var mouthPath = CGMutablePath()
        mouthPath.addArc(center: CGPoint(x: x + 16, y: y + 10), radius: 2, startAngle: 0, endAngle: .pi, clockwise: false)
        ctx.addPath(mouthPath)
        ctx.strokePath()
    }
    
    func drawPlayerEast(_ ctx: CGContext, x: CGFloat, y: CGFloat) {
        // Character facing east (right profile)
        let animFrame = game.player.animationFrame
        let legSwing = sin(CGFloat(animFrame) / 60.0 * CGFloat.pi * 2) * 2
        
        // Skin head (profile)
        ctx.setFillColor(NSColor(red: 1.0, green: 0.86, blue: 0.67, alpha: 1.0).cgColor)
        ctx.addEllipse(in: CGRect(x: x + 14, y: y + 2, width: 12, height: 12))
        ctx.fillPath()
        
        // Brown hair (right side)
        ctx.setFillColor(NSColor(red: 0.55, green: 0.27, blue: 0.07, alpha: 1.0).cgColor)
        ctx.fill(CGRect(x: x + 20, y: y + 2, width: 8, height: 8))
        
        // Right arm (visible - swinging)
        ctx.setFillColor(NSColor(red: 1.0, green: 0.86, blue: 0.67, alpha: 1.0).cgColor)
        ctx.saveGState()
        ctx.translateBy(x: x + 26, y: y + 16)
        ctx.rotate(by: (legSwing / 4) * .pi / 180)
        ctx.fill(CGRect(x: 0, y: 0, width: 3, height: 12))
        ctx.addEllipse(in: CGRect(x: -1.5, y: 12, width: 5, height: 5))
        ctx.fillPath()
        ctx.restoreGState()
        
        // Left arm (hidden behind body)
        ctx.setFillColor(NSColor(red: 0.55, green: 0.27, blue: 0.07, alpha: 1.0).cgColor)
        ctx.fill(CGRect(x: x + 5, y: y + 16, width: 3, height: 6))
        
        // Red shirt/body
        ctx.setFillColor(NSColor(red: 1.0, green: 0.42, blue: 0.42, alpha: 1.0).cgColor)
        var bodyPath = CGMutablePath()
        bodyPath.move(to: CGPoint(x: x + 8, y: y + 14))
        bodyPath.addLine(to: CGPoint(x: x + 24, y: y + 14))
        bodyPath.addLine(to: CGPoint(x: x + 24, y: y + 28))
        bodyPath.addLine(to: CGPoint(x: x + 8, y: y + 28))
        bodyPath.closeSubpath()
        ctx.addPath(bodyPath)
        ctx.fillPath()
        
        // Black shorts
        ctx.setFillColor(NSColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1.0).cgColor)
        ctx.fill(CGRect(x: x + 8, y: y + 26, width: 14, height: 4))
        
        // Left leg (back leg)
        ctx.setFillColor(NSColor(red: 1.0, green: 0.86, blue: 0.67, alpha: 1.0).cgColor)
        ctx.fill(CGRect(x: x + 10, y: y + 30, width: 5, height: 8 - legSwing))
        
        // Right leg (front leg)
        ctx.fill(CGRect(x: x + 17, y: y + 30, width: 5, height: 8 + legSwing))
        
        // Left foot
        ctx.setFillColor(NSColor(red: 1.0, green: 0.55, blue: 0.0, alpha: 1.0).cgColor)
        ctx.fill(CGRect(x: x + 10, y: y + 38 - legSwing, width: 5, height: 3))
        
        // Right foot
        ctx.fill(CGRect(x: x + 17, y: y + 38 + legSwing, width: 5, height: 3))
        
        // Eye (profile)
        ctx.setFillColor(NSColor.black.cgColor)
        ctx.addEllipse(in: CGRect(x: x + 20, y: y + 5, width: 3, height: 3))
        ctx.fillPath()
        
        // Mouth (profile)
        ctx.setStrokeColor(NSColor.black.cgColor)
        ctx.setLineWidth(1)
        var mouthPath = CGMutablePath()
        mouthPath.addArc(center: CGPoint(x: x + 20, y: y + 10), radius: 1.5, startAngle: 0, endAngle: .pi, clockwise: false)
        ctx.addPath(mouthPath)
        ctx.strokePath()
    }
    
    func drawPlayerWest(_ ctx: CGContext, x: CGFloat, y: CGFloat) {
        // Character facing west (left profile)
        let animFrame = game.player.animationFrame
        let legSwing = sin(CGFloat(animFrame) / 60.0 * CGFloat.pi * 2) * 2
        
        // Skin head (profile)
        ctx.setFillColor(NSColor(red: 1.0, green: 0.86, blue: 0.67, alpha: 1.0).cgColor)
        ctx.addEllipse(in: CGRect(x: x + 6, y: y + 2, width: 12, height: 12))
        ctx.fillPath()
        
        // Brown hair (left side)
        ctx.setFillColor(NSColor(red: 0.55, green: 0.27, blue: 0.07, alpha: 1.0).cgColor)
        ctx.fill(CGRect(x: x + 4, y: y + 2, width: 8, height: 8))
        
        // Left arm (visible - swinging)
        ctx.setFillColor(NSColor(red: 1.0, green: 0.86, blue: 0.67, alpha: 1.0).cgColor)
        ctx.saveGState()
        ctx.translateBy(x: x + 6, y: y + 16)
        ctx.rotate(by: (-legSwing / 4) * .pi / 180)
        ctx.fill(CGRect(x: -3, y: 0, width: 3, height: 12))
        ctx.addEllipse(in: CGRect(x: -4.5, y: 12, width: 5, height: 5))
        ctx.fillPath()
        ctx.restoreGState()
        
        // Right arm (hidden behind body)
        ctx.setFillColor(NSColor(red: 0.55, green: 0.27, blue: 0.07, alpha: 1.0).cgColor)
        ctx.fill(CGRect(x: x + 24, y: y + 16, width: 3, height: 6))
        
        // Red shirt/body
        ctx.setFillColor(NSColor(red: 1.0, green: 0.42, blue: 0.42, alpha: 1.0).cgColor)
        var bodyPath = CGMutablePath()
        bodyPath.move(to: CGPoint(x: x + 8, y: y + 14))
        bodyPath.addLine(to: CGPoint(x: x + 24, y: y + 14))
        bodyPath.addLine(to: CGPoint(x: x + 24, y: y + 28))
        bodyPath.addLine(to: CGPoint(x: x + 8, y: y + 28))
        bodyPath.closeSubpath()
        ctx.addPath(bodyPath)
        ctx.fillPath()
        
        // Black shorts
        ctx.setFillColor(NSColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1.0).cgColor)
        ctx.fill(CGRect(x: x + 10, y: y + 26, width: 14, height: 4))
        
        // Left leg (front leg)
        ctx.setFillColor(NSColor(red: 1.0, green: 0.86, blue: 0.67, alpha: 1.0).cgColor)
        ctx.fill(CGRect(x: x + 10, y: y + 30, width: 5, height: 8 + legSwing))
        
        // Right leg (back leg)
        ctx.fill(CGRect(x: x + 17, y: y + 30, width: 5, height: 8 - legSwing))
        
        // Left foot
        ctx.setFillColor(NSColor(red: 1.0, green: 0.55, blue: 0.0, alpha: 1.0).cgColor)
        ctx.fill(CGRect(x: x + 10, y: y + 38 + legSwing, width: 5, height: 3))
        
        // Right foot
        ctx.fill(CGRect(x: x + 17, y: y + 38 - legSwing, width: 5, height: 3))
        
        // Eye (profile)
        ctx.setFillColor(NSColor.black.cgColor)
        ctx.addEllipse(in: CGRect(x: x + 8, y: y + 5, width: 3, height: 3))
        ctx.fillPath()
        
        // Mouth (profile)
        ctx.setStrokeColor(NSColor.black.cgColor)
        ctx.setLineWidth(1)
        var mouthPath = CGMutablePath()
        mouthPath.addArc(center: CGPoint(x: x + 8, y: y + 10), radius: 1.5, startAngle: 0, endAngle: .pi, clockwise: false)
        ctx.addPath(mouthPath)
        ctx.strokePath()
    }
    
    override func keyDown(with event: NSEvent) {
        let key = event.characters?.lowercased() ?? ""
        let keyCode = Int(event.keyCode)
        
        switch key {
        case "w":
            game.keyPressed.insert("w")
        case "a":
            game.keyPressed.insert("a")
        case "s":
            game.keyPressed.insert("s")
        case "d":
            game.keyPressed.insert("d")
        case "r":
            game.resetPlayer()
        default:
            // Handle arrow keys by keyCode
            switch keyCode {
            case 126: // Up arrow
                game.keyPressed.insert("up")
            case 125: // Down arrow
                game.keyPressed.insert("down")
            case 123: // Left arrow
                game.keyPressed.insert("left")
            case 124: // Right arrow
                game.keyPressed.insert("right")
            default:
                super.keyDown(with: event)
            }
        }
    }
    
    override func keyUp(with event: NSEvent) {
        let key = event.characters?.lowercased() ?? ""
        let keyCode = Int(event.keyCode)
        
        game.keyPressed.remove(key)
        
        // Handle arrow keys by keyCode
        switch keyCode {
        case 126: // Up arrow
            game.keyPressed.remove("up")
        case 125: // Down arrow
            game.keyPressed.remove("down")
        case 123: // Left arrow
            game.keyPressed.remove("left")
        case 124: // Right arrow
            game.keyPressed.remove("right")
        default:
            break
        }
    }
}

// MARK: - Main SwiftUI View
struct PalletTownMacOSApp: View {
    @StateObject private var game = PalletTownGame()
    
    var body: some View {
        ZStack {
            Color(red: 0.1, green: 0.1, blue: 0.18)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                Text("🏘️ Pallet Town")
                    .font(.system(size: 32, weight: .bold, design: .default))
                    .foregroundColor(.white)
                
                Text("Pokémon - Top-Down View")
                    .font(.system(size: 14, design: .default))
                    .foregroundColor(.cyan)
                
                GameCanvasView(game: game)
                    .frame(height: 600)
                    .border(Color.white, width: 3)
                    .onAppear {
                        game.startGameLoop()
                        NSApp.mainWindow?.makeFirstResponder(NSApp.mainWindow?.contentView)
                    }
                
                VStack(alignment: .leading, spacing: 10) {
                    Text("Controls")
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundColor(.cyan)
                    
                    Text("WASD or Arrow Keys to move • R to reset")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(.white)
                }
                .padding()
                .background(Color.black.opacity(0.5))
                .cornerRadius(8)
                
                HStack(spacing: 20) {
                    Text("FPS: \(game.fps)")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(.green)
                    
                    Text(game.positionText)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(.green)
                }
                .padding()
                .background(Color.black.opacity(0.7))
                .cornerRadius(8)
                
                Spacer()
            }
            .padding()
        }
        .frame(minWidth: 900, minHeight: 800)
    }
}

// Preview
#Preview {
    PalletTownMacOSApp()
}
