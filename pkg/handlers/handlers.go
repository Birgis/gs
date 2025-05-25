package handlers

import (
	"database/sql"
	"encoding/json"
	"net/http"
	"strings"

	"github.com/Birgis/gs/pkg/auth"
	"github.com/Birgis/gs/pkg/db"
)

type RegisterRequest struct {
	Email       string `json:"email"`
	Username    string `json:"username"`
	Password    string `json:"password"`
	InviteToken string `json:"invite_token"`
}

type LoginRequest struct {
	EmailOrUsername string `json:"email_or_username"`
	Password        string `json:"password"`
}

type Response struct {
	Message string      `json:"message"`
	Data    interface{} `json:"data,omitempty"`
}

func Register(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	var req RegisterRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, "Invalid request body", http.StatusBadRequest)
		return
	}

	// Validate invite token
	var used bool
	err := db.DB.QueryRow("SELECT used FROM invite_tokens WHERE token = ?", req.InviteToken).Scan(&used)
	if err != nil {
		http.Error(w, "Invalid invite token", http.StatusBadRequest)
		return
	}
	if used {
		http.Error(w, "Invite token already used", http.StatusBadRequest)
		return
	}

	// Create user
	result, err := db.DB.Exec(`
		INSERT INTO users (email, username, password, role)
		VALUES (?, ?, ?, ?)
	`, req.Email, req.Username, req.Password, "user")
	if err != nil {
		http.Error(w, "Error creating user", http.StatusInternalServerError)
		return
	}

	// Mark invite token as used and set used_by
	_, err = db.DB.Exec("UPDATE invite_tokens SET used = TRUE, used_by = (SELECT id FROM users WHERE email = ?) WHERE token = ?", req.Email, req.InviteToken)
	if err != nil {
		http.Error(w, "Error updating invite token", http.StatusInternalServerError)
		return
	}

	userID, _ := result.LastInsertId()
	token, err := auth.GenerateToken(userID)
	if err != nil {
		http.Error(w, "Error generating token", http.StatusInternalServerError)
		return
	}

	json.NewEncoder(w).Encode(Response{
		Message: "User registered successfully",
		Data: map[string]interface{}{
			"token": token,
			"user": map[string]interface{}{
				"id":       userID,
				"email":    req.Email,
				"username": req.Username,
				"role":     "user",
			},
		},
	})
}

func Login(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	var req LoginRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, "Invalid request body", http.StatusBadRequest)
		return
	}

	var (
		userID   int64
		password string
		email    string
		username string
		role     string
	)
	err := db.DB.QueryRow(`
		SELECT id, password, email, username, role FROM users WHERE email = ? OR username = ?
	`, req.EmailOrUsername, req.EmailOrUsername).Scan(&userID, &password, &email, &username, &role)
	if err != nil {
		http.Error(w, "Invalid credentials", http.StatusUnauthorized)
		return
	}

	if password != req.Password {
		http.Error(w, "Invalid credentials", http.StatusUnauthorized)
		return
	}

	token, err := auth.GenerateToken(userID)
	if err != nil {
		http.Error(w, "Error generating token", http.StatusInternalServerError)
		return
	}

	json.NewEncoder(w).Encode(Response{
		Message: "Login successful",
		Data: map[string]interface{}{
			"token": token,
			"user": map[string]interface{}{
				"id":       userID,
				"email":    email,
				"username": username,
				"role":     role,
			},
		},
	})
}

func Public(w http.ResponseWriter, r *http.Request) {
	json.NewEncoder(w).Encode(Response{
		Message: "Welcome to GS!",
		Data: map[string]interface{}{
			"info": "This is a public endpoint. Register or login to access more features.",
			"links": map[string]string{
				"register": "/api/register",
				"login":    "/api/login",
			},
		},
	})
}

func Protected(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	token := r.Header.Get("Authorization")
	if token == "" {
		http.Error(w, "No token provided", http.StatusUnauthorized)
		return
	}
	if strings.HasPrefix(token, "Bearer ") {
		token = strings.TrimPrefix(token, "Bearer ")
	}

	claims, err := auth.ValidateToken(token)
	if err != nil {
		http.Error(w, "Invalid token", http.StatusUnauthorized)
		return
	}

	var email string
	var username string
	var role string
	err = db.DB.QueryRow("SELECT email, username, role FROM users WHERE id = ?", claims.UserID).Scan(&email, &username, &role)
	if err != nil {
		http.Error(w, "User not found", http.StatusNotFound)
		return
	}

	json.NewEncoder(w).Encode(Response{
		Message: "Protected endpoint accessed successfully",
		Data: map[string]interface{}{
			"user": map[string]interface{}{
				"id":       claims.UserID,
				"email":    email,
				"username": username,
				"role":     role,
			},
			"secret":    "This is some protected data only for logged-in users!",
			"timestamp": claims.IssuedAt.Unix(),
		},
	})
}

func CreateInvite(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	token := r.Header.Get("Authorization")
	if token == "" {
		http.Error(w, "No token provided", http.StatusUnauthorized)
		return
	}
	if strings.HasPrefix(token, "Bearer ") {
		token = strings.TrimPrefix(token, "Bearer ")
	}

	claims, err := auth.ValidateToken(token)
	if err != nil {
		http.Error(w, "Invalid token", http.StatusUnauthorized)
		return
	}

	var role string
	err = db.DB.QueryRow("SELECT role FROM users WHERE id = ?", claims.UserID).Scan(&role)
	if err != nil {
		http.Error(w, "User not found", http.StatusNotFound)
		return
	}

	if role != "admin" {
		http.Error(w, "Only admins can create invite tokens", http.StatusForbidden)
		return
	}

	inviteToken := auth.GenerateInviteToken()
	_, err = db.DB.Exec(`
		INSERT INTO invite_tokens (token, created_by)
		VALUES (?, ?)
	`, inviteToken, claims.UserID)
	if err != nil {
		http.Error(w, "Error creating invite token", http.StatusInternalServerError)
		return
	}

	json.NewEncoder(w).Encode(Response{
		Message: "Invite token created successfully",
		Data: map[string]string{
			"token": inviteToken,
		},
	})
}

func ListInvites(w http.ResponseWriter, r *http.Request) {
	// Auth: only admin
	token := r.Header.Get("Authorization")
	if token == "" {
		http.Error(w, "No token provided", http.StatusUnauthorized)
		return
	}
	if strings.HasPrefix(token, "Bearer ") {
		token = strings.TrimPrefix(token, "Bearer ")
	}
	claims, err := auth.ValidateToken(token)
	if err != nil {
		http.Error(w, "Invalid token", http.StatusUnauthorized)
		return
	}
	var role string
	err = db.DB.QueryRow("SELECT role FROM users WHERE id = ?", claims.UserID).Scan(&role)
	if err != nil || role != "admin" {
		http.Error(w, "Only admins can list invites", http.StatusForbidden)
		return
	}

	rows, err := db.DB.Query(`SELECT id, token, used, created_at, created_by, used_by FROM invite_tokens`)
	if err != nil {
		http.Error(w, "Error fetching invites", http.StatusInternalServerError)
		return
	}
	defer rows.Close()

	invites := []map[string]interface{}{}
	for rows.Next() {
		var id int64
		var token string
		var used bool
		var createdAt string
		var createdBy int64
		var usedBy sql.NullInt64
		if err := rows.Scan(&id, &token, &used, &createdAt, &createdBy, &usedBy); err != nil {
			continue
		}
		invite := map[string]interface{}{
			"id":         id,
			"token":      token,
			"used":       used,
			"created_at": createdAt,
			"created_by": createdBy,
			"used_by":    nil,
		}
		if usedBy.Valid {
			invite["used_by"] = usedBy.Int64
		}
		invites = append(invites, invite)
	}

	json.NewEncoder(w).Encode(Response{
		Message: "Invite list",
		Data:    invites,
	})
}
