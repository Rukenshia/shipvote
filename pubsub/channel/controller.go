package channel

// Controller is a stateful container to hold channels and serve relevant routes
type Controller struct {
	channels map[string]*Channel
}

// NewController creates a new Controller
func NewController() *Controller {
	return &Controller{make(map[string]*Channel)}
}
