package api

import (
	"bytes"
	"context"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"
	"time"

	"github.com/google/uuid"
	"vpn-dan/backend/internal/auth"
	"vpn-dan/backend/internal/models"
	"vpn-dan/backend/internal/store"
)

// mockUserStore implements store.UserStore for testing.
type mockUserStore struct {
	users map[string]*models.User
}

func newMockUserStore() *mockUserStore {
	return &mockUserStore{users: make(map[string]*models.User)}
}

func (m *mockUserStore) CreateUser(_ context.Context, email, hashedPassword string) (*models.User, error) {
	if _, exists := m.users[email]; exists {
		return nil, store.ErrEmailExists
	}
	user := &models.User{
		ID:       uuid.New(),
		Email:    email,
		Password: hashedPassword,
	}
	m.users[email] = user
	return user, nil
}

func (m *mockUserStore) GetUserByEmail(_ context.Context, email string) (*models.User, error) {
	user, ok := m.users[email]
	if !ok {
		return nil, store.ErrUserNotFound
	}
	return user, nil
}

func (m *mockUserStore) GetUserByID(_ context.Context, id uuid.UUID) (*models.User, error) {
	for _, user := range m.users {
		if user.ID == id {
			return user, nil
		}
	}
	return nil, store.ErrUserNotFound
}

func (m *mockUserStore) ListUsers(_ context.Context) ([]models.User, error) {
	var users []models.User
	for _, u := range m.users {
		users = append(users, *u)
	}
	return users, nil
}

func (m *mockUserStore) UpdatePassword(_ context.Context, id uuid.UUID, hashedPassword string) error {
	for _, u := range m.users {
		if u.ID == id {
			u.Password = hashedPassword
			return nil
		}
	}
	return store.ErrUserNotFound
}

func (m *mockUserStore) DeleteUser(_ context.Context, id uuid.UUID) error {
	for email, u := range m.users {
		if u.ID == id {
			delete(m.users, email)
			return nil
		}
	}
	return store.ErrUserNotFound
}

func (m *mockUserStore) SetAdmin(_ context.Context, id uuid.UUID, isAdmin bool) error {
	for _, u := range m.users {
		if u.ID == id {
			u.IsAdmin = isAdmin
			return nil
		}
	}
	return store.ErrUserNotFound
}

// mockAuthCodeStore implements store.AuthCodeStore for testing.
type mockAuthCodeStore struct {
	codes map[string]*models.AuthCode // keyed by email+code
}

func newMockAuthCodeStore() *mockAuthCodeStore {
	return &mockAuthCodeStore{codes: make(map[string]*models.AuthCode)}
}

func (m *mockAuthCodeStore) CreateCode(_ context.Context, email, code string, expiresAt time.Time) (*models.AuthCode, error) {
	ac := &models.AuthCode{
		ID:        uuid.New(),
		Email:     email,
		Code:      code,
		ExpiresAt: expiresAt,
		Used:      false,
		CreatedAt: time.Now(),
	}
	m.codes[email+":"+code] = ac
	return ac, nil
}

func (m *mockAuthCodeStore) VerifyCode(_ context.Context, email, code string) (*models.AuthCode, error) {
	ac, ok := m.codes[email+":"+code]
	if !ok {
		return nil, store.ErrCodeNotFound
	}
	if ac.Used {
		return nil, store.ErrCodeUsed
	}
	if time.Now().After(ac.ExpiresAt) {
		return nil, store.ErrCodeExpired
	}
	ac.Used = true
	return ac, nil
}

func (m *mockAuthCodeStore) DeleteExpiredCodes(_ context.Context) error {
	return nil
}

type mockServerStore struct{}

func (m *mockServerStore) ListActiveServers(_ context.Context) ([]models.Server, error) {
	return nil, nil
}

func (m *mockServerStore) GetServerByID(_ context.Context, _ uuid.UUID) (*models.Server, error) {
	return nil, store.ErrServerNotFound
}

func (m *mockServerStore) ListAllServers(_ context.Context) ([]models.Server, error) {
	return nil, nil
}

func (m *mockServerStore) CreateServer(_ context.Context, s *models.Server) (*models.Server, error) {
	return s, nil
}

func (m *mockServerStore) DeleteServer(_ context.Context, _ uuid.UUID) error {
	return store.ErrServerNotFound
}

func (m *mockServerStore) UpdateServerStatus(_ context.Context, _ uuid.UUID, _ bool) error {
	return store.ErrServerNotFound
}

func (m *mockServerStore) UpsertServerByHost(_ context.Context, s *models.Server) (*models.Server, error) {
	return s, nil
}

func (m *mockServerStore) UpdateHeartbeat(_ context.Context, _ string) error {
	return nil
}

func (m *mockServerStore) MarkStaleServersInactive(_ context.Context, _ time.Duration) (int, error) {
	return 0, nil
}

type mockGeoIPStore struct{}

func (m *mockGeoIPStore) GetCIDRsByCountry(_ context.Context, _ string) ([]string, error) {
	return nil, nil
}

func (m *mockGeoIPStore) ListAvailableCountries(_ context.Context) ([]models.AvailableCountry, error) {
	return nil, nil
}

func (m *mockGeoIPStore) BulkInsertCIDRs(_ context.Context, _ string, _ []string) error {
	return nil
}

func (m *mockGeoIPStore) DeleteByCountry(_ context.Context, _ string) error {
	return nil
}

type mockPeerManager struct{}

func (m *mockPeerManager) AddPeer(_, _ string) error { return nil }
func (m *mockPeerManager) RemovePeer(_ string) error  { return nil }

type mockPeerStore struct{}

func (m *mockPeerStore) CreatePeer(_ context.Context, _, _ uuid.UUID, _, _, _ string) (*models.Peer, error) {
	return nil, nil
}
func (m *mockPeerStore) GetPeerByUserID(_ context.Context, _ uuid.UUID) (*models.Peer, error) {
	return nil, store.ErrPeerNotFound
}
func (m *mockPeerStore) DeletePeerByUserID(_ context.Context, _ uuid.UUID) error {
	return store.ErrPeerNotFound
}
func (m *mockPeerStore) CountPeersByServerID(_ context.Context, _ uuid.UUID) (int, error) {
	return 0, nil
}

func (m *mockPeerStore) ListPeersByServerID(_ context.Context, _ uuid.UUID) ([]models.Peer, error) {
	return nil, nil
}

func (m *mockPeerStore) ListAllPeers(_ context.Context) ([]models.Peer, error) {
	return nil, nil
}

func setupRouter() (http.Handler, *mockUserStore, *mockAuthCodeStore) {
	ms := newMockUserStore()
	acs := newMockAuthCodeStore()
	jwtSvc := auth.NewJWTService("test-secret")
	router := NewRouter(ms, &mockServerStore{}, &mockPeerStore{}, &mockGeoIPStore{}, acs, jwtSvc, nil, &mockPeerManager{}, "", "")
	return router, ms, acs
}

func postJSON(router http.Handler, path string, body any) *httptest.ResponseRecorder {
	b, _ := json.Marshal(body)
	req := httptest.NewRequest(http.MethodPost, path, bytes.NewReader(b))
	req.Header.Set("Content-Type", "application/json")
	w := httptest.NewRecorder()
	router.ServeHTTP(w, req)
	return w
}

// --- Send Code tests ---

func TestSendCode_Success(t *testing.T) {
	router, _, _ := setupRouter()

	w := postJSON(router, "/api/v1/auth/send-code", map[string]string{
		"email": "test@example.com",
	})

	if w.Code != http.StatusOK {
		t.Fatalf("expected 200, got %d: %s", w.Code, w.Body.String())
	}

	var resp models.SendCodeResponse
	json.NewDecoder(w.Body).Decode(&resp)
	if resp.Message != "verification code sent" {
		t.Fatalf("expected confirmation message, got %q", resp.Message)
	}
}

func TestSendCode_InvalidEmail(t *testing.T) {
	router, _, _ := setupRouter()

	w := postJSON(router, "/api/v1/auth/send-code", map[string]string{
		"email": "not-an-email",
	})
	if w.Code != http.StatusUnprocessableEntity {
		t.Fatalf("expected 422, got %d: %s", w.Code, w.Body.String())
	}
}

// --- Verify Code tests ---

func TestVerifyCode_Success_NewUser(t *testing.T) {
	router, _, acs := setupRouter()

	// Pre-create a valid code
	acs.CreateCode(context.Background(), "new@example.com", "123456", time.Now().Add(10*time.Minute))

	w := postJSON(router, "/api/v1/auth/verify-code", map[string]string{
		"email": "new@example.com",
		"code":  "123456",
	})

	if w.Code != http.StatusOK {
		t.Fatalf("expected 200, got %d: %s", w.Code, w.Body.String())
	}

	var resp models.AuthResponse
	json.NewDecoder(w.Body).Decode(&resp)
	if resp.AccessToken == "" || resp.RefreshToken == "" {
		t.Fatal("expected tokens in response")
	}
}

func TestVerifyCode_Success_ExistingUser(t *testing.T) {
	router, ms, acs := setupRouter()

	ms.users["existing@example.com"] = &models.User{
		ID:    uuid.New(),
		Email: "existing@example.com",
	}

	acs.CreateCode(context.Background(), "existing@example.com", "654321", time.Now().Add(10*time.Minute))

	w := postJSON(router, "/api/v1/auth/verify-code", map[string]string{
		"email": "existing@example.com",
		"code":  "654321",
	})

	if w.Code != http.StatusOK {
		t.Fatalf("expected 200, got %d: %s", w.Code, w.Body.String())
	}
}

func TestVerifyCode_WrongCode(t *testing.T) {
	router, _, acs := setupRouter()

	acs.CreateCode(context.Background(), "test@example.com", "123456", time.Now().Add(10*time.Minute))

	w := postJSON(router, "/api/v1/auth/verify-code", map[string]string{
		"email": "test@example.com",
		"code":  "000000",
	})

	if w.Code != http.StatusUnauthorized {
		t.Fatalf("expected 401, got %d", w.Code)
	}
}

func TestVerifyCode_ExpiredCode(t *testing.T) {
	router, _, acs := setupRouter()

	acs.CreateCode(context.Background(), "test@example.com", "123456", time.Now().Add(-1*time.Minute))

	w := postJSON(router, "/api/v1/auth/verify-code", map[string]string{
		"email": "test@example.com",
		"code":  "123456",
	})

	if w.Code != http.StatusUnauthorized {
		t.Fatalf("expected 401, got %d", w.Code)
	}
}

func TestVerifyCode_CodeAlreadyUsed(t *testing.T) {
	router, _, acs := setupRouter()

	acs.CreateCode(context.Background(), "test@example.com", "123456", time.Now().Add(10*time.Minute))

	// First use succeeds
	postJSON(router, "/api/v1/auth/verify-code", map[string]string{
		"email": "test@example.com",
		"code":  "123456",
	})

	// Second use fails
	w := postJSON(router, "/api/v1/auth/verify-code", map[string]string{
		"email": "test@example.com",
		"code":  "123456",
	})

	if w.Code != http.StatusUnauthorized {
		t.Fatalf("expected 401, got %d", w.Code)
	}
}

// --- Refresh tests ---

func TestRefresh_Success(t *testing.T) {
	router, ms, _ := setupRouter()
	jwtSvc := auth.NewJWTService("test-secret")

	userID := uuid.New()
	ms.users["test@example.com"] = &models.User{
		ID:    userID,
		Email: "test@example.com",
	}

	_, refresh, _ := jwtSvc.GenerateTokenPair(userID, false)

	w := postJSON(router, "/api/v1/auth/refresh", map[string]string{
		"refresh_token": refresh,
	})

	if w.Code != http.StatusOK {
		t.Fatalf("expected 200, got %d: %s", w.Code, w.Body.String())
	}

	var resp models.AuthResponse
	json.NewDecoder(w.Body).Decode(&resp)
	if resp.AccessToken == "" || resp.RefreshToken == "" {
		t.Fatal("expected tokens in response")
	}
}

func TestRefresh_InvalidToken(t *testing.T) {
	router, _, _ := setupRouter()

	w := postJSON(router, "/api/v1/auth/refresh", map[string]string{
		"refresh_token": "invalid-token",
	})

	if w.Code != http.StatusUnauthorized {
		t.Fatalf("expected 401, got %d", w.Code)
	}
}

func TestRefresh_MissingToken(t *testing.T) {
	router, _, _ := setupRouter()

	w := postJSON(router, "/api/v1/auth/refresh", map[string]string{})

	if w.Code != http.StatusUnprocessableEntity {
		t.Fatalf("expected 422, got %d", w.Code)
	}
}

func TestRefresh_DeletedUser(t *testing.T) {
	router, _, _ := setupRouter()
	jwtSvc := auth.NewJWTService("test-secret")

	_, refresh, _ := jwtSvc.GenerateTokenPair(uuid.New(), false)

	w := postJSON(router, "/api/v1/auth/refresh", map[string]string{
		"refresh_token": refresh,
	})

	if w.Code != http.StatusUnauthorized {
		t.Fatalf("expected 401, got %d", w.Code)
	}
}

func TestRefresh_AccessTokenRejected(t *testing.T) {
	router, ms, _ := setupRouter()
	jwtSvc := auth.NewJWTService("test-secret")

	userID := uuid.New()
	ms.users["test@example.com"] = &models.User{ID: userID, Email: "test@example.com"}

	access, _, _ := jwtSvc.GenerateTokenPair(userID, false)

	w := postJSON(router, "/api/v1/auth/refresh", map[string]string{
		"refresh_token": access,
	})

	if w.Code != http.StatusUnauthorized {
		t.Fatalf("expected 401, got %d", w.Code)
	}
}
