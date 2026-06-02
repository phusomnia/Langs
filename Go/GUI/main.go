package main

import (
	"runtime"

	"github.com/go-gl/glfw/v3.4/glfw"
)

func init() {
	runtime.LockOSThread()
}

func main() {
	if err := glfw.Init(); err != nil {
		panic(err)
	}
	defer glfw.Terminate()

	window, err := glfw.CreateWindow(800, 600, "test", nil, nil)
	if err != nil {
		panic(err)
	}

	window.MakeContextCurrent()

	for !window.ShouldClose() {
		glfw.PollEvents()
		window.SwapBuffers()
	}
}
