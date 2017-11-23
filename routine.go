package main

import (
	"fmt"
	"sync"
)

var wg = sync.WaitGroup{}

func sayHi(to string) {
	fmt.Println("Hi", to)
	wg.Done()
}

func main() {
	for i := 0; i < 100; i++ {
		wg.Add(1)
		go sayHi(fmt.Sprintf("go routine %d", i))
	}
	wg.Wait()
}
