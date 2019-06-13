package api

import (
	"bytes"
	"fmt"
	"net/http"

	"github.com/levigross/grequests"
)

// Vote describes a Vote in Shipvote
type Vote struct {
	ID        uint64          `json:"id"`
	ChannelID uint64          `json:"channel_id"`
	Status    string          `json:"status"`
	Ships     []uint          `json:"ships"`
	Votes     map[string]uint `json:"votes"`
}

// GetOpenVotes returns a list of all open votes in shipvote
func GetOpenVotes(authorization string) ([]Vote, error) {
	ro := &grequests.RequestOptions{
		Headers: map[string]string{"Authorization": authorization},
	}

	res, err := grequests.Get("https://shipvote.in.fkn.space/api/votes?status=open", ro)
	if err != nil {
		return nil, err
	} else if res.StatusCode != 200 {
		return nil, fmt.Errorf("HTTP %d - %s", res.StatusCode, res.String())
	}

	var votes struct {
		Data []Vote `json:"data"`
	}

	if err := res.JSON(&votes); err != nil {
		return nil, err
	}

	return votes.Data, nil
}

// OpenVote opens a new vote for a channel
func OpenVote(authorization, channelID string, body []byte) (*http.Response, error) {
	ro := &grequests.RequestOptions{
		Headers:     map[string]string{"Authorization": authorization, "Content-Type": "application/json"},
		RequestBody: bytes.NewReader(body),
	}

	res, err := grequests.Post(fmt.Sprintf("https://shipvote.in.fkn.space/api/channels/%s/votes", channelID), ro)

	return res.RawResponse, err
}

// PatchVote patches the status of a channels vote
func PatchVote(authorization, channelID string, voteID uint64, body []byte) (*http.Response, error) {
	ro := &grequests.RequestOptions{
		Headers:     map[string]string{"Authorization": authorization, "Content-Type": "application/json"},
		RequestBody: bytes.NewReader(body),
	}

	res, err := grequests.Patch(fmt.Sprintf("https://shipvote.in.fkn.space/api/channels/%s/votes/%d/status", channelID, voteID), ro)
	if err != nil {
		return res.RawResponse, err
	} else if res.StatusCode != 200 {
		return res.RawResponse, fmt.Errorf("HTTP %d - %s", res.StatusCode, res.String())
	}

	return res.RawResponse, err
}

// VoteForShip adds a viewers vote to a channel vote
func VoteForShip(authorization, channelID string, voteID uint64, body []byte) (*http.Response, error) {
	ro := &grequests.RequestOptions{
		Headers:     map[string]string{"Authorization": authorization, "Content-Type": "application/json"},
		RequestBody: bytes.NewReader(body),
	}

	res, err := grequests.Post(fmt.Sprintf("https://shipvote.in.fkn.space/api/channels/%s/votes/%d/submit", channelID, voteID), ro)
	if err != nil {
		return res.RawResponse, err
	} else if res.StatusCode != 200 {
		return res.RawResponse, fmt.Errorf("HTTP %d - %s", res.StatusCode, res.String())
	}

	return res.RawResponse, err
}
