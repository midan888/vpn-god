package auth

import (
	"strings"
	"testing"
	"time"

	"github.com/golang-jwt/jwt/v5"
	"github.com/google/uuid"
)

// --- Helper: create a token with custom claims ---

func signToken(t *testing.T, svc *JWTService, claims Claims) string {
	t.Helper()
	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	signed, err := token.SignedString(svc.secret)
	if err != nil {
		t.Fatalf("sign token: %v", err)
	}
	return signed
}

func makeRefreshToken(t *testing.T, svc *JWTService, userID uuid.UUID, issuedAt, expiresAt time.Time) string {
	t.Helper()
	return signToken(t, svc, Claims{
		RegisteredClaims: jwt.RegisteredClaims{
			Subject:   userID.String(),
			IssuedAt:  jwt.NewNumericDate(issuedAt),
			ExpiresAt: jwt.NewNumericDate(expiresAt),
		},
		Type: "refresh",
	})
}

func makeAccessToken(t *testing.T, svc *JWTService, userID uuid.UUID, issuedAt, expiresAt time.Time, isAdmin bool) string {
	t.Helper()
	return signToken(t, svc, Claims{
		RegisteredClaims: jwt.RegisteredClaims{
			Subject:   userID.String(),
			IssuedAt:  jwt.NewNumericDate(issuedAt),
			ExpiresAt: jwt.NewNumericDate(expiresAt),
		},
		Type:    "access",
		IsAdmin: isAdmin,
	})
}

// --- GenerateTokenPair ---

func TestGenerateTokenPair(t *testing.T) {
	svc := NewJWTService("test-secret")
	userID := uuid.New()

	access, refresh, err := svc.GenerateTokenPair(userID, false)
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

func TestGenerateTokenPair_AdminFlag(t *testing.T) {
	svc := NewJWTService("test-secret")
	userID := uuid.New()

	access, _, err := svc.GenerateTokenPair(userID, true)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	// Admin access token should validate as admin
	got, err := svc.ValidateAdminAccessToken(access)
	if err != nil {
		t.Fatalf("expected admin token to validate: %v", err)
	}
	if got != userID {
		t.Fatalf("expected user ID %s, got %s", userID, got)
	}
}

func TestGenerateTokenPair_NonAdminRejectedByAdminValidation(t *testing.T) {
	svc := NewJWTService("test-secret")
	access, _, _ := svc.GenerateTokenPair(uuid.New(), false)

	_, err := svc.ValidateAdminAccessToken(access)
	if err == nil {
		t.Fatal("expected non-admin token to be rejected by admin validation")
	}
	if !strings.Contains(err.Error(), "admin access required") {
		t.Fatalf("expected 'admin access required' error, got: %v", err)
	}
}

// --- Basic validation ---

func TestValidateAccessToken(t *testing.T) {
	svc := NewJWTService("test-secret")
	userID := uuid.New()

	access, _, err := svc.GenerateTokenPair(userID, false)
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

	_, refresh, err := svc.GenerateTokenPair(userID, false)
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

// --- Token type confusion ---

func TestAccessTokenRejectedAsRefresh(t *testing.T) {
	svc := NewJWTService("test-secret")
	access, _, _ := svc.GenerateTokenPair(uuid.New(), false)

	_, err := svc.ValidateRefreshToken(access)
	if err == nil {
		t.Fatal("expected error using access token as refresh token")
	}
}

func TestRefreshTokenRejectedAsAccess(t *testing.T) {
	svc := NewJWTService("test-secret")
	_, refresh, _ := svc.GenerateTokenPair(uuid.New(), false)

	_, err := svc.ValidateAccessToken(refresh)
	if err == nil {
		t.Fatal("expected error using refresh token as access token")
	}
}

// --- Secret mismatch ---

func TestWrongSecretRejected(t *testing.T) {
	svc1 := NewJWTService("secret-one")
	svc2 := NewJWTService("secret-two")

	access, _, _ := svc1.GenerateTokenPair(uuid.New(), false)

	_, err := svc2.ValidateAccessToken(access)
	if err == nil {
		t.Fatal("expected error validating token with wrong secret")
	}
}

func TestWrongSecretRejected_RefreshToken(t *testing.T) {
	svc1 := NewJWTService("secret-one")
	svc2 := NewJWTService("secret-two")

	_, refresh, _ := svc1.GenerateTokenPair(uuid.New(), false)

	_, err := svc2.ValidateRefreshToken(refresh)
	if err == nil {
		t.Fatal("expected error validating refresh token with wrong secret")
	}
}

// --- Expiration ---

func TestExpiredAccessTokenRejected(t *testing.T) {
	svc := NewJWTService("test-secret")
	userID := uuid.New()

	signed := makeAccessToken(t, svc, userID,
		time.Now().Add(-1*time.Hour),
		time.Now().Add(-30*time.Minute),
		false,
	)

	_, err := svc.ValidateAccessToken(signed)
	if err == nil {
		t.Fatal("expected error for expired access token")
	}
}

func TestExpiredRefreshTokenRejected(t *testing.T) {
	svc := NewJWTService("test-secret")
	userID := uuid.New()

	signed := makeRefreshToken(t, svc, userID,
		time.Now().Add(-31*24*time.Hour),
		time.Now().Add(-1*24*time.Hour),
	)

	_, err := svc.ValidateRefreshToken(signed)
	if err == nil {
		t.Fatal("expected error for expired refresh token")
	}
}

// --- Token aging: simulate real-world "open app after N days" scenarios ---

func TestRefreshToken_ValidAfter2Days(t *testing.T) {
	svc := NewJWTService("test-secret")
	userID := uuid.New()

	// Token issued 2 days ago, expires in 28 days (30 - 2)
	signed := makeRefreshToken(t, svc, userID,
		time.Now().Add(-2*24*time.Hour),
		time.Now().Add(28*24*time.Hour),
	)

	got, err := svc.ValidateRefreshToken(signed)
	if err != nil {
		t.Fatalf("refresh token should be valid after 2 days: %v", err)
	}
	if got != userID {
		t.Fatalf("expected user ID %s, got %s", userID, got)
	}
}

func TestRefreshToken_ValidAfter7Days(t *testing.T) {
	svc := NewJWTService("test-secret")
	userID := uuid.New()

	signed := makeRefreshToken(t, svc, userID,
		time.Now().Add(-7*24*time.Hour),
		time.Now().Add(23*24*time.Hour),
	)

	got, err := svc.ValidateRefreshToken(signed)
	if err != nil {
		t.Fatalf("refresh token should be valid after 7 days: %v", err)
	}
	if got != userID {
		t.Fatalf("expected user ID %s, got %s", userID, got)
	}
}

func TestRefreshToken_ValidAfter29Days(t *testing.T) {
	svc := NewJWTService("test-secret")
	userID := uuid.New()

	signed := makeRefreshToken(t, svc, userID,
		time.Now().Add(-29*24*time.Hour),
		time.Now().Add(1*24*time.Hour),
	)

	got, err := svc.ValidateRefreshToken(signed)
	if err != nil {
		t.Fatalf("refresh token should be valid after 29 days: %v", err)
	}
	if got != userID {
		t.Fatalf("expected user ID %s, got %s", userID, got)
	}
}

func TestRefreshToken_ExpiredAfter31Days(t *testing.T) {
	svc := NewJWTService("test-secret")
	userID := uuid.New()

	signed := makeRefreshToken(t, svc, userID,
		time.Now().Add(-31*24*time.Hour),
		time.Now().Add(-1*24*time.Hour),
	)

	_, err := svc.ValidateRefreshToken(signed)
	if err == nil {
		t.Fatal("refresh token should be expired after 31 days")
	}
}

func TestAccessToken_ExpiredAfter16Minutes(t *testing.T) {
	svc := NewJWTService("test-secret")
	userID := uuid.New()

	signed := makeAccessToken(t, svc, userID,
		time.Now().Add(-16*time.Minute),
		time.Now().Add(-1*time.Minute),
		false,
	)

	_, err := svc.ValidateAccessToken(signed)
	if err == nil {
		t.Fatal("access token should be expired after 16 minutes")
	}
}

func TestAccessToken_ValidWithin15Minutes(t *testing.T) {
	svc := NewJWTService("test-secret")
	userID := uuid.New()

	signed := makeAccessToken(t, svc, userID,
		time.Now().Add(-10*time.Minute),
		time.Now().Add(5*time.Minute),
		false,
	)

	got, err := svc.ValidateAccessToken(signed)
	if err != nil {
		t.Fatalf("access token should be valid within 15 minutes: %v", err)
	}
	if got != userID {
		t.Fatalf("expected user ID %s, got %s", userID, got)
	}
}

// --- Malformed / edge cases ---

func TestInvalidTokenStringRejected(t *testing.T) {
	svc := NewJWTService("test-secret")

	_, err := svc.ValidateAccessToken("not-a-real-token")
	if err == nil {
		t.Fatal("expected error for garbage token string")
	}
}

func TestEmptyTokenStringRejected(t *testing.T) {
	svc := NewJWTService("test-secret")

	_, err := svc.ValidateAccessToken("")
	if err == nil {
		t.Fatal("expected error for empty token string")
	}

	_, err = svc.ValidateRefreshToken("")
	if err == nil {
		t.Fatal("expected error for empty refresh token string")
	}
}

func TestTokenWithInvalidSubjectRejected(t *testing.T) {
	svc := NewJWTService("test-secret")

	signed := signToken(t, svc, Claims{
		RegisteredClaims: jwt.RegisteredClaims{
			Subject:   "not-a-uuid",
			IssuedAt:  jwt.NewNumericDate(time.Now()),
			ExpiresAt: jwt.NewNumericDate(time.Now().Add(15 * time.Minute)),
		},
		Type: "access",
	})

	_, err := svc.ValidateAccessToken(signed)
	if err == nil {
		t.Fatal("expected error for non-UUID subject")
	}
}

func TestTokenWithMissingTypeClaim(t *testing.T) {
	svc := NewJWTService("test-secret")

	signed := signToken(t, svc, Claims{
		RegisteredClaims: jwt.RegisteredClaims{
			Subject:   uuid.New().String(),
			IssuedAt:  jwt.NewNumericDate(time.Now()),
			ExpiresAt: jwt.NewNumericDate(time.Now().Add(15 * time.Minute)),
		},
		Type: "", // empty type
	})

	_, err := svc.ValidateAccessToken(signed)
	if err == nil {
		t.Fatal("expected error for missing type claim")
	}
}

func TestTokenWithNoneAlgorithmRejected(t *testing.T) {
	svc := NewJWTService("test-secret")

	claims := Claims{
		RegisteredClaims: jwt.RegisteredClaims{
			Subject:   uuid.New().String(),
			IssuedAt:  jwt.NewNumericDate(time.Now()),
			ExpiresAt: jwt.NewNumericDate(time.Now().Add(15 * time.Minute)),
		},
		Type: "access",
	}
	// Use "none" signing method (alg confusion attack)
	token := jwt.NewWithClaims(jwt.SigningMethodNone, claims)
	signed, _ := token.SignedString(jwt.UnsafeAllowNoneSignatureType)

	_, err := svc.ValidateAccessToken(signed)
	if err == nil {
		t.Fatal("expected error for 'none' algorithm token")
	}
}

// --- Token refresh chain: generate, validate, re-generate ---

func TestRefreshTokenChain(t *testing.T) {
	svc := NewJWTService("test-secret")
	userID := uuid.New()

	// Initial token pair
	_, refresh1, err := svc.GenerateTokenPair(userID, false)
	if err != nil {
		t.Fatalf("generate initial pair: %v", err)
	}

	// Validate refresh token (simulates backend refresh endpoint)
	gotID, err := svc.ValidateRefreshToken(refresh1)
	if err != nil {
		t.Fatalf("validate refresh1: %v", err)
	}
	if gotID != userID {
		t.Fatalf("expected %s, got %s", userID, gotID)
	}

	// Generate new pair (simulates issuing new tokens after refresh)
	access2, refresh2, err := svc.GenerateTokenPair(gotID, false)
	if err != nil {
		t.Fatalf("generate second pair: %v", err)
	}

	// New tokens should be valid
	gotID, err = svc.ValidateAccessToken(access2)
	if err != nil {
		t.Fatalf("validate access2: %v", err)
	}
	if gotID != userID {
		t.Fatalf("expected %s, got %s", userID, gotID)
	}

	gotID, err = svc.ValidateRefreshToken(refresh2)
	if err != nil {
		t.Fatalf("validate refresh2: %v", err)
	}
	if gotID != userID {
		t.Fatalf("expected %s, got %s", userID, gotID)
	}

	// Old refresh token should still be valid (stateless — no rotation invalidation)
	gotID, err = svc.ValidateRefreshToken(refresh1)
	if err != nil {
		t.Fatalf("old refresh token should still validate (stateless): %v", err)
	}
	if gotID != userID {
		t.Fatalf("expected %s, got %s", userID, gotID)
	}
}

func TestEmptySecretStillWorks(t *testing.T) {
	// Ensure empty secret doesn't panic (though it's insecure)
	svc := NewJWTService("")
	userID := uuid.New()

	access, refresh, err := svc.GenerateTokenPair(userID, false)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	got, err := svc.ValidateAccessToken(access)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if got != userID {
		t.Fatalf("expected %s, got %s", userID, got)
	}

	got, err = svc.ValidateRefreshToken(refresh)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if got != userID {
		t.Fatalf("expected %s, got %s", userID, got)
	}
}
