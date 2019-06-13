package channel

import (
	"log"
	"shipvote/channel/api"
)

// Controller is a stateful container to hold channels and serve relevant routes
type Controller struct {
	channels map[string]*Channel
}

// NewController creates a new Controller
func NewController() *Controller {
	return &Controller{make(map[string]*Channel)}
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

	log.Printf("%v", votes)
}
