package auth

import (
	"crypto/rand"
	"crypto/sha256"
	"encoding/base64"
	"encoding/hex"
	"os"
	"time"

	"github.com/Birgis/gs/pkg/db"
	"github.com/golang-jwt/jwt/v5"
)

type Claims struct {
	UserID int64 `json:"user_id"`
	jwt.RegisteredClaims
}

func GenerateToken(userID int64) (string, error) {
	secret := os.Getenv("JWT_SECRET")
	if secret == "" {
		secret = "your-secret-key"
	}

	claims := Claims{
		UserID: userID,
		RegisteredClaims: jwt.RegisteredClaims{
			ExpiresAt: jwt.NewNumericDate(time.Now().Add(24 * time.Hour)),
			IssuedAt:  jwt.NewNumericDate(time.Now()),
		},
	}

	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	return token.SignedString([]byte(secret))
}

func ValidateToken(tokenString string) (*Claims, error) {
	secret := os.Getenv("JWT_SECRET")
	if secret == "" {
		secret = "your-secret-key"
	}

	token, err := jwt.ParseWithClaims(tokenString, &Claims{}, func(token *jwt.Token) (interface{}, error) {
		return []byte(secret), nil
	})

	if err != nil {
		return nil, err
	}

	if claims, ok := token.Claims.(*Claims); ok && token.Valid {
		return claims, nil
	}

	return nil, jwt.ErrSignatureInvalid
}

func HashPassword(password string) (string, error) {
	hash := sha256.Sum256([]byte(password))
	return base64.StdEncoding.EncodeToString(hash[:]), nil
}

func VerifyPassword(password, hash string) bool {
	hashedPassword, _ := HashPassword(password)
	return hashedPassword == hash
}

func GenerateInviteToken() string {
	bytes := make([]byte, 16)
	rand.Read(bytes)
	return hex.EncodeToString(bytes)
}

func ValidateInviteToken(token string) (bool, error) {
	var used bool
	err := db.DB.QueryRow("SELECT used FROM invite_tokens WHERE token = ?", token).Scan(&used)
	if err != nil {
		return false, err
	}
	return !used, nil
}

func MarkInviteTokenAsUsed(token string) error {
	_, err := db.DB.Exec("UPDATE invite_tokens SET used = TRUE WHERE token = ?", token)
	return err
}

func CreateInviteToken() (string, error) {
	token := GenerateInviteToken()

	_, err := db.DB.Exec("INSERT INTO invite_tokens (token) VALUES (?)", token)
	if err != nil {
		return "", err
	}

	return token, nil
}
