package auth

import (
	"net/http"
	"net/http/httptest"
	"testing"
	"time"

	"github.com/golang-jwt/jwt/v5"
	"github.com/google/uuid"
)

func makeHandler() http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		userID, ok := UserIDFromContext(r.Context())
		if !ok {
			http.Error(w, "no user in context", http.StatusInternalServerError)
			return
		}
		w.WriteHeader(http.StatusOK)
		w.Write([]byte(userID.String()))
	})
}

func TestMiddleware_ValidToken(t *testing.T) {
	svc := NewJWTService("test-secret")
	userID := uuid.New()
	access, _, _ := svc.GenerateTokenPair(userID, false)

	handler := Middleware(svc)(makeHandler())
	req := httptest.NewRequest(http.MethodGet, "/test", nil)
	req.Header.Set("Authorization", "Bearer "+access)
	w := httptest.NewRecorder()

	handler.ServeHTTP(w, req)

	if w.Code != http.StatusOK {
		t.Fatalf("expected 200, got %d: %s", w.Code, w.Body.String())
	}
	if w.Body.String() != userID.String() {
		t.Fatalf("expected user ID %s in body, got %s", userID, w.Body.String())
	}
}

func TestMiddleware_MissingAuthHeader(t *testing.T) {
	svc := NewJWTService("test-secret")
	handler := Middleware(svc)(makeHandler())

	req := httptest.NewRequest(http.MethodGet, "/test", nil)
	w := httptest.NewRecorder()

	handler.ServeHTTP(w, req)

	if w.Code != http.StatusUnauthorized {
		t.Fatalf("expected 401, got %d", w.Code)
	}
}

func TestMiddleware_InvalidAuthFormat_NoBearerPrefix(t *testing.T) {
	svc := NewJWTService("test-secret")
	handler := Middleware(svc)(makeHandler())

	req := httptest.NewRequest(http.MethodGet, "/test", nil)
	req.Header.Set("Authorization", "Basic abc123")
	w := httptest.NewRecorder()

	handler.ServeHTTP(w, req)

	if w.Code != http.StatusUnauthorized {
		t.Fatalf("expected 401, got %d", w.Code)
	}
}

func TestMiddleware_ExpiredAccessToken(t *testing.T) {
	svc := NewJWTService("test-secret")
	userID := uuid.New()

	expired := makeAccessToken(t, svc, userID,
		time.Now().Add(-1*time.Hour),
		time.Now().Add(-30*time.Minute),
		false,
	)

	handler := Middleware(svc)(makeHandler())
	req := httptest.NewRequest(http.MethodGet, "/test", nil)
	req.Header.Set("Authorization", "Bearer "+expired)
	w := httptest.NewRecorder()

	handler.ServeHTTP(w, req)

	if w.Code != http.StatusUnauthorized {
		t.Fatalf("expected 401 for expired token, got %d", w.Code)
	}
}

func TestMiddleware_RefreshTokenRejected(t *testing.T) {
	svc := NewJWTService("test-secret")
	_, refresh, _ := svc.GenerateTokenPair(uuid.New(), false)

	handler := Middleware(svc)(makeHandler())
	req := httptest.NewRequest(http.MethodGet, "/test", nil)
	req.Header.Set("Authorization", "Bearer "+refresh)
	w := httptest.NewRecorder()

	handler.ServeHTTP(w, req)

	if w.Code != http.StatusUnauthorized {
		t.Fatalf("expected 401 for refresh token used as access, got %d", w.Code)
	}
}

func TestMiddleware_WrongSecret(t *testing.T) {
	svc1 := NewJWTService("secret-one")
	svc2 := NewJWTService("secret-two")

	access, _, _ := svc1.GenerateTokenPair(uuid.New(), false)

	handler := Middleware(svc2)(makeHandler())
	req := httptest.NewRequest(http.MethodGet, "/test", nil)
	req.Header.Set("Authorization", "Bearer "+access)
	w := httptest.NewRecorder()

	handler.ServeHTTP(w, req)

	if w.Code != http.StatusUnauthorized {
		t.Fatalf("expected 401 for wrong-secret token, got %d", w.Code)
	}
}

func TestMiddleware_GarbageToken(t *testing.T) {
	svc := NewJWTService("test-secret")
	handler := Middleware(svc)(makeHandler())

	req := httptest.NewRequest(http.MethodGet, "/test", nil)
	req.Header.Set("Authorization", "Bearer garbage.token.string")
	w := httptest.NewRecorder()

	handler.ServeHTTP(w, req)

	if w.Code != http.StatusUnauthorized {
		t.Fatalf("expected 401, got %d", w.Code)
	}
}

func TestMiddleware_EmptyBearerToken(t *testing.T) {
	svc := NewJWTService("test-secret")
	handler := Middleware(svc)(makeHandler())

	req := httptest.NewRequest(http.MethodGet, "/test", nil)
	req.Header.Set("Authorization", "Bearer ")
	w := httptest.NewRecorder()

	handler.ServeHTTP(w, req)

	if w.Code != http.StatusUnauthorized {
		t.Fatalf("expected 401 for empty bearer token, got %d", w.Code)
	}
}

func TestMiddleware_NoneAlgorithmToken(t *testing.T) {
	svc := NewJWTService("test-secret")

	claims := Claims{
		RegisteredClaims: jwt.RegisteredClaims{
			Subject:   uuid.New().String(),
			IssuedAt:  jwt.NewNumericDate(time.Now()),
			ExpiresAt: jwt.NewNumericDate(time.Now().Add(15 * time.Minute)),
		},
		Type: "access",
	}
	token := jwt.NewWithClaims(jwt.SigningMethodNone, claims)
	signed, _ := token.SignedString(jwt.UnsafeAllowNoneSignatureType)

	handler := Middleware(svc)(makeHandler())
	req := httptest.NewRequest(http.MethodGet, "/test", nil)
	req.Header.Set("Authorization", "Bearer "+signed)
	w := httptest.NewRecorder()

	handler.ServeHTTP(w, req)

	if w.Code != http.StatusUnauthorized {
		t.Fatalf("expected 401 for 'none' alg token, got %d", w.Code)
	}
}

func TestUserIDFromContext_MissingValue(t *testing.T) {
	req := httptest.NewRequest(http.MethodGet, "/test", nil)
	_, ok := UserIDFromContext(req.Context())
	if ok {
		t.Fatal("expected false for context without user ID")
	}
}
