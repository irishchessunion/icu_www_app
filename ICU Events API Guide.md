# ICU Events API: Guide for ChessFam

Oct 12, 2026 · @joconnor@icu.ie

## Overview

The Irish Chess Union (ICU) publishes its events calendar as JSON at one read-only endpoint, which ChessFam pulls from:

```
GET https://www.icu.ie/api/v1/events
```

Each call returns a page of active events, with their sections and entry fees. By default it returns events in Ireland that have not yet finished.

The endpoint is not live yet. We will confirm the go-live date and send your API key separately.

## Authentication

Every request must carry your API key as a bearer token in the `Authorization` header:

```
Authorization: Bearer <your API key>
```

- The key is a 64-character string. We show it once when we create it and cannot retrieve it afterwards, so store it securely.
- The key is not accepted as a URL parameter.
- Use HTTPS for every request.
- If a key is lost or exposed, tell us. We will deactivate it and issue a new one.

## Request parameters

All parameters are optional and go in the query string. A call with none returns the first 50 upcoming events in Ireland.

| Parameter | Format | Effect | Default |
| --- | --- | --- | --- |
| `from` | `YYYY-MM-DD` | Only events that end on or after this date | Today |
| `to` | `YYYY-MM-DD` | Only events that start on or before this date | No limit |
| `category` | One or more of `irish`, `junior`, `women`, `foreign`, `junint`, separated by commas | Only events in these categories | `irish,junior,women` |
| `updated_since` | ISO 8601 date or time, e.g. `2026-10-01` or `2026-10-01T09:00:00Z` | Only events changed at or after this moment | No limit |
| `page` | Whole number, 1 or more | Which page of results to return | 1 |
| `per_page` | Whole number, 1 to 100 | Events per page | 50 |

Notes:

- `from` and `to` together select events that overlap the range, so an event in progress on the `from` date is included.
- `to` cannot be earlier than `from`. Because `from` defaults to today, a `to` in the past needs an explicit `from`.
- A date given for `updated_since` means the start of that day in UTC.
- `foreign` and `junint` are events held abroad. They are left out unless you ask for them, and they carry `country_code` `IRL` like every other event.
- Unknown parameters are ignored.

## Response and pagination

A successful call returns HTTP 200 with a JSON object: four paging fields and the list of events. The content type is always `application/json`.

| Field | Type | Meaning |
| --- | --- | --- |
| `page` | number | The page returned |
| `per_page` | number | The page size used |
| `total` | number | How many events match the filters, across all pages |
| `total_pages` | number | How many pages there are at this page size |
| `events` | array | The events on this page |

To read everything, request `page=1` and keep going until `page` reaches `total_pages`. A page past the end returns 200 with an empty `events` array. When nothing matches, `total` and `total_pages` are 0.

Events are ordered by start date, then end date, then name, then ID, so the order is the same on every call.

## Event fields

Every event has the same 19 fields, in this order. A field with no value is `null` unless the table says otherwise; it is never left out.

| Field | Type | Meaning |
| --- | --- | --- |
| `external_id` | string | Our permanent ID for the event, e.g. `ICU-EVENT-1234`. Use it as your dedup key. |
| `name` | string | Event name |
| `start_date` | string | First day, `YYYY-MM-DD` |
| `end_date` | string | Last day, `YYYY-MM-DD` |
| `country_code` | string | Always `IRL` |
| `latitude` | number or null | Venue latitude, when the organiser has supplied it |
| `longitude` | number or null | Venue longitude, when the organiser has supplied it |
| `address` | string | Venue as one free-text string, up to 100 characters. There are no separate city, state or country fields. |
| `tournament_type` | string | `swiss`, `round_robin` or `knockout` |
| `format` | string | `classical`, `rapid` or `blitz`. An event with more than one format reports the first. |
| `time_control` | string | Free text such as `90+30`. An empty string when the organiser has not published one. |
| `is_fide_rated` | boolean | Whether the event is FIDE rated |
| `is_nationally_rated` | boolean | Whether the event is ICU rated |
| `max_participants` | number or null | Entry limit, when there is one |
| `registration_deadline` | string or null | Last day any entry fee is on sale, `YYYY-MM-DD` |
| `external_registration_url` | string | The event's page on www.icu.ie, where players enter |
| `description` | string or null | The organiser's notes, as HTML |
| `contact` | string or null | Name of the organiser's contact person |
| `sections` | array | The event's sections and their entry fees; see the next section. Never empty. |

## Sections and fees

Entry fees, rating bands and age limits belong to an event's sections, not to the event itself. `sections` is an array with one entry per section, in the organiser's order.

- An event with named sections (e.g. Masters, Major, Minor) has one entry for each.
- An event with no sections has exactly one entry, named `all`, holding every fee.

Each section has two fields:

| Field | Type | Meaning |
| --- | --- | --- |
| `name` | string | Section name, or `all` |
| `fees` | array | The entry fees that apply to this section. Can be empty. |

Each fee has 12 fields:

| Field | Type | Meaning |
| --- | --- | --- |
| `name` | string | Fee name as shown to players |
| `amount` | number | Full price |
| `currency` | string | Always `EUR` |
| `discounted_amount` | number or null | Reduced price for early entry |
| `discount_deadline` | string or null | Last day of the reduced price, `YYYY-MM-DD` |
| `rating_min` | number or null | Lowest rating allowed |
| `rating_max` | number or null | Highest rating allowed |
| `age_min` | number or null | Youngest age allowed |
| `age_max` | number or null | Oldest age allowed |
| `age_ref_date` | string or null | The date on which a player's age is measured, `YYYY-MM-DD` |
| `sale_start` | string or null | First day the fee is on sale, `YYYY-MM-DD` |
| `sale_end` | string or null | Last day the fee is on sale, `YYYY-MM-DD` |

Things to know:

- A fee that covers several sections appears under each of them.
- A section can have several fees, for example a standard fee and a junior fee.
- Only fees the organiser has marked active are listed. A fee whose sale period has not opened yet, or has closed, is still listed; use `sale_start` and `sale_end` to tell.
- An event can be listed before its organiser has set up fees, in which case `fees` is empty.

## Differences from the ChessFam field spec

Most fields match your spec by name and type, but ten of its fields are not sent at the top level and need handling on your side.

| Your field | What we send instead |
| --- | --- |
| `city`, `state`, `country` | Not sent. `address` is a single string; `country_code` gives the country. |
| `rating_min`, `rating_max` | Per fee, inside `sections` |
| `entry_fee`, `currency` | Per fee, inside `sections`, as `amount` and `currency` |
| `organizer_name_override` | Not sent |
| `rules` | Not sent |
| `image` | Not sent; our events have no image |

Other points:

- `format` is never `bullet`.
- `time_control` can be an empty string, although your spec marks it required.
- `contact` and `sections` are additions that are not in your spec.
- For a single entry fee or rating band per tournament, you will need to choose from `sections`, for example the lowest `amount` across all fees.

## Errors

An error returns a JSON object with a single `error` field holding a message in English, for example:

```json
{ "error": "from must be a date like 2026-12-31" }
```

| Status | When | What to do |
| --- | --- | --- |
| 400 Bad Request | A parameter cannot be used | Fix the request; the message names the parameter |
| 401 Unauthorized | The key is missing, wrong, inactive, or not sent as a bearer token | Check the `Authorization` header, then contact us |
| 403 Forbidden | The key is valid but is not allowed to read events | Contact us |

The key is checked before the parameters, so a request with both a bad key and a bad parameter gets a 401.

Requests that get a 400:

- A `from` or `to` that is not `YYYY-MM-DD`, or is not a real date such as `2026-02-30`
- A `to` earlier than `from`
- An `updated_since` that is neither an ISO 8601 date nor time
- A `category` value outside the five listed
- A `page` below 1, a `per_page` outside 1 to 100, or either one not a whole number
- A parameter sent in array form, such as from\[\]=2026-11-01

## Examples

Upcoming events in Ireland, first page:

```bash
curl -H "Authorization: Bearer $ICU_API_KEY" \
  "https://www.icu.ie/api/v1/events"
```

Events overlapping the first half of 2027, 100 per page:

```bash
curl -H "Authorization: Bearer $ICU_API_KEY" \
  "https://www.icu.ie/api/v1/events?from=2027-01-01&to=2027-06-30&per_page=100"
```

Upcoming events changed since 1 October 2026:

```bash
curl -H "Authorization: Bearer $ICU_API_KEY" \
  "https://www.icu.ie/api/v1/events?updated_since=2026-10-01T00:00:00Z"
```

An illustrative response with one event that has two sections. The values are made up; the structure is exact.

```json
{
  "page": 1,
  "per_page": 50,
  "total": 1,
  "total_pages": 1,
  "events": [
    {
      "external_id": "ICU-EVENT-1234",
      "name": "Galway Congress",
      "start_date": "2026-11-13",
      "end_date": "2026-11-15",
      "country_code": "IRL",
      "latitude": 53.259,
      "longitude": -9.077,
      "address": "Salthill Hotel, Galway",
      "tournament_type": "swiss",
      "format": "classical",
      "time_control": "90+30",
      "is_fide_rated": true,
      "is_nationally_rated": true,
      "max_participants": 120,
      "registration_deadline": "2026-11-12",
      "external_registration_url": "https://www.icu.ie/events/1234",
      "description": "<p>Five rounds over the weekend.</p>\n",
      "contact": "Mary Murphy",
      "sections": [
        {
          "name": "Masters",
          "fees": [
            {
              "name": "Galway Masters",
              "amount": 60.0,
              "currency": "EUR",
              "discounted_amount": 50.0,
              "discount_deadline": "2026-10-31",
              "rating_min": 1900,
              "rating_max": null,
              "age_min": null,
              "age_max": null,
              "age_ref_date": null,
              "sale_start": "2026-08-13",
              "sale_end": "2026-11-12"
            }
          ]
        },
        {
          "name": "Major",
          "fees": [
            {
              "name": "Galway Major",
              "amount": 45.0,
              "currency": "EUR",
              "discounted_amount": null,
              "discount_deadline": null,
              "rating_min": null,
              "rating_max": 1899,
              "age_min": null,
              "age_max": null,
              "age_ref_date": null,
              "sale_start": "2026-08-13",
              "sale_end": "2026-11-12"
            },
            {
              "name": "Galway Major Junior",
              "amount": 25.0,
              "currency": "EUR",
              "discounted_amount": null,
              "discount_deadline": null,
              "rating_min": null,
              "rating_max": 1899,
              "age_min": null,
              "age_max": 17,
              "age_ref_date": "2026-11-13",
              "sale_start": "2026-08-13",
              "sale_end": "2026-11-12"
            }
          ]
        }
      ]
    }
  ]
}
```

## Suggested sync approach

We recommend a full pull of upcoming events once a day, keyed on `external_id`, treating any event that has disappeared as withdrawn.

1. Call the endpoint with no filters and `per_page=100`, and read every page up to `total_pages`.
2. Create or update one tournament per event, matched on `external_id`.
3. Remove or hide any upcoming tournament you hold whose `external_id` was not in the pull.

Known limitations:

- **Withdrawn events disappear.** An event the organiser cancels or unpublishes is no longer returned; there is no flag for it. Step 3 above is the only way to detect this.
- **`updated_since` does not see fee changes.** It reflects edits to the event itself. A change to an entry fee alone does not move the event's update time, so do not rely on `updated_since` as your only sync.
- **Events have no update timestamp field.** You cannot compare your copy's age with ours; take ours as current.
- **Finished events drop out of the default call** the day after their `end_date`. Pass an earlier `from` to fetch them.
- **Organisers supply the optional details.** `time_control`, `max_participants`, coordinates and fees are often blank on events announced early, and are filled in later.

Questions and key requests go to the ICU webmaster at webmaster@icu.ie.
