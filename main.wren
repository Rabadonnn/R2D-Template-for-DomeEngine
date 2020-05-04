import "input" for Keyboard, Mouse, GamePad
import "graphics" for Canvas, Color, ImageData, Point, Font
import "audio" for AudioEngine
import "random" for Random
import "dome" for Process, Window
import "io" for FileSystem
import "math" for Math, Vector

import "./r2d" for Camera, Screen, Rectangle, H, Button, Assets, CollisionSide
import "./r2d" for Spritesheet, Animation, LoopMode
import "./r2d" for ParticleSystem, ParticleEffects
import "./r2d" for Text, TextAlign
import "./r2d" for ECS, Entity

class Game {
    static init() {
        Window.title = "R2D Game"
        Window.vsync = true

        __backgroundColor = Color.black

        __windowWidth = 800
        __windowHeight = 600
        resize()

        H.init()

        ECS.init()

        Camera.init()

        Assets.load()

        __currentScreenIndex = 0
        __screens = [ MainMenu.new(), GameScreen.new() ]
    }

    static windowWidth = (value) { __windowWidth = value }
    static windowWidth { __windowWidth }
    static windowHeight = (value) { __windowHeight = value }
    static windowHeight { __windowHeight }

    static backgroundColor = (value) { __backgroundColor = value }
    static backgroundColor { __backgroundColor }

    static currentScreenIndex = (value) { 
        __screens[__currentScreenIndex].onExit()
        __currentScreenIndex = value 
        __screens[__currentScreenIndex].onEnter()
    }
    static currentScreenIndex { __currentScreenIndex }

    static resize() {
        Window.resize(__windowWidth, __windowHeight)
        Canvas.resize(__windowWidth, __windowHeight)
    }

    static update() {
        if (Keyboard.isKeyDown("Escape")) {
            Process.exit()
        }

        __screens[__currentScreenIndex].update()
    }

    static draw(dt) {
        Canvas.cls(Color.black)
        __screens[__currentScreenIndex].draw()
    }
}

class GameScreen is Screen {
    construct new() {

    }

    update() {

    }

    draw() {

    }
}

class MainMenu is Screen {
    construct new() {
        __playButton = Button.new("Play", Game.windowWidth / 2, Game.windowHeight / 2, Fn.new {
            Game.currentScreenIndex = 1
        })
        __playButton.text.color = Color.yellow

        __titleText = Text.new("Rabadon Game Template", Canvas.width / 2, Canvas.height / 3)
        __titleText.align = TextAlign.center
        __titleText.color = Color.white
        __titleText.fontName = "Courier New"
        __titleText.fontSize = 44
    }

    update() {
        __playButton.update()
    }

    draw() {
        __playButton.draw()
        __titleText.draw()
    }
}
