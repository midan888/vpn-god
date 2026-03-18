package auth

import (
	"testing"
	"time"

	"github.com/golang-jwt/jwt/v5"
	"github.com/google/uuid"
)

func TestGenerateTokenPair(t *testing.T) {
	svc := NewJWTService("test-secret")
	userID := uuid.New()

	access, refresh, err := svc.GenerateTokenPair(userID)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if access == "" {
		t.Fatal("access token is empty")
	}
	if refresh == "" {
		t.Fatal("refresh token is empty")
	}
	if access == refresh {
		t.Fatal("access and refresh tokens should differ")
	}
}

func TestValidateAccessToken(t *testing.T) {
	svc := NewJWTService("test-secret")
	userID := uuid.New()

	access, _, err := svc.GenerateTokenPair(userID)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	got, err := svc.ValidateAccessToken(access)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if got != userID {
		t.Fatalf("expected user ID %s, got %s", userID, got)
	}
}

func TestValidateRefreshToken(t *testing.T) {
	svc := NewJWTService("test-secret")
	userID := uuid.New()

	_, refresh, err := svc.GenerateTokenPair(userID)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	got, err := svc.ValidateRefreshToken(refresh)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if got != userID {
		t.Fatalf("expected user ID %s, got %s", userID, got)
	}
}

func TestAccessTokenRejectedAsRefresh(t *testing.T) {
	svc := NewJWTService("test-secret")
	access, _, _ := svc.GenerateTokenPair(uuid.New())

	_, err := svc.ValidateRefreshToken(access)
	if err == nil {
		t.Fatal("expected error using access token as refresh token")
	}
}

func TestRefreshTokenRejectedAsAccess(t *testing.T) {
	svc := NewJWTService("test-secret")
	_, refresh, _ := svc.GenerateTokenPair(uuid.New())

	_, err := svc.ValidateAccessToken(refresh)
	if err == nil {
		t.Fatal("expected error using refresh token as access token")
	}
}

func TestWrongSecretRejected(t *testing.T) {
	svc1 := NewJWTService("secret-one")
	svc2 := NewJWTService("secret-two")

	access, _, _ := svc1.GenerateTokenPair(uuid.New())

	_, err := svc2.ValidateAccessToken(access)
	if err == nil {
		t.Fatal("expected error validating token with wrong secret")
	}
}

func TestExpiredTokenRejected(t *testing.T) {
	svc := NewJWTService("test-secret")
	userID := uuid.New()

	// Manually create an expired token
	claims := Claims{
		RegisteredClaims: jwt.RegisteredClaims{
			Subject:   userID.String(),
			IssuedAt:  jwt.NewNumericDate(time.Now().Add(-1 * time.Hour)),
			ExpiresAt: jwt.NewNumericDate(time.Now().Add(-30 * time.Minute)),
		},
		Type: "access",
	}
	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	signed, _ := token.SignedString(svc.secret)

	_, err := svc.ValidateAccessToken(signed)
	if err == nil {
		t.Fatal("expected error for expired token")
	}
}

func TestInvalidTokenStringRejected(t *testing.T) {
	svc := NewJWTService("test-secret")

	_, err := svc.ValidateAccessToken("not-a-real-token")
	if err == nil {
		t.Fatal("expected error for garbage token string")
	}
}
