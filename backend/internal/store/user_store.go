package store

import (
	"context"
	"database/sql"
	"time"

	"github.com/google/uuid"
	"github.com/lib/pq"
	"vpn-god/backend/internal/models"
)

type PostgresUserStore struct {
	db *sql.DB
}

func NewPostgresUserStore(db *sql.DB) *PostgresUserStore {
	return &PostgresUserStore{db: db}
}

func (s *PostgresUserStore) CreateUser(ctx context.Context, email, hashedPassword string) (*models.User, error) {
	user := &models.User{
		ID:        uuid.New(),
		Email:     email,
		Password:  hashedPassword,
		CreatedAt: time.Now(),
	}

	_, err := s.db.ExecContext(ctx,
		`INSERT INTO users (id, email, password, created_at) VALUES ($1, $2, $3, $4)`,
		user.ID, user.Email, user.Password, user.CreatedAt,
	)
	if err != nil {
		if pgErr, ok := err.(*pq.Error); ok && pgErr.Code == "23505" {
			return nil, ErrEmailExists
		}
		return nil, err
	}

	return user, nil
}

func (s *PostgresUserStore) GetUserByEmail(ctx context.Context, email string) (*models.User, error) {
	user := &models.User{}
	err := s.db.QueryRowContext(ctx,
		`SELECT id, email, password, created_at FROM users WHERE email = $1`, email,
	).Scan(&user.ID, &user.Email, &user.Password, &user.CreatedAt)
	if err == sql.ErrNoRows {
		return nil, ErrUserNotFound
	}
	if err != nil {
		return nil, err
	}
	return user, nil
}

func (s *PostgresUserStore) GetUserByID(ctx context.Context, id uuid.UUID) (*models.User, error) {
	user := &models.User{}
	err := s.db.QueryRowContext(ctx,
		`SELECT id, email, password, created_at FROM users WHERE id = $1`, id,
	).Scan(&user.ID, &user.Email, &user.Password, &user.CreatedAt)
	if err == sql.ErrNoRows {
		return nil, ErrUserNotFound
	}
	if err != nil {
		return nil, err
	}
	return user, nil
}
