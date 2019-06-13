package main

import (
	"shipvote/channel"

	"github.com/labstack/echo"
)

func main() {
	controller := channel.NewController()
	controller.AddCurrentVotes()

	e := echo.New()
	e.POST("/api/channels/:channel_id/votes", controller.OpenVote)
	e.PATCH("/api/channels/:channel_id/votes/:vote_id/status", controller.CloseVote)
	e.POST("/api/channels/:channel_id/votes/:vote_id/submit", controller.VoteForShip)
	e.Logger.Fatal(e.Start(":1323"))
}
