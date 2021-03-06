package main

import (
	"github.com/banthar/Go-SDL/sdl"
	"github.com/banthar/gl"
	"github.com/shogg/glfps"
	"io/ioutil"
)

type vec3 [3]float32
type vec2 [2]float32

var (
	width, height = 640, 480
	prg0 = gl.Program(0)
	prg gl.Program

	vertices = []vec3 {
		{-1.3,-1.0,-1.0}, // 0      2--3
		{ 1.3,-1.0,-1.0}, // 1      |\ |
		{-1.3, 1.0,-1.0}, // 2      | \|
		{ 1.3, 1.0,-1.0}, // 3      0--1
	}

	texCoords = []vec2 {
		{ 0.0, 0.0}, // 0      2--3
		{ 1.3, 0.0}, // 1      |\ |
		{ 0.0, 1.0}, // 2      | \|
		{ 1.3, 1.0}, // 3      0--1
	}

	vertexShaderSrc = `
		varying vec2 vTexCoord;
		uniform vec2 resolution;
		uniform float time;

		void main()
		{
			vTexCoord = vec2(gl_MultiTexCoord0) * 2.0 - 1.0;
			gl_Position = ftransform();
		}`
)

func main() {
	sdl.Init(sdl.INIT_VIDEO)

	defer sdl.Quit()

	screen := sdl.SetVideoMode(width, height, 32, sdl.OPENGL)
	if screen == nil {
		panic("Couldn't set video mode: " + sdl.GetError() + "\n")
	}

	if err := gl.Init(); err != 0 {
		panic("gl error")
	}

	initGl()
	initShaders()
	mainLoop()
}

func initShaders() {

	// Compile vertex shader
	vshader := gl.CreateShader(gl.VERTEX_SHADER)
	vshader.Source(vertexShaderSrc)
	vshader.Compile()
	if vshader.Get(gl.COMPILE_STATUS) != gl.TRUE {
		panic("vertex shader compile error: " + vshader.GetInfoLog())
	}

	// Compile fragment shader
	fshader := gl.CreateShader(gl.FRAGMENT_SHADER)
	fragSrc, err := readShader("dist-field-raycaster.glsl")
	if err != nil {
		panic(err)
	}

	fshader.Source(fragSrc)
	fshader.Compile()
	if fshader.Get(gl.COMPILE_STATUS) != gl.TRUE {
		panic("fragment shader compile error: " + fshader.GetInfoLog())
	}

	// Link program
	prg = gl.CreateProgram()
	prg.AttachShader(vshader)
	prg.AttachShader(fshader)
	prg.Link()
	if prg.Get(gl.LINK_STATUS) != gl.TRUE {
		panic("linker error: " + prg.GetInfoLog())
	}

	prg.Use()
}

func readShader(filename string) (s string, err error) {

	data, err := ioutil.ReadFile(filename)
	if err != nil { return }

	s = string(data)
	return
}

func initGl() {

	h := float64(height) / float64(width)

	gl.Viewport(0, 0, width, height)
	gl.MatrixMode(gl.PROJECTION)
	gl.LoadIdentity()
	gl.Frustum(-1.0, 1.0, -h, h, 5.0, 60.0)

	gl.MatrixMode(gl.MODELVIEW)
	gl.LoadIdentity()
	gl.Translatef(0.0, 0.0, -6.0)

	gl.EnableClientState(gl.VERTEX_ARRAY)
	gl.EnableClientState(gl.TEXTURE_COORD_ARRAY)
	gl.VertexPointer(3, 0,	&vertices[0][0])
	gl.TexCoordPointer(2, 0, &texCoords[0][0])
}

func draw() {

	t := float32(sdl.GetTicks()) / 500.0
	time := prg.GetUniformLocation("time")
	time.Uniform1f(t)

	gl.Clear(gl.COLOR_BUFFER_BIT)

	gl.DrawArrays(gl.TRIANGLE_STRIP, 0, 4)
	if gl.GetError() != gl.NO_ERROR {
		panic("draw error")
	}
}

func drawOverlay() {
	prg0.Use()
	glfps.Draw(10, 10)
	prg.Use()
}

func mainLoop() {
	done := false
	for !done {
		for e := sdl.PollEvent(); e != nil; e = sdl.PollEvent() {
			switch e.(type) {
			case *sdl.QuitEvent:
				done = true
				break
			case *sdl.KeyboardEvent:
				key := e.(*sdl.KeyboardEvent).Keysym.Sym
				if key == sdl.K_RETURN {
					done = true
					break
				} else {
					handleKey(key)
				}
			}
		}

		draw()
		drawOverlay()
		sdl.GL_SwapBuffers()
	}
}

func handleKey(key uint32) {
	switch key {
	case sdl.K_LEFT:
	case sdl.K_RIGHT:
	case sdl.K_UP:
	case sdl.K_DOWN:
	}
}

