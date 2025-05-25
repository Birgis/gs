package db

import (
	"database/sql"
	"log"
	"os"

	_ "github.com/mattn/go-sqlite3"
)

var DB *sql.DB

func Init() {
	dbPath := os.Getenv("DB_PATH")
	if dbPath == "" {
		dbPath = "users.db"
	}

	var err error
	DB, err = sql.Open("sqlite3", dbPath)
	if err != nil {
		log.Fatalf("Error opening database: %v", err)
	}

	if err := DB.Ping(); err != nil {
		log.Fatalf("Error connecting to database: %v", err)
	}

	createTables()
	seedUsers()
}

func createTables() {
	_, err := DB.Exec(`
		CREATE TABLE IF NOT EXISTS users (
			id INTEGER PRIMARY KEY AUTOINCREMENT,
			email TEXT UNIQUE NOT NULL,
			username TEXT UNIQUE NOT NULL,
			password TEXT NOT NULL,
			role TEXT NOT NULL DEFAULT 'user'
		);
		CREATE TABLE IF NOT EXISTS invite_tokens (
			id INTEGER PRIMARY KEY AUTOINCREMENT,
			token TEXT UNIQUE NOT NULL,
			used BOOLEAN NOT NULL DEFAULT FALSE,
			created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
			created_by INTEGER NOT NULL,
			used_by INTEGER
		);
	`)
	if err != nil {
		log.Fatalf("Error creating tables: %v", err)
	}
}

func seedUsers() {
	// Check if users already exist
	var count int
	err := DB.QueryRow("SELECT COUNT(*) FROM users").Scan(&count)
	if err != nil {
		log.Printf("Error checking users: %v", err)
		return
	}

	if count > 0 {
		return // Users already exist, skip seeding
	}

	// Create admin user
	_, err = DB.Exec(`
		INSERT INTO users (email, username, password, role)
		VALUES (?, ?, ?, ?)
	`, "admin@admin.com", "admin", "admin", "admin")
	if err != nil {
		log.Printf("Error seeding admin user: %v", err)
	}

	// Create regular user
	_, err = DB.Exec(`
		INSERT INTO users (email, username, password, role)
		VALUES (?, ?, ?, ?)
	`, "user@user.com", "user", "user", "user")
	if err != nil {
		log.Printf("Error seeding regular user: %v", err)
	}

	log.Println("Database seeded with initial users")
}
