package channel

import (
	"bytes"
	"encoding/json"
	"io/ioutil"
	"log"
	"shipvote/channel/api"
	"strconv"

	"github.com/labstack/echo"
)

type voteForShipRequest struct {
	ShipID string `json:"ship_id"`
}

// OpenVote opens a new vote for a given channel and publishes a message to Twitch PubSub
func (c *Controller) OpenVote(ctx echo.Context) error {
	channelID, err := strconv.ParseUint(ctx.Param("channel_id"), 10, 32)
	if err != nil {
		return err
	}

	authorization := ctx.Request().Header.Get("Authorization")

	defer ctx.Request().Body.Close()
	body, err := ioutil.ReadAll(ctx.Request().Body)
	if err != nil {
		return err
	}

	res, err := api.OpenVote(authorization, channelID, body)
	if err != nil {
		return err
	}

	if res.StatusCode != 200 {
		ctx.Stream(res.StatusCode, res.Header.Get("Content-Type"), res.Body)
		return nil
	}

	defer res.Body.Close()
	resBody, err := ioutil.ReadAll(res.Body)
	if err != nil {
		return err
	}

	var vote api.Vote
	if err := json.Unmarshal(resBody, vote); err != nil {
		return err
	}

	channel, ok := c.channels[channelID]
	if !ok {
		channel = NewChannel(channelID)
		c.channels[channelID] = channel
	}

	if err := channel.StartVote(NewActiveVote(channel, vote.ID)); err != nil {
		log.Printf("Could not start pubsub for vote: %s", err)

		// FIXME: what to do here? attempt to close the vote?
		// maybe set up a sentry and send the error there to see how often it occurs
		// or another kind of notification
	}

	ctx.Stream(res.StatusCode, res.Header.Get("Content-Type"), bytes.NewReader(resBody))
	return nil
}

// CloseVote closes a given vote of the channel and publishes a message to Twitch PubSub
func (c *Controller) CloseVote(ctx echo.Context) error {
	channelID, err := strconv.ParseUint(ctx.Param("channel_id"), 10, 32)
	if err != nil {
		return err
	}
	voteID, err := strconv.ParseUint(ctx.Param("vote_id"), 10, 32)
	if err != nil {
		return err
	}

	authorization := ctx.Request().Header.Get("Authorization")

	defer ctx.Request().Body.Close()
	body, err := ioutil.ReadAll(ctx.Request().Body)
	if err != nil {
		return err
	}

	res, err := api.PatchVote(authorization, channelID, voteID, body)
	if err != nil {
		log.Printf("close vote api error: %v", err)
		return err
	}

	if res.StatusCode != 200 {
		ctx.Stream(res.StatusCode, res.Header.Get("Content-Type"), res.Body)
		return nil
	}

	channel, ok := c.channels[channelID]
	if !ok {
		log.Printf("Cannot close vote %d for non-existing channel %s", voteID, channelID)
	} else {
		if err := channel.StopVote(); err != nil {
			log.Printf("Error closing vote %d for channel %s: %s", voteID, channelID, err)

			// TODO error reporting
		}
	}

	ctx.Stream(res.StatusCode, res.Header.Get("Content-Type"), res.Body)
	return nil
}

// VoteForShip adds a viewers voted ship to a channel vote
func (c *Controller) VoteForShip(ctx echo.Context) error {
	channelID, err := strconv.ParseUint(ctx.Param("channel_id"), 10, 32)
	if err != nil {
		return err
	}
	voteID, err := strconv.ParseUint(ctx.Param("vote_id"), 10, 32)
	if err != nil {
		return err
	}
	authorization := ctx.Request().Header.Get("Authorization")

	defer ctx.Request().Body.Close()
	body, err := ioutil.ReadAll(ctx.Request().Body)
	if err != nil {
		return err
	}

	res, err := api.VoteForShip(authorization, channelID, voteID, body)
	if err != nil {
		return err
	}

	if res.StatusCode != 200 {
		ctx.Stream(res.StatusCode, res.Header.Get("Content-Type"), res.Body)
		return nil
	}

	channel, ok := c.channels[channelID]
	if !ok {
		log.Printf("Could not update internal vote: no channel %s found", channelID)
	}

	var requestBody voteForShipRequest
	if err := ctx.Bind(requestBody); err != nil {
		return err
	}

	channel.AddVotedShip(voteID, requestBody.ShipID)

	ctx.Stream(res.StatusCode, res.Header.Get("Content-Type"), res.Body)

	return nil
}
