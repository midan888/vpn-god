package api

import (
	"net/http"

	"github.com/danielgtaylor/huma/v2"
	"github.com/danielgtaylor/huma/v2/adapters/humago"
	"vpn-god/backend/internal/auth"
	"vpn-god/backend/internal/store"
)

func NewRouter(users store.UserStore, jwtService *auth.JWTService) http.Handler {
	mux := http.NewServeMux()

	humaAPI := humago.New(mux, huma.DefaultConfig("VPN God API", "1.0.0"))

	authHandler := NewAuthHandler(users, jwtService)

	huma.Register(humaAPI, huma.Operation{
		Method:        http.MethodPost,
		Path:          "/api/v1/auth/register",
		OperationID:   "register",
		Summary:       "Register a new user",
		Tags:          []string{"Auth"},
		DefaultStatus: http.StatusCreated,
	}, authHandler.Register)

	huma.Register(humaAPI, huma.Operation{
		Method:      http.MethodPost,
		Path:        "/api/v1/auth/login",
		OperationID: "login",
		Summary:     "Log in with email and password",
		Tags:        []string{"Auth"},
	}, authHandler.Login)

	huma.Register(humaAPI, huma.Operation{
		Method:      http.MethodPost,
		Path:        "/api/v1/auth/refresh",
		OperationID: "refresh-token",
		Summary:     "Refresh access token",
		Tags:        []string{"Auth"},
	}, authHandler.Refresh)

	return mux
}
