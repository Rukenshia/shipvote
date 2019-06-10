package pubsub

import (
	"encoding/base64"
	"os"
	"time"

	"github.com/dgrijalva/jwt-go"
)

// Perms describes permissions for a JWT to the Twitch PubSub API
type Perms struct {
	Send []string `json:"send"`
}

// Claims describe the Twitch JWT claims
type Claims struct {
	ChannelID string `json:"channel_id"`
	UserID    string `json:"user_id"`
	Role      string `json:"role"`
	Perms     *Perms `json:"pubsub_perms,omitempty"`

	jwt.StandardClaims
}

// GeneratePubSubToken generates a valid token for the Twitch PubSub API
func GeneratePubSubToken(channelID, messageType string) (string, error) {
	claims := &Claims{
		ChannelID: channelID,
		UserID:    channelID,
		Role:      "external",
		Perms: &Perms{
			Send: []string{messageType},
		},

		StandardClaims: jwt.StandardClaims{
			ExpiresAt: time.Now().Add(time.Minute * 1).Unix(),
		},
	}

	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)

	secret, _ := base64.StdEncoding.DecodeString(os.Getenv("TWITCH_CLIENT_SECRET"))
	ss, err := token.SignedString(secret)

	return ss, err
}
