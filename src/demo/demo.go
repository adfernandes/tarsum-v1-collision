package main

import (
	"fmt"
	"io"
	"os"

	"github.com/docker/docker/pkg/tarsum"
)

func die(msg error) {
	fmt.Println("error: %s", msg)
	os.Exit(-1)
}

func main() {
	ts, error := tarsum.NewTarSumForLabel(os.Stdin, true, "tarsum.v1+sha256")
	if error != nil {
		die(error)
	}
	buffer := make([]byte, 64*1024)
	for {
		_, error := ts.Read(buffer)
		if error != nil {
			if error == io.EOF {
				break
			} else {
				die(error)
			}
		}
	}
	sum := ts.Sum(nil)
	fmt.Println(sum)
}
