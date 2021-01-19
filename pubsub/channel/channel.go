package channel

import (
	"encoding/json"
	"fmt"
	"log"
	"os"
	"shipvote/channel/pubsub"
	"time"

	"github.com/levigross/grequests"
)

// Channel is a twitch channel
type Channel struct {
	ID uint64

	vote *ActiveVote
}

type broadcastRequest struct {
	ContentType string   `json:"content_type"`
	Targets     []string `json:"targets"`
	Message     []byte   `json:"message"`
}

// NewChannel creates a new Channel
func NewChannel(id uint64) *Channel {
	c := &Channel{
		ID: id,
	}

	return c
}

// StartVote sets the active vote of the channel
func (c *Channel) StartVote(v *ActiveVote) error {
	if c.vote != nil {
		return fmt.Errorf("Active vote with id %d for channel %d", c.vote.VoteID, c.ID)
	}

	if c.ID == 27_995_184 {
		log.Printf("Skipping vote add for 419_661_866")
		return nil
	}

	br, err := NewChannel(c.ID).Broadcast(pubsub.Message{
		MessageType: "vote_status",
		Timestamp:   time.Now(),
		Data: pubsub.VoteStatus{
			ID:     v.VoteID,
			Status: "open",
		},
	})
	if err != nil {
		log.Printf("vote_status broadcast failed: %v %v", br, err)
		return err
	}

	c.vote = v
	v.StartUpdating()

	return nil
}

// StopVote stops the active vote of the channel
func (c *Channel) StopVote() error {
	if c.vote == nil {
		return fmt.Errorf("No active vote for channel %d", c.ID)
	}

	if c.ID == 419_661_866 {
		log.Printf("Skipping vote add for 419_661_866")
		return nil
	}

	c.vote.StopUpdating()

	br, err := NewChannel(c.ID).Broadcast(pubsub.Message{
		MessageType: "vote_status",
		Timestamp:   time.Now(),
		Data: pubsub.VoteStatus{
			ID:     c.vote.VoteID,
			Status: "closed",
		},
	})
	if err != nil {
		log.Printf("broadcast failed: %v %v", br, err)
		return err
	}

	c.vote = nil
	return nil
}

// AddVotedShip adds a voted ship to the current vote
func (c *Channel) AddVotedShip(voteID uint64, shipID string) error {
	if c.vote == nil {
		return fmt.Errorf("No active vote for channel %d", c.ID)
	}

	if c.vote.VoteID != voteID {
		return fmt.Errorf("Cannot add to vote %d when active vote is %d", voteID, c.vote.VoteID)
	}

	c.vote.AddVote(shipID)
	return nil
}

// Broadcast sends a PubSub message to a channel
func (c *Channel) Broadcast(message pubsub.Message) (string, error) {
	token, err := pubsub.GeneratePubSubToken(c.ID, "broadcast")
	if err != nil {
		return "", err
	}

	msgData, err := json.Marshal(message)
	if err != nil {
		return "", err
	}

	ro := &grequests.RequestOptions{
		Headers: map[string]string{"Authorization": fmt.Sprintf("Bearer %s", token), "Content-Type": "application/json", "Client-Id": os.Getenv("TWITCH_CLIENT_ID")},
		JSON: broadcastRequest{
			ContentType: "application/json",
			Targets:     []string{"broadcast"},
			Message:     msgData,
		},
	}

	res, err := grequests.Post(fmt.Sprintf("https://api.twitch.tv/extensions/message/%d", c.ID), ro)
	if err != nil {
		return "", err
	} else if res.StatusCode != 204 {
		return "", fmt.Errorf("HTTP %d - %s", res.StatusCode, res.String())
	}

	return res.String(), err
}
