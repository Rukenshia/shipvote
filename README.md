<!--# Shipvote-->

<!--TODO: Description-->

<!--## Backend Architecture-->

<!--![Backend Architecture Diagram](docs/Shipvote%20Architecture.png)-->

### API Flows

This section describes interactions with the `backend` and Wargaming APIs.

#### Channel Configuration

```mermaid
sequenceDiagram
	participant Extension Frontend
	participant Backend
	participant Database
	participant Wargaming API

	Extension Frontend->>+Backend: create or update configuration
	Backend->>Database: retrieve channel and ships
	Backend->>+Wargaming API: /wows/accounts/list
	Wargaming API-->>-Backend: user ID
	Backend->>+Wargaming API: /wows/ships/stats
	Wargaming API-->>-Backend: player statistics
	Backend->>+Backend: calculate ship delta
	Backend->>-Database: store channel and ships
	Database-->>Backend: ;
	Backend-->>-Extension Frontend: channel information
```

#### Twitch Viewer

```mermaid
sequenceDiagram
	participant Extension Frontend
	participant VoteProgress
	participant ShipSelection
	participant Backend
	participant Wargaming API

	Extension Frontend->>+Backend: retrieve channel information
	Backend-->>-Extension Frontend: channel information

	loop every 5 seconds
		VoteProgress->>+Backend: retrieve open votes
		Backend->>-VoteProgress: vote status

		opt vote is open
			loop every 2500ms
				VoteProgress->>+Backend: get vote results
				Backend-->>-VoteProgress: vote results
			end
			VoteProgress-->>Extension Frontend: display vote

			opt "Vote for a Ship now"
				ShipSelection->>+Backend: POST vote
				alt user voted already
					Backend-->>ShipSelection: 400
				else
					Backend->>Backend: store vote
					Backend-->>-ShipSelection: 200
				end
			end
		end
	end
```
