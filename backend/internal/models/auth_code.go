package models

import (
	"time"

	"github.com/google/uuid"
)

type AuthCode struct {
	ID        uuid.UUID `json:"id" db:"id"`
	Email     string    `json:"email" db:"email"`
	Code      string    `json:"-" db:"code"`
	ExpiresAt time.Time `json:"expires_at" db:"expires_at"`
	Used      bool      `json:"used" db:"used"`
	CreatedAt time.Time `json:"created_at" db:"created_at"`
}

type SendCodeRequest struct {
	Email string `json:"email" doc:"User email address" format:"email" minLength:"1"`
}

type SendCodeResponse struct {
	Message string `json:"message" doc:"Confirmation message"`
}

type VerifyCodeRequest struct {
	Email string `json:"email" doc:"User email address" format:"email" minLength:"1"`
	Code  string `json:"code" doc:"6-digit verification code" minLength:"6" maxLength:"6"`
}
