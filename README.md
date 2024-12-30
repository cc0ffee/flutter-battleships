# Battleships

## 1. Overview

This is an implementation of the classic game [Battleships](https://en.wikipedia.org/wiki/Battleship_(game)) with a simplified UI as part of my Mobile Application Development class. It uses a RESTful API to allow sign up, login, and play games with others. 

Built with Dart and Flutter, using the following packages: [`http`](https://pub.dev/packages/http) for commmunication with HTTP server, [`shared_preferences`](https://pub.dev/packages/shared_preferences) for persistent storage, and [`provider`](https://pub.dev/packages/provider) for managing stateful data.

Though the connection to the API is now removed per completion of the course, I've provided the API operations from the MP readme to recreate it to make this function again either by me or others!

## 2. Features and Specifications

Feature overview with behavioral details of each implemented feature.

#### 2.1 Login and Registration

Login Screen allows the registration and log in to the app. After login/registration the session token returned by the server is stored locally and used to authenticate any requests to the server. If this expires, the user is required to log in again.

#### 2.2.2 Game List
Game List Screen displays a list of all games that are in matchmaking or active games. The following information is displayed for each game:
- The game ID
- The usernames of both players
- Current game status

These games can be swiped to be deleted, any active ones will result in a forfeit to the opponent.

This screen also provides a menu to:
1. Start a new game with another user
2. Start a new game with an AI
3. Show completed games
4. Log out

#### 2.2.3 New Game

Each new game will prompt the user with a 5x5 tile grid where each square tapped is a placed ship (can be removed by tapping again). Submitting the ships starts a game for matchmaking and will be displayed for everyone as an active game from the server.

#### 2.2.4 Playing a Game

The Game View screen displays the game board which shows:
- user's ships
- ships that have been hit by opponent
- shots that are missed by user
- shots that are hit by enemy ship

If it is the user's turn, the user can tap on any available square and submit it to the server. The server will respond with the result (ship hit, missed, etc.) and will wait for the other player's turn unless it is a win.


## 3. REST API for Battleships

As stated in the overview, the REST API service is inactive, but can be recreated. The API can be reached through http (originally it was based on a URL with the IP address). The body content and responses are all JSON objects.

Below is the functionality of the API and what to expect of requests/responses, taken from the original readme of the MP.

### 3.1 Auth

- `POST URL/register`: Registers a new user. The JSON request body should contain the following fields:
  - `username`: The username of the new user.
  - `password`: The password of the new user.

  Both username and password must be at least 3 characters long and cannot contain spaces. If the username is not already taken, the server will respond with a JSON object containing the following fields:

  - `message`: A message indicating that the user was successfully created.
  - `access_token`: A string containing the user's access token. This token should be included in subsequent requests to API calls that require it. Tokens expire after 1 hour, and must be refreshed by logging in again.

- `POST URL/login`: Logs in an existing user. The JSON request body should contain the following fields:
  - `username`: The username of the user to log in.
  - `password`: The password of the user to log in.

  If the username and password are correct, the server will respond with a JSON object containing the following fields:

  - `message`: A message indicating that the user was successfully logged in.
  - `access_token`: A string containing the user's access token. This token should be included in subsequent requests to API calls that require it. Tokens expire after 1 hour, and must be refreshed by logging in again.

### 3.2 Games

For all the routes in this section, the HTTP request header should contain the field named "`Authorization`", with the value "`Bearer <access_token>`", where `<access_token>` is the access token returned by the server when the user logged in. If the access token is missing or invalid, the server will respond with a `401 Unauthorized` error, which means that a new token must be obtained by logging in again.

All successful operations will result in an HTTP status code of `200`.

- `GET URL/games`: Retrieves all games (active and completed) for one user.

  - The server will respond with a JSON object containing the field `games`, whose value is a list of JSON objects representing the games. Each game object contains the following fields:

    - `id`: The unique ID of the game.
    - `player1`: The username of the player in position 1.
    - `player2`: The username of the player in position 2.
    - `position`: The position of the user in the game (either `1` or `2`).
    - `status`: The status of the game, which can be one of the following values:
      - `0`: The game is in the matchmaking phase.
      - `1`: The game has been won by player 1.
      - `2`: The game has been won by player 2.
      - `3`: The game is actively being played.
    - `turn`: If the game is active, then the position of the player whose turn it is (either `1` or `2`); if the game is not active, `0`.
  
- `POST URL/games`: Starts a game with the provided ships. The JSON request body should contain the following fields:

  - `ships`: a list of 5 unique ship locations, each of which is a string of the form "`<row><col>`", where `<row>` is a letter between `A` and `E` and `<col>` is a number between `1` and `5`. For example, the string "`A1`" represents the top-left corner of the board, and the string "`E5`" represents the bottom-right corner of the board.
  - `ai`: (optional) one of the strings "`random`", "`perfect`", or "`oneship`", which select an AI opponent to play. If omitted, the server will match the user with another human player.
  - e.g., some sample request bodies:
    - `{ "ships": ["A1", "A2", "A3", "A4", "A5"] }`
    - `{ "ships": ["B1", "A2", "D3", "C4", "E5"], "ai": "random" }`

  If the request is successful, the server will respond with a JSON object containing the following fields:

  - `id`: the unique ID of the game
  - `player`: the position of the user in the game (either `1` or `2`)
  - `matched`: `True` if the user was matched with another human player, or if the game is against an AI opponent; `False` if the game is waiting for a human opponent.

- `GET URL/games/<game_id>`: Gets detailed information about a game with the integer id `<game_id>`. The server will respond with a JSON object containing the following fields:

  - `id`: The unique ID of the game.
  - `status`: The status of the game, which can be one of the following values:
    - `0`: The game is in the matchmaking phase.
    - `1`: The game has been won by player 1.
    - `2`: The game has been won by player 2.
    - `3`: The game is actively being played.
  - `position`: The position of the user in the game (either `1` or `2`).
  - `turn`: If the game is active, then the position of the player whose turn it is (either `1` or `2`); if the game is not active, `0`.
  - `player1`: The username of the player in position 1.
  - `player2`: The username of the player in position 2.
  - `ships`: a list of coordinates of remaining ships (of the form `A1`, `E5`, etc.) belonging to the user
  - `wrecks`: a list of coordinates of wrecked ships belonging to the user
  - `shots`: a list of shot coordinates previously played by the user, excluding those that successfully hit a ship
  - `sunk`: a list of shot coordinates previously played by the user that hit an enemy ship

- `PUT URL/games/<game_id>`: Plays a shot in the game with the integer id `<game_id>`. The JSON request body should contain the following field:

  - `shot`: a string of the form "`<row><col>`", where `<row>` is a letter between `A` and `E` and `<col>` is a number between `1` and `5`.

  If the request is successful, the server will respond with a JSON object containing the following fields:

  - `message`: a message indicating that the shot was played successfully
  - `sunk_ship`: `True` if the shot hit an enemy ship, `False` otherwise.
  - `won`: `True` if the shot won the game for the user, `False` otherwise.

- `DELETE URL/games/<game_id>`: Cancels/Forfeits the game with the integer id `<game_id>`. Note that only games which are currently in the matchmaking or active states can be canceled/forfeited. The server will respond with a JSON object containing the following field:

  - `message`: a message indicating that the game was successfully canceled or forfeited.

## 4. Build
Having dart and flutter installed already, in the parent directory the process to build is simply:
`flutter run`

You will be prompted with a selection of what platform to output. This app *should* be able to run on any of the platforms as the app's UI is responsive.