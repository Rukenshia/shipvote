package channel

import (
	"log"
	"shipvote/channel/pubsub"
	"time"
)

// ActiveVote represents an active vote on a channel
type ActiveVote struct {
	Channel *Channel
	VoteID  uint64

	votedShips map[string]uint
	stop       chan bool
}

// NewActiveVote creates a new entity of ActiveVote
func NewActiveVote(channel *Channel, voteID uint64) *ActiveVote {
	return &ActiveVote{channel, voteID, make(map[string]uint), make(chan bool, 1)}
}

// StartUpdating starts a thread to send PubSub messages on the vote progress to twitch
func (a *ActiveVote) StartUpdating() {
	log.Printf("StartUpdating for channel %d with vote %d", a.Channel.ID, a.VoteID)
	go func() {
		ticker := time.NewTicker(time.Millisecond * 2000)

		for {
			select {
			case <-ticker.C:
				log.Printf("Updating for channel %d with vote %d", a.Channel.ID, a.VoteID)
				res, err := a.Channel.Broadcast(pubsub.Message{
					MessageType: "vote_progress",
					Timestamp:   time.Now(),
					Data: &pubsub.VoteProgress{
						ID:         a.VoteID,
						VotedShips: a.votedShips,
					},
				})
				if err != nil {
					log.Printf("Error updating channel %d vote %d: %v (response: %s)", a.Channel.ID, a.VoteID, err, res)
				}
				continue
			case <-a.stop:
				ticker.Stop()
				log.Printf("stop updating vote %s", a.VoteID)
				return
			}
		}
	}()
}

// StopUpdating stops updating the vote
func (a *ActiveVote) StopUpdating() {
	a.stop <- true
}

// AddVote adds a vote for a ship and will be sent in the next update
func (a *ActiveVote) AddVote(shipID string) {
	if _, ok := a.votedShips[shipID]; !ok {
		a.votedShips[shipID] = 1
	} else {
		a.votedShips[shipID]++
	}
}
