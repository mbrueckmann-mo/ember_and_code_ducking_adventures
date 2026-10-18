# Ember & Code Ducking Adventures — API Design Document

**Version:** 1.0.0
**Base URL:** `https://api.embercode.duck/v1`
**Last Updated:** 2026-10-18
**Format:** REST / JSON

---

## Table of Contents

1. [Overview](#overview)
2. [Authentication](#authentication)
3. [Common Conventions](#common-conventions)
4. [Error Handling](#error-handling)
5. [Resources](#resources)
   - [Users](#users)
   - [Ducks](#ducks)
   - [Journeys](#journeys)
   - [Achievements](#achievements)
6. [Webhooks](#webhooks)
7. [Rate Limiting](#rate-limiting)
8. [Changelog](#changelog)

---

## Overview

The Ember & Code Ducking Adventures API provides programmatic access to all core game resources: player accounts, collectible ducks, quest journeys, and unlockable achievements. The API follows REST conventions and returns JSON for all responses.

**Design Principles:**
- Resource-oriented URLs
- Stateless requests with JWT authentication
- Consistent envelope structure on all responses
- Pagination on all list endpoints

---

## Authentication

All endpoints (except `POST /auth/register` and `POST /auth/login`) require a Bearer token in the `Authorization` header.

```http
Authorization: Bearer <access_token>
```

### Token Lifecycle

| Token Type    | TTL     | Refresh Strategy          |
|---------------|---------|---------------------------|
| Access Token  | 15 min  | Use refresh token         |
| Refresh Token | 30 days | Re-authenticate on expiry |

### Auth Endpoints

#### `POST /auth/register`
Register a new player account.

**Request Body:**
```json
{
  "username": "quackmaster",
  "email": "quack@example.com",
  "password": "s3cur3P@ss!"
}
```

**Response `201 Created`:**
```json
{
  "data": {
    "user_id": "usr_abc123",
    "username": "quackmaster",
    "email": "quack@example.com",
    "created_at": "2026-10-18T14:00:00Z"
  }
}
```

---

#### `POST /auth/login`
Authenticate a player and receive tokens.

**Request Body:**
```json
{
  "email": "quack@example.com",
  "password": "s3cur3P@ss!"
}
```

**Response `200 OK`:**
```json
{
  "data": {
    "access_token": "eyJ...",
    "refresh_token": "dRT...",
    "expires_in": 900
  }
}
```

---

#### `POST /auth/refresh`
Exchange a refresh token for a new access token.

**Request Body:**
```json
{ "refresh_token": "dRT..." }
```

**Response `200 OK`:**
```json
{
  "data": {
    "access_token": "eyJ...",
    "expires_in": 900
  }
}
```

---

#### `POST /auth/logout`
Revoke the current session tokens.

**Response `204 No Content`**

---

## Common Conventions

### Request Headers

| Header          | Required   | Description                      |
|-----------------|------------|----------------------------------|
| `Authorization` | Yes        | `Bearer <access_token>`          |
| `Content-Type`  | Yes (body) | `application/json`               |
| `Accept`        | No         | `application/json` (default)     |
| `X-Request-ID`  | No         | Client-generated idempotency key |

### Response Envelope

All responses wrap data in a consistent envelope:

```json
{
  "data": { ... },
  "meta": {
    "request_id": "req_xyz",
    "timestamp": "2026-10-18T14:00:00Z"
  }
}
```

List responses include a `pagination` block:

```json
{
  "data": [ ... ],
  "pagination": {
    "page": 1,
    "per_page": 20,
    "total": 142,
    "total_pages": 8
  },
  "meta": { ... }
}
```

### Query Parameters (All List Endpoints)

| Parameter  | Type    | Default | Description                  |
|------------|---------|---------|------------------------------|
| `page`     | integer | `1`     | Page number                  |
| `per_page` | integer | `20`    | Results per page (max `100`) |
| `sort`     | string  | varies  | Field to sort by             |
| `order`    | string  | `asc`   | `asc` or `desc`              |

---

## Error Handling

All errors follow a consistent structure:

```json
{
  "error": {
    "code": "DUCK_NOT_FOUND",
    "message": "The requested duck could not be found.",
    "status": 404,
    "request_id": "req_xyz"
  }
}
```

### HTTP Status Codes

| Code | Meaning                                          |
|------|--------------------------------------------------|
| 200  | OK — Successful GET / PUT / PATCH                |
| 201  | Created — Successful POST                        |
| 204  | No Content — Successful DELETE                   |
| 400  | Bad Request — Invalid parameters or body         |
| 401  | Unauthorized — Missing or invalid token          |
| 403  | Forbidden — Authenticated but insufficient scope |
| 404  | Not Found — Resource does not exist              |
| 409  | Conflict — Duplicate resource or state conflict  |
| 422  | Unprocessable Entity — Validation failure        |
| 429  | Too Many Requests — Rate limit exceeded          |
| 500  | Internal Server Error                            |

### Application Error Codes

| Error Code                    | Status | Description                           |
|-------------------------------|--------|---------------------------------------|
| `VALIDATION_ERROR`            | 422    | Request body failed schema validation |
| `USER_NOT_FOUND`              | 404    | User does not exist                   |
| `DUCK_NOT_FOUND`              | 404    | Duck does not exist                   |
| `DUCK_ALREADY_OWNED`          | 409    | Player already owns this duck         |
| `JOURNEY_NOT_FOUND`           | 404    | Journey does not exist                |
| `JOURNEY_ALREADY_ACTIVE`      | 409    | Player already has an active journey  |
| `JOURNEY_PREREQUISITES_UNMET` | 403    | Required prior journeys not completed |
| `ACHIEVEMENT_NOT_FOUND`       | 404    | Achievement does not exist            |
| `ACHIEVEMENT_ALREADY_UNLOCKED`| 409    | Player already has this achievement   |
| `RATE_LIMIT_EXCEEDED`         | 429    | Too many requests                     |
| `INSUFFICIENT_QUACKS`         | 402    | Not enough in-game currency           |

---

## Resources

---

### Users

A **User** represents a registered player account. Users own ducks, progress through journeys, and earn achievements.

#### User Object

```json
{
  "user_id": "usr_abc123",
  "username": "quackmaster",
  "email": "quack@example.com",
  "avatar_url": "https://cdn.embercode.duck/avatars/usr_abc123.png",
  "quack_balance": 1500,
  "level": 12,
  "xp": 4820,
  "xp_to_next_level": 5000,
  "duck_count": 7,
  "journey_count": 3,
  "achievement_count": 14,
  "created_at": "2026-08-01T09:00:00Z",
  "updated_at": "2026-10-18T12:30:00Z"
}
```

---

#### `GET /users/me`
Retrieve the authenticated player's profile.

**Response `200 OK`:** Returns the User Object.

---

#### `PATCH /users/me`
Update the authenticated player's profile.

**Request Body (all fields optional):**
```json
{
  "username": "superquacker",
  "avatar_url": "https://cdn.embercode.duck/avatars/new.png"
}
```

**Response `200 OK`:** Returns the updated User Object.

---

#### `DELETE /users/me`
Permanently delete the authenticated player's account.

**Response `204 No Content`**

---

#### `GET /users/{user_id}`
Retrieve a public profile for any user. Returns a reduced field set (no email or balance).

**Path Parameters:**

| Parameter | Type   | Description    |
|-----------|--------|----------------|
| `user_id` | string | Target user ID |

**Response `200 OK`:**
```json
{
  "data": {
    "user_id": "usr_abc123",
    "username": "quackmaster",
    "avatar_url": "https://cdn.embercode.duck/avatars/usr_abc123.png",
    "level": 12,
    "duck_count": 7,
    "achievement_count": 14
  }
}
```

---

#### `GET /users/me/ducks`
List all ducks owned by the authenticated user.

**Query Parameters:** Standard pagination + `sort` (`obtained_at`, `rarity`, `name`).

**Response `200 OK`:** Paginated list of Duck Objects.

---

#### `GET /users/me/journeys`
List all journeys for the authenticated user.

**Query Parameters:** Standard pagination + `status` filter (`active`, `completed`, `abandoned`).

**Response `200 OK`:** Paginated list of Journey Record Objects.

---

#### `GET /users/me/achievements`
List all achievements unlocked by the authenticated user.

**Query Parameters:** Standard pagination + `sort` (`unlocked_at`, `rarity`).

**Response `200 OK`:** Paginated list of Achievement Objects.

---

#### `GET /users/me/stats`
Retrieve detailed gameplay statistics.

**Response `200 OK`:**
```json
{
  "data": {
    "user_id": "usr_abc123",
    "total_journeys_completed": 12,
    "total_distance_traveled": 48200,
    "total_ducks_collected": 31,
    "total_achievements_unlocked": 14,
    "playtime_minutes": 3740,
    "favorite_duck_id": "dck_ember01",
    "longest_streak_days": 9,
    "current_streak_days": 3
  }
}
```

---

### Ducks

A **Duck** is a collectible companion with a rarity tier, elemental affinity, and special ability. Players obtain ducks through journeys, achievements, or the in-game shop.

#### Duck Rarities

| Rarity    | Code | Drop Weight |
|-----------|------|-------------|
| Common    | `C`  | 60%         |
| Uncommon  | `U`  | 25%         |
| Rare      | `R`  | 10%         |
| Epic      | `E`  | 4%          |
| Legendary | `L`  | 1%          |

#### Duck Object

```json
{
  "duck_id": "dck_ember01",
  "name": "Ember",
  "slug": "ember",
  "description": "A fiery little duck forged in the heart of a volcano.",
  "rarity": "L",
  "element": "fire",
  "ability": {
    "name": "Inferno Quack",
    "description": "Scorches the path ahead, revealing hidden secrets.",
    "cooldown_seconds": 30
  },
  "base_stats": {
    "speed": 85,
    "stamina": 70,
    "luck": 60,
    "charm": 90
  },
  "sprite_url": "https://cdn.embercode.duck/ducks/ember.png",
  "lore": "Legend says Ember hatched from a meteor that fell into the Quacking Caldera.",
  "obtainable_from": ["journey_volcanic_trial", "achievement_first_flame"],
  "created_at": "2026-06-01T00:00:00Z"
}
```

---

#### `GET /ducks`
List all ducks in the game catalog.

**Query Parameters:**

| Parameter | Type   | Description                                              |
|-----------|--------|----------------------------------------------------------|
| `rarity`  | string | Filter by rarity code (`C`, `U`, `R`, `E`, `L`)         |
| `element` | string | `fire`, `water`, `earth`, `air`, `void`                  |
| `search`  | string | Full-text search on name and description                 |
| `sort`    | string | `name`, `rarity`, `created_at`                           |

**Response `200 OK`:** Paginated list of Duck Objects.

---

#### `GET /ducks/{duck_id}`
Retrieve a single duck from the catalog.

**Response `200 OK`:** Returns the Duck Object.

---

#### `POST /users/me/ducks/{duck_id}`
Add a duck to the authenticated player's collection.

**Request Body:**
```json
{
  "source": "journey",
  "source_id": "jny_xyz789"
}
```

**Response `201 Created`:**
```json
{
  "data": {
    "duck_id": "dck_ember01",
    "obtained_at": "2026-10-18T14:00:00Z",
    "source": "journey",
    "source_id": "jny_xyz789"
  }
}
```

---

#### `DELETE /users/me/ducks/{duck_id}`
Release a duck from the player's collection.

**Response `204 No Content`**

---

#### `PUT /users/me/active-duck`
Set the player's active companion duck.

**Request Body:**
```json
{ "duck_id": "dck_ember01" }
```

**Response `200 OK`:**
```json
{
  "data": {
    "active_duck_id": "dck_ember01",
    "updated_at": "2026-10-18T14:05:00Z"
  }
}
```

---

### Journeys

A **Journey** is a multi-stage quest. Journeys may have prerequisites, a required duck element, and a maximum attempt count. Completing a journey grants XP, quacks, and potentially new ducks or achievements.

#### Journey Status Values

| Status      | Description                              |
|-------------|------------------------------------------|
| `pending`   | Not yet started by the player            |
| `active`    | Currently in progress                    |
| `completed` | Successfully finished                    |
| `failed`    | Ended without meeting success conditions |
| `abandoned` | Manually quit by the player              |

#### Journey Object

```json
{
  "journey_id": "jny_volcanic_trial",
  "name": "The Volcanic Trial",
  "slug": "volcanic-trial",
  "description": "Brave the scorching heat of the Quacking Caldera to prove your worth.",
  "difficulty": "hard",
  "estimated_duration_minutes": 45,
  "prerequisites": ["jny_ember_awakening"],
  "required_duck_element": "fire",
  "stages": [
    {
      "stage_number": 1,
      "name": "Lava Crossing",
      "objective": "Cross the lava field without falling in.",
      "xp_reward": 200
    },
    {
      "stage_number": 2,
      "name": "The Caldera Summit",
      "objective": "Reach the peak of the Quacking Caldera.",
      "xp_reward": 500
    }
  ],
  "rewards": {
    "xp": 1200,
    "quacks": 300,
    "duck_ids": ["dck_ember01"],
    "achievement_ids": ["ach_volcanic_conqueror"]
  },
  "max_attempts": 3,
  "created_at": "2026-06-15T00:00:00Z"
}
```

#### Player Journey Record Object

```json
{
  "record_id": "jrec_001",
  "journey_id": "jny_volcanic_trial",
  "user_id": "usr_abc123",
  "status": "active",
  "current_stage": 1,
  "attempts": 1,
  "started_at": "2026-10-18T14:00:00Z",
  "completed_at": null,
  "elapsed_seconds": 420,
  "rewards_claimed": false
}
```

---

#### `GET /journeys`
List all journeys in the game world.

**Query Parameters:**

| Parameter    | Type   | Description                                                     |
|--------------|--------|-----------------------------------------------------------------|
| `difficulty` | string | `easy`, `medium`, `hard`, `legendary`                           |
| `element`    | string | Filter by required duck element                                 |
| `available`  | bool   | If `true`, returns only journeys the player is eligible to start|
| `search`     | string | Full-text search on name and description                        |

**Response `200 OK`:** Paginated list of Journey Objects.

---

#### `GET /journeys/{journey_id}`
Retrieve a single journey definition.

**Response `200 OK`:** Returns the Journey Object.

---

#### `POST /users/me/journeys`
Start a new journey for the authenticated player.

**Request Body:**
```json
{
  "journey_id": "jny_volcanic_trial",
  "active_duck_id": "dck_ember01"
}
```

**Response `201 Created`:** Returns the Player Journey Record Object.

**Possible Errors:**
- `JOURNEY_ALREADY_ACTIVE` — Player has an active journey
- `JOURNEY_PREREQUISITES_UNMET` — Required journeys not completed
- `DUCK_NOT_FOUND` — Specified duck not in player's collection

---

#### `GET /users/me/journeys/{record_id}`
Retrieve a specific journey instance record.

**Response `200 OK`:** Returns the Player Journey Record Object.

---

#### `PATCH /users/me/journeys/{record_id}`
Update journey progress (advance stage, sync elapsed time).

**Request Body:**
```json
{
  "current_stage": 2,
  "elapsed_seconds": 720
}
```

**Response `200 OK`:** Returns the updated Player Journey Record Object.

---

#### `POST /users/me/journeys/{record_id}/complete`
Mark a journey as completed and trigger reward distribution.

**Response `200 OK`:**
```json
{
  "data": {
    "record_id": "jrec_001",
    "status": "completed",
    "completed_at": "2026-10-18T14:45:00Z",
    "rewards_granted": {
      "xp": 1200,
      "quacks": 300,
      "ducks_unlocked": ["dck_ember01"],
      "achievements_unlocked": ["ach_volcanic_conqueror"]
    }
  }
}
```

---

#### `POST /users/me/journeys/{record_id}/abandon`
Abandon an active journey. Consumes one attempt if `max_attempts` is set.

**Response `200 OK`:**
```json
{
  "data": {
    "record_id": "jrec_001",
    "status": "abandoned",
    "attempts_remaining": 2
  }
}
```

---

### Achievements

An **Achievement** is a milestone unlocked by meeting specific in-game conditions. Achievements can reward XP, quacks, or exclusive ducks.

#### Achievement Trigger Types

| Trigger Type       | Description                                   |
|--------------------|-----------------------------------------------|
| `journey_complete` | Triggered by completing a specific journey    |
| `duck_collect`     | Triggered by collecting a specific duck       |
| `stat_threshold`   | Triggered when a stat reaches a numeric value |
| `streak`           | Triggered by maintaining a login/play streak  |
| `secret`           | Condition is hidden until unlocked            |

#### Achievement Object

```json
{
  "achievement_id": "ach_volcanic_conqueror",
  "name": "Volcanic Conqueror",
  "description": "Complete the Volcanic Trial on the first attempt.",
  "icon_url": "https://cdn.embercode.duck/achievements/volcanic_conqueror.png",
  "rarity": "R",
  "trigger_type": "journey_complete",
  "trigger_condition": {
    "journey_id": "jny_volcanic_trial",
    "max_attempts": 1
  },
  "rewards": {
    "xp": 500,
    "quacks": 100,
    "duck_ids": []
  },
  "is_secret": false,
  "created_at": "2026-06-15T00:00:00Z"
}
```

#### Player Achievement Record Object

```json
{
  "achievement_id": "ach_volcanic_conqueror",
  "user_id": "usr_abc123",
  "unlocked_at": "2026-10-18T14:45:00Z",
  "trigger_context": {
    "journey_id": "jny_volcanic_trial",
    "record_id": "jrec_001"
  }
}
```

---

#### `GET /achievements`
List all achievements in the game. Secret achievement fields are redacted unless already unlocked by the caller.

**Query Parameters:**

| Parameter      | Type   | Description                              |
|----------------|--------|------------------------------------------|
| `rarity`       | string | Filter by rarity code                    |
| `trigger_type` | string | Filter by trigger type                   |
| `is_secret`    | bool   | Include/exclude secret achievements      |
| `search`       | string | Full-text search on name and description |

**Response `200 OK`:** Paginated list of Achievement Objects.

---

#### `GET /achievements/{achievement_id}`
Retrieve a single achievement. Secret achievements return redacted details unless the caller has already unlocked them.

**Response `200 OK`:** Returns the Achievement Object.

---

#### `GET /users/me/achievements/{achievement_id}`
Check whether the authenticated player has unlocked a specific achievement.

**Response `200 OK`:** Returns the Player Achievement Record Object.
**Response `404 Not Found`:** `ACHIEVEMENT_NOT_FOUND` if not yet unlocked.

---

#### `POST /users/me/achievements/{achievement_id}/claim`
Manually claim rewards for an unlocked achievement (used when auto-grant is disabled).

**Response `200 OK`:**
```json
{
  "data": {
    "achievement_id": "ach_volcanic_conqueror",
    "rewards_claimed": {
      "xp": 500,
      "quacks": 100,
      "ducks_unlocked": []
    },
    "claimed_at": "2026-10-18T15:00:00Z"
  }
}
```

---

#### `GET /achievements/leaderboard`
Top players ranked by total achievement count.

**Query Parameters:** Standard pagination + `rarity` (filter achievements counted by rarity).

**Response `200 OK`:**
```json
{
  "data": [
    {
      "rank": 1,
      "user_id": "usr_def456",
      "username": "duckwhisperer",
      "avatar_url": "https://cdn.embercode.duck/avatars/usr_def456.png",
      "achievement_count": 42,
      "rarest_achievement": "ach_first_legend"
    }
  ],
  "pagination": { ... }
}
```

---

## Webhooks

Subscribe to real-time game events delivered to your server endpoint.

### Supported Events

| Event Name              | Trigger                                    |
|-------------------------|--------------------------------------------|
| `user.level_up`         | Player gains a level                       |
| `duck.obtained`         | Player adds a duck to their collection     |
| `journey.started`       | Player begins a journey                    |
| `journey.completed`     | Player successfully completes a journey    |
| `journey.failed`        | Player fails a journey                     |
| `achievement.unlocked`  | Player unlocks an achievement              |
| `quack_balance.changed` | Player's quack currency balance changes    |

### Webhook Payload Example (`achievement.unlocked`)

```json
{
  "event": "achievement.unlocked",
  "timestamp": "2026-10-18T14:45:00Z",
  "data": {
    "user_id": "usr_abc123",
    "achievement_id": "ach_volcanic_conqueror"
  }
}
```

### Webhook Registration

```http
POST /webhooks
Authorization: Bearer <access_token>
Content-Type: application/json

{
  "url": "https://yourserver.example.com/hooks/duck",
  "events": ["achievement.unlocked", "duck.obtained"],
  "secret": "your_signing_secret"
}
```

Payloads are signed with HMAC-SHA256 using your `secret`. Validate the `X-Duck-Signature` header on incoming requests.

---

## Rate Limiting

| Tier            | Requests / Minute | Burst |
|-----------------|-------------------|-------|
| Unauthenticated | 20                | 30    |
| Authenticated   | 120               | 200   |
| Admin           | 1000              | 1500  |

Rate limit headers are returned on every response:

```http
X-RateLimit-Limit: 120
X-RateLimit-Remaining: 87
X-RateLimit-Reset: 1760888460
```

When exceeded, the API returns `429 Too Many Requests` with a `Retry-After` header.

---

## Changelog

| Version | Date       | Notes                                                     |
|---------|------------|-----------------------------------------------------------|
| 1.0.0   | 2026-10-18 | Initial release — Users, Ducks, Journeys, Achievements    |


| Section | Endpoints |
| --- | --- |
| **Auth** | Register, Login, Refresh, Logout |
| **Users** | Profile CRUD, public lookup, owned ducks/journeys/achievements, stats |
| **Ducks** | Catalog browse, single duck, collect/release, set active duck |
| **Journeys** | Browse, start, progress, complete, abandon, per-player records |
| **Achievements** | Catalog browse, unlock check, reward claim, leaderboard |
| **Webhooks** | 7 event types, HMAC-SHA256 payload signing |
| **Rate Limiting** | Tiered limits with standard headers |