package channel

import (
	"fmt"
	"log"
	"shipvote/channel/api"
)

// Controller is a stateful container to hold channels and serve relevant routes
type Controller struct {
	channels map[uint64]*Channel
}

// NewController creates a new Controller
func NewController() *Controller {
	return &Controller{make(map[uint64]*Channel)}
}

// AddCurrentVotes takes all currently open votes and adds channels with active votes accordingly
//
// this function is useful for initialising the controller as it might not know about all
// votes on startup.
func (c *Controller) AddCurrentVotes() error {
	votes, err := api.GetOpenVotes("None")
	if err != nil {
		return err
	}

	for _, vote := range votes {
		_, ok := c.channels[vote.ChannelID]
		if ok {
			return fmt.Errorf("AddCurrentVotes could not handle existing channel %d with vote %d", vote.ChannelID, vote.ID)
		}

		channel := NewChannel(vote.ChannelID)
		av := NewActiveVote(channel, vote.ID)

		av.votedShips = vote.Votes

		if err := channel.StartVote(av); err != nil {
			log.Printf("Skipping channel %d vote %d because it could not be started internally with error %v", vote.ChannelID, av.VoteID, err)
			continue
		}

		c.channels[vote.ChannelID] = channel

	}
	return nil
}
