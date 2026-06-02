package main

import "fmt"

func add(a int, b int) int {
	return a + b
}

func control_flow() {
	const age = 14
	if age >= 18 {
		fmt.Println("Adult")
	} else {
		fmt.Println("Minor")
	}

	var nums []int = []int{1, 2, 3}

	// _ is index but it is ignored
	for _, value := range nums {
		fmt.Printf("%d ", value)
	}

	for i := 0; i < 10; i++ {
		fmt.Print(i, " ")
	}

	var score int = 100
	switch {
	case score >= 90:
		{
			fmt.Println("GRADE: A")
			break
		}
	case score >= 80:
		{
			fmt.Println("GRADE: A")
			break
		}
	}
}

func data_collection() {
	var arr [5]int
	arr = [5]int{1, 2, 3}
	fmt.Println(arr)
	fmt.Printf("Length: %d\n", len(arr))
	fmt.Printf("Capacity: %d\n", cap(arr))

	primes := []int{1, 3, 5}
	fmt.Printf("Primes: %v\n", primes)

	slice1 := []int{1, 2, 3}
	slice2 := make([]int, 5, 10)
	slice2 = append(slice2, 1)
	fmt.Print(slice1, slice1[:2], slice1[0:2], len(slice2), cap(slice2), "\n")

	// Maps
	// m1 := make(map[string]int)
	m2 := map[string]int{
		"apple": 1,
	}
	value := m2["apple"]
	fmt.Printf("%d\n", value)
	for key, value := range m2 {
		fmt.Printf("%s: %d\n", key, value)
	}
}

type Player struct {
	Id     int
	Name   string
	Health int
	Skill  []string
}

func shoot_ur_leg() {
	var p *int
	x := 42
	p = &x
	*p = 100
	fmt.Print(x, "\n")

	// new
	var p1 *int = new(int)
	y := 40
	*p1 = y
	fmt.Print(*p1, &y, p1, "\n")

	// struct
	pl := Player{Id: 1, Name: "abc", Health: 100}
	pl.Skill = append(pl.Skill, "Fireball", "Iceberg")
	fmt.Print(pl)
}


type Graph struct {
	adjMatrix [][]int
	size int
	visited []bool
}

func initGraph(size int) *Graph {
	matrix := make([][]int, size)
	for i := range matrix {
		matrix[i] = make([]int, size)
	}
	return &Graph { adjMatrix: matrix, size: size, visited: make([]bool, size)}
}

func (g *Graph) addEgde(u, v int) {
	g.adjMatrix[u][v] = 1
	g.adjMatrix[v][u] = 1
}

func (g *Graph) printGraph() {
	for i := 0; i < len(g.adjMatrix); i++ {
		for j := 0; j < len(g.adjMatrix[i]); j++ {
			fmt.Printf("%d ", g.adjMatrix[i][j])
		}
		fmt.Println()
	}
}

func (g *Graph) DFS(vertex int) {
	g.visited[vertex] = true
	fmt.Printf("Visited: %d ", vertex)

	for i:= 0; i < g.size; i++ {
		if g.adjMatrix[vertex][i] == 1 && !g.visited[i] {
			g.DFS(i)
		}
	}
}


func main() {
	// control_flow()
	// data_collection()
	// shoot_ur_leg()
	g := initGraph(5)
	g.addEgde(0,1)
	g.addEgde(0,2)
	g.addEgde(0,3)
	// g.addEgde(2,1)
	g.addEgde(2,4)
	g.printGraph()
	
	g.DFS(0)
}