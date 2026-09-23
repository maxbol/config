package main

import "fmt"

func square(x int) int { return x * x }

func SumSquares(n int) int {
	acc := 0
	for i := 0; i < n; i++ {
		acc += square(i)
	}
	return acc
}

func main() { fmt.Println(SumSquares(10)) }
