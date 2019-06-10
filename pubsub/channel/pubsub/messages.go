package pubsub

import "time"

// Message is an envelope struct used for PubSub messages
type Message struct {
	MessageType string      `json:"type"`
	Data        interface{} `json:"data"`

	Timestamp time.Time `json:"timestamp"`
}

// VoteStatus describes a change in a votes status such as "open" or "closed"
type VoteStatus struct {
	ID     uint64 `json:"id"`
	Status string `json:"status"`
}

// VoteProgress describes an update in ships viewers have voted for
type VoteProgress struct {
	ID         uint64          `json:"id"`
	VotedShips map[string]uint `json:"voted_ships"`
}
