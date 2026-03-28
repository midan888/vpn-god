package api

import (
	"context"
	"crypto/rand"
	"errors"
	"fmt"
	"log"
	"math/big"
	"time"

	"github.com/danielgtaylor/huma/v2"
	"vpn-dan/backend/internal/auth"
	"vpn-dan/backend/internal/email"
	"vpn-dan/backend/internal/models"
	"vpn-dan/backend/internal/store"
)

type AuthHandler struct {
	users     store.UserStore
	authCodes store.AuthCodeStore
	jwt       *auth.JWTService
	email     email.Sender
}

func NewAuthHandler(users store.UserStore, authCodes store.AuthCodeStore, jwt *auth.JWTService, emailSender email.Sender) *AuthHandler {
	return &AuthHandler{users: users, authCodes: authCodes, jwt: jwt, email: emailSender}
}

// Input/Output types for huma

type SendCodeInput struct {
	Body models.SendCodeRequest
}

type SendCodeOutput struct {
	Body models.SendCodeResponse
}

type VerifyCodeInput struct {
	Body models.VerifyCodeRequest
}

type VerifyCodeOutput struct {
	Body models.AuthResponse
}

type RefreshInput struct {
	Body models.RefreshRequest
}

type RefreshOutput struct {
	Body models.AuthResponse
}

func generateCode() (string, error) {
	n, err := rand.Int(rand.Reader, big.NewInt(1000000))
	if err != nil {
		return "", err
	}
	return fmt.Sprintf("%06d", n.Int64()), nil
}

func (h *AuthHandler) SendCode(ctx context.Context, input *SendCodeInput) (*SendCodeOutput, error) {
	code, err := generateCode()
	if err != nil {
		return nil, huma.Error500InternalServerError("internal server error")
	}

	expiresAt := time.Now().Add(10 * time.Minute)

	_, err = h.authCodes.CreateCode(ctx, input.Body.Email, code, expiresAt)
	if err != nil {
		return nil, huma.Error500InternalServerError("internal server error")
	}

	if h.email != nil {
		if err := h.email.SendCode(input.Body.Email, code); err != nil {
			log.Printf("failed to send email to %s: %v", input.Body.Email, err)
			return nil, huma.Error500InternalServerError("failed to send verification email")
		}
	} else {
		// Dev fallback: log the code
		log.Printf("AUTH CODE for %s: %s", input.Body.Email, code)
	}

	return &SendCodeOutput{Body: models.SendCodeResponse{
		Message: "verification code sent",
	}}, nil
}

func (h *AuthHandler) VerifyCode(ctx context.Context, input *VerifyCodeInput) (*VerifyCodeOutput, error) {
	_, err := h.authCodes.VerifyCode(ctx, input.Body.Email, input.Body.Code)
	if err != nil {
		if errors.Is(err, store.ErrCodeNotFound) || errors.Is(err, store.ErrCodeUsed) {
			return nil, huma.Error401Unauthorized("invalid verification code")
		}
		if errors.Is(err, store.ErrCodeExpired) {
			return nil, huma.Error401Unauthorized("verification code expired")
		}
		return nil, huma.Error500InternalServerError("internal server error")
	}

	// Find or create user
	user, err := h.users.GetUserByEmail(ctx, input.Body.Email)
	if err != nil {
		if errors.Is(err, store.ErrUserNotFound) {
			// Auto-register
			user, err = h.users.CreateUser(ctx, input.Body.Email, "")
			if err != nil {
				return nil, huma.Error500InternalServerError("internal server error")
			}
		} else {
			return nil, huma.Error500InternalServerError("internal server error")
		}
	}

	accessToken, refreshToken, err := h.jwt.GenerateTokenPair(user.ID, user.IsAdmin)
	if err != nil {
		return nil, huma.Error500InternalServerError("internal server error")
	}

	return &VerifyCodeOutput{Body: models.AuthResponse{
		AccessToken:  accessToken,
		RefreshToken: refreshToken,
	}}, nil
}

func (h *AuthHandler) Refresh(ctx context.Context, input *RefreshInput) (*RefreshOutput, error) {
	userID, err := h.jwt.ValidateRefreshToken(input.Body.RefreshToken)
	if err != nil {
		return nil, huma.Error401Unauthorized("invalid or expired refresh token")
	}

	user, err := h.users.GetUserByID(ctx, userID)
	if err != nil {
		return nil, huma.Error401Unauthorized("invalid or expired refresh token")
	}

	accessToken, refreshToken, err := h.jwt.GenerateTokenPair(userID, user.IsAdmin)
	if err != nil {
		return nil, huma.Error500InternalServerError("internal server error")
	}

	return &RefreshOutput{Body: models.AuthResponse{
		AccessToken:  accessToken,
		RefreshToken: refreshToken,
	}}, nil
}
