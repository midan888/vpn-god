package store

import (
	"context"
	"database/sql"
	"errors"
	"time"

	"github.com/google/uuid"
	"github.com/jmoiron/sqlx"
	"vpn-dan/backend/internal/models"
)

var (
	ErrCodeNotFound = errors.New("auth code not found")
	ErrCodeExpired  = errors.New("auth code expired")
	ErrCodeUsed     = errors.New("auth code already used")
)

type AuthCodeStore interface {
	CreateCode(ctx context.Context, email, code string, expiresAt time.Time) (*models.AuthCode, error)
	VerifyCode(ctx context.Context, email, code string) (*models.AuthCode, error)
	DeleteExpiredCodes(ctx context.Context) error
}

type PostgresAuthCodeStore struct {
	db *sqlx.DB
}

func NewPostgresAuthCodeStore(db *sqlx.DB) *PostgresAuthCodeStore {
	return &PostgresAuthCodeStore{db: db}
}

func (s *PostgresAuthCodeStore) CreateCode(ctx context.Context, email, code string, expiresAt time.Time) (*models.AuthCode, error) {
	// Invalidate any existing unused codes for this email
	_, _ = s.db.ExecContext(ctx,
		`UPDATE auth_codes SET used = true WHERE email = $1 AND used = false`, email)

	ac := &models.AuthCode{
		ID:        uuid.New(),
		Email:     email,
		Code:      code,
		ExpiresAt: expiresAt,
		Used:      false,
		CreatedAt: time.Now(),
	}

	_, err := s.db.ExecContext(ctx,
		`INSERT INTO auth_codes (id, email, code, expires_at, used, created_at)
		 VALUES ($1, $2, $3, $4, $5, $6)`,
		ac.ID, ac.Email, ac.Code, ac.ExpiresAt, ac.Used, ac.CreatedAt,
	)
	if err != nil {
		return nil, err
	}

	return ac, nil
}

func (s *PostgresAuthCodeStore) VerifyCode(ctx context.Context, email, code string) (*models.AuthCode, error) {
	var ac models.AuthCode
	err := s.db.GetContext(ctx, &ac,
		`SELECT id, email, code, expires_at, used, created_at
		 FROM auth_codes
		 WHERE email = $1 AND code = $2
		 ORDER BY created_at DESC
		 LIMIT 1`,
		email, code,
	)
	if err != nil {
		if errors.Is(err, sql.ErrNoRows) {
			return nil, ErrCodeNotFound
		}
		return nil, err
	}

	if ac.Used {
		return nil, ErrCodeUsed
	}

	if time.Now().After(ac.ExpiresAt) {
		return nil, ErrCodeExpired
	}

	// Mark as used
	_, _ = s.db.ExecContext(ctx, `UPDATE auth_codes SET used = true WHERE id = $1`, ac.ID)

	return &ac, nil
}

func (s *PostgresAuthCodeStore) DeleteExpiredCodes(ctx context.Context) error {
	_, err := s.db.ExecContext(ctx,
		`DELETE FROM auth_codes WHERE expires_at < $1`, time.Now())
	return err
}
