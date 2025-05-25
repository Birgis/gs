package main

import (
	"fmt"
	"log"
	"net/http"
	"os"

	"github.com/Birgis/gs/pkg/db"
	"github.com/Birgis/gs/pkg/handlers"
	"github.com/joho/godotenv"
)

func withCORS(h http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Access-Control-Allow-Origin", "*")
		w.Header().Set("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
		w.Header().Set("Access-Control-Allow-Headers", "Content-Type, Authorization")
		if r.Method == "OPTIONS" {
			w.WriteHeader(http.StatusOK)
			return
		}
		h.ServeHTTP(w, r)
	})
}

func main() {
	if err := godotenv.Load(); err != nil {
		log.Printf("Warning: .env file not found")
	}

	db.Init()

	port := os.Getenv("PORT")
	if port == "" {
		port = "6060"
	}

	mux := http.NewServeMux()

	mux.HandleFunc("/api/register", handlers.Register)
	mux.HandleFunc("/api/login", handlers.Login)
	mux.HandleFunc("/api/protected", handlers.Protected)
	mux.HandleFunc("/api/invite", handlers.CreateInvite)
	mux.HandleFunc("/api/public", handlers.Public)
	mux.HandleFunc("/api/invites", handlers.ListInvites)

	addr := fmt.Sprintf(":%s", port)
	log.Printf("Server listening on %s", addr)
	if err := http.ListenAndServe(addr, withCORS(mux)); err != nil {
		log.Fatalf("Error starting server: %v", err)
	}
}
