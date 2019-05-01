# Shipvote

TODO: Description

## Backend Architecture

![Backend Architecture Diagram](docs/Shipvote%20Architecture.png)

### Design Decisions

#### REST API over WebSocket

The early implementation used WebSockets, as the way the votes work can be represented easily with them. However, it showed early
that the $5 DigitalOcean droplet(s) the backend is deployed on with the Phoenix Channrl implementation could not handle
many WebSocket connections, the CPU peaked at around 250 connections, even with caching (using ConCache) enabled. For that reason
I switched to a RESTful API for the whole voting, using polling for the vote. The timing can be seen in the sequence diagrams below.
With this, the $5 droplet can handle around 1000 to 1500 users. Still seems a bit low, but since the usage of the application is not
higher than that there was no further optimization done.
The plan is to retry the WebSocket implementation at some point.

### API Flows

This section describes interactions with the `backend` and Wargaming APIs.

#### Channel Configuration

![Channel Configuration Sequence Diagram](docs/config.svg)

#### Twitch Video Overlay

![Twitch Video Overlay Sequence Diagram](docs/video_overlay.svg)
