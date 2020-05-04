import "input" for Keyboard, Mouse, GamePad
import "graphics" for Canvas, Color, ImageData, Point, Font
import "audio" for AudioEngine
import "random" for Random
import "dome" for Process, Window
import "io" for FileSystem
import "math" for Math, Vector

/*

Color tinting:

var c = Color.rgb(255, 0, 0, 128) // This makes a translucent color
yourSprite.draw(x, y)
yourSprite.transform({"mode": "MONO", "foreground": c, "background": Color.none}).draw(x, y)

*/

class Assets {
    static load() {
        __assets = {}

        H.loadFont("Courier New", 32)
        H.loadFont("Courier New", 44)
    }

    static get(name) {
        return __assets[name]
    }
}

// Helper
class H {

    static init() {
        __random = Random.new()
    }
    
    static loadFont(name, size) {
        Font.load(name + " %(size)", name + ".ttf", size)
        getFont(name, size).antialias = true
    }

    static loadFont(name, size, antialias) {
        Font.load(name + " %(size)", name, size)
        getFont(name, size).antialias = antialias
    }

    static loadFont(name, size, filename, antialias) {
        Font.load(name + " %(size)", filename, size)
        getFont(name, size).antialias = antialias
    }

    static getFont(name, size) {
        return Font[name + " %(size)"]
    }

    static rand { __random }

    static map(value, start1, stop1, start2, stop2) {
        return start2 + (stop2 - start2) * ((value - start1) / (stop1 - start1))
    }

    static distance(vec1, vec2) {
        var dx = vec1.x - vec2.x
        var dy = vec1.y - vec2.y
        return Math.sqrt(dx * dx + dy * dy)
    }

    static distance(x1, y1, x2, y2) {
        var dx = x1 - x2
        var dy = x2 - x1
        return Math.sqrt(dx * dy + dy * dy)
    }

    static delta { 1/ 60 }
}

// Particles

class ParticleEffects {
    static basicExplosion {
        return {
            "lifespan": 3,
            "minAccX": -1,
            "maxAccX": 1,
            "minAccY": -1,
            "maxAccY": 1,
            "speed": 1,
            "maxParticles": 32,
            "maxSize": 25,
            "minSize": 10,
            "deadSize": 0
        }
    }
}

class Particle {
    construct new(settings, position) {
        _settings = settings
        _position = position
        _lifespan = settings["lifespan"]
        _iLifespan = _lifespan
        var accX = H.rand.float(settings["minAccX"], settings["maxAccX"])
        var accY = H.rand.float(settings["minAccY"], settings["maxAccY"])
        _acc = Vector.new(accX, accY)
        _size = H.rand.float(settings["minSize"], settings["maxSize"])
        _iSize = _size
        _dead = false
    }

    dead { _dead }

    update() {
        _lifespan = _lifespan - H.delta
        _size = H.map(_lifespan, _iLifespan, 0, _iSize, _settings["deadSize"])

        _position = _position + _acc * _settings["speed"]

        if (_lifespan < 0) {
            _dead = true
            return
        }
    }

    draw() {
        if (Camera.bounds.contains(_position.x, _position.y)) {
            Canvas.circlefill(_position.x, _position.y, _size, Color.red)
        }
    }
}

class ParticleSystem {

    // It is better to emit particles and then update them
    
    construct new(settings) {
        _particles = []
        _settings = settings
    }

    settings = (value) { _settings = value }
    settings { _settings }

    particles = (value) { _particles = value }
    particles { _particles }

    emit(position, amount) {
        for (i in 0..amount) {
            if (_particles.count < _settings["maxParticles"]) {
                _particles.add(Particle.new(_settings, position))
            }
        }
    }

    update() {
        // Update and remove dead particles
        _particles = _particles.where { |particle|
            particle.update()
            return !particle.dead
        }.toList
    }

    draw() {

        Canvas.print("Particles Count: %(_particles.count)", -200, 100, Color.white)

        for (p in _particles) {
            p.draw()
        }
    }
}

// Animation Stuff
class Spritesheet {
    construct new(texture, frameWidth, frameHeight) {
        _texture = texture
        _frameWidth = frameWidth
        _frameHeight = frameHeight
    }

    texture { _texture }

    frameWidth { _frameWidth }
    frameHeight { _frameHeight }

    rows { texture.width / _frameWidth }
    columns { texture.height / _frameHeight }
}

class Animation {
    construct new(spritesheet, row, column, length, duration) {
        _loopMode = LoopMode.loop
        _spritesheet = spritesheet
        _row = row
        _column = column
        _length = length
        _duration = duration
        _dir = 1
        _currentFrame = row
        _switchCd = frameDuration
        _scale = Vector.new(1, 1)
    }

    loopMode { _loopMode }
    spritesheet { _spritesheet }

    duration = (value) { _duration = value }
    duration { _duration }

    frameDuration { duration / _length }

    textureRect {
        return Rectangle.new(_currentFrame * _spritesheet.frameWidth, _column * _spritesheet.frameHeight, spritesheet.frameWidth, spritesheet.frameHeight)
    }

    scale = (value) { _scale = value }
    scale { _value }

    update() {
        _switchCd = _switchCd - H.delta

        if (_switchCd < 0) {
            _switchCd = frameDuration
            
            if (_loopMode == LoopMode.loop) {
                _currentFrame = _currentFrame + 1
                if (_currentFrame >= _row + _length) {
                    _currentFrame = _row
                }
            } else if (_loopMode = LoopMode.loopReverse) {
                _currentFrame = _currentFrame + _dir
                if (_currentFrame == _row + _length + 1 || _currentFrame == _row) {
                    _dir = _dir * 1
                }
            } else if (_loopMode = LoopMode.once && _currentFrame < _row + _length) {
                _currentFrame = _currentFrame + 1
            }
        }
    }
    
    draw(position) {
        _spritesheet.texture.transform({
            "srcX": textureRect.x,
            "srcY": textureRect.y,
            "srcW": textureRect.w,
            "srcH": textureRect.h,
            "scaleX": _scale.x,
            "scaleY": _scale.y
        }).draw(position.x, position.y)
    }
}

class LoopMode {
    static once { 1 }
    static loop { 2 }
    static loopReverse { 3 }
}

// Rectangles / Collision
class Rectangle {
    construct new(x, y, w, h) {
        _x = x
        _y = y
        _w = w
        _h = h

        _debugColor = Color.red
    }

    debugColor = (value) { _debugColor = value }
    debugColor { _debugColor }

    contains(x, y) {
        return (x >= _x && x <= right && y >= _y && y <= bottom)
    }

    construct withCenter(x, y, w, h) {
        _x = x - w / 2
        _y = y - h / 2
        _w = w
        _h = h
        _debugColor = Color.red
    }

    construct fromVector(vec, w, h) {
        _x = vec.x
        _y = vec.y
        _w = w
        _h = h
        _debugColor = Color.red
    }

    construct fromVectorWithCenter(vec, w, h) {
        _x = vec.x - w / 2
        _y = vec.y - h / 2
        _w = w
        _h = h
        _debugColor = Color.red
    }

    construct square(x, y, s) {
        _x = x
        _y = y
        _w = s
        _h = s
        _debugColor = Color.red
    }

    construct squareFromVector(vec, s) {
        _x = vec.x
        _y = vec.y
        _w = s
        _h = s
        _debugColor = Color.red
    }

    construct squareWithCenter(x, y, s) {
        _x = x - s / 2
        _y = y - s / 2
        _w = s
        _h = s
        _debugColor = Color.red
    }

    construct squareFromVectorWithCenter(vec, s) {
        _x = vec.x - s / 2
        _y = vec.y - s / 2
        _w = s
        _h = s
        _debugColor = Color.red
    }

    x = (value) { _x = value }
    x { _x }
    y = (value) { _y = value }
    y { _y }
    w = (value) { _w = value }
    w { _w }
    h = (value) { _h = value }
    h { _h }

    left { _x }
    top { _y }
    right { _x + _w }
    bottom { _y + _h }

    center {
        return Vector.new(_x + _w / 2, _y + _h / 2)
    }

    debug() {
        Canvas.rect(_x, _y, _w, _h, _debugColor)
    }

    fill(color) {
        Canvas.rectfill(x, y, w, h, color)
    }

    stroke(color) {
        Canvas.rect(x, y, w, h, color)
    }

    interstects(rect) {
        return !(rect.left > right || rect.right < left || rect.top > bottom || rect.bottom < top)
    }

    collides(rect) {
        var w1 = 0.5 * (_w + rect.w)
        var h1 = 0.5 * (_h + rect.h)
        var dx = center.x - rect.center.x
        var dy = center.y - rect.center.y

        if (interstects(rect)) {
            var wy = w1 * dy
            var hx = h1 * dx

            if (wy > hx) {
                if (wy > -hx) {
                    return CollisionSide.top
                } else {
                    return CollisionSide.right
                }
            } else {
                if (wy > -hx) {
                    return CollisionSide.left
                } else {
                    return CollisionSide.bottom
                }
            }
        } else {
            return CollisionSide.none
        }
    }
}

class CollisionSide {
    static left { 1 }
    static right { 2 }
    static top { 3 }
    static bottom { 4 }
    static none { 5 }
}

// Other shit
class Camera {
    static init() {
        __position = Vector.new()
        __bounds = Rectangle.fromVectorWithCenter(__position, Canvas.width, Canvas.height)
    }

    static position = (value) { 
        __position = Vector.new(value.x - __bounds.w / 2, value.y - __bounds.h / 2)
        __bounds = Rectangle.fromVector(__position, Canvas.width, Canvas.height)
    }
    static position { __position }

    static bounds { __bounds }

    static begin() {
        Canvas.offset(-Camera.position.x, -Camera.position.y)
    }

    static end() {
        Canvas.offset()
    }
}

class Screen {
    init() {}
    update() {}
    draw() {}
    onEnter() {}
    onExit() {}
}

// UI Stuff

// use Button.text.value to get text (string)
class Button {
    construct new(textValue, x, y, action) {
        _text = Text.new(textValue, x, y)
        _text.align = TextAlign.center
        _action = action
        _fillRect = false
        _color = Color.white
        _hoverColor = Color.red
        _boundsOffset = 10

        _lastPressed = false
    }

    boundsOffset = (value) { 
        _boundsOffset = value
        _minBoundsOffset = value
    }
    boundsOffset { _boundsOffset }

    text = (value) { _text = value }
    text { _text }

    action = (value) { _action = value }
    action { _action }

    bounds { 
        if (_text.align == TextAlign.left) {
            return Rectangle.new(_text.x - _boundsOffset / 2, _text.y - boundsOffset, _text.textWidth + boundsOffset, _text.fontSize + _boundsOffset)
        } else if (_text.align == TextAlign.right) {
            return Rectangle.new(_text.x - _text.textWidth - boundsOffset / 2, _text.y - boundsOffset, _text.textWidth + boundsOffset, _text.fontSize + boundsOffset)
        } else if (_text.align == TextAlign.center) {
            return Rectangle.withCenter(_text.x, _text.y + boundsOffset, _text.textWidth + _boundsOffset, _text.fontSize + _boundsOffset)
        }
    }

    color = (value) { _color = value }
    color { _color }
    hoverColor = (value) { _hoverColor = value }
    hoverColor { _hoverColor }

    fillRect = (value) { _fillRect = value }
    fillRect { _fillRect }

    isHover {
        return bounds.contains(Mouse.x, Mouse.y)
    }

    update() {
        if (isHover && _lastPressed && Mouse.isButtonPressed("left")) {
            _action.call()
        }
        _lastPressed = Mouse.isButtonPressed("left")
    }

    draw() {
        var col = isHover ? _hoverColor : _color
        if (_fillRect) {
            bounds.fill(col)
        } else {
            bounds.stroke(col)
        }
        _text.draw()
    }
}

// Text
class TextAlign {
    static left { 1 }
    static right { 2 }
    static center { 3 }
}

// Text measurement is approximated
// Change font size too if you change fontName
class Text {
    construct new(text, x, y) {
        _text = text
        _align = TextAlign.left
        _x = x
        _y = y
        _fontName = "Courier New"
        _fontSize = 32
        _color = Color.white
    }

    align = (value) { _align = value }
    align { _align }

    value = (val) { _text = val }
    value { _text }

    color = (value) { _color = value }
    color { _color }

    fontName = (value) { _fontName = value }
    fontName { _fontName }

    fontSize = (value) { _fontSize = value }
    fontSize { _fontSize }

    textWidth { _fontSize * value.count * 0.63 }

    bounds { Rectangle.new(_x, _y * 0.96, textWidth, _fontSize)}

    x { _x }
    y { _y }
    x = (value) { _x = value }
    y = (value) { _y = value }

    draw() {
        var font = H.getFont(_fontName, _fontSize)

        if (_align == TextAlign.left) {
            font.print(_text, _x, _y, _color)
        } else if (_align == TextAlign.right) {
            font.print(_text, _x - textWidth, _y, _color)
        } else if (_align == TextAlign.center) {
            font.print(_text, _x - textWidth / 2, _y, _color)
        }

    }
}

// ECS

class ECS {
    static init() {
        __count = 0
        __entities = []
    }

    static count = (value) { __count = value }
    static count { __count }

    static entities = (value) { __entities = value }
    static entities { __entities }
}

class Entity {
    construct new() {
        _id = "%(ECS.count)"
        _components = {}
    }

    id { _id }
    components { _components }

    addComponent(component) {
        _components[component.name] = component
    }

    removeComponent(componentName) {
        _components.remove(componentName)
    }
}