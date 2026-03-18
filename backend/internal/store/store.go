package store

import (
	"context"
	"errors"

	"github.com/google/uuid"
	"vpn-god/backend/internal/models"
)

var (
	ErrUserNotFound   = errors.New("user not found")
	ErrEmailExists    = errors.New("email already exists")
	ErrServerNotFound = errors.New("server not found")
)

type UserStore interface {
	CreateUser(ctx context.Context, email, hashedPassword string) (*models.User, error)
	GetUserByEmail(ctx context.Context, email string) (*models.User, error)
	GetUserByID(ctx context.Context, id uuid.UUID) (*models.User, error)
}

type ServerStore interface {
	ListActiveServers(ctx context.Context) ([]models.Server, error)
	GetServerByID(ctx context.Context, id uuid.UUID) (*models.Server, error)
}
