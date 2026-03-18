package store

import (
	"context"
	"database/sql"

	"github.com/google/uuid"
	"vpn-god/backend/internal/models"
)

type PostgresServerStore struct {
	db *sql.DB
}

func NewPostgresServerStore(db *sql.DB) *PostgresServerStore {
	return &PostgresServerStore{db: db}
}

func (s *PostgresServerStore) ListActiveServers(ctx context.Context) ([]models.Server, error) {
	rows, err := s.db.QueryContext(ctx,
		`SELECT id, name, country, host, port, public_key, is_active, created_at
		 FROM servers WHERE is_active = true ORDER BY country, name`,
	)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var servers []models.Server
	for rows.Next() {
		var srv models.Server
		if err := rows.Scan(&srv.ID, &srv.Name, &srv.Country, &srv.Host, &srv.Port, &srv.PublicKey, &srv.IsActive, &srv.CreatedAt); err != nil {
			return nil, err
		}
		servers = append(servers, srv)
	}
	return servers, rows.Err()
}

func (s *PostgresServerStore) GetServerByID(ctx context.Context, id uuid.UUID) (*models.Server, error) {
	var srv models.Server
	err := s.db.QueryRowContext(ctx,
		`SELECT id, name, country, host, port, public_key, is_active, created_at
		 FROM servers WHERE id = $1`, id,
	).Scan(&srv.ID, &srv.Name, &srv.Country, &srv.Host, &srv.Port, &srv.PublicKey, &srv.IsActive, &srv.CreatedAt)
	if err == sql.ErrNoRows {
		return nil, ErrServerNotFound
	}
	if err != nil {
		return nil, err
	}
	return &srv, nil
}
