package channel

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io/ioutil"
	"log"
	"shipvote/channel/api"
	"strconv"

	"github.com/labstack/echo"
)

type voteForShipRequest struct {
	ShipID uint64 `json:"ship_id"`
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
		log.Printf("OpenVote internally returned %d on channel %d", res.StatusCode, channelID)
		ctx.Stream(res.StatusCode, res.Header.Get("Content-Type"), res.Body)
		return nil
	}

	defer res.Body.Close()
	resBody, err := ioutil.ReadAll(res.Body)
	if err != nil {
		return err
	}

	var vote struct {
		Data api.Vote `json:"data"`
	}
	if err := json.Unmarshal(resBody, &vote); err != nil {
		log.Printf("OpenVote could not unmarshal response")
		log.Printf("response was %s", resBody)
		return err
	}

	channel, ok := c.channels[channelID]
	if !ok {
		channel = NewChannel(channelID)
		c.channels[channelID] = channel
	}

	if err := channel.StartVote(NewActiveVote(channel, vote.Data.ID)); err != nil {
		log.Printf("Could not start pubsub for vote: %s", err)

		// FIXME: what to do here? attempt to close the vote?
		// maybe set up a sentry and send the error there to see how often it occurs
		// or another kind of notification
	}

	log.Printf("OpenVote done for channel %d", channelID)

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
		log.Printf("VoteForShip failed for vote %d in channel %d with %v", voteID, channelID, err)
		return err
	}

	if res.StatusCode != 200 {
		log.Printf("VoteForShip returned %d internally on vote %d in channel %d", res.StatusCode, voteID, channelID)
		ctx.Stream(res.StatusCode, res.Header.Get("Content-Type"), res.Body)
		return nil
	}

	channel, ok := c.channels[channelID]
	if !ok {
		log.Printf("Could not update internal vote: no channel %s found", channelID)
	}

	var requestBody voteForShipRequest
	if err := json.Unmarshal(body, &requestBody); err != nil {
		log.Printf("VoteForShip could not unmarshal requestBody: %v", err)
		return nil
	}

	log.Printf("Added voted ship to vote %d in channel %d with status code %d", voteID, channelID, res.StatusCode)

	channel.AddVotedShip(voteID, fmt.Sprintf("%d", requestBody.ShipID))

	ctx.Stream(res.StatusCode, res.Header.Get("Content-Type"), res.Body)

	return nil
}
