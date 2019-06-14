package main

import (
	"net/http"
	"shipvote/channel"

	"github.com/labstack/echo"
	"github.com/labstack/echo/middleware"
)

func main() {
	controller := channel.NewController()
	controller.AddCurrentVotes()

	e := echo.New()
	e.POST("/api/channels/:channel_id/votes", controller.OpenVote)
	e.PATCH("/api/channels/:channel_id/votes/:vote_id/status", controller.CloseVote)
	e.POST("/api/channels/:channel_id/votes/:vote_id/submit", controller.VoteForShip)
	e.Logger.Fatal(e.Start(":1323"))

	e.Use(middleware.CORSWithConfig(middleware.CORSConfig{
		AllowOrigins: []string{"*.ext-twitch.tv", "localhost.rig.twitch.tv"},
		AllowMethods: []string{http.MethodGet, http.MethodPut, http.MethodPost, http.MethodDelete},
	}))
}
