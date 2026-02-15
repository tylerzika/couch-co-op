import SwiftUI
import GameController
import AppKit

@main
struct PalletTownApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 900, minHeight: 800)
        }
    }
}

struct ContentView: View {
    @StateObject private var game = PalletTownGame()
    
    var body: some View {
        ZStack {
            Color(red: 0.1, green: 0.1, blue: 0.18)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                Text("🏘️ Pallet Town")
                    .font(.system(size: 32, weight: .bold, design: .default))
                    .foregroundColor(.white)
                
                Text("Grid Movement with Controller Support")
                    .font(.system(size: 14, design: .default))
                    .foregroundColor(.cyan)
                
                GameCanvasView(game: game)
                    .frame(width: 800, height: 600)
                    .border(Color.white, width: 3)
                    .onAppear {
                        game.startGameLoop()
                    }
                
                VStack(alignment: .leading, spacing: 10) {
                    Text("Controls")
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundColor(.cyan)
                    
                    Text("D-Pad or Analog Stick: Move | Y or R: Reset")
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
                    
                    Text("Pos: (\(Int(game.player.x)), \(Int(game.player.y)))")
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
    }
}

// MARK: - Game Canvas View
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
        
        // Draw terrain
        for y in 0..<mapHeight {
            for x in 0..<mapWidth {
                let screenX = (CGFloat(x) - cameraX) * tileSize
                let screenY = (CGFloat(y) - cameraY) * tileSize
                
                if screenX + tileSize > 0 && screenX < canvasWidth &&
                   screenY + tileSize > 0 && screenY < canvasHeight {
                    drawGrassTile(ctx, x: screenX, y: screenY)
                }
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
    
    func drawPlayer(_ ctx: CGContext, x: CGFloat, y: CGFloat) {
        let animFrame = game.player.animationFrame
        let legSwing = sin((CGFloat(animFrame) / 60.0) * CGFloat.pi * 2) * 2
        
        switch game.player.direction {
        case .down:
            drawPlayerSouth(ctx, x: x, y: y, legSwing: legSwing)
        case .up:
            drawPlayerNorth(ctx, x: x, y: y, legSwing: legSwing)
        case .left:
            drawPlayerWest(ctx, x: x, y: y, legSwing: legSwing)
        case .right:
            drawPlayerEast(ctx, x: x, y: y, legSwing: legSwing)
        }
    }
    
    func drawPlayerSouth(_ ctx: CGContext, x: CGFloat, y: CGFloat, legSwing: CGFloat) {
        // Skin head
        ctx.setFillColor(NSColor(red: 1.0, green: 0.86, blue: 0.67, alpha: 1.0).cgColor)
        ctx.fillEllipse(in: CGRect(x: x + 10, y: y + 2, width: 12, height: 12))
        
        // Brown hair
        ctx.setFillColor(NSColor(red: 0.55, green: 0.27, blue: 0.07, alpha: 1.0).cgColor)
        ctx.fill(CGRect(x: x + 10, y: y + 2, width: 12, height: 6))
        
        // Red shirt
        ctx.setFillColor(NSColor(red: 1.0, green: 0.42, blue: 0.42, alpha: 1.0).cgColor)
        ctx.fill(CGRect(x: x + 6, y: y + 14, width: 20, height: 14))
        
        // Black shorts
        ctx.setFillColor(NSColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1.0).cgColor)
        ctx.fill(CGRect(x: x + 8, y: y + 26, width: 16, height: 4))
        
        // Legs
        ctx.setFillColor(NSColor(red: 1.0, green: 0.86, blue: 0.67, alpha: 1.0).cgColor)
        ctx.fill(CGRect(x: x + 8, y: y + 30, width: 6, height: 8 + legSwing))
        ctx.fill(CGRect(x: x + 18, y: y + 30, width: 6, height: 8 - legSwing))
        
        // Feet
        ctx.setFillColor(NSColor(red: 1.0, green: 0.55, blue: 0.0, alpha: 1.0).cgColor)
        ctx.fill(CGRect(x: x + 8, y: y + 38 + legSwing, width: 6, height: 3))
        ctx.fill(CGRect(x: x + 18, y: y + 38 - legSwing, width: 6, height: 3))
        
        // Eyes
        ctx.setFillColor(NSColor.black.cgColor)
        ctx.fillEllipse(in: CGRect(x: x + 12, y: y + 5, width: 3, height: 3))
        ctx.fillEllipse(in: CGRect(x: x + 17, y: y + 5, width: 3, height: 3))
    }
    
    func drawPlayerNorth(_ ctx: CGContext, x: CGFloat, y: CGFloat, legSwing: CGFloat) {
        // Brown hair
        ctx.setFillColor(NSColor(red: 0.55, green: 0.27, blue: 0.07, alpha: 1.0).cgColor)
        ctx.fillEllipse(in: CGRect(x: x + 10, y: y + 2, width: 12, height: 12))
        
        // Red shirt
        ctx.setFillColor(NSColor(red: 1.0, green: 0.42, blue: 0.42, alpha: 1.0).cgColor)
        ctx.fill(CGRect(x: x + 6, y: y + 14, width: 20, height: 14))
        
        // Black shorts
        ctx.setFillColor(NSColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1.0).cgColor)
        ctx.fill(CGRect(x: x + 8, y: y + 26, width: 16, height: 4))
        
        // Legs
        ctx.setFillColor(NSColor(red: 1.0, green: 0.86, blue: 0.67, alpha: 1.0).cgColor)
        ctx.fill(CGRect(x: x + 8, y: y + 30, width: 6, height: 8 + legSwing))
        ctx.fill(CGRect(x: x + 18, y: y + 30, width: 6, height: 8 - legSwing))
        
        // Feet
        ctx.setFillColor(NSColor(red: 1.0, green: 0.55, blue: 0.0, alpha: 1.0).cgColor)
        ctx.fill(CGRect(x: x + 8, y: y + 38 + legSwing, width: 6, height: 3))
        ctx.fill(CGRect(x: x + 18, y: y + 38 - legSwing, width: 6, height: 3))
    }
    
    func drawPlayerWest(_ ctx: CGContext, x: CGFloat, y: CGFloat, legSwing: CGFloat) {
        // Skin head
        ctx.setFillColor(NSColor(red: 1.0, green: 0.86, blue: 0.67, alpha: 1.0).cgColor)
        ctx.fillEllipse(in: CGRect(x: x + 6, y: y + 2, width: 12, height: 12))
        
        // Brown hair
        ctx.setFillColor(NSColor(red: 0.55, green: 0.27, blue: 0.07, alpha: 1.0).cgColor)
        ctx.fill(CGRect(x: x + 4, y: y + 2, width: 8, height: 8))
        
        // Red shirt
        ctx.setFillColor(NSColor(red: 1.0, green: 0.42, blue: 0.42, alpha: 1.0).cgColor)
        ctx.fill(CGRect(x: x + 6, y: y + 14, width: 20, height: 14))
        
        // Black shorts
        ctx.setFillColor(NSColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1.0).cgColor)
        ctx.fill(CGRect(x: x + 8, y: y + 26, width: 16, height: 4))
        
        // Legs
        ctx.setFillColor(NSColor(red: 1.0, green: 0.86, blue: 0.67, alpha: 1.0).cgColor)
        ctx.fill(CGRect(x: x + 10, y: y + 30, width: 5, height: 8 + legSwing))
        ctx.fill(CGRect(x: x + 17, y: y + 30, width: 5, height: 8 - legSwing))
        
        // Feet
        ctx.setFillColor(NSColor(red: 1.0, green: 0.55, blue: 0.0, alpha: 1.0).cgColor)
        ctx.fill(CGRect(x: x + 10, y: y + 38 + legSwing, width: 5, height: 3))
        ctx.fill(CGRect(x: x + 17, y: y + 38 - legSwing, width: 5, height: 3))
        
        // Eye
        ctx.setFillColor(NSColor.black.cgColor)
        ctx.fillEllipse(in: CGRect(x: x + 8, y: y + 5, width: 3, height: 3))
    }
    
    func drawPlayerEast(_ ctx: CGContext, x: CGFloat, y: CGFloat, legSwing: CGFloat) {
        // Skin head
        ctx.setFillColor(NSColor(red: 1.0, green: 0.86, blue: 0.67, alpha: 1.0).cgColor)
        ctx.fillEllipse(in: CGRect(x: x + 14, y: y + 2, width: 12, height: 12))
        
        // Brown hair
        ctx.setFillColor(NSColor(red: 0.55, green: 0.27, blue: 0.07, alpha: 1.0).cgColor)
        ctx.fill(CGRect(x: x + 20, y: y + 2, width: 8, height: 8))
        
        // Red shirt
        ctx.setFillColor(NSColor(red: 1.0, green: 0.42, blue: 0.42, alpha: 1.0).cgColor)
        ctx.fill(CGRect(x: x + 6, y: y + 14, width: 20, height: 14))
        
        // Black shorts
        ctx.setFillColor(NSColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1.0).cgColor)
        ctx.fill(CGRect(x: x + 8, y: y + 26, width: 16, height: 4))
        
        // Legs
        ctx.setFillColor(NSColor(red: 1.0, green: 0.86, blue: 0.67, alpha: 1.0).cgColor)
        ctx.fill(CGRect(x: x + 10, y: y + 30, width: 5, height: 8 - legSwing))
        ctx.fill(CGRect(x: x + 17, y: y + 30, width: 5, height: 8 + legSwing))
        
        // Feet
        ctx.setFillColor(NSColor(red: 1.0, green: 0.55, blue: 0.0, alpha: 1.0).cgColor)
        ctx.fill(CGRect(x: x + 10, y: y + 38 - legSwing, width: 5, height: 3))
        ctx.fill(CGRect(x: x + 17, y: y + 38 + legSwing, width: 5, height: 3))
        
        // Eye
        ctx.setFillColor(NSColor.black.cgColor)
        ctx.fillEllipse(in: CGRect(x: x + 22, y: y + 5, width: 3, height: 3))
    }
}

// MARK: - Game Model
enum PlayerDirection {
    case up, down, left, right
}

class PalletTownGame: NSObject, ObservableObject {
    @Published var player = PlayerState()
    @Published var fps = 60
    
    let tileSize: CGFloat = 32
    let mapWidth = 30
    let mapHeight = 25
    
    private var gameTimer: Timer?
    private var frameCount = 0
    private var lastFpsUpdate = Date()
    
    // Controller state
    private var gameController: GCGamepad?
    private var firstKey: String?
    private var repeatTimeout: Timer?
    private var repeatTimer: Timer?
    private let repeatDelay: Double = 0.3
    private let repeatInterval: Double = 0.12
    
    override init() {
        super.init()
        setupControllers()
    }
    
    func setupControllers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(controllerDidConnect),
            name: NSNotification.Name.GCControllerDidConnect,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(controllerDidDisconnect),
            name: NSNotification.Name.GCControllerDidDisconnect,
            object: nil
        )
        
        GCController.startWirelessControllerDiscovery()
        
        if let controller = GCController.controllers().first {
            attachController(controller)
        }
    }
    
    @objc func controllerDidConnect(notification: NSNotification) {
        if let controller = notification.object as? GCController {
            attachController(controller)
        }
    }
    
    @objc func controllerDidDisconnect(notification: NSNotification) {
        gameController = nil
        firstKey = nil
        stopRepeatTimers()
    }
    
    func attachController(_ controller: GCController) {
        guard let gamepad = controller.gamepad else { return }
        self.gameController = gamepad
        
        // D-Pad
        gamepad.dpad.up.pressedChangedHandler = { [weak self] _, isPressed, _ in
            if isPressed { self?.handleInput(.up) }
        }
        gamepad.dpad.down.pressedChangedHandler = { [weak self] _, isPressed, _ in
            if isPressed { self?.handleInput(.down) }
        }
        gamepad.dpad.left.pressedChangedHandler = { [weak self] _, isPressed, _ in
            if isPressed { self?.handleInput(.left) }
        }
        gamepad.dpad.right.pressedChangedHandler = { [weak self] _, isPressed, _ in
            if isPressed { self?.handleInput(.right) }
        }
        
        // Y button for reset
        gamepad.buttonY.pressedChangedHandler = { [weak self] _, isPressed, _ in
            if isPressed { self?.resetPlayer() }
        }
        
        // Left analog stick
        gamepad.leftThumbstick.valueChangedHandler = { [weak self] _, _ in
            guard let self = self else { return }
            let xValue = gamepad.leftThumbstick.xAxis.value
            let yValue = gamepad.leftThumbstick.yAxis.value
            
            // Deadzone
            let threshold: Float = 0.5
            if abs(xValue) > threshold || abs(yValue) > threshold {
                if abs(xValue) > abs(yValue) {
                    self.handleInput(xValue > 0 ? .right : .left)
                } else {
                    self.handleInput(yValue < 0 ? .down : .up)
                }
            }
        }
    }
    
    func handleInput(_ dir: PlayerDirection) {
        if firstKey == nil {
            firstKey = "active"
            
            let dirStr: String
            switch dir {
            case .up: dirStr = "up"
            case .down: dirStr = "down"
            case .left: dirStr = "left"
            case .right: dirStr = "right"
            }
            
            attemptGridMove(dir)
            
            // Start repeat timers
            repeatTimeout = Timer.scheduledTimer(withTimeInterval: repeatDelay, repeats: false) { [weak self] _ in
                self?.repeatTimer = Timer.scheduledTimer(withTimeInterval: self?.repeatInterval ?? 0.12, repeats: true) { [weak self] _ in
                    self?.attemptGridMove(dir)
                }
            }
        }
    }
    
    func resetControllerInput() {
        firstKey = nil
        stopRepeatTimers()
    }
    
    private func stopRepeatTimers() {
        repeatTimeout?.invalidate()
        repeatTimer?.invalidate()
        repeatTimeout = nil
        repeatTimer = nil
    }
    
    func attemptGridMove(_ dir: PlayerDirection) {
        let originalX = player.x
        let originalY = player.y
        
        var nx = originalX
        var ny = originalY
        
        switch dir {
        case .up:
            ny -= 1
            player.direction = .up
        case .down:
            ny += 1
            player.direction = .down
        case .left:
            nx -= 1
            player.direction = .left
        case .right:
            nx += 1
            player.direction = .right
        }
        
        // Clamp
        nx = max(0, min(nx, Int(mapWidth) - 1))
        ny = max(0, min(ny, Int(mapHeight) - 1))
        
        player.x = nx
        player.y = ny
        player.isMoving = (player.x != originalX || player.y != originalY)
        
        // Animate
        if player.isMoving {
            player.animationFrame = (player.animationFrame + 1) % 60
        }
    }
    
    func resetPlayer() {
        player.x = 4
        player.y = 12
        player.direction = .down
        player.animationFrame = 0
        resetControllerInput()
    }
    
    func startGameLoop() {
        gameTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) { [weak self] _ in
            DispatchQueue.main.async {
                self?.updateUI()
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
    }
    
    deinit {
        gameTimer?.invalidate()
        stopRepeatTimers()
        NotificationCenter.default.removeObserver(self)
    }
}

struct PlayerState {
    var x: Int = 4
    var y: Int = 12
    var direction: PlayerDirection = .down
    var isMoving: Bool = false
    var animationFrame: Int = 0
}

#Preview {
    ContentView()
}
