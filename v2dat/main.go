package main

import (
	"github.com/kenzok8/v2dat/cmd"
	_ "github.com/kenzok8/v2dat/cmd/unpack"
)

func main() {
	_ = cmd.RootCmd.Execute()
}
