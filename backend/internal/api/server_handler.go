package api

import (
	"context"

	"vpn-god/backend/internal/auth"
	"vpn-god/backend/internal/models"
	"vpn-god/backend/internal/store"

	"github.com/danielgtaylor/huma/v2"
)

type ServerHandler struct {
	servers store.ServerStore
	jwt     *auth.JWTService
}

func NewServerHandler(servers store.ServerStore, jwt *auth.JWTService) *ServerHandler {
	return &ServerHandler{servers: servers, jwt: jwt}
}

type ListServersInput struct {
	Authorization string `header:"Authorization" required:"true" doc:"Bearer access token"`
}

type ListServersOutput struct {
	Body []models.ServerResponse
}

func (h *ServerHandler) ListServers(ctx context.Context, input *ListServersInput) (*ListServersOutput, error) {
	if _, err := authenticateRequest(h.jwt, input.Authorization); err != nil {
		return nil, err
	}

	servers, err := h.servers.ListActiveServers(ctx)
	if err != nil {
		return nil, huma.Error500InternalServerError("internal server error")
	}

	resp := make([]models.ServerResponse, len(servers))
	for i, s := range servers {
		resp[i] = models.ServerResponse{
			ID:       s.ID,
			Name:     s.Name,
			Country:  s.Country,
			Host:     s.Host,
			IsActive: s.IsActive,
		}
	}

	return &ListServersOutput{Body: resp}, nil
}
