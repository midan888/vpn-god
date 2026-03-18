package store

import (
	"context"
	"errors"

	"github.com/google/uuid"
	"vpn-god/backend/internal/models"
)

var (
	ErrUserNotFound = errors.New("user not found")
	ErrEmailExists  = errors.New("email already exists")
)

type UserStore interface {
	CreateUser(ctx context.Context, email, hashedPassword string) (*models.User, error)
	GetUserByEmail(ctx context.Context, email string) (*models.User, error)
	GetUserByID(ctx context.Context, id uuid.UUID) (*models.User, error)
}
