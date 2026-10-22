package main

import (
	"fmt"
	"net/http"
	"os"
)

func main() {
	version := os.Getenv("APP_VERSION")
	if version == "" {
		version = "1.0.0"
	}
	host, _ := os.Hostname()

	http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		fmt.Fprintf(w, "hello from %s (version %s)\n", host, version)
	})
	http.HandleFunc("/healthz", func(w http.ResponseWriter, r *http.Request) {
		fmt.Fprint(w, "{\"status\":\"ok\"}\n")
	})

	http.ListenAndServe(":8000", nil)
}
